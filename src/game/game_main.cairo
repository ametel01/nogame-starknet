#[starknet::contract]
mod NoGame {
    use core::option::OptionTrait;
    use core::traits::{Into, TryInto};
    use starknet::{ContractAddress, get_block_timestamp, get_caller_address, get_contract_address};
    use nogame::game::game_interface::INoGame;
    use nogame::game::game_library::{
        E18, DefencesCost, DefencesLevels, EnergyCost, ERC20s, CompoundsCost, CompoundsLevels,
        Resources, ShipsLevels, ShipsCost, TechLevels, TechsCost, Tokens, LeaderBoard
    };
    use nogame::libraries::lib_compounds::Compounds;
    use nogame::libraries::lib_defences::Defences;
    use nogame::libraries::lib_dockyard::Dockyard;
    use nogame::libraries::lib_research::Lab;
    use nogame::token::token_erc20::INGERC20DispatcherTrait;
    use nogame::token::token_erc20::INGERC20Dispatcher;
    use nogame::token::token_erc721::INGERC721DispatcherTrait;
    use nogame::token::token_erc721::INGERC721Dispatcher;

    use debug::PrintTrait;

    #[storage]
    struct Storage {
        // General.
        number_of_planets: u32,
        universe_start_time: u64,
        planet_generated: LegacyMap::<u128, bool>,
        resources_spent: LegacyMap::<u128, u128>,
        tech_spent: LegacyMap::<u128, u128>,
        fleet_spent: LegacyMap::<u128, u128>,
        point_leader: u128,
        tech_leader: u128,
        fleet_leader: u128,
        // Tokens.
        erc721_address: ContractAddress,
        steel_address: ContractAddress,
        quartz_address: ContractAddress,
        tritium_address: ContractAddress,
        // Infrastructures.
        steel_mine_level: LegacyMap::<u128, u128>,
        quartz_mine_level: LegacyMap::<u128, u128>,
        tritium_mine_level: LegacyMap::<u128, u128>,
        energy_plant_level: LegacyMap::<u128, u128>,
        dockyard_level: LegacyMap::<u128, u128>,
        lab_level: LegacyMap::<u128, u128>,
        resources_timer: LegacyMap::<u128, u64>,
        // Technologies
        energy_innovation_level: LegacyMap::<u128, u128>,
        digital_systems_level: LegacyMap::<u128, u128>,
        beam_technology_level: LegacyMap::<u128, u128>,
        armour_innovation_level: LegacyMap::<u128, u128>,
        ion_systems_level: LegacyMap::<u128, u128>,
        plasma_engineering_level: LegacyMap::<u128, u128>,
        stellar_physics_level: LegacyMap::<u128, u128>,
        weapons_development_level: LegacyMap::<u128, u128>,
        shield_tech_level: LegacyMap::<u128, u128>,
        spacetime_warp_level: LegacyMap::<u128, u128>,
        combustive_engine_level: LegacyMap::<u128, u128>,
        thrust_propulsion_level: LegacyMap::<u128, u128>,
        warp_drive_level: LegacyMap::<u128, u128>,
        // Ships
        carrier_available: LegacyMap::<u128, u128>,
        scraper_available: LegacyMap::<u128, u128>,
        celestia_available: LegacyMap::<u128, u128>,
        sparrow_available: LegacyMap::<u128, u128>,
        frigate_available: LegacyMap::<u128, u128>,
        armade_available: LegacyMap::<u128, u128>,
        // Defences
        blaster_available: LegacyMap::<u128, u128>,
        beam_available: LegacyMap::<u128, u128>,
        astral_launcher_available: LegacyMap::<u128, u128>,
        plasma_projector_available: LegacyMap::<u128, u128>,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        ResourcesSpent: ResourcesSpent,
        TechSpent: TechSpent,
        FleetSpent: FleetSpent,
    }

    // Resources spending events.
    #[derive(Drop, starknet::Event)]
    struct ResourcesSpent {
        planet_id: u128,
        spent: ERC20s
    }

    #[derive(Drop, starknet::Event)]
    struct TechSpent {
        planet_id: u128,
        spent: u128,
    }

    #[derive(Drop, starknet::Event)]
    struct FleetSpent {
        planet_id: u128,
        spent: u128,
    }

    // Structures upgrade events.

    // Constructor
    // #[constructor]
    fn constructor(ref self: ContractState) {
        self.universe_start_time.write(get_block_timestamp());
    }

    #[external(v0)]
    impl NoGame of INoGame<ContractState> {
        fn _initializer(
            ref self: ContractState,
            erc721: ContractAddress,
            steel: ContractAddress,
            quartz: ContractAddress,
            tritium: ContractAddress
        ) {
            self.erc721_address.write(erc721);
            self.steel_address.write(steel);
            self.quartz_address.write(quartz);
            self.tritium_address.write(tritium);
        }

        fn generate_planet(ref self: ContractState) {
            let caller = get_caller_address();
            let number_of_planets = self.number_of_planets.read();
            let token_id: u128 = self.calculate_token_id(number_of_planets);
            INGERC721Dispatcher { contract_address: self.erc721_address.read() }
                .mint(to: caller, token_id: token_id.into());
            self.number_of_planets.write(number_of_planets + 1);
            self.mint_initial_liquidity(caller);
            self.resources_timer.write(token_id, get_block_timestamp());
        }

        fn collect_resources(ref self: ContractState) {
            self._collect_resources(get_caller_address());
        }

        fn steel_mine_upgrade(ref self: ContractState) {
            let caller = get_caller_address();
            self._collect_resources(caller);
            let planet_id = self.get_token_owner(caller);
            let current_level = self.steel_mine_level.read(planet_id);
            let cost: ERC20s = Compounds::steel_mine_cost(current_level);
            self.check_enough_resources(caller, cost);
            self.pay_resources_erc20(caller, cost);
            self.steel_mine_level.write(planet_id, current_level + 1);
            self.update_planet_points(planet_id, cost);
            self.update_resources_spent(planet_id, cost);
            self.update_leaderboard(planet_id);
            self.emit(Event::ResourcesSpent(ResourcesSpent { planet_id: planet_id, spent: cost }))
        }
        fn quartz_mine_upgrade(ref self: ContractState) {
            let caller = get_caller_address();
            self._collect_resources(caller);
            let planet_id = self.get_token_owner(caller);
            let current_level = self.quartz_mine_level.read(planet_id);
            let cost: ERC20s = Compounds::quartz_mine_cost(current_level);
            self.check_enough_resources(caller, cost);
            self.pay_resources_erc20(caller, cost);
            self.quartz_mine_level.write(planet_id, current_level + 1);
            self.update_planet_points(planet_id, cost);
            self.update_resources_spent(planet_id, cost);
            self.update_leaderboard(planet_id);
            self.emit(Event::ResourcesSpent(ResourcesSpent { planet_id: planet_id, spent: cost }))
        }
        fn tritium_mine_upgrade(ref self: ContractState) {
            let caller = get_caller_address();
            self._collect_resources(caller);
            let planet_id = self.get_token_owner(caller);
            let current_level = self.steel_mine_level.read(planet_id);
            let cost: ERC20s = Compounds::tritium_mine_cost(current_level);
            self.check_enough_resources(caller, cost);
            self.pay_resources_erc20(caller, cost);
            self.tritium_mine_level.write(planet_id, current_level + 1);
            self.update_planet_points(planet_id, cost);
            self.update_resources_spent(planet_id, cost);
            self.update_leaderboard(planet_id);
            self.emit(Event::ResourcesSpent(ResourcesSpent { planet_id: planet_id, spent: cost }))
        }
        fn energy_plant_upgrade(ref self: ContractState) {
            let caller = get_caller_address();
            self._collect_resources(caller);
            let planet_id = self.get_token_owner(caller);
            let current_level = self.energy_plant_level.read(planet_id);
            let cost: ERC20s = Compounds::energy_plant_cost(current_level);
            self.check_enough_resources(caller, cost);
            self.pay_resources_erc20(caller, cost);
            self.energy_plant_level.write(planet_id, current_level + 1);
            self.update_planet_points(planet_id, cost);
            self.update_resources_spent(planet_id, cost);
            self.update_leaderboard(planet_id);
            self.emit(Event::ResourcesSpent(ResourcesSpent { planet_id: planet_id, spent: cost }))
        }

        fn dockyard_upgrade(ref self: ContractState) {
            let caller = get_caller_address();
            self._collect_resources(caller);
            let planet_id = self.get_token_owner(caller);
            let current_level = self.dockyard_level.read(planet_id);
            let cost: ERC20s = Compounds::dockyard_cost(current_level);
            self.check_enough_resources(caller, cost);
            self.pay_resources_erc20(caller, cost);
            self.dockyard_level.write(planet_id, current_level + 1);
            self.update_planet_points(planet_id, cost);
            self.update_resources_spent(planet_id, cost);
            self.update_leaderboard(planet_id);
            self.emit(Event::ResourcesSpent(ResourcesSpent { planet_id: planet_id, spent: cost }))
        }
        fn lab_upgrade(ref self: ContractState) {
            let caller = get_caller_address();
            self._collect_resources(caller);
            let planet_id = self.get_token_owner(caller);
            let current_level = self.lab_level.read(planet_id);
            let cost: ERC20s = Compounds::lab_cost(current_level);
            self.check_enough_resources(caller, cost);
            self.pay_resources_erc20(caller, cost);
            self.lab_level.write(planet_id, current_level + 1);
            self.update_planet_points(planet_id, cost);
            self.update_resources_spent(planet_id, cost);
            self.update_leaderboard(planet_id);
            self.emit(Event::ResourcesSpent(ResourcesSpent { planet_id: planet_id, spent: cost }))
        }

        //#########################################################################################
        //                                      TECH UPGRADES FUNCTIONS                           #
        //########################################################################################
        fn energy_innovation_upgrade(ref self: ContractState) {
            let caller = get_caller_address();
            self._collect_resources(caller);
            let planet_id = self.get_token_owner(caller);
            let lab_level = self.lab_level.read(planet_id);
            let techs = self.get_tech_levels(planet_id);
            Lab::energy_innovation_requirements_check(lab_level, techs);
            let cost = self.techs_cost(techs).energy;
            self.check_enough_resources(caller, cost);
            self.pay_resources_erc20(caller, cost);
            self.update_planet_points(planet_id, cost);
            self.update_resources_spent(planet_id, cost);
            self.update_tech_spent(planet_id, cost);
            self.update_leaderboard(planet_id);
            self.energy_innovation_level.write(planet_id, techs.energy + 1);
            self.emit(Event::ResourcesSpent(ResourcesSpent { planet_id: planet_id, spent: cost }))
        }
        fn digital_systems_upgrade(ref self: ContractState) {
            let caller = get_caller_address();
            self._collect_resources(caller);
            let planet_id = self.get_token_owner(caller);
            let lab_level = self.lab_level.read(planet_id);
            let techs = self.get_tech_levels(planet_id);
            Lab::digital_systems_requirements_check(lab_level, techs);
            let cost = self.techs_cost(techs).digital;
            self.check_enough_resources(caller, cost);
            self.pay_resources_erc20(caller, cost);
            self.update_planet_points(planet_id, cost);
            self.update_resources_spent(planet_id, cost);
            self.update_tech_spent(planet_id, cost);
            self.update_leaderboard(planet_id);
            self.digital_systems_level.write(planet_id, techs.digital + 1);
            self.emit(Event::ResourcesSpent(ResourcesSpent { planet_id: planet_id, spent: cost }))
        }
        fn beam_technology_upgrade(ref self: ContractState) {
            let caller = get_caller_address();
            self._collect_resources(caller);
            let planet_id = self.get_token_owner(caller);
            let lab_level = self.lab_level.read(planet_id);
            let techs = self.get_tech_levels(planet_id);
            Lab::beam_technology_requirements_check(lab_level, techs);
            let cost = self.techs_cost(techs).beam;
            self.check_enough_resources(caller, cost);
            self.pay_resources_erc20(caller, cost);
            self.update_planet_points(planet_id, cost);
            self.update_resources_spent(planet_id, cost);
            self.update_tech_spent(planet_id, cost);
            self.update_leaderboard(planet_id);
            self.beam_technology_level.write(planet_id, techs.beam + 1);
            self.emit(Event::ResourcesSpent(ResourcesSpent { planet_id: planet_id, spent: cost }))
        }
        fn armour_innovation_upgrade(ref self: ContractState) {
            let caller = get_caller_address();
            self._collect_resources(caller);
            let planet_id = self.get_token_owner(caller);
            let lab_level = self.lab_level.read(planet_id);
            let techs = self.get_tech_levels(planet_id);
            Lab::armour_innovation_requirements_check(lab_level, techs);
            let cost = self.techs_cost(techs).armour;
            self.check_enough_resources(caller, cost);
            self.pay_resources_erc20(caller, cost);
            self.update_planet_points(planet_id, cost);
            self.update_resources_spent(planet_id, cost);
            self.update_tech_spent(planet_id, cost);
            self.update_leaderboard(planet_id);
            self.armour_innovation_level.write(planet_id, techs.armour + 1);
            self.emit(Event::ResourcesSpent(ResourcesSpent { planet_id: planet_id, spent: cost }))
        }
        fn ion_systems_upgrade(ref self: ContractState) {
            let caller = get_caller_address();
            self._collect_resources(caller);
            let planet_id = self.get_token_owner(caller);
            let lab_level = self.lab_level.read(planet_id);
            let techs = self.get_tech_levels(planet_id);
            Lab::ion_systems_requirements_check(lab_level, techs);
            let cost = self.techs_cost(techs).ion;
            self.check_enough_resources(caller, cost);
            self.pay_resources_erc20(caller, cost);
            self.update_planet_points(planet_id, cost);
            self.update_resources_spent(planet_id, cost);
            self.update_tech_spent(planet_id, cost);
            self.update_leaderboard(planet_id);
            self.ion_systems_level.write(planet_id, techs.ion + 1);
            self.emit(Event::ResourcesSpent(ResourcesSpent { planet_id: planet_id, spent: cost }))
        }
        fn plasma_engineering_upgrade(ref self: ContractState) {
            let caller = get_caller_address();
            self._collect_resources(caller);
            let planet_id = self.get_token_owner(caller);
            let lab_level = self.lab_level.read(planet_id);
            let techs = self.get_tech_levels(planet_id);
            Lab::plasma_engineering_requirements_check(lab_level, techs);
            let cost = self.techs_cost(techs).plasma;
            self.check_enough_resources(caller, cost);
            self.pay_resources_erc20(caller, cost);
            self.update_planet_points(planet_id, cost);
            self.update_resources_spent(planet_id, cost);
            self.update_tech_spent(planet_id, cost);
            self.update_leaderboard(planet_id);
            self.plasma_engineering_level.write(planet_id, techs.plasma + 1);
            self.emit(Event::ResourcesSpent(ResourcesSpent { planet_id: planet_id, spent: cost }))
        }

        fn weapons_development_upgrade(ref self: ContractState) {
            let caller = get_caller_address();
            self._collect_resources(caller);
            let planet_id = self.get_token_owner(caller);
            let lab_level = self.lab_level.read(planet_id);
            let techs = self.get_tech_levels(planet_id);
            Lab::weapons_development_requirements_check(lab_level, techs);
            let cost = self.techs_cost(techs).weapons;
            self.check_enough_resources(caller, cost);
            self.pay_resources_erc20(caller, cost);
            self.update_planet_points(planet_id, cost);
            self.update_resources_spent(planet_id, cost);
            self.update_tech_spent(planet_id, cost);
            self.update_leaderboard(planet_id);
            self.weapons_development_level.write(planet_id, techs.weapons + 1);
            self.emit(Event::ResourcesSpent(ResourcesSpent { planet_id: planet_id, spent: cost }))
        }
        fn shield_tech_upgrade(ref self: ContractState) {
            let caller = get_caller_address();
            self._collect_resources(caller);
            let planet_id = self.get_token_owner(caller);
            let lab_level = self.lab_level.read(planet_id);
            let techs = self.get_tech_levels(planet_id);
            Lab::shield_tech_requirements_check(lab_level, techs);
            let cost = self.techs_cost(techs).shield;
            self.check_enough_resources(caller, cost);
            self.pay_resources_erc20(caller, cost);
            self.update_planet_points(planet_id, cost);
            self.update_resources_spent(planet_id, cost);
            self.update_tech_spent(planet_id, cost);
            self.update_leaderboard(planet_id);
            self.shield_tech_level.write(planet_id, techs.shield + 1);
            self.emit(Event::ResourcesSpent(ResourcesSpent { planet_id: planet_id, spent: cost }))
        }
        fn spacetime_warp_upgrade(ref self: ContractState) {
            let caller = get_caller_address();
            self._collect_resources(caller);
            let planet_id = self.get_token_owner(caller);
            let lab_level = self.lab_level.read(planet_id);
            let techs = self.get_tech_levels(planet_id);
            Lab::spacetime_warp_requirements_check(lab_level, techs);
            let cost = self.techs_cost(techs).spacetime;
            self.check_enough_resources(caller, cost);
            self.pay_resources_erc20(caller, cost);
            self.update_planet_points(planet_id, cost);
            self.update_resources_spent(planet_id, cost);
            self.update_tech_spent(planet_id, cost);
            self.update_leaderboard(planet_id);
            self.spacetime_warp_level.write(planet_id, techs.spacetime + 1);
            self.emit(Event::ResourcesSpent(ResourcesSpent { planet_id: planet_id, spent: cost }))
        }
        fn combustive_engine_upgrade(ref self: ContractState) {
            let caller = get_caller_address();
            self._collect_resources(caller);
            let planet_id = self.get_token_owner(caller);
            let lab_level = self.lab_level.read(planet_id);
            let techs = self.get_tech_levels(planet_id);
            Lab::combustive_engine_requirements_check(lab_level, techs);
            let cost = Lab::get_tech_cost(techs.combustion, 400, 0, 600);
            self.check_enough_resources(caller, cost);
            self.pay_resources_erc20(caller, cost);
            self.update_planet_points(planet_id, cost);
            self.update_resources_spent(planet_id, cost);
            self.update_tech_spent(planet_id, cost);
            self.update_leaderboard(planet_id);
            self.combustive_engine_level.write(planet_id, techs.combustion + 1);
            self.emit(Event::ResourcesSpent(ResourcesSpent { planet_id: planet_id, spent: cost }))
        }
        fn thrust_propulsion_upgrade(ref self: ContractState) {
            let caller = get_caller_address();
            self._collect_resources(caller);
            let planet_id = self.get_token_owner(caller);
            let lab_level = self.lab_level.read(planet_id);
            let techs = self.get_tech_levels(planet_id);
            Lab::thrust_propulsion_requirements_check(lab_level, techs);
            let cost = self.techs_cost(techs).thrust;
            self.check_enough_resources(caller, cost);
            self.pay_resources_erc20(caller, cost);
            self.update_planet_points(planet_id, cost);
            self.update_resources_spent(planet_id, cost);
            self.update_tech_spent(planet_id, cost);
            self.update_leaderboard(planet_id);
            self.thrust_propulsion_level.write(planet_id, techs.thrust + 1);
            self.emit(Event::ResourcesSpent(ResourcesSpent { planet_id: planet_id, spent: cost }))
        }
        fn warp_drive_upgrade(ref self: ContractState) {
            let caller = get_caller_address();
            self._collect_resources(caller);
            let planet_id = self.get_token_owner(caller);
            let lab_level = self.lab_level.read(planet_id);
            let techs = self.get_tech_levels(planet_id);
            Lab::warp_drive_requirements_check(lab_level, techs);
            let cost = self.techs_cost(techs).warp;
            self.check_enough_resources(caller, cost);
            self.pay_resources_erc20(caller, cost);
            self.update_planet_points(planet_id, cost);
            self.update_resources_spent(planet_id, cost);
            self.update_tech_spent(planet_id, cost);
            self.update_leaderboard(planet_id);
            self.warp_drive_level.write(planet_id, techs.warp + 1);
            self.emit(Event::ResourcesSpent(ResourcesSpent { planet_id: planet_id, spent: cost }))
        }
        //#########################################################################################
        //                                      DOCKYARD FUNCTIONS                                #
        //########################################################################################
        fn carrier_build(ref self: ContractState, quantity: u128) {
            let caller = get_caller_address();
            self._collect_resources(caller);
            let planet_id = self.get_token_owner(caller);
            let dockyard_level = self.dockyard_level.read(planet_id);
            let techs = self.get_tech_levels(planet_id);
            Dockyard::carrier_requirements_check(dockyard_level, techs);
            let cost = Dockyard::get_ships_cost(quantity, NoGame::get_ships_cost(@self).carrier);
            self.check_enough_resources(caller, cost);
            self.pay_resources_erc20(caller, cost);
            self.update_planet_points(planet_id, cost);
            self.update_resources_spent(planet_id, cost);
            self.update_fleet_spent(planet_id, cost);
            self.update_leaderboard(planet_id);
            self
                .carrier_available
                .write(planet_id, self.carrier_available.read(planet_id) + quantity);
            self.emit(Event::ResourcesSpent(ResourcesSpent { planet_id: planet_id, spent: cost }))
        }
        fn scraper_build(ref self: ContractState, quantity: u128) {
            let caller = get_caller_address();
            self._collect_resources(caller);
            let planet_id = self.get_token_owner(caller);
            let dockyard_level = self.dockyard_level.read(planet_id);
            let techs = self.get_tech_levels(planet_id);
            Dockyard::scraper_requirements_check(dockyard_level, techs);
            let cost = Dockyard::get_ships_cost(quantity, NoGame::get_ships_cost(@self).scraper);
            self.check_enough_resources(caller, cost);
            self.pay_resources_erc20(caller, cost);
            self.update_planet_points(planet_id, cost);
            self.update_resources_spent(planet_id, cost);
            self.update_fleet_spent(planet_id, cost);
            self.update_leaderboard(planet_id);
            self
                .scraper_available
                .write(planet_id, self.scraper_available.read(planet_id) + quantity);
            self.emit(Event::ResourcesSpent(ResourcesSpent { planet_id: planet_id, spent: cost }))
        }
        fn celestia_build(ref self: ContractState, quantity: u128) {
            let caller = get_caller_address();
            self._collect_resources(caller);
            let planet_id = self.get_token_owner(caller);
            let dockyard_level = self.dockyard_level.read(planet_id);
            let techs = self.get_tech_levels(planet_id);
            Dockyard::celestia_requirements_check(dockyard_level, techs);
            let cost = Dockyard::get_ships_cost(quantity, NoGame::get_ships_cost(@self).celestia);
            self.check_enough_resources(caller, cost);
            self.pay_resources_erc20(caller, cost);
            self.update_planet_points(planet_id, cost);
            self.update_resources_spent(planet_id, cost);
            self.update_fleet_spent(planet_id, cost);
            self.update_leaderboard(planet_id);
            self
                .celestia_available
                .write(planet_id, self.celestia_available.read(planet_id) + quantity);
            self.emit(Event::ResourcesSpent(ResourcesSpent { planet_id: planet_id, spent: cost }))
        }
        fn sparrow_build(ref self: ContractState, quantity: u128) {
            let caller = get_caller_address();
            self._collect_resources(caller);
            let planet_id = self.get_token_owner(caller);
            let dockyard_level = self.dockyard_level.read(planet_id);
            let techs = self.get_tech_levels(planet_id);
            Dockyard::sparrow_requirements_check(dockyard_level, techs);
            let cost = Dockyard::get_ships_cost(quantity, NoGame::get_ships_cost(@self).sparrow);
            self.check_enough_resources(caller, cost);
            self.pay_resources_erc20(caller, cost);
            self.update_planet_points(planet_id, cost);
            self.update_resources_spent(planet_id, cost);
            self.update_fleet_spent(planet_id, cost);
            self.update_leaderboard(planet_id);
            self
                .sparrow_available
                .write(planet_id, self.sparrow_available.read(planet_id) + quantity);
            self.emit(Event::ResourcesSpent(ResourcesSpent { planet_id: planet_id, spent: cost }))
        }
        fn frigate_build(ref self: ContractState, quantity: u128) {
            let caller = get_caller_address();
            self._collect_resources(caller);
            let planet_id = self.get_token_owner(caller);
            let dockyard_level = self.dockyard_level.read(planet_id);
            let techs = self.get_tech_levels(planet_id);
            Dockyard::frigate_requirements_check(dockyard_level, techs);
            let cost = Dockyard::get_ships_cost(quantity, NoGame::get_ships_cost(@self).frigate);
            self.check_enough_resources(caller, cost);
            self.pay_resources_erc20(caller, cost);
            self.update_planet_points(planet_id, cost);
            self.update_resources_spent(planet_id, cost);
            self.update_fleet_spent(planet_id, cost);
            self.update_leaderboard(planet_id);
            self
                .frigate_available
                .write(planet_id, self.frigate_available.read(planet_id) + quantity);
            self.emit(Event::ResourcesSpent(ResourcesSpent { planet_id: planet_id, spent: cost }))
        }
        fn armade_build(ref self: ContractState, quantity: u128) {
            let caller = get_caller_address();
            self._collect_resources(caller);
            let planet_id = self.get_token_owner(caller);
            let dockyard_level = self.dockyard_level.read(planet_id);
            let techs = self.get_tech_levels(planet_id);
            Dockyard::armade_requirements_check(dockyard_level, techs);
            let cost = Dockyard::get_ships_cost(quantity, NoGame::get_ships_cost(@self).armade);
            self.check_enough_resources(caller, cost);
            self.pay_resources_erc20(caller, cost);
            self.update_planet_points(planet_id, cost);
            self.update_resources_spent(planet_id, cost);
            self.update_fleet_spent(planet_id, cost);
            self.update_leaderboard(planet_id);
            self
                .armade_available
                .write(planet_id, self.armade_available.read(planet_id) + quantity);
            self.emit(Event::ResourcesSpent(ResourcesSpent { planet_id: planet_id, spent: cost }))
        }

        //#########################################################################################
        //                                      DEFENCES FUNCTIONS                                #
        //########################################################################################
        fn blaster_build(ref self: ContractState, quantity: u128) {
            let caller = get_caller_address();
            self._collect_resources(caller);
            let planet_id = self.get_token_owner(caller);
            let dockyard_level = self.dockyard_level.read(planet_id);
            let techs = self.get_tech_levels(planet_id);
            Defences::blaster_requirements_check(dockyard_level, techs);
            let cost = Defences::get_defences_cost(quantity, 2000, 0, 0);
            self.check_enough_resources(caller, cost);
            self.pay_resources_erc20(caller, cost);
            self.update_planet_points(planet_id, cost);
            self.update_resources_spent(planet_id, cost);
            self.update_fleet_spent(planet_id, cost);
            self.update_leaderboard(planet_id);
            self
                .blaster_available
                .write(planet_id, self.blaster_available.read(planet_id) + quantity);
            self.emit(Event::ResourcesSpent(ResourcesSpent { planet_id: planet_id, spent: cost }))
        }
        fn beam_build(ref self: ContractState, quantity: u128) {
            let caller = get_caller_address();
            self._collect_resources(caller);
            let planet_id = self.get_token_owner(caller);
            let dockyard_level = self.dockyard_level.read(planet_id);
            let techs = self.get_tech_levels(planet_id);
            Defences::beam_requirements_check(dockyard_level, techs);
            let cost = Defences::get_defences_cost(quantity, 6000, 2000, 0);
            self.check_enough_resources(caller, cost);
            self.pay_resources_erc20(caller, cost);
            self.update_planet_points(planet_id, cost);
            self.update_resources_spent(planet_id, cost);
            self.update_fleet_spent(planet_id, cost);
            self.update_leaderboard(planet_id);
            self.beam_available.write(planet_id, self.beam_available.read(planet_id) + quantity);
            self.emit(Event::ResourcesSpent(ResourcesSpent { planet_id: planet_id, spent: cost }))
        }
        fn astral_launcher_build(ref self: ContractState, quantity: u128) {
            let caller = get_caller_address();
            self._collect_resources(caller);
            let planet_id = self.get_token_owner(caller);
            let dockyard_level = self.dockyard_level.read(planet_id);
            let techs = self.get_tech_levels(planet_id);
            Defences::astral_launcher_requirements_check(dockyard_level, techs);
            let cost = Defences::get_defences_cost(quantity, 20000, 15000, 2000);
            self.check_enough_resources(caller, cost);
            self.pay_resources_erc20(caller, cost);
            self.update_planet_points(planet_id, cost);
            self.update_resources_spent(planet_id, cost);
            self.update_fleet_spent(planet_id, cost);
            self.update_leaderboard(planet_id);
            self
                .astral_launcher_available
                .write(planet_id, self.astral_launcher_available.read(planet_id) + quantity);
            self.emit(Event::ResourcesSpent(ResourcesSpent { planet_id: planet_id, spent: cost }))
        }
        fn plasma_projector_build(ref self: ContractState, quantity: u128) {
            let caller = get_caller_address();
            self._collect_resources(caller);
            let planet_id = self.get_token_owner(caller);
            let dockyard_level = self.dockyard_level.read(planet_id);
            let techs = self.get_tech_levels(planet_id);
            Defences::plasma_beam_requirements_check(dockyard_level, techs);
            let cost = Defences::get_defences_cost(quantity, 50000, 50000, 30000);
            self.pay_resources_erc20(caller, cost);
            self.update_planet_points(planet_id, cost);
            self.update_resources_spent(planet_id, cost);
            self.update_fleet_spent(planet_id, cost);
            self.update_leaderboard(planet_id);
            self
                .plasma_projector_available
                .write(planet_id, self.plasma_projector_available.read(planet_id) + quantity);
            self.emit(Event::ResourcesSpent(ResourcesSpent { planet_id: planet_id, spent: cost }))
        }

        //#########################################################################################
        //                                      VIEW FUNCTIONS                                #
        //########################################################################################

        fn get_token_addresses(self: @ContractState) -> Tokens {
            self.get_tokens_addresses()
        }

        fn get_number_of_planets(self: @ContractState) -> u32 {
            self.number_of_planets.read()
        }

        fn get_leaderboard(self: @ContractState) -> LeaderBoard {
            LeaderBoard {
                point_leader: self.point_leader.read(),
                tech_leader: self.tech_leader.read(),
                fleet_leader: self.fleet_leader.read()
            }
        }

        fn get_planet_points(self: @ContractState, planet_id: u128) -> u128 {
            self.resources_spent.read(planet_id) / 1000
        }

        fn get_spendable_resources(self: @ContractState, planet_id: u128) -> ERC20s {
            let planet_owner = INGERC721Dispatcher { contract_address: self.erc721_address.read() }
                .owner_of(planet_id.into());
            let steel: u128 = INGERC20Dispatcher { contract_address: self.steel_address.read() }
                .balance_of(planet_owner)
                .try_into()
                .unwrap();
            let quartz: u128 = INGERC20Dispatcher { contract_address: self.quartz_address.read() }
                .balance_of(planet_owner)
                .try_into()
                .unwrap();
            let tritium: u128 = INGERC20Dispatcher { contract_address: self.tritium_address.read() }
                .balance_of(planet_owner)
                .try_into()
                .unwrap();
            ERC20s { steel: steel, quartz: quartz, tritium: tritium }
        }

        fn get_collectible_resources(self: @ContractState, planet_id: u128) -> ERC20s {
            let time_elapsed = self.time_since_last_collection(planet_id);
            let steel = Compounds::steel_production(self.steel_mine_level.read(planet_id))
                * time_elapsed.into()
                / 3600;
            let quartz = Compounds::quartz_production(self.quartz_mine_level.read(planet_id))
                * time_elapsed.into()
                / 3600;
            let tritium = Compounds::tritium_production(self.tritium_mine_level.read(planet_id))
                * time_elapsed.into()
                / 3600;
            ERC20s { steel: steel, quartz: quartz, tritium: tritium }
        }

        fn get_energy_available(self: @ContractState, planet_id: u128) -> u128 {
            let compounds_levels = NoGame::get_compounds_levels(self, planet_id);
            let gross_production = Compounds::energy_plant_production(
                self.energy_plant_level.read(planet_id)
            );
            let celestia_production = self.celestia_available.read(planet_id) * 15;
            let energy_required = self.calculate_energy_consumption(compounds_levels);
            if (gross_production + celestia_production) < energy_required {
                return 0;
            } else {
                return gross_production + celestia_production - energy_required;
            }
        }

        fn get_compounds_levels(self: @ContractState, planet_id: u128) -> CompoundsLevels {
            (CompoundsLevels {
                steel: self.steel_mine_level.read(planet_id),
                quartz: self.quartz_mine_level.read(planet_id),
                tritium: self.tritium_mine_level.read(planet_id),
                energy: self.energy_plant_level.read(planet_id),
                lab: self.lab_level.read(planet_id),
                dockyard: self.dockyard_level.read(planet_id)
            })
        }

        fn get_compounds_upgrade_cost(self: @ContractState, planet_id: u128) -> CompoundsCost {
            let steel = Compounds::steel_mine_cost(self.steel_mine_level.read(planet_id));
            let quartz = Compounds::quartz_mine_cost(self.quartz_mine_level.read(planet_id));
            let tritium = Compounds::tritium_mine_cost(self.tritium_mine_level.read(planet_id));
            let energy = Compounds::energy_plant_cost(self.energy_plant_level.read(planet_id));
            let lab = Compounds::lab_cost(self.lab_level.read(planet_id));
            let dockyard = Compounds::dockyard_cost(self.dockyard_level.read(planet_id));
            CompoundsCost {
                steel: steel,
                quartz: quartz,
                tritium: tritium,
                energy: energy,
                lab: lab,
                dockyard: dockyard
            }
        }

        fn get_energy_for_upgrade(self: @ContractState, planet_id: u128) -> EnergyCost {
            let steel = Compounds::base_mine_consumption(self.steel_mine_level.read(planet_id) + 1)
                - Compounds::base_mine_consumption(self.steel_mine_level.read(planet_id));
            let quartz = Compounds::base_mine_consumption(
                self.quartz_mine_level.read(planet_id) + 1
            )
                - Compounds::base_mine_consumption(self.quartz_mine_level.read(planet_id));
            let tritium = Compounds::tritium_mine_consumption(
                self.tritium_mine_level.read(planet_id) + 1
            )
                - Compounds::tritium_mine_consumption(self.tritium_mine_level.read(planet_id));

            EnergyCost { steel: steel, quartz: quartz, tritium: tritium }
        }

        fn get_techs_levels(self: @ContractState, planet_id: u128) -> TechLevels {
            self.get_tech_levels(planet_id)
        }

        fn get_techs_upgrade_cost(self: @ContractState, planet_id: u128) -> TechsCost {
            let techs = self.get_tech_levels(planet_id);
            self.techs_cost(techs)
        }

        fn get_ships_levels(self: @ContractState, planet_id: u128) -> ShipsLevels {
            ShipsLevels {
                carrier: self.carrier_available.read(planet_id),
                celestia: self.celestia_available.read(planet_id),
                scraper: self.scraper_available.read(planet_id),
                sparrow: self.sparrow_available.read(planet_id),
                frigate: self.frigate_available.read(planet_id),
                armade: self.armade_available.read(planet_id)
            }
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

        fn get_defences_levels(self: @ContractState, planet_id: u128) -> DefencesLevels {
            DefencesLevels {
                blaster: self.blaster_available.read(planet_id),
                beam: self.beam_available.read(planet_id),
                astral: self.astral_launcher_available.read(planet_id),
                plasma: self.plasma_projector_available.read(planet_id),
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
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn calculate_token_id(ref self: ContractState, n: u32) -> u128 {
            if n % 2 == 0 {
                return 100 * (n.into() / 2 + 1) + 4;
            } else {
                return 100 * ((n.into() + 1) / 2) + 8;
            }
        }

        fn get_token_owner(self: @ContractState, caller: ContractAddress) -> u128 {
            let erc721 = self.erc721_address.read();
            let planet_id = INGERC721Dispatcher { contract_address: erc721 }.token_of(caller);
            planet_id.low
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
        /// - Gets the planet ID that is owned by the caller using `self.get_token_owner`.
        /// - Calculates the production for the planet using `self.calculate_production`.
        /// - Receives the resources using `self.receive_resources_erc20`.
        /// - Writes the current block timestamp to the `resources_timer` for the planet.
        ///
        fn _collect_resources(ref self: ContractState, caller: ContractAddress) {
            let caller = get_caller_address();
            let planet_id = self.get_token_owner(caller);
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
            let _steel = INGERC20Dispatcher { contract_address: self.steel_address.read() }
                .balance_of(caller);
            // let steel_total = Mines::steel_production(steel_level) + steel_available;

            let _quartz = INGERC20Dispatcher { contract_address: self.quartz_address.read() }
                .balance_of(caller);
            // let quartz_total = Mines::quartz_production(quartz_level) + quartz_available;

            let _tritium = INGERC20Dispatcher { contract_address: self.tritium_address.read() }
                .balance_of(caller);
            // let steel_produced = Mines::steel_production(steel_level) + steel_available;
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
        fn calculate_production(self: @ContractState, planet_id: u128) -> Resources {
            let time_now = get_block_timestamp();
            let last_collection_time = self.resources_timer.read(planet_id);
            let time_elapsed: u128 = (time_now - last_collection_time).into();
            let mines_levels = NoGame::get_compounds_levels(self, planet_id);
            let steel_available = Compounds::steel_production(mines_levels.steel)
                * time_elapsed
                / 3600;

            let quartz_available = Compounds::quartz_production(mines_levels.quartz)
                * time_elapsed
                / 3600;

            let tritium_available = Compounds::tritium_production(mines_levels.tritium)
                * time_elapsed
                / 3600;
            let energy_available = Compounds::energy_plant_production(mines_levels.energy);
            let energy_required = Compounds::base_mine_consumption(mines_levels.steel)
                + Compounds::base_mine_consumption(mines_levels.quartz)
                + Compounds::tritium_mine_consumption(mines_levels.tritium);
            if energy_available < energy_required {
                let _steel = Compounds::production_scaler(
                    steel_available, energy_available, energy_required
                );
                let _quartz = Compounds::production_scaler(
                    quartz_available, energy_available, energy_required
                );
                let _tritium = Compounds::production_scaler(
                    tritium_available, energy_available, energy_required
                );

                return Resources {
                    steel: _steel,
                    quartz: _quartz,
                    tritium: _tritium,
                    energy: energy_available - energy_required
                };
            }

            Resources {
                steel: steel_available,
                quartz: quartz_available,
                tritium: tritium_available,
                energy: energy_available - energy_required
            }
        }

        fn calculate_energy_consumption(self: @ContractState, compounds: CompoundsLevels) -> u128 {
            Compounds::base_mine_consumption(compounds.steel)
                + Compounds::base_mine_consumption(compounds.quartz)
                + Compounds::tritium_mine_consumption(compounds.tritium)
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
        fn receive_resources_erc20(self: @ContractState, to: ContractAddress, amounts: Resources) {
            let tokens: Tokens = self.get_tokens_addresses();
            INGERC20Dispatcher { contract_address: tokens.steel }
                .mint(to, (amounts.steel * E18).into());
            INGERC20Dispatcher { contract_address: tokens.quartz }
                .mint(to, (amounts.quartz * E18).into());
            INGERC20Dispatcher { contract_address: tokens.tritium }
                .mint(to, (amounts.tritium * E18).into())
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
            let tokens: Tokens = self.get_tokens_addresses();
            INGERC20Dispatcher { contract_address: tokens.steel }
                .burn(account, (amounts.steel * E18).into());
            INGERC20Dispatcher { contract_address: tokens.quartz }
                .burn(account, (amounts.quartz * E18).into());
            INGERC20Dispatcher { contract_address: tokens.tritium }
                .burn(account, (amounts.tritium * E18).into())
        }

        /// Mints initial liquidity to the given account.
        ///
        /// This function is responsible for minting an initial set of tokens to the specified account. 
        /// The tokens minted include Steel, Quartz, and Tritium, with specific quantities of each.
        ///
        /// # Arguments
        ///
        /// * `self: @ContractState` - The current state of the contract.
        /// * `account: ContractAddress` - The contract address to which the initial liquidity will be minted.
        ///
        /// # Tokens Minted
        ///
        /// * Steel: 500 * 10^18
        /// * Quartz: 300 * 10^18
        /// * Tritium: 100 * 10^18
        ///
        /// # Note
        ///
        /// This function should only be called at the appropriate stage in the contract lifecycle, such as during initialization or under specific conditions set forth in the contract.
        ///
        fn mint_initial_liquidity(self: @ContractState, account: ContractAddress) {
            let tokens: Tokens = self.get_tokens_addresses();
            INGERC20Dispatcher { contract_address: tokens.steel }
                .mint(recipient: account, amount: (500 * E18).into());
            INGERC20Dispatcher { contract_address: tokens.quartz }
                .mint(recipient: account, amount: (300 * E18).into());
            INGERC20Dispatcher { contract_address: tokens.tritium }
                .mint(recipient: account, amount: (100 * E18).into());
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
                erc721: self.erc721_address.read(),
                steel: self.steel_address.read(),
                quartz: self.quartz_address.read(),
                tritium: self.tritium_address.read()
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
        fn update_planet_points(ref self: ContractState, planet_id: u128, spent: ERC20s) {
            self
                .resources_spent
                .write(
                    planet_id, self.resources_spent.read(planet_id) + spent.steel + spent.quartz
                );
        }

        /// Updates the total resources spent for a specific planet within a contract.
        ///
        /// This method reads the current fleet spent for the given `planet_id` and then updates the `tech_spent` 
        /// with the sum of the current spent, steel cost, and quartz cost.
        ///
        /// # Arguments
        ///
        /// * `ref self` - A reference to the contract's state.
        /// * `planet_id` - The unique identifier for the planet for which the fleet spending needs to be updated.
        /// * `cost` - An instance of the `ERC20s` struct containing the cost details in steel and quartz.
        ///
        fn update_resources_spent(ref self: ContractState, planet_id: u128, cost: ERC20s) {
            let current_spent = self.resources_spent.read(planet_id);
            self.resources_spent.write(planet_id, current_spent + cost.steel + cost.quartz);
        }

        /// Updates the tech spent for a specific planet within a contract.
        ///
        /// This method reads the current fleet spent for the given `planet_id` and then updates the `tech_spent` 
        /// with the sum of the current spent, steel cost, and quartz cost.
        ///
        /// # Arguments
        ///
        /// * `ref self` - A reference to the contract's state.
        /// * `planet_id` - The unique identifier for the planet for which the fleet spending needs to be updated.
        /// * `cost` - An instance of the `ERC20s` struct containing the cost details in steel and quartz.
        ///
        fn update_tech_spent(ref self: ContractState, planet_id: u128, cost: ERC20s) {
            let current_spent = self.tech_spent.read(planet_id);
            self.tech_spent.write(planet_id, current_spent + cost.steel + cost.quartz);
        }

        /// Updates the fleet spent for a specific.
        ///
        /// This method reads the current fleet spent for the given `planet_id` and then updates the `tech_spent` 
        /// with the sum of the current spent, steel cost, and quartz cost.
        ///
        /// # Arguments
        ///
        /// * `ref self` - A reference to the contract's state.
        /// * `planet_id` - The unique identifier for the planet for which the fleet spending needs to be updated.
        /// * `cost` - An instance of the `ERC20s` struct containing the cost details in steel and quartz.
        ///
        fn update_fleet_spent(ref self: ContractState, planet_id: u128, cost: ERC20s) {
            let current_spent = self.fleet_spent.read(planet_id);
            self.tech_spent.write(planet_id, current_spent + cost.steel + cost.quartz);
        }

        /// Updates the leaderboard of the contract state based on the resources, tech, and fleet spent.
        ///
        /// The function compares the resources, tech, and fleet spent on a given planet with the
        /// current leaders in each category. If the given planet has spent more in any of these
        /// categories, it becomes the new leader.
        ///
        /// # Arguments
        ///
        /// * `ref self`: Reference to the contract state that contains the current leaders and the amount spent.
        /// * `planet_id`: The unique identifier of the planet for which the leaderboard is to be updated.
        ///
        fn update_leaderboard(ref self: ContractState, planet_id: u128) {
            if self
                .resources_spent
                .read(planet_id) > self
                .resources_spent
                .read(self.point_leader.read()) {
                self.point_leader.write(planet_id);
            }
            if self.tech_spent.read(planet_id) > self.tech_spent.read(self.tech_leader.read()) {
                self.tech_leader.write(planet_id);
            }
            if self.fleet_spent.read(planet_id) > self.fleet_spent.read(self.fleet_leader.read()) {
                self.fleet_leader.write(planet_id);
            }
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
        fn time_since_last_collection(self: @ContractState, planet_id: u128) -> u64 {
            get_block_timestamp() - self.resources_timer.read(planet_id)
        }

        fn get_tech_levels(self: @ContractState, planet_id: u128) -> TechLevels {
            TechLevels {
                energy: self.energy_innovation_level.read(planet_id),
                digital: self.digital_systems_level.read(planet_id),
                beam: self.beam_technology_level.read(planet_id),
                armour: self.armour_innovation_level.read(planet_id),
                ion: self.ion_systems_level.read(planet_id),
                plasma: self.plasma_engineering_level.read(planet_id),
                weapons: self.weapons_development_level.read(planet_id),
                shield: self.shield_tech_level.read(planet_id),
                spacetime: self.spacetime_warp_level.read(planet_id),
                combustion: self.combustive_engine_level.read(planet_id),
                thrust: self.thrust_propulsion_level.read(planet_id),
                warp: self.warp_drive_level.read(planet_id)
            }
        }

        fn techs_cost(self: @ContractState, techs: TechLevels) -> TechsCost {
            let energy = Lab::get_tech_cost(techs.energy, 0, 800, 400);
            let digital = Lab::get_tech_cost(techs.digital, 0, 400, 600);
            let beam = Lab::get_tech_cost(techs.beam, 0, 800, 400);
            let ion = Lab::get_tech_cost(techs.ion, 1000, 300, 1000);
            let plasma = Lab::get_tech_cost(techs.plasma, 2000, 4000, 1000);
            let spacetime = Lab::get_tech_cost(techs.spacetime, 0, 4000, 2000);
            let combustion = Lab::get_tech_cost(techs.combustion, 400, 0, 600);
            let thrust = Lab::get_tech_cost(techs.thrust, 2000, 4000, 600);
            let warp = Lab::get_tech_cost(techs.warp, 10000, 2000, 6000);
            let armour = Lab::get_tech_cost(techs.armour, 1000, 0, 0);
            let weapons = Lab::get_tech_cost(techs.weapons, 800, 200, 0);
            let shield = Lab::get_tech_cost(techs.shield, 200, 600, 0);

            TechsCost {
                energy: energy,
                digital: digital,
                beam: beam,
                ion: ion,
                plasma: plasma,
                spacetime: spacetime,
                combustion: combustion,
                thrust: thrust,
                warp: warp,
                armour: armour,
                weapons: weapons,
                shield: shield
            }
        }
    }
}

