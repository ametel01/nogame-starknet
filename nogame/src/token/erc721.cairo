use array::ArrayTrait;
use core::traits::Into;
use starknet::ContractAddress;

#[starknet::interface]
trait IERC721<T> {
    fn name(self: @T) -> felt252;
    fn symbol(self: @T) -> felt252;
    fn token_uri(self: @T, token_id: u256) -> Array<felt252>;
    fn balance_of(self: @T, account: ContractAddress) -> u256;
    fn token_of(self: @T, address: ContractAddress) -> u256;
    fn owner_of(self: @T, token_id: u256) -> ContractAddress;
    fn get_approved(self: @T, token_id: u256) -> ContractAddress;
    fn is_approved_for_all(self: @T, owner: ContractAddress, operator: ContractAddress) -> bool;
    fn admin(self: @T) -> ContractAddress;
    fn set_approval_for_all(ref self: T, operator: ContractAddress, approved: bool);
    fn approve(ref self: T, to: ContractAddress, token_id: u256);
    fn transfer_from(ref self: T, from: ContractAddress, to: ContractAddress, token_id: u256);
    fn set_minter(ref self: T, address: ContractAddress);
    fn mint(ref self: T, _to: ContractAddress, token_id: u256);
}

#[starknet::contract]
mod ERC721 {
    use array::ArrayTrait;
    use core::traits::TryInto;
    use option::OptionTrait;
    use starknet::{ContractAddress, get_caller_address};
    use core::zeroable::Zeroable;
    use core::traits::Into;

    #[derive(Copy, Drop, Serde, storage_access::StorageAccess)]
    struct LongString {
        part1: felt252,
        part2: felt252
    }

    #[storage]
    struct Storage {
        _owners: LegacyMap::<u256, ContractAddress>,
        _tokens: LegacyMap::<ContractAddress, u256>,
        _balances: LegacyMap::<ContractAddress, u256>,
        _token_approvals: LegacyMap::<u256, ContractAddress>,
        _name: felt252,
        _symbol: felt252,
        _operator_approvals: LegacyMap::<(ContractAddress, ContractAddress), bool>,
        _minter: ContractAddress,
        _admin: ContractAddress,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        Transfer: Transfer,
        Approval: Approval,
        ApprovalForAll: ApprovalForAll
    }
    #[derive(Drop, starknet::Event)]
    struct Transfer {
        from: ContractAddress,
        to: ContractAddress,
        token_id: u256
    }

    #[derive(Drop, starknet::Event)]
    struct Approval {
        owner: ContractAddress,
        approved: ContractAddress,
        token_id: u256
    }

    #[derive(Drop, starknet::Event)]
    struct ApprovalForAll {
        owner: ContractAddress,
        operator: ContractAddress,
        approved: bool
    }

    #[constructor]
    fn constructor(
        ref self: ContractState, name: felt252, symbol: felt252, admin: ContractAddress
    ) {
        self._name.write(name);
        self._symbol.write(symbol);
        self._admin.write(admin);
    }

    #[external(v0)]
    impl ERC721 of super::IERC721<ContractState> {
        fn name(self: @ContractState) -> felt252 {
            self._name.read()
        }

        fn symbol(self: @ContractState) -> felt252 {
            self._symbol.read()
        }

        fn token_uri(self: @ContractState, token_id: u256) -> Array<felt252> {
            assert(PrivateFunctions::exists(self, token_id), 'ERC721: invalid token ID');
            let mut array = Default::default();
            array.append('ipfs://');
            array.append('QmUA4rfEYVtSKtjgck');
            array.append('PFEaZHir5bhFdWZMRcqMQp5wFpvu');
            array.append('/');
            array.append(token_id.try_into().unwrap());
            array.append('.json');
            array
        }

        fn balance_of(self: @ContractState, account: ContractAddress) -> u256 {
            assert(!account.is_zero(), 'ERC721: invalid account');
            self._balances.read(account)
        }

        fn owner_of(self: @ContractState, token_id: u256) -> ContractAddress {
            self._owners.read(token_id)
        }

        fn get_approved(self: @ContractState, token_id: u256) -> ContractAddress {
            assert(PrivateFunctions::exists(self, token_id), 'ERC721: invalid token ID');
            self._token_approvals.read(token_id)
        }

        fn is_approved_for_all(
            self: @ContractState, owner: ContractAddress, operator: ContractAddress
        ) -> bool {
            self._operator_approvals.read((owner, operator))
        }

        fn approve(ref self: ContractState, to: ContractAddress, token_id: u256) {
            PrivateFunctions::approve(ref self, to, token_id);
        }

        fn set_approval_for_all(
            ref self: ContractState, operator: ContractAddress, approved: bool
        ) {
            PrivateFunctions::set_approval_for_all(
                ref self, get_caller_address(), operator, approved
            )
        }
        fn admin(self: @ContractState) -> ContractAddress {
            self._admin.read()
        }
        fn transfer_from(
            ref self: ContractState, from: ContractAddress, to: ContractAddress, token_id: u256
        ) {
            assert(
                PrivateFunctions::is_approved_or_owner(@self, get_caller_address(), token_id),
                'ERC721: unauthorized caller'
            );
            PrivateFunctions::transfer(ref self, from, to, token_id);
        }

        fn set_minter(ref self: ContractState, address: ContractAddress) {
            assert(get_caller_address() == self._admin.read(), 'Caller is not admin');
            self._minter.write(address);
        }

        fn token_of(self: @ContractState, address: ContractAddress) -> u256 {
            self._tokens.read(address)
        }

        fn mint(ref self: ContractState, _to: ContractAddress, token_id: u256) {
            assert(get_caller_address() == self._minter.read(), 'caller is not minter');
            assert(!PrivateFunctions::exists(@self, token_id), 'ERC721: token already minted');
            assert(self._balances.read(_to) < 1, 'max tokens balance reached');
            // Update balances
            self._balances.write(_to, self._balances.read(_to) + 1);

            // Update token_id owner
            self._owners.write(token_id, _to);
            self._tokens.write(_to, token_id);

            // Emit event
            self.emit(Transfer { from: Zeroable::zero(), to: _to, token_id });
        }
    }

    #[generate_trait]
    impl PrivateFunctions of PrivateFunctionsTrait {
        fn exists(self: @ContractState, token_id: u256) -> bool {
            !self._owners.read(token_id).is_zero()
        }
        fn owner_of(self: @ContractState, token_id: u256) -> ContractAddress {
            let owner = self._owners.read(token_id);
            match owner.is_zero() {
                bool::False(()) => owner,
                bool::True(()) => panic_with_felt252('ERC721: invalid token ID')
            }
        }
        fn approve(ref self: ContractState, to: ContractAddress, token_id: u256) {
            let owner = self._owners.read(token_id);

            let caller = get_caller_address();
            assert(
                owner == caller || PrivateFunctions::is_approved_for_all(@self, owner, caller),
                'ERC721: unauthorized caller'
            );
            assert(owner != to, 'ERC721: approval to owner');
            self._token_approvals.write(token_id, to);
            self.emit(Approval { owner, approved: to, token_id });
        }
        fn set_approval_for_all(
            ref self: ContractState,
            owner: ContractAddress,
            operator: ContractAddress,
            approved: bool
        ) {
            assert(owner != operator, 'ERC721: self approval');
            self._operator_approvals.write((owner, operator), approved);
            self.emit(ApprovalForAll { owner, operator, approved });
        }
        fn is_approved_for_all(
            self: @ContractState, owner: ContractAddress, operator: ContractAddress
        ) -> bool {
            self._operator_approvals.read((owner, operator))
        }
        fn is_approved_or_owner(
            self: @ContractState, spender: ContractAddress, token_id: u256
        ) -> bool {
            let owner = ERC721::owner_of(self, token_id);
            owner == spender
                || PrivateFunctions::is_approved_for_all(self, owner, spender)
                || spender == ERC721::get_approved(self, token_id)
        }
        fn transfer(
            ref self: ContractState, from: ContractAddress, to: ContractAddress, token_id: u256
        ) {
            assert(!to.is_zero(), 'ERC721: invalid receiver');
            let owner = ERC721::owner_of(@self, token_id);
            assert(from == owner, 'ERC721: wrong sender');

            // Implicit clear approvals, no need to emit an event
            self._token_approvals.write(token_id, Zeroable::zero());

            // Update balances
            self._balances.write(from, self._balances.read(from) - 1);
            self._balances.write(to, self._balances.read(to) + 1);

            // Update token_id owner
            self._owners.write(token_id, to);

            // Emit event
            self.emit(Transfer { from, to, token_id });
        }
    }
}

