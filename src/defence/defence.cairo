use nogame::libraries::types::{DefencesCost, ERC20s, DefenceBuildType};

#[starknet::interface]
trait IDefence<TState> {
    fn process_defence_build(ref self: TState, component: DefenceBuildType, quantity: u32);
}

#[starknet::contract]
mod Defence {
    use nogame::component::shared::SharedComponent;
    use nogame::compound::compound::{ICompoundDispatcher, ICompoundDispatcherTrait};
    use nogame::defence::library as defence;
    use nogame::dockyard::library as dockyard;
    use nogame::libraries::types::{DefencesCost, ERC20s, DefenceBuildType, TechLevels, E18, Names};
    use nogame::storage::storage::{IStorageDispatcher, IStorageDispatcherTrait};
    use nogame::token::erc20::interface::{IERC20NoGameDispatcher, IERC20NoGameDispatcherTrait};
    use nogame::token::erc721::interface::{IERC721NoGameDispatcherTrait, IERC721NoGameDispatcher};
    use starknet::{get_caller_address, ContractAddress};

    component!(path: SharedComponent, storage: shared, event: SharedEvent);
    impl SharedImpl = SharedComponent::Shared<ContractState>;
    impl SharedInternalImpl = SharedComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        shared: SharedComponent::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        DefenceSpent: DefenceSpent,
        #[flat]
        SharedEvent: SharedComponent::Event,
    }

    #[derive(Drop, starknet::Event)]
    struct DefenceSpent {
        planet_id: u32,
        quantity: u32,
        spent: ERC20s
    }

    #[abi(embed_v0)]
    impl DefenceImpl of super::IDefence<ContractState> {
        fn process_defence_build(
            ref self: ContractState, component: DefenceBuildType, quantity: u32
        ) {
            let caller = get_caller_address();
            self.shared.collect_resources();
            let planet_id = self.shared.get_owned_planet(caller);
            let dockyard_level = self
                .shared
                .storage
                .read()
                .get_compounds_levels(planet_id)
                .dockyard;
            let techs = self.shared.storage.read().get_tech_levels(planet_id);
            let cost = self
                .build_component(caller, planet_id, dockyard_level, techs, component, quantity);
            self.shared.storage.read().update_planet_points(planet_id, cost);
            self.emit(DefenceSpent { planet_id, quantity, spent: cost })
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
            let is_testnet = self.shared.storage.read().get_is_testnet();
            let techs = self.shared.storage.read().get_tech_levels(planet_id);
            let defences_levels = self.shared.storage.read().get_defences_levels(planet_id);
            match component {
                DefenceBuildType::Celestia => {
                    dockyard::celestia_requirements_check(dockyard_level, techs);
                    let cost = dockyard::get_ships_cost(
                        quantity, dockyard::get_ships_unit_cost().celestia
                    );
                    self.shared.check_enough_resources(caller, cost);
                    self.shared.pay_resources_erc20(caller, cost);
                    self
                        .shared
                        .storage
                        .read()
                        .set_defence_level(
                            planet_id, Names::CELESTIA, defences_levels.celestia + quantity
                        );
                    return cost;
                },
                DefenceBuildType::Blaster => {
                    defence::blaster_requirements_check(dockyard_level, techs);
                    let cost = defence::get_defences_cost(
                        quantity, defence::get_defences_unit_cost().blaster
                    );
                    self.shared.check_enough_resources(caller, cost);
                    self.shared.pay_resources_erc20(caller, cost);
                    self
                        .shared
                        .storage
                        .read()
                        .set_defence_level(
                            planet_id, Names::BLASTER, defences_levels.blaster + quantity
                        );
                    return cost;
                },
                DefenceBuildType::Beam => {
                    defence::beam_requirements_check(dockyard_level, techs);
                    let cost = defence::get_defences_cost(
                        quantity, defence::get_defences_unit_cost().beam
                    );
                    self.shared.check_enough_resources(caller, cost);
                    self.shared.pay_resources_erc20(caller, cost);
                    self
                        .shared
                        .storage
                        .read()
                        .set_defence_level(planet_id, Names::BEAM, defences_levels.beam + quantity);
                    return cost;
                },
                DefenceBuildType::Astral => {
                    assert!(!is_testnet, "NoGame: Astral not available on testnet realease");
                    defence::astral_launcher_requirements_check(dockyard_level, techs);
                    let cost = defence::get_defences_cost(
                        quantity, defence::get_defences_unit_cost().astral
                    );
                    self.shared.check_enough_resources(caller, cost);
                    self.shared.pay_resources_erc20(caller, cost);
                    self
                        .shared
                        .storage
                        .read()
                        .set_defence_level(
                            planet_id, Names::ASTRAL, defences_levels.astral + quantity
                        );
                    return cost;
                },
                DefenceBuildType::Plasma => {
                    assert!(!is_testnet, "NoGame: Plasma Cannon not available on testnet realease");
                    defence::plasma_beam_requirements_check(dockyard_level, techs);
                    let cost = defence::get_defences_cost(
                        quantity, defence::get_defences_unit_cost().plasma
                    );
                    self.shared.check_enough_resources(caller, cost);
                    self.shared.pay_resources_erc20(caller, cost);
                    self
                        .shared
                        .storage
                        .read()
                        .set_defence_level(
                            planet_id, Names::PLASMA, defences_levels.plasma + quantity
                        );
                    return cost;
                },
            }
        }
    }
}
