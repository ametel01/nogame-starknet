// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts for Cairo v0.8.0-beta.0 (token/erc721/erc721.cairo)

#[starknet::contract]
mod NGERC721 {
    use openzeppelin::account;
    use openzeppelin::introspection::dual_src5::DualCaseSRC5;
    use openzeppelin::introspection::dual_src5::DualCaseSRC5Trait;
    use openzeppelin::introspection::src5::SRC5 as src5_component;
    use openzeppelin::token::erc721::dual721_receiver::DualCaseERC721Receiver;
    use openzeppelin::token::erc721::dual721_receiver::DualCaseERC721ReceiverTrait;
    use openzeppelin::token::erc721::interface;
    use starknet::ContractAddress;
    use starknet::get_caller_address;

    // use nogame::token::interface::{IERC721NGMetadata, IERC721NGMetadataCamelOnly};
    use nogame::token::erc721::interface::IERC721NoGame;

    #[storage]
    struct Storage {
        ERC721_name: felt252,
        ERC721_symbol: felt252,
        ERC721_owners: LegacyMap<u256, ContractAddress>,
        ERC721_balances: LegacyMap<ContractAddress, u256>,
        ERC721_token_approvals: LegacyMap<u256, ContractAddress>,
        ERC721_operator_approvals: LegacyMap<(ContractAddress, ContractAddress), bool>,
        ERC721_token_uri: LegacyMap<u256, felt252>,
        ERC721_tokens: LegacyMap<ContractAddress, u256>,
        ERC721_minter: ContractAddress,
        deployer: ContractAddress,
        uri: LegacyMap<felt252, felt252>,
        #[substorage(v0)]
        src5: src5_component::Storage
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        Transfer: Transfer,
        Approval: Approval,
        ApprovalForAll: ApprovalForAll,
        SRC5Event: src5_component::Event
    }

    #[derive(Drop, starknet::Event)]
    struct Transfer {
        #[key]
        from: ContractAddress,
        #[key]
        to: ContractAddress,
        #[key]
        token_id: u256
    }

    #[derive(Drop, starknet::Event)]
    struct Approval {
        #[key]
        owner: ContractAddress,
        #[key]
        approved: ContractAddress,
        #[key]
        token_id: u256
    }

    #[derive(Drop, starknet::Event)]
    struct ApprovalForAll {
        #[key]
        owner: ContractAddress,
        #[key]
        operator: ContractAddress,
        approved: bool
    }

    mod Errors {
        const INVALID_TOKEN_ID: felt252 = 'ERC721: invalid token ID';
        const INVALID_ACCOUNT: felt252 = 'ERC721: invalid account';
        const UNAUTHORIZED: felt252 = 'ERC721: unauthorized caller';
        const APPROVAL_TO_OWNER: felt252 = 'ERC721: approval to owner';
        const SELF_APPROVAL: felt252 = 'ERC721: self approval';
        const INVALID_RECEIVER: felt252 = 'ERC721: invalid receiver';
        const ALREADY_MINTED: felt252 = 'ERC721: token already minted';
        const WRONG_SENDER: felt252 = 'ERC721: wrong sender';
        const SAFE_MINT_FAILED: felt252 = 'ERC721: safe mint failed';
        const SAFE_TRANSFER_FAILED: felt252 = 'ERC721: safe transfer failed';
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        name: felt252,
        symbol: felt252,
        minter: ContractAddress,
        owner: ContractAddress
    ) {
        self.initializer(name, symbol, minter, owner);
    }

    //
    // External
    //

    #[external(v0)]
    impl ERC721NoGameImpl of IERC721NoGame<ContractState> {
        fn name(self: @ContractState) -> felt252 {
            self.ERC721_name.read()
        }

        fn symbol(self: @ContractState) -> felt252 {
            self.ERC721_symbol.read()
        }

        fn token_uri(self: @ContractState, token_id: u256) -> Array<felt252> {
            let mut base = self.get_base_uri();
            let ten: NonZero<u256> = 10_u256.try_into().unwrap();
            let to_add = div_rec(token_id, ten);

            let mut output = ArrayTrait::new();
            let mut last_i = base.len() - 1;
            let last = *base.at(last_i);
            let mut i = 0;
            loop {
                if i == last_i {
                    break;
                }
                output.append(*base.at(i));
                i += 1;
            };
            append_to_str(ref output, last.into(), to_add.span());
            output
        }

        fn balance_of(self: @ContractState, account: ContractAddress) -> u256 {
            assert(!account.is_zero(), Errors::INVALID_ACCOUNT);
            self.ERC721_balances.read(account)
        }

        fn owner_of(self: @ContractState, token_id: u256) -> ContractAddress {
            self._owner_of(token_id)
        }

        fn token_of(self: @ContractState, address: ContractAddress) -> u256 {
            self.ERC721_tokens.read(address)
        }

        fn mint(ref self: ContractState, to: ContractAddress, token_id: u256) {
            assert(get_caller_address() == self.ERC721_minter.read(), 'ERC721 caller not minter');
            InternalImpl::_mint(ref self, to, token_id);
            self.ERC721_tokens.write(to, token_id);
        }

        fn get_base_uri(self: @ContractState) -> Array<felt252> {
            let mut output = ArrayTrait::new();
            let mut i = 0;
            loop {
                let value = self.uri.read(i);
                if value == 0 {
                    break;
                };
                output.append(value);
                i += 1;
            };
            output
        }

        fn get_uri(self: @ContractState, mut value: u256) -> Array<felt252> {
            let mut base = self.get_base_uri();
            let ten: NonZero<u256> = 10_u256.try_into().unwrap();
            let to_add = div_rec(value, ten);

            let mut output = ArrayTrait::new();
            let mut last_i = base.len() - 1;
            let last = *base.at(last_i);
            let mut i = 0;
            loop {
                if i == last_i {
                    break;
                }
                output.append(*base.at(i));
                i += 1;
            };
            append_to_str(ref output, last.into(), to_add.span());
            output
        }

        fn set_base_uri(ref self: ContractState, mut base_uri: Span<felt252>) {
            assert(get_caller_address() == self.deployer.read(), 'erc721 caller not deployer');
            // writing end of text
            self.uri.write(base_uri.len().into(), 0);
            loop {
                match base_uri.pop_back() {
                    Option::Some(value) => { self.uri.write(base_uri.len().into(), *value); },
                    Option::None => { break; }
                }
            };
        }


        fn tokenURI(self: @ContractState, tokenId: u256) -> Array<felt252> {
            let mut base = self.get_base_uri();
            let ten: NonZero<u256> = 10_u256.try_into().unwrap();
            let to_add = div_rec(tokenId, ten);

            let mut output = ArrayTrait::new();
            let mut last_i = base.len() - 1;
            let last = *base.at(last_i);
            let mut i = 0;
            loop {
                if i == last_i {
                    break;
                }
                output.append(*base.at(i));
                i += 1;
            };
            append_to_str(ref output, last.into(), to_add.span());
            output
        }

        fn get_approved(self: @ContractState, token_id: u256) -> ContractAddress {
            assert(self._exists(token_id), Errors::INVALID_TOKEN_ID);
            self.ERC721_token_approvals.read(token_id)
        }

        fn is_approved_for_all(
            self: @ContractState, owner: ContractAddress, operator: ContractAddress
        ) -> bool {
            self.ERC721_operator_approvals.read((owner, operator))
        }

        fn approve(ref self: ContractState, to: ContractAddress, token_id: u256) {
            let owner = self._owner_of(token_id);

            let caller = get_caller_address();
            assert(
                owner == caller || self.is_approved_for_all(owner, caller), Errors::UNAUTHORIZED
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
                self._is_approved_or_owner(get_caller_address(), token_id), Errors::UNAUTHORIZED
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
                self._is_approved_or_owner(get_caller_address(), token_id), Errors::UNAUTHORIZED
            );
            self._safe_transfer(from, to, token_id, data);
        }


        fn balanceOf(self: @ContractState, account: ContractAddress) -> u256 {
            self.balance_of(account)
        }

        fn ownerOf(self: @ContractState, tokenId: u256) -> ContractAddress {
            self.owner_of(tokenId)
        }

        fn getApproved(self: @ContractState, tokenId: u256) -> ContractAddress {
            self.get_approved(tokenId)
        }

        fn isApprovedForAll(
            self: @ContractState, owner: ContractAddress, operator: ContractAddress
        ) -> bool {
            self.is_approved_for_all(owner, operator)
        }

        fn setApprovalForAll(ref self: ContractState, operator: ContractAddress, approved: bool) {
            self.set_approval_for_all(operator, approved)
        }

        fn transferFrom(
            ref self: ContractState, from: ContractAddress, to: ContractAddress, tokenId: u256
        ) {
            self.transfer_from(from, to, tokenId)
        }

        fn safeTransferFrom(
            ref self: ContractState,
            from: ContractAddress,
            to: ContractAddress,
            tokenId: u256,
            data: Span<felt252>
        ) {
            self.safe_transfer_from(from, to, tokenId, data)
        }
    }

    //
    // Internal
    //

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn initializer(
            ref self: ContractState,
            name: felt252,
            symbol: felt252,
            minter: ContractAddress,
            deployer: ContractAddress
        ) {
            self.ERC721_name.write(name);
            self.ERC721_symbol.write(symbol);
            self.ERC721_minter.write(minter);
            self.deployer.write(deployer);
        }

        fn _owner_of(self: @ContractState, token_id: u256) -> ContractAddress {
            let owner = self.ERC721_owners.read(token_id);
            match owner.is_zero() {
                bool::False(()) => owner,
                bool::True(()) => panic_with_felt252(Errors::INVALID_TOKEN_ID)
            }
        }

        fn _exists(self: @ContractState, token_id: u256) -> bool {
            !self.ERC721_owners.read(token_id).is_zero()
        }

        fn _is_approved_or_owner(
            self: @ContractState, spender: ContractAddress, token_id: u256
        ) -> bool {
            let owner = self._owner_of(token_id);
            let is_approved_for_all = self.is_approved_for_all(owner, spender);
            owner == spender || is_approved_for_all || spender == self.get_approved(token_id)
        }

        fn _approve(ref self: ContractState, to: ContractAddress, token_id: u256) {
            let owner = self._owner_of(token_id);
            assert(owner != to, Errors::APPROVAL_TO_OWNER);

            self.ERC721_token_approvals.write(token_id, to);
            self.emit(Approval { owner, approved: to, token_id });
        }

        fn _set_approval_for_all(
            ref self: ContractState,
            owner: ContractAddress,
            operator: ContractAddress,
            approved: bool
        ) {
            assert(owner != operator, Errors::SELF_APPROVAL);
            self.ERC721_operator_approvals.write((owner, operator), approved);
            self.emit(ApprovalForAll { owner, operator, approved });
        }

        fn _mint(ref self: ContractState, to: ContractAddress, token_id: u256) {
            assert(!to.is_zero(), Errors::INVALID_RECEIVER);
            assert(!self._exists(token_id), Errors::ALREADY_MINTED);

            self.ERC721_balances.write(to, self.ERC721_balances.read(to) + 1);
            self.ERC721_owners.write(token_id, to);

            self.emit(Transfer { from: Zeroable::zero(), to, token_id });
        }

        fn _transfer(
            ref self: ContractState, from: ContractAddress, to: ContractAddress, token_id: u256
        ) {
            assert(!to.is_zero(), Errors::INVALID_RECEIVER);
            let owner = self._owner_of(token_id);
            assert(from == owner, Errors::WRONG_SENDER);

            // Implicit clear approvals, no need to emit an event
            self.ERC721_token_approvals.write(token_id, Zeroable::zero());

            self.ERC721_balances.write(from, self.ERC721_balances.read(from) - 1);
            self.ERC721_balances.write(to, self.ERC721_balances.read(to) + 1);
            self.ERC721_owners.write(token_id, to);

            self.emit(Transfer { from, to, token_id });
        }

        fn _burn(ref self: ContractState, token_id: u256) {
            let owner = self._owner_of(token_id);

            // Implicit clear approvals, no need to emit an event
            self.ERC721_token_approvals.write(token_id, Zeroable::zero());

            self.ERC721_balances.write(owner, self.ERC721_balances.read(owner) - 1);
            self.ERC721_owners.write(token_id, Zeroable::zero());

            self.emit(Transfer { from: owner, to: Zeroable::zero(), token_id });
        }

        fn _safe_mint(
            ref self: ContractState, to: ContractAddress, token_id: u256, data: Span<felt252>
        ) {
            self._mint(to, token_id);
            assert(
                _check_on_erc721_received(Zeroable::zero(), to, token_id, data),
                Errors::SAFE_MINT_FAILED
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
                _check_on_erc721_received(from, to, token_id, data), Errors::SAFE_TRANSFER_FAILED
            );
        }

        fn _set_token_uri(ref self: ContractState, token_id: u256, token_uri: felt252) {
            assert(self._exists(token_id), Errors::INVALID_TOKEN_ID);
            self.ERC721_token_uri.write(token_id, token_uri)
        }
    }

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

    fn div_rec(value: u256, divider: NonZero<u256>) -> Array<felt252> {
        let (value, digit) = DivRem::div_rem(value, divider);
        let mut output = if value == 0 {
            Default::default()
        } else {
            div_rec(value, divider)
        };
        output.append(48 + digit.try_into().unwrap());
        output
    }

    fn append_to_str(ref str: Array<felt252>, last_field: u256, to_add: Span<felt252>) {
        let mut free_space: usize = 0;
        let ascii_length: NonZero<u256> = 256_u256.try_into().unwrap();
        let mut i = 0;
        let mut shifted_field = last_field;
        // find free space in last text field
        loop {
            let (_shifted_field, char) = DivRem::div_rem(shifted_field, ascii_length);
            shifted_field = _shifted_field;
            if char == 0 {
                free_space += 1;
            } else {
                free_space = 0;
            };
            i += 1;
            if i == 31 {
                break;
            }
        };

        let mut new_field = 0;
        let mut shift = 1;
        let mut i = free_space;
        // add digits to the last text field
        loop {
            if free_space == 0 {
                break;
            }
            free_space -= 1;
            match to_add.get(free_space) {
                Option::Some(c) => {
                    new_field += shift * *c.unbox();
                    shift *= 256;
                },
                Option::None => {}
            };
        };
        new_field += last_field.try_into().expect('invalid string') * shift;
        str.append(new_field);
        if i >= to_add.len() {
            return;
        }

        let mut new_field_shift = 1;
        let mut new_field = 0;
        let mut j = i + 30;
        // keep adding digits by chunks of 31
        loop {
            match to_add.get(j) {
                Option::Some(char) => {
                    new_field += new_field_shift * *char.unbox();
                    if new_field_shift == 0x100000000000000000000000000000000000000000000000000000000000000 {
                        str.append(new_field);
                        new_field_shift = 1;
                        new_field = 0;
                    } else {
                        new_field_shift *= 256;
                    }
                },
                Option::None => {},
            }
            if j == i {
                i += 31;
                j = i + 30;
                str.append(new_field);
                if i >= to_add.len() {
                    break;
                }
                new_field_shift = 1;
                new_field = 0;
            } else {
                j -= 1;
            };
        };
    }
}

