use nogame::libraries::types::{Contracts, ERC20s, Tokens};
use starknet::{ClassHash, ContractAddress};

#[starknet::interface]
trait IGame<TState> {
    fn initialize(
        ref self: TState,
        colony: ContractAddress,
        compound: ContractAddress,
        defence: ContractAddress,
        dockyard: ContractAddress,
        fleet: ContractAddress,
        planet: ContractAddress,
        tech: ContractAddress,
        erc721: ContractAddress,
        steel: ContractAddress,
        quartz: ContractAddress,
        tritium: ContractAddress,
        eth: ContractAddress,
        uni_speed: u128,
        token_price: u128,
    );
    fn upgrade(ref self: TState, impl_hash: ClassHash);
    fn pay_resources_erc20(self: @TState, account: ContractAddress, amounts: ERC20s);
    fn receive_resources_erc20(self: @TState, account: ContractAddress, amounts: ERC20s);
    fn get_uni_speed(self: @TState) -> u128;
    fn get_tokens(self: @TState) -> Tokens;
    fn get_contracts(self: @TState) -> Contracts;
    fn get_universe_start_time(self: @TState) -> u64;
    fn get_token_price(self: @TState) -> u128;
    fn check_enough_resources(self: @TState, caller: ContractAddress, amounts: ERC20s);
}

#[starknet::contract]
mod Game {
    use nogame::colony::contract::IColonyDispatcher;
    use nogame::compound::contract::ICompoundDispatcher;
    use nogame::defence::contract::IDefenceDispatcher;
    use nogame::dockyard::contract::IDockyardDispatcher;
    use nogame::fleet_movements::contract::IFleetMovementsDispatcher;
    use nogame::libraries::types::{Contracts, E18, ERC20s, Tokens};
    use nogame::planet::contract::IPlanetDispatcher;
    use nogame::tech::contract::ITechDispatcher;
    use nogame::token::erc20::interface::{IERC20NoGameDispatcher, IERC20NoGameDispatcherTrait};
    use nogame::token::erc721::interface::IERC721NoGameDispatcher;
    use openzeppelin_access::ownable::OwnableComponent;
    use openzeppelin_token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
    use openzeppelin_upgrades::upgradeable::UpgradeableComponent;
    use starknet::storage::{
        Map, StoragePathEntry, StoragePointerReadAccess, StoragePointerWriteAccess,
    };
    use starknet::{ClassHash, ContractAddress, get_caller_address, get_contract_address};
    use super::IGameDispatcher;

    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    component!(path: UpgradeableComponent, storage: upgradeable, event: UpgradeableEvent);
    impl UpgradableInteralImpl = UpgradeableComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        token_price: u128,
        uni_speed: u128,
        erc721: IERC721NoGameDispatcher,
        steel: IERC20NoGameDispatcher,
        quartz: IERC20NoGameDispatcher,
        tritium: IERC20NoGameDispatcher,
        eth: IERC20Dispatcher,
        universe_start_time: u64,
        game_manager: IGameDispatcher,
        planet_manager: IPlanetDispatcher,
        compound_manager: ICompoundDispatcher,
        dockyard_manager: IDockyardDispatcher,
        defence_manager: IDefenceDispatcher,
        fleet_manager: IFleetMovementsDispatcher,
        colony_manager: IColonyDispatcher,
        tech_manager: ITechDispatcher,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        #[substorage(v0)]
        upgradeable: UpgradeableComponent::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        UpgradeableEvent: UpgradeableComponent::Event,
        #[flat]
        OwnableEvent: OwnableComponent::Event,
    }

    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress) {
        self.ownable.initializer(owner);
    }

    #[abi(embed_v0)]
    impl GameImpl of super::IGame<ContractState> {
        fn initialize(
            ref self: ContractState,
            colony: ContractAddress,
            compound: ContractAddress,
            defence: ContractAddress,
            dockyard: ContractAddress,
            fleet: ContractAddress,
            planet: ContractAddress,
            tech: ContractAddress,
            erc721: ContractAddress,
            steel: ContractAddress,
            quartz: ContractAddress,
            tritium: ContractAddress,
            eth: ContractAddress,
            uni_speed: u128,
            token_price: u128,
        ) {
            self.ownable.assert_only_owner();
            self.planet_manager.write(IPlanetDispatcher { contract_address: planet });
            self.compound_manager.write(ICompoundDispatcher { contract_address: compound });
            self.defence_manager.write(IDefenceDispatcher { contract_address: defence });
            self.dockyard_manager.write(IDockyardDispatcher { contract_address: dockyard });
            self.fleet_manager.write(IFleetMovementsDispatcher { contract_address: fleet });
            self.colony_manager.write(IColonyDispatcher { contract_address: colony });
            self.tech_manager.write(ITechDispatcher { contract_address: tech });
            self.steel.write(IERC20NoGameDispatcher { contract_address: steel });
            self.quartz.write(IERC20NoGameDispatcher { contract_address: quartz });
            self.tritium.write(IERC20NoGameDispatcher { contract_address: tritium });
            self.eth.write(IERC20Dispatcher { contract_address: eth });
            self.erc721.write(IERC721NoGameDispatcher { contract_address: erc721 });
            self.token_price.write(token_price * E18);
            self.uni_speed.write(uni_speed);
        }

        fn upgrade(ref self: ContractState, impl_hash: ClassHash) {
            self.upgradeable.upgrade(impl_hash);
        }

        fn pay_resources_erc20(self: @ContractState, account: ContractAddress, amounts: ERC20s) {
            let tokens = self.get_tokens();
            tokens.steel.burn(account, (amounts.steel * E18).into());
            tokens.quartz.burn(account, (amounts.quartz * E18).into());
            tokens.tritium.burn(account, (amounts.tritium * E18).into());
        }

        fn receive_resources_erc20(
            self: @ContractState, account: ContractAddress, amounts: ERC20s,
        ) {
            let tokens = self.get_tokens();
            tokens.steel.mint(account, (amounts.steel * E18).into());
            tokens.quartz.mint(account, (amounts.quartz * E18).into());
            tokens.tritium.mint(account, (amounts.tritium * E18).into());
        }

        fn get_uni_speed(self: @ContractState) -> u128 {
            self.uni_speed.read()
        }

        fn get_contracts(self: @ContractState) -> Contracts {
            Contracts {
                game: super::IGameDispatcher { contract_address: get_contract_address() },
                planet: self.planet_manager.read(),
                compound: self.compound_manager.read(),
                dockyard: self.dockyard_manager.read(),
                defence: self.defence_manager.read(),
                fleet: self.fleet_manager.read(),
                colony: self.colony_manager.read(),
                tech: self.tech_manager.read(),
            }
        }

        fn get_tokens(self: @ContractState) -> Tokens {
            Tokens {
                erc721: self.erc721.read(),
                steel: self.steel.read(),
                quartz: self.quartz.read(),
                tritium: self.tritium.read(),
                eth: self.eth.read(),
            }
        }

        fn get_universe_start_time(self: @ContractState) -> u64 {
            self.universe_start_time.read()
        }

        fn get_token_price(self: @ContractState) -> u128 {
            self.token_price.read()
        }

        fn check_enough_resources(self: @ContractState, caller: ContractAddress, amounts: ERC20s) {
            let available: ERC20s = self.get_erc20s_available(caller);
            assert(amounts.steel <= available.steel / E18, 'Not enough steel');
            assert(amounts.quartz <= available.quartz / E18, 'Not enough quartz');
            assert(amounts.tritium <= available.tritium / E18, 'Not enough tritium');
        }
    }

    #[generate_trait]
    impl Private of PrivateTrait {
        fn get_erc20s_available(self: @ContractState, caller: ContractAddress) -> ERC20s {
            let tokens = self.get_tokens();
            let steel = IERC20Dispatcher { contract_address: tokens.steel.contract_address }
                .balance_of(caller);
            let quartz = IERC20Dispatcher { contract_address: tokens.quartz.contract_address }
                .balance_of(caller);
            let tritium = IERC20Dispatcher { contract_address: tokens.tritium.contract_address }
                .balance_of(caller);

            ERC20s {
                steel: steel.try_into().unwrap(),
                quartz: quartz.try_into().unwrap(),
                tritium: tritium.try_into().unwrap(),
            }
        }
    }
}

