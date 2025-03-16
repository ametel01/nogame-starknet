use nogame::libraries::types::{DefenceBuildType, Defences, DefencesCost, ERC20s};

#[starknet::interface]
trait IDefence<TState> {
    fn process_defence_build(ref self: TState, component: DefenceBuildType, quantity: u32);
    fn set_defence_level(ref self: TState, planet_id: u32, name: u8, level: u32);
    fn get_defences_levels(ref self: TState, planet_id: u32) -> Defences;
}

#[starknet::contract]
mod Defence {
    use nogame::compound::contract::{ICompoundDispatcher, ICompoundDispatcherTrait};
    use nogame::defence::library as defence;
    use nogame::dockyard::library as dockyard;
    use nogame::game::contract::{IGameDispatcher, IGameDispatcherTrait};
    use nogame::libraries::names::Names;
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
            let game_manager = self.game_manager.read();
            let contracts = game_manager.get_contracts();
            contracts.planet.collect_resources(caller);
            let planet_id = contracts.planet.get_owned_planet(caller);
            println!("planet_id: {}", planet_id);
            let dockyard_level = contracts.compound.get_compounds_levels(planet_id).dockyard;
            println!("dockyard_level: {}", dockyard_level);
            let techs = contracts.tech.get_tech_levels(planet_id);
            println!("techs: {:?}", techs);
            let cost = self
                .build_component(caller, planet_id, dockyard_level, techs, component, quantity);
            contracts.planet.update_planet_points(planet_id, cost, false);
            self.emit(DefenceSpent { planet_id, quantity, spent: cost })
        }

        fn set_defence_level(ref self: ContractState, planet_id: u32, name: u8, level: u32) {
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
        fn build_component(
            ref self: ContractState,
            caller: ContractAddress,
            planet_id: u32,
            dockyard_level: u8,
            techs: TechLevels,
            component: DefenceBuildType,
            quantity: u32,
        ) -> ERC20s {
            let contracts = self.game_manager.read().get_contracts();
            let techs = contracts.tech.get_tech_levels(planet_id);
            let defences_levels = self.get_defences_levels(planet_id);
            let mut cost: ERC20s = Default::default();
            match component {
                DefenceBuildType::Celestia => {
                    defence::requirements::celestia(dockyard_level, techs);
                    cost =
                        dockyard::get_ships_cost(
                            quantity, defence::get_defences_unit_cost().celestia,
                        );
                    contracts.game.check_enough_resources(caller, cost);
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
                    contracts.game.check_enough_resources(caller, cost);
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
                    contracts.game.check_enough_resources(caller, cost);
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
                    contracts.game.check_enough_resources(caller, cost);
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
                    contracts.game.check_enough_resources(caller, cost);
                    self
                        .defence_level
                        .write(
                            (planet_id, Names::Defence::PLASMA), defences_levels.plasma + quantity,
                        );
                },
            }
            contracts.game.pay_resources_erc20(caller, cost);
            cost
        }
    }
}
