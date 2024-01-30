// TODOS: 
#[starknet::contract]
mod NoGame {
    use core::poseidon::poseidon_hash_span;
    use nogame::colony::colony::ColonyComponent;
    use nogame::colony::colony::IColonyView;
    use nogame::colony::colony::IColonyWrite;
    use nogame::game::interface::INoGame;

    use nogame::libraries::auction::{LinearVRGDA, LinearVRGDATrait};
    use nogame::libraries::compounds::{Compounds, CompoundCost, Consumption, Production};
    use nogame::libraries::defences::Defence;
    use nogame::libraries::dockyard::Dockyard;
    use nogame::libraries::fleet;
    use nogame::libraries::positions;
    use nogame::libraries::research::Lab;
    use nogame::libraries::types::{
        ETH_ADDRESS, BANK_ADDRESS, E18, DefencesCost, Defences, EnergyCost, ERC20s, erc20_mul,
        CompoundsCost, CompoundsLevels, ShipsLevels, ShipsCost, TechLevels, TechsCost, Tokens,
        PlanetPosition, Debris, Mission, IncomingMission, Fleet, MAX_NUMBER_OF_PLANETS, _0_05,
        PRICE, DAY, HOUR, Names, UpgradeType, BuildType, WEEK, SimulationResult, ColonyUpgradeType,
        ColonyBuildType, MissionCategory,
    };
    use nogame::storage::storage::{IStorageDispatcher, IStorageDispatcherTrait};
    use nogame::token::erc20::interface::{IERC20NoGameDispatcher, IERC20NoGameDispatcherTrait};
    use nogame::token::erc721::interface::{IERC721NoGameDispatcherTrait, IERC721NoGameDispatcher};

    use nogame_fixed::f128::types::{Fixed, FixedTrait, ONE_u128 as ONE};
    use openzeppelin::access::ownable::OwnableComponent;
    use openzeppelin::security::reentrancyguard::ReentrancyGuardComponent;
    use openzeppelin::token::erc20::interface::{IERC20CamelDispatcher, IERC20CamelDispatcherTrait};
    // Components
    use openzeppelin::upgrades::upgradeable::UpgradeableComponent;

    use snforge_std::PrintTrait;
    use starknet::{
        ContractAddress, get_block_timestamp, get_caller_address, get_contract_address,
        SyscallResultTrait, class_hash::ClassHash
    };

    component!(path: UpgradeableComponent, storage: upgradeable, event: UpgradeableEvent);
    impl UpgradableInteralImpl = UpgradeableComponent::InternalImpl<ContractState>;

    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    component!(
        path: ReentrancyGuardComponent, storage: reentrancyguard, event: ReentrancyGuardEvent
    );
    impl ReentrancyGuardInternalImpl = ReentrancyGuardComponent::InternalImpl<ContractState>;

    component!(path: ColonyComponent, storage: colony, event: ColonyEvent);
    #[abi(embed_v0)]
    impl ColonyViewImpl = ColonyComponent::ColonyView<ContractState>;
    impl ColonyWriteImpl = ColonyComponent::ColonyWrite<ContractState>;
    impl ColonyInternalImpl = ColonyComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        storage: IStorageDispatcher,
        active_missions: LegacyMap::<(u32, u32), Mission>,
        active_missions_len: LegacyMap<u32, usize>,
        hostile_missions: LegacyMap<(u32, u32), IncomingMission>,
        hostile_missions_len: LegacyMap<u32, usize>,
        #[substorage(v0)]
        upgradeable: UpgradeableComponent::Storage,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        #[substorage(v0)]
        reentrancyguard: ReentrancyGuardComponent::Storage,
        #[substorage(v0)]
        colony: ColonyComponent::Storage
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        PlanetGenerated: PlanetGenerated,
        CompoundSpent: CompoundSpent,
        TechSpent: TechSpent,
        FleetSpent: FleetSpent,
        DefenceSpent: DefenceSpent,
        FleetSent: FleetSent,
        FleetReturn: FleetReturn,
        BattleReport: BattleReport,
        DebrisCollected: DebrisCollected,
        #[flat]
        UpgradeableEvent: UpgradeableComponent::Event,
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        #[flat]
        ReentrancyGuardEvent: ReentrancyGuardComponent::Event,
        #[flat]
        ColonyEvent: ColonyComponent::Event,
    }

    #[derive(Drop, starknet::Event)]
    struct PlanetGenerated {
        id: u32,
        position: PlanetPosition,
        account: ContractAddress,
    }

    #[derive(Drop, starknet::Event)]
    struct CompoundSpent {
        planet_id: u32,
        quantity: u8,
        spent: ERC20s
    }

    #[derive(Drop, starknet::Event)]
    struct TechSpent {
        planet_id: u32,
        quantity: u8,
        spent: ERC20s
    }

    #[derive(Drop, starknet::Event)]
    struct FleetSpent {
        planet_id: u32,
        quantity: u32,
        spent: ERC20s
    }

    #[derive(Drop, starknet::Event)]
    struct DefenceSpent {
        planet_id: u32,
        quantity: u32,
        spent: ERC20s
    }

    #[derive(Drop, starknet::Event)]
    struct FleetSent {
        origin: u32,
        destination: u32,
        mission_type: u8,
        fleet: Fleet,
    }

    #[derive(Drop, starknet::Event)]
    struct FleetReturn {
        docked_at: u32,
        mission_type: u8,
        fleet: Fleet,
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
    fn constructor(ref self: ContractState) {}

    #[abi(embed_v0)]
    impl NoGame of INoGame<ContractState> {
        fn initializer(ref self: ContractState, owner: ContractAddress, storage: ContractAddress,) {
            self.ownable.initializer(owner);
            let storage_dispatcher = IStorageDispatcher { contract_address: storage };
            self.storage.write(storage_dispatcher);
        }

        fn upgrade(ref self: ContractState, impl_hash: ClassHash) {
            self.ownable.assert_only_owner();
            self.upgradeable._upgrade(impl_hash);
        }

        /////////////////////////////////////////////////////////////////////
        //                         Planet Functions                                
        /////////////////////////////////////////////////////////////////////
        fn generate_planet(ref self: ContractState) {
            let caller = get_caller_address();
            let tokens = self.storage.read().get_token_addresses();

            assert!(
                tokens.erc721.balance_of(caller).is_zero(),
                "NoGame: caller is already a planet owner"
            );

            let time_elapsed = (get_block_timestamp()
                - self.storage.read().get_universe_start_time())
                / DAY;
            let price: u256 = self.get_planet_price(time_elapsed).into();

            tokens.eth.transferFrom(caller, self.ownable.owner(), price);

            let number_of_planets = self.storage.read().get_number_of_planets();
            assert(number_of_planets != MAX_NUMBER_OF_PLANETS, 'max number of planets');
            let token_id = number_of_planets + 1;
            let position = positions::get_planet_position(token_id);

            tokens.erc721.mint(caller, token_id.into());

            self.storage.read().add_new_planet(token_id, position, number_of_planets + 1, 0);
            self.receive_resources_erc20(caller, ERC20s { steel: 500, quartz: 300, tritium: 100 });
            self
                .emit(
                    Event::PlanetGenerated(
                        PlanetGenerated { id: token_id, position, account: caller }
                    )
                );
        }

        fn generate_colony(ref self: ContractState) {
            let caller = get_caller_address();
            let planet_id = self.get_owned_planet(caller);
            let exo_tech = self.storage.read().get_tech_levels(planet_id).exocraft;
            let max_colonies = if exo_tech % 2 == 1 {
                exo_tech / 2 + 1
            } else {
                exo_tech / 2
            };
            let current_colonies = self.colony.get_planet_colony_count(planet_id);
            assert!(
                current_colonies < max_colonies,
                "NoGame: max colonies {} reached, upgrade Exocraft tech to increase max colonies",
                max_colonies
            );
            let tokens = self.storage.read().get_token_addresses();
            // TODO: integrate oracle for price
            let price: u256 = 0;
            if !price.is_zero() {
                tokens.eth.transferFrom(caller, self.ownable.owner(), price);
            }

            let (colony_id, colony_position) = self.colony.generate_colony(planet_id);
            let id = ((planet_id * 1000) + colony_id.into());
            let number_of_planets = self.storage.read().get_number_of_planets();
            self
                .storage
                .read()
                .add_new_planet(planet_id, colony_position, number_of_planets + 1, id);

            self
                .emit(
                    Event::PlanetGenerated(
                        PlanetGenerated { id, position: colony_position, account: caller }
                    )
                );
        }

        fn collect_resources(ref self: ContractState) {
            let caller = get_caller_address();
            let planet_id = self.get_owned_planet(caller);
            let colonies = self.get_planet_colonies(planet_id);
            let speed = self.storage.read().get_uni_speed();
            let mut i = 1;
            let colonies_len = colonies.len();
            let mut total_production: ERC20s = Default::default();
            loop {
                if colonies_len.is_zero() || i > colonies_len {
                    break;
                }
                let production = self
                    .colony
                    .collect_resources(speed, planet_id, i.try_into().unwrap());
                total_production = total_production + production;
                i += 1;
            };
            self.receive_resources_erc20(caller, total_production);
            self._collect_resources(get_caller_address());
        }

        fn collect_colony_resources(ref self: ContractState, colony_id: u8) {
            let caller = get_caller_address();
            let planet_id = self.get_owned_planet(caller);
            assert(!planet_id.is_zero(), 'planet does not exist');
            let speed = self.storage.read().get_uni_speed();
            let production = self.colony.collect_resources(speed, planet_id, colony_id);
            self.receive_resources_erc20(caller, production);
        }

        /////////////////////////////////////////////////////////////////////
        //                         Mines Functions                                
        /////////////////////////////////////////////////////////////////////
        fn process_compound_upgrade(ref self: ContractState, component: UpgradeType, quantity: u8) {
            let caller = get_caller_address();
            self._collect_resources(caller);
            let planet_id = self.get_owned_planet(caller);
            let cost = self.upgrade_component(caller, planet_id, component, quantity);
            self.update_planet_points(planet_id, cost);
            self.emit(CompoundSpent { planet_id: planet_id, quantity, spent: cost })
        }

        fn process_tech_upgrade(ref self: ContractState, component: UpgradeType, quantity: u8) {
            let caller = get_caller_address();
            self._collect_resources(caller);
            let planet_id = self.get_owned_planet(caller);
            let cost = self.upgrade_component(caller, planet_id, component, quantity);
            self.update_planet_points(planet_id, cost);
            self.emit(TechSpent { planet_id, quantity, spent: cost })
        }

        fn process_ship_build(ref self: ContractState, component: BuildType, quantity: u32) {
            let caller = get_caller_address();
            self._collect_resources(caller);
            let planet_id = self.get_owned_planet(caller);
            let dockyard_level = self.storage.read().get_compounds_levels(planet_id).dockyard;
            let techs = self.storage.read().get_tech_levels(planet_id);
            let cost = self
                .build_component(caller, planet_id, dockyard_level, techs, component, quantity);
            self.update_planet_points(planet_id, cost);
            self.emit(FleetSpent { planet_id, quantity, spent: cost })
        }

        fn process_defence_build(ref self: ContractState, component: BuildType, quantity: u32) {
            let caller = get_caller_address();
            self._collect_resources(caller);
            let planet_id = self.get_owned_planet(caller);
            let dockyard_level = self.storage.read().get_compounds_levels(planet_id).dockyard;
            let techs = self.storage.read().get_tech_levels(planet_id);
            let cost = self
                .build_component(caller, planet_id, dockyard_level, techs, component, quantity);
            self.update_planet_points(planet_id, cost);
            self.emit(DefenceSpent { planet_id, quantity, spent: cost })
        }

        /////////////////////////////////////////////////////////////////////
        //                         Colony Functions                                
        /////////////////////////////////////////////////////////////////////
        fn process_colony_compound_upgrade(
            ref self: ContractState, colony_id: u8, name: ColonyUpgradeType, quantity: u8
        ) {
            let caller = get_caller_address();
            self.collect_colony_resources(colony_id);
            let planet_id = self.get_owned_planet(caller);
            let cost = self.upgrade_colony_component(caller, planet_id, colony_id, name, quantity);
            self.update_planet_points(planet_id, cost);
            self.emit(CompoundSpent { planet_id, quantity, spent: cost })
        }

        fn process_colony_unit_build(
            ref self: ContractState, colony_id: u8, name: ColonyBuildType, quantity: u32,
        ) {
            let caller = get_caller_address();
            self.collect_colony_resources(colony_id);
            let planet_id = self.get_owned_planet(caller);
            let cost = self.build_colony_component(caller, planet_id, colony_id, name, quantity);
            self.update_planet_points(planet_id, cost);
            self.emit(DefenceSpent { planet_id, quantity, spent: cost })
        }

        /////////////////////////////////////////////////////////////////////
        //                         Fleet Functions                                
        /////////////////////////////////////////////////////////////////////
        fn send_fleet(
            ref self: ContractState,
            f: Fleet,
            destination: PlanetPosition,
            mission_type: u8,
            speed_modifier: u32,
            colony_id: u8,
        ) {
            let destination_id = self.get_position_slot_occupant(destination);
            assert(!destination_id.is_zero(), 'no planet at destination');
            let caller = get_caller_address();
            let planet_id = self.get_owned_planet(caller);
            let origin_id = if colony_id.is_zero() {
                planet_id
            } else {
                (planet_id * 1000) + colony_id.into()
            };

            if destination_id > 500 && mission_type == MissionCategory::TRANSPORT {
                assert(
                    self.storage.read().get_colony_mother_planet(destination_id) == planet_id,
                    'not your colony'
                );
            }
            if mission_type == MissionCategory::ATTACK {
                if destination_id > 500 {
                    assert(
                        self.storage.read().get_colony_mother_planet(destination_id) != planet_id,
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
                self.storage.read().get_planet_position(origin_id), destination
            );

            // Calculate time
            let techs = self.storage.read().get_tech_levels(planet_id);
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
            self.check_enough_resources(caller, cost);
            self.pay_resources_erc20(caller, cost);

            // Write mission
            let mut mission: Mission = Default::default();
            mission.time_start = time_now;
            mission.origin = origin_id;
            mission.destination = self.get_position_slot_occupant(destination);
            mission.time_arrival = time_now + travel_time;
            mission.fleet = f;

            if mission_type == MissionCategory::DEBRIS {
                assert(
                    !self.storage.read().get_planet_debris_field(destination_id).is_zero(),
                    'empty debris fiels'
                );
                assert(f.scraper >= 1, 'no scrapers for collection');
                mission.category = MissionCategory::DEBRIS;
                self.add_active_mission(planet_id, mission);
                self
                    .emit(
                        Event::FleetSent(
                            FleetSent {
                                origin: planet_id,
                                destination: destination_id,
                                mission_type: MissionCategory::DEBRIS,
                                fleet: f,
                            }
                        )
                    );
            } else if mission_type == MissionCategory::TRANSPORT {
                mission.category = MissionCategory::TRANSPORT;
                self.add_active_mission(planet_id, mission);
                self
                    .emit(
                        Event::FleetSent(
                            FleetSent {
                                origin: planet_id,
                                destination: destination_id,
                                mission_type: MissionCategory::TRANSPORT,
                                fleet: f,
                            }
                        )
                    );
            } else {
                let is_inactive = time_now
                    - self.storage.read().get_last_active(destination_id) > WEEK;
                if !is_inactive {
                    assert(
                        !self.is_noob_protected(planet_id, destination_id), 'noob protection active'
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
                    self.storage.read().get_colony_mother_planet(mission.destination)
                } else {
                    mission.destination
                };
                self.add_incoming_mission(target_planet, hostile_mission);
                self
                    .emit(
                        Event::FleetSent(
                            FleetSent {
                                origin: planet_id,
                                destination: destination_id,
                                mission_type: MissionCategory::ATTACK,
                                fleet: f,
                            }
                        )
                    );
            }
            self.storage.read().set_last_active(planet_id, time_now);
            // Write new fleet levels
            self.fleet_leave_planet(origin_id, f);
        }


        fn attack_planet(ref self: ContractState, mission_id: usize) {
            let caller = get_caller_address();
            let origin = self.get_owned_planet(caller);
            let mut mission = self.active_missions.read((origin, mission_id));
            assert(!mission.is_zero(), 'the mission is empty');
            assert(mission.category == MissionCategory::ATTACK, 'not an attack mission');
            assert(mission.destination != origin, 'cannot attack own planet');
            let time_now = get_block_timestamp();
            assert(time_now >= mission.time_arrival, 'destination not reached yet');
            let is_colony = mission.destination > 500;
            let colony_mother_planet = if is_colony {
                self.storage.read().get_colony_mother_planet(mission.destination)
            } else {
                0
            };
            let colony_id = if is_colony {
                (mission.destination - colony_mother_planet * 1000).try_into().unwrap()
            } else {
                0
            };

            let mut t1 = self.storage.read().get_tech_levels(origin);
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
                .storage
                .read()
                .get_planet_debris_field(mission.destination);
            self
                .storage
                .read()
                .set_planet_debris_field(mission.destination, current_debries_field + total_debris);

            if is_colony {
                self.colony.update_defences_after_attack(colony_mother_planet, colony_id, d);
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
            self.receive_resources_erc20(get_caller_address(), total_loot);

            if is_colony {
                self.colony.reset_resource_timer(colony_mother_planet, colony_id)
            } else {
                self.storage.read().update_resources_timer(mission.destination, time_now);
            }
            self.fleet_return_planet(mission.origin, f1);
            self.active_missions.write((origin, mission_id), Zeroable::zero());

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
            self.storage.read().set_last_active(origin, time_now);
            self
                .emit_battle_report(
                    time_now,
                    origin,
                    self.storage.read().get_planet_position(origin),
                    mission.fleet,
                    attacker_loss,
                    mission.destination,
                    self.storage.read().get_planet_position(mission.destination),
                    defender_fleet,
                    defender_loss,
                    defences,
                    defences_loss,
                    total_loot,
                    total_debris
                );
        }

        fn recall_fleet(ref self: ContractState, mission_id: usize) {
            let origin = self.get_owned_planet(get_caller_address());
            let mission = self.active_missions.read((origin, mission_id));
            assert(!mission.is_zero(), 'no fleet to recall');
            self.fleet_return_planet(mission.origin, mission.fleet);
            self.active_missions.write((origin, mission_id), Zeroable::zero());
            self.remove_incoming_mission(mission.destination, mission_id);
            self.storage.read().set_last_active(origin, get_block_timestamp());
            self
                .emit(
                    FleetReturn {
                        docked_at: origin, mission_type: mission.category, fleet: mission.fleet
                    }
                );
        }

        fn dock_fleet(ref self: ContractState, mission_id: usize) {
            let origin = self.get_owned_planet(get_caller_address());
            let mission = self.active_missions.read((origin, mission_id));
            assert(mission.category == MissionCategory::TRANSPORT, 'not a transport mission');
            assert(!mission.is_zero(), 'no fleet to dock');
            self.fleet_return_planet(mission.destination, mission.fleet);
            self.active_missions.write((origin, mission_id), Zeroable::zero());
            self.storage.read().set_last_active(origin, get_block_timestamp());
            self
                .emit(
                    FleetReturn {
                        docked_at: origin, mission_type: mission.category, fleet: mission.fleet
                    }
                );
        }

        fn collect_debris(ref self: ContractState, mission_id: usize) {
            let caller = get_caller_address();
            let origin = self.get_owned_planet(caller);

            let mut mission = self.active_missions.read((origin, mission_id));
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

            let debris = self.storage.read().get_planet_debris_field(mission.destination);
            let storage = fleet::get_fleet_cargo_capacity(collector_fleet);
            let collectible_debris = fleet::get_collectible_debris(storage, debris);
            let new_debris = Debris {
                steel: debris.steel - collectible_debris.steel,
                quartz: debris.quartz - collectible_debris.quartz
            };

            self.storage.read().set_planet_debris_field(mission.destination, new_debris);

            let erc20 = ERC20s {
                steel: collectible_debris.steel,
                quartz: collectible_debris.quartz,
                tritium: Zeroable::zero()
            };

            self.receive_resources_erc20(caller, erc20);

            self.fleet_return_planet(mission.origin, collector_fleet);
            self.active_missions.write((origin, mission_id), Zeroable::zero());
            self.storage.read().set_last_active(origin, time_now);

            self
                .emit(
                    FleetReturn {
                        docked_at: origin,
                        mission_type: MissionCategory::DEBRIS,
                        fleet: mission.fleet
                    }
                );

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

        /////////////////////////////////////////////////////////////////////
        //                         View Functions                                
        /////////////////////////////////////////////////////////////////////
        fn get_current_planet_price(self: @ContractState) -> u128 {
            let time_elapsed = (get_block_timestamp()
                - self.storage.read().get_universe_start_time())
                / DAY;
            self.get_planet_price(time_elapsed)
        }

        fn get_planet_colonies_count(self: @ContractState, planet_id: u32) -> u8 {
            self.colony.get_planet_colony_count(planet_id)
        }

        fn get_planet_colonies(
            self: @ContractState, planet_id: u32
        ) -> Array<(u8, PlanetPosition)> {
            self.colony.get_colonies_for_planet(planet_id)
        }

        fn get_colony_compounds(
            self: @ContractState, planet_id: u32, colony_id: u8
        ) -> CompoundsLevels {
            self.colony.get_colony_coumpounds(planet_id, colony_id)
        }

        fn get_planet_points(self: @ContractState, planet_id: u32) -> u128 {
            self.storage.read().get_resources_spent(planet_id) / 1000
        }

        fn get_spendable_resources(self: @ContractState, planet_id: u32) -> ERC20s {
            let tokens = self.storage.read().get_token_addresses();
            let planet_owner = tokens.erc721.ownerOf(planet_id.into());
            let steel = tokens.steel.balance_of(planet_owner).low / E18;
            let quartz = tokens.quartz.balance_of(planet_owner).low / E18;
            let tritium = tokens.tritium.balance_of(planet_owner).low / E18;
            ERC20s { steel: steel, quartz: quartz, tritium: tritium }
        }

        fn get_collectible_resources(self: @ContractState, planet_id: u32) -> ERC20s {
            self.calculate_production(planet_id)
        }

        fn get_colony_collectible_resources(
            self: @ContractState, planet_id: u32, colony_id: u8
        ) -> ERC20s {
            let uni_speed = self.storage.read().get_uni_speed();
            self.colony.get_colony_resources(uni_speed, planet_id, colony_id)
        }

        fn get_colony_ships_levels(self: @ContractState, planet_id: u32, colony_id: u8) -> Fleet {
            self.colony.get_colony_ships(planet_id, colony_id)
        }

        fn get_celestia_available(self: @ContractState, planet_id: u32) -> u32 {
            self.storage.read().get_defences_levels(planet_id).celestia
        }


        fn get_colony_defences_levels(
            self: @ContractState, planet_id: u32, colony_id: u8
        ) -> Defences {
            self.colony.get_colony_defences(planet_id, colony_id)
        }

        fn is_noob_protected(self: @ContractState, planet1_id: u32, planet2_id: u32) -> bool {
            let p1_points = self.get_planet_points(planet1_id);
            let p2_points = self.get_planet_points(planet2_id);
            if p1_points > p2_points {
                return p1_points > p2_points * 5;
            } else {
                return p2_points > p1_points * 5;
            }
        }

        fn get_mission_details(self: @ContractState, planet_id: u32, mission_id: usize) -> Mission {
            self.active_missions.read((planet_id, mission_id))
        }

        fn get_active_missions(self: @ContractState, planet_id: u32) -> Array<Mission> {
            let mut arr: Array<Mission> = array![];
            let len = self.active_missions_len.read(planet_id);
            let mut i = 1;
            loop {
                if i > len {
                    break;
                }
                let mission = self.active_missions.read((planet_id, i));
                if !mission.is_zero() {
                    arr.append(mission);
                }
                i += 1;
            };
            arr
        }

        fn get_incoming_missions(self: @ContractState, planet_id: u32) -> Array<IncomingMission> {
            let mut arr: Array<IncomingMission> = array![];
            let len = self.hostile_missions_len.read(planet_id);
            let mut i = 1;
            loop {
                if i > len {
                    break;
                }
                let mission = self.hostile_missions.read((planet_id, i));
                if !mission.is_zero() {
                    arr.append(mission);
                }
                i += 1;
            };
            arr
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
    impl InternalImpl of InternalTrait {
        fn get_owned_planet(self: @ContractState, caller: ContractAddress) -> u32 {
            let tokens = self.storage.read().get_token_addresses();
            tokens.erc721.token_of(caller).try_into().expect('get_owned_planet fail')
        }
        fn get_position_slot_occupant(self: @ContractState, position: PlanetPosition) -> u32 {
            self.storage.read().get_position_to_planet(position)
        }

        fn process_loot_payment(
            ref self: ContractState, destination_id: u32, loot_spendable: ERC20s,
        ) {
            let tokens = self.storage.read().get_token_addresses();
            if destination_id > 500 {
                let colony_mother_planet = self
                    .storage
                    .read()
                    .get_colony_mother_planet(destination_id);
                let planet_owner = tokens.erc721.ownerOf(colony_mother_planet.into());
                self.pay_resources_erc20(planet_owner, loot_spendable);
            } else {
                self
                    .pay_resources_erc20(
                        tokens.erc721.ownerOf(destination_id.into()), loot_spendable
                    );
            }
        }

        fn get_celestia_production(self: @ContractState, planet_id: u32) -> u32 {
            let position = self.storage.read().get_planet_position(planet_id);
            self.position_to_celestia_production(position.orbit)
        }

        fn get_fleet_and_defences_before_battle(
            self: @ContractState, planet_id: u32
        ) -> (Fleet, Defences, TechLevels, u32) {
            let mut fleet: Fleet = Default::default();
            let mut defences: Defences = Default::default();
            let mut techs: TechLevels = Default::default();
            let mut celestia = 0;
            if planet_id > 500 {
                let colony_mother_planet = self.storage.read().get_colony_mother_planet(planet_id);
                defences = self
                    .get_colony_defences_levels(
                        colony_mother_planet,
                        (planet_id - colony_mother_planet * 1000).try_into().unwrap()
                    );
                techs = self.storage.read().get_tech_levels(colony_mother_planet);
                celestia = defences.celestia;
            } else {
                fleet = self.storage.read().get_ships_levels(planet_id);
                defences = self.storage.read().get_defences_levels(planet_id);
                techs = self.storage.read().get_tech_levels(planet_id);
                celestia = self.get_celestia_available(planet_id);
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
                let mother_planet = self.storage.read().get_colony_mother_planet(destination_id);
                let uni_speed = self.storage.read().get_uni_speed();
                let colony_id: u8 = (destination_id - mother_planet * 1000).try_into().unwrap();
                collectible = self.colony.get_colony_resources(uni_speed, mother_planet, colony_id);
            } else {
                spendable = self.get_spendable_resources(destination_id);
                collectible = self.get_collectible_resources(destination_id);
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

        fn get_planet_price(self: @ContractState, time_elapsed: u64) -> u128 {
            let auction = LinearVRGDA {
                target_price: FixedTrait::new(self.storage.read().get_token_price(), false),
                decay_constant: FixedTrait::new(_0_05, true),
                per_time_unit: FixedTrait::new_unscaled(10, false),
            };
            let planet_sold: u128 = self.storage.read().get_number_of_planets().into();
            auction
                .get_vrgda_price(
                    FixedTrait::new_unscaled(time_elapsed.into(), false),
                    FixedTrait::new_unscaled(planet_sold, false)
                )
                .mag
                * E18
                / ONE
        }

        fn _collect_resources(ref self: ContractState, caller: ContractAddress) {
            let planet_id = self.get_owned_planet(caller);
            assert(!planet_id.is_zero(), 'planet does not exist');
            let production = self.calculate_production(planet_id);
            self.receive_resources_erc20(caller, production);
            self.storage.read().update_resources_timer(planet_id, get_block_timestamp());
        }

        fn get_erc20s_available(self: @ContractState, caller: ContractAddress) -> ERC20s {
            let tokens = self.storage.read().get_token_addresses();
            let steel = tokens.steel.balance_of(caller);
            let quartz = tokens.quartz.balance_of(caller);
            let tritium = tokens.tritium.balance_of(caller);

            ERC20s {
                steel: steel.try_into().unwrap(),
                quartz: quartz.try_into().unwrap(),
                tritium: tritium.try_into().unwrap()
            }
        }

        fn calculate_production(self: @ContractState, planet_id: u32) -> ERC20s {
            let time_now = get_block_timestamp();
            let last_collection_time = self.storage.read().get_resources_timer(planet_id);
            let time_elapsed = time_now - last_collection_time;
            let mines_levels = self.storage.read().get_compounds_levels(planet_id);
            let position = self.storage.read().get_planet_position(planet_id);
            let temp = self.calculate_avg_temperature(position.orbit);
            let speed = self.storage.read().get_uni_speed();
            let steel_available = Production::steel(mines_levels.steel)
                * speed
                * time_elapsed.into()
                / HOUR.into();

            let quartz_available = Production::quartz(mines_levels.quartz)
                * speed
                * time_elapsed.into()
                / HOUR.into();

            let tritium_available = Production::tritium(mines_levels.tritium, temp, speed)
                * time_elapsed.into()
                / HOUR.into();
            let energy_available = Production::energy(mines_levels.energy);
            let celestia_production = self.get_celestia_production(planet_id);
            let celestia_available = self.get_celestia_available(planet_id);
            let energy_required = Consumption::base(mines_levels.steel)
                + Consumption::base(mines_levels.quartz)
                + Consumption::base(mines_levels.tritium);
            if energy_available
                + (celestia_production.into() * celestia_available).into() < energy_required {
                let _steel = Compounds::production_scaler(
                    steel_available, energy_available, energy_required
                );
                let _quartz = Compounds::production_scaler(
                    quartz_available, energy_available, energy_required
                );
                let _tritium = Compounds::production_scaler(
                    tritium_available, energy_available, energy_required
                );

                return ERC20s { steel: _steel, quartz: _quartz, tritium: _tritium, };
            }

            ERC20s { steel: steel_available, quartz: quartz_available, tritium: tritium_available, }
        }

        fn receive_resources_erc20(self: @ContractState, to: ContractAddress, amounts: ERC20s) {
            let tokens = self.storage.read().get_token_addresses();
            tokens.steel.mint(to, (amounts.steel * E18).into());
            tokens.quartz.mint(to, (amounts.quartz * E18).into());
            tokens.tritium.mint(to, (amounts.tritium * E18).into());
        }

        fn pay_resources_erc20(self: @ContractState, account: ContractAddress, amounts: ERC20s) {
            let tokens = self.storage.read().get_token_addresses();
            tokens.steel.burn(account, (amounts.steel * E18).into());
            tokens.quartz.burn(account, (amounts.quartz * E18).into());
            tokens.tritium.burn(account, (amounts.tritium * E18).into());
        }

        fn check_enough_resources(self: @ContractState, caller: ContractAddress, amounts: ERC20s) {
            let available: ERC20s = self.get_erc20s_available(caller);
            assert(amounts.steel <= available.steel / E18, 'Not enough steel');
            assert(amounts.quartz <= available.quartz / E18, 'Not enough quartz');
            assert(amounts.tritium <= available.tritium / E18, 'Not enough tritium');
        }

        fn update_planet_points(ref self: ContractState, planet_id: u32, spent: ERC20s) {
            self.storage.read().set_last_active(planet_id, get_block_timestamp());
            self
                .storage
                .read()
                .set_resources_spent(
                    planet_id,
                    self.storage.read().get_resources_spent(planet_id) + spent.steel + spent.quartz
                );
        }

        fn get_ships_cost(self: @ContractState) -> ShipsCost {
            ShipsCost {
                carrier: ERC20s { steel: 2000, quartz: 2000, tritium: 0 },
                celestia: ERC20s { steel: 0, quartz: 2000, tritium: 500 },
                scraper: ERC20s { steel: 10000, quartz: 6000, tritium: 2000 },
                sparrow: ERC20s { steel: 3000, quartz: 1000, tritium: 0 },
                frigate: ERC20s { steel: 20000, quartz: 7000, tritium: 2000 },
                armade: ERC20s { steel: 45000, quartz: 15000, tritium: 0 }
            }
        }

        fn get_defences_cost(self: @ContractState) -> DefencesCost {
            DefencesCost {
                blaster: ERC20s { steel: 2000, quartz: 0, tritium: 0 },
                beam: ERC20s { steel: 6000, quartz: 2000, tritium: 0 },
                astral: ERC20s { steel: 20000, quartz: 15000, tritium: 2000 },
                plasma: ERC20s { steel: 50000, quartz: 50000, tritium: 30000 },
            }
        }

        fn fleet_leave_planet(ref self: ContractState, planet_id: u32, fleet: Fleet) {
            if planet_id > 500 {
                let colony_mother_planet = self.storage.read().get_colony_mother_planet(planet_id);
                self
                    .colony
                    .fleet_leaves(
                        colony_mother_planet, (planet_id % 1000).try_into().unwrap(), fleet
                    );
            } else {
                let fleet_levels = self.storage.read().get_ships_levels(planet_id);
                if fleet.carrier > 0 {
                    self
                        .storage
                        .read()
                        .set_ship_level(
                            planet_id, Names::CARRIER, fleet_levels.carrier - fleet.carrier
                        );
                }
                if fleet.scraper > 0 {
                    self
                        .storage
                        .read()
                        .set_ship_level(
                            planet_id, Names::SCRAPER, fleet_levels.scraper - fleet.scraper
                        );
                }
                if fleet.sparrow > 0 {
                    self
                        .storage
                        .read()
                        .set_ship_level(
                            planet_id, Names::SPARROW, fleet_levels.sparrow - fleet.sparrow
                        );
                }
                if fleet.frigate > 0 {
                    self
                        .storage
                        .read()
                        .set_ship_level(
                            planet_id, Names::FRIGATE, fleet_levels.frigate - fleet.frigate
                        );
                }
                if fleet.armade > 0 {
                    self
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
                let colony_mother_planet = self.storage.read().get_colony_mother_planet(planet_id);
                self
                    .colony
                    .fleet_arrives(
                        colony_mother_planet, (planet_id % 1000).try_into().unwrap(), fleet
                    );
            } else {
                let fleet_levels = self.storage.read().get_ships_levels(planet_id);
                if fleet.carrier > 0 {
                    self
                        .storage
                        .read()
                        .set_ship_level(
                            planet_id, Names::CARRIER, fleet_levels.carrier + fleet.carrier
                        );
                }
                if fleet.scraper > 0 {
                    self
                        .storage
                        .read()
                        .set_ship_level(
                            planet_id, Names::SCRAPER, fleet_levels.scraper + fleet.scraper
                        );
                }
                if fleet.sparrow > 0 {
                    self
                        .storage
                        .read()
                        .set_ship_level(
                            planet_id, Names::SPARROW, fleet_levels.sparrow + fleet.sparrow
                        );
                }
                if fleet.frigate > 0 {
                    self
                        .storage
                        .read()
                        .set_ship_level(
                            planet_id, Names::FRIGATE, fleet_levels.frigate + fleet.frigate
                        );
                }
                if fleet.armade > 0 {
                    self
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
                let ships_levels = self.storage.read().get_ships_levels(planet_id);
                assert(ships_levels.carrier >= fleet.carrier, 'not enough carrier');
                assert(ships_levels.scraper >= fleet.scraper, 'not enough scrapers');
                assert(ships_levels.sparrow >= fleet.sparrow, 'not enough sparrows');
                assert(ships_levels.frigate >= fleet.frigate, 'not enough frigates');
                assert(ships_levels.armade >= fleet.armade, 'not enough armades');
            } else {
                let ships_levels = self.get_colony_ships_levels(planet_id, colony_id);
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
            self.storage.read().set_ship_level(planet_id, Names::CARRIER, f.carrier);
            self.storage.read().set_ship_level(planet_id, Names::SCRAPER, f.scraper);
            self.storage.read().set_ship_level(planet_id, Names::SPARROW, f.sparrow);
            self.storage.read().set_ship_level(planet_id, Names::FRIGATE, f.frigate);
            self.storage.read().set_ship_level(planet_id, Names::ARMADE, f.armade);
        }

        fn update_defences_after_attack(ref self: ContractState, planet_id: u32, d: Defences) {
            self.storage.read().set_defence_level(planet_id, Names::CELESTIA, d.celestia);
            self.storage.read().set_defence_level(planet_id, Names::BLASTER, d.blaster);
            self.storage.read().set_defence_level(planet_id, Names::BEAM, d.beam);
            self.storage.read().set_defence_level(planet_id, Names::ASTRAL, d.astral);
            self.storage.read().set_defence_level(planet_id, Names::PLASMA, d.plasma);
        }

        fn add_active_mission(
            ref self: ContractState, planet_id: u32, mut mission: Mission
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
            };
            i
        }

        fn add_incoming_mission(ref self: ContractState, planet_id: u32, mission: IncomingMission) {
            let len = self.hostile_missions_len.read(planet_id);
            let mut i = 1;
            loop {
                if i > len {
                    self.hostile_missions.write((planet_id, i), mission);
                    self.hostile_missions_len.write(planet_id, i);
                    break;
                }
                let read_mission = self.hostile_missions.read((planet_id, i));
                if read_mission.is_zero() {
                    self.hostile_missions.write((planet_id, i), mission);
                    break;
                }
                i += 1;
            };
        }

        fn remove_incoming_mission(ref self: ContractState, planet_id: u32, id_to_remove: usize) {
            let len = self.hostile_missions_len.read(planet_id);
            let mut i = 1;
            loop {
                if i > len {
                    break;
                }
                let mission = self.hostile_missions.read((planet_id, i));
                if mission.id_at_origin == id_to_remove {
                    self.hostile_missions.write((planet_id, i), Zeroable::zero());
                    break;
                }
                i += 1;
            }
        }

        fn position_to_celestia_production(self: @ContractState, orbit: u8) -> u32 {
            if orbit == 1 {
                return 48;
            }
            if orbit == 2 {
                return 41;
            }
            if orbit == 3 {
                return 36;
            }
            if orbit == 4 {
                return 32;
            }
            if orbit == 5 {
                return 27;
            }
            if orbit == 6 {
                return 24;
            }
            if orbit == 7 {
                return 21;
            }
            if orbit == 8 {
                return 17;
            }
            if orbit == 9 {
                return 14;
            } else {
                return 11;
            }
        }

        fn calculate_avg_temperature(self: @ContractState, orbit: u8) -> u32 {
            if orbit == 1 {
                return 230;
            }
            if orbit == 2 {
                return 170;
            }
            if orbit == 3 {
                return 120;
            }
            if orbit == 4 {
                return 70;
            }
            if orbit == 5 {
                return 60;
            }
            if orbit == 6 {
                return 50;
            }
            if orbit == 7 {
                return 40;
            }
            if orbit == 8 {
                return 40;
            }
            if orbit == 9 {
                return 20;
            } else {
                return 10;
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
                self.storage.read().get_colony_mother_planet(defender)
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

        fn update_points_after_attack(
            ref self: ContractState, planet_id: u32, fleet: Fleet, defences: Defences
        ) {
            if fleet.is_zero() && defences.is_zero() {
                return;
            }
            let ships_cost = self.get_ships_cost();
            let ships_points = fleet.carrier.into()
                * (ships_cost.carrier.steel + ships_cost.carrier.quartz)
                + fleet.scraper.into() * (ships_cost.scraper.steel + ships_cost.scraper.quartz)
                + fleet.sparrow.into() * (ships_cost.sparrow.steel + ships_cost.sparrow.quartz)
                + fleet.frigate.into() * (ships_cost.frigate.steel + ships_cost.frigate.quartz)
                + fleet.armade.into() * (ships_cost.armade.steel + ships_cost.armade.quartz);

            let defences_cost = self.get_defences_cost();
            let defences_points = defences.celestia.into() * 2000
                + defences.blaster.into()
                    * (defences_cost.blaster.steel + defences_cost.blaster.quartz)
                + defences.beam.into() * (defences_cost.beam.steel + defences_cost.beam.quartz)
                + defences.astral.into()
                    * (defences_cost.astral.steel + defences_cost.astral.quartz)
                + defences.plasma.into()
                    * (defences_cost.plasma.steel + defences_cost.plasma.quartz);

            self
                .storage
                .read()
                .set_resources_spent(
                    planet_id,
                    self.storage.read().get_resources_spent(planet_id)
                        - (ships_points + defences_points)
                );
        }

        fn get_fuel_consumption(
            self: @ContractState, origin: PlanetPosition, destination: PlanetPosition, fleet: Fleet
        ) -> u128 {
            let distance = fleet::get_distance(origin, destination);
            fleet::get_fuel_consumption(fleet, distance)
        }

        fn upgrade_component(
            ref self: ContractState,
            caller: ContractAddress,
            planet_id: u32,
            component: UpgradeType,
            quantity: u8
        ) -> ERC20s {
            let is_testnet = self.storage.read().get_is_testnet();
            let compound_levels = self.storage.read().get_compounds_levels(planet_id);
            let techs = self.storage.read().get_tech_levels(planet_id);
            match component {
                UpgradeType::SteelMine => {
                    let cost: ERC20s = CompoundCost::steel(compound_levels.steel, quantity);
                    self.check_enough_resources(caller, cost);
                    self.pay_resources_erc20(caller, cost);
                    self
                        .storage
                        .read()
                        .set_compound_level(
                            planet_id,
                            Names::STEEL,
                            compound_levels.steel + quantity.try_into().expect('u32 into u8 failed')
                        );
                    return cost;
                },
                UpgradeType::QuartzMine => {
                    let cost: ERC20s = CompoundCost::quartz(compound_levels.quartz, quantity);
                    self.check_enough_resources(caller, cost);
                    self.pay_resources_erc20(caller, cost);
                    self
                        .storage
                        .read()
                        .set_compound_level(
                            planet_id,
                            Names::QUARTZ,
                            compound_levels.quartz
                                + quantity.try_into().expect('u32 into u8 failed')
                        );
                    return cost;
                },
                UpgradeType::TritiumMine => {
                    let cost: ERC20s = CompoundCost::tritium(compound_levels.tritium, quantity);
                    self.check_enough_resources(caller, cost);
                    self.pay_resources_erc20(caller, cost);
                    self
                        .storage
                        .read()
                        .set_compound_level(
                            planet_id,
                            Names::TRITIUM,
                            compound_levels.tritium
                                + quantity.try_into().expect('u32 into u8 failed')
                        );
                    return cost;
                },
                UpgradeType::EnergyPlant => {
                    let cost: ERC20s = CompoundCost::energy(compound_levels.energy, quantity);
                    self.check_enough_resources(caller, cost);
                    self.pay_resources_erc20(caller, cost);
                    self
                        .storage
                        .read()
                        .set_compound_level(
                            planet_id,
                            Names::ENERGY_PLANT,
                            compound_levels.energy
                                + quantity.try_into().expect('u32 into u8 failed')
                        );
                    return cost;
                },
                UpgradeType::Lab => {
                    let cost: ERC20s = CompoundCost::lab(compound_levels.lab, quantity);
                    self.check_enough_resources(caller, cost);
                    self.pay_resources_erc20(caller, cost);
                    self
                        .storage
                        .read()
                        .set_compound_level(
                            planet_id,
                            Names::LAB,
                            compound_levels.lab + quantity.try_into().expect('u32 into u8 failed')
                        );
                    return cost;
                },
                UpgradeType::Dockyard => {
                    let cost: ERC20s = CompoundCost::dockyard(compound_levels.dockyard, quantity);
                    self.check_enough_resources(caller, cost);
                    self.pay_resources_erc20(caller, cost);
                    self
                        .storage
                        .read()
                        .set_compound_level(
                            planet_id,
                            Names::DOCKYARD,
                            compound_levels.dockyard
                                + quantity.try_into().expect('u32 into u8 failed')
                        );
                    return cost;
                },
                UpgradeType::EnergyTech => {
                    Lab::energy_innovation_requirements_check(compound_levels.lab, techs);
                    let base_cost: ERC20s = Lab::base_tech_costs().energy;
                    let cost = Lab::get_tech_cost(techs.energy, quantity, base_cost);
                    self.check_enough_resources(caller, cost);
                    self.pay_resources_erc20(caller, cost);
                    self
                        .storage
                        .read()
                        .set_tech_level(
                            planet_id,
                            Names::ENERGY_TECH,
                            techs.energy + quantity.try_into().expect('u32 into u8 failed')
                        );
                    return cost;
                },
                UpgradeType::Digital => {
                    Lab::digital_systems_requirements_check(compound_levels.lab, techs);
                    let base_cost: ERC20s = Lab::base_tech_costs().digital;
                    let cost = Lab::get_tech_cost(techs.digital, quantity, base_cost);
                    self.check_enough_resources(caller, cost);
                    self.pay_resources_erc20(caller, cost);
                    self
                        .storage
                        .read()
                        .set_tech_level(
                            planet_id,
                            Names::DIGITAL,
                            techs.digital + quantity.try_into().expect('u32 into u8 failed')
                        );
                    return cost;
                },
                UpgradeType::BeamTech => {
                    Lab::beam_technology_requirements_check(compound_levels.lab, techs);
                    let base_cost: ERC20s = Lab::base_tech_costs().beam;
                    let cost = Lab::get_tech_cost(techs.beam, quantity, base_cost);
                    self.check_enough_resources(caller, cost);
                    self.pay_resources_erc20(caller, cost);
                    self
                        .storage
                        .read()
                        .set_tech_level(
                            planet_id,
                            Names::BEAM_TECH,
                            techs.beam + quantity.try_into().expect('u32 into u8 failed')
                        );
                    return cost;
                },
                UpgradeType::Armour => {
                    Lab::armour_innovation_requirements_check(compound_levels.lab, techs);
                    let base_cost: ERC20s = Lab::base_tech_costs().armour;
                    let cost = Lab::get_tech_cost(techs.armour, quantity, base_cost);
                    self.check_enough_resources(caller, cost);
                    self.pay_resources_erc20(caller, cost);
                    self
                        .storage
                        .read()
                        .set_tech_level(
                            planet_id,
                            Names::ARMOUR,
                            techs.armour + quantity.try_into().expect('u32 into u8 failed')
                        );
                    return cost;
                },
                UpgradeType::Ion => {
                    assert!(!is_testnet, "NoGame: Ion tech not available on testnet realease");
                    Lab::ion_systems_requirements_check(compound_levels.lab, techs);
                    let base_cost: ERC20s = Lab::base_tech_costs().ion;
                    let cost = Lab::get_tech_cost(techs.ion, quantity, base_cost);
                    self.check_enough_resources(caller, cost);
                    self.pay_resources_erc20(caller, cost);
                    self
                        .storage
                        .read()
                        .set_tech_level(
                            planet_id,
                            Names::ION,
                            techs.ion + quantity.try_into().expect('u32 into u8 failed')
                        );
                    return cost;
                },
                UpgradeType::PlasmaTech => {
                    assert!(!is_testnet, "NoGame: Plasma tech not available on testnet realease");
                    Lab::plasma_engineering_requirements_check(compound_levels.lab, techs);
                    let base_cost: ERC20s = Lab::base_tech_costs().plasma;
                    let cost = Lab::get_tech_cost(techs.plasma, quantity, base_cost);
                    self.check_enough_resources(caller, cost);
                    self.pay_resources_erc20(caller, cost);
                    self
                        .storage
                        .read()
                        .set_tech_level(
                            planet_id,
                            Names::PLASMA_TECH,
                            techs.plasma + quantity.try_into().expect('u32 into u8 failed')
                        );
                    return cost;
                },
                UpgradeType::Weapons => {
                    Lab::weapons_development_requirements_check(compound_levels.lab, techs);
                    let base_cost: ERC20s = Lab::base_tech_costs().weapons;
                    let cost = Lab::get_tech_cost(techs.weapons, quantity, base_cost);
                    self.check_enough_resources(caller, cost);
                    self.pay_resources_erc20(caller, cost);
                    self
                        .storage
                        .read()
                        .set_tech_level(
                            planet_id,
                            Names::WEAPONS,
                            techs.weapons + quantity.try_into().expect('u32 into u8 failed')
                        );
                    return cost;
                },
                UpgradeType::Shield => {
                    Lab::shield_tech_requirements_check(compound_levels.lab, techs);
                    let base_cost: ERC20s = Lab::base_tech_costs().shield;
                    let cost = Lab::get_tech_cost(techs.shield, quantity, base_cost);
                    self.check_enough_resources(caller, cost);
                    self.pay_resources_erc20(caller, cost);
                    self
                        .storage
                        .read()
                        .set_tech_level(
                            planet_id,
                            Names::SHIELD,
                            techs.shield + quantity.try_into().expect('u32 into u8 failed')
                        );
                    return cost;
                },
                UpgradeType::Spacetime => {
                    assert!(!is_testnet, "NoGame: Space tech not available on testnet realease");
                    Lab::spacetime_warp_requirements_check(compound_levels.lab, techs);
                    let base_cost: ERC20s = Lab::base_tech_costs().spacetime;
                    let cost = Lab::get_tech_cost(techs.spacetime, quantity, base_cost);
                    self.check_enough_resources(caller, cost);
                    self.pay_resources_erc20(caller, cost);
                    self
                        .storage
                        .read()
                        .set_tech_level(
                            planet_id,
                            Names::SPACETIME,
                            techs.spacetime + quantity.try_into().expect('u32 into u8 failed')
                        );
                    return cost;
                },
                UpgradeType::Combustion => {
                    Lab::combustive_engine_requirements_check(compound_levels.lab, techs);
                    let base_cost: ERC20s = Lab::base_tech_costs().combustion;
                    let cost = Lab::get_tech_cost(techs.combustion, quantity, base_cost);
                    self.check_enough_resources(caller, cost);
                    self.pay_resources_erc20(caller, cost);
                    self
                        .storage
                        .read()
                        .set_tech_level(
                            planet_id,
                            Names::COMBUSTION,
                            techs.combustion + quantity.try_into().expect('u32 into u8 failed')
                        );
                    return cost;
                },
                UpgradeType::Thrust => {
                    Lab::thrust_propulsion_requirements_check(compound_levels.lab, techs);
                    let base_cost: ERC20s = Lab::base_tech_costs().thrust;
                    let cost = Lab::get_tech_cost(techs.thrust, quantity, base_cost);
                    self.check_enough_resources(caller, cost);
                    self.pay_resources_erc20(caller, cost);
                    self
                        .storage
                        .read()
                        .set_tech_level(
                            planet_id,
                            Names::THRUST,
                            techs.thrust + quantity.try_into().expect('u32 into u8 failed')
                        );
                    return cost;
                },
                UpgradeType::Warp => {
                    assert!(!is_testnet, "NoGame: Warp tech not available on testnet realease");
                    Lab::warp_drive_requirements_check(compound_levels.lab, techs);
                    let base_cost: ERC20s = Lab::base_tech_costs().warp;
                    let cost = Lab::get_tech_cost(techs.warp, quantity, base_cost);
                    self.check_enough_resources(caller, cost);
                    self.pay_resources_erc20(caller, cost);
                    self
                        .storage
                        .read()
                        .set_tech_level(
                            planet_id,
                            Names::WARP,
                            techs.warp + quantity.try_into().expect('u32 into u8 failed')
                        );
                    return cost;
                },
                UpgradeType::Exocraft => {
                    Lab::exocraft_requirements_check(compound_levels.lab, techs);
                    let cost = Lab::exocraft_cost(techs.exocraft, quantity);
                    self.check_enough_resources(caller, cost);
                    self.pay_resources_erc20(caller, cost);
                    self
                        .storage
                        .read()
                        .set_tech_level(
                            planet_id,
                            Names::EXOCRAFT,
                            techs.exocraft + quantity.try_into().expect('u32 into u8 failed')
                        );
                    return cost;
                },
            }
        }

        fn build_component(
            ref self: ContractState,
            caller: ContractAddress,
            planet_id: u32,
            dockyard_level: u8,
            techs: TechLevels,
            component: BuildType,
            quantity: u32
        ) -> ERC20s {
            let is_testnet = self.storage.read().get_is_testnet();
            let techs = self.storage.read().get_tech_levels(planet_id);
            let ships_levels = self.storage.read().get_ships_levels(planet_id);
            let defences_levels = self.storage.read().get_defences_levels(planet_id);
            match component {
                BuildType::Carrier => {
                    Dockyard::carrier_requirements_check(dockyard_level, techs);
                    let cost = Dockyard::get_ships_cost(quantity, self.get_ships_cost().carrier);
                    self.check_enough_resources(caller, cost);
                    self.pay_resources_erc20(caller, cost);
                    self
                        .storage
                        .read()
                        .set_ship_level(planet_id, Names::CARRIER, ships_levels.carrier + quantity);
                    return cost;
                },
                BuildType::Scraper => {
                    Dockyard::scraper_requirements_check(dockyard_level, techs);
                    let cost = Dockyard::get_ships_cost(quantity, self.get_ships_cost().scraper);
                    self.check_enough_resources(caller, cost);
                    self.pay_resources_erc20(caller, cost);
                    self
                        .storage
                        .read()
                        .set_ship_level(planet_id, Names::SCRAPER, ships_levels.scraper + quantity);
                    return cost;
                },
                BuildType::Celestia => {
                    Dockyard::celestia_requirements_check(dockyard_level, techs);
                    let cost = Dockyard::get_ships_cost(quantity, self.get_ships_cost().celestia);
                    self.check_enough_resources(caller, cost);
                    self.pay_resources_erc20(caller, cost);
                    self
                        .storage
                        .read()
                        .set_defence_level(
                            planet_id, Names::CELESTIA, defences_levels.celestia + quantity
                        );
                    return cost;
                },
                BuildType::Sparrow => {
                    Dockyard::sparrow_requirements_check(dockyard_level, techs);
                    let cost = Dockyard::get_ships_cost(quantity, self.get_ships_cost().sparrow);
                    self.check_enough_resources(caller, cost);
                    self.pay_resources_erc20(caller, cost);
                    self
                        .storage
                        .read()
                        .set_ship_level(planet_id, Names::SPARROW, ships_levels.sparrow + quantity);
                    return cost;
                },
                BuildType::Frigate => {
                    assert!(!is_testnet, "NoGame: Frigate not available on testnet realease");
                    Dockyard::frigate_requirements_check(dockyard_level, techs);
                    let cost = Dockyard::get_ships_cost(quantity, self.get_ships_cost().frigate);
                    self.check_enough_resources(caller, cost);
                    self.pay_resources_erc20(caller, cost);
                    self
                        .storage
                        .read()
                        .set_ship_level(planet_id, Names::FRIGATE, ships_levels.frigate + quantity);
                    return cost;
                },
                BuildType::Armade => {
                    assert!(!is_testnet, "NoGame: Armade not available on testnet realease");
                    Dockyard::armade_requirements_check(dockyard_level, techs);
                    let cost = Dockyard::get_ships_cost(quantity, self.get_ships_cost().armade);
                    self.check_enough_resources(caller, cost);
                    self.pay_resources_erc20(caller, cost);
                    self
                        .storage
                        .read()
                        .set_ship_level(planet_id, Names::ARMADE, ships_levels.armade + quantity);
                    return cost;
                },
                BuildType::Blaster => {
                    Defence::blaster_requirements_check(dockyard_level, techs);
                    let cost = Defence::get_defences_cost(
                        quantity, self.get_defences_cost().blaster
                    );
                    self.check_enough_resources(caller, cost);
                    self.pay_resources_erc20(caller, cost);
                    self
                        .storage
                        .read()
                        .set_defence_level(
                            planet_id, Names::BLASTER, defences_levels.blaster + quantity
                        );
                    return cost;
                },
                BuildType::Beam => {
                    Defence::beam_requirements_check(dockyard_level, techs);
                    let cost = Defence::get_defences_cost(quantity, self.get_defences_cost().beam);
                    self.check_enough_resources(caller, cost);
                    self.pay_resources_erc20(caller, cost);
                    self
                        .storage
                        .read()
                        .set_defence_level(planet_id, Names::BEAM, defences_levels.beam + quantity);
                    return cost;
                },
                BuildType::Astral => {
                    assert!(!is_testnet, "NoGame: Astral not available on testnet realease");
                    Defence::astral_launcher_requirements_check(dockyard_level, techs);
                    let cost = Defence::get_defences_cost(
                        quantity, self.get_defences_cost().astral
                    );
                    self.check_enough_resources(caller, cost);
                    self.pay_resources_erc20(caller, cost);
                    self
                        .storage
                        .read()
                        .set_defence_level(
                            planet_id, Names::ASTRAL, defences_levels.astral + quantity
                        );
                    return cost;
                },
                BuildType::Plasma => {
                    assert!(!is_testnet, "NoGame: Plasma Cannon not available on testnet realease");
                    Defence::plasma_beam_requirements_check(dockyard_level, techs);
                    let cost = Defence::get_defences_cost(
                        quantity, self.get_defences_cost().plasma
                    );
                    self.check_enough_resources(caller, cost);
                    self.pay_resources_erc20(caller, cost);
                    self
                        .storage
                        .read()
                        .set_defence_level(
                            planet_id, Names::PLASMA, defences_levels.plasma + quantity
                        );
                    return cost;
                },
            }
        }

        fn upgrade_colony_component(
            ref self: ContractState,
            caller: ContractAddress,
            planet_id: u32,
            colony_id: u8,
            component: ColonyUpgradeType,
            quantity: u8
        ) -> ERC20s {
            let levels = self.colony.get_colony_coumpounds(planet_id, colony_id);
            match component {
                ColonyUpgradeType::SteelMine => {
                    let cost: ERC20s = CompoundCost::steel(levels.steel, quantity);
                    self.check_enough_resources(caller, cost);
                    self.pay_resources_erc20(caller, cost);
                    self
                        .colony
                        .process_colony_compound_upgrade(
                            planet_id, colony_id, ColonyUpgradeType::SteelMine, quantity
                        );
                    return cost;
                },
                ColonyUpgradeType::QuartzMine => {
                    let cost: ERC20s = CompoundCost::quartz(levels.quartz, quantity);
                    self.check_enough_resources(caller, cost);
                    self.pay_resources_erc20(caller, cost);
                    self
                        .colony
                        .process_colony_compound_upgrade(
                            planet_id, colony_id, ColonyUpgradeType::QuartzMine, quantity
                        );
                    return cost;
                },
                ColonyUpgradeType::TritiumMine => {
                    let cost: ERC20s = CompoundCost::tritium(levels.tritium, quantity);
                    self.check_enough_resources(caller, cost);
                    self.pay_resources_erc20(caller, cost);
                    self
                        .colony
                        .process_colony_compound_upgrade(
                            planet_id, colony_id, ColonyUpgradeType::TritiumMine, quantity
                        );
                    return cost;
                },
                ColonyUpgradeType::EnergyPlant => {
                    let cost: ERC20s = CompoundCost::energy(levels.energy, quantity);
                    self.check_enough_resources(caller, cost);
                    self.pay_resources_erc20(caller, cost);
                    self
                        .colony
                        .process_colony_compound_upgrade(
                            planet_id, colony_id, ColonyUpgradeType::EnergyPlant, quantity
                        );
                    return cost;
                },
                ColonyUpgradeType::Dockyard => {
                    let cost: ERC20s = CompoundCost::dockyard(levels.dockyard, quantity);
                    self.check_enough_resources(caller, cost);
                    self.pay_resources_erc20(caller, cost);
                    self
                        .colony
                        .process_colony_compound_upgrade(
                            planet_id, colony_id, ColonyUpgradeType::Dockyard, quantity
                        );
                    return cost;
                },
            }
        }

        fn build_colony_component(
            ref self: ContractState,
            caller: ContractAddress,
            planet_id: u32,
            colony_id: u8,
            component: ColonyBuildType,
            quantity: u32
        ) -> ERC20s {
            let techs = self.storage.read().get_tech_levels(planet_id);
            let is_testnet = self.storage.read().get_is_testnet();
            match component {
                ColonyBuildType::Carrier => {
                    let cost: ERC20s = Dockyard::get_ships_cost(
                        quantity, self.get_ships_cost().carrier
                    );
                    self.check_enough_resources(caller, cost);
                    self.pay_resources_erc20(caller, cost);
                    self
                        .colony
                        .process_colony_unit_build(
                            planet_id,
                            colony_id,
                            techs,
                            ColonyBuildType::Carrier,
                            quantity,
                            is_testnet
                        );
                    return cost;
                },
                ColonyBuildType::Scraper => {
                    let cost: ERC20s = Dockyard::get_ships_cost(
                        quantity, self.get_ships_cost().scraper
                    );
                    self.check_enough_resources(caller, cost);
                    self.pay_resources_erc20(caller, cost);
                    self
                        .colony
                        .process_colony_unit_build(
                            planet_id,
                            colony_id,
                            techs,
                            ColonyBuildType::Scraper,
                            quantity,
                            is_testnet
                        );
                    return cost;
                },
                ColonyBuildType::Sparrow => {
                    let cost: ERC20s = Dockyard::get_ships_cost(
                        quantity, self.get_ships_cost().sparrow
                    );
                    self.check_enough_resources(caller, cost);
                    self.pay_resources_erc20(caller, cost);
                    self
                        .colony
                        .process_colony_unit_build(
                            planet_id,
                            colony_id,
                            techs,
                            ColonyBuildType::Sparrow,
                            quantity,
                            is_testnet
                        );
                    return cost;
                },
                ColonyBuildType::Frigate => {
                    let cost: ERC20s = Dockyard::get_ships_cost(
                        quantity, self.get_ships_cost().frigate
                    );
                    self.check_enough_resources(caller, cost);
                    self.pay_resources_erc20(caller, cost);
                    self
                        .colony
                        .process_colony_unit_build(
                            planet_id,
                            colony_id,
                            techs,
                            ColonyBuildType::Frigate,
                            quantity,
                            is_testnet
                        );
                    return cost;
                },
                ColonyBuildType::Armade => {
                    let cost: ERC20s = Dockyard::get_ships_cost(
                        quantity, self.get_ships_cost().armade
                    );
                    self.check_enough_resources(caller, cost);
                    self.pay_resources_erc20(caller, cost);
                    self
                        .colony
                        .process_colony_unit_build(
                            planet_id,
                            colony_id,
                            techs,
                            ColonyBuildType::Armade,
                            quantity,
                            is_testnet
                        );
                    return cost;
                },
                ColonyBuildType::Celestia => {
                    let cost: ERC20s = Dockyard::get_ships_cost(
                        quantity, self.get_ships_cost().celestia
                    );
                    self.check_enough_resources(caller, cost);
                    self.pay_resources_erc20(caller, cost);
                    self
                        .colony
                        .process_colony_unit_build(
                            planet_id,
                            colony_id,
                            techs,
                            ColonyBuildType::Celestia,
                            quantity,
                            is_testnet
                        );
                    return cost;
                },
                ColonyBuildType::Blaster => {
                    let cost = Defence::get_defences_cost(
                        quantity, self.get_defences_cost().blaster
                    );
                    self.check_enough_resources(caller, cost);
                    self.pay_resources_erc20(caller, cost);
                    self
                        .colony
                        .process_colony_unit_build(
                            planet_id,
                            colony_id,
                            techs,
                            ColonyBuildType::Blaster,
                            quantity,
                            is_testnet
                        );
                    return cost;
                },
                ColonyBuildType::Beam => {
                    let cost = Defence::get_defences_cost(quantity, self.get_defences_cost().beam);
                    self.check_enough_resources(caller, cost);
                    self.pay_resources_erc20(caller, cost);
                    self
                        .colony
                        .process_colony_unit_build(
                            planet_id, colony_id, techs, ColonyBuildType::Beam, quantity, is_testnet
                        );
                    return cost;
                },
                ColonyBuildType::Astral => {
                    let cost = Defence::get_defences_cost(
                        quantity, self.get_defences_cost().astral
                    );
                    self.check_enough_resources(caller, cost);
                    self.pay_resources_erc20(caller, cost);
                    self
                        .colony
                        .process_colony_unit_build(
                            planet_id,
                            colony_id,
                            techs,
                            ColonyBuildType::Astral,
                            quantity,
                            is_testnet
                        );
                    return cost;
                },
                ColonyBuildType::Plasma => {
                    let cost = Defence::get_defences_cost(
                        quantity, self.get_defences_cost().plasma
                    );
                    self.check_enough_resources(caller, cost);
                    self.pay_resources_erc20(caller, cost);
                    self
                        .colony
                        .process_colony_unit_build(
                            planet_id,
                            colony_id,
                            techs,
                            ColonyBuildType::Plasma,
                            quantity,
                            is_testnet
                        );
                    return cost;
                },
            }
        }
    }
}

