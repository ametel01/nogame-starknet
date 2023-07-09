use core::traits::Into;
use starknet::ContractAddress;

#[starknet::interface]
trait IERC721<TContractState> {
    fn name(self: @TContractState) -> felt252;
    fn symbol(self: @TContractState) -> felt252;
    fn approve(ref self: TContractState, to: ContractAddress, token_id: u256);
    fn balance_of(self: @TContractState, account: ContractAddress) -> u256;
    fn owner_of(self: @TContractState, token_id: u256) -> ContractAddress;
    fn transfer_from(
        ref self: TContractState, from: ContractAddress, to: ContractAddress, token_id: u256
    );
    fn set_approval_for_all(ref self: TContractState, operator: ContractAddress, approved: bool);
    fn get_approved(self: @TContractState, token_id: u256) -> ContractAddress;
    fn is_approved_for_all(
        self: @TContractState, owner: ContractAddress, operator: ContractAddress
    ) -> bool;
    fn token_uri(self: @TContractState, token_id: u256) -> felt252;
    fn token_of(self: @TContractState, address: ContractAddress) -> u256;
    fn mint(ref self: TContractState, token_id: u256);
}

#[starknet::contract]
mod ERC721 {
    use starknet::{ContractAddress, get_caller_address};
    use core::zeroable::Zeroable;
    use core::traits::Into;

    #[storage]
    struct Storage {
        _owners: LegacyMap<u256, ContractAddress>,
        _tokens: LegacyMap::<ContractAddress, u256>,
        _balances: LegacyMap<ContractAddress, u256>,
        _token_approvals: LegacyMap<u256, ContractAddress>,
        _name: felt252,
        _symbol: felt252,
        _operator_approvals: LegacyMap<(ContractAddress, ContractAddress), bool>,
        _token_uri: LegacyMap<u256, felt252>,
        _minter: ContractAddress,
        _owner: ContractAddress,
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
        ref self: ContractState,
        name: felt252,
        symbol: felt252,
        minter: ContractAddress,
        owner: ContractAddress
    ) {
        self._name.write(name);
        self._symbol.write(symbol);
        self._minter.write(minter);
        self._owner.write(owner);
    }

    #[external(v0)]
    fn name(self: @ContractState) -> felt252 {
        self._name.read()
    }

    #[external(v0)]
    fn symbol(self: @ContractState) -> felt252 {
        self._symbol.read()
    }

    #[external(v0)]
    fn token_uri(self: @ContractState, token_id: u256) -> felt252 {
        assert(exists(self, token_id), 'ERC721: invalid token ID');
        self._token_uri.read(token_id)
    }

    #[external(v0)]
    fn balance_of(self: @ContractState, account: ContractAddress) -> u256 {
        assert(!account.is_zero(), 'ERC721: invalid account');
        self._balances.read(account)
    }

    #[external(v0)]
    fn owner_of(self: @ContractState, token_id: u256) -> ContractAddress {
        owner_of(self, token_id)
    }

    #[external(v0)]
    fn token_of(self: @ContractState, address: ContractAddress) -> u256 {
        self._tokens.read(address)
    }

    #[external(v0)]
    fn get_approved(self: @ContractState, token_id: u256) -> ContractAddress {
        assert(exists(self, token_id), 'ERC721: invalid token ID');
        self._token_approvals.read(token_id)
    }

    #[external(v0)]
    fn is_approved_for_all(
        self: @ContractState, owner: ContractAddress, operator: ContractAddress
    ) -> bool {
        self._operator_approvals.read((owner, operator))
    }

    #[external(v0)]
    fn approve(ref self: ContractState, to: ContractAddress, token_id: u256) {
        let owner = owner_of(@self, token_id);

        let caller = get_caller_address();
        assert(
            owner == caller || is_approved_for_all(@self, owner, caller),
            'ERC721: unauthorized caller'
        );
        approve(ref self, to, token_id);
    }

    #[external(v0)]
    fn set_approval_for_all(ref self: ContractState, operator: ContractAddress, approved: bool) {
        _set_approval_for_all(ref self, get_caller_address(), operator, approved)
    }

    #[external(v0)]
    fn transfer_from(
        ref self: ContractState, from: ContractAddress, to: ContractAddress, token_id: u256
    ) {
        assert(
            is_approved_or_owner(@self, get_caller_address(), token_id),
            'ERC721: unauthorized caller'
        );
        transfer(ref self, from, to, token_id);
    }

    #[external(v0)]
    fn mint(ref self: ContractState, token_id: u256) {
        let minter = self._minter.read();
        let owner = self._owner.read();
        assert(get_caller_address() == minter, 'caller is not admin');
        assert(!exists(@self, token_id), 'ERC721: token already minted');

        // Update balances
        self._balances.write(owner, self._balances.read(owner) + 1);

        // Update token_id owner
        self._owners.write(token_id, owner);

        // Emit event
        self.emit(Transfer { from: Zeroable::zero(), to: owner, token_id });
    }


    fn exists(self: @ContractState, token_id: u256) -> bool {
        !self._owners.read(token_id).is_zero()
    }
    fn _owner_of(self: @ContractState, token_id: u256) -> ContractAddress {
        let owner = self._owners.read(token_id);
        match owner.is_zero() {
            bool::False(()) => owner,
            bool::True(()) => panic_with_felt252('ERC721: invalid token ID')
        }
    }
    fn _approve(ref self: ContractState, to: ContractAddress, token_id: u256) {
        let owner = owner_of(@self, token_id);
        assert(owner != to, 'ERC721: approval to owner');
        self._token_approvals.write(token_id, to);
        self.emit(Approval { owner, approved: to, token_id });
    }
    fn _set_approval_for_all(
        ref self: ContractState, owner: ContractAddress, operator: ContractAddress, approved: bool
    ) {
        assert(owner != operator, 'ERC721: self approval');
        self._operator_approvals.write((owner, operator), approved);
        self.emit(ApprovalForAll { owner, operator, approved });
    }
    fn _is_approved_for_all(
        self: @ContractState, owner: ContractAddress, operator: ContractAddress
    ) -> bool {
        self._operator_approvals.read((owner, operator))
    }
    fn is_approved_or_owner(
        self: @ContractState, spender: ContractAddress, token_id: u256
    ) -> bool {
        let owner = owner_of(self, token_id);
        owner == spender
            || is_approved_for_all(self, owner, spender)
            || spender == get_approved(self, token_id)
    }
    fn transfer(
        ref self: ContractState, from: ContractAddress, to: ContractAddress, token_id: u256
    ) {
        assert(!to.is_zero(), 'ERC721: invalid receiver');
        let owner = owner_of(@self, token_id);
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

