use starknet::ContractAddress;

#[starknet::interface]
trait INGERC721<T> {
    fn name(self: @T) -> felt252;
    fn symbol(self: @T) -> felt252;
    fn token_uri(self: @T, token_id: u256) -> felt252;
    fn balance_of(self: @T, account: ContractAddress) -> u256;
    fn owner_of(self: @T, token_id: u256) -> ContractAddress;
    fn transfer_from(ref self: T, from: ContractAddress, to: ContractAddress, token_id: u256);
    fn safe_transfer_from(
        ref self: T, from: ContractAddress, to: ContractAddress, token_id: u256, data: Span<felt252>
    );
    fn approve(ref self: T, to: ContractAddress, token_id: u256);
    fn set_approval_for_all(ref self: T, operator: ContractAddress, approved: bool);
    fn get_approved(self: @T, token_id: u256) -> ContractAddress;
    fn is_approved_for_all(self: @T, owner: ContractAddress, operator: ContractAddress) -> bool;
    fn token_of(self: @T, address: ContractAddress) -> u256;
    fn base_uri(self: @T) -> felt252;
    fn set_minter(ref self: T, address: ContractAddress);
    fn set_base_uri(ref self: T, uri: felt252);
    fn mint(ref self: T, to: ContractAddress, token_id: u256);
}

#[starknet::contract]
mod NGERC721 {
    use array::SpanTrait;
    use openzeppelin::account;
    use openzeppelin::introspection::dual_src5::DualCaseSRC5;
    use openzeppelin::introspection::dual_src5::DualCaseSRC5Trait;
    use openzeppelin::introspection::interface::ISRC5;
    use openzeppelin::introspection::interface::ISRC5Camel;
    use openzeppelin::introspection::src5;
    use openzeppelin::token::erc721::dual721_receiver::DualCaseERC721Receiver;
    use openzeppelin::token::erc721::dual721_receiver::DualCaseERC721ReceiverTrait;
    use openzeppelin::token::erc721::interface;
    use option::OptionTrait;
    use starknet::ContractAddress;
    use starknet::get_caller_address;
    use zeroable::Zeroable;

    #[storage]
    struct Storage {
        _name: felt252,
        _symbol: felt252,
        _owners: LegacyMap<u256, ContractAddress>,
        _tokens: LegacyMap<ContractAddress, u256>,
        _balances: LegacyMap<ContractAddress, u256>,
        _token_approvals: LegacyMap<u256, ContractAddress>,
        _operator_approvals: LegacyMap<(ContractAddress, ContractAddress), bool>,
        _token_uri: LegacyMap<u256, felt252>,
        _minter: ContractAddress,
        _base_uri: felt252,
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
        ref self: ContractState, name: felt252, symbol: felt252, minter: ContractAddress
    ) {
        self.initializer(name, symbol, minter);
    }

    //
    // External
    //

    #[external(v0)]
    impl SRC5Impl of ISRC5<ContractState> {
        fn supports_interface(self: @ContractState, interface_id: felt252) -> bool {
            let unsafe_state = src5::SRC5::unsafe_new_contract_state();
            src5::SRC5::SRC5Impl::supports_interface(@unsafe_state, interface_id)
        }
    }
    #[external(v0)]
    impl NGERC721Impl of super::INGERC721<ContractState> {
        fn name(self: @ContractState) -> felt252 {
            self._name.read()
        }

        fn symbol(self: @ContractState) -> felt252 {
            self._symbol.read()
        }

        fn token_uri(self: @ContractState, token_id: u256) -> felt252 {
            assert(self._exists(token_id), 'ERC721: invalid token ID');
            self._token_uri.read(token_id)
        }


        fn balance_of(self: @ContractState, account: ContractAddress) -> u256 {
            assert(!account.is_zero(), 'ERC721: invalid account');
            self._balances.read(account)
        }

        fn owner_of(self: @ContractState, token_id: u256) -> ContractAddress {
            self._owner_of(token_id)
        }

        fn get_approved(self: @ContractState, token_id: u256) -> ContractAddress {
            assert(self._exists(token_id), 'ERC721: invalid token ID');
            self._token_approvals.read(token_id)
        }

        fn is_approved_for_all(
            self: @ContractState, owner: ContractAddress, operator: ContractAddress
        ) -> bool {
            self._operator_approvals.read((owner, operator))
        }

        fn approve(ref self: ContractState, to: ContractAddress, token_id: u256) {
            let owner = self._owner_of(token_id);

            let caller = get_caller_address();
            assert(
                owner == caller || NGERC721Impl::is_approved_for_all(@self, owner, caller),
                'ERC721: unauthorized caller'
            );
            self._approve(to, token_id);
        }

        fn set_approval_for_all(
            ref self: ContractState, operator: ContractAddress, approved: bool
        ) {
            self._set_approval_for_all(get_caller_address(), operator, approved)
        }

        fn transfer_from(
            ref self: ContractState, from: ContractAddress, to: ContractAddress, token_id: u256
        ) {
            assert(
                self._is_approved_or_owner(get_caller_address(), token_id),
                'ERC721: unauthorized caller'
            );
            self._transfer(from, to, token_id);
        }

        fn safe_transfer_from(
            ref self: ContractState,
            from: ContractAddress,
            to: ContractAddress,
            token_id: u256,
            data: Span<felt252>
        ) {
            assert(
                self._is_approved_or_owner(get_caller_address(), token_id),
                'ERC721: unauthorized caller'
            );
            self._safe_transfer(from, to, token_id, data);
        }


        fn token_of(self: @ContractState, address: ContractAddress) -> u256 {
            self._tokens.read(address)
        }
        fn base_uri(self: @ContractState) -> felt252 {
            self._base_uri.read()
        }

        fn set_minter(ref self: ContractState, address: ContractAddress) {
            self._minter.write(address);
        }

        fn set_base_uri(ref self: ContractState, uri: felt252) {
            self._base_uri.write(uri);
        }

        fn mint(ref self: ContractState, to: ContractAddress, token_id: u256) {
            assert(get_caller_address() == self._minter.read(), 'Caller not minter');
            InternalImpl::_mint(ref self, to, token_id);
            self._tokens.write(to, token_id);
        }
    }

    //
    // Internal
    //

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn initializer(
            ref self: ContractState, name_: felt252, symbol_: felt252, minter: ContractAddress
        ) {
            self._name.write(name_);
            self._symbol.write(symbol_);
            self._minter.write(minter);

            let mut unsafe_state = src5::SRC5::unsafe_new_contract_state();
            src5::SRC5::InternalImpl::register_interface(ref unsafe_state, interface::IERC721_ID);
            src5::SRC5::InternalImpl::register_interface(
                ref unsafe_state, interface::IERC721_METADATA_ID
            );
        }

        fn _owner_of(self: @ContractState, token_id: u256) -> ContractAddress {
            let owner = self._owners.read(token_id);
            match owner.is_zero() {
                bool::False(()) => owner,
                bool::True(()) => panic_with_felt252('ERC721: invalid token ID')
            }
        }

        fn _exists(self: @ContractState, token_id: u256) -> bool {
            !self._owners.read(token_id).is_zero()
        }

        fn _is_approved_or_owner(
            self: @ContractState, spender: ContractAddress, token_id: u256
        ) -> bool {
            let owner = self._owner_of(token_id);
            let is_approved_for_all = NGERC721Impl::is_approved_for_all(self, owner, spender);
            owner == spender
                || is_approved_for_all
                || spender == NGERC721Impl::get_approved(self, token_id)
        }

        fn _approve(ref self: ContractState, to: ContractAddress, token_id: u256) {
            let owner = self._owner_of(token_id);
            assert(owner != to, 'ERC721: approval to owner');

            self._token_approvals.write(token_id, to);
            self.emit(Approval { owner, approved: to, token_id });
        }

        fn _set_approval_for_all(
            ref self: ContractState,
            owner: ContractAddress,
            operator: ContractAddress,
            approved: bool
        ) {
            assert(owner != operator, 'ERC721: self approval');
            self._operator_approvals.write((owner, operator), approved);
            self.emit(ApprovalForAll { owner, operator, approved });
        }

        fn _mint(ref self: ContractState, to: ContractAddress, token_id: u256) {
            assert(!to.is_zero(), 'ERC721: invalid receiver');
            assert(!self._exists(token_id), 'ERC721: token already minted');
            InternalImpl::_assert_balance_is_zero(@self, to);
            self._balances.write(to, self._balances.read(to) + 1);
            self._owners.write(token_id, to);

            self.emit(Transfer { from: Zeroable::zero(), to, token_id });
        }

        fn _transfer(
            ref self: ContractState, from: ContractAddress, to: ContractAddress, token_id: u256
        ) {
            assert(!to.is_zero(), 'ERC721: invalid receiver');
            let owner = self._owner_of(token_id);
            assert(from == owner, 'ERC721: wrong sender');
            InternalImpl::_assert_balance_is_zero(@self, to);
            // Implicit clear approvals, no need to emit an event
            self._token_approvals.write(token_id, Zeroable::zero());

            self._balances.write(from, self._balances.read(from) - 1);
            self._balances.write(to, self._balances.read(to) + 1);
            self._owners.write(token_id, to);

            self.emit(Transfer { from, to, token_id });
        }

        fn _burn(ref self: ContractState, token_id: u256) {
            let owner = self._owner_of(token_id);

            // Implicit clear approvals, no need to emit an event
            self._token_approvals.write(token_id, Zeroable::zero());

            self._balances.write(owner, self._balances.read(owner) - 1);
            self._owners.write(token_id, Zeroable::zero());

            self.emit(Transfer { from: owner, to: Zeroable::zero(), token_id });
        }

        fn _safe_mint(
            ref self: ContractState, to: ContractAddress, token_id: u256, data: Span<felt252>
        ) {
            self._mint(to, token_id);
            assert(
                _check_on_erc721_received(Zeroable::zero(), to, token_id, data),
                'ERC721: safe mint failed'
            );
        }

        fn _safe_transfer(
            ref self: ContractState,
            from: ContractAddress,
            to: ContractAddress,
            token_id: u256,
            data: Span<felt252>
        ) {
            self._transfer(from, to, token_id);
            assert(
                _check_on_erc721_received(from, to, token_id, data), 'ERC721: safe transfer failed'
            );
        }

        fn _set_token_uri(ref self: ContractState, token_id: u256, token_uri: felt252) {
            assert(self._exists(token_id), 'ERC721: invalid token ID');
            self._token_uri.write(token_id, token_uri)
        }

        fn _assert_balance_is_zero(self: @ContractState, address: ContractAddress) {
            assert(self._balances.read(address) == 0, 'Max token balance reached');
        }
    }

    #[internal]
    fn _check_on_erc721_received(
        from: ContractAddress, to: ContractAddress, token_id: u256, data: Span<felt252>
    ) -> bool {
        if (DualCaseSRC5 { contract_address: to }
            .supports_interface(interface::IERC721_RECEIVER_ID)) {
            DualCaseERC721Receiver { contract_address: to }
                .on_erc721_received(
                    get_caller_address(), from, token_id, data
                ) == interface::IERC721_RECEIVER_ID
        } else {
            DualCaseSRC5 { contract_address: to }.supports_interface(account::interface::ISRC6_ID)
        }
    }
}
