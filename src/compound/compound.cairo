use nogame::libraries::types::{ERC20s, CompoundUpgradeType};

#[starknet::interface]
trait ICompound<TState> {
    fn process_upgrade(ref self: TState, component: CompoundUpgradeType, quantity: u8);

    fn get_spendable_resources(self: @TState, planet_id: u32) -> ERC20s;
    fn get_collectible_resources(self: @TState, planet_id: u32) -> ERC20s;
}

#[starknet::contract]
mod Compound {
    use nogame::colony::colony::{IColonyDispatcher, IColonyDispatcherTrait};
    use nogame::component::shared::SharedComponent;
    use nogame::compound::library as compound;
    use nogame::libraries::types::{ERC20s, E18, HOUR, CompoundUpgradeType, Names};
    use nogame::storage::storage::{IStorageDispatcher, IStorageDispatcherTrait};
    use nogame::token::erc20::interface::{IERC20NoGameDispatcher, IERC20NoGameDispatcherTrait};
    use nogame::token::erc721::interface::{IERC721NoGameDispatcherTrait, IERC721NoGameDispatcher};
    use openzeppelin::access::ownable::OwnableComponent;
    use starknet::{
        ContractAddress, get_caller_address, get_block_timestamp, contract_address_const
    };

    component!(path: SharedComponent, storage: shared, event: SharedEvent);
    impl SharedInternalImpl = SharedComponent::InternalImpl<ContractState>;

    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;


    #[storage]
    struct Storage {
        #[substorage(v0)]
        shared: SharedComponent::Storage,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        CompoundSpent: CompoundSpent,
        #[flat]
        SharedEvent: SharedComponent::Event,
        #[flat]
        OwnableEvent: OwnableComponent::Event,
    }

    #[derive(Drop, starknet::Event)]
    struct CompoundSpent {
        planet_id: u32,
        quantity: u8,
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
    impl CompoundImpl of super::ICompound<ContractState> {
        fn process_upgrade(ref self: ContractState, component: CompoundUpgradeType, quantity: u8) {
            let caller = get_caller_address();
            self.shared.collect(caller);
            let planet_id = self.shared.get_owned_planet(caller);
            let cost = self.upgrade_component(caller, planet_id, component, quantity);
            self.shared.storage.read().update_planet_points(planet_id, cost);
            self.emit(CompoundSpent { planet_id: planet_id, quantity, spent: cost })
        }

        fn get_spendable_resources(self: @ContractState, planet_id: u32) -> ERC20s {
            let tokens = self.shared.storage.read().get_token_addresses();
            let planet_owner = tokens.erc721.ownerOf(planet_id.into());
            let steel = tokens.steel.balance_of(planet_owner).low / E18;
            let quartz = tokens.quartz.balance_of(planet_owner).low / E18;
            let tritium = tokens.tritium.balance_of(planet_owner).low / E18;
            ERC20s { steel: steel, quartz: quartz, tritium: tritium }
        }

        fn get_collectible_resources(self: @ContractState, planet_id: u32) -> ERC20s {
            self.shared.calculate_production(planet_id)
        }
    }

    #[generate_trait]
    impl Private of PrivateTrait {
        fn upgrade_component(
            ref self: ContractState,
            caller: ContractAddress,
            planet_id: u32,
            component: CompoundUpgradeType,
            quantity: u8
        ) -> ERC20s {
            let compound_levels = self.shared.storage.read().get_compounds_levels(planet_id);
            match component {
                CompoundUpgradeType::SteelMine => {
                    let cost: ERC20s = compound::cost::steel(compound_levels.steel, quantity);
                    self.shared.check_enough_resources(caller, cost);
                    self.shared.pay_resources_erc20(caller, cost);
                    self
                        .shared
                        .storage
                        .read()
                        .set_compound_level(
                            planet_id,
                            Names::STEEL,
                            compound_levels.steel + quantity.try_into().expect('u32 into u8 failed')
                        );
                    return cost;
                },
                CompoundUpgradeType::QuartzMine => {
                    let cost: ERC20s = compound::cost::quartz(compound_levels.quartz, quantity);
                    self.shared.check_enough_resources(caller, cost);
                    self.shared.pay_resources_erc20(caller, cost);
                    self
                        .shared
                        .storage
                        .read()
                        .set_compound_level(
                            planet_id,
                            Names::QUARTZ,
                            compound_levels.quartz
                                + quantity.try_into().expect('u32 into u8 failed')
                        );
                    return cost;
                },
                CompoundUpgradeType::TritiumMine => {
                    let cost: ERC20s = compound::cost::tritium(compound_levels.tritium, quantity);
                    self.shared.check_enough_resources(caller, cost);
                    self.shared.pay_resources_erc20(caller, cost);
                    self
                        .shared
                        .storage
                        .read()
                        .set_compound_level(
                            planet_id,
                            Names::TRITIUM,
                            compound_levels.tritium
                                + quantity.try_into().expect('u32 into u8 failed')
                        );
                    return cost;
                },
                CompoundUpgradeType::EnergyPlant => {
                    let cost: ERC20s = compound::cost::energy(compound_levels.energy, quantity);
                    self.shared.check_enough_resources(caller, cost);
                    self.shared.pay_resources_erc20(caller, cost);
                    self
                        .shared
                        .storage
                        .read()
                        .set_compound_level(
                            planet_id,
                            Names::ENERGY_PLANT,
                            compound_levels.energy
                                + quantity.try_into().expect('u32 into u8 failed')
                        );
                    return cost;
                },
                CompoundUpgradeType::Lab => {
                    let cost: ERC20s = compound::cost::lab(compound_levels.lab, quantity);
                    self.shared.check_enough_resources(caller, cost);
                    self.shared.pay_resources_erc20(caller, cost);
                    self
                        .shared
                        .storage
                        .read()
                        .set_compound_level(
                            planet_id,
                            Names::LAB,
                            compound_levels.lab + quantity.try_into().expect('u32 into u8 failed')
                        );
                    return cost;
                },
                CompoundUpgradeType::Dockyard => {
                    let cost: ERC20s = compound::cost::dockyard(compound_levels.dockyard, quantity);
                    self.shared.check_enough_resources(caller, cost);
                    self.shared.pay_resources_erc20(caller, cost);
                    self
                        .shared
                        .storage
                        .read()
                        .set_compound_level(
                            planet_id,
                            Names::DOCKYARD,
                            compound_levels.dockyard
                                + quantity.try_into().expect('u32 into u8 failed')
                        );
                    return cost;
                },
            }
        }
    }
}
