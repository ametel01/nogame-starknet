// TODOS: 

#[starknet::contract]
mod NoGame {
    use traits::DivRem;
    use starknet::{
        ContractAddress, get_block_timestamp, get_caller_address, get_contract_address,
        SyscallResultTrait, class_hash::ClassHash
    };
    use openzeppelin::token::erc20::interface::{IERC20CamelDispatcher, IERC20CamelDispatcherTrait};
    use nogame_fixed::f128::types::{Fixed, FixedTrait, ONE_u128 as ONE};

    use nogame::game::interface::INoGame;
    use nogame::libraries::types::{
        ETH_ADDRESS, BANK_ADDRESS, E18, DefencesCost, DefencesLevels, EnergyCost, ERC20s, erc20_mul,
        CompoundsCost, CompoundsLevels, ShipsLevels, ShipsCost, TechLevels, TechsCost, Tokens,
        PlanetPosition, Debris, Mission, HostileMission, Fleet, MAX_NUMBER_OF_PLANETS, _0_05, PRICE,
        DAY, HOUR, Names, UpgradeType, BuildType
    };
    use nogame::libraries::compounds::{Compounds, CompoundCost, Consumption, Production};
    use nogame::libraries::defences::Defences;
    use nogame::libraries::dockyard::Dockyard;
    use nogame::libraries::fleet;
    use nogame::libraries::research::Lab;
    use nogame::libraries::positions;
    use nogame::token::erc20::interface::{IERC20NoGameDispatcher, IERC20NoGameDispatcherTrait};
    use nogame::token::erc721::interface::{IERC721NoGameDispatcherTrait, IERC721NoGameDispatcher};

    use nogame::libraries::auction::{LinearVRGDA, LinearVRGDATrait};
    use snforge_std::PrintTrait;

    use snforge_std::PrintTrait;

    #[storage]
    struct Storage {
        initialized: bool,
        is_testnet: bool,
        receiver: ContractAddress,
        version: u8,
        token_price: u128,
        uni_speed: u128,
        // General.
        number_of_planets: u16,
        planet_position: LegacyMap::<u16, PlanetPosition>,
        position_to_planet: LegacyMap::<PlanetPosition, u16>,
        planet_debris_field: LegacyMap::<u16, Debris>,
        universe_start_time: u64,
        resources_spent: LegacyMap::<u16, u128>,
        last_active: LegacyMap::<u16, u64>,
        resources_timer: LegacyMap::<u16, u64>,
        // Tokens.
        erc721: IERC721NoGameDispatcher,
        steel: IERC20NoGameDispatcher,
        quartz: IERC20NoGameDispatcher,
        tritium: IERC20NoGameDispatcher,
        ETH: IERC20CamelDispatcher,
        // Infrastructures.
        compounds_level: LegacyMap::<(u16, felt252), u8>,
        // Technologies
        techs_level: LegacyMap::<(u16, felt252), u8>,
        // Ships
        ships_level: LegacyMap::<(u16, felt252), u32>,
        // Defences
        defences_level: LegacyMap::<(u16, felt252), u32>,
        active_missions: LegacyMap::<(u16, u32), Mission>,
        active_missions_len: LegacyMap<u16, usize>,
        hostile_missions: LegacyMap<(u16, u32), HostileMission>,
        hostile_missions_len: LegacyMap<u16, usize>,
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
        BattleReport: BattleReport,
        DebrisCollected: DebrisCollected,
        Upgraded: Upgraded,
    }

    #[derive(Drop, starknet::Event)]
    struct PlanetGenerated {
        id: u16,
        position: PlanetPosition,
        account: ContractAddress,
    }

    #[derive(Drop, starknet::Event)]
    struct CompoundSpent {
        planet_id: u16,
        compound_name: felt252,
        quantity: u8,
        spent: ERC20s
    }

    #[derive(Drop, starknet::Event)]
    struct TechSpent {
        planet_id: u16,
        tech_name: felt252,
        quantity: u8,
        spent: ERC20s
    }

    #[derive(Drop, starknet::Event)]
    struct FleetSpent {
        planet_id: u16,
        ship_name: felt252,
        quantity: u32,
        spent: ERC20s
    }

    #[derive(Drop, starknet::Event)]
    struct DefenceSpent {
        planet_id: u16,
        defence_name: felt252,
        quantity: u32,
        spent: ERC20s
    }

    #[derive(Drop, starknet::Event)]
    struct Upgraded {
        implementation: ClassHash
    }

    #[derive(Drop, starknet::Event)]
    struct FleetSent {
        time: u64,
        origin: u16,
        destination: u16,
        mission_type: felt252,
    }


    #[derive(Drop, starknet::Event)]
    struct BattleReport {
        time: u64,
        attacker: u16,
        attacker_position: PlanetPosition,
        attacker_initial_fleet: Fleet,
        attacker_fleet_loss: Fleet,
        defender: u16,
        defender_position: PlanetPosition,
        defender_initial_fleet: Fleet,
        defender_fleet_loss: Fleet,
        initial_defences: DefencesLevels,
        defences_loss: DefencesLevels,
        loot: ERC20s,
        debris: Debris,
    }

    #[derive(Drop, starknet::Event)]
    struct DebrisCollected {
        time: u64,
        debris_field_id: u16,
        amount: Debris,
    }

    #[constructor]
    fn constructor(ref self: ContractState) {
        self.universe_start_time.write(get_block_timestamp());
    }

    #[external(v0)]
    impl NoGame of INoGame<ContractState> {
        fn initializer(
            ref self: ContractState,
            erc721: ContractAddress,
            steel: ContractAddress,
            quartz: ContractAddress,
            tritium: ContractAddress,
            eth: ContractAddress,
            receiver: ContractAddress,
            uni_speed: u128,
            token_price: u128,
            is_testnet: bool,
        ) {
            self
                .init(
                    erc721,
                    steel,
                    quartz,
                    tritium,
                    eth,
                    receiver,
                    uni_speed,
                    token_price,
                    is_testnet
                )
        }

        fn upgrade(ref self: ContractState, impl_hash: ClassHash) {
            assert(!impl_hash.is_zero(), 'Class hash cannot be zero');
            starknet::replace_class_syscall(impl_hash).unwrap_syscall();
            self.version.write(self.version.read() + 1);
            self.emit(Event::Upgraded(Upgraded { implementation: impl_hash }))
        }

        fn version(self: @ContractState) -> u8 {
            self.version.read()
        }

        /////////////////////////////////////////////////////////////////////
        //                         Planet Functions                                
        /////////////////////////////////////////////////////////////////////
        fn generate_planet(ref self: ContractState) {
            let caller = get_caller_address();
            let time_elapsed = (get_block_timestamp() - self.universe_start_time.read()) / DAY;
            let price: u256 = self.get_planet_price(time_elapsed).into();
            self.ETH.read().transferFrom(caller, self.receiver.read(), price);
            let number_of_planets = self.number_of_planets.read();
            assert(number_of_planets != MAX_NUMBER_OF_PLANETS, 'max number of planets');
            let token_id = number_of_planets + 1;
            let position = positions::get_planet_position(token_id);
            self.erc721.read().mint(caller, token_id.into());
            self.planet_position.write(token_id, position);
            self.position_to_planet.write(position, token_id);
            self.number_of_planets.write(number_of_planets + 1);
            self.receive_resources_erc20(caller, ERC20s { steel: 500, quartz: 300, tritium: 100 });
            self.resources_timer.write(token_id, get_block_timestamp());
            self
                .emit(
                    Event::PlanetGenerated(
                        PlanetGenerated { id: token_id, position, account: caller }
                    )
                );
        }

        fn collect_resources(ref self: ContractState) {
            self._collect_resources(get_caller_address());
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
            let new_level = current_level + quantity.try_into().expect('u32 into u8 failed');
            self.steel_mine_level.write(planet_id, new_level);
            self
                .emit(
                    CompoundSpent { planet_id: planet_id, compound_name: Names::STEEL, spent: cost }
                )
        }

        fn process_tech_upgrade(ref self: ContractState, component: UpgradeType, quantity: u8) {
            let caller = get_caller_address();
            self._collect_resources(caller);
            let planet_id = self.get_owned_planet(caller);
            let cost = self.upgrade_component(caller, planet_id, component, quantity);
            self.update_planet_points(planet_id, cost);
            self.last_active.write(planet_id, get_block_timestamp());
            self.emit(TechSpent { planet_id: planet_id, tech_name: Names::STEEL, spent: cost })
        }

        fn process_ship_build(ref self: ContractState, component: BuildType, quantity: u32) {
            let caller = get_caller_address();
            self._collect_resources(caller);
            let planet_id = self.get_owned_planet(caller);
            let dockyard_level = self.compounds_level.read((planet_id, Names::DOCKYARD));
            let techs = self.get_tech_levels(planet_id);
            let cost = self
                .build_component(caller, planet_id, dockyard_level, techs, component, quantity);
            self.update_planet_points(planet_id, cost);
            self.last_active.write(planet_id, get_block_timestamp());
        }

        fn process_defence_build(ref self: ContractState, component: BuildType, quantity: u32) {
            let caller = get_caller_address();
            self._collect_resources(caller);
            let planet_id = self.get_owned_planet(caller);
            let dockyard_level = self.compounds_level.read((planet_id, Names::DOCKYARD));
            let techs = self.get_tech_levels(planet_id);
            let cost = self
                .build_component(caller, planet_id, dockyard_level, techs, component, quantity);
            self.update_planet_points(planet_id, cost);
            self.last_active.write(planet_id, get_block_timestamp());
        }

        /////////////////////////////////////////////////////////////////////
        //                         Fleet Functions                                
        /////////////////////////////////////////////////////////////////////
        fn send_fleet(
            ref self: ContractState,
            f: Fleet,
            destination: PlanetPosition,
            is_debris_collection: bool
        ) {
            let destination_id = self.position_to_planet.read(destination);
            assert(!destination_id.is_zero(), 'no planet at destination');
            let caller = get_caller_address();
            let planet_id = self.get_owned_planet(caller);
            let time_now = get_block_timestamp();
            let is_inactive = time_now - self.last_active.read(destination_id) > WEEK;

            if is_debris_collection {
                assert(
                    !self.planet_debris_field.read(destination_id).is_zero(), 'empty debris fiels'
                );
                assert(f.scraper >= 1, 'no scrapers for collection');
                assert(
                    f.carrier.is_zero()
                        && f.sparrow.is_zero()
                        && f.frigate.is_zero() & f.armade.is_zero(),
                    'only scraper can collect'
                );
            } else {
                assert(destination_id != planet_id, 'cannot send to own planet');
                if !is_inactive {
                    assert(
                        !self.is_noob_protected(planet_id, destination_id), 'noob protection active'
                    );
                }
            }

            self.check_enough_ships(planet_id, f);
            // Calculate distance
            let distance = fleet::get_distance(self.planet_position.read(planet_id), destination);

            // Calculate time
            let techs = self.get_tech_levels(planet_id);
            let speed = fleet::get_fleet_speed(f, techs);
            let travel_time = fleet::get_flight_time(speed, distance);

            // Check numeber of mission
            let active_missions = self.active_missions_len.read(planet_id);
            assert(active_missions < techs.digital.into() + 1, 'max active missions');

            // Pay for fuel
            let consumption = fleet::get_fuel_consumption(f, distance);
            let mut cost: ERC20s = Default::default();
            cost.tritium = consumption;
            self.check_enough_resources(caller, cost);
            self.pay_resources_erc20(caller, cost);

            // Write mission
            let mut mission: Mission = Default::default();
            mission.time_start = time_now;
            mission.destination = self.get_position_slot_occupant(destination);
            mission.time_arrival = time_now + travel_time;
            mission.fleet = f;

            if is_debris_collection {
                mission.is_debris = true;
                self.add_active_mission(planet_id, mission);
                self
                    .emit(
                        Event::FleetSent(
                            FleetSent {
                                time: time_now,
                                origin: planet_id,
                                destination: destination_id,
                                mission_type: 'debris collection'
                            }
                        )
                    );
            } else {
                let id = self.add_active_mission(planet_id, mission);
                mission.is_debris = false;
                let mut hostile_mission: HostileMission = Default::default();
                hostile_mission.origin = planet_id;
                hostile_mission.id_at_origin = id;
                hostile_mission.time_arrival = mission.time_arrival;
                hostile_mission
                    .number_of_ships = fleet::calculate_number_of_ships(f, Zeroable::zero());

                self.add_hostile_mission(destination_id, hostile_mission);
                self
                    .emit(
                        Event::FleetSent(
                            FleetSent {
                                time: time_now,
                                origin: planet_id,
                                destination: destination_id,
                                mission_type: 'attack'
                            }
                        )
                    );
            }

            // Write new fleet levels
            self.fleet_leave_planet(planet_id, f);
        }

        fn attack_planet(ref self: ContractState, mission_id: usize) {
            let caller = get_caller_address();
            let origin = self.get_owned_planet(caller);
            let mut mission = self.active_missions.read((origin, mission_id));
            assert(!mission.is_zero(), 'the mission is empty');
            assert(mission.destination != origin, 'cannot attack own planet');
            let time_now = get_block_timestamp();
            assert(time_now >= mission.time_arrival, 'destination not reached yet');
            let defender_fleet = self.get_ships_levels(mission.destination);
            let defences = self.get_defences_levels(mission.destination);
            let t1 = self.get_tech_levels(origin);
            let t2 = self.get_tech_levels(mission.destination);
            let celestia_before = self.get_celestia_available(mission.destination);

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
            let current_debries_field = self.planet_debris_field.read(mission.destination);
            self
                .planet_debris_field
                .write(mission.destination, current_debries_field + total_debris);

            self.update_defender_fleet_levels_after_attack(mission.destination, f2);
            self.update_defences_after_attack(mission.destination, d);

            let mut loot_amount: ERC20s = Default::default();

            if f1.is_zero() {
                self.active_missions.write((origin, mission_id), Zeroable::zero());
            } else {
                let spendable = self.get_spendable_resources(mission.destination);
                let collectible = self.get_collectible_resources(mission.destination);
                let mut loot_collectible: ERC20s = Default::default();
                let mut storage = fleet::get_fleet_cargo_capacity(f1);
                if storage < (collectible.steel + collectible.quartz + collectible.tritium) {
                    loot_amount = fleet::load_resources(collectible + spendable, storage);
                    self.receive_resources_erc20(get_caller_address(), loot_amount);
                } else {
                    let loot_amount_collectible = fleet::load_resources(collectible, storage);
                    let mut loot_amount_spendable: ERC20s = Default::default();
                    loot_amount_spendable.steel = spendable.steel / 2;
                    loot_amount_spendable.quartz = spendable.quartz / 2;
                    loot_amount_spendable.tritium = spendable.tritium / 2;
                    loot_amount_spendable =
                        fleet::load_resources(
                            loot_amount_spendable,
                            storage
                                - (loot_amount_collectible.steel
                                    + loot_amount_collectible.quartz
                                    + loot_amount_collectible.tritium)
                        );
                    loot_amount = loot_amount_collectible + loot_amount_spendable;

                    self
                        .pay_resources_erc20(
                            self.erc721.read().ownerOf(mission.destination.into()),
                            loot_amount_spendable
                        );
                    self
                        .receive_resources_erc20(
                            get_caller_address(), loot_amount_collectible + loot_amount_spendable
                        );
                }

                self.resources_timer.write(mission.destination, time_now);
                self.fleet_return_planet(origin, f1);
                self.active_missions.write((origin, mission_id), Zeroable::zero());
            }

            self.remove_hostile_mission(mission.destination, mission_id);

            let attacker_loss = self.calculate_fleet_loss(mission.fleet, f1);
            let defender_loss = self.calculate_fleet_loss(defender_fleet, f2);
            let defences_loss = self.calculate_defences_loss(defences, d);

            self.update_points_after_attack(origin, attacker_loss, Zeroable::zero());
            self.update_points_after_attack(mission.destination, defender_loss, defences_loss);

            self
                .emit_battle_report(
                    time_now,
                    origin,
                    self.planet_position.read(origin),
                    mission.fleet,
                    attacker_loss,
                    mission.destination,
                    self.planet_position.read(mission.destination),
                    defender_fleet,
                    defender_loss,
                    defences,
                    defences_loss,
                    loot_amount,
                    total_debris
                );
        }

        fn recall_fleet(ref self: ContractState, mission_id: usize) {
            let origin = self.get_owned_planet(get_caller_address());
            let mission = self.active_missions.read((origin, mission_id));
            assert(!mission.is_zero(), 'no fleet to recall');
            self.fleet_return_planet(origin, mission.fleet);
            self.active_missions.write((origin, mission_id), Zeroable::zero());
            self.remove_hostile_mission(mission.destination, mission_id);
        }

        fn collect_debris(ref self: ContractState, mission_id: usize) {
            let caller = get_caller_address();
            let origin = self.get_owned_planet(caller);

            let mut mission = self.active_missions.read((origin, mission_id));
            assert(!mission.is_zero(), 'the mission is empty');
            assert(mission.is_debris, 'not a debris mission');

            let time_now = get_block_timestamp();
            assert(time_now >= mission.time_arrival, 'destination not reached yet');

            let time_since_arrived = time_now - mission.time_arrival;
            let mut collector_fleet: Fleet = mission.fleet;

            if time_since_arrived > (2 * HOUR) {
                let decay_amount = fleet::calculate_fleet_loss(time_since_arrived - (2 * HOUR));
                collector_fleet = fleet::decay_fleet(mission.fleet, decay_amount);
            }

            let debris = self.planet_debris_field.read(mission.destination);
            let storage = fleet::get_fleet_cargo_capacity(collector_fleet);
            let collectible_debris = fleet::get_collectible_debris(storage, debris);
            let new_debris = Debris {
                steel: debris.steel - collectible_debris.steel,
                quartz: debris.quartz - collectible_debris.quartz
            };

            self.planet_debris_field.write(mission.destination, new_debris);

            let erc20 = ERC20s {
                steel: collectible_debris.steel,
                quartz: collectible_debris.quartz,
                tritium: Zeroable::zero()
            };

            self.receive_resources_erc20(caller, erc20);
            self
                .ships_level
                .write(
                    (origin, Names::SCRAPER),
                    self.ships_level.read((origin, Names::SCRAPER)) + collector_fleet.scraper
                );
            self.active_missions.write((origin, mission_id), Zeroable::zero());
            let active_missions = self.active_missions_len.read(origin);
            self.active_missions_len.write(origin, active_missions - 1);

            self
                .emit(
                    Event::DebrisCollected(
                        DebrisCollected {
                            time: time_now,
                            debris_field_id: mission.destination,
                            amount: collectible_debris,
                        }
                    )
                );
        }

        /////////////////////////////////////////////////////////////////////
        //                         View Functions                                
        /////////////////////////////////////////////////////////////////////
        fn get_receiver(self: @ContractState) -> ContractAddress {
            self.receiver.read()
        }
        fn get_token_addresses(self: @ContractState) -> Tokens {
            self.get_tokens_addresses()
        }

        fn get_current_planet_price(self: @ContractState) -> u128 {
            let time_elapsed = (get_block_timestamp() - self.universe_start_time.read()) / DAY;
            self.get_planet_price(time_elapsed)
        }

        fn get_number_of_planets(self: @ContractState) -> u16 {
            self.number_of_planets.read()
        }

        fn get_generated_planets_positions(self: @ContractState) -> Array<PlanetPosition> {
            let mut arr: Array<PlanetPosition> = array![];
            let mut i = self.get_number_of_planets();
            loop {
                if i.is_zero() {
                    break;
                }
                let position = self.get_planet_position(i);
                arr.append(position);
                i -= 1;
            };
            arr
        }

        fn get_planet_position(self: @ContractState, planet_id: u16) -> PlanetPosition {
            self.planet_position.read(planet_id)
        }

        fn get_position_slot_occupant(self: @ContractState, position: PlanetPosition) -> u16 {
            self.position_to_planet.read(position)
        }

        fn get_debris_field(self: @ContractState, planet_id: u16) -> Debris {
            self.planet_debris_field.read(planet_id)
        }

        fn get_planet_points(self: @ContractState, planet_id: u16) -> u128 {
            self.resources_spent.read(planet_id) / 1000
        }

        fn get_spendable_resources(self: @ContractState, planet_id: u16) -> ERC20s {
            let planet_owner = self.erc721.read().ownerOf(planet_id.into());
            let steel = self.steel.read().balance_of(planet_owner).low / E18;
            let quartz = self.quartz.read().balance_of(planet_owner).low / E18;
            let tritium = self.tritium.read().balance_of(planet_owner).low / E18;
            ERC20s { steel: steel, quartz: quartz, tritium: tritium }
        }

        fn get_collectible_resources(self: @ContractState, planet_id: u16) -> ERC20s {
            let time_elapsed = self.time_since_last_collection(planet_id);
            let position = self.planet_position.read(planet_id);
            let temp = self.calculate_avg_temperature(position.orbit);
            let speed = self.uni_speed.read();
            let steel = Production::steel(self.compounds_level.read((planet_id, Names::STEEL)))
                * speed
                * time_elapsed.into();
            let quartz = Production::quartz(self.quartz_mine_level.read(planet_id))
                * speed
                * time_elapsed.into();
            let tritium = Production::tritium(
                self.compounds_level.read((planet_id, Names::TRITIUM)), temp, speed
            )
                * time_elapsed.into();
            ERC20s { steel: steel, quartz: quartz, tritium: tritium }
        }

        fn get_energy_available(self: @ContractState, planet_id: u16) -> u128 {
            let compounds = self.get_compounds_levels(planet_id);
            let gross_production = Production::energy(compounds.energy);
            let celestia_production = (self.ships_level.read((planet_id, Names::CELESTIA)).into()
                * 15);
            let energy_required = (self.calculate_energy_consumption(planet_id));
            if (gross_production + celestia_production < energy_required) {
                return 0;
            } else {
                return gross_production + celestia_production - energy_required;
            }
        }

        fn get_compounds_levels(self: @ContractState, planet_id: u16) -> CompoundsLevels {
            CompoundsLevels {
                steel: self.compounds_level.read((planet_id, Names::STEEL)),
                quartz: self.compounds_level.read((planet_id, Names::QUARTZ)),
                tritium: self.compounds_level.read((planet_id, Names::TRITIUM)),
                energy: self.compounds_level.read((planet_id, Names::ENERGY_PLANT)),
                lab: self.compounds_level.read((planet_id, Names::LAB)),
                dockyard: self.compounds_level.read((planet_id, Names::DOCKYARD))
            }
        }

        fn get_compounds_upgrade_cost(self: @ContractState, planet_id: u16) -> CompoundsCost {
            let compounds = self.get_compounds_levels(planet_id);
            let steel = CompoundCost::steel(compounds.steel, 1);
            let quartz = CompoundCost::quartz(compounds.quartz, 1);
            let tritium = CompoundCost::tritium(compounds.tritium, 1);
            let energy = CompoundCost::energy(compounds.energy, 1);
            let lab = CompoundCost::lab(compounds.lab, 1);
            let dockyard = CompoundCost::dockyard(compounds.dockyard, 1);
            CompoundsCost {
                steel: steel,
                quartz: quartz,
                tritium: tritium,
                energy: energy,
                lab: lab,
                dockyard: dockyard
            }
        }

        fn get_energy_for_upgrade(self: @ContractState, planet_id: u16) -> EnergyCost {
            let compounds = self.get_compounds_levels(planet_id);
            let steel = Consumption::base(compounds.steel + 1) - Consumption::base(compounds.steel);
            let quartz = Consumption::base(compounds.quartz + 1)
                - Consumption::base(compounds.quartz);
            let tritium = Consumption::tritium(compounds.tritium + 1)
                - Consumption::tritium(compounds.tritium);

            EnergyCost { steel: steel, quartz: quartz, tritium: tritium }
        }

        fn get_energy_gain_after_upgrade(self: @ContractState, planet_id: u16) -> u128 {
            let compounds = self.get_compounds_levels(planet_id);
            Production::energy(compounds.energy + 1) - Production::energy(compounds.energy)
        }

        fn get_celestia_production(self: @ContractState, planet_id: u16) -> u16 {
            let position = self.get_planet_position(planet_id);
            self.position_to_celestia_production(position.orbit)
        }

        fn get_ships_levels(self: @ContractState, planet_id: u16) -> Fleet {
            Fleet {
                carrier: self.ships_level.read((planet_id, Names::CARRIER)),
                scraper: self.ships_level.read((planet_id, Names::SCRAPER)),
                sparrow: self.ships_level.read((planet_id, Names::SPARROW)),
                frigate: self.ships_level.read((planet_id, Names::FRIGATE)),
                armade: self.ships_level.read((planet_id, Names::ARMADE)),
            }
        }

        fn get_celestia_available(self: @ContractState, planet_id: u16) -> u32 {
            self.defences_level.read((planet_id, Names::CELESTIA))
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

        fn get_defences_levels(self: @ContractState, planet_id: u16) -> DefencesLevels {
            DefencesLevels {
                celestia: self.defences_level.read((planet_id, Names::CELESTIA)),
                blaster: self.defences_level.read((planet_id, Names::BLASTER)),
                beam: self.defences_level.read((planet_id, Names::BEAM)),
                astral: self.defences_level.read((planet_id, Names::ASTRAL)),
                plasma: self.defences_level.read((planet_id, Names::PLASMA)),
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

        fn is_noob_protected(self: @ContractState, planet1_id: u16, planet2_id: u16) -> bool {
            let p1_points = self.get_planet_points(planet1_id);
            let p2_points = self.get_planet_points(planet2_id);
            if p1_points > p2_points {
                return p1_points > p2_points * 5;
            } else {
                return p2_points > p1_points * 5;
            }
        }

        fn get_mission_details(self: @ContractState, planet_id: u16, mission_id: usize) -> Mission {
            self.active_missions.read((planet_id, mission_id))
        }

        fn get_active_missions(self: @ContractState, planet_id: u16) -> Array<Mission> {
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

        fn get_hostile_missions(self: @ContractState, planet_id: u16) -> Array<HostileMission> {
            let mut arr: Array<HostileMission> = array![];
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

        fn get_travel_time(
            self: @ContractState,
            origin: PlanetPosition,
            destination: PlanetPosition,
            fleet: Fleet,
            techs: TechLevels
        ) -> u64 {
            let destination_id = self.position_to_planet.read(destination);
            assert(!destination_id.is_zero(), 'no planet at destination');
            let distance = fleet::get_distance(origin, destination);
            let speed = fleet::get_fleet_speed(fleet, techs);
            fleet::get_flight_time(speed, distance)
        }

        fn get_fuel_consumption(
            self: @ContractState, origin: PlanetPosition, destination: PlanetPosition, fleet: Fleet
        ) -> u128 {
            let distance = fleet::get_distance(origin, destination);
            fleet::get_fuel_consumption(fleet, distance)
        }
    }


    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn init(
            ref self: ContractState,
            erc721: ContractAddress,
            steel: ContractAddress,
            quartz: ContractAddress,
            tritium: ContractAddress,
            eth: ContractAddress,
            receiver: ContractAddress,
            uni_speed: u128,
            token_price: u128,
            is_testnet: bool
        ) {
            assert(!self.initialized.read(), 'already initialized');
            self.erc721.write(IERC721NoGameDispatcher { contract_address: erc721 });
            self.steel.write(IERC20NoGameDispatcher { contract_address: steel });
            self.quartz.write(IERC20NoGameDispatcher { contract_address: quartz });
            self.tritium.write(IERC20NoGameDispatcher { contract_address: tritium });
            self.ETH.write(IERC20CamelDispatcher { contract_address: eth });
            self.receiver.write(receiver);
            self.uni_speed.write(uni_speed);
            self.initialized.write(true);
            self.token_price.write(token_price);
            self.is_testnet.write(is_testnet);
        }

        fn upgrade_component(
            ref self: ContractState,
            caller: ContractAddress,
            planet_id: u16,
            component: UpgradeType,
            quantity: u8
        ) -> ERC20s {
            match component {
                UpgradeType::SteelMine => {
                    let current_level = self.compounds_level.read((planet_id, Names::STEEL));
                    let cost: ERC20s = CompoundCost::steel(current_level, quantity);
                    self.check_enough_resources(caller, cost);
                    self.pay_resources_erc20(caller, cost);
                    self
                        .compounds_level
                        .write(
                            (planet_id, Names::STEEL),
                            current_level + quantity.try_into().expect('u32 into u8 failed')
                        );
                    return cost;
                },
                UpgradeType::QuartzMine => {
                    let current_level = self.compounds_level.read((planet_id, Names::QUARTZ));
                    let cost: ERC20s = CompoundCost::quartz(current_level, quantity);
                    self.check_enough_resources(caller, cost);
                    self.pay_resources_erc20(caller, cost);
                    self
                        .compounds_level
                        .write(
                            (planet_id, Names::QUARTZ),
                            current_level + quantity.try_into().expect('u32 into u8 failed')
                        );
                    return cost;
                },
                UpgradeType::TritiumMine => {
                    let current_level = self.compounds_level.read((planet_id, Names::TRITIUM));
                    let cost: ERC20s = CompoundCost::tritium(current_level, quantity);
                    self.check_enough_resources(caller, cost);
                    self.pay_resources_erc20(caller, cost);
                    self
                        .compounds_level
                        .write(
                            (planet_id, Names::TRITIUM),
                            current_level + quantity.try_into().expect('u32 into u8 failed')
                        );
                    return cost;
                },
                UpgradeType::EnergyPlant => {
                    let current_level = self.compounds_level.read((planet_id, Names::ENERGY_PLANT));
                    let cost: ERC20s = CompoundCost::energy(current_level, quantity);
                    self.check_enough_resources(caller, cost);
                    self.pay_resources_erc20(caller, cost);
                    self
                        .compounds_level
                        .write(
                            (planet_id, Names::ENERGY_PLANT),
                            current_level + quantity.try_into().expect('u32 into u8 failed')
                        );
                    return cost;
                },
                UpgradeType::Lab => {
                    let current_level = self.compounds_level.read((planet_id, Names::LAB));
                    let cost: ERC20s = CompoundCost::lab(current_level, quantity);
                    self.check_enough_resources(caller, cost);
                    self.pay_resources_erc20(caller, cost);
                    self
                        .compounds_level
                        .write(
                            (planet_id, Names::LAB),
                            current_level + quantity.try_into().expect('u32 into u8 failed')
                        );
                    return cost;
                },
                UpgradeType::Dockyard => {
                    let current_level = self.compounds_level.read((planet_id, Names::DOCKYARD));
                    let cost: ERC20s = CompoundCost::dockyard(current_level, quantity);
                    self.check_enough_resources(caller, cost);
                    self.pay_resources_erc20(caller, cost);
                    self
                        .compounds_level
                        .write(
                            (planet_id, Names::DOCKYARD),
                            current_level + quantity.try_into().expect('u32 into u8 failed')
                        );
                    return cost;
                },
                UpgradeType::EnergyTech => {
                    let lab_level = self.compounds_level.read((planet_id, Names::LAB));
                    let techs = self.get_tech_levels(planet_id);
                    Lab::energy_innovation_requirements_check(lab_level, techs);
                    let base_cost: ERC20s = Lab::base_tech_costs().energy;
                    let cost = Lab::get_tech_cost(techs.energy, quantity, base_cost);
                    self.check_enough_resources(caller, cost);
                    self.pay_resources_erc20(caller, cost);
                    self
                        .techs_level
                        .write(
                            (planet_id, Names::ENERGY_TECH),
                            techs.energy + quantity.try_into().expect('u32 into u8 failed')
                        );
                    return cost;
                },
                UpgradeType::Digital => {
                    let lab_level = self.compounds_level.read((planet_id, Names::LAB));
                    let techs = self.get_tech_levels(planet_id);
                    Lab::digital_systems_requirements_check(lab_level, techs);
                    let base_cost: ERC20s = Lab::base_tech_costs().digital;
                    let cost = Lab::get_tech_cost(techs.digital, quantity, base_cost);
                    self.check_enough_resources(caller, cost);
                    self.pay_resources_erc20(caller, cost);
                    self
                        .techs_level
                        .write(
                            (planet_id, Names::DIGITAL),
                            techs.digital + quantity.try_into().expect('u32 into u8 failed')
                        );
                    return cost;
                },
                UpgradeType::BeamTech => {
                    let lab_level = self.compounds_level.read((planet_id, Names::LAB));
                    let techs = self.get_tech_levels(planet_id);
                    Lab::beam_technology_requirements_check(lab_level, techs);
                    let base_cost: ERC20s = Lab::base_tech_costs().beam;
                    let cost = Lab::get_tech_cost(techs.beam, quantity, base_cost);
                    self.check_enough_resources(caller, cost);
                    self.pay_resources_erc20(caller, cost);
                    self.update_planet_points(planet_id, cost);
                    self.last_active.write(planet_id, get_block_timestamp());
                    self
                        .techs_level
                        .write(
                            (planet_id, Names::BEAM_TECH),
                            techs.beam + quantity.try_into().expect('u32 into u8 failed')
                        );
                    return cost;
                },
                UpgradeType::Armour => {
                    let lab_level = self.compounds_level.read((planet_id, Names::LAB));
                    let techs = self.get_tech_levels(planet_id);
                    Lab::armour_innovation_requirements_check(lab_level, techs);
                    let base_cost: ERC20s = Lab::base_tech_costs().armour;
                    let cost = Lab::get_tech_cost(techs.armour, quantity, base_cost);
                    self.check_enough_resources(caller, cost);
                    self.pay_resources_erc20(caller, cost);
                    self
                        .techs_level
                        .write(
                            (planet_id, Names::ARMOUR),
                            techs.beam + quantity.try_into().expect('u32 into u8 failed')
                        );
                    return cost;
                },
                UpgradeType::Ion => {
                    let lab_level = self.compounds_level.read((planet_id, Names::LAB));
                    let techs = self.get_tech_levels(planet_id);
                    Lab::ion_systems_requirements_check(lab_level, techs);
                    let base_cost: ERC20s = Lab::base_tech_costs().ion;
                    let cost = Lab::get_tech_cost(techs.ion, quantity, base_cost);
                    self.check_enough_resources(caller, cost);
                    self.pay_resources_erc20(caller, cost);
                    self
                        .techs_level
                        .write(
                            (planet_id, Names::ION),
                            techs.ion + quantity.try_into().expect('u32 into u8 failed')
                        );
                    return cost;
                },
                UpgradeType::PlasmaTech => {
                    let lab_level = self.compounds_level.read((planet_id, Names::LAB));
                    let techs = self.get_tech_levels(planet_id);
                    Lab::plasma_engineering_requirements_check(lab_level, techs);
                    let base_cost: ERC20s = Lab::base_tech_costs().plasma;
                    let cost = Lab::get_tech_cost(techs.plasma, quantity, base_cost);
                    self.check_enough_resources(caller, cost);
                    self.pay_resources_erc20(caller, cost);
                    self
                        .techs_level
                        .write(
                            (planet_id, Names::PLASMA_TECH),
                            techs.plasma + quantity.try_into().expect('u32 into u8 failed')
                        );
                    return cost;
                },
                UpgradeType::Weapons => {
                    let lab_level = self.compounds_level.read((planet_id, Names::LAB));
                    let techs = self.get_tech_levels(planet_id);
                    Lab::weapons_development_requirements_check(lab_level, techs);
                    let base_cost: ERC20s = Lab::base_tech_costs().weapons;
                    let cost = Lab::get_tech_cost(techs.weapons, quantity, base_cost);
                    self.check_enough_resources(caller, cost);
                    self.pay_resources_erc20(caller, cost);
                    self
                        .techs_level
                        .write(
                            (planet_id, Names::WEAPONS),
                            techs.weapons + quantity.try_into().expect('u32 into u8 failed')
                        );
                    return cost;
                },
                UpgradeType::Shield => {
                    let lab_level = self.compounds_level.read((planet_id, Names::LAB));
                    let techs = self.get_tech_levels(planet_id);
                    Lab::shield_tech_requirements_check(lab_level, techs);
                    let base_cost: ERC20s = Lab::base_tech_costs().shield;
                    let cost = Lab::get_tech_cost(techs.shield, quantity, base_cost);
                    self.check_enough_resources(caller, cost);
                    self.pay_resources_erc20(caller, cost);
                    self
                        .techs_level
                        .write(
                            (planet_id, Names::SHIELD),
                            techs.shield + quantity.try_into().expect('u32 into u8 failed')
                        );
                    return cost;
                },
                UpgradeType::Spacetime => {
                    let lab_level = self.compounds_level.read((planet_id, Names::LAB));
                    let techs = self.get_tech_levels(planet_id);
                    Lab::spacetime_warp_requirements_check(lab_level, techs);
                    let base_cost: ERC20s = Lab::base_tech_costs().spacetime;
                    let cost = Lab::get_tech_cost(techs.spacetime, quantity, base_cost);
                    self.check_enough_resources(caller, cost);
                    self.pay_resources_erc20(caller, cost);
                    self
                        .techs_level
                        .write(
                            (planet_id, Names::SPACETIME),
                            techs.spacetime + quantity.try_into().expect('u32 into u8 failed')
                        );
                    return cost;
                },
                UpgradeType::Combustion => {
                    let lab_level = self.compounds_level.read((planet_id, Names::LAB));
                    let techs = self.get_tech_levels(planet_id);
                    Lab::combustive_engine_requirements_check(lab_level, techs);
                    let base_cost: ERC20s = Lab::base_tech_costs().combustion;
                    let cost = Lab::get_tech_cost(techs.combustion, quantity, base_cost);
                    self.check_enough_resources(caller, cost);
                    self.pay_resources_erc20(caller, cost);
                    self
                        .techs_level
                        .write(
                            (planet_id, Names::COMBUSTION),
                            techs.combustion + quantity.try_into().expect('u32 into u8 failed')
                        );
                    return cost;
                },
                UpgradeType::Thrust => {
                    let lab_level = self.compounds_level.read((planet_id, Names::LAB));
                    let techs = self.get_tech_levels(planet_id);
                    Lab::thrust_propulsion_requirements_check(lab_level, techs);
                    let base_cost: ERC20s = Lab::base_tech_costs().thrust;
                    let cost = Lab::get_tech_cost(techs.thrust, quantity, base_cost);
                    self.check_enough_resources(caller, cost);
                    self.pay_resources_erc20(caller, cost);
                    self
                        .techs_level
                        .write(
                            (planet_id, Names::THRUST),
                            techs.thrust + quantity.try_into().expect('u32 into u8 failed')
                        );
                    return cost;
                },
                UpgradeType::Warp => {
                    let lab_level = self.compounds_level.read((planet_id, Names::LAB));
                    let techs = self.get_tech_levels(planet_id);
                    Lab::warp_drive_requirements_check(lab_level, techs);
                    let base_cost: ERC20s = Lab::base_tech_costs().warp;
                    let cost = Lab::get_tech_cost(techs.warp, quantity, base_cost);
                    self.check_enough_resources(caller, cost);
                    self.pay_resources_erc20(caller, cost);
                    self
                        .techs_level
                        .write(
                            (planet_id, Names::WARP),
                            techs.warp + quantity.try_into().expect('u32 into u8 failed')
                        );
                    return cost;
                },
            }
        }

        fn build_component(
            ref self: ContractState,
            caller: ContractAddress,
            planet_id: u16,
            dockyard_level: u8,
            techs: TechLevels,
            component: BuildType,
            quantity: u32
        ) -> ERC20s {
            match component {
                BuildType::Carrier => {
                    let techs = self.get_tech_levels(planet_id);
                    Dockyard::carrier_requirements_check(dockyard_level, techs);
                    let cost = Dockyard::get_ships_cost(quantity, self.get_ships_cost().carrier);
                    self.check_enough_resources(caller, cost);
                    self.pay_resources_erc20(caller, cost);
                    self
                        .ships_level
                        .write(
                            (planet_id, Names::CARRIER),
                            self.ships_level.read((planet_id, Names::CARRIER)) + quantity
                        );
                    return cost;
                },
                BuildType::Scraper => {
                    let techs = self.get_tech_levels(planet_id);
                    Dockyard::scraper_requirements_check(dockyard_level, techs);
                    let cost = Dockyard::get_ships_cost(quantity, self.get_ships_cost().scraper);
                    self.check_enough_resources(caller, cost);
                    self.pay_resources_erc20(caller, cost);
                    self
                        .ships_level
                        .write(
                            (planet_id, Names::SCRAPER),
                            self.ships_level.read((planet_id, Names::SCRAPER)) + quantity
                        );
                    return cost;
                },
                BuildType::Celestia => {
                    let techs = self.get_tech_levels(planet_id);
                    Dockyard::celestia_requirements_check(dockyard_level, techs);
                    let cost = Dockyard::get_ships_cost(quantity, self.get_ships_cost().celestia);
                    self.check_enough_resources(caller, cost);
                    self.pay_resources_erc20(caller, cost);
                    self
                        .defences_level
                        .write(
                            (planet_id, Names::CELESTIA),
                            self.defences_level.read((planet_id, Names::CELESTIA)) + quantity
                        );
                    return cost;
                },
                BuildType::Sparrow => {
                    let techs = self.get_tech_levels(planet_id);
                    Dockyard::sparrow_requirements_check(dockyard_level, techs);
                    let cost = Dockyard::get_ships_cost(quantity, self.get_ships_cost().sparrow);
                    self.check_enough_resources(caller, cost);
                    self.pay_resources_erc20(caller, cost);
                    self
                        .ships_level
                        .write(
                            (planet_id, Names::SPARROW),
                            self.ships_level.read((planet_id, Names::SPARROW)) + quantity
                        );
                    return cost;
                },
                BuildType::Frigate => {
                    let techs = self.get_tech_levels(planet_id);
                    Dockyard::frigate_requirements_check(dockyard_level, techs);
                    let cost = Dockyard::get_ships_cost(quantity, self.get_ships_cost().frigate);
                    self.check_enough_resources(caller, cost);
                    self.pay_resources_erc20(caller, cost);
                    self
                        .ships_level
                        .write(
                            (planet_id, Names::FRIGATE),
                            self.ships_level.read((planet_id, Names::FRIGATE)) + quantity
                        );
                    return cost;
                },
                BuildType::Armade => {
                    let techs = self.get_tech_levels(planet_id);
                    Dockyard::armade_requirements_check(dockyard_level, techs);
                    let cost = Dockyard::get_ships_cost(quantity, self.get_ships_cost().armade);
                    self.check_enough_resources(caller, cost);
                    self.pay_resources_erc20(caller, cost);
                    self
                        .ships_level
                        .write(
                            (planet_id, Names::ARMADE),
                            self.ships_level.read((planet_id, Names::ARMADE)) + quantity
                        );
                    return cost;
                },
                BuildType::Blaster => {
                    let techs = self.get_tech_levels(planet_id);
                    Defences::blaster_requirements_check(dockyard_level, techs);
                    let cost = Defences::get_defences_cost(
                        quantity, self.get_defences_cost().blaster
                    );
                    self.check_enough_resources(caller, cost);
                    self.pay_resources_erc20(caller, cost);
                    self
                        .defences_level
                        .write(
                            (planet_id, Names::BLASTER),
                            self.defences_level.read((planet_id, Names::BLASTER)) + quantity
                        );
                    return cost;
                },
                BuildType::Beam => {
                    let techs = self.get_tech_levels(planet_id);
                    Defences::beam_requirements_check(dockyard_level, techs);
                    let cost = Defences::get_defences_cost(quantity, self.get_defences_cost().beam);
                    self.check_enough_resources(caller, cost);
                    self.pay_resources_erc20(caller, cost);
                    self
                        .defences_level
                        .write(
                            (planet_id, Names::BEAM),
                            self.defences_level.read((planet_id, Names::BEAM)) + quantity
                        );
                    return cost;
                },
                BuildType::Astral => {
                    let techs = self.get_tech_levels(planet_id);
                    Defences::astral_launcher_requirements_check(dockyard_level, techs);
                    let cost = Defences::get_defences_cost(
                        quantity, self.get_defences_cost().astral
                    );
                    self.check_enough_resources(caller, cost);
                    self.pay_resources_erc20(caller, cost);
                    self
                        .defences_level
                        .write(
                            (planet_id, Names::ASTRAL),
                            self.defences_level.read((planet_id, Names::ASTRAL)) + quantity
                        );
                    return cost;
                },
                BuildType::Plasma => {
                    let techs = self.get_tech_levels(planet_id);
                    Defences::plasma_beam_requirements_check(dockyard_level, techs);
                    let cost = Defences::get_defences_cost(
                        quantity, self.get_defences_cost().plasma
                    );
                    self.check_enough_resources(caller, cost);
                    self.pay_resources_erc20(caller, cost);
                    self
                        .defences_level
                        .write(
                            (planet_id, Names::PLASMA),
                            self.defences_level.read((planet_id, Names::PLASMA)) + quantity
                        );
                    return cost;
                },
            }
        }

        fn get_planet_price(self: @ContractState, time_elapsed: u64) -> u128 {
            let auction = LinearVRGDA {
                target_price: FixedTrait::new(self.token_price.read(), false),
                decay_constant: FixedTrait::new(_0_05, true),
                per_time_unit: FixedTrait::new_unscaled(10, false),
            };
            let planet_sold: u128 = self.number_of_planets.read().into();
            auction
                .get_vrgda_price(
                    FixedTrait::new_unscaled(time_elapsed.into(), false),
                    FixedTrait::new_unscaled(planet_sold, false)
                )
                .mag
                * E18
                / ONE
        }

        // fn calculate_planet_position(self: @ContractState) -> PlanetPosition {
        //     let mut position: PlanetPosition = Default::default();
        //     let rand = self.rand.read();
        //     loop {
        //         position.system = (rand.next() % 200 + 1).try_into().unwrap();
        //         position.orbit = (rand.next() % 10 + 1).try_into().unwrap();
        //         let calculated_token_id = self.position_to_planet.read(position);
        //         if self.planet_position.read(calculated_token_id).is_zero() {
        //             break;
        //         }
        //         continue;
        //     };
        //     position
        // }

        #[inline(always)]
        fn get_position_from_raw(self: @ContractState, raw_position: u16) -> PlanetPosition {
            PlanetPosition {
                system: (raw_position / 10).try_into().unwrap(),
                orbit: (raw_position % 10).try_into().unwrap()
            }
        }


        #[inline(always)]
        fn get_owned_planet(self: @ContractState, caller: ContractAddress) -> u16 {
            let planet_id = self.erc721.read().token_of(caller);
            planet_id.low.try_into().unwrap()
        }

        /// Collects resources for a given contract and caller.
        ///
        /// This function is responsible for gathering resources based on the caller's ownership
        /// of a specific planet token. The production is calculated based on the token's associated planet,
        /// and resources are received using an ERC20 token standard.
        ///
        /// # Parameters
        ///
        /// - `ref self`: Reference to the current contract state.
        /// - `caller`: Address of the caller.
        ///
        /// # Behavior
        ///
        /// - Retrieves the caller's address using the `get_caller_address` function.
        /// - Gets the planet ID that is owned by the caller using `self.get_owned_planet`.
        /// - Calculates the production for the planet using `self.calculate_production`.
        /// - Receives the resources using `self.receive_resources_erc20`.
        /// - Writes the current block timestamp to the `resources_timer` for the planet.
        ///
        fn _collect_resources(ref self: ContractState, caller: ContractAddress) {
            let caller = get_caller_address();
            let planet_id = self.get_owned_planet(caller);
            assert(!planet_id.is_zero(), 'planet does not exist');
            let production = self.calculate_production(planet_id);
            self.receive_resources_erc20(caller, production);
            self.resources_timer.write(planet_id, get_block_timestamp());
        }

        /// Returns the available ERC20 tokens for a specific caller's address.
        ///
        /// This function retrieves the balances of three different tokens: steel, quartz, and tritium,
        /// for the given caller's address.
        ///
        /// # Parameters
        ///
        /// * `self`: The state of the contract, containing the addresses of the ERC20 tokens.
        /// * `caller`: The address of the contract making the call.
        ///
        /// # Returns
        ///
        /// An instance of `ERC20s` struct containing the available balances for steel, quartz, and tritium tokens.
        ///
        fn get_erc20s_available(self: @ContractState, caller: ContractAddress) -> ERC20s {
            let _steel = self.steel.read().balance_of(caller);
            let _quartz = self.quartz.read().balance_of(caller);
            let _tritium = self.tritium.read().balance_of(caller);
            ERC20s {
                steel: _steel.try_into().unwrap(),
                quartz: _quartz.try_into().unwrap(),
                tritium: _tritium.try_into().unwrap()
            }
        }

        /// Calculates the production of resources on a given planet based on the current
        /// state of the contract and the current time.
        ///
        /// # Parameters
        ///
        /// * `self`: A reference to the current state of the contract.
        /// * `planet_id`: The unique identifier for the planet for which to calculate the production.
        ///
        /// # Returns
        ///
        /// Returns a `Resources` structure containing the amounts of steel, quartz, tritium,
        /// and energy produced on the planet since the last collection time.
        ///
        /// # Notes
        ///
        /// This function takes into account various factors like the levels of mines,
        /// available energy, and the time elapsed since the last collection. The production
        /// is then scaled based on available and required energy, and the result is returned
        /// as a `Resources` structure.
        fn calculate_production(self: @ContractState, planet_id: u16) -> ERC20s {
            // let time_now = get_block_timestamp();
            // let last_collection_time = self.resources_timer.read(planet_id);
            // let time_elapsed = time_now - last_collection_time;
            // let position = self.planet_position.read(planet_id);
            // let temp = self.calculate_avg_temperature(position.orbit);
            // let speed = self.uni_speed.read();
            // let steel_available = Production::steel(mines_levels.steel)
            //     * speed
            //     * time_elapsed.into()
            //     / HOUR.into();

            // let quartz_available = Production::quartz(mines_levels.quartz)
            //     * speed
            //     * time_elapsed.into()
            //     / HOUR.into();

            // let tritium_available = Production::tritium(mines_levels.tritium, temp, speed)
            //     * time_elapsed.into()
            //     / HOUR.into();
            let mines_levels = NoGame::get_compounds_levels(self, planet_id);
            let raw = self.get_collectible_resources(planet_id);
            let energy_available = Production::energy(mines_levels.energy);
            let energy_required = Consumption::base(mines_levels.steel)
                + Consumption::base(mines_levels.quartz)
                + Consumption::base(mines_levels.tritium);
            if energy_available < energy_required {
                let _steel = Compounds::production_scaler(
                    raw.steel / 3600, energy_available, energy_required
                );
                let _quartz = Compounds::production_scaler(
                    raw.quartz / 3600, energy_available, energy_required
                );
                let _tritium = Compounds::production_scaler(
                    raw.tritium / 3600, energy_available, energy_required
                );

                return ERC20s { steel: _steel, quartz: _quartz, tritium: _tritium, };
            }

            ERC20s {
                steel: raw.steel / 3600, quartz: raw.quartz / 3600, tritium: raw.tritium / 3600
            }
        }

        fn calculate_energy_consumption(self: @ContractState, planet_id: u16) -> u128 {
            let compounds = self.get_compounds_levels(planet_id);
            Consumption::base(compounds.steel)
                + Consumption::base(compounds.quartz)
                + Consumption::base(compounds.tritium)
        }

        /// Receives resources in ERC20 token format and mints the corresponding amounts to a contract address.
        ///
        /// This function takes in a contract state, a contract address to send the tokens to, and the resources amounts for three different materials: steel, quartz, and tritium.
        /// It retrieves the token addresses for these materials from the contract state and then mints the corresponding amounts in ERC20 tokens.
        ///
        /// # Arguments
        ///
        /// * `self`: The current contract state, must implement the `ContractState` trait.
        /// * `to`: The `ContractAddress` where the ERC20 tokens will be minted.
        /// * `amounts`: A `Resources` struct containing the amounts of steel, quartz, and tritium to mint.
        ///
        fn receive_resources_erc20(self: @ContractState, to: ContractAddress, amounts: ERC20s) {
            self.steel.read().mint(to, (amounts.steel * E18).into());
            self.quartz.read().mint(to, (amounts.quartz * E18).into());
            self.tritium.read().mint(to, (amounts.tritium * E18).into());
        }

        /// Burns the specified amount of ERC20 tokens from the given account.
        ///
        /// This function takes the specified amounts of steel, quartz, and tritium tokens,
        /// multiplies each amount by 10^18 (represented by `E18`), and burns them from the
        /// account's balance.
        ///
        /// # Arguments
        ///
        /// * `self`: A reference to the contract state.
        /// * `account`: The address of the contract containing the ERC20 tokens to be burned.
        /// * `amounts`: An `ERC20s` struct containing the amounts of steel, quartz, and tritium tokens to be burned.
        ///
        /// # Note
        ///
        /// This function internally calls `self.get_tokens_addresses` to obtain the
        /// addresses for the cNGorresponding tokens and leverages the `IERC20Dispatcher` for
        /// the burn operation.
        ///
        fn pay_resources_erc20(self: @ContractState, account: ContractAddress, amounts: ERC20s) {
            self.steel.read().burn(account, (amounts.steel * E18).into());
            self.quartz.read().burn(account, (amounts.quartz * E18).into());
            self.tritium.read().burn(account, (amounts.tritium * E18).into());
        }

        fn receive_loot_erc20(
            self: @ContractState, from: ContractAddress, to: ContractAddress, amounts: ERC20s
        ) {
            self.steel.read().transfer_from(from, to, (amounts.steel * E18).into());
            self.quartz.read().transfer_from(from, to, (amounts.quartz * E18).into());
            self.tritium.read().transfer_from(from, to, (amounts.tritium * E18).into());
        }

        /// Checks if the caller has enough resources based on the provided amounts of ERC20 tokens.
        ///
        /// This function compares the required amounts of steel, quartz, and tritium with the available
        /// amounts for the given caller. The available amounts are scaled down by a factor of E18 (10^18) before
        /// comparison.
        ///
        /// # Arguments
        ///
        /// * `self` - A reference to the contract's current state.
        /// * `caller` - The address of the calling contract.
        /// * `amounts` - A struct containing the amounts of steel, quartz, and tritium that are required.
        ///
        /// # Panics
        ///
        /// The function will panic if:
        /// * The amount of steel required is greater than the available steel scaled down by E18.
        /// * The amount of quartz required is greater than the available quartz scaled down by E18.
        /// * The amount of tritium required is greater than the available tritium scaled down by E18.
        ///
        fn check_enough_resources(self: @ContractState, caller: ContractAddress, amounts: ERC20s) {
            let available: ERC20s = self.get_erc20s_available(caller);
            assert(amounts.steel <= available.steel / E18, 'Not enough steel');
            assert(amounts.quartz <= available.quartz / E18, 'Not enough quartz');
            assert(amounts.tritium <= available.tritium / E18, 'Not enough tritium');
        }

        /// Returns the addresses for various tokens stored within the contract's state.
        ///
        /// This function reads the current addresses for the steel, quartz, and tritium tokens
        /// from the contract's state and returns them encapsulated in a `Tokens` struct.
        ///
        /// # Returns
        /// A `Tokens` struct containing the addresses for the following tokens:
        /// - `steel`: The address of the steel token.
        /// - `quartz`: The address of the quartz token.
        /// - `tritium`: The address of the tritium token.
        ///
        fn get_tokens_addresses(self: @ContractState) -> Tokens {
            Tokens {
                erc721: self.erc721.read().contract_address,
                steel: self.steel.read().contract_address,
                quartz: self.quartz.read().contract_address,
                tritium: self.tritium.read().contract_address
            }
        }

        /// Updates the resource points for a specified planet within a contract state.
        ///
        /// This function adds the total of `spent.steel` and `spent.quartz` to the current resources
        /// spent for the specified `planet_id` in the contract state's resources.
        ///
        /// # Arguments
        ///
        /// * `self`: A mutable reference to the current contract state.
        /// * `planet_id`: The unique identifier of the planet for which the resources are being updated.
        /// * `spent`: A value of type `ERC20s` representing the resources spent, including steel and quartz.
        ///
        fn update_planet_points(ref self: ContractState, planet_id: u16, spent: ERC20s) {
            self.last_active.write(planet_id, get_block_timestamp());
            self
                .resources_spent
                .write(
                    planet_id, self.resources_spent.read(planet_id) + spent.steel + spent.quartz
                );
        }

        /// Returns the time elapsed since the last collection for a specified planet.
        ///
        /// This function calculates the time that has passed since the last resource collection
        /// on a given planet, identified by its `planet_id`.
        ///
        /// # Arguments
        ///
        /// * `self`: A reference to the contract's state.
        /// * `planet_id`: The unique identifier for the planet.
        ///
        /// # Returns
        ///
        /// Returns a 64-bit unsigned integer representing the time in seconds 
        ///
        fn time_since_last_collection(self: @ContractState, planet_id: u16) -> u64 {
            get_block_timestamp() - self.resources_timer.read(planet_id)
        }

        fn get_tech_levels(self: @ContractState, planet_id: u16) -> TechLevels {
            TechLevels {
                energy: self.techs_level.read((planet_id, Names::ENERGY_TECH)),
                digital: self.techs_level.read((planet_id, Names::DIGITAL)),
                beam: self.techs_level.read((planet_id, Names::BEAM_TECH)),
                armour: self.techs_level.read((planet_id, Names::ARMOUR)),
                ion: self.techs_level.read((planet_id, Names::ION)),
                plasma: self.techs_level.read((planet_id, Names::PLASMA_TECH)),
                weapons: self.techs_level.read((planet_id, Names::WEAPONS)),
                shield: self.techs_level.read((planet_id, Names::SHIELD)),
                spacetime: self.techs_level.read((planet_id, Names::SPACETIME)),
                combustion: self.techs_level.read((planet_id, Names::COMBUSTION)),
                thrust: self.techs_level.read((planet_id, Names::THRUST)),
                warp: self.techs_level.read((planet_id, Names::WARP))
            }
        }

        fn fleet_leave_planet(ref self: ContractState, planet_id: u16, fleet: Fleet) {
            let fleet_levels = self.get_ships_levels(planet_id);
            if fleet.carrier > 0 {
                self
                    .ships_level
                    .write((planet_id, Names::CARRIER), fleet_levels.carrier - fleet.carrier);
            }
            if fleet.scraper > 0 {
                self
                    .ships_level
                    .write((planet_id, Names::SCRAPER), fleet_levels.scraper - fleet.scraper);
            }
            if fleet.sparrow > 0 {
                self
                    .ships_level
                    .write((planet_id, Names::SPARROW), fleet_levels.sparrow - fleet.sparrow);
            }
            if fleet.frigate > 0 {
                self
                    .ships_level
                    .write((planet_id, Names::FRIGATE), fleet_levels.frigate - fleet.frigate);
            }
            if fleet.armade > 0 {
                self
                    .ships_level
                    .write((planet_id, Names::ARMADE), fleet_levels.armade - fleet.armade);
            }
        }

        fn fleet_return_planet(ref self: ContractState, planet_id: u16, fleet: Fleet) {
            let fleet_levels = self.get_ships_levels(planet_id);
            if fleet.carrier > 0 {
                self
                    .ships_level
                    .write((planet_id, Names::CARRIER), fleet_levels.carrier + fleet.carrier);
            }
            if fleet.scraper > 0 {
                self
                    .ships_level
                    .write((planet_id, Names::SCRAPER), fleet_levels.scraper + fleet.scraper);
            }
            if fleet.sparrow > 0 {
                self
                    .ships_level
                    .write((planet_id, Names::SPARROW), fleet_levels.sparrow + fleet.sparrow);
            }
            if fleet.frigate > 0 {
                self
                    .ships_level
                    .write((planet_id, Names::FRIGATE), fleet_levels.frigate + fleet.frigate);
            }
            if fleet.armade > 0 {
                self
                    .ships_level
                    .write((planet_id, Names::ARMADE), fleet_levels.armade + fleet.armade);
            }
        }

        fn check_enough_ships(self: @ContractState, planet_id: u16, fleet: Fleet) {
            let ships_levels = self.get_ships_levels(planet_id);
            assert(ships_levels.carrier >= fleet.carrier, 'not enough carrier');
            assert(ships_levels.scraper >= fleet.scraper, 'not enough scrapers');
            assert(ships_levels.sparrow >= fleet.sparrow, 'not enough sparrows');
            assert(ships_levels.frigate >= fleet.frigate, 'not enough frigates');
            assert(ships_levels.armade >= fleet.armade, 'not enough armades');
        }

        fn update_defender_fleet_levels_after_attack(
            ref self: ContractState, planet_id: u16, f: Fleet
        ) {
            self.ships_level.write((planet_id, Names::CARRIER), f.carrier);
            self.ships_level.write((planet_id, Names::SCRAPER), f.scraper);
            self.ships_level.write((planet_id, Names::SPARROW), f.sparrow);
            self.ships_level.write((planet_id, Names::FRIGATE), f.frigate);
            self.ships_level.write((planet_id, Names::ARMADE), f.armade);
        }

        fn update_defences_after_attack(
            ref self: ContractState, planet_id: u16, d: DefencesLevels
        ) {
            self.defences_level.write((planet_id, Names::CELESTIA), d.celestia);
            self.defences_level.write((planet_id, Names::BLASTER), d.blaster);
            self.defences_level.write((planet_id, Names::BEAM), d.beam);
            self.defences_level.write((planet_id, Names::ASTRAL), d.astral);
            self.defences_level.write((planet_id, Names::PLASMA), d.plasma);
        }

        fn add_active_mission(
            ref self: ContractState, planet_id: u16, mut mission: Mission
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

        fn add_hostile_mission(ref self: ContractState, planet_id: u16, mission: HostileMission) {
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

        fn remove_hostile_mission(ref self: ContractState, planet_id: u16, id_to_remove: usize) {
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

        fn position_to_celestia_production(self: @ContractState, orbit: u8) -> u16 {
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

        fn calculate_avg_temperature(self: @ContractState, orbit: u8) -> u16 {
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

        fn calculate_defences_loss(
            self: @ContractState, a: DefencesLevels, b: DefencesLevels
        ) -> DefencesLevels {
            DefencesLevels {
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
            attacker: u16,
            attacker_position: PlanetPosition,
            attacker_initial_fleet: Fleet,
            attacker_fleet_loss: Fleet,
            defender: u16,
            defender_position: PlanetPosition,
            defender_initial_fleet: Fleet,
            defender_fleet_loss: Fleet,
            initial_defences: DefencesLevels,
            defences_loss: DefencesLevels,
            loot: ERC20s,
            debris: Debris
        ) {
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
            ref self: ContractState, planet_id: u16, fleet: Fleet, defences: DefencesLevels
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
                .resources_spent
                .write(
                    planet_id,
                    self.resources_spent.read(planet_id) - (ships_points + defences_points)
                );
        }
    }
}

