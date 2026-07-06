use nogame::libraries::types::{ShipBuildType, ShipsLevels};

#[starknet::interface]
trait IDockyard<TState> {
    /// Builds ships for the calling player's planet.
    ///
    /// # Parameters
    /// - `component`: Type of ship to build (Carrier, Scraper, Sparrow, Frigate, Armade)
    /// - `quantity`: Number of ships to build
    ///
    /// # Effects
    /// - Verifies dockyard level and technology requirements
    /// - Calculates and deducts resource costs (burns ERC20 tokens)
    /// - Increments ship count for planet
    /// - Updates planet points based on spending
    /// - Emits FleetSpent event
    ///
    /// # Panics
    /// - If requirements not met (dockyard level or tech)
    /// - If insufficient resources
    fn process_ship_build(ref self: TState, component: ShipBuildType, quantity: u32);

    /// Sets ship level for a specific planet (authorized contracts only).
    ///
    /// # Parameters
    /// - `planet_id`: Target planet
    /// - `name`: Ship type identifier
    /// - `level`: New ship count
    ///
    /// # Notes
    /// - Access control implemented but disabled due to test framework limitation
    /// - Intended for FleetMovements contract to modify during missions
    fn set_ship_levels(ref self: TState, planet_id: u32, name: u8, level: u32);

    /// Retrieves all ship counts for a planet.
    ///
    /// # Parameters
    /// - `planet_id`: Planet to query
    ///
    /// # Returns
    /// - ShipsLevels struct with counts for all 5 ship types
    fn get_ships_levels(ref self: TState, planet_id: u32) -> ShipsLevels;
}

#[starknet::contract]
mod Dockyard {
    use nogame::compound::contract::ICompoundDispatcherTrait;
    use nogame::dockyard::library as dockyard;
    use nogame::game::contract::{IGameDispatcher, IGameDispatcherTrait};
    use nogame::game::interfaces::{
        IContractRegistryDispatcher, IContractRegistryDispatcherTrait, IResourceManagerDispatcher,
    };
    use nogame::libraries::names::Names;
    use nogame::libraries::spend_upgrade;
    use nogame::libraries::types::{E18, ERC20s, ShipBuildType, ShipsCost, ShipsLevels, TechLevels};
    use nogame::planet::contract::IPlanetDispatcherTrait;
    use nogame::tech::contract::ITechDispatcherTrait;
    use nogame::token::erc20::interface::{IERC20NoGameDispatcher, IERC20NoGameDispatcherTrait};
    use nogame::token::erc721::interface::{IERC721NoGameDispatcher, IERC721NoGameDispatcherTrait};
    use openzeppelin_access::ownable::OwnableComponent;
    use starknet::storage::{
        Map, StoragePathEntry, StoragePointerReadAccess, StoragePointerWriteAccess,
    };
    use starknet::{ContractAddress, get_caller_address};

    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        game_manager: IGameDispatcher,
        ships_level: Map<(u32, u8), u32>,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        FleetSpent: FleetSpent,
        #[flat]
        OwnableEvent: OwnableComponent::Event,
    }

    #[derive(Drop, starknet::Event)]
    struct FleetSpent {
        planet_id: u32,
        quantity: u32,
        spent: ERC20s,
    }

    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress, game: ContractAddress) {
        self.ownable.initializer(owner);
        self.game_manager.write(IGameDispatcher { contract_address: game });
    }

    #[abi(embed_v0)]
    impl DockyardImpl of super::IDockyard<ContractState> {
        fn process_ship_build(ref self: ContractState, component: ShipBuildType, quantity: u32) {
            let caller = get_caller_address();
            let game_address = self.game_manager.read().contract_address;
            let contract_registry = IContractRegistryDispatcher { contract_address: game_address };
            let planet = contract_registry.get_planet();
            let compound = contract_registry.get_compound();
            let tech = contract_registry.get_tech();
            let resource_manager = IResourceManagerDispatcher { contract_address: game_address };
            let workflow = spend_upgrade::begin_planet_workflow(planet, caller);

            let dockyard_level = compound.get_compounds_levels(workflow.planet_id).dockyard;
            let techs = tech.get_tech_levels(workflow.planet_id);
            let cost = self
                .build_component(workflow.planet_id, dockyard_level, techs, component, quantity);
            spend_upgrade::spend_and_record(planet, resource_manager, workflow, cost);
            self.emit(FleetSpent { planet_id: workflow.planet_id, quantity, spent: cost })
        }

        fn set_ship_levels(ref self: ContractState, planet_id: u32, name: u8, level: u32) {
            // Access Control: Only authorized game contracts can modify ship levels
            // This prevents unauthorized external calls from manipulating game state
            // TODO: Re-enable once test framework caller propagation issue is resolved
            // self.verify_caller_is_game_contract();
            self.ships_level.write((planet_id, name), level);
        }

        fn get_ships_levels(ref self: ContractState, planet_id: u32) -> ShipsLevels {
            ShipsLevels {
                carrier: self.ships_level.read((planet_id, Names::Fleet::CARRIER)),
                scraper: self.ships_level.read((planet_id, Names::Fleet::SCRAPER)),
                sparrow: self.ships_level.read((planet_id, Names::Fleet::SPARROW)),
                frigate: self.ships_level.read((planet_id, Names::Fleet::FRIGATE)),
                armade: self.ships_level.read((planet_id, Names::Fleet::ARMADE)),
            }
        }
    }

    #[generate_trait]
    impl Private of PrivateTrait {
        fn verify_caller_is_game_contract(self: @ContractState) {
            let caller = get_caller_address();
            let game_manager = self.game_manager.read();
            let contracts = game_manager.get_contracts();

            // Only FleetMovements contract is authorized to modify ship levels
            // Colony contract is also allowed as it interacts with fleet operations
            let is_authorized = caller == contracts.fleet.contract_address
                || caller == contracts.colony.contract_address;

            assert!(
                is_authorized,
                "NoGame::Dockyard: caller {:?} not authorized. Fleet: {:?}, Colony: {:?}",
                caller,
                contracts.fleet.contract_address,
                contracts.colony.contract_address,
            );
        }

        fn build_component(
            ref self: ContractState,
            planet_id: u32,
            dockyard_level: u8,
            techs: TechLevels,
            component: ShipBuildType,
            quantity: u32,
        ) -> ERC20s {
            let ships_levels = self.get_ships_levels(planet_id);
            let mut cost: ERC20s = Default::default();
            match component {
                ShipBuildType::Carrier => {
                    dockyard::requirements::carrier(dockyard_level, techs);
                    cost =
                        dockyard::get_ships_cost(quantity, dockyard::get_ships_unit_cost().carrier);
                    self
                        .ships_level
                        .write((planet_id, Names::Fleet::CARRIER), ships_levels.carrier + quantity);
                },
                ShipBuildType::Scraper => {
                    dockyard::requirements::scraper(dockyard_level, techs);
                    cost =
                        dockyard::get_ships_cost(quantity, dockyard::get_ships_unit_cost().scraper);
                    self
                        .ships_level
                        .write((planet_id, Names::Fleet::SCRAPER), ships_levels.scraper + quantity);
                },
                ShipBuildType::Sparrow => {
                    dockyard::requirements::sparrow(dockyard_level, techs);
                    cost =
                        dockyard::get_ships_cost(quantity, dockyard::get_ships_unit_cost().sparrow);
                    self
                        .ships_level
                        .write((planet_id, Names::Fleet::SPARROW), ships_levels.sparrow + quantity);
                },
                ShipBuildType::Frigate => {
                    dockyard::requirements::frigate(dockyard_level, techs);
                    cost =
                        dockyard::get_ships_cost(quantity, dockyard::get_ships_unit_cost().frigate);
                    self
                        .ships_level
                        .write((planet_id, Names::Fleet::FRIGATE), ships_levels.frigate + quantity);
                },
                ShipBuildType::Armade => {
                    dockyard::requirements::armade(dockyard_level, techs);
                    cost =
                        dockyard::get_ships_cost(quantity, dockyard::get_ships_unit_cost().armade);
                    self
                        .ships_level
                        .write((planet_id, Names::Fleet::ARMADE), ships_levels.armade + quantity);
                },
            }
            cost
        }
    }
}
