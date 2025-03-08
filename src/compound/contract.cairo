use nogame::libraries::types::{CompoundUpgradeType, CompoundsLevels, ERC20s};
use starknet::ClassHash;

#[starknet::interface]
trait ICompound<TState> {
    fn upgrade(ref self: TState, impl_hash: ClassHash);
    fn process_upgrade(ref self: TState, component: CompoundUpgradeType, quantity: u8);
    fn get_compounds_levels(self: @TState, planet_id: u32) -> CompoundsLevels;
}

#[starknet::contract]
mod Compound {
    use nogame::colony::contract::{IColonyDispatcher, IColonyDispatcherTrait};
    use nogame::compound::library as compound;
    use nogame::game::contract::{IGameDispatcher, IGameDispatcherTrait};
    use nogame::libraries::names::Names;
    use nogame::libraries::types::{CompoundUpgradeType, CompoundsLevels, E18, ERC20s, HOUR};
    use nogame::planet::contract::{IPlanetDispatcher, IPlanetDispatcherTrait};
    use nogame::token::erc20::interface::{IERC20NoGameDispatcher, IERC20NoGameDispatcherTrait};
    use nogame::token::erc721::interface::{IERC721NoGameDispatcher, IERC721NoGameDispatcherTrait};
    use openzeppelin_access::ownable::OwnableComponent;
    use openzeppelin_upgrades::upgradeable::UpgradeableComponent;
    use starknet::storage::{
        Map, StoragePathEntry, StoragePointerReadAccess, StoragePointerWriteAccess,
    };
    use starknet::{ClassHash, ContractAddress, get_block_timestamp, get_caller_address};


    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    component!(path: UpgradeableComponent, storage: upgradeable, event: UpgradeableEvent);
    impl UpgradableInteralImpl = UpgradeableComponent::InternalImpl<ContractState>;


    #[storage]
    struct Storage {
        game_manager: IGameDispatcher,
        compound_level: Map<(u32, u8), u8>,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        #[substorage(v0)]
        upgradeable: UpgradeableComponent::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        CompoundSpent: CompoundSpent,
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        #[flat]
        UpgradeableEvent: UpgradeableComponent::Event,
    }

    #[derive(Drop, starknet::Event)]
    struct CompoundSpent {
        planet_id: u32,
        quantity: u8,
        spent: ERC20s,
    }

    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress, game: ContractAddress) {
        self.ownable.initializer(owner);
        self.game_manager.write(IGameDispatcher { contract_address: game });
    }

    #[abi(embed_v0)]
    impl CompoundImpl of super::ICompound<ContractState> {
        fn upgrade(ref self: ContractState, impl_hash: ClassHash) {
            self.ownable.assert_only_owner();
            self.upgradeable.upgrade(impl_hash);
        }

        fn process_upgrade(ref self: ContractState, component: CompoundUpgradeType, quantity: u8) {
            let caller = get_caller_address();
            let contracts = self.game_manager.read().get_contracts();
            contracts.planet.collect_resources(caller);
            let planet_id = contracts.planet.get_owned_planet(caller);
            let cost = self.upgrade_component(caller, planet_id, component, quantity);
            contracts.planet.update_planet_points(planet_id, cost, false);
            self.emit(CompoundSpent { planet_id: planet_id, quantity, spent: cost })
        }

        fn get_compounds_levels(self: @ContractState, planet_id: u32) -> CompoundsLevels {
            CompoundsLevels {
                steel: self.compound_level.read((planet_id, Names::Compound::STEEL)),
                quartz: self.compound_level.read((planet_id, Names::Compound::QUARTZ)),
                tritium: self.compound_level.read((planet_id, Names::Compound::TRITIUM)),
                energy: self.compound_level.read((planet_id, Names::Compound::ENERGY)),
                lab: self.compound_level.read((planet_id, Names::Compound::LAB)),
                dockyard: self.compound_level.read((planet_id, Names::Compound::DOCKYARD)),
            }
        }
    }

    #[generate_trait]
    impl Private of PrivateTrait {
        fn upgrade_component(
            ref self: ContractState,
            caller: ContractAddress,
            planet_id: u32,
            component: CompoundUpgradeType,
            quantity: u8,
        ) -> ERC20s {
            let compound_levels = self.get_compounds_levels(planet_id);
            let mut cost: ERC20s = Default::default();
            let game_manager = self.game_manager.read();
            match component {
                CompoundUpgradeType::SteelMine => {
                    cost = compound::cost::steel(compound_levels.steel, quantity);
                    game_manager.check_enough_resources(caller, cost);
                    self
                        .compound_level
                        .write(
                            (planet_id, Names::Compound::STEEL),
                            compound_levels.steel
                                + quantity.try_into().expect('u32 into u8 failed'),
                        );
                },
                CompoundUpgradeType::QuartzMine => {
                    cost = compound::cost::quartz(compound_levels.quartz, quantity);
                    game_manager.check_enough_resources(caller, cost);
                    self
                        .compound_level
                        .write(
                            (planet_id, Names::Compound::QUARTZ),
                            compound_levels.quartz
                                + quantity.try_into().expect('u32 into u8 failed'),
                        );
                },
                CompoundUpgradeType::TritiumMine => {
                    cost = compound::cost::tritium(compound_levels.tritium, quantity);
                    game_manager.check_enough_resources(caller, cost);
                    self
                        .compound_level
                        .write(
                            (planet_id, Names::Compound::TRITIUM),
                            compound_levels.tritium
                                + quantity.try_into().expect('u32 into u8 failed'),
                        );
                },
                CompoundUpgradeType::EnergyPlant => {
                    cost = compound::cost::energy(compound_levels.energy, quantity);
                    game_manager.check_enough_resources(caller, cost);
                    self
                        .compound_level
                        .write(
                            (planet_id, Names::Compound::ENERGY),
                            compound_levels.energy
                                + quantity.try_into().expect('u32 into u8 failed'),
                        );
                },
                CompoundUpgradeType::Lab => {
                    cost = compound::cost::lab(compound_levels.lab, quantity);
                    game_manager.check_enough_resources(caller, cost);
                    self
                        .compound_level
                        .write(
                            (planet_id, Names::Compound::LAB),
                            compound_levels.lab + quantity.try_into().expect('u32 into u8 failed'),
                        );
                },
                CompoundUpgradeType::Dockyard => {
                    cost = compound::cost::dockyard(compound_levels.dockyard, quantity);
                    game_manager.check_enough_resources(caller, cost);
                    self
                        .compound_level
                        .write(
                            (planet_id, Names::Compound::DOCKYARD),
                            compound_levels.dockyard
                                + quantity.try_into().expect('u32 into u8 failed'),
                        );
                },
            }
            game_manager.pay_resources_erc20(caller, cost);
            cost
        }
    }
}
