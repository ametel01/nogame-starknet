use core::traits::Into;
use starknet::ContractAddress;

#[starknet::interface]
trait IERC20<T> {
    fn name(self: @T) -> felt252;
    fn symbol(self: @T) -> felt252;
    fn decimals(self: @T) -> u8;
    fn total_supply(self: @T) -> u256;
    fn balances(self: @T, account: ContractAddress) -> u256;
    fn admin(self: @T) -> ContractAddress;
    fn transfer(ref self: T, recipient: ContractAddress, amount: u256) -> bool;
    fn allowances(self: @T, owner: ContractAddress, spender: ContractAddress) -> u256;
    fn approve(ref self: T, spender: ContractAddress, amount: u256) -> bool;
    fn increase_allowance(ref self: T, spender: ContractAddress, added_value: u256) -> bool;
    fn decrease_allowance(ref self: T, spender: ContractAddress, substracted_value: u256) -> bool;
    fn transfer_from(
        ref self: T, sender: ContractAddress, recipient: ContractAddress, amount: u256
    ) -> bool;
    fn mint(ref self: T, recipient: ContractAddress, amount: u256);
    fn burn(ref self: T, account: ContractAddress, amount: u256);
    fn set_minter(ref self: T, address: ContractAddress);
}

#[starknet::contract]
mod ERC20 {
    use core::integer::{U256Add, U256Sub};
    use core::zeroable::Zeroable;
    use integer::BoundedInt;
    use option::OptionTrait;
    use starknet::{ContractAddress, get_caller_address};
    use starknet::contract_address::ContractAddressZeroable;
    use traits::TryInto;

    #[storage]
    struct Storage {
        _name: felt252,
        _symbol: felt252,
        _decimals: u8,
        _admin: ContractAddress,
        _total_supply: u256,
        _balances: LegacyMap::<ContractAddress, u256>,
        _allowances: LegacyMap::<(ContractAddress, ContractAddress), u256>,
        _minter: ContractAddress,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        Transfer: Transfer,
        Approval: Approval,
    }

    #[derive(Drop, starknet::Event)]
    struct Transfer {
        from: ContractAddress,
        to: ContractAddress,
        value: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct Approval {
        owner: ContractAddress,
        spender: ContractAddress,
        value: u256,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState, name: felt252, symbol: felt252, admin: ContractAddress
    ) {
        self._name.write(name);
        self._symbol.write(symbol);
        self._decimals.write(18_u8);
        self._admin.write(admin);
    }

    #[external(v0)]
    impl ERC20Impl of super::IERC20<ContractState> {
        fn name(self: @ContractState) -> felt252 {
            self._name.read()
        }
        fn symbol(self: @ContractState) -> felt252 {
            self._symbol.read()
        }
        fn decimals(self: @ContractState) -> u8 {
            18_u8
        }
        fn total_supply(self: @ContractState) -> u256 {
            self._total_supply.read()
        }
        fn allowances(
            self: @ContractState, owner: ContractAddress, spender: ContractAddress
        ) -> u256 {
            self._allowances.read((owner, spender))
        }
        fn admin(self: @ContractState) -> ContractAddress {
            self._admin.read()
        }
        fn transfer(ref self: ContractState, recipient: ContractAddress, amount: u256) -> bool {
            let sender = get_caller_address();
            assert(!sender.is_zero(), 'ERC20: transfer from 0');
            assert(!recipient.is_zero(), 'ERC20: transfer to 0');
            self._balances.write(sender, self._balances.read(sender) - amount);
            self._balances.write(recipient, self._balances.read(recipient) + amount);
            self.emit(Event::Transfer(Transfer { from: sender, to: recipient, value: amount }));
            true
        }
        fn increase_allowance(
            ref self: ContractState, spender: ContractAddress, added_value: u256
        ) -> bool {
            let caller = get_caller_address();
            let current_allowance = self._allowances.read((caller, spender));
            let new_allowance = U256Add::add(current_allowance, added_value);
            assert(!caller.is_zero(), 'ERC20: approve from 0');
            assert(!caller.is_zero(), 'ERC20: approve to 0');
            self._allowances.write((caller, spender), new_allowance);
            true
        }
        fn decrease_allowance(
            ref self: ContractState, spender: ContractAddress, substracted_value: u256
        ) -> bool {
            let caller = get_caller_address();
            let current_allowance = self._allowances.read((caller, spender));
            let new_allowance = U256Sub::sub(current_allowance, substracted_value);
            assert(!caller.is_zero(), 'ERC20: approve from 0');
            assert(!caller.is_zero(), 'ERC20: approve to 0');
            self._allowances.write((caller, spender), new_allowance);
            true
        }
        fn set_minter(ref self: ContractState, address: ContractAddress) {
            assert(get_caller_address() == self._admin.read(), 'Caller is not admin');
            self._minter.write(address);
        }
        fn balances(self: @ContractState, account: ContractAddress) -> u256 {
            self._balances.read(account)
        }

        fn approve(ref self: ContractState, spender: ContractAddress, amount: u256) -> bool {
            let caller = get_caller_address();
            assert(!caller.is_zero(), 'ERC20: approve from 0');
            assert(!spender.is_zero(), 'ERC20: approve to 0');
            self._allowances.write((caller, spender), amount);
            true
        }

        fn transfer_from(
            ref self: ContractState,
            sender: ContractAddress,
            recipient: ContractAddress,
            amount: u256
        ) -> bool {
            let sender = get_caller_address();
            let current_allowance = self._allowances.read((sender, recipient));
            if current_allowance != BoundedInt::max() {
                assert(!sender.is_zero(), 'ERC20: approve from 0');
                assert(!recipient.is_zero(), 'ERC20: approve to 0');
                self._allowances.write((sender, recipient), amount);
                self
                    .emit(
                        Event::Approval(
                            Approval { owner: sender, spender: recipient, value: amount }
                        )
                    );
            }
            true
        }

        fn mint(ref self: ContractState, recipient: ContractAddress, amount: u256) {
            let caller = get_caller_address();
            assert(caller == self._minter.read(), 'ERC20: caller not minter');
            assert(!recipient.is_zero(), 'ERC20: mint to 0');
            let new_supply = U256Add::add(self._total_supply.read(), amount);
            self._total_supply.write(new_supply);
            let new_balance = U256Add::add(self._balances.read(recipient), amount);
            self._balances.write(recipient, new_balance);
            self
                .emit(
                    Event::Transfer(
                        Transfer {
                            from: ContractAddressZeroable::zero(), to: recipient, value: amount
                        }
                    )
                );
        }

        fn burn(ref self: ContractState, account: ContractAddress, amount: u256) {
            let caller = get_caller_address();
            assert(caller == self._minter.read(), 'ERC20: caller not minter');
            assert(!account.is_zero(), 'ERC20: mint to 0');
            let new_supply = U256Sub::sub(self._total_supply.read(), amount);
            self._total_supply.write(new_supply);
            let new_balance = U256Sub::sub(self._balances.read(account), amount);
            self._balances.write(account, new_balance);
            self
                .emit(
                    Event::Transfer(
                        Transfer {
                            from: account, to: ContractAddressZeroable::zero(), value: amount
                        }
                    )
                );
        }
    }
}
