use nogame::libraries::types::{
    Debris, Defences, Fleet, IncomingMission, Mission, PlanetPosition, SimulationResult,
};

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
        self: @TState, attacker_fleet: Fleet, defender_fleet: Fleet, defences: Defences,
    ) -> SimulationResult;
    fn get_active_missions(self: @TState, planet_id: u32) -> Array<Mission>;
    fn get_mission_details(self: @TState, planet_id: u32, mission_id: usize) -> Mission;
    fn get_incoming_missions(self: @TState, planet_id: u32) -> Array<IncomingMission>;
}

#[starknet::contract]
mod FleetMovements {
    use core::clone::Clone;
    use nogame::colony::contract::{IColonyDispatcher, IColonyDispatcherTrait};
    use nogame::compound::contract::{ICompoundDispatcher, ICompoundDispatcherTrait};
    use nogame::defence::contract::IDefenceDispatcherTrait;
    use nogame::defence::library as defence;
    use nogame::dockyard::contract::{IDockyardDispatcher, IDockyardDispatcherTrait};
    use nogame::dockyard::library as dockyard;
    use nogame::fleet_movements::library as fleet;
    use nogame::game::contract::{IGameDispatcher, IGameDispatcherTrait};
    use nogame::libraries::names::Names;
    use nogame::libraries::types::{
        Debris, Defences, E18, ERC20s, Fleet, HOUR, IncomingMission, Mission, MissionCategory,
        PlanetPosition, SimulationResult, TechLevels, WEEK, erc20_mul,
    };
    use nogame::planet::contract::IPlanetDispatcherTrait;
    use nogame::tech::contract::ITechDispatcherTrait;
    use nogame::token::erc20::interface::{IERC20NoGameDispatcher, IERC20NoGameDispatcherTrait};
    use nogame::token::erc721::interface::{IERC721NoGameDispatcher, IERC721NoGameDispatcherTrait};
    use openzeppelin_access::ownable::OwnableComponent;
    use starknet::storage::{
        Map, StoragePathEntry, StoragePointerReadAccess, StoragePointerWriteAccess,
    };
    use starknet::{ContractAddress, get_block_timestamp, get_caller_address, get_contract_address};


    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        game_manager: IGameDispatcher,
        active_missions: Map<(u32, u32), Mission>,
        active_missions_len: Map<u32, usize>,
        incoming_missions: Map<(u32, u32), IncomingMission>,
        incoming_missions_len: Map<u32, usize>,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        BattleReport: BattleReport,
        DebrisCollected: DebrisCollected,
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
    fn constructor(ref self: ContractState, owner: ContractAddress, game: ContractAddress) {
        self.ownable.initializer(get_caller_address());
        self.game_manager.write(IGameDispatcher { contract_address: game });
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
            let contracts = self.game_manager.read().get_contracts();
            let destination_id = contracts.planet.get_position_to_planet(destination);
            assert(!destination_id.is_zero(), 'no planet at destination');
            let caller = get_caller_address();
            let planet_id = contracts.planet.get_owned_planet(caller);
            let origin_id = if colony_id.is_zero() {
                planet_id
            } else {
                (planet_id * 1000) + colony_id.into()
            };

            if destination_id > 500 && mission_type == MissionCategory::TRANSPORT {
                assert(
                    contracts.colony.get_colony_mother_planet(destination_id) == planet_id,
                    'not your colony',
                );
            }
            if mission_type == MissionCategory::ATTACK {
                if destination_id > 500 {
                    assert(
                        contracts.colony.get_colony_mother_planet(destination_id) != planet_id,
                        'cannot attack own planet',
                    );
                } else {
                    assert(destination_id != planet_id, 'cannot attack own planet');
                }
            }
            let time_now = get_block_timestamp();

            self.check_enough_ships(planet_id, colony_id, f);
            // Calculate distance
            let distance = fleet::get_distance(
                contracts.planet.get_planet_position(origin_id), destination,
            );

            // Calculate time
            let techs = contracts.tech.get_tech_levels(planet_id);
            let speed = fleet::get_fleet_speed(f, techs);
            let travel_time = fleet::get_flight_time(speed, distance, speed_modifier);

            // Check numeber of mission
            let active_missions = self.get_active_missions(planet_id).len();
            assert(active_missions < techs.digital.into() + 1, 'max active missions');

            // Pay for fuel
            let consumption = fleet::get_fuel_consumption(f, distance)
                * 100
                / speed_modifier.into();
            let mut cost: ERC20s = Default::default();
            cost.tritium = consumption;
            contracts.game.check_enough_resources(caller, cost);
            contracts.game.pay_resources_erc20(caller, cost);

            // Write mission
            let mut mission: Mission = Default::default();
            mission.time_start = time_now;
            mission.origin = origin_id;
            mission.destination = contracts.planet.get_position_to_planet(destination);
            mission.time_arrival = time_now + travel_time;
            mission.fleet = f;

            if mission_type == MissionCategory::DEBRIS {
                assert(
                    !contracts.planet.get_planet_debris_field(destination_id).is_zero(),
                    'empty debris fiels',
                );
                assert(f.scraper >= 1, 'no scrapers for collection');
                mission.category = MissionCategory::DEBRIS;
                self.add_active_mission(planet_id, mission);
            } else if mission_type == MissionCategory::TRANSPORT {
                mission.category = MissionCategory::TRANSPORT;
                self.add_active_mission(planet_id, mission);
            } else {
                let is_inactive = time_now
                    - contracts.planet.get_last_active(destination_id) > WEEK;
                if !is_inactive {
                    assert(
                        !contracts.planet.get_is_noob_protected(planet_id, destination_id),
                        'noob protection active',
                    );
                }
                mission.category = MissionCategory::ATTACK;
                let id = self.add_active_mission(planet_id, mission);
                let mut hostile_mission: IncomingMission = Default::default();
                hostile_mission.origin = planet_id;
                hostile_mission.id_at_origin = id;
                hostile_mission.time_arrival = mission.time_arrival;
                hostile_mission
                    .number_of_ships = fleet::calculate_number_of_ships(f, Zeroable::zero());
                hostile_mission.destination = destination_id;
                let is_colony = mission.destination > 1000;
                let target_planet = if is_colony {
                    contracts.colony.get_colony_mother_planet(mission.destination)
                } else {
                    mission.destination
                };
                self.add_incoming_mission(target_planet, hostile_mission);
            }
            contracts.planet.set_last_active(planet_id);
            self.fleet_leave_planet(origin_id, f);
        }

        fn attack_planet(ref self: ContractState, mission_id: usize) {
            let caller = get_caller_address();
            let contracts = self.game_manager.read().get_contracts();
            let origin = contracts.planet.get_owned_planet(caller);
            let mut mission = self.get_mission_details(origin, mission_id);
            assert(!mission.is_zero(), 'the mission is empty');
            assert(mission.category == MissionCategory::ATTACK, 'not an attack mission');
            assert(mission.destination != origin, 'cannot attack own planet');
            let time_now = get_block_timestamp();
            assert(time_now >= mission.time_arrival, 'destination not reached yet');
            let is_colony = mission.destination > 500;
            let colony_mother_planet = if is_colony {
                contracts.colony.get_colony_mother_planet(mission.destination)
            } else {
                0
            };
            let colony_id: u8 = if is_colony {
                (mission.destination - colony_mother_planet * 1000).try_into().unwrap()
            } else {
                0
            };

            let mut t1 = contracts.tech.get_tech_levels(origin);
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
            let current_debries_field = contracts
                .planet
                .get_planet_debris_field(mission.destination);
            contracts
                .planet
                .set_planet_debris_field(mission.destination, current_debries_field + total_debris);

            if is_colony {
                contracts.colony.update_defences_after_attack(colony_mother_planet, colony_id, d);
            } else {
                self.update_defender_fleet_levels_after_attack(mission.destination, colony_id, f2);
                self.update_defences_after_attack(mission.destination, colony_id, d);
            }

            let (loot_spendable, loot_collectible) = self
                .calculate_loot_amount(mission.destination, f1);
            let total_loot = loot_spendable + loot_collectible;

            if !is_colony {
                self.process_loot_payment(mission.destination, loot_spendable);
            }
            contracts.game.receive_resources_erc20(get_caller_address(), total_loot);

            if is_colony {
                contracts.colony.set_resource_timer(colony_mother_planet, colony_id)
            } else {
                contracts.planet.set_resources_timer(mission.destination);
            }
            self.fleet_return_planet(mission.origin, f1);
            self.set_mission(origin, mission_id, Zeroable::zero());

            if is_colony {
                self.remove_incoming_mission(colony_mother_planet, mission_id);
            } else {
                self.remove_incoming_mission(mission.destination, mission_id);
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
            contracts.planet.set_last_active(origin);
            self
                .emit_battle_report(
                    time_now,
                    origin,
                    contracts.planet.get_planet_position(origin),
                    mission.fleet,
                    attacker_loss,
                    mission.destination,
                    contracts.planet.get_planet_position(mission.destination),
                    defender_fleet,
                    defender_loss,
                    defences,
                    defences_loss,
                    total_loot,
                    total_debris,
                );
        }

        fn recall_fleet(ref self: ContractState, mission_id: usize) {
            let contracts = self.game_manager.read().get_contracts();
            let origin = contracts.planet.get_owned_planet(get_caller_address());
            let mission = self.get_mission_details(origin, mission_id);
            assert(!mission.is_zero(), 'no fleet to recall');
            self.fleet_return_planet(mission.origin, mission.fleet);
            self.set_mission(origin, mission_id, Zeroable::zero());
            self.remove_incoming_mission(mission.destination, mission_id);
            contracts.planet.set_last_active(origin);
        }

        fn dock_fleet(ref self: ContractState, mission_id: usize) {
            let contracts = self.game_manager.read().get_contracts();
            let origin = contracts.planet.get_owned_planet(get_caller_address());
            let mission = self.get_mission_details(origin, mission_id);
            assert(mission.category == MissionCategory::TRANSPORT, 'not a transport mission');
            assert(!mission.is_zero(), 'no fleet to dock');
            self.fleet_return_planet(mission.destination, mission.fleet);
            self.set_mission(origin, mission_id, Zeroable::zero());
            contracts.planet.set_last_active(origin);
        }

        fn collect_debris(ref self: ContractState, mission_id: usize) {
            let contracts = self.game_manager.read().get_contracts();
            let caller = get_caller_address();
            let origin = contracts.planet.get_owned_planet(caller);

            let mission = self.get_mission_details(origin, mission_id);
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

            let debris = contracts.planet.get_planet_debris_field(mission.destination);
            let storage = fleet::get_fleet_cargo_capacity(collector_fleet);
            let collectible_debris = fleet::get_collectible_debris(storage, debris);
            let new_debris = Debris {
                steel: debris.steel - collectible_debris.steel,
                quartz: debris.quartz - collectible_debris.quartz,
            };

            contracts.planet.set_planet_debris_field(mission.destination, new_debris);

            let erc20 = ERC20s {
                steel: collectible_debris.steel,
                quartz: collectible_debris.quartz,
                tritium: Zeroable::zero(),
            };

            contracts.game.receive_resources_erc20(caller, erc20);

            self.fleet_return_planet(mission.origin, collector_fleet);
            self.set_mission(origin, mission_id, Zeroable::zero());
            contracts.planet.set_last_active(origin);

            self
                .emit(
                    Event::DebrisCollected(
                        DebrisCollected {
                            planet_id: origin,
                            debris_field_id: mission.destination,
                            amount: collectible_debris,
                        },
                    ),
                );
        }

        fn simulate_attack(
            self: @ContractState, attacker_fleet: Fleet, defender_fleet: Fleet, defences: Defences,
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
                plasma: defences_loss.plasma,
            }
        }

        fn get_active_missions(self: @ContractState, planet_id: u32) -> Array<Mission> {
            let mut arr: Array<Mission> = array![];
            let len = self.active_missions_len.read(planet_id);
            let mut i = 1;
            while i != len {
                let mission = self.active_missions.read((planet_id, i));
                if !mission.is_zero() {
                    arr.append(mission);
                }
                i += 1;
            }
            arr
        }

        fn get_incoming_missions(self: @ContractState, planet_id: u32) -> Array<IncomingMission> {
            let mut arr: Array<IncomingMission> = array![];
            let len = self.incoming_missions_len.read(planet_id);
            let mut i = 1;
            while i != len {
                let mission = self.incoming_missions.read((planet_id, i));
                if !mission.is_zero() {
                    arr.append(mission);
                }
                i += 1;
            }
            arr
        }

        fn get_mission_details(self: @ContractState, planet_id: u32, mission_id: usize) -> Mission {
            self.active_missions.read((planet_id, mission_id))
        }
    }

    #[generate_trait]
    impl Private of PrivateTrait {
        fn fleet_leave_planet(ref self: ContractState, planet_id: u32, fleet: Fleet) {
            let contracts = self.game_manager.read().get_contracts();
            if planet_id > 500 {
                let colony_mother_planet = contracts.colony.get_colony_mother_planet(planet_id);
                contracts
                    .colony
                    .fleet_leaves(
                        colony_mother_planet, (planet_id % 1000).try_into().unwrap(), fleet,
                    );
            } else {
                let fleet_levels = contracts.dockyard.get_ships_levels(planet_id);
                if fleet.carrier > 0 {
                    contracts
                        .dockyard
                        .set_ship_levels(
                            planet_id, Names::Fleet::CARRIER, fleet_levels.carrier - fleet.carrier,
                        );
                }
                if fleet.scraper > 0 {
                    contracts
                        .dockyard
                        .set_ship_levels(
                            planet_id, Names::Fleet::SCRAPER, fleet_levels.scraper - fleet.scraper,
                        );
                }
                if fleet.sparrow > 0 {
                    contracts
                        .dockyard
                        .set_ship_levels(
                            planet_id, Names::Fleet::SPARROW, fleet_levels.sparrow - fleet.sparrow,
                        );
                }
                if fleet.frigate > 0 {
                    contracts
                        .dockyard
                        .set_ship_levels(
                            planet_id, Names::Fleet::FRIGATE, fleet_levels.frigate - fleet.frigate,
                        );
                }
                if fleet.armade > 0 {
                    contracts
                        .dockyard
                        .set_ship_levels(
                            planet_id, Names::Fleet::ARMADE, fleet_levels.armade - fleet.armade,
                        );
                }
            }
        }

        fn fleet_return_planet(ref self: ContractState, planet_id: u32, fleet: Fleet) {
            let contracts = self.game_manager.read().get_contracts();
            if planet_id > 500 {
                let colony_mother_planet = contracts.colony.get_colony_mother_planet(planet_id);
                contracts
                    .colony
                    .fleet_arrives(
                        colony_mother_planet, (planet_id % 1000).try_into().unwrap(), fleet,
                    );
            } else {
                let fleet_levels = contracts.dockyard.get_ships_levels(planet_id);
                if fleet.carrier > 0 {
                    contracts
                        .dockyard
                        .set_ship_levels(
                            planet_id, Names::Fleet::CARRIER, fleet_levels.carrier + fleet.carrier,
                        );
                }
                if fleet.scraper > 0 {
                    contracts
                        .dockyard
                        .set_ship_levels(
                            planet_id, Names::Fleet::SCRAPER, fleet_levels.scraper + fleet.scraper,
                        );
                }
                if fleet.sparrow > 0 {
                    contracts
                        .dockyard
                        .set_ship_levels(
                            planet_id, Names::Fleet::SPARROW, fleet_levels.sparrow + fleet.sparrow,
                        );
                }
                if fleet.frigate > 0 {
                    contracts
                        .dockyard
                        .set_ship_levels(
                            planet_id, Names::Fleet::FRIGATE, fleet_levels.frigate + fleet.frigate,
                        );
                }
                if fleet.armade > 0 {
                    contracts
                        .dockyard
                        .set_ship_levels(
                            planet_id, Names::Fleet::ARMADE, fleet_levels.armade + fleet.armade,
                        );
                }
            }
        }

        fn check_enough_ships(self: @ContractState, planet_id: u32, colony_id: u8, fleet: Fleet) {
            let contracts = self.game_manager.read().get_contracts();
            if colony_id == 0 {
                let ships_levels = contracts.dockyard.get_ships_levels(planet_id);
                assert(ships_levels.carrier >= fleet.carrier, 'not enough carrier');
                assert(ships_levels.scraper >= fleet.scraper, 'not enough scrapers');
                assert(ships_levels.sparrow >= fleet.sparrow, 'not enough sparrows');
                assert(ships_levels.frigate >= fleet.frigate, 'not enough frigates');
                assert(ships_levels.armade >= fleet.armade, 'not enough armades');
            } else {
                let ships_levels = contracts.colony.get_colony_ships(planet_id, colony_id);
                assert(ships_levels.carrier >= fleet.carrier, 'not enough carrier');
                assert(ships_levels.scraper >= fleet.scraper, 'not enough scrapers');
                assert(ships_levels.sparrow >= fleet.sparrow, 'not enough sparrows');
                assert(ships_levels.frigate >= fleet.frigate, 'not enough frigates');
                assert(ships_levels.armade >= fleet.armade, 'not enough armades');
            }
        }

        fn update_defender_fleet_levels_after_attack(
            ref self: ContractState, planet_id: u32, colony_id: u8, f: Fleet,
        ) {
            let contracts = self.game_manager.read().get_contracts();
            if colony_id.is_zero() {
                contracts.dockyard.set_ship_levels(planet_id, Names::Fleet::CARRIER, f.carrier);
                contracts.dockyard.set_ship_levels(planet_id, Names::Fleet::SCRAPER, f.scraper);
                contracts.dockyard.set_ship_levels(planet_id, Names::Fleet::SPARROW, f.sparrow);
                contracts.dockyard.set_ship_levels(planet_id, Names::Fleet::FRIGATE, f.frigate);
                contracts.dockyard.set_ship_levels(planet_id, Names::Fleet::ARMADE, f.armade);
            } else {
                contracts
                    .colony
                    .set_colony_ship(planet_id, colony_id, Names::Fleet::CARRIER, f.carrier);
                contracts
                    .colony
                    .set_colony_ship(planet_id, colony_id, Names::Fleet::SCRAPER, f.scraper);
                contracts
                    .colony
                    .set_colony_ship(planet_id, colony_id, Names::Fleet::SPARROW, f.sparrow);
                contracts
                    .colony
                    .set_colony_ship(planet_id, colony_id, Names::Fleet::FRIGATE, f.frigate);
                contracts
                    .colony
                    .set_colony_ship(planet_id, colony_id, Names::Fleet::ARMADE, f.armade);
            }
        }

        fn update_defences_after_attack(
            ref self: ContractState, planet_id: u32, colony_id: u8, d: Defences,
        ) {
            let contracts = self.game_manager.read().get_contracts();
            if colony_id.is_zero() {
                contracts
                    .defence
                    .set_defence_level(planet_id, Names::Defence::CELESTIA, d.celestia);
                contracts.defence.set_defence_level(planet_id, Names::Defence::BLASTER, d.blaster);
                contracts.defence.set_defence_level(planet_id, Names::Defence::BEAM, d.beam);
                contracts.defence.set_defence_level(planet_id, Names::Defence::ASTRAL, d.astral);
                contracts.defence.set_defence_level(planet_id, Names::Defence::PLASMA, d.plasma);
            } else {
                contracts
                    .colony
                    .set_colony_defence(planet_id, colony_id, Names::Defence::CELESTIA, d.celestia);
                contracts
                    .colony
                    .set_colony_defence(planet_id, colony_id, Names::Defence::BLASTER, d.blaster);
                contracts
                    .colony
                    .set_colony_defence(planet_id, colony_id, Names::Defence::BEAM, d.beam);
                contracts
                    .colony
                    .set_colony_defence(planet_id, colony_id, Names::Defence::ASTRAL, d.astral);
                contracts
                    .colony
                    .set_colony_defence(planet_id, colony_id, Names::Defence::PLASMA, d.plasma);
            }
        }

        fn get_fleet_and_defences_before_battle(
            self: @ContractState, planet_id: u32,
        ) -> (Fleet, Defences, TechLevels, u32) {
            let contracts = self.game_manager.read().get_contracts();
            let mut fleet: Fleet = Default::default();
            let mut defences: Defences = Default::default();
            let mut techs: TechLevels = Default::default();
            let mut celestia = 0;
            if planet_id > 500 {
                let colony_mother_planet = contracts.colony.get_colony_mother_planet(planet_id);
                let colony_id: u8 = (planet_id - colony_mother_planet * 1000).try_into().unwrap();
                defences = contracts.colony.get_colony_defences(colony_mother_planet, colony_id);
                techs = contracts.tech.get_tech_levels(colony_mother_planet);
                fleet = contracts.colony.get_colony_ships(colony_mother_planet, colony_id).into();
                celestia = defences.celestia;
            } else {
                fleet = contracts.dockyard.get_ships_levels(planet_id).into();
                defences = contracts.defence.get_defences_levels(planet_id);
                techs = contracts.tech.get_tech_levels(planet_id);
                celestia = contracts.defence.get_defences_levels(planet_id).celestia;
            }
            (fleet, defences, techs, celestia)
        }

        fn calculate_loot_amount(
            self: @ContractState, destination_id: u32, attacker_fleet: Fleet,
        ) -> (ERC20s, ERC20s) {
            let contracts = self.game_manager.read().get_contracts();
            let mut loot_collectible: ERC20s = Default::default();
            let mut loot_spendable: ERC20s = Default::default();
            let mut storage = fleet::get_fleet_cargo_capacity(attacker_fleet);
            let mut spendable: ERC20s = Default::default();
            let mut collectible: ERC20s = Default::default();

            if destination_id > 500 {
                let mother_planet = contracts.colony.get_colony_mother_planet(destination_id);
                let colony_id: u8 = (destination_id - mother_planet * 1000).try_into().unwrap();
                collectible = contracts.colony.get_colony_resources(mother_planet, colony_id);
            } else {
                spendable = contracts.planet.get_spendable_resources(destination_id);
                collectible = contracts.planet.get_collectible_resources(destination_id);
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
                                    + loot_collectible.tritium),
                        );
                }
            }
            return (loot_spendable, loot_collectible);
        }

        fn process_loot_payment(
            ref self: ContractState, destination_id: u32, loot_spendable: ERC20s,
        ) {
            let contracts = self.game_manager.read().get_contracts();
            let tokens = contracts.game.get_tokens();
            if destination_id > 500 {
                let colony_mother_planet = contracts
                    .colony
                    .get_colony_mother_planet(destination_id);
                let planet_owner = tokens.erc721.ownerOf(colony_mother_planet.into());
                contracts.game.pay_resources_erc20(planet_owner, loot_spendable);
            } else {
                contracts
                    .game
                    .pay_resources_erc20(
                        tokens.erc721.ownerOf(destination_id.into()), loot_spendable,
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
            ref self: ContractState, planet_id: u32, fleet: Fleet, defences: Defences,
        ) {
            if fleet.is_zero() && defences.is_zero() {
                return;
            }
            let ships_cost = dockyard::get_ships_unit_cost();
            let defences_cost = defence::get_defences_unit_cost();
            let mut resources_points: ERC20s = Default::default();
            let gross_damage = erc20_mul(ships_cost.carrier, fleet.carrier.into())
                + erc20_mul(ships_cost.scraper, fleet.scraper.into())
                + erc20_mul(ships_cost.sparrow, fleet.sparrow.into())
                + erc20_mul(ships_cost.frigate, fleet.frigate.into())
                + erc20_mul(ships_cost.armade, fleet.armade.into())
                + erc20_mul(defences_cost.celestia, defences.celestia.into())
                + erc20_mul(defences_cost.blaster, defences.blaster.into())
                + erc20_mul(defences_cost.beam, defences.beam.into())
                + erc20_mul(defences_cost.astral, defences.astral.into())
                + erc20_mul(defences_cost.plasma, defences.plasma.into());
            resources_points.steel = gross_damage.steel;
            resources_points.quartz = gross_damage.quartz;

            let contracts = self.game_manager.read().get_contracts();
            contracts.planet.update_planet_points(planet_id, resources_points, true);
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
            debris: Debris,
        ) {
            let contracts = self.game_manager.read().get_contracts();
            let defender = if defender > 500 {
                contracts.colony.get_colony_mother_planet(defender)
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
                            debris,
                        },
                    ),
                )
        }

        fn get_fuel_consumption(
            self: @ContractState, origin: PlanetPosition, destination: PlanetPosition, fleet: Fleet,
        ) -> u128 {
            let distance = fleet::get_distance(origin, destination);
            fleet::get_fuel_consumption(fleet, distance)
        }

        fn add_active_mission(
            ref self: ContractState, planet_id: u32, mut mission: Mission,
        ) -> usize {
            let len = self.active_missions_len.read(planet_id);
            let mut i = 1;
            loop {
                if i > len {
                    mission.id = i.try_into().expect('add active mission fail');
                    self.active_missions.write((planet_id, i), mission);
                    self.active_missions_len.write(planet_id, i);
                    break;
                }
                let read_mission = self.active_missions.read((planet_id, i));
                if read_mission.is_zero() {
                    mission.id = i.try_into().expect('add active mission fail');
                    self.active_missions.write((planet_id, i), mission);
                    break;
                }
                i += 1;
            }
            i
        }

        fn add_incoming_mission(ref self: ContractState, planet_id: u32, mission: IncomingMission) {
            let len = self.incoming_missions_len.read(planet_id);
            let mut i = 1;
            loop {
                if i > len {
                    self.incoming_missions.write((planet_id, i), mission);
                    self.incoming_missions_len.write(planet_id, i);
                    break;
                }
                let read_mission = self.incoming_missions.read((planet_id, i));
                if read_mission.is_zero() {
                    self.incoming_missions.write((planet_id, i), mission);
                    break;
                }
                i += 1;
            };
        }

        fn remove_incoming_mission(ref self: ContractState, planet_id: u32, id_to_remove: usize) {
            let len = self.incoming_missions_len.read(planet_id);
            let mut i = 1;
            while i != len {
                let mission = self.incoming_missions.read((planet_id, i));
                if mission.id_at_origin == id_to_remove {
                    self.incoming_missions.write((planet_id, i), Zeroable::zero());
                    break;
                }
                i += 1;
            }
        }

        fn set_mission(
            ref self: ContractState, planet_id: u32, mission_id: usize, mission: Mission,
        ) {
            self.active_missions.write((planet_id, mission_id), mission);
        }
    }
}
