#[starknet::contract]
mod ERC20NoGame {
    use starknet::{ContractAddress, get_caller_address};
    use openzeppelin::token::erc20::erc20::ERC20Component;

    use nogame::token::erc20::interface::IERC20NoGame;
    use nogame::token::erc721::interface::{IERC721NoGameDispatcher, IERC721NoGameDispatcherTrait};

    component!(path: ERC20Component, storage: erc20, event: ERC20Event);

    #[abi(embed_v0)]
    impl ERC20Impl = ERC20Component::ERC20Impl<ContractState>;

    #[abi(embed_v0)]
    impl SafeAllowanceImpl = ERC20Component::SafeAllowanceImpl<ContractState>;

    #[abi(embed_v0)]
    impl ERC20MetadataImpl = ERC20Component::ERC20MetadataImpl<ContractState>;

    impl InternalImpl = ERC20Component::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        minter: ContractAddress,
        nft: IERC721NoGameDispatcher,
        #[substorage(v0)]
        erc20: ERC20Component::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        ERC20Event: ERC20Component::Event,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        name: felt252,
        symbol: felt252,
        minter: ContractAddress,
        nft_address: ContractAddress
    ) {
        self.erc20.initializer(name, symbol);
        self.minter.write(minter);
        self.nft.write(IERC721NoGameDispatcher { contract_address: nft_address });
    }

    impl ERC20NoGameImpl of IERC20NoGame<ContractState> {
        fn name(self: @ContractState) -> felt252 {
            self.erc20.name()
        }

        fn symbol(self: @ContractState) -> felt252 {
            self.erc20.symbol()
        }

        fn decimals(self: @ContractState) -> u8 {
            self.erc20.decimals()
        }

        fn total_supply(self: @ContractState) -> u256 {
            self.erc20.total_supply()
        }

        fn balance_of(self: @ContractState, account: ContractAddress) -> u256 {
            self.erc20.balance_of(account)
        }

        fn allowance(
            self: @ContractState, owner: ContractAddress, spender: ContractAddress
        ) -> u256 {
            self.erc20.allowance(owner, spender)
        }

        fn transfer(ref self: ContractState, recipient: ContractAddress, amount: u256) -> bool {
            assert(
                !self.nft.read().balance_of(recipient).is_zero(), 'recipient is not planet owner'
            );
            self.erc20.transfer(recipient, amount)
        }

        fn transfer_from(
            ref self: ContractState,
            sender: ContractAddress,
            recipient: ContractAddress,
            amount: u256
        ) -> bool {
            assert(
                !self.nft.read().balance_of(recipient).is_zero(), 'recipient is not planet owner'
            );
            self.erc20.transfer_from(sender, recipient, amount)
        }

        fn approve(ref self: ContractState, spender: ContractAddress, amount: u256) -> bool {
            self.erc20.approve(spender, amount)
        }

        fn increase_allowance(
            ref self: ContractState, spender: ContractAddress, added_value: u256
        ) -> bool {
            self.erc20.increase_allowance(spender, added_value)
        }

        fn decrease_allowance(
            ref self: ContractState, spender: ContractAddress, subtracted_value: u256
        ) -> bool {
            self.erc20.decrease_allowance(spender, subtracted_value)
        }
        // IERC20CamelOnly
        fn totalSupply(self: @ContractState) -> u256 {
            self.erc20.total_supply()
        }
        fn balanceOf(self: @ContractState, account: ContractAddress) -> u256 {
            self.erc20.balance_of(account)
        }

        fn transferFrom(
            ref self: ContractState,
            sender: ContractAddress,
            recipient: ContractAddress,
            amount: u256
        ) -> bool {
            self.erc20.transfer_from(sender, recipient, amount)
        }


        fn increaseAllowance(
            ref self: ContractState, spender: ContractAddress, addedValue: u256
        ) -> bool {
            self.erc20.increase_allowance(spender, addedValue)
        }

        fn decreaseAllowance(
            ref self: ContractState, spender: ContractAddress, subtractedValue: u256
        ) -> bool {
            self.erc20.decrease_allowance(spender, subtractedValue)
        }

        // IERC20NG
        fn mint(ref self: ContractState, recipient: ContractAddress, amount: u256) {
            assert(get_caller_address() == self.minter.read(), 'caller is not minter');
            self.erc20._mint(recipient, amount)
        }
        fn burn(ref self: ContractState, account: ContractAddress, amount: u256) {
            assert(get_caller_address() == self.minter.read(), 'caller is not minter');
            self.erc20._burn(account, amount);
        }
    }
}
