use nogame::libraries::types::{Debris, ERC20s, PlanetPosition, Tokens};
use starknet::ContractAddress;

#[starknet::interface]
trait IPlanet<TState> {
    /// Generates a new planet for the caller using a VRGDA pricing model.
    ///
    /// # Effects
    /// - Charges caller based on time-decaying VRGDA price in ETH
    /// - Mints planet NFT to caller
    /// - Assigns position based on predetermined galaxy/system/orbit
    /// - Grants initial resources (500 steel, 300 quartz, 100 tritium)
    /// - Emits PlanetGenerated event
    ///
    /// # Panics
    /// - If caller already owns a planet
    /// - If maximum number of planets reached (MAX_NUMBER_OF_PLANETS)
    /// - If insufficient ETH for current price
    fn generate_planet(ref self: TState);

    /// Collects accumulated resources from planet and all colonies.
    ///
    /// # Parameters
    /// - `player`: Address to receive minted resource tokens
    ///
    /// # Effects
    /// - Calculates production since last collection
    /// - Mints ERC20 tokens (steel, quartz, tritium) to player
    /// - Resets resource timer for planet and colonies
    ///
    /// # Notes
    /// - Production scaled by energy availability
    /// - Iterates through all colonies if present
    fn collect_resources(ref self: TState, player: ContractAddress);

    /// Retrieves current planet purchase price based on VRGDA model.
    ///
    /// # Returns
    /// - Current price in Wei (18 decimals)
    ///
    /// # Notes
    /// - Price decreases over time if planets sold slower than target rate
    /// - Target rate: 10 planets per day
    /// - Uses decay constant of 0.05
    fn get_current_planet_price(self: @TState) -> u128;

    /// Updates planet's accumulated resource spending for points calculation.
    ///
    /// # Parameters
    /// - `planet_id`: Planet to update
    /// - `spent`: Resources spent on upgrades/builds
    /// - `neg`: If true, subtracts points (for losses); if false, adds points
    ///
    /// # Effects
    /// - Modifies resources_spent storage
    /// - Updates last_active timestamp
    ///
    /// # Notes
    /// - Points = (steel + quartz spent) / 1000
    /// - Used for ranking and noob protection calculations
    fn update_planet_points(ref self: TState, planet_id: u32, spent: ERC20s, neg: bool);

    /// Registers a colony planet in the universe position mapping.
    ///
    /// # Parameters
    /// - `planet_id`: Colony ID (mother_planet_id * 1000 + colony_number)
    /// - `position`: Position in universe
    /// - `new_planet_count`: Updated total planet count
    ///
    /// # Effects
    /// - Creates bidirectional position mapping
    /// - Updates total planet count
    ///
    /// # Notes
    /// - Called by Colony contract when generating new colony
    fn add_colony_planet(
        ref self: TState, planet_id: u32, position: PlanetPosition, new_planet_count: u32,
    );

    /// Updates planet's last activity timestamp.
    ///
    /// # Parameters
    /// - `planet_id`: Planet to update
    ///
    /// # Effects
    /// - Sets last_active to current block timestamp
    ///
    /// # Notes
    /// - Used for inactive player detection (>1 week = inactive)
    /// - Inactive players can be attacked without noob protection checks
    fn set_last_active(ref self: TState, planet_id: u32);

    /// Resets resource collection timer after raid or collection.
    ///
    /// # Parameters
    /// - `planet_id`: Planet to reset
    ///
    /// # Effects
    /// - Sets resources_timer to current block timestamp
    ///
    /// # Notes
    /// - Called after successful attack to prevent immediate re-raid
    /// - Also called during normal resource collection
    fn set_resources_timer(ref self: TState, planet_id: u32);

    /// Updates debris field around a planet after battle.
    ///
    /// # Parameters
    /// - `planet_id`: Planet with debris field
    /// - `debris`: New debris amounts (steel, quartz)
    ///
    /// # Effects
    /// - Overwrites existing debris field
    ///
    /// # Notes
    /// - Debris comes from destroyed ships and defences (30% of cost)
    /// - Can be collected by scraper ships
    fn set_planet_debris_field(ref self: TState, planet_id: u32, debris: Debris);

    /// Returns total number of planets generated (including colonies).
    ///
    /// # Returns
    /// - Count of all planet NFTs minted
    fn get_number_of_planets(self: @TState) -> u32;

    /// Retrieves planet ID owned by an account.
    ///
    /// # Parameters
    /// - `account`: Address to query
    ///
    /// # Returns
    /// - Planet ID (token ID of planet NFT)
    ///
    /// # Notes
    /// - Returns 0 if account doesn't own a planet
    /// - Each account can only own one home planet (colonies tracked separately)
    fn get_owned_planet(self: @TState, account: ContractAddress) -> u32;

    /// Calculates planet's rank points based on resource spending.
    ///
    /// # Parameters
    /// - `planet_id`: Planet to query
    ///
    /// # Returns
    /// - Points value (resources_spent / 1000)
    ///
    /// # Notes
    /// - Used for leaderboards and noob protection
    fn get_planet_points(self: @TState, planet_id: u32) -> u128;

    /// Retrieves accumulated production resources (not yet collected).
    ///
    /// # Parameters
    /// - `planet_id`: Planet to query
    ///
    /// # Returns
    /// - ERC20s struct with steel, quartz, tritium amounts
    ///
    /// # Notes
    /// - Production scaled by available energy
    /// - Calculated from last collection time to now
    fn get_collectible_resources(self: @TState, planet_id: u32) -> ERC20s;

    /// Retrieves planet owner's spendable ERC20 token balances.
    ///
    /// # Parameters
    /// - `planet_id`: Planet to query
    ///
    /// # Returns
    /// - ERC20s struct with token balances (in base units, not Wei)
    ///
    /// # Notes
    /// - Queries actual ERC20 contract balances
    /// - Does not include uncollected production
    fn get_spendable_resources(self: @TState, planet_id: u32) -> ERC20s;

    /// Retrieves planet's position in the universe.
    ///
    /// # Parameters
    /// - `planet_id`: Planet to query
    ///
    /// # Returns
    /// - PlanetPosition struct (galaxy, system, orbit)
    fn get_planet_position(self: @TState, planet_id: u32) -> PlanetPosition;

    /// Reverse lookup: finds planet ID at a given position.
    ///
    /// # Parameters
    /// - `position`: Universe coordinates to query
    ///
    /// # Returns
    /// - Planet ID at that position (0 if empty)
    ///
    /// # Notes
    /// - Used for fleet targeting and colony placement validation
    fn get_position_to_planet(self: @TState, position: PlanetPosition) -> u32;

    /// Retrieves debris field around a planet.
    ///
    /// # Parameters
    /// - `planet_id`: Planet to query
    ///
    /// # Returns
    /// - Debris struct with steel and quartz amounts
    fn get_planet_debris_field(self: @TState, planet_id: u32) -> Debris;

    /// Retrieves timestamp of planet's last activity.
    ///
    /// # Parameters
    /// - `planet_id`: Planet to query
    ///
    /// # Returns
    /// - Unix timestamp of last action
    fn get_last_active(self: @TState, planet_id: u32) -> u64;

    /// Checks if noob protection applies between two planets.
    ///
    /// # Parameters
    /// - `planet1_id`: First planet
    /// - `planet2_id`: Second planet
    ///
    /// # Returns
    /// - True if either planet is protected (5x points difference)
    ///
    /// # Notes
    /// - Protection applies if one planet has >5x the points of the other
    /// - Prevents high-level players from farming new players
    /// - Uses modulo 1000 to get home planet ID from colonies
    fn get_is_noob_protected(self: @TState, planet1_id: u32, planet2_id: u32) -> bool;
}

#[starknet::contract]
mod Planet {
    use core::traits::TryInto;
    use nogame::colony::contract::IColonyDispatcherTrait;
    use nogame::compound::contract::ICompoundDispatcherTrait;
    use nogame::compound::library as compound;
    use nogame::defence::contract::IDefenceDispatcherTrait;
    use nogame::game::contract::{IGameDispatcher, IGameDispatcherTrait};
    use nogame::game::interfaces::{
        IContractRegistryDispatcher, IContractRegistryDispatcherTrait, ITokenProviderDispatcher,
        ITokenProviderDispatcherTrait, IUniverseConfigDispatcher, IUniverseConfigDispatcherTrait,
    };
    use nogame::libraries::auction::{LinearVRGDA, LinearVRGDATrait};
    use nogame::libraries::positions;
    use nogame::libraries::types::{
        Contracts, DAY, Debris, E18, ERC20s, HOUR, MAX_NUMBER_OF_PLANETS, PlanetPosition, Tokens,
        _0_05,
    };
    //
    use nogame::token::erc20::interface::{IERC20NoGameDispatcher, IERC20NoGameDispatcherTrait};
    use nogame::token::erc721::interface::{IERC721NoGameDispatcher, IERC721NoGameDispatcherTrait};
    use nogame_fixed::f128::types::{Fixed, FixedTrait, ONE_u128 as ONE};
    use openzeppelin_access::ownable::OwnableComponent;
    use openzeppelin_interfaces::erc20::{IERC20Dispatcher, IERC20DispatcherTrait};
    use openzeppelin_security::reentrancyguard::ReentrancyGuardComponent;
    use openzeppelin_upgrades::upgradeable::UpgradeableComponent;
    use starknet::storage::{
        Map, StoragePathEntry, StoragePointerReadAccess, StoragePointerWriteAccess,
    };
    use starknet::{ContractAddress, get_block_timestamp, get_caller_address, get_contract_address};

    component!(path: UpgradeableComponent, storage: upgradeable, event: UpgradeableEvent);
    impl UpgradableInteralImpl = UpgradeableComponent::InternalImpl<ContractState>;

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
        resources_spent: Map<u32, u128>,
        number_of_planets: u32,
        planet_position: Map<u32, PlanetPosition>,
        position_to_planet: Map<PlanetPosition, u32>,
        last_active: Map<u32, u64>,
        resources_timer: Map<u32, u64>,
        planet_debris_field: Map<u32, Debris>,
        #[substorage(v0)]
        upgradeable: UpgradeableComponent::Storage,
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
        UpgradeableEvent: UpgradeableComponent::Event,
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        #[flat]
        ReentrancyGuardEvent: ReentrancyGuardComponent::Event,
    }

    /// Planet generation event emitted when a new planet is created.
    ///
    /// # Indexed Fields (for efficient off-chain queries)
    /// - `account`: Planet owner address - Index for "my planet" queries
    /// - `id`: Planet ID - Index for specific planet lookup
    ///
    /// # Notes
    /// - Enables efficient tracking of planet ownership
    /// - Frontend can query all planets owned by an address
    /// - Indexers can build planet registry by ID
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
    impl PlanetImpl of super::IPlanet<ContractState> {
        fn generate_planet(ref self: ContractState) {
            let caller = get_caller_address();
            // Use segregated interfaces instead of monolithic IGameDispatcher
            let game_address = self.game_manager.read().contract_address;
            let token_provider = ITokenProviderDispatcher { contract_address: game_address };
            let universe_config = IUniverseConfigDispatcher { contract_address: game_address };

            let tokens = token_provider.get_tokens();

            let existing_planets = tokens.erc721.balance_of(caller);
            assert!(existing_planets.is_zero(), "Planet:E_ALREADY_OWNER");

            let time_elapsed = (get_block_timestamp() - universe_config.get_universe_start_time())
                / DAY;
            let price: u256 = self.get_planet_price(time_elapsed).into();

            tokens.eth.transfer_from(caller, self.ownable.owner(), price);

            let number_of_planets = self.number_of_planets.read();
            assert!(number_of_planets != MAX_NUMBER_OF_PLANETS, "Planet:E_MAX_PLANETS");
            let token_id = number_of_planets + 1;
            let position = positions::get_planet_position(token_id);

            tokens.erc721.mint(caller, token_id.into());

            self.planet_position.write(token_id, position);
            self.position_to_planet.write(position, token_id);
            self.number_of_planets.write(number_of_planets + 1);
            self.receive_resources_erc20(caller, ERC20s { steel: 500, quartz: 300, tritium: 100 });
            self
                .emit(
                    Event::PlanetGenerated(
                        PlanetGenerated { id: token_id, position, account: caller },
                    ),
                );
        }

        fn collect_resources(ref self: ContractState, player: ContractAddress) {
            let caller = get_caller_address();
            // Use segregated interfaces
            let game_address = self.game_manager.read().contract_address;
            let contract_registry = IContractRegistryDispatcher { contract_address: game_address };
            let token_provider = ITokenProviderDispatcher { contract_address: game_address };

            let contracts = contract_registry.get_contracts();
            self.verify_caller(contracts, caller);
            let tokens = token_provider.get_tokens();
            let planet_id = tokens.erc721.token_of(caller).try_into().unwrap();
            let colonies_len = contracts.colony.get_colonies_for_planet(planet_id).len();

            if colonies_len != 0 {
                let mut total_production: ERC20s = Default::default();
                let mut i = 1;
                while i != colonies_len {
                    let production = contracts.colony.collect_resources(i.try_into().unwrap());
                    total_production = total_production + production;
                    i += 1;
                }
                self.receive_resources_erc20(player, total_production);
            }
            self.collect(player);
        }

        fn update_planet_points(ref self: ContractState, planet_id: u32, spent: ERC20s, neg: bool) {
            self.last_active.write(planet_id, get_block_timestamp());
            if neg {
                self
                    .resources_spent
                    .write(
                        planet_id,
                        self.resources_spent.read(planet_id) - spent.steel - spent.quartz,
                    );
            } else {
                self
                    .resources_spent
                    .write(
                        planet_id,
                        self.resources_spent.read(planet_id) + spent.steel + spent.quartz,
                    );
            }
        }

        fn add_colony_planet(
            ref self: ContractState,
            planet_id: u32,
            position: PlanetPosition,
            new_planet_count: u32,
        ) {
            self.position_to_planet.write(position, planet_id);
            self.planet_position.write(planet_id, position);
            self.number_of_planets.write(new_planet_count);
        }

        fn set_last_active(ref self: ContractState, planet_id: u32) {
            self.last_active.write(planet_id, get_block_timestamp());
        }

        fn set_resources_timer(ref self: ContractState, planet_id: u32) {
            self.resources_timer.write(planet_id, get_block_timestamp());
        }

        fn set_planet_debris_field(ref self: ContractState, planet_id: u32, debris: Debris) {
            self.planet_debris_field.write(planet_id, debris);
        }

        fn get_number_of_planets(self: @ContractState) -> u32 {
            self.number_of_planets.read()
        }

        fn get_owned_planet(self: @ContractState, account: ContractAddress) -> u32 {
            // Use segregated interface
            let game_address = self.game_manager.read().contract_address;
            let token_provider = ITokenProviderDispatcher { contract_address: game_address };
            let tokens = token_provider.get_tokens();
            tokens.erc721.token_of(account).try_into().unwrap()
        }

        fn get_planet_points(self: @ContractState, planet_id: u32) -> u128 {
            self.resources_spent.read(planet_id) / 1000
        }

        fn get_current_planet_price(self: @ContractState) -> u128 {
            // Use segregated interface
            let game_address = self.game_manager.read().contract_address;
            let universe_config = IUniverseConfigDispatcher { contract_address: game_address };
            let time_elapsed = (get_block_timestamp() - universe_config.get_universe_start_time())
                / DAY;
            self.get_planet_price(time_elapsed)
        }

        fn get_collectible_resources(self: @ContractState, planet_id: u32) -> ERC20s {
            self.calculate_production(planet_id)
        }

        fn get_spendable_resources(self: @ContractState, planet_id: u32) -> ERC20s {
            // Use segregated interface
            let game_address = self.game_manager.read().contract_address;
            let token_provider = ITokenProviderDispatcher { contract_address: game_address };
            let tokens = token_provider.get_tokens();
            let planet_owner = tokens.erc721.ownerOf(planet_id.into());
            let steel = IERC20Dispatcher { contract_address: tokens.steel.contract_address }
                .balance_of(planet_owner)
                .try_into()
                .unwrap()
                / E18;
            let quartz = IERC20Dispatcher { contract_address: tokens.quartz.contract_address }
                .balance_of(planet_owner)
                .try_into()
                .unwrap()
                / E18;
            let tritium = IERC20Dispatcher { contract_address: tokens.tritium.contract_address }
                .balance_of(planet_owner)
                .try_into()
                .unwrap()
                / E18;
            ERC20s { steel: steel, quartz: quartz, tritium: tritium }
        }

        fn get_planet_position(self: @ContractState, planet_id: u32) -> PlanetPosition {
            self.planet_position.read(planet_id)
        }

        fn get_position_to_planet(self: @ContractState, position: PlanetPosition) -> u32 {
            self.position_to_planet.read(position)
        }

        fn get_planet_debris_field(self: @ContractState, planet_id: u32) -> Debris {
            self.planet_debris_field.read(planet_id)
        }

        fn get_last_active(self: @ContractState, planet_id: u32) -> u64 {
            self.last_active.read(planet_id)
        }

        fn get_is_noob_protected(self: @ContractState, planet1_id: u32, planet2_id: u32) -> bool {
            let p1_points = self.get_planet_points(planet1_id % 1000);
            let p2_points = self.get_planet_points(planet2_id % 1000);
            if p1_points > p2_points {
                return p1_points > p2_points * 5;
            } else {
                return p2_points > p1_points * 5;
            }
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn get_planet_price(self: @ContractState, time_elapsed: u64) -> u128 {
            // Use segregated interface
            let game_address = self.game_manager.read().contract_address;
            let universe_config = IUniverseConfigDispatcher { contract_address: game_address };
            let token_price = universe_config.get_token_price();
            let auction = LinearVRGDA {
                target_price: FixedTrait::new(token_price, false),
                decay_constant: FixedTrait::new(_0_05, true),
                per_time_unit: FixedTrait::new_unscaled(10, false),
            };
            let planet_sold: u128 = self.number_of_planets.read().into();
            auction
                .get_vrgda_price(
                    FixedTrait::new_unscaled(time_elapsed.into(), false),
                    FixedTrait::new_unscaled(planet_sold, false),
                )
                .mag
                * E18
                / ONE
        }

        fn verify_caller(self: @ContractState, contracts: Contracts, caller: ContractAddress) {
            assert!(
                caller == contracts.colony.contract_address
                    || caller == contracts.defence.contract_address
                    || caller == contracts.compound.contract_address
                    || caller == contracts.defence.contract_address
                    || caller == contracts.tech.contract_address
                    || caller == contracts.fleet.contract_address
                    || caller == contracts.dockyard.contract_address,
                "Planet:E_UNAUTHORIZED_CALLER",
            );
        }

        fn collect(ref self: ContractState, player: ContractAddress) {
            // Use segregated interface
            let game_address = self.game_manager.read().contract_address;
            let token_provider = ITokenProviderDispatcher { contract_address: game_address };
            let planet_id = token_provider.get_tokens().erc721.token_of(player).try_into().unwrap();
            assert!(!planet_id.is_zero(), "Planet:E_PLANET_NOT_FOUND");
            let production = self.calculate_production(planet_id);
            self.receive_resources_erc20(player, production);
            self.resources_timer.write(planet_id, get_block_timestamp());
        }

        fn receive_resources_erc20(self: @ContractState, to: ContractAddress, amounts: ERC20s) {
            // Use segregated interface
            let game_address = self.game_manager.read().contract_address;
            let token_provider = ITokenProviderDispatcher { contract_address: game_address };
            let tokens = token_provider.get_tokens();
            tokens.steel.mint(to, (amounts.steel * E18).into());
            tokens.quartz.mint(to, (amounts.quartz * E18).into());
            tokens.tritium.mint(to, (amounts.tritium * E18).into());
        }

        fn get_celestia_production(self: @ContractState, planet_id: u32) -> u32 {
            let position = self.get_planet_position(planet_id);
            compound::position_to_celestia_production(position.orbit)
        }

        /// Calculates resource production based on mine levels, time elapsed, and energy.
        ///
        /// # Parameters
        /// - `planet_id`: Planet to calculate production for
        ///
        /// # Returns
        /// - ERC20s with steel, quartz, tritium production amounts
        ///
        /// # Notes
        /// - Production = base_rate * mine_level * uni_speed * time_elapsed / HOUR
        /// - Tritium affected by planet temperature (orbit-dependent)
        /// - If insufficient energy: production scaled proportionally
        /// - Energy sources: solar plant + celestia satellites
        /// - Consumption: mines require energy based on levels
        fn calculate_production(self: @ContractState, planet_id: u32) -> ERC20s {
            let time_now = get_block_timestamp();
            let last_collection_time = self.resources_timer.read(planet_id);
            let time_elapsed = time_now - last_collection_time;
            // Use segregated interfaces for better separation of concerns
            let game_address = self.game_manager.read().contract_address;
            let contract_registry = IContractRegistryDispatcher { contract_address: game_address };
            let universe_config = IUniverseConfigDispatcher { contract_address: game_address };

            let contracts = contract_registry.get_contracts();
            let mines_levels = contracts.compound.get_compounds_levels(planet_id);
            let position = self.get_planet_position(planet_id);
            // Cache temperature calculation (used only once now)
            let temp = compound::calculate_avg_temperature(position.orbit);
            let speed = universe_config.get_uni_speed();

            // Calculate production values
            let steel_available = compound::production::steel(mines_levels.steel)
                * speed
                * time_elapsed.into()
                / HOUR.into();

            let quartz_available = compound::production::quartz(mines_levels.quartz)
                * speed
                * time_elapsed.into()
                / HOUR.into();

            let tritium_available = compound::production::tritium(mines_levels.tritium, temp, speed)
                * time_elapsed.into()
                / HOUR.into();

            // Cache energy calculations
            let energy_available = compound::production::energy(mines_levels.energy);
            let celestia_production = self.get_celestia_production(planet_id);
            let celestia_available = contracts.defence.get_defences_levels(planet_id).celestia;
            let total_energy = energy_available
                + (celestia_production.into() * celestia_available).into();
            let energy_required = compound::consumption::base(mines_levels.steel)
                + compound::consumption::base(mines_levels.quartz)
                + compound::consumption::base(mines_levels.tritium);

            if total_energy < energy_required {
                let _steel = compound::production_scaler(
                    steel_available, energy_available, energy_required,
                );
                let _quartz = compound::production_scaler(
                    quartz_available, energy_available, energy_required,
                );
                let _tritium = compound::production_scaler(
                    tritium_available, energy_available, energy_required,
                );

                return ERC20s { steel: _steel, quartz: _quartz, tritium: _tritium };
            }

            ERC20s { steel: steel_available, quartz: quartz_available, tritium: tritium_available }
        }
    }
}
