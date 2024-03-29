#[starknet::contract]
mod ERC721NoGame {
    use starknet::ContractAddress;
    use starknet::get_caller_address;

    use openzeppelin::token::erc721::erc721::ERC721Component;
    use openzeppelin::introspection::src5::SRC5Component;
    use openzeppelin::access::ownable::OwnableComponent;
    use openzeppelin::upgrades::upgradeable::UpgradeableComponent;
    use nogame::token::erc721::interface::IERC721NoGame;


    component!(path: ERC721Component, storage: erc721, event: ERC721Event);
    component!(path: SRC5Component, storage: src5, event: SRC5Event);
    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    component!(path: UpgradeableComponent, storage: upgradeable, event: UpgradeableEvent);

    const ERC721_NOGAME_ID: felt252 =
        0x1e8208686f48fa69c89a47bbe7a99940495de8d5f238e7316fe57909b728d1a;

    impl ERC721Impl = ERC721Component::ERC721Impl<ContractState>;

    impl ERC721MetadataImpl = ERC721Component::ERC721MetadataImpl<ContractState>;

    impl ERC721InternalImpl = ERC721Component::InternalImpl<ContractState>;

    #[abi(embed_v0)]
    impl SRC5Impl = SRC5Component::SRC5Impl<ContractState>;
    #[abi(embed_v0)]
    impl SRC5CamelImpl = SRC5Component::SRC5CamelImpl<ContractState>;
    impl SRC5InternalImpl = SRC5Component::InternalImpl<ContractState>;

    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    impl UpgradableInteralImpl = UpgradeableComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        tokens: LegacyMap<ContractAddress, u256>,
        minter: ContractAddress,
        uri: LegacyMap<felt252, felt252>,
        #[substorage(v0)]
        erc721: ERC721Component::Storage,
        #[substorage(v0)]
        src5: SRC5Component::Storage,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        #[substorage(v0)]
        upgradeable: UpgradeableComponent::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        ERC721Event: ERC721Component::Event,
        #[flat]
        SRC5Event: SRC5Component::Event,
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        #[flat]
        UpgradeableEvent: UpgradeableComponent::Event,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        name: felt252,
        symbol: felt252,
        minter: ContractAddress,
        owner: ContractAddress
    ) {
        self.src5.register_interface(ERC721_NOGAME_ID);
        self.erc721.initializer(name, symbol);
        self.minter.write(minter);
        self.ownable.initializer(owner);
    }

    #[abi(embed_v0)]
    impl ERC721NoGameImpl of IERC721NoGame<ContractState> {
        fn balance_of(self: @ContractState, account: ContractAddress) -> u256 {
            self.erc721.balance_of(account)
        }

        fn owner_of(self: @ContractState, token_id: u256) -> ContractAddress {
            self.erc721.owner_of(token_id)
        }

        fn safe_transfer_from(
            ref self: ContractState,
            from: ContractAddress,
            to: ContractAddress,
            token_id: u256,
            data: Span<felt252>
        ) {
            self.erc721.safe_transfer_from(from, to, token_id, data);
            self.tokens.write(to, token_id)
        }

        fn transfer_from(
            ref self: ContractState, from: ContractAddress, to: ContractAddress, token_id: u256
        ) {
            self.erc721.transfer_from(from, to, token_id);
            self.tokens.write(to, token_id)
        }

        fn approve(ref self: ContractState, to: ContractAddress, token_id: u256) {
            self.erc721.approve(to, token_id);
        }

        fn set_approval_for_all(
            ref self: ContractState, operator: ContractAddress, approved: bool
        ) {
            self.erc721.set_approval_for_all(operator, approved);
        }

        fn get_approved(self: @ContractState, token_id: u256) -> ContractAddress {
            self.erc721.get_approved(token_id)
        }

        fn is_approved_for_all(
            self: @ContractState, owner: ContractAddress, operator: ContractAddress
        ) -> bool {
            self.erc721.is_approved_for_all(owner, operator)
        }

        fn name(self: @ContractState) -> felt252 {
            self.erc721.name()
        }

        fn symbol(self: @ContractState) -> felt252 {
            self.erc721.symbol()
        }

        fn token_uri(self: @ContractState, token_id: u256) -> Array<felt252> {
            let mut base = self.get_base_uri();
            let ten: NonZero<u256> = 10_u256.try_into().unwrap();
            let to_add = self.div_rec(token_id, ten);

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
            self.append_to_str(ref output, last.into(), to_add.span());
            output.append(46);
            output.append(106);
            output.append(115);
            output.append(111);
            output.append(110);
            output
        }

        fn balanceOf(self: @ContractState, account: ContractAddress) -> u256 {
            self.erc721.balance_of(account)
        }

        fn ownerOf(self: @ContractState, tokenId: u256) -> ContractAddress {
            self.erc721.owner_of(tokenId)
        }

        fn safeTransferFrom(
            ref self: ContractState,
            from: ContractAddress,
            to: ContractAddress,
            tokenId: u256,
            data: Span<felt252>
        ) {
            self.erc721.safe_transfer_from(from, to, tokenId, data);
        }

        fn transferFrom(
            ref self: ContractState, from: ContractAddress, to: ContractAddress, tokenId: u256
        ) {
            self.erc721.transfer_from(from, to, tokenId);
            self.tokens.write(to, tokenId)
        }

        fn setApprovalForAll(ref self: ContractState, operator: ContractAddress, approved: bool) {
            self.erc721.set_approval_for_all(operator, approved);
        }

        fn getApproved(self: @ContractState, tokenId: u256) -> ContractAddress {
            self.erc721.get_approved(tokenId)
        }

        fn isApprovedForAll(
            self: @ContractState, owner: ContractAddress, operator: ContractAddress
        ) -> bool {
            self.erc721.is_approved_for_all(owner, operator)
        }

        fn tokenURI(self: @ContractState, tokenId: u256) -> Array<felt252> {
            let mut base = self.get_base_uri();
            let ten: NonZero<u256> = 10_u256.try_into().unwrap();
            let to_add = self.div_rec(tokenId, ten);

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
            self.append_to_str(ref output, last.into(), to_add.span());
            output.append(46);
            output.append(106);
            output.append(115);
            output.append(111);
            output.append(110);
            output
        }

        fn token_of(self: @ContractState, address: ContractAddress) -> u256 {
            self.tokens.read(address)
        }

        fn mint(ref self: ContractState, to: ContractAddress, token_id: u256) {
            assert(get_caller_address() == self.minter.read(), 'ERC721 caller not minter');
            self.erc721._mint(to, token_id);
            self.tokens.write(to, token_id);
        }
    }

    #[generate_trait]
    impl ERC721NoGameInternalImpl of ERC721NoGameInternalTrait {
        fn div_rec(self: @ContractState, value: u256, divider: NonZero<u256>) -> Array<felt252> {
            let (value, digit) = DivRem::div_rem(value, divider);
            let mut output = if value == 0 {
                Default::default()
            } else {
                self.div_rec(value, divider)
            };
            output.append(48 + digit.try_into().unwrap());
            output
        }

        fn append_to_str(
            self: @ContractState, ref str: Array<felt252>, last_field: u256, to_add: Span<felt252>
        ) {
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

        fn get_base_uri(self: @ContractState) -> Array<felt252> {
            array![
                105,
                112,
                102,
                115,
                58,
                47,
                47,
                81,
                109,
                80,
                74,
                113,
                69,
                54,
                81,
                116,
                80,
                120,
                56,
                52,
                102,
                120,
                54,
                90,
                82,
                84,
                49,
                72,
                69,
                51,
                66,
                100,
                50,
                107,
                83,
                52,
                115,
                49,
                57,
                68,
                110,
                74,
                49,
                109,
                70,
                71,
                100,
                110,
                84,
                110,
                56,
                71,
                97,
                47
            ]
        }
    }
}

