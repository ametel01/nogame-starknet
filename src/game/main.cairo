#[starknet::contract]
mod NoGame {
    use traits::DivRem;
    use starknet::{ContractAddress, get_block_timestamp, get_caller_address, get_contract_address};
    use nogame::game::interface::INoGame;
    use nogame::{
        E18, DefencesCost, DefencesLevels, EnergyCost, ERC20s, CompoundsCost, CompoundsLevels,
        ShipsLevels, ShipsCost, TechLevels, TechsCost, Tokens, PlanetPosition, Cargo, Debris
    };
    use nogame::compounds::Compounds;
    use nogame::defences::Defences;
    use nogame::dockyard::Dockyard;
    use nogame::research::Lab;
    use nogame::token::erc20::{INGERC20DispatcherTrait, INGERC20Dispatcher};
    use nogame::token::erc721::{INGERC721DispatcherTrait, INGERC721Dispatcher};

    use xoroshiro::xoroshiro::{IXoroshiroDispatcher, IXoroshiroDispatcherTrait};

    use debug::PrintTrait;

    #[storage]
    struct Storage {
        // General.
        number_of_planets: u16,
        planet_position: LegacyMap::<u16, PlanetPosition>,
        position_raw_to_planet_id: LegacyMap::<u16, u16>,
        planet_debris_field: LegacyMap::<u16, Debris>,
        universe_start_time: u64,
        resources_spent: LegacyMap::<u16, u128>,
        // Tokens.
        erc721: INGERC721Dispatcher,
        steel: INGERC20Dispatcher,
        quartz: INGERC20Dispatcher,
        tritium: INGERC20Dispatcher,
        rand: IXoroshiroDispatcher,
        // Infrastructures.
        steel_mine_level: LegacyMap::<u16, u8>,
        quartz_mine_level: LegacyMap::<u16, u8>,
        tritium_mine_level: LegacyMap::<u16, u8>,
        energy_plant_level: LegacyMap::<u16, u8>,
        dockyard_level: LegacyMap::<u16, u8>,
        lab_level: LegacyMap::<u16, u8>,
        resources_timer: LegacyMap::<u16, u64>,
        // Technologies
        energy_innovation_level: LegacyMap::<u16, u8>,
        digital_systems_level: LegacyMap::<u16, u8>,
        beam_technology_level: LegacyMap::<u16, u8>,
        armour_innovation_level: LegacyMap::<u16, u8>,
        ion_systems_level: LegacyMap::<u16, u8>,
        plasma_engineering_level: LegacyMap::<u16, u8>,
        stellar_physics_level: LegacyMap::<u16, u8>,
        weapons_development_level: LegacyMap::<u16, u8>,
        shield_tech_level: LegacyMap::<u16, u8>,
        spacetime_warp_level: LegacyMap::<u16, u8>,
        combustive_engine_level: LegacyMap::<u16, u8>,
        thrust_propulsion_level: LegacyMap::<u16, u8>,
        warp_drive_level: LegacyMap::<u16, u8>,
        // Ships
        carrier_available: LegacyMap::<u16, u32>,
        scraper_available: LegacyMap::<u16, u32>,
        celestia_available: LegacyMap::<u16, u32>,
        sparrow_available: LegacyMap::<u16, u32>,
        frigate_available: LegacyMap::<u16, u32>,
        armade_available: LegacyMap::<u16, u32>,
        // Defences
        blaster_available: LegacyMap::<u16, u32>,
        beam_available: LegacyMap::<u16, u32>,
        astral_launcher_available: LegacyMap::<u16, u32>,
        plasma_projector_available: LegacyMap::<u16, u32>,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        ResourcesSpent: ResourcesSpent,
        TechSpent: TechSpent,
        FleetSpent: FleetSpent,
    }

    #[derive(Drop, starknet::Event)]
    struct ResourcesSpent {
        planet_id: u16,
        spent: ERC20s
    }

    #[derive(Drop, starknet::Event)]
    struct TechSpent {
        planet_id: u16,
        spent: u128,
    }

    #[derive(Drop, starknet::Event)]
    struct FleetSpent {
        planet_id: u16,
        spent: u128,
    }

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
            tritium: ContractAddress,
            rand: ContractAddress,
        ) {
            self.erc721.write(INGERC721Dispatcher { contract_address: erc721 });
            self.steel.write(INGERC20Dispatcher { contract_address: steel });
            self.quartz.write(INGERC20Dispatcher { contract_address: quartz });
            self.tritium.write(INGERC20Dispatcher { contract_address: tritium });
            self.rand.write(IXoroshiroDispatcher { contract_address: rand });
        }

        /////////////////////////////////////////////////////////////////////
        //                         Planet Functions                                
        /////////////////////////////////////////////////////////////////////
        fn generate_planet(ref self: ContractState) {
            let caller = get_caller_address();
            let token_id = self.number_of_planets.read() + 1;
            self.erc721.read().mint(to: caller, token_id: token_id.into());
            let position = self.calculate_planet_position(token_id);
            let raw_position = self.get_raw_from_position(position);
            self.planet_position.write(token_id, position);
            self.position_raw_to_planet_id.write(raw_position, token_id);
            self.number_of_planets.write(token_id);
            self.receive_resources_erc20(caller, ERC20s { steel: 500, quartz: 300, tritium: 100 });
            self.resources_timer.write(token_id, get_block_timestamp());
        }

        fn collect_resources(ref self: ContractState) {
            self._collect_resources(get_caller_address());
        }

        /////////////////////////////////////////////////////////////////////
        //                         Mines Functions                                
        /////////////////////////////////////////////////////////////////////
        fn steel_mine_upgrade(ref self: ContractState) {
            let caller = get_caller_address();
            self._collect_resources(caller);
            let planet_id = self.get_owned_planet(caller);
            let current_level = self.steel_mine_level.read(planet_id);
            let cost: ERC20s = Compounds::steel_mine_cost(current_level);
            self.check_enough_resources(caller, cost);
            self.pay_resources_erc20(caller, cost);
            self.steel_mine_level.write(planet_id, current_level + 1);
            self.update_planet_points(planet_id, cost);
            self.emit(Event::ResourcesSpent(ResourcesSpent { planet_id: planet_id, spent: cost }))
        }
        fn quartz_mine_upgrade(ref self: ContractState) {
            let caller = get_caller_address();
            self._collect_resources(caller);
            let planet_id = self.get_owned_planet(caller);
            let current_level = self.quartz_mine_level.read(planet_id);
            let cost: ERC20s = Compounds::quartz_mine_cost(current_level);
            self.check_enough_resources(caller, cost);
            self.pay_resources_erc20(caller, cost);
            self.quartz_mine_level.write(planet_id, current_level + 1);
            self.update_planet_points(planet_id, cost);
            self.emit(Event::ResourcesSpent(ResourcesSpent { planet_id: planet_id, spent: cost }))
        }
        fn tritium_mine_upgrade(ref self: ContractState) {
            let caller = get_caller_address();
            self._collect_resources(caller);
            let planet_id = self.get_owned_planet(caller);
            let current_level = self.steel_mine_level.read(planet_id);
            let cost: ERC20s = Compounds::tritium_mine_cost(current_level);
            self.check_enough_resources(caller, cost);
            self.pay_resources_erc20(caller, cost);
            self.tritium_mine_level.write(planet_id, current_level + 1);
            self.update_planet_points(planet_id, cost);
            self.emit(Event::ResourcesSpent(ResourcesSpent { planet_id: planet_id, spent: cost }))
        }
        fn energy_plant_upgrade(ref self: ContractState) {
            let caller = get_caller_address();
            self._collect_resources(caller);
            let planet_id = self.get_owned_planet(caller);
            let current_level = self.energy_plant_level.read(planet_id);
            let cost: ERC20s = Compounds::energy_plant_cost(current_level);
            self.check_enough_resources(caller, cost);
            self.pay_resources_erc20(caller, cost);
            self.energy_plant_level.write(planet_id, current_level + 1);
            self.update_planet_points(planet_id, cost);
            self.emit(Event::ResourcesSpent(ResourcesSpent { planet_id: planet_id, spent: cost }))
        }

        fn dockyard_upgrade(ref self: ContractState) {
            let caller = get_caller_address();
            self._collect_resources(caller);
            let planet_id = self.get_owned_planet(caller);
            let current_level = self.dockyard_level.read(planet_id);
            let cost: ERC20s = Compounds::dockyard_cost(current_level);
            self.check_enough_resources(caller, cost);
            self.pay_resources_erc20(caller, cost);
            self.dockyard_level.write(planet_id, current_level + 1);
            self.update_planet_points(planet_id, cost);
            self.emit(Event::ResourcesSpent(ResourcesSpent { planet_id: planet_id, spent: cost }))
        }
        fn lab_upgrade(ref self: ContractState) {
            let caller = get_caller_address();
            self._collect_resources(caller);
            let planet_id = self.get_owned_planet(caller);
            let current_level = self.lab_level.read(planet_id);
            let cost: ERC20s = Compounds::lab_cost(current_level);
            self.check_enough_resources(caller, cost);
            self.pay_resources_erc20(caller, cost);
            self.lab_level.write(planet_id, current_level + 1);
            self.update_planet_points(planet_id, cost);
            self.emit(Event::ResourcesSpent(ResourcesSpent { planet_id: planet_id, spent: cost }))
        }

        /////////////////////////////////////////////////////////////////////
        //                         Research Functions                                
        /////////////////////////////////////////////////////////////////////
        fn energy_innovation_upgrade(ref self: ContractState) {
            let caller = get_caller_address();
            self._collect_resources(caller);
            let planet_id = self.get_owned_planet(caller);
            let lab_level = self.lab_level.read(planet_id);
            let techs = self.get_tech_levels(planet_id);
            Lab::energy_innovation_requirements_check(lab_level, techs);
            let cost = self.techs_cost(techs).energy;
            self.check_enough_resources(caller, cost);
            self.pay_resources_erc20(caller, cost);
            self.update_planet_points(planet_id, cost);
            self.energy_innovation_level.write(planet_id, techs.energy + 1);
            self.emit(Event::ResourcesSpent(ResourcesSpent { planet_id: planet_id, spent: cost }))
        }
        fn digital_systems_upgrade(ref self: ContractState) {
            let caller = get_caller_address();
            self._collect_resources(caller);
            let planet_id = self.get_owned_planet(caller);
            let lab_level = self.lab_level.read(planet_id);
            let techs = self.get_tech_levels(planet_id);
            Lab::digital_systems_requirements_check(lab_level, techs);
            let cost = self.techs_cost(techs).digital;
            self.check_enough_resources(caller, cost);
            self.pay_resources_erc20(caller, cost);
            self.update_planet_points(planet_id, cost);
            self.digital_systems_level.write(planet_id, techs.digital + 1);
            self.emit(Event::ResourcesSpent(ResourcesSpent { planet_id: planet_id, spent: cost }))
        }
        fn beam_technology_upgrade(ref self: ContractState) {
            let caller = get_caller_address();
            self._collect_resources(caller);
            let planet_id = self.get_owned_planet(caller);
            let lab_level = self.lab_level.read(planet_id);
            let techs = self.get_tech_levels(planet_id);
            Lab::beam_technology_requirements_check(lab_level, techs);
            let cost = self.techs_cost(techs).beam;
            self.check_enough_resources(caller, cost);
            self.pay_resources_erc20(caller, cost);
            self.update_planet_points(planet_id, cost);
            self.beam_technology_level.write(planet_id, techs.beam + 1);
            self.emit(Event::ResourcesSpent(ResourcesSpent { planet_id: planet_id, spent: cost }))
        }
        fn armour_innovation_upgrade(ref self: ContractState) {
            let caller = get_caller_address();
            self._collect_resources(caller);
            let planet_id = self.get_owned_planet(caller);
            let lab_level = self.lab_level.read(planet_id);
            let techs = self.get_tech_levels(planet_id);
            Lab::armour_innovation_requirements_check(lab_level, techs);
            let cost = self.techs_cost(techs).armour;
            self.check_enough_resources(caller, cost);
            self.pay_resources_erc20(caller, cost);
            self.update_planet_points(planet_id, cost);
            self.armour_innovation_level.write(planet_id, techs.armour + 1);
            self.emit(Event::ResourcesSpent(ResourcesSpent { planet_id: planet_id, spent: cost }))
        }
        fn ion_systems_upgrade(ref self: ContractState) {
            let caller = get_caller_address();
            self._collect_resources(caller);
            let planet_id = self.get_owned_planet(caller);
            let lab_level = self.lab_level.read(planet_id);
            let techs = self.get_tech_levels(planet_id);
            Lab::ion_systems_requirements_check(lab_level, techs);
            let cost = self.techs_cost(techs).ion;
            self.check_enough_resources(caller, cost);
            self.pay_resources_erc20(caller, cost);
            self.update_planet_points(planet_id, cost);
            self.ion_systems_level.write(planet_id, techs.ion + 1);
            self.emit(Event::ResourcesSpent(ResourcesSpent { planet_id: planet_id, spent: cost }))
        }
        fn plasma_engineering_upgrade(ref self: ContractState) {
            let caller = get_caller_address();
            self._collect_resources(caller);
            let planet_id = self.get_owned_planet(caller);
            let lab_level = self.lab_level.read(planet_id);
            let techs = self.get_tech_levels(planet_id);
            Lab::plasma_engineering_requirements_check(lab_level, techs);
            let cost = self.techs_cost(techs).plasma;
            self.check_enough_resources(caller, cost);
            self.pay_resources_erc20(caller, cost);
            self.update_planet_points(planet_id, cost);
            self.plasma_engineering_level.write(planet_id, techs.plasma + 1);
            self.emit(Event::ResourcesSpent(ResourcesSpent { planet_id: planet_id, spent: cost }))
        }

        fn weapons_development_upgrade(ref self: ContractState) {
            let caller = get_caller_address();
            self._collect_resources(caller);
            let planet_id = self.get_owned_planet(caller);
            let lab_level = self.lab_level.read(planet_id);
            let techs = self.get_tech_levels(planet_id);
            Lab::weapons_development_requirements_check(lab_level, techs);
            let cost = self.techs_cost(techs).weapons;
            self.check_enough_resources(caller, cost);
            self.pay_resources_erc20(caller, cost);
            self.update_planet_points(planet_id, cost);
            self.weapons_development_level.write(planet_id, techs.weapons + 1);
            self.emit(Event::ResourcesSpent(ResourcesSpent { planet_id: planet_id, spent: cost }))
        }
        fn shield_tech_upgrade(ref self: ContractState) {
            let caller = get_caller_address();
            self._collect_resources(caller);
            let planet_id = self.get_owned_planet(caller);
            let lab_level = self.lab_level.read(planet_id);
            let techs = self.get_tech_levels(planet_id);
            Lab::shield_tech_requirements_check(lab_level, techs);
            let cost = self.techs_cost(techs).shield;
            self.check_enough_resources(caller, cost);
            self.pay_resources_erc20(caller, cost);
            self.update_planet_points(planet_id, cost);
            self.shield_tech_level.write(planet_id, techs.shield + 1);
            self.emit(Event::ResourcesSpent(ResourcesSpent { planet_id: planet_id, spent: cost }))
        }
        fn spacetime_warp_upgrade(ref self: ContractState) {
            let caller = get_caller_address();
            self._collect_resources(caller);
            let planet_id = self.get_owned_planet(caller);
            let lab_level = self.lab_level.read(planet_id);
            let techs = self.get_tech_levels(planet_id);
            Lab::spacetime_warp_requirements_check(lab_level, techs);
            let cost = self.techs_cost(techs).spacetime;
            self.check_enough_resources(caller, cost);
            self.pay_resources_erc20(caller, cost);
            self.update_planet_points(planet_id, cost);
            self.spacetime_warp_level.write(planet_id, techs.spacetime + 1);
            self.emit(Event::ResourcesSpent(ResourcesSpent { planet_id: planet_id, spent: cost }))
        }
        fn combustive_engine_upgrade(ref self: ContractState) {
            let caller = get_caller_address();
            self._collect_resources(caller);
            let planet_id = self.get_owned_planet(caller);
            let lab_level = self.lab_level.read(planet_id);
            let techs = self.get_tech_levels(planet_id);
            Lab::combustive_engine_requirements_check(lab_level, techs);
            let cost = Lab::get_tech_cost(techs.combustion, 400, 0, 600);
            self.check_enough_resources(caller, cost);
            self.pay_resources_erc20(caller, cost);
            self.update_planet_points(planet_id, cost);
            self.combustive_engine_level.write(planet_id, techs.combustion + 1);
            self.emit(Event::ResourcesSpent(ResourcesSpent { planet_id: planet_id, spent: cost }))
        }
        fn thrust_propulsion_upgrade(ref self: ContractState) {
            let caller = get_caller_address();
            self._collect_resources(caller);
            let planet_id = self.get_owned_planet(caller);
            let lab_level = self.lab_level.read(planet_id);
            let techs = self.get_tech_levels(planet_id);
            Lab::thrust_propulsion_requirements_check(lab_level, techs);
            let cost = self.techs_cost(techs).thrust;
            self.check_enough_resources(caller, cost);
            self.pay_resources_erc20(caller, cost);
            self.update_planet_points(planet_id, cost);
            self.thrust_propulsion_level.write(planet_id, techs.thrust + 1);
            self.emit(Event::ResourcesSpent(ResourcesSpent { planet_id: planet_id, spent: cost }))
        }
        fn warp_drive_upgrade(ref self: ContractState) {
            let caller = get_caller_address();
            self._collect_resources(caller);
            let planet_id = self.get_owned_planet(caller);
            let lab_level = self.lab_level.read(planet_id);
            let techs = self.get_tech_levels(planet_id);
            Lab::warp_drive_requirements_check(lab_level, techs);
            let cost = self.techs_cost(techs).warp;
            self.check_enough_resources(caller, cost);
            self.pay_resources_erc20(caller, cost);
            self.update_planet_points(planet_id, cost);
            self.warp_drive_level.write(planet_id, techs.warp + 1);
            self.emit(Event::ResourcesSpent(ResourcesSpent { planet_id: planet_id, spent: cost }))
        }

        /////////////////////////////////////////////////////////////////////
        //                         Dockyard Functions                                
        /////////////////////////////////////////////////////////////////////
        fn carrier_build(ref self: ContractState, quantity: u32) {
            let caller = get_caller_address();
            self._collect_resources(caller);
            let planet_id = self.get_owned_planet(caller);
            let dockyard_level = self.dockyard_level.read(planet_id);
            let techs = self.get_tech_levels(planet_id);
            Dockyard::carrier_requirements_check(dockyard_level, techs);
            let cost = Dockyard::get_ships_cost(quantity, NoGame::get_ships_cost(@self).carrier);
            self.check_enough_resources(caller, cost);
            self.pay_resources_erc20(caller, cost);
            self.update_planet_points(planet_id, cost);
            self
                .carrier_available
                .write(planet_id, self.carrier_available.read(planet_id) + quantity);
            self.emit(Event::ResourcesSpent(ResourcesSpent { planet_id: planet_id, spent: cost }))
        }
        fn scraper_build(ref self: ContractState, quantity: u32) {
            let caller = get_caller_address();
            self._collect_resources(caller);
            let planet_id = self.get_owned_planet(caller);
            let dockyard_level = self.dockyard_level.read(planet_id);
            let techs = self.get_tech_levels(planet_id);
            Dockyard::scraper_requirements_check(dockyard_level, techs);
            let cost = Dockyard::get_ships_cost(quantity, NoGame::get_ships_cost(@self).scraper);
            self.check_enough_resources(caller, cost);
            self.pay_resources_erc20(caller, cost);
            self.update_planet_points(planet_id, cost);
            self
                .scraper_available
                .write(planet_id, self.scraper_available.read(planet_id) + quantity);
            self.emit(Event::ResourcesSpent(ResourcesSpent { planet_id: planet_id, spent: cost }))
        }
        fn celestia_build(ref self: ContractState, quantity: u32) {
            let caller = get_caller_address();
            self._collect_resources(caller);
            let planet_id = self.get_owned_planet(caller);
            let dockyard_level = self.dockyard_level.read(planet_id);
            let techs = self.get_tech_levels(planet_id);
            Dockyard::celestia_requirements_check(dockyard_level, techs);
            let cost = Dockyard::get_ships_cost(quantity, NoGame::get_ships_cost(@self).celestia);
            self.check_enough_resources(caller, cost);
            self.pay_resources_erc20(caller, cost);
            self.update_planet_points(planet_id, cost);
            self
                .celestia_available
                .write(planet_id, self.celestia_available.read(planet_id) + quantity);
            self.emit(Event::ResourcesSpent(ResourcesSpent { planet_id: planet_id, spent: cost }))
        }
        fn sparrow_build(ref self: ContractState, quantity: u32) {
            let caller = get_caller_address();
            self._collect_resources(caller);
            let planet_id = self.get_owned_planet(caller);
            let dockyard_level = self.dockyard_level.read(planet_id);
            let techs = self.get_tech_levels(planet_id);
            Dockyard::sparrow_requirements_check(dockyard_level, techs);
            let cost = Dockyard::get_ships_cost(quantity, NoGame::get_ships_cost(@self).sparrow);
            self.check_enough_resources(caller, cost);
            self.pay_resources_erc20(caller, cost);
            self.update_planet_points(planet_id, cost);
            self
                .sparrow_available
                .write(planet_id, self.sparrow_available.read(planet_id) + quantity);
            self.emit(Event::ResourcesSpent(ResourcesSpent { planet_id: planet_id, spent: cost }))
        }
        fn frigate_build(ref self: ContractState, quantity: u32) {
            let caller = get_caller_address();
            self._collect_resources(caller);
            let planet_id = self.get_owned_planet(caller);
            let dockyard_level = self.dockyard_level.read(planet_id);
            let techs = self.get_tech_levels(planet_id);
            Dockyard::frigate_requirements_check(dockyard_level, techs);
            let cost = Dockyard::get_ships_cost(quantity, NoGame::get_ships_cost(@self).frigate);
            self.check_enough_resources(caller, cost);
            self.pay_resources_erc20(caller, cost);
            self.update_planet_points(planet_id, cost);
            self
                .frigate_available
                .write(planet_id, self.frigate_available.read(planet_id) + quantity);
            self.emit(Event::ResourcesSpent(ResourcesSpent { planet_id: planet_id, spent: cost }))
        }
        fn armade_build(ref self: ContractState, quantity: u32) {
            let caller = get_caller_address();
            self._collect_resources(caller);
            let planet_id = self.get_owned_planet(caller);
            let dockyard_level = self.dockyard_level.read(planet_id);
            let techs = self.get_tech_levels(planet_id);
            Dockyard::armade_requirements_check(dockyard_level, techs);
            let cost = Dockyard::get_ships_cost(quantity, NoGame::get_ships_cost(@self).armade);
            self.check_enough_resources(caller, cost);
            self.pay_resources_erc20(caller, cost);
            self.update_planet_points(planet_id, cost);
            self
                .armade_available
                .write(planet_id, self.armade_available.read(planet_id) + quantity);
            self.emit(Event::ResourcesSpent(ResourcesSpent { planet_id: planet_id, spent: cost }))
        }

        /////////////////////////////////////////////////////////////////////
        //                         Defences Functions                                
        /////////////////////////////////////////////////////////////////////
        fn blaster_build(ref self: ContractState, quantity: u32) {
            let caller = get_caller_address();
            self._collect_resources(caller);
            let planet_id = self.get_owned_planet(caller);
            let dockyard_level = self.dockyard_level.read(planet_id);
            let techs = self.get_tech_levels(planet_id);
            Defences::blaster_requirements_check(dockyard_level, techs);
            let cost = Defences::get_defences_cost(quantity, 2000, 0, 0);
            self.check_enough_resources(caller, cost);
            self.pay_resources_erc20(caller, cost);
            self.update_planet_points(planet_id, cost);
            self
                .blaster_available
                .write(planet_id, self.blaster_available.read(planet_id) + quantity);
            self.emit(Event::ResourcesSpent(ResourcesSpent { planet_id: planet_id, spent: cost }))
        }
        fn beam_build(ref self: ContractState, quantity: u32) {
            let caller = get_caller_address();
            self._collect_resources(caller);
            let planet_id = self.get_owned_planet(caller);
            let dockyard_level = self.dockyard_level.read(planet_id);
            let techs = self.get_tech_levels(planet_id);
            Defences::beam_requirements_check(dockyard_level, techs);
            let cost = Defences::get_defences_cost(quantity, 6000, 2000, 0);
            self.check_enough_resources(caller, cost);
            self.pay_resources_erc20(caller, cost);
            self.update_planet_points(planet_id, cost);
            self.beam_available.write(planet_id, self.beam_available.read(planet_id) + quantity);
            self.emit(Event::ResourcesSpent(ResourcesSpent { planet_id: planet_id, spent: cost }))
        }
        fn astral_launcher_build(ref self: ContractState, quantity: u32) {
            let caller = get_caller_address();
            self._collect_resources(caller);
            let planet_id = self.get_owned_planet(caller);
            let dockyard_level = self.dockyard_level.read(planet_id);
            let techs = self.get_tech_levels(planet_id);
            Defences::astral_launcher_requirements_check(dockyard_level, techs);
            let cost = Defences::get_defences_cost(quantity, 20000, 15000, 2000);
            self.check_enough_resources(caller, cost);
            self.pay_resources_erc20(caller, cost);
            self.update_planet_points(planet_id, cost);
            self
                .astral_launcher_available
                .write(planet_id, self.astral_launcher_available.read(planet_id) + quantity);
            self.emit(Event::ResourcesSpent(ResourcesSpent { planet_id: planet_id, spent: cost }))
        }
        fn plasma_projector_build(ref self: ContractState, quantity: u32) {
            let caller = get_caller_address();
            self._collect_resources(caller);
            let planet_id = self.get_owned_planet(caller);
            let dockyard_level = self.dockyard_level.read(planet_id);
            let techs = self.get_tech_levels(planet_id);
            Defences::plasma_beam_requirements_check(dockyard_level, techs);
            let cost = Defences::get_defences_cost(quantity, 50000, 50000, 30000);
            self.pay_resources_erc20(caller, cost);
            self.update_planet_points(planet_id, cost);
            self
                .plasma_projector_available
                .write(planet_id, self.plasma_projector_available.read(planet_id) + quantity);
            self.emit(Event::ResourcesSpent(ResourcesSpent { planet_id: planet_id, spent: cost }))
        }

        /////////////////////////////////////////////////////////////////////
        //                         Fleet Functions                                
        /////////////////////////////////////////////////////////////////////
        fn send_fleet(
            ref self: ContractState, fleet: ShipsLevels, destination: PlanetPosition, cargo: Cargo
        ) {}
        fn drop_resources(ref self: ContractState, mission_id: u8) {}
        fn attack_planet(ref self: ContractState, mission_id: u8) {}
        fn recall_fleet(ref self: ContractState, mission_id: u8) {}

        /////////////////////////////////////////////////////////////////////
        //                         View Functions                                
        /////////////////////////////////////////////////////////////////////
        fn get_token_addresses(self: @ContractState) -> Tokens {
            self.get_tokens_addresses()
        }

        fn get_number_of_planets(self: @ContractState) -> u16 {
            self.number_of_planets.read()
        }

        fn get_planet_position(self: @ContractState, planet_id: u16) -> PlanetPosition {
            self.planet_position.read(planet_id)
        }

        fn get_position_slot_occupant(self: @ContractState, position: PlanetPosition) -> u16 {
            self.position_raw_to_planet_id.read(self.get_raw_from_position(position))
        }

        fn get_debris_field(self: @ContractState, planet_id: u16) -> Debris {
            self.planet_debris_field.read(planet_id)
        }

        fn get_planet_points(self: @ContractState, planet_id: u16) -> u128 {
            self.resources_spent.read(planet_id) / 1000
        }

        fn get_spendable_resources(self: @ContractState, planet_id: u16) -> ERC20s {
            let planet_owner = self.erc721.read().owner_of(planet_id.into());
            let steel = self.steel.read().balance_of(planet_owner).low / E18;
            let quartz = self.quartz.read().balance_of(planet_owner).low / E18;
            let tritium = self.tritium.read().balance_of(planet_owner).low / E18;
            ERC20s { steel: steel, quartz: quartz, tritium: tritium }
        }

        fn get_collectible_resources(self: @ContractState, planet_id: u16) -> ERC20s {
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

        fn get_energy_available(self: @ContractState, planet_id: u16) -> u128 {
            let compounds_levels = NoGame::get_compounds_levels(self, planet_id);
            let gross_production = Compounds::energy_plant_production(
                self.energy_plant_level.read(planet_id)
            );
            let celestia_production: u128 = self.celestia_available.read(planet_id).into() * 15;
            let energy_required = self.calculate_energy_consumption(compounds_levels);
            if (gross_production + celestia_production) < energy_required {
                return 0;
            } else {
                return gross_production + celestia_production - energy_required;
            }
        }

        fn get_compounds_levels(self: @ContractState, planet_id: u16) -> CompoundsLevels {
            (CompoundsLevels {
                steel: self.steel_mine_level.read(planet_id),
                quartz: self.quartz_mine_level.read(planet_id),
                tritium: self.tritium_mine_level.read(planet_id),
                energy: self.energy_plant_level.read(planet_id),
                lab: self.lab_level.read(planet_id),
                dockyard: self.dockyard_level.read(planet_id)
            })
        }

        fn get_compounds_upgrade_cost(self: @ContractState, planet_id: u16) -> CompoundsCost {
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

        fn get_energy_for_upgrade(self: @ContractState, planet_id: u16) -> EnergyCost {
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

        fn get_techs_levels(self: @ContractState, planet_id: u16) -> TechLevels {
            self.get_tech_levels(planet_id)
        }

        fn get_techs_upgrade_cost(self: @ContractState, planet_id: u16) -> TechsCost {
            let techs = self.get_tech_levels(planet_id);
            self.techs_cost(techs)
        }

        fn get_ships_levels(self: @ContractState, planet_id: u16) -> ShipsLevels {
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

        fn get_defences_levels(self: @ContractState, planet_id: u16) -> DefencesLevels {
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
        fn calculate_planet_position(self: @ContractState, planet_id: u16) -> PlanetPosition {
            let mut position: PlanetPosition = Default::default();
            let rand = self.rand.read();
            loop {
                position.system = (rand.next() % 200 + 1).try_into().unwrap();
                position.orbit = (rand.next() % 10 + 1).try_into().unwrap();
                if self
                    .position_raw_to_planet_id
                    .read(self.get_raw_from_position(position))
                    .is_zero() {
                    break;
                }
                continue;
            };
            position
        }

        #[inline(always)]
        fn get_position_from_raw(self: @ContractState, raw_position: u16) -> PlanetPosition {
            PlanetPosition {
                system: (raw_position / 10).try_into().unwrap(),
                orbit: (raw_position % 10).try_into().unwrap()
            }
        }

        #[inline(always)]
        fn get_raw_from_position(self: @ContractState, position: PlanetPosition) -> u16 {
            position.system.into() * 10 + position.orbit.into()
        }

        #[inline(always)]
        fn extract_planet_position(raw_position: u64) -> (u64, u64) {
            DivRem::div_rem(raw_position, 100_u64.try_into().unwrap())
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
            let time_now = get_block_timestamp();
            let last_collection_time = self.resources_timer.read(planet_id);
            let time_elapsed = time_now - last_collection_time;
            let mines_levels = NoGame::get_compounds_levels(self, planet_id);
            let steel_available = Compounds::steel_production(mines_levels.steel)
                * time_elapsed.into()
                / 3600;

            let quartz_available = Compounds::quartz_production(mines_levels.quartz)
                * time_elapsed.into()
                / 3600;

            let tritium_available = Compounds::tritium_production(mines_levels.tritium)
                * time_elapsed.into()
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

                return ERC20s { steel: _steel, quartz: _quartz, tritium: _tritium, };
            }

            ERC20s { steel: steel_available, quartz: quartz_available, tritium: tritium_available, }
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
        fn receive_resources_erc20(self: @ContractState, to: ContractAddress, amounts: ERC20s) {
            self.steel.read().mint(to, (amounts.steel * E18).into());
            self.quartz.read().mint(to, (amounts.quartz * E18).into());
            self.tritium.read().mint(to, (amounts.tritium * E18).into())
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
            self.tritium.read().burn(account, (amounts.tritium * E18).into())
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

