#[starknet::contract]
mod NoGame {
    use core::option::OptionTrait;
    use core::traits::{Into, TryInto};
    use starknet::{ContractAddress, get_block_timestamp, get_caller_address, get_contract_address};
    use nogame::game::interface::INoGame;
    use nogame::game::library::{
        E18, DefencesCost, DefencesLevels, EnergyCost, ERC20s, CompoundsCost, CompoundsLevels,
        Resources, ShipsLevels, ShipsCost, TechLevels, TechsCost, Tokens, LeaderBoard
    };
    use nogame::libraries::compounds::Compounds;
    use nogame::libraries::defences::Defences;
    use nogame::libraries::dockyard::Dockyard;
    use nogame::libraries::research::Lab;
    use nogame::token::erc20::IERC20DispatcherTrait;
    use nogame::token::erc20::IERC20Dispatcher;
    use nogame::token::erc721::INGERC721DispatcherTrait;
    use nogame::token::erc721::INGERC721Dispatcher;

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
        resources_timer: LegacyMap::<u120, u64>,
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
        plasma_beam_available: LegacyMap::<u128, u128>,
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

        //#########################################################################################
        //                                      EXTERNAL FUNCTIONS                                #
        //########################################################################################
        fn generate_planet(ref self: ContractState) {
            let caller = get_caller_address();
            let number_of_planets = self.number_of_planets.read();
            let token_id: u128 = (number_of_planets + 1).into();
            INGERC721Dispatcher {
                contract_address: self.erc721_address.read()
            }.mint(to: caller, token_id: token_id.into());
            self.number_of_planets.write(number_of_planets + 1);
            PrivateFunctions::mint_initial_liquidity(@self, caller);
            self.resources_timer.write(token_id, get_block_timestamp());
        }

        fn collect_resources(ref self: ContractState) {
            let caller = get_caller_address();
            PrivateFunctions::collect_resources(ref self, caller);
        }
        //#########################################################################################
        //                               COMPOUNDS UPGRADE FUNCTIONS                                  #
        //########################################################################################
        fn steel_mine_upgrade(ref self: ContractState) {
            let caller = get_caller_address();
            PrivateFunctions::collect_resources(ref self, caller);
            let planet_id = PrivateFunctions::get_token_owner(@self, caller);
            let current_level = self.steel_mine_level.read(planet_id);
            let cost: ERC20s = Compounds::steel_mine_cost(current_level);
            PrivateFunctions::check_enough_resources(@self, caller, cost);
            PrivateFunctions::pay_resources_erc20(@self, caller, cost);
            self.steel_mine_level.write(planet_id, current_level + 1);
            PrivateFunctions::update_planet_points(ref self, planet_id, cost);
            PrivateFunctions::update_resources_spent(ref self, planet_id, cost);
            PrivateFunctions::update_leaderboard(ref self, planet_id);
            self.emit(Event::ResourcesSpent(ResourcesSpent { planet_id: planet_id, spent: cost }))
        }
        fn quartz_mine_upgrade(ref self: ContractState) {
            let caller = get_caller_address();
            PrivateFunctions::collect_resources(ref self, caller);
            let planet_id = PrivateFunctions::get_token_owner(@self, caller);
            let current_level = self.quartz_mine_level.read(planet_id);
            let cost: ERC20s = Compounds::quartz_mine_cost(current_level);
            PrivateFunctions::check_enough_resources(@self, caller, cost);
            PrivateFunctions::pay_resources_erc20(@self, caller, cost);
            self.quartz_mine_level.write(planet_id, current_level + 1);
            PrivateFunctions::update_planet_points(ref self, planet_id, cost);
            PrivateFunctions::update_resources_spent(ref self, planet_id, cost);
            PrivateFunctions::update_leaderboard(ref self, planet_id);
            self.emit(Event::ResourcesSpent(ResourcesSpent { planet_id: planet_id, spent: cost }))
        }
        fn tritium_mine_upgrade(ref self: ContractState) {
            let caller = get_caller_address();
            PrivateFunctions::collect_resources(ref self, caller);
            let planet_id = PrivateFunctions::get_token_owner(@self, caller);
            let current_level = self.steel_mine_level.read(planet_id);
            let cost: ERC20s = Compounds::tritium_mine_cost(current_level);
            PrivateFunctions::check_enough_resources(@self, caller, cost);
            PrivateFunctions::pay_resources_erc20(@self, caller, cost);
            self.tritium_mine_level.write(planet_id, current_level + 1);
            PrivateFunctions::update_planet_points(ref self, planet_id, cost);
            PrivateFunctions::update_resources_spent(ref self, planet_id, cost);
            PrivateFunctions::update_leaderboard(ref self, planet_id);
            self.emit(Event::ResourcesSpent(ResourcesSpent { planet_id: planet_id, spent: cost }))
        }
        fn energy_plant_upgrade(ref self: ContractState) {
            let caller = get_caller_address();
            PrivateFunctions::collect_resources(ref self, caller);
            let planet_id = PrivateFunctions::get_token_owner(@self, caller);
            let current_level = self.energy_plant_level.read(planet_id);
            let cost: ERC20s = Compounds::energy_plant_cost(current_level);
            PrivateFunctions::check_enough_resources(@self, caller, cost);
            PrivateFunctions::pay_resources_erc20(@self, caller, cost);
            self.energy_plant_level.write(planet_id, current_level + 1);
            PrivateFunctions::update_planet_points(ref self, planet_id, cost);
            PrivateFunctions::update_resources_spent(ref self, planet_id, cost);
            PrivateFunctions::update_leaderboard(ref self, planet_id);
            self.emit(Event::ResourcesSpent(ResourcesSpent { planet_id: planet_id, spent: cost }))
        }

        fn dockyard_upgrade(ref self: ContractState) {
            let caller = get_caller_address();
            PrivateFunctions::collect_resources(ref self, caller);
            let planet_id = PrivateFunctions::get_token_owner(@self, caller);
            let current_level = self.dockyard_level.read(planet_id);
            let cost: ERC20s = Compounds::dockyard_cost(current_level);
            PrivateFunctions::check_enough_resources(@self, caller, cost);
            PrivateFunctions::pay_resources_erc20(@self, caller, cost);
            self.dockyard_level.write(planet_id, current_level + 1);
            PrivateFunctions::update_planet_points(ref self, planet_id, cost);
            PrivateFunctions::update_resources_spent(ref self, planet_id, cost);
            PrivateFunctions::update_leaderboard(ref self, planet_id);
            self.emit(Event::ResourcesSpent(ResourcesSpent { planet_id: planet_id, spent: cost }))
        }
        fn lab_upgrade(ref self: ContractState) {
            let caller = get_caller_address();
            PrivateFunctions::collect_resources(ref self, caller);
            let planet_id = PrivateFunctions::get_token_owner(@self, caller);
            let current_level = self.lab_level.read(planet_id);
            let cost: ERC20s = Compounds::lab_cost(current_level);
            PrivateFunctions::check_enough_resources(@self, caller, cost);
            PrivateFunctions::pay_resources_erc20(@self, caller, cost);
            self.lab_level.write(planet_id, current_level + 1);
            PrivateFunctions::update_planet_points(ref self, planet_id, cost);
            PrivateFunctions::update_resources_spent(ref self, planet_id, cost);
            PrivateFunctions::update_leaderboard(ref self, planet_id);
            self.emit(Event::ResourcesSpent(ResourcesSpent { planet_id: planet_id, spent: cost }))
        }

        //#########################################################################################
        //                                      TECH UPGRADES FUNCTIONS                           #
        //########################################################################################
        fn energy_innovation_upgrade(ref self: ContractState) {
            let caller = get_caller_address();
            PrivateFunctions::collect_resources(ref self, caller);
            let planet_id = PrivateFunctions::get_token_owner(@self, caller);
            let lab_level = self.lab_level.read(planet_id);
            let techs = PrivateFunctions::get_tech_levels(@self, planet_id);
            Lab::energy_innovation_requirements_check(lab_level, techs);
            let cost = Lab::get_tech_cost(techs.energy_innovation, 0, 800, 400);
            PrivateFunctions::check_enough_resources(@self, caller, cost);
            PrivateFunctions::pay_resources_erc20(@self, caller, cost);
            PrivateFunctions::update_planet_points(ref self, planet_id, cost);
            PrivateFunctions::update_resources_spent(ref self, planet_id, cost);
            PrivateFunctions::update_tech_spent(ref self, planet_id, cost);
            PrivateFunctions::update_leaderboard(ref self, planet_id);
            self.energy_innovation_level.write(planet_id, techs.energy_innovation + 1);
            self.emit(Event::ResourcesSpent(ResourcesSpent { planet_id: planet_id, spent: cost }))
        }
        fn digital_systems_upgrade(ref self: ContractState) {
            let caller = get_caller_address();
            PrivateFunctions::collect_resources(ref self, caller);
            let planet_id = PrivateFunctions::get_token_owner(@self, caller);
            let lab_level = self.lab_level.read(planet_id);
            let techs = PrivateFunctions::get_tech_levels(@self, planet_id);
            Lab::digital_systems_requirements_check(lab_level, techs);
            let cost = Lab::get_tech_cost(techs.digital_systems, 0, 400, 600);
            PrivateFunctions::check_enough_resources(@self, caller, cost);
            PrivateFunctions::pay_resources_erc20(@self, caller, cost);
            PrivateFunctions::update_planet_points(ref self, planet_id, cost);
            PrivateFunctions::update_resources_spent(ref self, planet_id, cost);
            PrivateFunctions::update_tech_spent(ref self, planet_id, cost);
            PrivateFunctions::update_leaderboard(ref self, planet_id);
            self.digital_systems_level.write(planet_id, techs.digital_systems + 1);
            self.emit(Event::ResourcesSpent(ResourcesSpent { planet_id: planet_id, spent: cost }))
        }
        fn beam_technology_upgrade(ref self: ContractState) {
            let caller = get_caller_address();
            PrivateFunctions::collect_resources(ref self, caller);
            let planet_id = PrivateFunctions::get_token_owner(@self, caller);
            let lab_level = self.lab_level.read(planet_id);
            let techs = PrivateFunctions::get_tech_levels(@self, planet_id);
            Lab::beam_technology_requirements_check(lab_level, techs);
            let cost = Lab::get_tech_cost(techs.beam_technology, 200, 100, 0);
            PrivateFunctions::check_enough_resources(@self, caller, cost);
            PrivateFunctions::pay_resources_erc20(@self, caller, cost);
            PrivateFunctions::update_planet_points(ref self, planet_id, cost);
            PrivateFunctions::update_resources_spent(ref self, planet_id, cost);
            PrivateFunctions::update_tech_spent(ref self, planet_id, cost);
            PrivateFunctions::update_leaderboard(ref self, planet_id);
            self.beam_technology_level.write(planet_id, techs.beam_technology + 1);
            self.emit(Event::ResourcesSpent(ResourcesSpent { planet_id: planet_id, spent: cost }))
        }
        fn armour_innovation_upgrade(ref self: ContractState) {
            let caller = get_caller_address();
            PrivateFunctions::collect_resources(ref self, caller);
            let planet_id = PrivateFunctions::get_token_owner(@self, caller);
            let lab_level = self.lab_level.read(planet_id);
            let techs = PrivateFunctions::get_tech_levels(@self, planet_id);
            Lab::armour_innovation_requirements_check(lab_level, techs);
            let cost = Lab::get_tech_cost(techs.digital_systems, 0, 800, 400);
            PrivateFunctions::check_enough_resources(@self, caller, cost);
            PrivateFunctions::pay_resources_erc20(@self, caller, cost);
            PrivateFunctions::update_planet_points(ref self, planet_id, cost);
            PrivateFunctions::update_resources_spent(ref self, planet_id, cost);
            PrivateFunctions::update_tech_spent(ref self, planet_id, cost);
            PrivateFunctions::update_leaderboard(ref self, planet_id);
            self.digital_systems_level.write(planet_id, techs.armour_innovation + 1);
            self.emit(Event::ResourcesSpent(ResourcesSpent { planet_id: planet_id, spent: cost }))
        }
        fn ion_systems_upgrade(ref self: ContractState) {
            let caller = get_caller_address();
            PrivateFunctions::collect_resources(ref self, caller);
            let planet_id = PrivateFunctions::get_token_owner(@self, caller);
            let lab_level = self.lab_level.read(planet_id);
            let techs = PrivateFunctions::get_tech_levels(@self, planet_id);
            Lab::ion_systems_requirements_check(lab_level, techs);
            let cost = Lab::get_tech_cost(techs.ion_systems, 1000, 300, 1000);
            PrivateFunctions::check_enough_resources(@self, caller, cost);
            PrivateFunctions::pay_resources_erc20(@self, caller, cost);
            PrivateFunctions::update_planet_points(ref self, planet_id, cost);
            PrivateFunctions::update_resources_spent(ref self, planet_id, cost);
            PrivateFunctions::update_tech_spent(ref self, planet_id, cost);
            PrivateFunctions::update_leaderboard(ref self, planet_id);
            self.ion_systems_level.write(planet_id, techs.ion_systems + 1);
            self.emit(Event::ResourcesSpent(ResourcesSpent { planet_id: planet_id, spent: cost }))
        }
        fn plasma_engineering_upgrade(ref self: ContractState) {
            let caller = get_caller_address();
            PrivateFunctions::collect_resources(ref self, caller);
            let planet_id = PrivateFunctions::get_token_owner(@self, caller);
            let lab_level = self.lab_level.read(planet_id);
            let techs = PrivateFunctions::get_tech_levels(@self, planet_id);
            Lab::plasma_engineering_requirements_check(lab_level, techs);
            let cost = Lab::get_tech_cost(techs.plasma_engineering, 2000, 4000, 1000);
            PrivateFunctions::check_enough_resources(@self, caller, cost);
            PrivateFunctions::pay_resources_erc20(@self, caller, cost);
            PrivateFunctions::update_planet_points(ref self, planet_id, cost);
            PrivateFunctions::update_resources_spent(ref self, planet_id, cost);
            PrivateFunctions::update_tech_spent(ref self, planet_id, cost);
            PrivateFunctions::update_leaderboard(ref self, planet_id);
            self.plasma_engineering_level.write(planet_id, techs.plasma_engineering + 1);
            self.emit(Event::ResourcesSpent(ResourcesSpent { planet_id: planet_id, spent: cost }))
        }

        fn arms_development_upgrade(ref self: ContractState) {
            let caller = get_caller_address();
            PrivateFunctions::collect_resources(ref self, caller);
            let planet_id = PrivateFunctions::get_token_owner(@self, caller);
            let lab_level = self.lab_level.read(planet_id);
            let techs = PrivateFunctions::get_tech_levels(@self, planet_id);
            Lab::arms_development_requirements_check(lab_level, techs);
            let cost = Lab::get_tech_cost(techs.weapons_development, 800, 200, 0);
            PrivateFunctions::check_enough_resources(@self, caller, cost);
            PrivateFunctions::pay_resources_erc20(@self, caller, cost);
            PrivateFunctions::update_planet_points(ref self, planet_id, cost);
            PrivateFunctions::update_resources_spent(ref self, planet_id, cost);
            PrivateFunctions::update_tech_spent(ref self, planet_id, cost);
            PrivateFunctions::update_leaderboard(ref self, planet_id);
            self.weapons_development_level.write(planet_id, techs.weapons_development + 1);
            self.emit(Event::ResourcesSpent(ResourcesSpent { planet_id: planet_id, spent: cost }))
        }
        fn shield_tech_upgrade(ref self: ContractState) {
            let caller = get_caller_address();
            PrivateFunctions::collect_resources(ref self, caller);
            let planet_id = PrivateFunctions::get_token_owner(@self, caller);
            let lab_level = self.lab_level.read(planet_id);
            let techs = PrivateFunctions::get_tech_levels(@self, planet_id);
            Lab::shield_tech_requirements_check(lab_level, techs);
            let cost = Lab::get_tech_cost(techs.shield_tech, 200, 600, 0);
            PrivateFunctions::check_enough_resources(@self, caller, cost);
            PrivateFunctions::pay_resources_erc20(@self, caller, cost);
            PrivateFunctions::update_planet_points(ref self, planet_id, cost);
            PrivateFunctions::update_resources_spent(ref self, planet_id, cost);
            PrivateFunctions::update_tech_spent(ref self, planet_id, cost);
            PrivateFunctions::update_leaderboard(ref self, planet_id);
            self.shield_tech_level.write(planet_id, techs.shield_tech + 1);
            self.emit(Event::ResourcesSpent(ResourcesSpent { planet_id: planet_id, spent: cost }))
        }
        fn spacetime_warp_upgrade(ref self: ContractState) {
            let caller = get_caller_address();
            PrivateFunctions::collect_resources(ref self, caller);
            let planet_id = PrivateFunctions::get_token_owner(@self, caller);
            let lab_level = self.lab_level.read(planet_id);
            let techs = PrivateFunctions::get_tech_levels(@self, planet_id);
            Lab::spacetime_warp_requirements_check(lab_level, techs);
            let cost = Lab::get_tech_cost(techs.spacetime_warp, 0, 4000, 2000);
            PrivateFunctions::check_enough_resources(@self, caller, cost);
            PrivateFunctions::pay_resources_erc20(@self, caller, cost);
            PrivateFunctions::update_planet_points(ref self, planet_id, cost);
            PrivateFunctions::update_resources_spent(ref self, planet_id, cost);
            PrivateFunctions::update_tech_spent(ref self, planet_id, cost);
            PrivateFunctions::update_leaderboard(ref self, planet_id);
            self.spacetime_warp_level.write(planet_id, techs.spacetime_warp + 1);
            self.emit(Event::ResourcesSpent(ResourcesSpent { planet_id: planet_id, spent: cost }))
        }
        fn combustive_engine_upgrade(ref self: ContractState) {
            let caller = get_caller_address();
            PrivateFunctions::collect_resources(ref self, caller);
            let planet_id = PrivateFunctions::get_token_owner(@self, caller);
            let lab_level = self.lab_level.read(planet_id);
            let techs = PrivateFunctions::get_tech_levels(@self, planet_id);
            Lab::combustive_engine_requirements_check(lab_level, techs);
            let cost = Lab::get_tech_cost(techs.combustion_drive, 400, 0, 600);
            PrivateFunctions::check_enough_resources(@self, caller, cost);
            PrivateFunctions::pay_resources_erc20(@self, caller, cost);
            PrivateFunctions::update_planet_points(ref self, planet_id, cost);
            PrivateFunctions::update_resources_spent(ref self, planet_id, cost);
            PrivateFunctions::update_tech_spent(ref self, planet_id, cost);
            PrivateFunctions::update_leaderboard(ref self, planet_id);
            self.combustive_engine_level.write(planet_id, techs.combustion_drive + 1);
            self.emit(Event::ResourcesSpent(ResourcesSpent { planet_id: planet_id, spent: cost }))
        }
        fn thrust_propulsion_upgrade(ref self: ContractState) {
            let caller = get_caller_address();
            PrivateFunctions::collect_resources(ref self, caller);
            let planet_id = PrivateFunctions::get_token_owner(@self, caller);
            let lab_level = self.lab_level.read(planet_id);
            let techs = PrivateFunctions::get_tech_levels(@self, planet_id);
            Lab::thrust_propulsion_requirements_check(lab_level, techs);
            let cost = Lab::get_tech_cost(techs.thrust_propulsion, 2000, 4000, 600);
            PrivateFunctions::check_enough_resources(@self, caller, cost);
            PrivateFunctions::pay_resources_erc20(@self, caller, cost);
            PrivateFunctions::update_planet_points(ref self, planet_id, cost);
            PrivateFunctions::update_resources_spent(ref self, planet_id, cost);
            PrivateFunctions::update_tech_spent(ref self, planet_id, cost);
            PrivateFunctions::update_leaderboard(ref self, planet_id);
            self.thrust_propulsion_level.write(planet_id, techs.thrust_propulsion + 1);
            self.emit(Event::ResourcesSpent(ResourcesSpent { planet_id: planet_id, spent: cost }))
        }
        fn warp_drive_upgrade(ref self: ContractState) {
            let caller = get_caller_address();
            PrivateFunctions::collect_resources(ref self, caller);
            let planet_id = PrivateFunctions::get_token_owner(@self, caller);
            let lab_level = self.lab_level.read(planet_id);
            let techs = PrivateFunctions::get_tech_levels(@self, planet_id);
            Lab::warp_drive_requirements_check(lab_level, techs);
            let cost = Lab::get_tech_cost(techs.thrust_propulsion, 10000, 20000, 6000);
            PrivateFunctions::check_enough_resources(@self, caller, cost);
            PrivateFunctions::pay_resources_erc20(@self, caller, cost);
            PrivateFunctions::update_planet_points(ref self, planet_id, cost);
            PrivateFunctions::update_resources_spent(ref self, planet_id, cost);
            PrivateFunctions::update_tech_spent(ref self, planet_id, cost);
            PrivateFunctions::update_leaderboard(ref self, planet_id);
            self.warp_drive_level.write(planet_id, techs.warp_drive + 1);
            self.emit(Event::ResourcesSpent(ResourcesSpent { planet_id: planet_id, spent: cost }))
        }
        //#########################################################################################
        //                                      DOCKYARD FUNCTIONS                                #
        //########################################################################################
        fn carrier_build(ref self: ContractState, quantity: u128) {
            let caller = get_caller_address();
            PrivateFunctions::collect_resources(ref self, caller);
            let planet_id = PrivateFunctions::get_token_owner(@self, caller);
            let dockyard_level = self.dockyard_level.read(planet_id);
            let techs = PrivateFunctions::get_tech_levels(@self, planet_id);
            Dockyard::carrier_requirements_check(dockyard_level, techs);
            let cost = Dockyard::get_ships_cost(quantity, NoGame::get_ships_cost(@self).carrier);
            PrivateFunctions::check_enough_resources(@self, caller, cost);
            PrivateFunctions::pay_resources_erc20(@self, caller, cost);
            PrivateFunctions::update_planet_points(ref self, planet_id, cost);
            PrivateFunctions::update_resources_spent(ref self, planet_id, cost);
            PrivateFunctions::update_fleet_spent(ref self, planet_id, cost);
            PrivateFunctions::update_leaderboard(ref self, planet_id);
            self
                .carrier_available
                .write(planet_id, self.carrier_available.read(planet_id) + quantity);
            self.emit(Event::ResourcesSpent(ResourcesSpent { planet_id: planet_id, spent: cost }))
        }
        fn scraper_build(ref self: ContractState, quantity: u128) {
            let caller = get_caller_address();
            PrivateFunctions::collect_resources(ref self, caller);
            let planet_id = PrivateFunctions::get_token_owner(@self, caller);
            let dockyard_level = self.dockyard_level.read(planet_id);
            let techs = PrivateFunctions::get_tech_levels(@self, planet_id);
            Dockyard::scraper_requirements_check(dockyard_level, techs);
            let cost = Dockyard::get_ships_cost(quantity, NoGame::get_ships_cost(@self).scraper);
            PrivateFunctions::check_enough_resources(@self, caller, cost);
            PrivateFunctions::pay_resources_erc20(@self, caller, cost);
            PrivateFunctions::update_planet_points(ref self, planet_id, cost);
            PrivateFunctions::update_resources_spent(ref self, planet_id, cost);
            PrivateFunctions::update_fleet_spent(ref self, planet_id, cost);
            PrivateFunctions::update_leaderboard(ref self, planet_id);
            self
                .scraper_available
                .write(planet_id, self.scraper_available.read(planet_id) + quantity);
            self.emit(Event::ResourcesSpent(ResourcesSpent { planet_id: planet_id, spent: cost }))
        }
        fn celestia_build(ref self: ContractState, quantity: u128) {
            let caller = get_caller_address();
            PrivateFunctions::collect_resources(ref self, caller);
            let planet_id = PrivateFunctions::get_token_owner(@self, caller);
            let dockyard_level = self.dockyard_level.read(planet_id);
            let techs = PrivateFunctions::get_tech_levels(@self, planet_id);
            Dockyard::celestia_requirements_check(dockyard_level, techs);
            let cost = Dockyard::get_ships_cost(quantity, NoGame::get_ships_cost(@self).celestia);
            PrivateFunctions::check_enough_resources(@self, caller, cost);
            PrivateFunctions::pay_resources_erc20(@self, caller, cost);
            PrivateFunctions::update_planet_points(ref self, planet_id, cost);
            PrivateFunctions::update_resources_spent(ref self, planet_id, cost);
            PrivateFunctions::update_fleet_spent(ref self, planet_id, cost);
            PrivateFunctions::update_leaderboard(ref self, planet_id);
            self
                .celestia_available
                .write(planet_id, self.celestia_available.read(planet_id) + quantity);
            self.emit(Event::ResourcesSpent(ResourcesSpent { planet_id: planet_id, spent: cost }))
        }
        fn sparrow_build(ref self: ContractState, quantity: u128) {
            let caller = get_caller_address();
            PrivateFunctions::collect_resources(ref self, caller);
            let planet_id = PrivateFunctions::get_token_owner(@self, caller);
            let dockyard_level = self.dockyard_level.read(planet_id);
            let techs = PrivateFunctions::get_tech_levels(@self, planet_id);
            Dockyard::sparrow_requirements_check(dockyard_level, techs);
            let cost = Dockyard::get_ships_cost(quantity, NoGame::get_ships_cost(@self).sparrow);
            PrivateFunctions::check_enough_resources(@self, caller, cost);
            PrivateFunctions::pay_resources_erc20(@self, caller, cost);
            PrivateFunctions::update_planet_points(ref self, planet_id, cost);
            PrivateFunctions::update_resources_spent(ref self, planet_id, cost);
            PrivateFunctions::update_fleet_spent(ref self, planet_id, cost);
            PrivateFunctions::update_leaderboard(ref self, planet_id);
            self
                .sparrow_available
                .write(planet_id, self.sparrow_available.read(planet_id) + quantity);
            self.emit(Event::ResourcesSpent(ResourcesSpent { planet_id: planet_id, spent: cost }))
        }
        fn frigate_build(ref self: ContractState, quantity: u128) {
            let caller = get_caller_address();
            PrivateFunctions::collect_resources(ref self, caller);
            let planet_id = PrivateFunctions::get_token_owner(@self, caller);
            let dockyard_level = self.dockyard_level.read(planet_id);
            let techs = PrivateFunctions::get_tech_levels(@self, planet_id);
            Dockyard::frigate_requirements_check(dockyard_level, techs);
            let cost = Dockyard::get_ships_cost(quantity, NoGame::get_ships_cost(@self).frigate);
            PrivateFunctions::check_enough_resources(@self, caller, cost);
            PrivateFunctions::pay_resources_erc20(@self, caller, cost);
            PrivateFunctions::update_planet_points(ref self, planet_id, cost);
            PrivateFunctions::update_resources_spent(ref self, planet_id, cost);
            PrivateFunctions::update_fleet_spent(ref self, planet_id, cost);
            PrivateFunctions::update_leaderboard(ref self, planet_id);
            self
                .frigate_available
                .write(planet_id, self.frigate_available.read(planet_id) + quantity);
            self.emit(Event::ResourcesSpent(ResourcesSpent { planet_id: planet_id, spent: cost }))
        }
        fn armade_build(ref self: ContractState, quantity: u128) {
            let caller = get_caller_address();
            PrivateFunctions::collect_resources(ref self, caller);
            let planet_id = PrivateFunctions::get_token_owner(@self, caller);
            let dockyard_level = self.dockyard_level.read(planet_id);
            let techs = PrivateFunctions::get_tech_levels(@self, planet_id);
            Dockyard::armade_requirements_check(dockyard_level, techs);
            let cost = Dockyard::get_ships_cost(quantity, NoGame::get_ships_cost(@self).armade);
            PrivateFunctions::check_enough_resources(@self, caller, cost);
            PrivateFunctions::pay_resources_erc20(@self, caller, cost);
            PrivateFunctions::update_planet_points(ref self, planet_id, cost);
            PrivateFunctions::update_resources_spent(ref self, planet_id, cost);
            PrivateFunctions::update_fleet_spent(ref self, planet_id, cost);
            PrivateFunctions::update_leaderboard(ref self, planet_id);
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
            PrivateFunctions::collect_resources(ref self, caller);
            let planet_id = PrivateFunctions::get_token_owner(@self, caller);
            let dockyard_level = self.dockyard_level.read(planet_id);
            let techs = PrivateFunctions::get_tech_levels(@self, planet_id);
            Defences::blaster_requirements_check(dockyard_level, techs);
            let cost = Defences::get_defences_cost(quantity, 2000, 0, 0);
            PrivateFunctions::check_enough_resources(@self, caller, cost);
            PrivateFunctions::pay_resources_erc20(@self, caller, cost);
            PrivateFunctions::update_planet_points(ref self, planet_id, cost);
            PrivateFunctions::update_resources_spent(ref self, planet_id, cost);
            PrivateFunctions::update_fleet_spent(ref self, planet_id, cost);
            PrivateFunctions::update_leaderboard(ref self, planet_id);
            self
                .blaster_available
                .write(planet_id, self.blaster_available.read(planet_id) + quantity);
            self.emit(Event::ResourcesSpent(ResourcesSpent { planet_id: planet_id, spent: cost }))
        }
        fn beam_build(ref self: ContractState, quantity: u128) {
            let caller = get_caller_address();
            PrivateFunctions::collect_resources(ref self, caller);
            let planet_id = PrivateFunctions::get_token_owner(@self, caller);
            let dockyard_level = self.dockyard_level.read(planet_id);
            let techs = PrivateFunctions::get_tech_levels(@self, planet_id);
            Defences::beam_requirements_check(dockyard_level, techs);
            let cost = Defences::get_defences_cost(quantity, 6000, 2000, 0);
            PrivateFunctions::check_enough_resources(@self, caller, cost);
            PrivateFunctions::pay_resources_erc20(@self, caller, cost);
            PrivateFunctions::update_planet_points(ref self, planet_id, cost);
            PrivateFunctions::update_resources_spent(ref self, planet_id, cost);
            PrivateFunctions::update_fleet_spent(ref self, planet_id, cost);
            PrivateFunctions::update_leaderboard(ref self, planet_id);
            self.beam_available.write(planet_id, self.beam_available.read(planet_id) + quantity);
            self.emit(Event::ResourcesSpent(ResourcesSpent { planet_id: planet_id, spent: cost }))
        }
        fn astral_launcher_build(ref self: ContractState, quantity: u128) {
            let caller = get_caller_address();
            PrivateFunctions::collect_resources(ref self, caller);
            let planet_id = PrivateFunctions::get_token_owner(@self, caller);
            let dockyard_level = self.dockyard_level.read(planet_id);
            let techs = PrivateFunctions::get_tech_levels(@self, planet_id);
            Defences::astral_launcher_requirements_check(dockyard_level, techs);
            let cost = Defences::get_defences_cost(quantity, 20000, 15000, 2000);
            PrivateFunctions::check_enough_resources(@self, caller, cost);
            PrivateFunctions::pay_resources_erc20(@self, caller, cost);
            PrivateFunctions::update_planet_points(ref self, planet_id, cost);
            PrivateFunctions::update_resources_spent(ref self, planet_id, cost);
            PrivateFunctions::update_fleet_spent(ref self, planet_id, cost);
            PrivateFunctions::update_leaderboard(ref self, planet_id);
            self
                .astral_launcher_available
                .write(planet_id, self.astral_launcher_available.read(planet_id) + quantity);
            self.emit(Event::ResourcesSpent(ResourcesSpent { planet_id: planet_id, spent: cost }))
        }
        fn plasma_beam_build(ref self: ContractState, quantity: u128) {
            let caller = get_caller_address();
            PrivateFunctions::collect_resources(ref self, caller);
            let planet_id = PrivateFunctions::get_token_owner(@self, caller);
            let dockyard_level = self.dockyard_level.read(planet_id);
            let techs = PrivateFunctions::get_tech_levels(@self, planet_id);
            Defences::plasma_beam_requirements_check(dockyard_level, techs);
            let cost = Defences::get_defences_cost(quantity, 50000, 50000, 30000);
            PrivateFunctions::check_enough_resources(@self, caller, cost);
            PrivateFunctions::pay_resources_erc20(@self, caller, cost);
            PrivateFunctions::update_planet_points(ref self, planet_id, cost);
            PrivateFunctions::update_resources_spent(ref self, planet_id, cost);
            PrivateFunctions::update_fleet_spent(ref self, planet_id, cost);
            PrivateFunctions::update_leaderboard(ref self, planet_id);
            self
                .plasma_beam_available
                .write(planet_id, self.plasma_beam_available.read(planet_id) + quantity);
            self.emit(Event::ResourcesSpent(ResourcesSpent { planet_id: planet_id, spent: cost }))
        }

        //#########################################################################################
        //                                      VIEW FUNCTIONS                                #
        //########################################################################################

        fn get_tokens_addresses(self: @ContractState) -> Tokens {
            PrivateFunctions::get_tokens_addresses(self)
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
            let planet_owner = INGERC721Dispatcher {
                contract_address: self.erc721_address.read()
            }.owner_of(planet_id.into());
            let steel: u128 = IERC20Dispatcher {
                contract_address: self.steel_address.read()
            }.balances(planet_owner).try_into().unwrap();
            let quartz: u128 = IERC20Dispatcher {
                contract_address: self.quartz_address.read()
            }.balances(planet_owner).try_into().unwrap();
            let tritium: u128 = IERC20Dispatcher {
                contract_address: self.tritium_address.read()
            }.balances(planet_owner).try_into().unwrap();
            ERC20s { steel: steel, quartz: quartz, tritium: tritium }
        }

        fn get_collectible_resources(self: @ContractState, planet_id: u128) -> ERC20s {
            let time_elapsed = PrivateFunctions::time_since_last_collection(self, planet_id);
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
            let energy_required = PrivateFunctions::calculate_energy_consumption(compounds_levels);
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
            PrivateFunctions::get_tech_levels(self, planet_id)
        }

        fn get_techs_upgrade_cost(self: @ContractState, planet_id: u128) -> TechsCost {
            let techs = PrivateFunctions::get_tech_levels(self, planet_id);
            PrivateFunctions::techs_cost(techs)
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
                carrier: ERC20s {
                    steel: 4000, quartz: 4000, tritium: 0
                    }, celestia: ERC20s {
                    steel: 0, quartz: 2000, tritium: 500
                    }, scraper: ERC20s {
                    steel: 1000, quartz: 6000, tritium: 2000
                    }, sparrow: ERC20s {
                    steel: 3000, quartz: 1000, tritium: 0
                    }, frigate: ERC20s {
                    steel: 20000, quartz: 7000, tritium: 2000
                    }, armade: ERC20s {
                    steel: 45000, quartz: 15000, tritium: 0
                }
            }
        }
    }


    //#########################################################################################
    //                                      PRIVATE FUNCTIONS                                 #
    //#########################################################################################

    #[generate_trait]
    impl PrivateFunctions of PrivateTrait {
        fn get_token_owner(self: @ContractState, caller: ContractAddress) -> u128 {
            let erc721 = self.erc721_address.read();
            let planet_id = INGERC721Dispatcher { contract_address: erc721 }.token_of(caller);
            planet_id.low
        }

        fn collect_resources(ref self: ContractState, caller: ContractAddress) {
            let caller = get_caller_address();
            let planet_id = PrivateFunctions::get_token_owner(@self, caller);
            let production = PrivateFunctions::calculate_production(@self, planet_id);
            PrivateFunctions::receive_resources_erc20(@self, caller, production);
            self.resources_timer.write(planet_id, get_block_timestamp());
        }

        fn get_erc20s_available(self: @ContractState, caller: ContractAddress) -> ERC20s {
            let _steel = IERC20Dispatcher {
                contract_address: self.steel_address.read()
            }.balances(caller);
            // let steel_total = Mines::steel_production(steel_level) + steel_available;

            let _quartz = IERC20Dispatcher {
                contract_address: self.quartz_address.read()
            }.balances(caller);
            // let quartz_total = Mines::quartz_production(quartz_level) + quartz_available;

            let _tritium = IERC20Dispatcher {
                contract_address: self.tritium_address.read()
            }.balances(caller);
            // let steel_produced = Mines::steel_production(steel_level) + steel_available;
            ERC20s {
                steel: _steel.try_into().unwrap(),
                quartz: _quartz.try_into().unwrap(),
                tritium: _tritium.try_into().unwrap()
            }
        }

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
            let _steel = Compounds::production_scaler(
                steel_available, energy_available, energy_required
            );
            let _quartz = Compounds::production_scaler(
                quartz_available, energy_available, energy_required
            );
            let _tritium = Compounds::production_scaler(
                tritium_available, energy_available, energy_required
            );

            Resources {
                steel: _steel,
                quartz: _quartz,
                tritium: _tritium,
                energy: energy_available - energy_required
            }
        }

        fn calculate_energy_consumption(compounds: CompoundsLevels) -> u128 {
            Compounds::base_mine_consumption(compounds.steel)
                + Compounds::base_mine_consumption(compounds.quartz)
                + Compounds::tritium_mine_consumption(compounds.tritium)
        }

        fn calculate_net_energy(self: @ContractState, planet_id: u128) -> u128 {
            let energy = Compounds::energy_plant_production(
                self.energy_plant_level.read(planet_id)
            );
            let energy_needed = Compounds::base_mine_consumption(
                self.steel_mine_level.read(planet_id)
            )
                + Compounds::base_mine_consumption(self.quartz_mine_level.read(planet_id))
                + Compounds::tritium_mine_consumption(self.tritium_mine_level.read(planet_id));
            if energy < energy_needed {
                return 0;
            } else {
                energy - energy_needed
            }
        }

        fn receive_resources_erc20(self: @ContractState, to: ContractAddress, amounts: Resources) {
            let tokens: Tokens = PrivateFunctions::get_tokens_addresses(self);
            IERC20Dispatcher {
                contract_address: tokens.steel
            }.mint(to, (amounts.steel * E18).into());
            IERC20Dispatcher {
                contract_address: tokens.quartz
            }.mint(to, (amounts.quartz * E18).into());
            IERC20Dispatcher {
                contract_address: tokens.tritium
            }.mint(to, (amounts.tritium * E18).into())
        }

        fn pay_resources_erc20(self: @ContractState, account: ContractAddress, amounts: ERC20s) {
            let tokens: Tokens = PrivateFunctions::get_tokens_addresses(self);
            IERC20Dispatcher {
                contract_address: tokens.steel
            }.burn(account, (amounts.steel * E18).into());
            IERC20Dispatcher {
                contract_address: tokens.quartz
            }.burn(account, (amounts.quartz * E18).into());
            IERC20Dispatcher {
                contract_address: tokens.tritium
            }.burn(account, (amounts.tritium * E18).into())
        }

        fn mint_initial_liquidity(self: @ContractState, account: ContractAddress) {
            let tokens: Tokens = PrivateFunctions::get_tokens_addresses(self);
            IERC20Dispatcher {
                contract_address: tokens.steel
            }.mint(recipient: account, amount: (500 * E18).into());
            IERC20Dispatcher {
                contract_address: tokens.quartz
            }.mint(recipient: account, amount: (300 * E18).into());
            IERC20Dispatcher {
                contract_address: tokens.tritium
            }.mint(recipient: account, amount: (100 * E18).into());
        }

        fn check_enough_resources(self: @ContractState, caller: ContractAddress, amounts: ERC20s) {
            let available: ERC20s = PrivateFunctions::get_erc20s_available(self, caller);
            assert(amounts.steel <= available.steel, 'Not enough steel');
            assert(amounts.quartz <= available.quartz, 'Not enough quartz');
            assert(amounts.tritium <= available.tritium, 'Not enough tritium');
        }

        fn get_tokens_addresses(self: @ContractState) -> Tokens {
            Tokens {
                steel: self.steel_address.read(),
                quartz: self.quartz_address.read(),
                tritium: self.tritium_address.read()
            }
        }

        fn update_planet_points(ref self: ContractState, planet_id: u128, spent: ERC20s) {
            self
                .resources_spent
                .write(
                    planet_id, self.resources_spent.read(planet_id) + spent.steel + spent.quartz
                );
        }

        fn update_resources_spent(ref self: ContractState, planet_id: u128, cost: ERC20s) {
            let current_spent = self.resources_spent.read(planet_id);
            self.resources_spent.write(planet_id, current_spent + cost.steel + cost.quartz);
        }

        fn update_tech_spent(ref self: ContractState, planet_id: u128, cost: ERC20s) {
            let current_spent = self.tech_spent.read(planet_id);
            self.tech_spent.write(planet_id, current_spent + cost.steel + cost.quartz);
        }

        fn update_fleet_spent(ref self: ContractState, planet_id: u128, cost: ERC20s) {
            let current_spent = self.fleet_spent.read(planet_id);
            self.tech_spent.write(planet_id, current_spent + cost.steel + cost.quartz);
        }

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

        fn time_since_last_collection(self: @ContractState, planet_id: u128) -> u64 {
            get_block_timestamp() - self.resources_timer.read(planet_id)
        }
        // ##################################################################################
        //                                TECH FUNCTIONS                   #
        //###################################################################################

        fn get_tech_levels(self: @ContractState, planet_id: u128) -> TechLevels {
            TechLevels {
                energy_innovation: self.energy_innovation_level.read(planet_id),
                digital_systems: self.digital_systems_level.read(planet_id),
                beam_technology: self.beam_technology_level.read(planet_id),
                armour_innovation: self.armour_innovation_level.read(planet_id),
                ion_systems: self.ion_systems_level.read(planet_id),
                plasma_engineering: self.plasma_engineering_level.read(planet_id),
                weapons_development: self.weapons_development_level.read(planet_id),
                shield_tech: self.shield_tech_level.read(planet_id),
                spacetime_warp: self.spacetime_warp_level.read(planet_id),
                combustion_drive: self.combustive_engine_level.read(planet_id),
                thrust_propulsion: self.thrust_propulsion_level.read(planet_id),
                warp_drive: self.warp_drive_level.read(planet_id)
            }
        }

        fn techs_cost(techs: TechLevels) -> TechsCost {
            let energy = Lab::get_tech_cost(techs.energy_innovation, 0, 800, 400);
            let digital = Lab::get_tech_cost(techs.digital_systems, 0, 400, 600);
            let beam = Lab::get_tech_cost(techs.beam_technology, 0, 800, 400);
            let ion = Lab::get_tech_cost(techs.ion_systems, 1000, 300, 1000);
            let plasma = Lab::get_tech_cost(techs.plasma_engineering, 2000, 4000, 1000);
            let spacetime = Lab::get_tech_cost(techs.spacetime_warp, 0, 4000, 2000);
            let combustion = Lab::get_tech_cost(techs.combustion_drive, 400, 0, 600);
            let thrust = Lab::get_tech_cost(techs.thrust_propulsion, 2000, 4000, 600);
            let warp = Lab::get_tech_cost(techs.warp_drive, 10000, 2000, 6000);
            let armour = Lab::get_tech_cost(techs.armour_innovation, 1000, 0, 0);
            let weapons = Lab::get_tech_cost(techs.weapons_development, 800, 200, 0);
            let shield = Lab::get_tech_cost(techs.shield_tech, 200, 600, 0);

            TechsCost {
                energy_innovation: energy,
                digital_systems: digital,
                beam_technology: beam,
                ion_systems: ion,
                plasma_engineering: plasma,
                spacetime_warp: spacetime,
                combustion_drive: combustion,
                thrust_propulsion: thrust,
                warp_drive: warp,
                armour_innovation: armour,
                weapons_development: weapons,
                shield_tech: shield
            }
        }
    }
}

