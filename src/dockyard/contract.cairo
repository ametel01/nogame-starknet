use nogame::libraries::types::{ShipBuildType, ShipsLevels};

#[starknet::interface]
trait IDockyard<TState> {
    fn process_ship_build(ref self: TState, component: ShipBuildType, quantity: u32);
    fn set_ship_levels(ref self: TState, planet_id: u32, name: u8, level: u32);
    fn get_ships_levels(ref self: TState, planet_id: u32) -> ShipsLevels;
}

#[starknet::contract]
mod Dockyard {
    use nogame::compound::contract::ICompoundDispatcherTrait;
    use nogame::dockyard::library as dockyard;
    use nogame::game::contract::{IGameDispatcher, IGameDispatcherTrait};
    use nogame::libraries::names::Names;
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
            let contracts = self.game_manager.read().get_contracts();
            contracts.planet.collect_resources(caller);
            let planet_id = contracts.planet.get_owned_planet(caller);

            let dockyard_level = contracts.compound.get_compounds_levels(planet_id).dockyard;
            let techs = contracts.tech.get_tech_levels(planet_id);
            let cost = self
                .build_component(caller, planet_id, dockyard_level, techs, component, quantity);
            contracts.planet.update_planet_points(planet_id, cost, false);
            self.emit(FleetSpent { planet_id, quantity, spent: cost })
        }

        fn set_ship_levels(ref self: ContractState, planet_id: u32, name: u8, level: u32) {
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
        fn build_component(
            ref self: ContractState,
            caller: ContractAddress,
            planet_id: u32,
            dockyard_level: u8,
            techs: TechLevels,
            component: ShipBuildType,
            quantity: u32,
        ) -> ERC20s {
            let contracts = self.game_manager.read().get_contracts();
            let dockyard_level = contracts.compound.get_compounds_levels(planet_id).dockyard;
            let techs = contracts.tech.get_tech_levels(planet_id);
            let ships_levels = self.get_ships_levels(planet_id);
            let mut cost: ERC20s = Default::default();
            let game_manager = self.game_manager.read();
            match component {
                ShipBuildType::Carrier => {
                    dockyard::requirements::carrier(dockyard_level, techs);
                    cost =
                        dockyard::get_ships_cost(quantity, dockyard::get_ships_unit_cost().carrier);
                    game_manager.check_enough_resources(caller, cost);
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
            game_manager.pay_resources_erc20(caller, cost);
            cost
        }
    }
}
