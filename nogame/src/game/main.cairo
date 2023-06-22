use starknet::ContractAddress;
use nogame::game::library::{MinesCost, MinesLevels, Resources};

#[starknet::interface]
trait INoGame<TContractState> {
    fn get_tokens_addresses(
        self: @TContractState
    ) -> (ContractAddress, ContractAddress, ContractAddress, ContractAddress);
    // View functions
    fn get_number_of_planets(self: @TContractState) -> u32;
    fn get_planet_points(self: @TContractState, planet_id: u256) -> u128;
    fn get_mines_levels(self: @TContractState, planet_id: u256) -> MinesLevels;
    fn get_mines_upgrade_cost(self: @TContractState, planet_id: u256) -> MinesCost;
    fn total_resources_available(self: @TContractState, caller: ContractAddress) -> Resources;
    fn generate_planet(ref self: TContractState);
    fn collect_resources(ref self: TContractState);
    // Mines functions
    fn steel_mine_upgrade(ref self: TContractState);
    fn quartz_mine_upgrade(ref self: TContractState);
    fn tritium_mine_upgrade(ref self: TContractState);
    // Compounds functions
    fn energy_plant_upgrade(ref self: TContractState);
    fn dockyard_upgrade(ref self: TContractState);
    fn lab_upgrade(ref self: TContractState);
    // Tech functions
    fn energy_innovation_upgrade(ref self: TContractState);
    fn digital_systems_upgrade(ref self: TContractState);
    fn beam_technology_upgrade(ref self: TContractState);
    fn armour_innovation_upgrade(ref self: TContractState);
    fn ion_systems_upgrade(ref self: TContractState);
    fn plasma_engineering_upgrade(ref self: TContractState);
    fn stellar_physics_upgrade(ref self: TContractState);
    fn arms_development_upgrade(ref self: TContractState);
    fn shield_tech_upgrade(ref self: TContractState);
    fn spacetime_warp_upgrade(ref self: TContractState);
    fn combustive_engine_upgrade(ref self: TContractState);
    fn thrust_propulsion_upgrade(ref self: TContractState);
    fn warp_drive_upgrade(ref self: TContractState);
    // Dockyard functions
    fn carrier_build(ref self: TContractState, quantity: u128);
    fn scraper_build(ref self: TContractState, quantity: u128);
    fn celestia_build(ref self: TContractState, quantity: u128);
    fn sparrow_build(ref self: TContractState, quantity: u128);
    fn frigate_build(ref self: TContractState, quantity: u128);
    fn armade_build(ref self: TContractState, quantity: u128);
}

#[starknet::contract]
mod NoGame {
    use core::option::OptionTrait;
    use core::traits::Into;
    use core::traits::TryInto;
    use starknet::{ContractAddress, get_block_timestamp, get_caller_address, get_contract_address};
    use nogame::game::library::{Tokens, CostExtended, MinesCost, MinesLevels, Resources, Techs};
    use nogame::compounds::library::Compounds;
    use nogame::dockyard::library::Dockyard;
    use nogame::mines::library::Mines;
    use nogame::research::library::Lab;
    use nogame::token::erc20::IERC20DispatcherTrait;
    use nogame::token::erc20::IERC20Dispatcher;
    use nogame::token::erc721::IERC721DispatcherTrait;
    use nogame::token::erc721::IERC721Dispatcher;

    #[storage]
    struct Storage {
        // General.
        number_of_planets: u32,
        planet_generated: LegacyMap::<u256, bool>,
        planet_points: LegacyMap::<u256, u128>,
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
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        PlanetGenerated: PlanetGenerated,
        ResourcesSpent: ResourcesSpent,
        EconomySpent: EconomySpent,
        TechSpent: TechSpent,
        DefenceSpent: DefenceSpent,
    }

    #[derive(Drop, starknet::Event)]
    struct PlanetGenerated {
        planet_id: u256
    }

    // Resources spending events.
    #[derive(Drop, starknet::Event)]
    struct ResourcesSpent {
        planet_id: u256,
        spent: CostExtended
    }

    #[derive(Drop, starknet::Event)]
    struct EconomySpent {
        planet_id: u256,
        spent: u256
    }

    #[derive(Drop, starknet::Event)]
    struct TechSpent {
        planet_id: u256,
        spent: u256
    }

    #[derive(Drop, starknet::Event)]
    struct DefenceSpent {
        planet_id: u256,
        spent: u256
    }

    // Structures upgrade events.

    // Constructor
    #[constructor]
    fn init(
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

    #[external(v0)]
    impl NoGame of super::INoGame<ContractState> {
        //#########################################################################################
        //                                      VIEW FUNCTIONS                                    #
        //#########################################################################################
        fn get_tokens_addresses(
            self: @ContractState
        ) -> (ContractAddress, ContractAddress, ContractAddress, ContractAddress) {
            (
                self.erc721_address.read(),
                self.steel_address.read(),
                self.quartz_address.read(),
                self.tritium_address.read()
            )
        }

        fn get_number_of_planets(self: @ContractState) -> u32 {
            self.number_of_planets.read()
        }


        fn get_planet_points(self: @ContractState, planet_id: u256) -> u128 {
            self.planet_points.read(planet_id)
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
            let _steel: CostExtended = Mines::steel_mine_cost(planet_id.low);
            let _quartz: CostExtended = Mines::quartz_mine_cost(planet_id.low);
            let _tritium: CostExtended = Mines::tritium_mine_cost(planet_id.low);
            let _solar: CostExtended = Mines::energy_plant_cost(planet_id.low);
            MinesCost { steel: _steel, quartz: _quartz, tritium: _tritium, solar: _solar }
        }

        fn total_resources_available(self: @ContractState, caller: ContractAddress) -> Resources {
            let production: Resources = PrivateFunctions::calculate_production(self, caller);
            let erc20_available = PrivateFunctions::get_erc20s_available(self, caller);
            Resources {
                steel: production.steel + erc20_available.steel,
                quartz: production.quartz + erc20_available.quartz,
                tritium: production.tritium + erc20_available.tritium,
                energy: production.energy
            }
        }
        //#########################################################################################
        //                                      EXTERNAL FUNCTIONS                                #
        //#########################################################################################
        fn generate_planet(ref self: ContractState) {
            let game_address = get_contract_address();
            let caller = get_caller_address();
            let planet_id = PrivateFunctions::get_planet_id_from_address(@self, caller);
            if self.planet_generated.read(planet_id) == false {
                self.planet_generated.write(planet_id, true);
                IERC721Dispatcher {
                    contract_address: self.erc721_address.read()
                }.transfer(from: game_address, to: caller, token_id: planet_id);
            }
            let number_of_planets = self.number_of_planets.read();
            self.number_of_planets.write(number_of_planets + 1);
            PrivateFunctions::mint_initial_liquidity(@self, caller);
            self.emit(Event::PlanetGenerated(PlanetGenerated { planet_id: planet_id }))
        }


        fn collect_resources(ref self: ContractState) {
            let caller = get_caller_address();
            let planet_id = PrivateFunctions::get_planet_id_from_address(@self, caller);
            let production = PrivateFunctions::calculate_production(@self, caller);
            PrivateFunctions::send_resources_erc20(@self, caller, production);
            self.resources_timer.write(planet_id, get_block_timestamp());
        }
        //#########################################################################################
        //                               MINES UPGRADE FUNCTIONS                                  #
        //#########################################################################################
        fn steel_mine_upgrade(ref self: ContractState) {
            let caller = get_caller_address();
            let planet_id = PrivateFunctions::get_planet_id_from_address(@self, caller);
            let current_level = self.steel_mine_level.read(planet_id);
            let cost: CostExtended = Mines::steel_mine_cost(current_level);
            PrivateFunctions::check_enough_resources(@self, caller, cost);
            PrivateFunctions::pay_resources_erc20(@self, caller, cost);
            self.steel_mine_level.write(planet_id, current_level + 1);
            PrivateFunctions::update_planet_points(ref self, planet_id, cost);
            self.emit(Event::ResourcesSpent(ResourcesSpent { planet_id: planet_id, spent: cost }))
        }

        fn quartz_mine_upgrade(ref self: ContractState) {
            let caller = get_caller_address();
            let planet_id = PrivateFunctions::get_planet_id_from_address(@self, caller);
            let current_level = self.quartz_mine_level.read(planet_id);
            let cost: CostExtended = Mines::quartz_mine_cost(current_level);
            PrivateFunctions::check_enough_resources(@self, caller, cost);
            PrivateFunctions::pay_resources_erc20(@self, caller, cost);
            self.quartz_mine_level.write(planet_id, current_level + 1);
            PrivateFunctions::update_planet_points(ref self, planet_id, cost);
            self.emit(Event::ResourcesSpent(ResourcesSpent { planet_id: planet_id, spent: cost }))
        }

        fn tritium_mine_upgrade(ref self: ContractState) {
            let caller = get_caller_address();
            let planet_id = PrivateFunctions::get_planet_id_from_address(@self, caller);
            let current_level = self.steel_mine_level.read(planet_id);
            let cost: CostExtended = Mines::tritium_mine_cost(current_level);
            PrivateFunctions::check_enough_resources(@self, caller, cost);
            PrivateFunctions::pay_resources_erc20(@self, caller, cost);
            self.tritium_mine_level.write(planet_id, current_level + 1);
            PrivateFunctions::update_planet_points(ref self, planet_id, cost);
            self.emit(Event::ResourcesSpent(ResourcesSpent { planet_id: planet_id, spent: cost }))
        }

        fn energy_plant_upgrade(ref self: ContractState) {
            let caller = get_caller_address();
            let planet_id = PrivateFunctions::get_planet_id_from_address(@self, caller);
            let current_level = self.energy_plant_level.read(planet_id);
            let cost: CostExtended = Mines::energy_plant_cost(current_level);
            PrivateFunctions::check_enough_resources(@self, caller, cost);
            PrivateFunctions::pay_resources_erc20(@self, caller, cost);
            self.energy_plant_level.write(planet_id, current_level + 1);
            PrivateFunctions::update_planet_points(ref self, planet_id, cost);
            self.emit(Event::ResourcesSpent(ResourcesSpent { planet_id: planet_id, spent: cost }))
        }
        //#########################################################################################
        //                               COMPOUNDS UPGRADE FUNCTIONS                              #
        //#########################################################################################
        fn dockyard_upgrade(ref self: ContractState) {
            let caller = get_caller_address();
            let planet_id = PrivateFunctions::get_planet_id_from_address(@self, caller);
            let current_level = self.dockyard_level.read(planet_id);
            let cost: CostExtended = Compounds::dockyard_cost(current_level);
            PrivateFunctions::check_enough_resources(@self, caller, cost);
            PrivateFunctions::pay_resources_erc20(@self, caller, cost);
            self.dockyard_level.write(planet_id, current_level + 1);
            PrivateFunctions::update_planet_points(ref self, planet_id, cost);
            self.emit(Event::ResourcesSpent(ResourcesSpent { planet_id: planet_id, spent: cost }))
        }

        fn lab_upgrade(ref self: ContractState) {
            let caller = get_caller_address();
            let planet_id = PrivateFunctions::get_planet_id_from_address(@self, caller);
            let current_level = self.lab_level.read(planet_id);
            let cost: CostExtended = Compounds::lab_cost(current_level);
            PrivateFunctions::check_enough_resources(@self, caller, cost);
            PrivateFunctions::pay_resources_erc20(@self, caller, cost);
            self.lab_level.write(planet_id, current_level + 1);
            PrivateFunctions::update_planet_points(ref self, planet_id, cost);
            self.emit(Event::ResourcesSpent(ResourcesSpent { planet_id: planet_id, spent: cost }))
        }

        //#########################################################################################
        //                                      TECH UPGRADES FUNCTIONS                           #
        //#########################################################################################
        fn energy_innovation_upgrade(ref self: ContractState) {
            let caller = get_caller_address();
            let planet_id = PrivateFunctions::get_planet_id_from_address(@self, caller);
            let lab_level = self.lab_level.read(planet_id);
            let techs = PrivateFunctions::get_tech_levels(@self, planet_id);
            Lab::energy_innovation_requirements_check(lab_level, techs);
            let cost = Lab::get_tech_cost(techs.energy_innovation, 0, 800, 400);
            PrivateFunctions::check_enough_resources(@self, caller, cost);
            PrivateFunctions::pay_resources_erc20(@self, caller, cost);
            PrivateFunctions::update_planet_points(ref self, planet_id, cost);
            self.energy_innovation_level.write(planet_id, techs.energy_innovation + 1);
            self.emit(Event::ResourcesSpent(ResourcesSpent { planet_id: planet_id, spent: cost }))
        }

        fn digital_systems_upgrade(ref self: ContractState) {
            let caller = get_caller_address();
            let planet_id = PrivateFunctions::get_planet_id_from_address(@self, caller);
            let lab_level = self.lab_level.read(planet_id);
            let techs = PrivateFunctions::get_tech_levels(@self, planet_id);
            Lab::digital_systems_requirements_check(lab_level, techs);
            let cost = Lab::get_tech_cost(techs.digital_systems, 0, 400, 600);
            PrivateFunctions::check_enough_resources(@self, caller, cost);
            PrivateFunctions::pay_resources_erc20(@self, caller, cost);
            PrivateFunctions::update_planet_points(ref self, planet_id, cost);
            self.digital_systems_level.write(planet_id, techs.digital_systems + 1);
            self.emit(Event::ResourcesSpent(ResourcesSpent { planet_id: planet_id, spent: cost }))
        }

        fn beam_technology_upgrade(ref self: ContractState) {
            let caller = get_caller_address();
            let planet_id = PrivateFunctions::get_planet_id_from_address(@self, caller);
            let lab_level = self.lab_level.read(planet_id);
            let techs = PrivateFunctions::get_tech_levels(@self, planet_id);
            Lab::beam_technology_requirements_check(lab_level, techs);
            let cost = Lab::get_tech_cost(techs.beam_technology, 200, 100, 0);
            PrivateFunctions::check_enough_resources(@self, caller, cost);
            PrivateFunctions::pay_resources_erc20(@self, caller, cost);
            PrivateFunctions::update_planet_points(ref self, planet_id, cost);
            self.beam_technology_level.write(planet_id, techs.beam_technology + 1);
            self.emit(Event::ResourcesSpent(ResourcesSpent { planet_id: planet_id, spent: cost }))
        }

        fn armour_innovation_upgrade(ref self: ContractState) {
            let caller = get_caller_address();
            let planet_id = PrivateFunctions::get_planet_id_from_address(@self, caller);
            let lab_level = self.lab_level.read(planet_id);
            let techs = PrivateFunctions::get_tech_levels(@self, planet_id);
            Lab::armour_innovation_requirements_check(lab_level, techs);
            let cost = Lab::get_tech_cost(techs.digital_systems, 0, 800, 400);
            PrivateFunctions::check_enough_resources(@self, caller, cost);
            PrivateFunctions::pay_resources_erc20(@self, caller, cost);
            PrivateFunctions::update_planet_points(ref self, planet_id, cost);
            self.digital_systems_level.write(planet_id, techs.armour_innovation + 1);
            self.emit(Event::ResourcesSpent(ResourcesSpent { planet_id: planet_id, spent: cost }))
        }

        fn ion_systems_upgrade(ref self: ContractState) {
            let caller = get_caller_address();
            let planet_id = PrivateFunctions::get_planet_id_from_address(@self, caller);
            let lab_level = self.lab_level.read(planet_id);
            let techs = PrivateFunctions::get_tech_levels(@self, planet_id);
            Lab::ion_systems_requirements_check(lab_level, techs);
            let cost = Lab::get_tech_cost(techs.ion_systems, 1000, 300, 1000);
            PrivateFunctions::check_enough_resources(@self, caller, cost);
            PrivateFunctions::pay_resources_erc20(@self, caller, cost);
            PrivateFunctions::update_planet_points(ref self, planet_id, cost);
            self.ion_systems_level.write(planet_id, techs.ion_systems + 1);
            self.emit(Event::ResourcesSpent(ResourcesSpent { planet_id: planet_id, spent: cost }))
        }

        fn plasma_engineering_upgrade(ref self: ContractState) {
            let caller = get_caller_address();
            let planet_id = PrivateFunctions::get_planet_id_from_address(@self, caller);
            let lab_level = self.lab_level.read(planet_id);
            let techs = PrivateFunctions::get_tech_levels(@self, planet_id);
            Lab::plasma_engineering_requirements_check(lab_level, techs);
            let cost = Lab::get_tech_cost(techs.plasma_engineering, 2000, 4000, 1000);
            PrivateFunctions::check_enough_resources(@self, caller, cost);
            PrivateFunctions::pay_resources_erc20(@self, caller, cost);
            PrivateFunctions::update_planet_points(ref self, planet_id, cost);
            self.plasma_engineering_level.write(planet_id, techs.plasma_engineering + 1);
            self.emit(Event::ResourcesSpent(ResourcesSpent { planet_id: planet_id, spent: cost }))
        }

        fn stellar_physics_upgrade(ref self: ContractState) {
            let caller = get_caller_address();
            let planet_id = PrivateFunctions::get_planet_id_from_address(@self, caller);
            let lab_level = self.lab_level.read(planet_id);
            let techs = PrivateFunctions::get_tech_levels(@self, planet_id);
            Lab::stellar_physics_requirements_check(lab_level, techs);
            let cost = Lab::get_tech_cost(techs.stellar_physics, 4000, 8000, 4000);
            PrivateFunctions::check_enough_resources(@self, caller, cost);
            PrivateFunctions::pay_resources_erc20(@self, caller, cost);
            PrivateFunctions::update_planet_points(ref self, planet_id, cost);
            self.stellar_physics_level.write(planet_id, techs.stellar_physics + 1);
            self.emit(Event::ResourcesSpent(ResourcesSpent { planet_id: planet_id, spent: cost }))
        }

        fn arms_development_upgrade(ref self: ContractState) {
            let caller = get_caller_address();
            let planet_id = PrivateFunctions::get_planet_id_from_address(@self, caller);
            let lab_level = self.lab_level.read(planet_id);
            let techs = PrivateFunctions::get_tech_levels(@self, planet_id);
            Lab::arms_development_requirements_check(lab_level, techs);
            let cost = Lab::get_tech_cost(techs.arms_development, 800, 200, 0);
            PrivateFunctions::check_enough_resources(@self, caller, cost);
            PrivateFunctions::pay_resources_erc20(@self, caller, cost);
            PrivateFunctions::update_planet_points(ref self, planet_id, cost);
            self.arms_development_level.write(planet_id, techs.arms_development + 1);
            self.emit(Event::ResourcesSpent(ResourcesSpent { planet_id: planet_id, spent: cost }))
        }

        fn shield_tech_upgrade(ref self: ContractState) {
            let caller = get_caller_address();
            let planet_id = PrivateFunctions::get_planet_id_from_address(@self, caller);
            let lab_level = self.lab_level.read(planet_id);
            let techs = PrivateFunctions::get_tech_levels(@self, planet_id);
            Lab::shield_tech_requirements_check(lab_level, techs);
            let cost = Lab::get_tech_cost(techs.shield_tech, 200, 600, 0);
            PrivateFunctions::check_enough_resources(@self, caller, cost);
            PrivateFunctions::pay_resources_erc20(@self, caller, cost);
            PrivateFunctions::update_planet_points(ref self, planet_id, cost);
            self.shield_tech_level.write(planet_id, techs.shield_tech + 1);
            self.emit(Event::ResourcesSpent(ResourcesSpent { planet_id: planet_id, spent: cost }))
        }

        fn spacetime_warp_upgrade(ref self: ContractState) {
            let caller = get_caller_address();
            let planet_id = PrivateFunctions::get_planet_id_from_address(@self, caller);
            let lab_level = self.lab_level.read(planet_id);
            let techs = PrivateFunctions::get_tech_levels(@self, planet_id);
            Lab::spacetime_warp_requirements_check(lab_level, techs);
            let cost = Lab::get_tech_cost(techs.spacetime_warp, 0, 4000, 2000);
            PrivateFunctions::check_enough_resources(@self, caller, cost);
            PrivateFunctions::pay_resources_erc20(@self, caller, cost);
            PrivateFunctions::update_planet_points(ref self, planet_id, cost);
            self.spacetime_warp_level.write(planet_id, techs.spacetime_warp + 1);
            self.emit(Event::ResourcesSpent(ResourcesSpent { planet_id: planet_id, spent: cost }))
        }

        fn combustive_engine_upgrade(ref self: ContractState) {
            let caller = get_caller_address();
            let planet_id = PrivateFunctions::get_planet_id_from_address(@self, caller);
            let lab_level = self.lab_level.read(planet_id);
            let techs = PrivateFunctions::get_tech_levels(@self, planet_id);
            Lab::combustive_engine_requirements_check(lab_level, techs);
            let cost = Lab::get_tech_cost(techs.combustive_engine, 400, 0, 600);
            PrivateFunctions::check_enough_resources(@self, caller, cost);
            PrivateFunctions::pay_resources_erc20(@self, caller, cost);
            PrivateFunctions::update_planet_points(ref self, planet_id, cost);
            self.combustive_engine_level.write(planet_id, techs.combustive_engine + 1);
            self.emit(Event::ResourcesSpent(ResourcesSpent { planet_id: planet_id, spent: cost }))
        }

        fn thrust_propulsion_upgrade(ref self: ContractState) {
            let caller = get_caller_address();
            let planet_id = PrivateFunctions::get_planet_id_from_address(@self, caller);
            let lab_level = self.lab_level.read(planet_id);
            let techs = PrivateFunctions::get_tech_levels(@self, planet_id);
            Lab::thrust_propulsion_requirements_check(lab_level, techs);
            let cost = Lab::get_tech_cost(techs.thrust_propulsion, 2000, 4000, 600);
            PrivateFunctions::check_enough_resources(@self, caller, cost);
            PrivateFunctions::pay_resources_erc20(@self, caller, cost);
            PrivateFunctions::update_planet_points(ref self, planet_id, cost);
            self.thrust_propulsion_level.write(planet_id, techs.thrust_propulsion + 1);
            self.emit(Event::ResourcesSpent(ResourcesSpent { planet_id: planet_id, spent: cost }))
        }

        fn warp_drive_upgrade(ref self: ContractState) {
            let caller = get_caller_address();
            let planet_id = PrivateFunctions::get_planet_id_from_address(@self, caller);
            let lab_level = self.lab_level.read(planet_id);
            let techs = PrivateFunctions::get_tech_levels(@self, planet_id);
            Lab::warp_drive_requirements_check(lab_level, techs);
            let cost = Lab::get_tech_cost(techs.thrust_propulsion, 10000, 20000, 6000);
            PrivateFunctions::check_enough_resources(@self, caller, cost);
            PrivateFunctions::pay_resources_erc20(@self, caller, cost);
            PrivateFunctions::update_planet_points(ref self, planet_id, cost);
            self.warp_drive_level.write(planet_id, techs.warp_drive + 1);
            self.emit(Event::ResourcesSpent(ResourcesSpent { planet_id: planet_id, spent: cost }))
        }
        //#########################################################################################
        //                                      DOCKYARD FUNCTIONS                                #
        //#########################################################################################
        fn carrier_build(ref self: ContractState, quantity: u128) {
            let caller = get_caller_address();
            let planet_id = PrivateFunctions::get_planet_id_from_address(@self, caller);
            let dockyard_level = self.dockyard_level.read(planet_id);
            let techs = PrivateFunctions::get_tech_levels(@self, planet_id);
            Dockyard::carrier_requirements_check(dockyard_level, techs);
            let cost = Dockyard::get_ships_cost(quantity, 2000, 2000, 0);
            PrivateFunctions::check_enough_resources(@self, caller, cost);
            PrivateFunctions::pay_resources_erc20(@self, caller, cost);
            PrivateFunctions::update_planet_points(ref self, planet_id, cost);
            self
                .carrier_available
                .write(planet_id, self.carrier_available.read(planet_id) + quantity);
            self.emit(Event::ResourcesSpent(ResourcesSpent { planet_id: planet_id, spent: cost }))
        }

        fn scraper_build(ref self: ContractState, quantity: u128) {
            let caller = get_caller_address();
            let planet_id = PrivateFunctions::get_planet_id_from_address(@self, caller);
            let dockyard_level = self.dockyard_level.read(planet_id);
            let techs = PrivateFunctions::get_tech_levels(@self, planet_id);
            Dockyard::scraper_requirements_check(dockyard_level, techs);
            let cost = Dockyard::get_ships_cost(quantity, 10000, 6000, 2000);
            PrivateFunctions::check_enough_resources(@self, caller, cost);
            PrivateFunctions::pay_resources_erc20(@self, caller, cost);
            PrivateFunctions::update_planet_points(ref self, planet_id, cost);
            self
                .scraper_available
                .write(planet_id, self.scraper_available.read(planet_id) + quantity);
            self.emit(Event::ResourcesSpent(ResourcesSpent { planet_id: planet_id, spent: cost }))
        }

        fn celestia_build(ref self: ContractState, quantity: u128) {
            let caller = get_caller_address();
            let planet_id = PrivateFunctions::get_planet_id_from_address(@self, caller);
            let dockyard_level = self.dockyard_level.read(planet_id);
            let techs = PrivateFunctions::get_tech_levels(@self, planet_id);
            Dockyard::celestia_requirements_check(dockyard_level, techs);
            let cost = Dockyard::get_ships_cost(quantity, 0, 2000, 500);
            PrivateFunctions::check_enough_resources(@self, caller, cost);
            PrivateFunctions::pay_resources_erc20(@self, caller, cost);
            PrivateFunctions::update_planet_points(ref self, planet_id, cost);
            self
                .celestia_available
                .write(planet_id, self.celestia_available.read(planet_id) + quantity);
            self.emit(Event::ResourcesSpent(ResourcesSpent { planet_id: planet_id, spent: cost }))
        }

        fn sparrow_build(ref self: ContractState, quantity: u128) {
            let caller = get_caller_address();
            let planet_id = PrivateFunctions::get_planet_id_from_address(@self, caller);
            let dockyard_level = self.dockyard_level.read(planet_id);
            let techs = PrivateFunctions::get_tech_levels(@self, planet_id);
            Dockyard::sparrow_requirements_check(dockyard_level, techs);
            let cost = Dockyard::get_ships_cost(quantity, 3000, 1000, 0);
            PrivateFunctions::check_enough_resources(@self, caller, cost);
            PrivateFunctions::pay_resources_erc20(@self, caller, cost);
            PrivateFunctions::update_planet_points(ref self, planet_id, cost);
            self
                .sparrow_available
                .write(planet_id, self.sparrow_available.read(planet_id) + quantity);
            self.emit(Event::ResourcesSpent(ResourcesSpent { planet_id: planet_id, spent: cost }))
        }

        fn frigate_build(ref self: ContractState, quantity: u128) {
            let caller = get_caller_address();
            let planet_id = PrivateFunctions::get_planet_id_from_address(@self, caller);
            let dockyard_level = self.dockyard_level.read(planet_id);
            let techs = PrivateFunctions::get_tech_levels(@self, planet_id);
            Dockyard::frigate_requirements_check(dockyard_level, techs);
            let cost = Dockyard::get_ships_cost(quantity, 20000, 7000, 2000);
            PrivateFunctions::check_enough_resources(@self, caller, cost);
            PrivateFunctions::pay_resources_erc20(@self, caller, cost);
            PrivateFunctions::update_planet_points(ref self, planet_id, cost);
            self
                .frigate_available
                .write(planet_id, self.frigate_available.read(planet_id) + quantity);
            self.emit(Event::ResourcesSpent(ResourcesSpent { planet_id: planet_id, spent: cost }))
        }

        fn armade_build(ref self: ContractState, quantity: u128) {
            let caller = get_caller_address();
            let planet_id = PrivateFunctions::get_planet_id_from_address(@self, caller);
            let dockyard_level = self.dockyard_level.read(planet_id);
            let techs = PrivateFunctions::get_tech_levels(@self, planet_id);
            Dockyard::armade_requirements_check(dockyard_level, techs);
            let cost = Dockyard::get_ships_cost(quantity, 10000, 6000, 2000);
            PrivateFunctions::check_enough_resources(@self, caller, cost);
            PrivateFunctions::pay_resources_erc20(@self, caller, cost);
            PrivateFunctions::update_planet_points(ref self, planet_id, cost);
            self
                .armade_available
                .write(planet_id, self.armade_available.read(planet_id) + quantity);
            self.emit(Event::ResourcesSpent(ResourcesSpent { planet_id: planet_id, spent: cost }))
        }
    }


    //#########################################################################################
    //                                      PRIVATE FUNCTIONS                                 #
    //#########################################################################################

    #[generate_trait]
    impl PrivateFunctions of PrivateTrait {
        fn get_planet_id_from_address(self: @ContractState, caller: ContractAddress) -> u256 {
            let erc721 = self.erc721_address.read();
            let planet_id = IERC721Dispatcher { contract_address: erc721 }.owner_of(caller);
            planet_id
        }

        fn get_erc20s_available(self: @ContractState, caller: ContractAddress) -> Resources {
            let planet_id = PrivateFunctions::get_planet_id_from_address(self, caller);
            let steel_level = self.steel_mine_level.read(planet_id);
            let quartz_level = self.quartz_mine_level.read(planet_id);
            let tritium_level = self.tritium_mine_level.read(planet_id);

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
            let _energy = PrivateFunctions::calculate_net_energy(self, planet_id);
            Resources { steel: _steel, quartz: _quartz, tritium: _tritium, energy: _energy }
        }

        fn calculate_production(self: @ContractState, caller: ContractAddress) -> Resources {
            let planet_id = PrivateFunctions::get_planet_id_from_address(self, caller);
            let time_now = get_block_timestamp();
            let last_collection_time = self.resources_timer.read(planet_id);
            let time_elapsed = time_now - last_collection_time;
            let steel_available: u256 = u256 {
                low: Mines::steel_production(self.steel_mine_level.read(planet_id)).low
                    * (time_elapsed / 3600).into(),
                high: 0
            };

            let quartz_available: u256 = u256 {
                low: Mines::quartz_production(self.quartz_mine_level.read(planet_id)).low
                    * (time_elapsed / 3600).into(),
                high: 0
            };

            let tritium_available: u256 = u256 {
                low: Mines::tritium_production(self.tritium_mine_level.read(planet_id)).low
                    * (time_elapsed / 3600).into(),
                high: 0
            };

            let energy_available = PrivateFunctions::calculate_net_energy(self, planet_id);

            Resources {
                steel: steel_available,
                quartz: quartz_available,
                tritium: tritium_available,
                energy: energy_available
            }
        }

        fn calculate_net_energy(self: @ContractState, planet_id: u256) -> u128 {
            let energy = Mines::energy_plant_production(self.energy_plant_level.read(planet_id));
            let energy_needed = Mines::base_mine_consumption(self.steel_mine_level.read(planet_id))
                + Mines::base_mine_consumption(self.quartz_mine_level.read(planet_id))
                + Mines::tritium_mine_consumption(self.tritium_mine_level.read(planet_id));
            if energy < energy_needed {
                return 0;
            } else {
                energy - energy_needed
            }
        }

        fn send_resources_erc20(self: @ContractState, to: ContractAddress, amounts: Resources) {
            let tokens: Tokens = PrivateFunctions::get_tokens_addresses(self);
            IERC20Dispatcher { contract_address: tokens.steel }.mint(to, amounts.steel);
            IERC20Dispatcher { contract_address: tokens.quartz }.mint(to, amounts.quartz);
            IERC20Dispatcher { contract_address: tokens.tritium }.mint(to, amounts.tritium)
        }

        fn pay_resources_erc20(
            self: @ContractState, account: ContractAddress, amounts: CostExtended
        ) {
            let tokens: Tokens = PrivateFunctions::get_tokens_addresses(self);
            IERC20Dispatcher { contract_address: tokens.steel }.burn(account, amounts.steel);
            IERC20Dispatcher { contract_address: tokens.quartz }.burn(account, amounts.quartz);
            IERC20Dispatcher { contract_address: tokens.tritium }.burn(account, amounts.tritium)
        }

        fn mint_initial_liquidity(self: @ContractState, account: ContractAddress) {
            let tokens: Tokens = PrivateFunctions::get_tokens_addresses(self);
            IERC20Dispatcher {
                contract_address: tokens.steel
            }.mint(recipient: account, amount: u256 { low: 500, high: 0 });
            IERC20Dispatcher {
                contract_address: tokens.quartz
            }.mint(recipient: account, amount: u256 { low: 300, high: 0 });
            IERC20Dispatcher {
                contract_address: tokens.tritium
            }.mint(recipient: account, amount: u256 { low: 100, high: 0 });
        }

        fn check_enough_resources(
            self: @ContractState, caller: ContractAddress, amounts: CostExtended
        ) {
            let available: Resources = PrivateFunctions::get_erc20s_available(self, caller);
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

        fn update_planet_points(ref self: ContractState, planet_id: u256, spent: CostExtended) {
            let current_points = self.planet_points.read(planet_id);
            let acquired_points = (spent.steel.low + spent.quartz.low) / 1000;
            self.planet_points.write(planet_id, current_points + acquired_points);
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

