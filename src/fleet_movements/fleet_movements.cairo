use nogame::libraries::types::{Fleet, PlanetPosition, SimulationResult, Defences, Debris};

#[starknet::interface]
trait IFleetMovements<TState> {
    fn send_fleet(
        ref self: TState,
        f: Fleet,
        destination: PlanetPosition,
        mission_type: u8,
        speed_modifier: u32,
        colony_id: u8,
    );
    fn attack_planet(ref self: TState, mission_id: usize);
    fn recall_fleet(ref self: TState, mission_id: usize);
    fn dock_fleet(ref self: TState, mission_id: usize);
    fn collect_debris(ref self: TState, mission_id: usize);
    fn simulate_attack(
        self: @TState, attacker_fleet: Fleet, defender_fleet: Fleet, defences: Defences
    ) -> SimulationResult;
}

#[starknet::contract]
mod FleetMovements {
    use nogame::colony::colony::{IColonyDispatcher, IColonyDispatcherTrait};
    use nogame::component::shared::SharedComponent;
    use nogame::compound::compound::{ICompoundDispatcher, ICompoundDispatcherTrait};
    use nogame::defence::library as defence;
    use nogame::dockyard::dockyard::{IDockyardDispatcher, IDockyardDispatcherTrait};
    use nogame::dockyard::library as dockyard;
    use nogame::fleet_movements::library as fleet;
    use nogame::libraries::types::{
        MissionCategory, Fleet, PlanetPosition, Mission, ERC20s, Names, E18, IncomingMission,
        Defences, Debris, TechLevels, WEEK, HOUR, SimulationResult
    };
    use nogame::storage::storage::{IStorageDispatcher, IStorageDispatcherTrait};
    use nogame::token::erc20::interface::{IERC20NoGameDispatcher, IERC20NoGameDispatcherTrait};
    use nogame::token::erc721::interface::{IERC721NoGameDispatcherTrait, IERC721NoGameDispatcher};
    use openzeppelin::access::ownable::OwnableComponent;
    use starknet::{
        ContractAddress, get_caller_address, get_block_timestamp, get_contract_address,
        contract_address_const
    };

    component!(path: SharedComponent, storage: shared, event: SharedEvent);
    impl SharedInternalImpl = SharedComponent::InternalImpl<ContractState>;

    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        shared: SharedComponent::Storage,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        BattleReport: BattleReport,
        DebrisCollected: DebrisCollected,
        #[flat]
        SharedEvent: SharedComponent::Event,
        #[flat]
        OwnableEvent: OwnableComponent::Event,
    }

    #[derive(Drop, starknet::Event)]
    struct BattleReport {
        time: u64,
        attacker: u32,
        attacker_position: PlanetPosition,
        attacker_initial_fleet: Fleet,
        attacker_fleet_loss: Fleet,
        defender: u32,
        defender_position: PlanetPosition,
        defender_initial_fleet: Fleet,
        defender_fleet_loss: Fleet,
        initial_defences: Defences,
        defences_loss: Defences,
        loot: ERC20s,
        debris: Debris,
    }

    #[derive(Drop, starknet::Event)]
    struct DebrisCollected {
        planet_id: u32,
        debris_field_id: u32,
        amount: Debris,
    }

    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress, storage: ContractAddress, colony: ContractAddress) {
        self.ownable.initializer(get_caller_address());
        self.shared.initializer(storage, colony);
    }

    #[abi(embed_v0)]
    impl FleetMovementsImpl of super::IFleetMovements<ContractState> {
        fn send_fleet(
            ref self: ContractState,
            f: Fleet,
            destination: PlanetPosition,
            mission_type: u8,
            speed_modifier: u32,
            colony_id: u8,
        ) {
            let destination_id = self.shared.storage.read().get_position_to_planet(destination);
            assert(!destination_id.is_zero(), 'no planet at destination');
            let caller = get_caller_address();
            let planet_id = self.shared.get_owned_planet(caller);
            let origin_id = if colony_id.is_zero() {
                planet_id
            } else {
                (planet_id * 1000) + colony_id.into()
            };

            if destination_id > 500 && mission_type == MissionCategory::TRANSPORT {
                assert(
                    self
                        .shared
                        .storage
                        .read()
                        .get_colony_mother_planet(destination_id) == planet_id,
                    'not your colony'
                );
            }
            if mission_type == MissionCategory::ATTACK {
                if destination_id > 500 {
                    assert(
                        self
                            .shared
                            .storage
                            .read()
                            .get_colony_mother_planet(destination_id) != planet_id,
                        'cannot attack own planet'
                    );
                } else {
                    assert(destination_id != planet_id, 'cannot attack own planet');
                }
            }
            let time_now = get_block_timestamp();

            self.check_enough_ships(planet_id, colony_id, f);
            // Calculate distance
            let distance = fleet::get_distance(
                self.shared.storage.read().get_planet_position(origin_id), destination
            );

            // Calculate time
            let techs = self.shared.storage.read().get_tech_levels(planet_id);
            let speed = fleet::get_fleet_speed(f, techs);
            let travel_time = fleet::get_flight_time(speed, distance, speed_modifier);

            // Check numeber of mission
            let active_missions = self.shared.storage.read().get_active_missions(planet_id).len();
            assert(active_missions < techs.digital.into() + 1, 'max active missions');

            // Pay for fuel
            let consumption = fleet::get_fuel_consumption(f, distance)
                * 100
                / speed_modifier.into();
            let mut cost: ERC20s = Default::default();
            cost.tritium = consumption;
            self.shared.check_enough_resources(caller, cost);
            self.shared.pay_resources_erc20(caller, cost);

            // Write mission
            let mut mission: Mission = Default::default();
            mission.time_start = time_now;
            mission.origin = origin_id;
            mission.destination = self.shared.storage.read().get_position_to_planet(destination);
            mission.time_arrival = time_now + travel_time;
            mission.fleet = f;

            if mission_type == MissionCategory::DEBRIS {
                assert(
                    !self.shared.storage.read().get_planet_debris_field(destination_id).is_zero(),
                    'empty debris fiels'
                );
                assert(f.scraper >= 1, 'no scrapers for collection');
                mission.category = MissionCategory::DEBRIS;
                self.shared.storage.read().add_active_mission(planet_id, mission);
            } else if mission_type == MissionCategory::TRANSPORT {
                mission.category = MissionCategory::TRANSPORT;
                self.shared.storage.read().add_active_mission(planet_id, mission);
            } else {
                let is_inactive = time_now
                    - self.shared.storage.read().get_last_active(destination_id) > WEEK;
                if !is_inactive {
                    assert(
                        !self
                            .shared
                            .storage
                            .read()
                            .get_is_noob_protected(planet_id, destination_id),
                        'noob protection active'
                    );
                }
                mission.category = MissionCategory::ATTACK;
                let id = self.shared.storage.read().add_active_mission(planet_id, mission);
                let mut hostile_mission: IncomingMission = Default::default();
                hostile_mission.origin = planet_id;
                hostile_mission.id_at_origin = id;
                hostile_mission.time_arrival = mission.time_arrival;
                hostile_mission
                    .number_of_ships = fleet::calculate_number_of_ships(f, Zeroable::zero());
                hostile_mission.destination = destination_id;
                let is_colony = mission.destination > 1000;
                let target_planet = if is_colony {
                    self.shared.storage.read().get_colony_mother_planet(mission.destination)
                } else {
                    mission.destination
                };
                self.shared.storage.read().add_incoming_mission(target_planet, hostile_mission);
            }
            self.shared.storage.read().set_last_active(planet_id, time_now);
            self.fleet_leave_planet(origin_id, f);
        }

        fn attack_planet(ref self: ContractState, mission_id: usize) {
            let caller = get_caller_address();
            let origin = self.shared.get_owned_planet(caller);
            let mut mission = self.shared.storage.read().get_mission_details(origin, mission_id);
            assert(!mission.is_zero(), 'the mission is empty');
            assert(mission.category == MissionCategory::ATTACK, 'not an attack mission');
            assert(mission.destination != origin, 'cannot attack own planet');
            let time_now = get_block_timestamp();
            assert(time_now >= mission.time_arrival, 'destination not reached yet');
            let is_colony = mission.destination > 500;
            let colony_mother_planet = if is_colony {
                self.shared.storage.read().get_colony_mother_planet(mission.destination)
            } else {
                0
            };
            let colony_id: u8 = if is_colony {
                (mission.destination - colony_mother_planet * 1000).try_into().unwrap()
            } else {
                0
            };

            let mut t1 = self.shared.storage.read().get_tech_levels(origin);
            let (defender_fleet, defences, t2, celestia_before) = self
                .get_fleet_and_defences_before_battle(mission.destination);

            let time_since_arrived = time_now - mission.time_arrival;
            let mut attacker_fleet: Fleet = mission.fleet;

            if time_since_arrived > (2 * HOUR) {
                let decay_amount = fleet::calculate_fleet_loss(time_since_arrived - (2 * HOUR));
                attacker_fleet = fleet::decay_fleet(mission.fleet, decay_amount);
            }

            let (f1, f2, d) = fleet::war(attacker_fleet, t1, defender_fleet, defences, t2);

            // calculate debris and update field
            let debris1 = fleet::get_debris(mission.fleet, f1, 0);
            let debris2 = fleet::get_debris(defender_fleet, f2, celestia_before - d.celestia);
            let total_debris = debris1 + debris2;
            let current_debries_field = self
                .shared
                .storage
                .read()
                .get_planet_debris_field(mission.destination);
            self
                .shared
                .storage
                .read()
                .set_planet_debris_field(mission.destination, current_debries_field + total_debris);

            if is_colony {
                self
                    .shared
                    .colony
                    .read()
                    .update_defences_after_attack(colony_mother_planet, colony_id, d);
            } else {
                self.update_defender_fleet_levels_after_attack(mission.destination, f2);
                self.update_defences_after_attack(mission.destination, d);
            }

            let (loot_spendable, loot_collectible) = self
                .calculate_loot_amount(mission.destination, f1);
            let total_loot = loot_spendable + loot_collectible;

            if !is_colony {
                self.process_loot_payment(mission.destination, loot_spendable);
            }
            self.shared.receive_resources_erc20(get_caller_address(), total_loot);

            if is_colony {
                self.shared.colony.read().reset_resource_timer(colony_mother_planet, colony_id)
            } else {
                self.shared.storage.read().update_resources_timer(mission.destination, time_now);
            }
            self.fleet_return_planet(mission.origin, f1);
            self.shared.storage.read().set_mission(origin, mission_id, Zeroable::zero());

            if is_colony {
                self
                    .shared
                    .storage
                    .read()
                    .remove_incoming_mission(colony_mother_planet, mission_id);
            } else {
                self.shared.storage.read().remove_incoming_mission(mission.destination, mission_id);
            }

            let attacker_loss = self.calculate_fleet_loss(mission.fleet, f1);
            let defender_loss = self.calculate_fleet_loss(defender_fleet, f2);
            let defences_loss = self.calculate_defences_loss(defences, d);

            self.update_points_after_attack(origin, attacker_loss, Zeroable::zero());
            if is_colony {
                self.update_points_after_attack(colony_mother_planet, defender_loss, defences_loss);
            } else {
                self.update_points_after_attack(mission.destination, defender_loss, defences_loss);
            }
            self.shared.storage.read().set_last_active(origin, time_now);
            self
                .emit_battle_report(
                    time_now,
                    origin,
                    self.shared.storage.read().get_planet_position(origin),
                    mission.fleet,
                    attacker_loss,
                    mission.destination,
                    self.shared.storage.read().get_planet_position(mission.destination),
                    defender_fleet,
                    defender_loss,
                    defences,
                    defences_loss,
                    total_loot,
                    total_debris
                );
        }

        fn recall_fleet(ref self: ContractState, mission_id: usize) {
            let origin = self.shared.get_owned_planet(get_caller_address());
            let mission = self.shared.storage.read().get_mission_details(origin, mission_id);
            assert(!mission.is_zero(), 'no fleet to recall');
            self.fleet_return_planet(mission.origin, mission.fleet);
            self.shared.storage.read().set_mission(origin, mission_id, Zeroable::zero());
            self.shared.storage.read().remove_incoming_mission(mission.destination, mission_id);
            self.shared.storage.read().set_last_active(origin, get_block_timestamp());
        }

        fn dock_fleet(ref self: ContractState, mission_id: usize) {
            let origin = self.shared.get_owned_planet(get_caller_address());
            let mission = self.shared.storage.read().get_mission_details(origin, mission_id);
            assert(mission.category == MissionCategory::TRANSPORT, 'not a transport mission');
            assert(!mission.is_zero(), 'no fleet to dock');
            self.fleet_return_planet(mission.destination, mission.fleet);
            self.shared.storage.read().set_mission(origin, mission_id, Zeroable::zero());
            self.shared.storage.read().set_last_active(origin, get_block_timestamp());
        }

        fn collect_debris(ref self: ContractState, mission_id: usize) {
            let caller = get_caller_address();
            let origin = self.shared.get_owned_planet(caller);

            let mission = self.shared.storage.read().get_mission_details(origin, mission_id);
            assert(!mission.is_zero(), 'the mission is empty');
            assert(mission.category == MissionCategory::DEBRIS, 'not a debris mission');

            let time_now = get_block_timestamp();
            assert(time_now >= mission.time_arrival, 'destination not reached yet');

            let time_since_arrived = time_now - mission.time_arrival;
            let mut collector_fleet: Fleet = mission.fleet;

            if time_since_arrived > (2 * HOUR) {
                let decay_amount = fleet::calculate_fleet_loss(time_since_arrived - (2 * HOUR));
                collector_fleet = fleet::decay_fleet(mission.fleet, decay_amount);
            }

            let debris = self.shared.storage.read().get_planet_debris_field(mission.destination);
            let storage = fleet::get_fleet_cargo_capacity(collector_fleet);
            let collectible_debris = fleet::get_collectible_debris(storage, debris);
            let new_debris = Debris {
                steel: debris.steel - collectible_debris.steel,
                quartz: debris.quartz - collectible_debris.quartz
            };

            self.shared.storage.read().set_planet_debris_field(mission.destination, new_debris);

            let erc20 = ERC20s {
                steel: collectible_debris.steel,
                quartz: collectible_debris.quartz,
                tritium: Zeroable::zero()
            };

            self.shared.receive_resources_erc20(caller, erc20);

            self.fleet_return_planet(mission.origin, collector_fleet);
            self.shared.storage.read().set_mission(origin, mission_id, Zeroable::zero());
            self.shared.storage.read().set_last_active(origin, time_now);

            self
                .emit(
                    Event::DebrisCollected(
                        DebrisCollected {
                            planet_id: origin,
                            debris_field_id: mission.destination,
                            amount: collectible_debris,
                        }
                    )
                );
        }

        fn simulate_attack(
            self: @ContractState, attacker_fleet: Fleet, defender_fleet: Fleet, defences: Defences
        ) -> SimulationResult {
            let techs: TechLevels = Default::default();
            let (f1, f2, d) = fleet::war(attacker_fleet, techs, defender_fleet, defences, techs);
            let attacker_loss = self.calculate_fleet_loss(attacker_fleet, f1);
            let defender_loss = self.calculate_fleet_loss(defender_fleet, f2);
            let defences_loss = self.calculate_defences_loss(defences, d);
            SimulationResult {
                attacker_carrier: attacker_loss.carrier,
                attacker_scraper: attacker_loss.scraper,
                attacker_sparrow: attacker_loss.sparrow,
                attacker_frigate: attacker_loss.frigate,
                attacker_armade: attacker_loss.armade,
                defender_carrier: defender_loss.carrier,
                defender_scraper: defender_loss.scraper,
                defender_sparrow: defender_loss.sparrow,
                defender_frigate: defender_loss.frigate,
                defender_armade: defender_loss.armade,
                celestia: defences_loss.celestia,
                blaster: defences_loss.blaster,
                beam: defences_loss.beam,
                astral: defences_loss.astral,
                plasma: defences_loss.plasma
            }
        }
    }

    #[generate_trait]
    impl Private of PrivateTrait {
        fn fleet_leave_planet(ref self: ContractState, planet_id: u32, fleet: Fleet) {
            if planet_id > 500 {
                let colony_mother_planet = self
                    .shared
                    .storage
                    .read()
                    .get_colony_mother_planet(planet_id);
                self
                    .shared
                    .colony
                    .read()
                    .fleet_leaves(
                        colony_mother_planet, (planet_id % 1000).try_into().unwrap(), fleet
                    );
            } else {
                let fleet_levels = self.shared.storage.read().get_ships_levels(planet_id);
                if fleet.carrier > 0 {
                    self
                        .shared
                        .storage
                        .read()
                        .set_ship_level(
                            planet_id, Names::CARRIER, fleet_levels.carrier - fleet.carrier
                        );
                }
                if fleet.scraper > 0 {
                    self
                        .shared
                        .storage
                        .read()
                        .set_ship_level(
                            planet_id, Names::SCRAPER, fleet_levels.scraper - fleet.scraper
                        );
                }
                if fleet.sparrow > 0 {
                    self
                        .shared
                        .storage
                        .read()
                        .set_ship_level(
                            planet_id, Names::SPARROW, fleet_levels.sparrow - fleet.sparrow
                        );
                }
                if fleet.frigate > 0 {
                    self
                        .shared
                        .storage
                        .read()
                        .set_ship_level(
                            planet_id, Names::FRIGATE, fleet_levels.frigate - fleet.frigate
                        );
                }
                if fleet.armade > 0 {
                    self
                        .shared
                        .storage
                        .read()
                        .set_ship_level(
                            planet_id, Names::ARMADE, fleet_levels.armade - fleet.armade
                        );
                }
            }
        }

        fn fleet_return_planet(ref self: ContractState, planet_id: u32, fleet: Fleet) {
            if planet_id > 500 {
                let colony_mother_planet = self
                    .shared
                    .storage
                    .read()
                    .get_colony_mother_planet(planet_id);
                self
                    .shared
                    .colony
                    .read()
                    .fleet_arrives(
                        colony_mother_planet, (planet_id % 1000).try_into().unwrap(), fleet
                    );
            } else {
                let fleet_levels = self.shared.storage.read().get_ships_levels(planet_id);
                if fleet.carrier > 0 {
                    self
                        .shared
                        .storage
                        .read()
                        .set_ship_level(
                            planet_id, Names::CARRIER, fleet_levels.carrier + fleet.carrier
                        );
                }
                if fleet.scraper > 0 {
                    self
                        .shared
                        .storage
                        .read()
                        .set_ship_level(
                            planet_id, Names::SCRAPER, fleet_levels.scraper + fleet.scraper
                        );
                }
                if fleet.sparrow > 0 {
                    self
                        .shared
                        .storage
                        .read()
                        .set_ship_level(
                            planet_id, Names::SPARROW, fleet_levels.sparrow + fleet.sparrow
                        );
                }
                if fleet.frigate > 0 {
                    self
                        .shared
                        .storage
                        .read()
                        .set_ship_level(
                            planet_id, Names::FRIGATE, fleet_levels.frigate + fleet.frigate
                        );
                }
                if fleet.armade > 0 {
                    self
                        .shared
                        .storage
                        .read()
                        .set_ship_level(
                            planet_id, Names::ARMADE, fleet_levels.armade + fleet.armade
                        );
                }
            }
        }

        fn check_enough_ships(self: @ContractState, planet_id: u32, colony_id: u8, fleet: Fleet) {
            if colony_id == 0 {
                let ships_levels = self.shared.storage.read().get_ships_levels(planet_id);
                assert(ships_levels.carrier >= fleet.carrier, 'not enough carrier');
                assert(ships_levels.scraper >= fleet.scraper, 'not enough scrapers');
                assert(ships_levels.sparrow >= fleet.sparrow, 'not enough sparrows');
                assert(ships_levels.frigate >= fleet.frigate, 'not enough frigates');
                assert(ships_levels.armade >= fleet.armade, 'not enough armades');
            } else {
                let ships_levels = self
                    .shared
                    .storage
                    .read()
                    .get_colony_ships(planet_id, colony_id);
                assert(ships_levels.carrier >= fleet.carrier, 'not enough carrier');
                assert(ships_levels.scraper >= fleet.scraper, 'not enough scrapers');
                assert(ships_levels.sparrow >= fleet.sparrow, 'not enough sparrows');
                assert(ships_levels.frigate >= fleet.frigate, 'not enough frigates');
                assert(ships_levels.armade >= fleet.armade, 'not enough armades');
            }
        }

        fn update_defender_fleet_levels_after_attack(
            ref self: ContractState, planet_id: u32, f: Fleet
        ) {
            self.shared.storage.read().set_ship_level(planet_id, Names::CARRIER, f.carrier);
            self.shared.storage.read().set_ship_level(planet_id, Names::SCRAPER, f.scraper);
            self.shared.storage.read().set_ship_level(planet_id, Names::SPARROW, f.sparrow);
            self.shared.storage.read().set_ship_level(planet_id, Names::FRIGATE, f.frigate);
            self.shared.storage.read().set_ship_level(planet_id, Names::ARMADE, f.armade);
        }

        fn update_defences_after_attack(ref self: ContractState, planet_id: u32, d: Defences) {
            self.shared.storage.read().set_defence_level(planet_id, Names::CELESTIA, d.celestia);
            self.shared.storage.read().set_defence_level(planet_id, Names::BLASTER, d.blaster);
            self.shared.storage.read().set_defence_level(planet_id, Names::BEAM, d.beam);
            self.shared.storage.read().set_defence_level(planet_id, Names::ASTRAL, d.astral);
            self.shared.storage.read().set_defence_level(planet_id, Names::PLASMA, d.plasma);
        }

        fn get_fleet_and_defences_before_battle(
            self: @ContractState, planet_id: u32
        ) -> (Fleet, Defences, TechLevels, u32) {
            let mut fleet: Fleet = Default::default();
            let mut defences: Defences = Default::default();
            let mut techs: TechLevels = Default::default();
            let mut celestia = 0;
            if planet_id > 500 {
                let colony_mother_planet = self
                    .shared
                    .storage
                    .read()
                    .get_colony_mother_planet(planet_id);
                defences = self
                    .shared
                    .storage
                    .read()
                    .get_colony_defences(
                        colony_mother_planet,
                        (planet_id - colony_mother_planet * 1000).try_into().unwrap()
                    );
                techs = self.shared.storage.read().get_tech_levels(colony_mother_planet);
                celestia = defences.celestia;
            } else {
                fleet = self.shared.storage.read().get_ships_levels(planet_id);
                defences = self.shared.storage.read().get_defences_levels(planet_id);
                techs = self.shared.storage.read().get_tech_levels(planet_id);
                celestia = self.shared.storage.read().get_defences_levels(planet_id).celestia;
            }
            (fleet, defences, techs, celestia)
        }

        fn calculate_loot_amount(
            self: @ContractState, destination_id: u32, attacker_fleet: Fleet
        ) -> (ERC20s, ERC20s) {
            let mut loot_collectible: ERC20s = Default::default();
            let mut loot_spendable: ERC20s = Default::default();
            let mut storage = fleet::get_fleet_cargo_capacity(attacker_fleet);
            let mut spendable: ERC20s = Default::default();
            let mut collectible: ERC20s = Default::default();

            if destination_id > 500 {
                let mother_planet = self
                    .shared
                    .storage
                    .read()
                    .get_colony_mother_planet(destination_id);
                let colony_id: u8 = (destination_id - mother_planet * 1000).try_into().unwrap();
                collectible = self
                    .shared
                    .colony
                    .read()
                    .get_colony_resources(mother_planet, colony_id);
            } else {
                let contracts = self.shared.storage.read().get_contracts();
                let compound = ICompoundDispatcher { contract_address: contracts.compound };
                spendable = compound.get_spendable_resources(destination_id);
                collectible = compound.get_collectible_resources(destination_id);
            }

            if storage < (collectible.steel + collectible.quartz + collectible.tritium) {
                loot_collectible = fleet::load_resources(collectible + spendable, storage);
            } else {
                loot_collectible = fleet::load_resources(collectible, storage);

                if !spendable.is_zero() {
                    loot_spendable.steel = spendable.steel / 2;
                    loot_spendable.quartz = spendable.quartz / 2;
                    loot_spendable.tritium = spendable.tritium / 2;
                    loot_spendable =
                        fleet::load_resources(
                            loot_spendable,
                            storage
                                - (loot_collectible.steel
                                    + loot_collectible.quartz
                                    + loot_collectible.tritium)
                        );
                }
            }
            return (loot_spendable, loot_collectible);
        }

        fn process_loot_payment(
            ref self: ContractState, destination_id: u32, loot_spendable: ERC20s,
        ) {
            let tokens = self.shared.storage.read().get_token_addresses();
            if destination_id > 500 {
                let colony_mother_planet = self
                    .shared
                    .storage
                    .read()
                    .get_colony_mother_planet(destination_id);
                let planet_owner = tokens.erc721.ownerOf(colony_mother_planet.into());
                self.shared.pay_resources_erc20(planet_owner, loot_spendable);
            } else {
                self
                    .shared
                    .pay_resources_erc20(
                        tokens.erc721.ownerOf(destination_id.into()), loot_spendable
                    );
            }
        }

        fn calculate_fleet_loss(self: @ContractState, a: Fleet, b: Fleet) -> Fleet {
            Fleet {
                carrier: a.carrier - b.carrier,
                scraper: a.scraper - b.scraper,
                sparrow: a.sparrow - b.sparrow,
                frigate: a.frigate - b.frigate,
                armade: a.armade - b.armade,
            }
        }

        fn calculate_defences_loss(self: @ContractState, a: Defences, b: Defences) -> Defences {
            Defences {
                celestia: a.celestia - b.celestia,
                blaster: a.blaster - b.blaster,
                beam: a.beam - b.beam,
                astral: a.astral - b.astral,
                plasma: a.plasma - b.plasma,
            }
        }

        fn update_points_after_attack(
            ref self: ContractState, planet_id: u32, fleet: Fleet, defences: Defences
        ) {
            if fleet.is_zero() && defences.is_zero() {
                return;
            }
            let ships_cost = dockyard::get_ships_unit_cost();
            let ships_points = fleet.carrier.into()
                * (ships_cost.carrier.steel + ships_cost.carrier.quartz)
                + fleet.scraper.into() * (ships_cost.scraper.steel + ships_cost.scraper.quartz)
                + fleet.sparrow.into() * (ships_cost.sparrow.steel + ships_cost.sparrow.quartz)
                + fleet.frigate.into() * (ships_cost.frigate.steel + ships_cost.frigate.quartz)
                + fleet.armade.into() * (ships_cost.armade.steel + ships_cost.armade.quartz);

            let defences_cost = defence::get_defences_unit_cost();
            let defences_points = defences.celestia.into() * 2000
                + defences.blaster.into()
                    * (defences_cost.blaster.steel + defences_cost.blaster.quartz)
                + defences.beam.into() * (defences_cost.beam.steel + defences_cost.beam.quartz)
                + defences.astral.into()
                    * (defences_cost.astral.steel + defences_cost.astral.quartz)
                + defences.plasma.into()
                    * (defences_cost.plasma.steel + defences_cost.plasma.quartz);

            self
                .shared
                .storage
                .read()
                .set_resources_spent(
                    planet_id,
                    self.shared.storage.read().get_resources_spent(planet_id)
                        - (ships_points + defences_points)
                );
        }

        fn emit_battle_report(
            ref self: ContractState,
            time: u64,
            attacker: u32,
            attacker_position: PlanetPosition,
            attacker_initial_fleet: Fleet,
            attacker_fleet_loss: Fleet,
            defender: u32,
            defender_position: PlanetPosition,
            defender_initial_fleet: Fleet,
            defender_fleet_loss: Fleet,
            initial_defences: Defences,
            defences_loss: Defences,
            loot: ERC20s,
            debris: Debris
        ) {
            let defender = if defender > 500 {
                self.shared.storage.read().get_colony_mother_planet(defender)
            } else {
                defender
            };
            self
                .emit(
                    Event::BattleReport(
                        BattleReport {
                            time,
                            attacker,
                            attacker_position,
                            attacker_initial_fleet,
                            attacker_fleet_loss,
                            defender,
                            defender_position,
                            defender_initial_fleet,
                            defender_fleet_loss,
                            initial_defences,
                            defences_loss,
                            loot,
                            debris
                        }
                    )
                )
        }

        fn get_fuel_consumption(
            self: @ContractState, origin: PlanetPosition, destination: PlanetPosition, fleet: Fleet
        ) -> u128 {
            let distance = fleet::get_distance(origin, destination);
            fleet::get_fuel_consumption(fleet, distance)
        }
    }
}
