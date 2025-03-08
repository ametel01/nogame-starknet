use nogame::libraries::types::{Debris, ERC20s, PlanetPosition, Tokens};
use starknet::ContractAddress;

#[starknet::interface]
trait IPlanet<TState> {
    fn generate_planet(ref self: TState);
    fn collect_resources(ref self: TState, caller: ContractAddress);
    fn get_current_planet_price(self: @TState) -> u128;
    fn update_planet_points(ref self: TState, planet_id: u32, spent: ERC20s, neg: bool);
    fn add_colony_planet(
        ref self: TState, planet_id: u32, position: PlanetPosition, new_planet_count: u32,
    );
    fn set_last_active(ref self: TState, planet_id: u32);
    fn set_resources_timer(ref self: TState, planet_id: u32);
    fn set_planet_debris_field(ref self: TState, planet_id: u32, debris: Debris);
    fn get_number_of_planets(self: @TState) -> u32;
    fn get_owned_planet(self: @TState, account: ContractAddress) -> u32;
    fn get_planet_points(self: @TState, planet_id: u32) -> u128;
    fn get_collectible_resources(self: @TState, planet_id: u32) -> ERC20s;
    fn get_spendable_resources(self: @TState, planet_id: u32) -> ERC20s;
    fn get_planet_position(self: @TState, planet_id: u32) -> PlanetPosition;
    fn get_position_to_planet(self: @TState, position: PlanetPosition) -> u32;
    fn get_planet_debris_field(self: @TState, planet_id: u32) -> Debris;
    fn get_last_active(self: @TState, planet_id: u32) -> u64;
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
    use nogame::libraries::auction::{LinearVRGDA, LinearVRGDATrait};
    use nogame::libraries::positions;
    use nogame::libraries::types::{
        Contracts, DAY, Debris, E18, ERC20s, HOUR, MAX_NUMBER_OF_PLANETS, PlanetPosition, Tokens,
        _0_05,
    };
    // use nogame::storage::storage::{IStorageDispatcher, IStorageDispatcherTrait};
    use nogame::token::erc20::interface::{IERC20NoGameDispatcher, IERC20NoGameDispatcherTrait};
    use nogame::token::erc721::interface::{IERC721NoGameDispatcher, IERC721NoGameDispatcherTrait};
    use nogame_fixed::f128::types::{Fixed, FixedTrait, ONE_u128 as ONE};
    use openzeppelin_access::ownable::OwnableComponent;
    use openzeppelin_security::reentrancyguard::ReentrancyGuardComponent;
    use openzeppelin_token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
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

    #[derive(Drop, starknet::Event)]
    struct PlanetGenerated {
        id: u32,
        position: PlanetPosition,
        account: ContractAddress,
    }

    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress, game: ContractAddress) {
        self.ownable.initializer(get_caller_address());
        self.game_manager.write(IGameDispatcher { contract_address: game });
    }

    #[abi(embed_v0)]
    impl PlanetImpl of super::IPlanet<ContractState> {
        fn generate_planet(ref self: ContractState) {
            let caller = get_caller_address();
            let game_manager = self.game_manager.read();
            let tokens = game_manager.get_tokens();

            assert!(
                tokens.erc721.balance_of(caller).is_zero(),
                "NoGame: caller is already a planet owner",
            );

            let time_elapsed = (get_block_timestamp() - game_manager.get_universe_start_time())
                / DAY;
            let price: u256 = self.get_planet_price(time_elapsed).into();

            tokens.eth.transfer_from(caller, self.ownable.owner(), price);

            let number_of_planets = self.number_of_planets.read();
            assert(number_of_planets != MAX_NUMBER_OF_PLANETS, 'max number of planets');
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

        fn collect_resources(ref self: ContractState, caller: ContractAddress) {
            let caller = get_caller_address();
            let game_manager = self.game_manager.read();
            let contracts = game_manager.get_contracts();
            self.verify_caller(contracts, caller);
            let tokens = game_manager.get_tokens();
            let planet_id = tokens.erc721.token_of(caller).try_into().unwrap();
            let colonies = contracts.colony.get_colonies_for_planet(planet_id);
            let mut i = 1;
            let colonies_len = colonies.len();
            let mut total_production: ERC20s = Default::default();
            while i != colonies_len {
                let production = contracts.colony.collect_resources(i.try_into().unwrap());
                total_production = total_production + production;
                i += 1;
            }
            self.receive_resources_erc20(caller, total_production);
            self.collect(caller);
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
            let tokens = self.game_manager.read().get_tokens();
            tokens.erc721.token_of(account).try_into().unwrap()
        }

        fn get_planet_points(self: @ContractState, planet_id: u32) -> u128 {
            self.resources_spent.read(planet_id) / 1000
        }

        fn get_current_planet_price(self: @ContractState) -> u128 {
            let time_elapsed = (get_block_timestamp()
                - self.game_manager.read().get_universe_start_time())
                / DAY;
            self.get_planet_price(time_elapsed)
        }

        fn get_collectible_resources(self: @ContractState, planet_id: u32) -> ERC20s {
            self.calculate_production(planet_id)
        }

        fn get_spendable_resources(self: @ContractState, planet_id: u32) -> ERC20s {
            let tokens = self.game_manager.read().get_tokens();
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
            let p1_points = self.get_planet_points(planet1_id);
            let p2_points = self.get_planet_points(planet2_id);
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
            let token_price = self.game_manager.read().get_token_price();
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
                "NoGame::Planet: caller is not authorized to collect resources",
            );
        }

        fn collect(ref self: ContractState, caller: ContractAddress) {
            let planet_id = self
                .game_manager
                .read()
                .get_tokens()
                .erc721
                .token_of(caller)
                .try_into()
                .unwrap();
            assert(!planet_id.is_zero(), 'planet does not exist');
            let production = self.calculate_production(planet_id);
            self.receive_resources_erc20(caller, production);
            self.resources_timer.write(planet_id, get_block_timestamp());
        }

        fn receive_resources_erc20(self: @ContractState, to: ContractAddress, amounts: ERC20s) {
            let tokens = self.game_manager.read().get_tokens();
            tokens.steel.mint(to, (amounts.steel * E18).into());
            tokens.quartz.mint(to, (amounts.quartz * E18).into());
            tokens.tritium.mint(to, (amounts.tritium * E18).into());
        }

        fn get_celestia_production(self: @ContractState, planet_id: u32) -> u32 {
            let position = self.get_planet_position(planet_id);
            compound::position_to_celestia_production(position.orbit)
        }

        fn calculate_production(self: @ContractState, planet_id: u32) -> ERC20s {
            let time_now = get_block_timestamp();
            let last_collection_time = self.resources_timer.read(planet_id);
            let time_elapsed = time_now - last_collection_time;
            let game_manager = self.game_manager.read();
            let contracts = game_manager.get_contracts();
            let mines_levels = contracts.compound.get_compounds_levels(planet_id);
            let position = self.get_planet_position(planet_id);
            let temp = compound::calculate_avg_temperature(position.orbit);
            let speed = game_manager.get_uni_speed();
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
            let energy_available = compound::production::energy(mines_levels.energy);
            let celestia_production = self.get_celestia_production(planet_id);
            let celestia_available = contracts.defence.get_defences_levels(planet_id).celestia;
            let energy_required = compound::consumption::base(mines_levels.steel)
                + compound::consumption::base(mines_levels.quartz)
                + compound::consumption::base(mines_levels.tritium);
            if energy_available
                + (celestia_production.into() * celestia_available).into() < energy_required {
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

