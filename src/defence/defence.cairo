use nogame::libraries::types::{DefencesCost, ERC20s, DefenceBuildType, Defences};

#[starknet::interface]
trait IDefence<TState> {
    fn process_defence_build(ref self: TState, component: DefenceBuildType, quantity: u32);
    fn get_defences_levels(ref self: TState, planet_id: u32) -> Defences;
}

#[starknet::contract]
mod Defence {
    use nogame::component::shared::SharedComponent;
    use nogame::compound::compound::{ICompoundDispatcher, ICompoundDispatcherTrait};
    use nogame::defence::library as defence;
    use nogame::dockyard::library as dockyard;
    use nogame::libraries::names::Names;
    use nogame::libraries::types::{
        DefencesCost, ERC20s, DefenceBuildType, TechLevels, E18, Defences
    };
    use nogame::storage::storage::{IStorageDispatcher, IStorageDispatcherTrait};
    use nogame::token::erc20::interface::{IERC20NoGameDispatcher, IERC20NoGameDispatcherTrait};
    use nogame::token::erc721::interface::{IERC721NoGameDispatcherTrait, IERC721NoGameDispatcher};
    use openzeppelin::access::ownable::OwnableComponent;
    use starknet::{get_caller_address, ContractAddress, contract_address_const};

    component!(path: SharedComponent, storage: shared, event: SharedEvent);
    impl SharedInternalImpl = SharedComponent::InternalImpl<ContractState>;

    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        defence_level: LegacyMap::<(u32, u8), u32>,
        compounds: ICompoundDispatcher,
        #[substorage(v0)]
        shared: SharedComponent::Storage,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        DefenceSpent: DefenceSpent,
        #[flat]
        SharedEvent: SharedComponent::Event,
        #[flat]
        OwnableEvent: OwnableComponent::Event,
    }

    #[derive(Drop, starknet::Event)]
    struct DefenceSpent {
        planet_id: u32,
        quantity: u32,
        spent: ERC20s
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        owner: ContractAddress,
        storage: ContractAddress,
        colony: ContractAddress
    ) {
        self.ownable.initializer(owner);
        self.shared.initializer(storage, colony);
    }

    #[abi(embed_v0)]
    impl DefenceImpl of super::IDefence<ContractState> {
        fn process_defence_build(
            ref self: ContractState, component: DefenceBuildType, quantity: u32
        ) {
            let caller = get_caller_address();
            self.shared.collect_resources();
            let planet_id = self.shared.get_owned_planet(caller);
            let dockyard_level = self.compounds.read().get_compounds_levels(planet_id).dockyard;
            let techs = self.shared.storage.read().get_tech_levels(planet_id);
            let cost = self
                .build_component(caller, planet_id, dockyard_level, techs, component, quantity);
            self.shared.storage.read().update_planet_points(planet_id, cost);
            self.emit(DefenceSpent { planet_id, quantity, spent: cost })
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
            quantity: u32
        ) -> ERC20s {
            let techs = self.shared.storage.read().get_tech_levels(planet_id);
            let defences_levels = self.get_defences_levels(planet_id);
            match component {
                DefenceBuildType::Celestia => {
                    defence::requirements::celestia(dockyard_level, techs);
                    let cost = dockyard::get_ships_cost(
                        quantity, defence::get_defences_unit_cost().celestia
                    );
                    self.shared.check_enough_resources(caller, cost);
                    self.shared.pay_resources_erc20(caller, cost);
                    self
                        .defence_level
                        .write(
                            (planet_id, Names::Defence::CELESTIA),
                            defences_levels.celestia + quantity
                        );
                    return cost;
                },
                DefenceBuildType::Blaster => {
                    defence::requirements::blaster(dockyard_level, techs);
                    let cost = dockyard::get_ships_cost(
                        quantity, defence::get_defences_unit_cost().blaster
                    );
                    self.shared.check_enough_resources(caller, cost);
                    self.shared.pay_resources_erc20(caller, cost);
                    self
                        .defence_level
                        .write(
                            (planet_id, Names::Defence::BLASTER), defences_levels.blaster + quantity
                        );
                    return cost;
                },
                DefenceBuildType::Beam => {
                    defence::requirements::beam(dockyard_level, techs);
                    let cost = dockyard::get_ships_cost(
                        quantity, defence::get_defences_unit_cost().beam
                    );
                    self.shared.check_enough_resources(caller, cost);
                    self.shared.pay_resources_erc20(caller, cost);
                    self
                        .defence_level
                        .write((planet_id, Names::Defence::BEAM), defences_levels.beam + quantity);
                    return cost;
                },
                DefenceBuildType::Astral => {
                    defence::requirements::astral(dockyard_level, techs);
                    let cost = dockyard::get_ships_cost(
                        quantity, defence::get_defences_unit_cost().astral
                    );
                    self.shared.check_enough_resources(caller, cost);
                    self.shared.pay_resources_erc20(caller, cost);
                    self
                        .defence_level
                        .write(
                            (planet_id, Names::Defence::ASTRAL), defences_levels.astral + quantity
                        );
                    return cost;
                },
                DefenceBuildType::Plasma => {
                    defence::requirements::plasma(dockyard_level, techs);
                    let cost = dockyard::get_ships_cost(
                        quantity, defence::get_defences_unit_cost().plasma
                    );
                    self.shared.check_enough_resources(caller, cost);
                    self.shared.pay_resources_erc20(caller, cost);
                    self
                        .defence_level
                        .write(
                            (planet_id, Names::Defence::PLASMA), defences_levels.plasma + quantity
                        );
                    return cost;
                },
            }
        }
    }
}
