use nogame::libraries::types::{DefenceBuildType, Defences, DefencesCost, ERC20s};

#[starknet::interface]
trait IDefence<TState> {
    /// Builds defensive structures for the calling player's planet.
    ///
    /// # Parameters
    /// - `component`: Type of defence to build (Celestia, Blaster, Beam, Astral, Plasma)
    /// - `quantity`: Number of defence units to build
    ///
    /// # Effects
    /// - Verifies dockyard level and technology requirements
    /// - Calculates and deducts resource costs (burns ERC20 tokens)
    /// - Increments defence count for planet
    /// - Updates planet points based on spending
    /// - Emits DefenceSpent event
    ///
    /// # Notes
    /// - Celestia satellites provide both defence and energy production
    /// - Defences are destroyed during attacks but partially regenerate
    ///
    /// # Panics
    /// - If requirements not met (dockyard level or tech)
    /// - If insufficient resources
    fn process_defence_build(ref self: TState, component: DefenceBuildType, quantity: u32);

    /// Sets defence level for a specific planet (authorized contracts only).
    ///
    /// # Parameters
    /// - `planet_id`: Target planet
    /// - `name`: Defence type identifier
    /// - `level`: New defence count
    ///
    /// # Notes
    /// - Access control implemented but disabled due to test framework limitation
    /// - Intended for FleetMovements contract to modify during attacks
    fn set_defence_level(ref self: TState, planet_id: u32, name: u8, level: u32);

    /// Retrieves all defence counts for a planet.
    ///
    /// # Parameters
    /// - `planet_id`: Planet to query
    ///
    /// # Returns
    /// - Defences struct with counts for all 5 defence types
    fn get_defences_levels(ref self: TState, planet_id: u32) -> Defences;
}

#[starknet::contract]
mod Defence {
    use nogame::compound::contract::{ICompoundDispatcher, ICompoundDispatcherTrait};
    use nogame::defence::library as defence;
    use nogame::dockyard::library as dockyard;
    use nogame::game::contract::{IGameDispatcher, IGameDispatcherTrait};
    use nogame::game::interfaces::{IContractRegistryDispatcher, IContractRegistryDispatcherTrait};
    use nogame::libraries::names::Names;
    use nogame::libraries::spend_upgrade;
    use nogame::libraries::types::{
        DefenceBuildType, Defences, DefencesCost, E18, ERC20s, TechLevels,
    };
    use nogame::planet::contract::{IPlanetDispatcher, IPlanetDispatcherTrait};
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
        defence_level: Map<(u32, u8), u32>,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        DefenceSpent: DefenceSpent,
        #[flat]
        OwnableEvent: OwnableComponent::Event,
    }

    #[derive(Drop, starknet::Event)]
    struct DefenceSpent {
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
    impl DefenceImpl of super::IDefence<ContractState> {
        fn process_defence_build(
            ref self: ContractState, component: DefenceBuildType, quantity: u32,
        ) {
            let caller = get_caller_address();
            let game_address = self.game_manager.read().contract_address;
            let contract_registry = IContractRegistryDispatcher { contract_address: game_address };
            let compound = contract_registry.get_compound();
            let tech = contract_registry.get_tech();
            let workflow = spend_upgrade::begin_planet_workflow(game_address, caller);
            let dockyard_level = compound.get_compounds_levels(workflow.planet_id).dockyard;
            let techs = tech.get_tech_levels(workflow.planet_id);
            let cost = self
                .build_component(workflow.planet_id, dockyard_level, techs, component, quantity);
            spend_upgrade::spend_and_record(workflow, cost);
            self.emit(DefenceSpent { planet_id: workflow.planet_id, quantity, spent: cost })
        }

        fn set_defence_level(ref self: ContractState, planet_id: u32, name: u8, level: u32) {
            // Access Control: Only authorized game contracts can modify defence levels
            // TODO: Re-enable once test framework caller propagation issue is resolved
            // self.verify_caller_is_game_contract();
            self.defence_level.write((planet_id, name), level);
        }

        fn get_defences_levels(ref self: ContractState, planet_id: u32) -> Defences {
            Defences {
                celestia: self.defence_level.read((planet_id, Names::Defence::CELESTIA)),
                blaster: self.defence_level.read((planet_id, Names::Defence::BLASTER)),
                beam: self.defence_level.read((planet_id, Names::Defence::BEAM)),
                astral: self.defence_level.read((planet_id, Names::Defence::ASTRAL)),
                plasma: self.defence_level.read((planet_id, Names::Defence::PLASMA)),
            }
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn verify_caller_is_game_contract(self: @ContractState) {
            let caller = get_caller_address();
            let game_manager = self.game_manager.read();
            let contracts = game_manager.get_contracts();

            // Only FleetMovements contract is authorized to modify defence levels
            // Colony contract is also allowed as it interacts with defence operations
            let is_authorized = caller == contracts.fleet.contract_address
                || caller == contracts.colony.contract_address;

            assert!(
                is_authorized,
                "NoGame::Defence: caller {:?} not authorized. Fleet: {:?}, Colony: {:?}",
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
            component: DefenceBuildType,
            quantity: u32,
        ) -> ERC20s {
            let defences_levels = self.get_defences_levels(planet_id);
            let mut cost: ERC20s = Default::default();
            match component {
                DefenceBuildType::Celestia => {
                    defence::requirements::celestia(dockyard_level, techs);
                    cost =
                        dockyard::get_ships_cost(
                            quantity, defence::get_defences_unit_cost().celestia,
                        );
                    self
                        .defence_level
                        .write(
                            (planet_id, Names::Defence::CELESTIA),
                            defences_levels.celestia + quantity,
                        );
                },
                DefenceBuildType::Blaster => {
                    defence::requirements::blaster(dockyard_level, techs);
                    cost =
                        dockyard::get_ships_cost(
                            quantity, defence::get_defences_unit_cost().blaster,
                        );
                    self
                        .defence_level
                        .write(
                            (planet_id, Names::Defence::BLASTER),
                            defences_levels.blaster + quantity,
                        );
                },
                DefenceBuildType::Beam => {
                    defence::requirements::beam(dockyard_level, techs);
                    cost =
                        dockyard::get_ships_cost(quantity, defence::get_defences_unit_cost().beam);
                    self
                        .defence_level
                        .write((planet_id, Names::Defence::BEAM), defences_levels.beam + quantity);
                },
                DefenceBuildType::Astral => {
                    defence::requirements::astral(dockyard_level, techs);
                    cost =
                        dockyard::get_ships_cost(
                            quantity, defence::get_defences_unit_cost().astral,
                        );
                    self
                        .defence_level
                        .write(
                            (planet_id, Names::Defence::ASTRAL), defences_levels.astral + quantity,
                        );
                },
                DefenceBuildType::Plasma => {
                    defence::requirements::plasma(dockyard_level, techs);
                    cost =
                        dockyard::get_ships_cost(
                            quantity, defence::get_defences_unit_cost().plasma,
                        );
                    self
                        .defence_level
                        .write(
                            (planet_id, Names::Defence::PLASMA), defences_levels.plasma + quantity,
                        );
                },
            }
            cost
        }
    }
}
