use nogame::libraries::types::{ShipBuildType, ShipsCost};

#[starknet::interface]
trait IDockyard<TState> {
    fn process_ship_build(ref self: TState, component: ShipBuildType, quantity: u32);
}

#[starknet::contract]
mod Dockyard {
    use nogame::component::shared::SharedComponent;
    use nogame::compound::compound::{ICompoundDispatcher, ICompoundDispatcherTrait};
    use nogame::dockyard::library as dockyard;
    use nogame::libraries::types::{ShipBuildType, ERC20s, TechLevels, E18, ShipsCost, Names};
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
        compounds: ICompoundDispatcher,
        #[substorage(v0)]
        shared: SharedComponent::Storage,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        FleetSpent: FleetSpent,
        #[flat]
        SharedEvent: SharedComponent::Event,
        #[flat]
        OwnableEvent: OwnableComponent::Event,
    }

    #[derive(Drop, starknet::Event)]
    struct FleetSpent {
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
    impl DockyardImpl of super::IDockyard<ContractState> {
        fn process_ship_build(ref self: ContractState, component: ShipBuildType, quantity: u32) {
            let caller = get_caller_address();
            self.shared.collect_resources();
            let planet_id = self.shared.get_owned_planet(caller);
            let dockyard_level = self.compounds.read().get_compounds_levels(planet_id).dockyard;
            let techs = self.shared.storage.read().get_tech_levels(planet_id);
            let cost = self
                .build_component(caller, planet_id, dockyard_level, techs, component, quantity);
            self.shared.storage.read().update_planet_points(planet_id, cost);
            self.emit(FleetSpent { planet_id, quantity, spent: cost })
        }
    }

    #[generate_trait]
    impl Private of PrivateTrait {
        fn build_component(
            ref self: ContractState,
            caller: ContractAddress,
            planet_id: u32,
            dockyard_level: u8,
            techs: TechLevels,
            component: ShipBuildType,
            quantity: u32
        ) -> ERC20s {
            let is_testnet = self.shared.storage.read().get_is_testnet();
            let techs = self.shared.storage.read().get_tech_levels(planet_id);
            let ships_levels = self.shared.storage.read().get_ships_levels(planet_id);
            match component {
                ShipBuildType::Carrier => {
                    dockyard::requirements::carrier(dockyard_level, techs);
                    let cost = dockyard::get_ships_cost(
                        quantity, dockyard::get_ships_unit_cost().carrier
                    );
                    self.shared.check_enough_resources(caller, cost);
                    self.shared.pay_resources_erc20(caller, cost);
                    self
                        .shared
                        .storage
                        .read()
                        .set_ship_level(planet_id, Names::CARRIER, ships_levels.carrier + quantity);
                    return cost;
                },
                ShipBuildType::Scraper => {
                    dockyard::requirements::scraper(dockyard_level, techs);
                    let cost = dockyard::get_ships_cost(
                        quantity, dockyard::get_ships_unit_cost().scraper
                    );
                    self.shared.check_enough_resources(caller, cost);
                    self.shared.pay_resources_erc20(caller, cost);
                    self
                        .shared
                        .storage
                        .read()
                        .set_ship_level(planet_id, Names::SCRAPER, ships_levels.scraper + quantity);
                    return cost;
                },
                ShipBuildType::Sparrow => {
                    dockyard::requirements::sparrow(dockyard_level, techs);
                    let cost = dockyard::get_ships_cost(
                        quantity, dockyard::get_ships_unit_cost().sparrow
                    );
                    self.shared.check_enough_resources(caller, cost);
                    self.shared.pay_resources_erc20(caller, cost);
                    self
                        .shared
                        .storage
                        .read()
                        .set_ship_level(planet_id, Names::SPARROW, ships_levels.sparrow + quantity);
                    return cost;
                },
                ShipBuildType::Frigate => {
                    assert!(!is_testnet, "NoGame: Frigate not available on testnet realease");
                    dockyard::requirements::frigate(dockyard_level, techs);
                    let cost = dockyard::get_ships_cost(
                        quantity, dockyard::get_ships_unit_cost().frigate
                    );
                    self.shared.check_enough_resources(caller, cost);
                    self.shared.pay_resources_erc20(caller, cost);
                    self
                        .shared
                        .storage
                        .read()
                        .set_ship_level(planet_id, Names::FRIGATE, ships_levels.frigate + quantity);
                    return cost;
                },
                ShipBuildType::Armade => {
                    assert!(!is_testnet, "NoGame: Armade not available on testnet realease");
                    dockyard::requirements::armade(dockyard_level, techs);
                    let cost = dockyard::get_ships_cost(
                        quantity, dockyard::get_ships_unit_cost().armade
                    );
                    self.shared.check_enough_resources(caller, cost);
                    self.shared.pay_resources_erc20(caller, cost);
                    self
                        .shared
                        .storage
                        .read()
                        .set_ship_level(planet_id, Names::ARMADE, ships_levels.armade + quantity);
                    return cost;
                },
            }
        }
    }
}
