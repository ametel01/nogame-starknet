//! SPDX-License-Identifier: MIT
//! OpenZeppelin Contracts for Cairo v0.7.0 (token/erc20/erc20.cairo)
//!
//! # ERC20 Contract and Implementation
//!
//! This ERC20 contract includes both a library and a basic preset implementation.
//! The library is agnostic regarding how tokens are created; however,
//! the preset implementation sets the initial supply in the constructor.
//! A derived contract can use [_mint](_mint) to create a different supply mechanism.
#[starknet::contract]
mod ERC20NG {
    use integer::BoundedInt;
    use openzeppelin::token::erc20::interface::IERC20;
    use openzeppelin::token::erc20::interface::IERC20CamelOnly;
    use starknet::ContractAddress;
    use starknet::get_caller_address;

    use nogame::token::erc721::interface::{IERC721NoGameDispatcher, IERC721NoGameDispatcherTrait};
    use nogame::token::erc20::interface::IERC20NG;

    #[storage]
    struct Storage {
        ERC20_name: felt252,
        ERC20_symbol: felt252,
        ERC20_total_supply: u256,
        ERC20_balances: LegacyMap<ContractAddress, u256>,
        ERC20_allowances: LegacyMap<(ContractAddress, ContractAddress), u256>,
        ERC20_minter: ContractAddress,
        ERC20_nft: IERC721NoGameDispatcher,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        Transfer: Transfer,
        Approval: Approval,
    }

    /// Emitted when tokens are moved from address `from` to address `to`.
    #[derive(Drop, starknet::Event)]
    struct Transfer {
        #[key]
        from: ContractAddress,
        #[key]
        to: ContractAddress,
        value: u256
    }

    /// Emitted when the allowance of a `spender` for an `owner` is set by a call
    /// to [approve](approve). `value` is the new allowance.
    #[derive(Drop, starknet::Event)]
    struct Approval {
        #[key]
        owner: ContractAddress,
        #[key]
        spender: ContractAddress,
        value: u256
    }

    mod Errors {
        const APPROVE_FROM_ZERO: felt252 = 'ERC20: approve from 0';
        const APPROVE_TO_ZERO: felt252 = 'ERC20: approve to 0';
        const TRANSFER_FROM_ZERO: felt252 = 'ERC20: transfer from 0';
        const TRANSFER_TO_ZERO: felt252 = 'ERC20: transfer to 0';
        const BURN_FROM_ZERO: felt252 = 'ERC20: burn from 0';
        const MINT_TO_ZERO: felt252 = 'ERC20: mint to 0';
        const RECEPIENT_NOT_PLANET_OWNER: felt252 = 'recepient not Planet owner';
    }

    /// Initializes the state of the ERC20 contract. This includes setting the
    /// initial supply of tokens as well as the recipient of the initial supply.
    #[constructor]
    fn constructor(
        ref self: ContractState,
        name: felt252,
        symbol: felt252,
        minter: ContractAddress,
        nft_address: ContractAddress
    ) {
        self.initializer(name, symbol, minter, nft_address);
    }

    //
    // External
    //

    #[external(v0)]
    impl ERC20NGImpl of IERC20NG<ContractState> {
        /// Returns the name of the token.
        fn name(self: @ContractState) -> felt252 {
            self.ERC20_name.read()
        }

        /// Returns the ticker symbol of the token, usually a shorter version of the name.
        fn symbol(self: @ContractState) -> felt252 {
            self.ERC20_symbol.read()
        }

        /// Returns the number of decimals used to get its user representation.
        fn decimals(self: @ContractState) -> u8 {
            18
        }

        /// Returns the value of tokens in existence.
        fn total_supply(self: @ContractState) -> u256 {
            self.ERC20_total_supply.read()
        }

        /// Returns the amount of tokens owned by `account`.
        fn balance_of(self: @ContractState, account: ContractAddress) -> u256 {
            self.ERC20_balances.read(account)
        }

        /// Returns the remaining number of tokens that `spender` is
        /// allowed to spend on behalf of `owner` through [transfer_from](transfer_from).
        /// This is zero by default.
        /// This value changes when [approve](approve) or [transfer_from](transfer_from)
        /// are called.
        fn allowance(
            self: @ContractState, owner: ContractAddress, spender: ContractAddress
        ) -> u256 {
            self.ERC20_allowances.read((owner, spender))
        }

        /// Moves `amount` tokens from the caller's token balance to `to`.
        /// Emits a [Transfer](Transfer) event.
        fn transfer(ref self: ContractState, recipient: ContractAddress, amount: u256) -> bool {
            let sender = get_caller_address();
            self._transfer(sender, recipient, amount);
            true
        }

        /// Moves `amount` tokens from `from` to `to` using the allowance mechanism.
        /// `amount` is then deducted from the caller's allowance.
        /// Emits a [Transfer](Transfer) event.
        fn transfer_from(
            ref self: ContractState,
            sender: ContractAddress,
            recipient: ContractAddress,
            amount: u256
        ) -> bool {
            let caller = get_caller_address();
            self._spend_allowance(sender, caller, amount);
            self._transfer(sender, recipient, amount);
            true
        }

        /// Sets `amount` as the allowance of `spender` over the caller’s tokens.
        fn approve(ref self: ContractState, spender: ContractAddress, amount: u256) -> bool {
            let caller = get_caller_address();
            self._approve(caller, spender, amount);
            true
        }

        fn increase_allowance(
            ref self: ContractState, spender: ContractAddress, added_value: u256
        ) -> bool {
            self._increase_allowance(spender, added_value)
        }

        fn decrease_allowance(
            ref self: ContractState, spender: ContractAddress, subtracted_value: u256
        ) -> bool {
            self._decrease_allowance(spender, subtracted_value)
        }

        fn totalSupply(self: @ContractState) -> u256 {
            self.total_supply()
        }

        fn balanceOf(self: @ContractState, account: ContractAddress) -> u256 {
            self.balance_of(account)
        }

        fn transferFrom(
            ref self: ContractState,
            sender: ContractAddress,
            recipient: ContractAddress,
            amount: u256
        ) -> bool {
            self.transfer_from(sender, recipient, amount)
        }

        fn increaseAllowance(
            ref self: ContractState, spender: ContractAddress, addedValue: u256
        ) -> bool {
            self.increase_allowance(spender, addedValue)
        }

        fn decreaseAllowance(
            ref self: ContractState, spender: ContractAddress, subtractedValue: u256
        ) -> bool {
            self.decrease_allowance(spender, subtractedValue)
        }

        fn mint(ref self: ContractState, recipient: ContractAddress, amount: u256) {
            self._mint(recipient, amount);
        }

        fn burn(ref self: ContractState, account: ContractAddress, amount: u256) {
            self._burn(account, amount);
        }
    }

    //
    // Internal
    //

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        /// Initializes the contract by setting the token name and symbol.
        /// To prevent reinitialization, this should only be used inside of a contract's constructor.
        fn initializer(
            ref self: ContractState,
            name: felt252,
            symbol: felt252,
            minter: ContractAddress,
            nft_address: ContractAddress
        ) {
            self.ERC20_name.write(name);
            self.ERC20_symbol.write(symbol);
            self.ERC20_minter.write(minter);
            self.ERC20_nft.write(IERC721NoGameDispatcher { contract_address: nft_address });
        }

        /// Internal method that moves an `amount` of tokens from `from` to `to`.
        /// Emits a [Transfer](Transfer) event.
        fn _transfer(
            ref self: ContractState,
            sender: ContractAddress,
            recipient: ContractAddress,
            amount: u256
        ) {
            assert(!sender.is_zero(), Errors::TRANSFER_FROM_ZERO);
            assert(!recipient.is_zero(), Errors::TRANSFER_TO_ZERO);
            assert(
                !self.ERC20_nft.read().balanceOf(recipient).is_zero(),
                Errors::RECEPIENT_NOT_PLANET_OWNER
            );
            self.ERC20_balances.write(sender, self.ERC20_balances.read(sender) - amount);
            self.ERC20_balances.write(recipient, self.ERC20_balances.read(recipient) + amount);
            self.emit(Transfer { from: sender, to: recipient, value: amount });
        }

        /// Internal method that sets `amount` as the allowance of `spender` over the
        /// `owner`s tokens.
        /// Emits an [Approval](Approval) event.
        fn _approve(
            ref self: ContractState, owner: ContractAddress, spender: ContractAddress, amount: u256
        ) {
            assert(!owner.is_zero(), Errors::APPROVE_FROM_ZERO);
            assert(!spender.is_zero(), Errors::APPROVE_TO_ZERO);
            self.ERC20_allowances.write((owner, spender), amount);
            self.emit(Approval { owner, spender, value: amount });
        }

        /// Creates a `value` amount of tokens and assigns them to `account`.
        /// Emits a [Transfer](Transfer) event with `from` set to the zero address.
        fn _mint(ref self: ContractState, recipient: ContractAddress, amount: u256) {
            assert(get_caller_address() == self.ERC20_minter.read(), 'ERC20: caller not minter');
            assert(!recipient.is_zero(), Errors::MINT_TO_ZERO);
            self.ERC20_total_supply.write(self.ERC20_total_supply.read() + amount);
            self.ERC20_balances.write(recipient, self.ERC20_balances.read(recipient) + amount);
            self.emit(Transfer { from: Zeroable::zero(), to: recipient, value: amount });
        }

        /// Destroys a `value` amount of tokens from `account`.
        /// Emits a [Transfer](Transfer) event with `to` set to the zero address.
        fn _burn(ref self: ContractState, account: ContractAddress, amount: u256) {
            assert(get_caller_address() == self.ERC20_minter.read(), 'ERC20: caller not minter');
            assert(!account.is_zero(), Errors::BURN_FROM_ZERO);
            self.ERC20_total_supply.write(self.ERC20_total_supply.read() - amount);
            self.ERC20_balances.write(account, self.ERC20_balances.read(account) - amount);
            self.emit(Transfer { from: account, to: Zeroable::zero(), value: amount });
        }

        /// Internal method for the external [increase_allowance](increase_allowance).
        /// Emits an [Approval](Approval) event indicating the updated allowance.
        fn _increase_allowance(
            ref self: ContractState, spender: ContractAddress, added_value: u256
        ) -> bool {
            let caller = get_caller_address();
            self
                ._approve(
                    caller, spender, self.ERC20_allowances.read((caller, spender)) + added_value
                );
            true
        }

        /// Internal method for the external [decrease_allowance](decrease_allowance).
        /// Emits an [Approval](Approval) event indicating the updated allowance.
        fn _decrease_allowance(
            ref self: ContractState, spender: ContractAddress, subtracted_value: u256
        ) -> bool {
            let caller = get_caller_address();
            self
                ._approve(
                    caller,
                    spender,
                    self.ERC20_allowances.read((caller, spender)) - subtracted_value
                );
            true
        }

        /// Updates `owner`s allowance for `spender` based on spent `amount`.
        /// Does not update the allowance value in case of infinite allowance.
        /// Possibly emits an [Approval](Approval) event.
        fn _spend_allowance(
            ref self: ContractState, owner: ContractAddress, spender: ContractAddress, amount: u256
        ) {
            let current_allowance = self.ERC20_allowances.read((owner, spender));
            if current_allowance != BoundedInt::max() {
                self._approve(owner, spender, current_allowance - amount);
            }
        }
    }
}
