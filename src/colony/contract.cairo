use nogame::libraries::types::{
    ColonyBuildType, ColonyUpgradeType, CompoundsLevels, Defences, ERC20s, Fleet, PlanetPosition,
    ShipsLevels, TechLevels,
};

#[starknet::interface]
trait IColony<TState> {
    /// Generates a new colony for the calling player's planet.
    ///
    /// # Effects
    /// - Requires Exocraft technology (max colonies = exocraft_level / 2)
    /// - Assigns predetermined position in universe
    /// - Creates colony ID: (planet_id * 1000) + colony_number
    /// - Initializes resource timer
    /// - Registers colony in Planet contract position mapping
    /// - Emits PlanetGenerated event
    ///
    /// # Panics
    /// - If max colonies already reached
    /// - If payment required and insufficient ETH
    fn generate_colony(ref self: TState);

    /// Collects accumulated resources from a colony.
    ///
    /// # Parameters
    /// - `colony_id`: Colony to collect from (1-based index)
    ///
    /// # Returns
    /// - ERC20s with collected steel, quartz, tritium amounts
    ///
    /// # Effects
    /// - Calculates production since last collection
    /// - Resets resource timer
    /// - Does NOT mint tokens (handled by Planet contract)
    ///
    /// # Panics
    /// - If colony doesn't exist
    fn collect_resources(ref self: TState, colony_id: u8) -> ERC20s;

    /// Collects accumulated resources from an explicit planet colony.
    ///
    /// # Parameters
    /// - `planet_id`: Mother planet ID
    /// - `colony_id`: Colony number
    ///
    /// # Notes
    /// - Authorized contracts only
    /// - Does NOT derive ownership from the immediate caller
    fn collect_resources_for_planet(ref self: TState, planet_id: u32, colony_id: u8) -> ERC20s;

    /// Collects accumulated resources from all colonies owned by the caller.
    ///
    /// # Returns
    /// - ERC20s with total collected steel, quartz, tritium amounts from all colonies
    ///
    /// # Effects
    /// - Iterates through all colonies for caller's planet
    /// - Calculates production for each colony since last collection
    /// - Resets resource timers for all colonies
    /// - Aggregates all resources into single return value
    /// - Does NOT mint tokens (handled by Planet contract)
    ///
    /// # Notes
    /// - Gas-efficient batch operation
    /// - Skips empty colonies automatically
    /// - Returns zero if player has no colonies
    fn collect_resources_from_all_colonies(ref self: TState) -> ERC20s;

    /// Upgrades a compound structure on a colony.
    ///
    /// # Parameters
    /// - `colony_id`: Target colony
    /// - `name`: Structure type (SteelMine, QuartzMine, TritiumMine, EnergyPlant, Dockyard)
    /// - `quantity`: Number of levels to upgrade
    ///
    /// # Effects
    /// - Increments structure level
    /// - Costs deducted by caller (Planet/Compound contract)
    ///
    /// # Panics
    /// - If colony doesn't exist
    fn process_colony_compound_upgrade(
        ref self: TState, colony_id: u8, name: ColonyUpgradeType, quantity: u8,
    );

    /// Builds ships or defences on a colony.
    ///
    /// # Parameters
    /// - `colony_id`: Target colony
    /// - `name`: Unit type (ships or defences)
    /// - `quantity`: Number of units to build
    ///
    /// # Effects
    /// - Verifies tech and dockyard requirements
    /// - Increments unit count
    /// - Costs deducted by caller
    ///
    /// # Panics
    /// - If colony doesn't exist
    /// - If requirements not met
    fn process_colony_unit_build(
        ref self: TState, colony_id: u8, name: ColonyBuildType, quantity: u32,
    );

    /// Resets colony resource timer (authorized contracts only).
    ///
    /// # Parameters
    /// - `planet_id`: Mother planet ID
    /// - `colony_id`: Colony number
    ///
    /// # Notes
    /// - Called after attacks to prevent immediate re-raid
    fn set_resource_timer(ref self: TState, planet_id: u32, colony_id: u8);

    /// Sets ship count on colony (authorized contracts only).
    fn set_colony_ship(ref self: TState, planet_id: u32, colony_id: u8, name: u8, quantity: u32);

    /// Sets defence count on colony (authorized contracts only).
    fn set_colony_defence(ref self: TState, planet_id: u32, colony_id: u8, name: u8, quantity: u32);

    /// Retrieves accumulated resources for a colony (view only).
    fn get_colony_resources(self: @TState, planet_id: u32, colony_id: u8) -> ERC20s;

    /// Updates defence levels after attack (authorized contracts only).
    fn update_defences_after_attack(ref self: TState, planet_id: u32, colony_id: u8, d: Defences);

    /// Adds fleet to colony after arrival (authorized contracts only).
    fn fleet_arrives(ref self: TState, planet_id: u32, colony_id: u8, fleet: Fleet);

    /// Removes fleet from colony on departure (authorized contracts only).
    fn fleet_leaves(ref self: TState, planet_id: u32, colony_id: u8, fleet: Fleet);

    /// Retrieves colony position in universe.
    fn get_colony_position(self: @TState, planet_id: u32, colony_id: u8) -> PlanetPosition;

    /// Calculates composite colony ID from planet and colony number.
    fn get_colony_id(self: @TState, planet_id: u32, colony_id: u8) -> u32;

    /// Lists all colonies owned by a planet.
    fn get_colonies_for_planet(self: @TState, planet_id: u32) -> Array<(u8, PlanetPosition)>;

    /// Gets mother planet ID from colony composite ID.
    fn get_colony_mother_planet(self: @TState, colony_planet_id: u32) -> u32;

    /// Retrieves colony compound levels.
    fn get_colony_compounds(self: @TState, planet_id: u32, colony_id: u8) -> CompoundsLevels;

    /// Retrieves colony ship counts.
    fn get_colony_ships(self: @TState, planet_id: u32, colony_id: u8) -> ShipsLevels;

    /// Retrieves colony defence counts.
    fn get_colony_defences(self: @TState, planet_id: u32, colony_id: u8) -> Defences;
}

mod ResourceName {
    const STEEL: felt252 = 1;
    const QUARTZ: felt252 = 1;
    const TRITIUM: felt252 = 3;
}

#[starknet::contract]
mod Colony {
    use nogame::colony::assets::{self, ColonyAssetState};
    use nogame::colony::positions;
    use nogame::compound::library as compound;
    use nogame::game::contract::{IGameDispatcher, IGameDispatcherTrait};
    use nogame::libraries::names::Names;
    use nogame::libraries::types::{
        ColonyBuildType, ColonyUpgradeType, CompoundsLevels, Defences, ERC20s, Fleet, HOUR,
        PlanetPosition, ShipsLevels, TechLevels,
    };
    use nogame::libraries::{colony_identity, production};
    use nogame::planet::contract::IPlanetDispatcherTrait;
    use nogame::tech::contract::ITechDispatcherTrait;
    use openzeppelin_access::ownable::OwnableComponent;
    use openzeppelin_interfaces::erc20::{IERC20Dispatcher, IERC20DispatcherTrait};
    use openzeppelin_security::reentrancyguard::ReentrancyGuardComponent;
    use starknet::storage::{
        Map, StoragePathEntry, StoragePointerReadAccess, StoragePointerWriteAccess,
    };
    use starknet::{ContractAddress, get_block_timestamp, get_caller_address};

    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    component!(
        path: ReentrancyGuardComponent, storage: reentrancyguard, event: ReentrancyGuardEvent,
    );
    impl ReentrancyGuardInternalImpl = ReentrancyGuardComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        game_manager: IGameDispatcher,
        colony_owner: Map<u32, u32>,
        colony_count: usize,
        planet_colonies_count: Map<u32, u8>,
        colony_position: Map<(u32, u8), PlanetPosition>,
        position_to_colony: Map<PlanetPosition, (u32, u8)>,
        colony_resource_timer: Map<(u32, u8), u64>,
        colony_compounds: Map<(u32, u8, u8), u8>,
        colony_ships: Map<(u32, u8, u8), u32>,
        colony_defences: Map<(u32, u8, u8), u32>,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        #[substorage(v0)]
        reentrancyguard: ReentrancyGuardComponent::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        PlanetGenerated: PlanetGenerated,
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        #[flat]
        ReentrancyGuardEvent: ReentrancyGuardComponent::Event,
    }

    /// Colony generation event emitted when a new colony is created.
    ///
    /// # Indexed Fields (for efficient off-chain queries)
    /// - `account`: Colony owner address - Index for "my colonies" queries
    /// - `id`: Colony composite ID - Index for specific colony lookup
    ///
    /// # Notes
    /// - Colony ID = (mother_planet_id * 1000) + colony_number
    /// - Enables efficient tracking of colony ownership
    /// - Frontend can query all colonies owned by a player
    #[derive(Drop, starknet::Event)]
    struct PlanetGenerated {
        #[key]
        id: u32,
        position: PlanetPosition,
        #[key]
        account: ContractAddress,
    }

    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress, game: ContractAddress) {
        self.ownable.initializer(owner);
        self.game_manager.write(IGameDispatcher { contract_address: game });
    }

    #[abi(embed_v0)]
    impl ColonyImpl of super::IColony<ContractState> {
        fn generate_colony(ref self: ContractState) {
            let caller = get_caller_address();
            // Cache game_manager read to avoid redundant storage access
            let game_manager = self.game_manager.read();
            let contracts = game_manager.get_contracts();
            let planet_id = contracts.planet.get_owned_planet(caller);
            let exo_tech = contracts.tech.get_tech_levels(planet_id).exocraft;
            let max_colonies = if exo_tech % 2 == 1 {
                exo_tech / 2 + 1
            } else {
                exo_tech / 2
            };
            let global_count = self.colony_count.read();
            let current_planet_colonies = self.planet_colonies_count.read(planet_id);
            assert!(
                current_planet_colonies < max_colonies,
                "NoGame: max colonies {} reached, upgrade Exocraft tech to increase max colonies",
                max_colonies,
            );
            let price: u256 = 0;
            if !price.is_zero() {
                let eth = game_manager.get_tokens().eth;
                eth.transfer_from(caller, self.ownable.owner(), price);
            }
            let position = positions::get_colony_position(global_count);
            let colony_id = current_planet_colonies + 1;
            let id = colony_identity::encode_colony_id(planet_id, colony_id);
            self.colony_position.write((planet_id, colony_id), position);
            self.planet_colonies_count.write(planet_id, colony_id);
            self.colony_count.write(global_count + 1);
            let number_of_planets = contracts.planet.get_number_of_planets();
            self.colony_owner.write(id, planet_id);
            self.colony_resource_timer.write((planet_id, colony_id), get_block_timestamp());
            contracts.planet.add_colony_planet(id, position, number_of_planets + 1);
            self.emit(Event::PlanetGenerated(PlanetGenerated { id, position, account: caller }));
        }

        fn collect_resources(ref self: ContractState, colony_id: u8) -> ERC20s {
            // Cache game_manager read to avoid redundant storage access
            let game_manager = self.game_manager.read();
            let contracts = game_manager.get_contracts();
            let planet_id = contracts.planet.get_owned_planet(get_caller_address());
            self
                .collect_colony_resources(
                    planet_id, colony_id, game_manager.get_uni_speed(), get_block_timestamp(),
                )
        }

        fn collect_resources_for_planet(
            ref self: ContractState, planet_id: u32, colony_id: u8,
        ) -> ERC20s {
            self.verify_authorized_caller();
            let game_manager = self.game_manager.read();
            self
                .collect_colony_resources(
                    planet_id, colony_id, game_manager.get_uni_speed(), get_block_timestamp(),
                )
        }

        fn collect_resources_from_all_colonies(ref self: ContractState) -> ERC20s {
            // Cache game_manager read to avoid redundant storage access
            let game_manager = self.game_manager.read();
            let contracts = game_manager.get_contracts();
            let planet_id = contracts.planet.get_owned_planet(get_caller_address());

            self
                .collect_all_colony_resources(
                    planet_id, game_manager.get_uni_speed(), get_block_timestamp(),
                )
        }

        fn process_colony_compound_upgrade(
            ref self: ContractState, colony_id: u8, name: ColonyUpgradeType, quantity: u8,
        ) {
            // Cache game_manager read to avoid redundant storage access
            let contracts = self.game_manager.read().get_contracts();
            let planet_id = contracts.planet.get_owned_planet(get_caller_address());
            self.verify_colony_exist(planet_id, colony_id);
            self.upgrade_component(planet_id, colony_id, name, quantity);
        }

        fn process_colony_unit_build(
            ref self: ContractState, colony_id: u8, name: ColonyBuildType, quantity: u32,
        ) {
            // Cache game_manager read to avoid redundant storage access
            let game_manager = self.game_manager.read();
            let contracts = game_manager.get_contracts();
            let planet_id = contracts.planet.get_owned_planet(get_caller_address());
            self.verify_colony_exist(planet_id, colony_id);
            let techs = contracts.tech.get_tech_levels(planet_id);
            self.build_component(planet_id, colony_id, techs, name, quantity);
        }

        fn update_defences_after_attack(
            ref self: ContractState, planet_id: u32, colony_id: u8, d: Defences,
        ) {
            self.verify_authorized_caller();
            self.apply_defence_update(planet_id, colony_id, d);
        }

        fn fleet_arrives(ref self: ContractState, planet_id: u32, colony_id: u8, fleet: Fleet) {
            self.verify_authorized_caller();
            self.apply_fleet_arrival(planet_id, colony_id, fleet);
        }

        fn fleet_leaves(ref self: ContractState, planet_id: u32, colony_id: u8, fleet: Fleet) {
            self.verify_authorized_caller();
            self.apply_fleet_departure(planet_id, colony_id, fleet);
        }

        fn get_colony_position(
            self: @ContractState, planet_id: u32, colony_id: u8,
        ) -> PlanetPosition {
            self.colony_position.read((planet_id, colony_id))
        }

        fn get_colony_id(self: @ContractState, planet_id: u32, colony_id: u8) -> u32 {
            colony_identity::encode_colony_id(planet_id, colony_id)
        }

        fn get_colonies_for_planet(
            self: @ContractState, planet_id: u32,
        ) -> Array<(u8, PlanetPosition)> {
            let mut arr: Array<(u8, PlanetPosition)> = array![];
            let mut i = 1;
            loop {
                let colony_position = self.colony_position.read((planet_id, i));
                if colony_position.is_zero() {
                    break;
                }
                arr.append((i, colony_position));
                i += 1;
            }
            arr
        }

        fn get_colony_mother_planet(self: @ContractState, colony_planet_id: u32) -> u32 {
            self.colony_owner.read(colony_planet_id)
        }

        fn set_resource_timer(ref self: ContractState, planet_id: u32, colony_id: u8) {
            self.verify_authorized_caller();
            self.reset_resource_timer(planet_id, colony_id, get_block_timestamp());
        }

        fn set_colony_ship(
            ref self: ContractState, planet_id: u32, colony_id: u8, name: u8, quantity: u32,
        ) {
            self.verify_authorized_caller();
            self.set_colony_ship_level(planet_id, colony_id, name, quantity);
        }

        fn set_colony_defence(
            ref self: ContractState, planet_id: u32, colony_id: u8, name: u8, quantity: u32,
        ) {
            self.verify_authorized_caller();
            self.set_colony_defence_level(planet_id, colony_id, name, quantity);
        }


        fn get_colony_resources(self: @ContractState, planet_id: u32, colony_id: u8) -> ERC20s {
            if self.colony_position.read((planet_id, colony_id)).is_zero() {
                return Zeroable::zero();
            }
            let uni_speed = self.game_manager.read().get_uni_speed();
            self.calculate_colony_production(uni_speed, planet_id, colony_id)
        }

        fn get_colony_compounds(
            self: @ContractState, planet_id: u32, colony_id: u8,
        ) -> CompoundsLevels {
            CompoundsLevels {
                steel: self.colony_compounds.read((planet_id, colony_id, Names::Compound::STEEL)),
                quartz: self.colony_compounds.read((planet_id, colony_id, Names::Compound::QUARTZ)),
                tritium: self
                    .colony_compounds
                    .read((planet_id, colony_id, Names::Compound::TRITIUM)),
                energy: self.colony_compounds.read((planet_id, colony_id, Names::Compound::ENERGY)),
                lab: self.colony_compounds.read((planet_id, colony_id, Names::Compound::LAB)),
                dockyard: self
                    .colony_compounds
                    .read((planet_id, colony_id, Names::Compound::DOCKYARD)),
            }
        }

        fn get_colony_ships(self: @ContractState, planet_id: u32, colony_id: u8) -> ShipsLevels {
            ShipsLevels {
                carrier: self.colony_ships.read((planet_id, colony_id, Names::Fleet::CARRIER)),
                scraper: self.colony_ships.read((planet_id, colony_id, Names::Fleet::SCRAPER)),
                sparrow: self.colony_ships.read((planet_id, colony_id, Names::Fleet::SPARROW)),
                frigate: self.colony_ships.read((planet_id, colony_id, Names::Fleet::FRIGATE)),
                armade: self.colony_ships.read((planet_id, colony_id, Names::Fleet::ARMADE)),
            }
        }

        fn get_colony_defences(self: @ContractState, planet_id: u32, colony_id: u8) -> Defences {
            Defences {
                celestia: self
                    .colony_defences
                    .read((planet_id, colony_id, Names::Defence::CELESTIA)),
                blaster: self.colony_defences.read((planet_id, colony_id, Names::Defence::BLASTER)),
                beam: self.colony_defences.read((planet_id, colony_id, Names::Defence::BEAM)),
                astral: self.colony_defences.read((planet_id, colony_id, Names::Defence::ASTRAL)),
                plasma: self.colony_defences.read((planet_id, colony_id, Names::Defence::PLASMA)),
            }
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn verify_authorized_caller(self: @ContractState) {
            let caller = get_caller_address();
            let game_manager = self.game_manager.read();
            let contracts = game_manager.get_contracts();

            // Check if caller is one of the registered game contracts
            let is_authorized = caller == contracts.fleet.contract_address
                || caller == contracts.planet.contract_address
                || caller == contracts.compound.contract_address
                || caller == contracts.tech.contract_address
                || caller == contracts.dockyard.contract_address
                || caller == contracts.defence.contract_address
                || caller == game_manager.contract_address;

            assert!(
                is_authorized,
                "NoGame::Colony[E_UNAUTHORIZED_CALLER]: caller {:?} allowed fleet {:?} planet {:?} compound {:?} tech {:?} dockyard {:?} defence {:?} manager {:?}",
                caller,
                contracts.fleet.contract_address,
                contracts.planet.contract_address,
                contracts.compound.contract_address,
                contracts.tech.contract_address,
                contracts.dockyard.contract_address,
                contracts.defence.contract_address,
                game_manager.contract_address,
            );
        }

        fn verify_colony_exist(self: @ContractState, planet_id: u32, colony_id: u8) {
            assert!(
                !self.colony_position.read((planet_id, colony_id)).is_zero(),
                "NoGameColony: colony {} not present for planet {}",
                colony_id,
                planet_id,
            );
        }

        fn collect_colony_resources(
            ref self: ContractState, planet_id: u32, colony_id: u8, uni_speed: u128, time_now: u64,
        ) -> ERC20s {
            self.verify_colony_exist(planet_id, colony_id);
            let production = self.calculate_colony_production(uni_speed, planet_id, colony_id);
            self.reset_resource_timer(planet_id, colony_id, time_now);
            production
        }

        fn collect_all_colony_resources(
            ref self: ContractState, planet_id: u32, uni_speed: u128, time_now: u64,
        ) -> ERC20s {
            let colony_count = self.planet_colonies_count.read(planet_id);
            if colony_count == 0 {
                return Zeroable::zero();
            }

            let mut total_resources: ERC20s = Default::default();
            let mut colony_id: u8 = 1;
            while colony_id <= colony_count {
                let colony_position = self.colony_position.read((planet_id, colony_id));
                if !colony_position.is_zero() {
                    total_resources = total_resources
                        + self.calculate_colony_production(uni_speed, planet_id, colony_id);
                    self.reset_resource_timer(planet_id, colony_id, time_now);
                }

                colony_id += 1;
            }

            total_resources
        }

        fn reset_resource_timer(
            ref self: ContractState, planet_id: u32, colony_id: u8, time_now: u64,
        ) {
            self.colony_resource_timer.write((planet_id, colony_id), time_now);
        }

        fn apply_defence_update(
            ref self: ContractState, planet_id: u32, colony_id: u8, defences: Defences,
        ) {
            self.write_colony_defences(planet_id, colony_id, defences);
        }

        fn apply_fleet_arrival(
            ref self: ContractState, planet_id: u32, colony_id: u8, fleet: Fleet,
        ) {
            let current_levels = self.get_colony_ships(planet_id, colony_id);
            self.write_colony_ships(planet_id, colony_id, assets::add_fleet(current_levels, fleet));
        }

        fn apply_fleet_departure(
            ref self: ContractState, planet_id: u32, colony_id: u8, fleet: Fleet,
        ) {
            let current_levels = self.get_colony_ships(planet_id, colony_id);
            self
                .write_colony_ships(
                    planet_id, colony_id, assets::remove_fleet(current_levels, fleet),
                );
        }

        fn set_colony_ship_level(
            ref self: ContractState, planet_id: u32, colony_id: u8, name: u8, quantity: u32,
        ) {
            self.colony_ships.write((planet_id, colony_id, name), quantity);
        }

        fn set_colony_defence_level(
            ref self: ContractState, planet_id: u32, colony_id: u8, name: u8, quantity: u32,
        ) {
            self.colony_defences.write((planet_id, colony_id, name), quantity);
        }

        fn upgrade_component(
            ref self: ContractState,
            planet_id: u32,
            colony_id: u8,
            component: ColonyUpgradeType,
            quantity: u8,
        ) {
            let current_levels = self.get_colony_compounds(planet_id, colony_id);
            self
                .write_colony_compounds(
                    planet_id,
                    colony_id,
                    assets::upgrade_compounds(current_levels, component, quantity),
                );
        }

        fn build_component(
            ref self: ContractState,
            planet_id: u32,
            colony_id: u8,
            techs: TechLevels,
            component: ColonyBuildType,
            quantity: u32,
        ) {
            let next = assets::build_units(
                ColonyAssetState {
                    compounds: self.get_colony_compounds(planet_id, colony_id),
                    ships: self.get_colony_ships(planet_id, colony_id),
                    defences: self.get_colony_defences(planet_id, colony_id),
                },
                techs,
                component,
                quantity,
            );
            self.write_colony_ships(planet_id, colony_id, next.ships);
            self.write_colony_defences(planet_id, colony_id, next.defences);
        }

        fn write_colony_compounds(
            ref self: ContractState, planet_id: u32, colony_id: u8, levels: CompoundsLevels,
        ) {
            self
                .colony_compounds
                .write((planet_id, colony_id, Names::Compound::STEEL), levels.steel);
            self
                .colony_compounds
                .write((planet_id, colony_id, Names::Compound::QUARTZ), levels.quartz);
            self
                .colony_compounds
                .write((planet_id, colony_id, Names::Compound::TRITIUM), levels.tritium);
            self
                .colony_compounds
                .write((planet_id, colony_id, Names::Compound::ENERGY), levels.energy);
            self.colony_compounds.write((planet_id, colony_id, Names::Compound::LAB), levels.lab);
            self
                .colony_compounds
                .write((planet_id, colony_id, Names::Compound::DOCKYARD), levels.dockyard);
        }

        fn write_colony_ships(
            ref self: ContractState, planet_id: u32, colony_id: u8, levels: ShipsLevels,
        ) {
            self.colony_ships.write((planet_id, colony_id, Names::Fleet::CARRIER), levels.carrier);
            self.colony_ships.write((planet_id, colony_id, Names::Fleet::SCRAPER), levels.scraper);
            self.colony_ships.write((planet_id, colony_id, Names::Fleet::SPARROW), levels.sparrow);
            self.colony_ships.write((planet_id, colony_id, Names::Fleet::FRIGATE), levels.frigate);
            self.colony_ships.write((planet_id, colony_id, Names::Fleet::ARMADE), levels.armade);
        }

        fn write_colony_defences(
            ref self: ContractState, planet_id: u32, colony_id: u8, levels: Defences,
        ) {
            self
                .colony_defences
                .write((planet_id, colony_id, Names::Defence::CELESTIA), levels.celestia);
            self
                .colony_defences
                .write((planet_id, colony_id, Names::Defence::BLASTER), levels.blaster);
            self.colony_defences.write((planet_id, colony_id, Names::Defence::BEAM), levels.beam);
            self
                .colony_defences
                .write((planet_id, colony_id, Names::Defence::ASTRAL), levels.astral);
            self
                .colony_defences
                .write((planet_id, colony_id, Names::Defence::PLASMA), levels.plasma);
        }

        fn calculate_colony_production(
            self: @ContractState, uni_speed: u128, planet_id: u32, colony_id: u8,
        ) -> ERC20s {
            let time_now = get_block_timestamp();
            let last_collection_time = self.colony_resource_timer.read((planet_id, colony_id));
            let time_elapsed = time_now - last_collection_time;
            let mines_levels = self.get_colony_compounds(planet_id, colony_id);
            let position = self.colony_position.read((planet_id, colony_id));
            let celestia_available = self.get_colony_defences(planet_id, colony_id).celestia;
            production::calculate_resource_production(
                mines_levels, position, celestia_available, uni_speed, time_elapsed,
            )
        }
    }
}
