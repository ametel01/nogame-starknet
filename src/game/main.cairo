use starknet::ContractAddress;
use nogame::game::library::{MinesCost, MinesLevels, Resources, Tokens};

#[starknet::interface]
trait INoGame<T> {
    fn get_tokens_addresses(self: @T) -> Tokens;
    fn _initializer(
        ref self: T,
        erc721: ContractAddress,
        steel: ContractAddress,
        quartz: ContractAddress,
        tritium: ContractAddress
    );
    // View functions
    fn get_planet_points(self: @T, planet_id: u256) -> u128;
    fn get_mines_levels(self: @T, planet_id: u256) -> MinesLevels;
    fn get_mines_upgrade_cost(self: @T, planet_id: u256) -> MinesCost;
    fn total_resources_available(self: @T, planet_id: u256) -> Resources;
    fn get_number_of_planets(self: @T) -> u32;
    fn generate_planet(ref self: T);
    fn collect_resources(ref self: T);
    // Compounds functions
    fn steel_mine_upgrade(ref self: T);
    fn quartz_mine_upgrade(ref self: T);
    fn tritium_mine_upgrade(ref self: T);
    fn energy_plant_upgrade(ref self: T);
    fn dockyard_upgrade(ref self: T);
    fn lab_upgrade(ref self: T);
    // Tech functions
    fn energy_innovation_upgrade(ref self: T);
    fn digital_systems_upgrade(ref self: T);
    fn beam_technology_upgrade(ref self: T);
    fn armour_innovation_upgrade(ref self: T);
    fn ion_systems_upgrade(ref self: T);
    fn plasma_engineering_upgrade(ref self: T);
    fn stellar_physics_upgrade(ref self: T);
    fn arms_development_upgrade(ref self: T);
    fn shield_tech_upgrade(ref self: T);
    fn spacetime_warp_upgrade(ref self: T);
    fn combustive_engine_upgrade(ref self: T);
    fn thrust_propulsion_upgrade(ref self: T);
    fn warp_drive_upgrade(ref self: T);
    // Dockyard functions
    fn carrier_build(ref self: T, quantity: u128);
    fn scraper_build(ref self: T, quantity: u128);
    fn celestia_build(ref self: T, quantity: u128);
    fn sparrow_build(ref self: T, quantity: u128);
    fn frigate_build(ref self: T, quantity: u128);
    fn armade_build(ref self: T, quantity: u128);
    // Defences functions
    fn blaster_build(ref self: T, quantity: u128);
    fn beam_build(ref self: T, quantity: u128);
    fn astral_launcher_build(ref self: T, quantity: u128);
    fn plasma_beam_build(ref self: T, quantity: u128);
}


#[starknet::contract]
mod NoGame {
    use core::option::OptionTrait;
    use core::traits::{Into, TryInto};
    use starknet::{ContractAddress, get_block_timestamp, get_caller_address, get_contract_address};
    use nogame::game::library::{
        Cost, E18, ERC20s, MinesCost, MinesLevels, Resources, Techs, Tokens
    };
    use nogame::libraries::compounds::Compounds;
    use nogame::libraries::defences::Defences;
    use nogame::libraries::dockyard::Dockyard;
    use nogame::libraries::research::Lab;
    use nogame::token::erc20::IERC20DispatcherTrait;
    use nogame::token::erc20::IERC20Dispatcher;
    use nogame::token::erc721::IERC721DispatcherTrait;
    use nogame::token::erc721::IERC721Dispatcher;


    #[storage]
    struct Storage {
        // General.
        number_of_planets: u32,
        universe_start_time: u64,
        planet_generated: LegacyMap::<u256, bool>,
        resources_spent: LegacyMap::<u256, u128>,
        tech_spent: LegacyMap::<u256, u128>,
        fleet_spent: LegacyMap::<u256, u128>,
        point_leader: u256,
        tech_leader: u256,
        fleet_leader: u256,
        // Tokens.
        erc721_address: ContractAddress,
        steel_address: ContractAddress,
        quartz_address: ContractAddress,
        tritium_address: ContractAddress,
        // Infrastructures.
        steel_mine_level: LegacyMap::<u256, u128>,
        quartz_mine_level: LegacyMap::<u256, u128>,
        tritium_mine_level: LegacyMap::<u256, u128>,
        energy_plant_level: LegacyMap::<u256, u128>,
        dockyard_level: LegacyMap::<u256, u128>,
        lab_level: LegacyMap::<u256, u128>,
        resources_timer: LegacyMap::<u256, u64>,
        // Technologies
        energy_innovation_level: LegacyMap::<u256, u128>,
        digital_systems_level: LegacyMap::<u256, u128>,
        beam_technology_level: LegacyMap::<u256, u128>,
        armour_innovation_level: LegacyMap::<u256, u128>,
        ion_systems_level: LegacyMap::<u256, u128>,
        plasma_engineering_level: LegacyMap::<u256, u128>,
        stellar_physics_level: LegacyMap::<u256, u128>,
        arms_development_level: LegacyMap::<u256, u128>,
        shield_tech_level: LegacyMap::<u256, u128>,
        spacetime_warp_level: LegacyMap::<u256, u128>,
        combustive_engine_level: LegacyMap::<u256, u128>,
        thrust_propulsion_level: LegacyMap::<u256, u128>,
        warp_drive_level: LegacyMap::<u256, u128>,
        // Ships
        carrier_available: LegacyMap::<u256, u128>,
        scraper_available: LegacyMap::<u256, u128>,
        celestia_available: LegacyMap::<u256, u128>,
        sparrow_available: LegacyMap::<u256, u128>,
        frigate_available: LegacyMap::<u256, u128>,
        armade_available: LegacyMap::<u256, u128>,
        // Defences
        blaster_available: LegacyMap::<u256, u128>,
        beam_available: LegacyMap::<u256, u128>,
        astral_launcher_available: LegacyMap::<u256, u128>,
        plasma_beam_available: LegacyMap::<u256, u128>,
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
        planet_id: u256,
        spent: Cost
    }

    #[derive(Drop, starknet::Event)]
    struct TechSpent {
        planet_id: u256,
        spent: u256
    }

    #[derive(Drop, starknet::Event)]
    struct FleetSpent {
        planet_id: u256,
        spent: u256
    }

    // Structures upgrade events.

    // Constructor
    // #[constructor]
    fn constructor(ref self: ContractState) {
        self.universe_start_time.write(get_block_timestamp());
    }

    #[external(v0)]
    impl NoGame of super::INoGame<ContractState> {
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
            let token_id: u256 = (number_of_planets + 1).into();
            IERC721Dispatcher {
                contract_address: self.erc721_address.read()
            }.mint(_to: caller, token_id: token_id);
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
            let cost: Cost = Compounds::steel_mine_cost(current_level);
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
            let cost: Cost = Compounds::quartz_mine_cost(current_level);
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
            let cost: Cost = Compounds::tritium_mine_cost(current_level);
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
            let cost: Cost = Compounds::energy_plant_cost(current_level);
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
            let cost: Cost = Compounds::dockyard_cost(current_level);
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
            let cost: Cost = Compounds::lab_cost(current_level);
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
        fn stellar_physics_upgrade(ref self: ContractState) {
            let caller = get_caller_address();
            PrivateFunctions::collect_resources(ref self, caller);
            let planet_id = PrivateFunctions::get_token_owner(@self, caller);
            let lab_level = self.lab_level.read(planet_id);
            let techs = PrivateFunctions::get_tech_levels(@self, planet_id);
            Lab::stellar_physics_requirements_check(lab_level, techs);
            let cost = Lab::get_tech_cost(techs.stellar_physics, 4000, 8000, 4000);
            PrivateFunctions::check_enough_resources(@self, caller, cost);
            PrivateFunctions::pay_resources_erc20(@self, caller, cost);
            PrivateFunctions::update_planet_points(ref self, planet_id, cost);
            PrivateFunctions::update_resources_spent(ref self, planet_id, cost);
            PrivateFunctions::update_tech_spent(ref self, planet_id, cost);
            PrivateFunctions::update_leaderboard(ref self, planet_id);
            self.stellar_physics_level.write(planet_id, techs.stellar_physics + 1);
            self.emit(Event::ResourcesSpent(ResourcesSpent { planet_id: planet_id, spent: cost }))
        }
        fn arms_development_upgrade(ref self: ContractState) {
            let caller = get_caller_address();
            PrivateFunctions::collect_resources(ref self, caller);
            let planet_id = PrivateFunctions::get_token_owner(@self, caller);
            let lab_level = self.lab_level.read(planet_id);
            let techs = PrivateFunctions::get_tech_levels(@self, planet_id);
            Lab::arms_development_requirements_check(lab_level, techs);
            let cost = Lab::get_tech_cost(techs.arms_development, 800, 200, 0);
            PrivateFunctions::check_enough_resources(@self, caller, cost);
            PrivateFunctions::pay_resources_erc20(@self, caller, cost);
            PrivateFunctions::update_planet_points(ref self, planet_id, cost);
            PrivateFunctions::update_resources_spent(ref self, planet_id, cost);
            PrivateFunctions::update_tech_spent(ref self, planet_id, cost);
            PrivateFunctions::update_leaderboard(ref self, planet_id);
            self.arms_development_level.write(planet_id, techs.arms_development + 1);
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
            let cost = Lab::get_tech_cost(techs.combustive_engine, 400, 0, 600);
            PrivateFunctions::check_enough_resources(@self, caller, cost);
            PrivateFunctions::pay_resources_erc20(@self, caller, cost);
            PrivateFunctions::update_planet_points(ref self, planet_id, cost);
            PrivateFunctions::update_resources_spent(ref self, planet_id, cost);
            PrivateFunctions::update_tech_spent(ref self, planet_id, cost);
            PrivateFunctions::update_leaderboard(ref self, planet_id);
            self.combustive_engine_level.write(planet_id, techs.combustive_engine + 1);
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
            let cost = Dockyard::get_ships_cost(quantity, 2000, 2000, 0);
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
            let cost = Dockyard::get_ships_cost(quantity, 10000, 6000, 2000);
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
            let cost = Dockyard::get_ships_cost(quantity, 0, 2000, 500);
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
            let cost = Dockyard::get_ships_cost(quantity, 3000, 1000, 0);
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
            let cost = Dockyard::get_ships_cost(quantity, 20000, 7000, 2000);
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
            let cost = Dockyard::get_ships_cost(quantity, 45000, 15000, 0);
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
        fn get_planet_points(self: @ContractState, planet_id: u256) -> u128 {
            self.resources_spent.read(planet_id) / 1000
        }
        fn get_mines_levels(self: @ContractState, planet_id: u256) -> MinesLevels {
            (MinesLevels {
                steel: self.steel_mine_level.read(planet_id),
                quartz: self.quartz_mine_level.read(planet_id),
                tritium: self.tritium_mine_level.read(planet_id),
                energy: self.energy_plant_level.read(planet_id)
            })
        }
        fn get_mines_upgrade_cost(self: @ContractState, planet_id: u256) -> MinesCost {
            let mines_levels = NoGame::get_mines_levels(self, planet_id);
            let _steel: Cost = Compounds::steel_mine_cost(mines_levels.steel);
            let _quartz: Cost = Compounds::quartz_mine_cost(mines_levels.quartz);
            let _tritium: Cost = Compounds::tritium_mine_cost(mines_levels.tritium);
            let _solar: Cost = Compounds::energy_plant_cost(mines_levels.energy);
            MinesCost { steel: _steel, quartz: _quartz, tritium: _tritium, solar: _solar }
        }
        fn total_resources_available(self: @ContractState, planet_id: u256) -> Resources {
            let production: Resources = PrivateFunctions::calculate_production(self, planet_id);
            let erc20_available = PrivateFunctions::get_erc20s_available(
                self, get_caller_address()
            );
            Resources {
                steel: production.steel + erc20_available.steel,
                quartz: production.quartz + erc20_available.quartz,
                tritium: production.tritium + erc20_available.tritium,
                energy: production.energy
            }
        }
    }


    //#########################################################################################
    //                                      PRIVATE FUNCTIONS                                 #
    //#########################################################################################

    #[generate_trait]
    impl PrivateFunctions of PrivateTrait {
        fn get_token_owner(self: @ContractState, caller: ContractAddress) -> u256 {
            let erc721 = self.erc721_address.read();
            let planet_id = IERC721Dispatcher { contract_address: erc721 }.token_of(caller);
            planet_id
        }

        fn collect_resources(ref self: ContractState, caller: ContractAddress) {
            let caller = get_caller_address();
            let planet_id = PrivateFunctions::get_token_owner(@self, caller);
            let production = PrivateFunctions::calculate_production(@self, planet_id);
            PrivateFunctions::send_resources_erc20(@self, caller, production);
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

        fn calculate_production(self: @ContractState, planet_id: u256) -> Resources {
            let time_now = get_block_timestamp();
            let last_collection_time = self.resources_timer.read(planet_id);
            let time_elapsed: u128 = (time_now - last_collection_time).into();
            let mines_levels = NoGame::get_mines_levels(self, planet_id);
            let steel_available = (Compounds::steel_production(mines_levels.steel)
                * time_elapsed
                / 3600);

            let quartz_available = (Compounds::quartz_production(mines_levels.quartz)
                * time_elapsed
                / 3600);

            let tritium_available = (Compounds::tritium_production(mines_levels.tritium)
                * time_elapsed
                / 3600);
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

        fn calculate_net_energy(self: @ContractState, planet_id: u256) -> u128 {
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

        fn send_resources_erc20(self: @ContractState, to: ContractAddress, amounts: Resources) {
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

        fn pay_resources_erc20(self: @ContractState, account: ContractAddress, amounts: Cost) {
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

        fn check_enough_resources(self: @ContractState, caller: ContractAddress, amounts: Cost) {
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

        fn update_planet_points(ref self: ContractState, planet_id: u256, spent: Cost) {
            self
                .resources_spent
                .write(
                    planet_id, self.resources_spent.read(planet_id) + spent.steel + spent.quartz
                );
        }

        fn update_resources_spent(ref self: ContractState, planet_id: u256, cost: Cost) {
            let current_spent = self.resources_spent.read(planet_id);
            self.resources_spent.write(planet_id, current_spent + cost.steel + cost.quartz);
        }

        fn update_tech_spent(ref self: ContractState, planet_id: u256, cost: Cost) {
            let current_spent = self.tech_spent.read(planet_id);
            self.tech_spent.write(planet_id, current_spent + cost.steel + cost.quartz);
        }

        fn update_fleet_spent(ref self: ContractState, planet_id: u256, cost: Cost) {
            let current_spent = self.fleet_spent.read(planet_id);
            self.tech_spent.write(planet_id, current_spent + cost.steel + cost.quartz);
        }

        fn update_leaderboard(ref self: ContractState, planet_id: u256) {
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
        // ##################################################################################
        //                                TECH FUNCTIONS                   #
        //###################################################################################

        fn get_tech_levels(self: @ContractState, planet_id: u256) -> Techs {
            Techs {
                energy_innovation: self.energy_innovation_level.read(planet_id),
                digital_systems: self.digital_systems_level.read(planet_id),
                beam_technology: self.beam_technology_level.read(planet_id),
                armour_innovation: self.armour_innovation_level.read(planet_id),
                ion_systems: self.ion_systems_level.read(planet_id),
                plasma_engineering: self.plasma_engineering_level.read(planet_id),
                stellar_physics: self.stellar_physics_level.read(planet_id),
                arms_development: self.arms_development_level.read(planet_id),
                shield_tech: self.shield_tech_level.read(planet_id),
                spacetime_warp: self.spacetime_warp_level.read(planet_id),
                combustive_engine: self.combustive_engine_level.read(planet_id),
                thrust_propulsion: self.thrust_propulsion_level.read(planet_id),
                warp_drive: self.warp_drive_level.read(planet_id)
            }
        }
    }
}

