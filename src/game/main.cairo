// TODOS: 
#[starknet::contract]
mod NoGame {
    use core::poseidon::poseidon_hash_span;
    use nogame::component::shared::SharedComponent;
    use nogame::game::interface::INoGame;
    use nogame::libraries::auction::{LinearVRGDA, LinearVRGDATrait};
    use nogame::libraries::positions;
    use nogame::libraries::types::{ERC20s, PlanetPosition, DAY, E18, MAX_NUMBER_OF_PLANETS, _0_05};
    use nogame::storage::storage::{IStorageDispatcher, IStorageDispatcherTrait};
    use nogame::token::erc20::interface::{IERC20NoGameDispatcher, IERC20NoGameDispatcherTrait};
    use nogame::token::erc721::interface::{IERC721NoGameDispatcherTrait, IERC721NoGameDispatcher};

    use nogame_fixed::f128::types::{Fixed, FixedTrait, ONE_u128 as ONE};
    use openzeppelin::access::ownable::OwnableComponent;
    use openzeppelin::security::reentrancyguard::ReentrancyGuardComponent;
    use openzeppelin::token::erc20::interface::{IERC20CamelDispatcher, IERC20CamelDispatcherTrait};
    // Components
    use openzeppelin::upgrades::upgradeable::UpgradeableComponent;

    use snforge_std::PrintTrait;
    use starknet::{
        ContractAddress, get_block_timestamp, get_caller_address, get_contract_address,
        SyscallResultTrait, class_hash::ClassHash
    };

    component!(path: SharedComponent, storage: shared, event: SharedEvent);
    impl SharedInternalImpl = SharedComponent::InternalImpl<ContractState>;
    #[abi(embed_v0)]
    impl SharedImpl = SharedComponent::Shared<ContractState>;

    component!(path: UpgradeableComponent, storage: upgradeable, event: UpgradeableEvent);
    impl UpgradableInteralImpl = UpgradeableComponent::InternalImpl<ContractState>;

    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    component!(
        path: ReentrancyGuardComponent, storage: reentrancyguard, event: ReentrancyGuardEvent
    );
    impl ReentrancyGuardInternalImpl = ReentrancyGuardComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        shared: SharedComponent::Storage,
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
        #[flat]
        SharedEvent: SharedComponent::Event,
    }

    #[derive(Drop, starknet::Event)]
    struct PlanetGenerated {
        id: u32,
        position: PlanetPosition,
        account: ContractAddress,
    }

    #[constructor]
    fn constructor(ref self: ContractState) {}

    #[abi(embed_v0)]
    impl NoGame of INoGame<ContractState> {
        fn initializer(ref self: ContractState, owner: ContractAddress, storage: ContractAddress,) {
            self.ownable.initializer(owner);
            self.shared.storage.write(IStorageDispatcher { contract_address: storage });
        }

        /////////////////////////////////////////////////////////////////////
        //                         Planet Functions                                
        /////////////////////////////////////////////////////////////////////
        fn generate_planet(ref self: ContractState) {
            let caller = get_caller_address();
            let tokens = self.shared.storage.read().get_token_addresses();

            assert!(
                tokens.erc721.balance_of(caller).is_zero(),
                "NoGame: caller is already a planet owner"
            );

            let time_elapsed = (get_block_timestamp()
                - self.shared.storage.read().get_universe_start_time())
                / DAY;
            let price: u256 = self.get_planet_price(time_elapsed).into();

            tokens.eth.transferFrom(caller, self.ownable.owner(), price);

            let number_of_planets = self.shared.storage.read().get_number_of_planets();
            assert(number_of_planets != MAX_NUMBER_OF_PLANETS, 'max number of planets');
            let token_id = number_of_planets + 1;
            let position = positions::get_planet_position(token_id);

            tokens.erc721.mint(caller, token_id.into());

            self.shared.storage.read().add_new_planet(token_id, position, number_of_planets + 1, 0);
            self
                .shared
                .receive_resources_erc20(caller, ERC20s { steel: 500, quartz: 300, tritium: 100 });
            self
                .emit(
                    Event::PlanetGenerated(
                        PlanetGenerated { id: token_id, position, account: caller }
                    )
                );
        }

        fn get_current_planet_price(self: @ContractState) -> u128 {
            let time_elapsed = (get_block_timestamp()
                - self.shared.storage.read().get_universe_start_time())
                / DAY;
            self.get_planet_price(time_elapsed)
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn get_planet_price(self: @ContractState, time_elapsed: u64) -> u128 {
            let auction = LinearVRGDA {
                target_price: FixedTrait::new(self.shared.storage.read().get_token_price(), false),
                decay_constant: FixedTrait::new(_0_05, true),
                per_time_unit: FixedTrait::new_unscaled(10, false),
            };
            let planet_sold: u128 = self.shared.storage.read().get_number_of_planets().into();
            auction
                .get_vrgda_price(
                    FixedTrait::new_unscaled(time_elapsed.into(), false),
                    FixedTrait::new_unscaled(planet_sold, false)
                )
                .mag
                * E18
                / ONE
        }
    }
}

