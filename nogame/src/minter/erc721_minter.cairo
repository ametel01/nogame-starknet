#[starknet::contract]
mod minter {
    use starknet::{ContractAddress, get_caller_address, get_contract_address};
    use traits::Into;
    use nogame::token::erc721::IERC721Dispatcher;
    use nogame::token::erc721::IERC721DispatcherTrait;

    #[storage]
    struct Storage {
        erc721_address: ContractAddress,
        _admim: ContractAddress,
    }

    #[constructor]
    fn constructor(ref self: ContractState, admin: ContractAddress) {
        self._admim.write(admin);
    }

    #[external(v0)]
    #[generate_trait]
    impl Minter of MinterTrait {
        fn set_nft_address(ref self: ContractState, address: ContractAddress) {
            assert(get_caller_address() == self._admim.read(), 'caller not admin');
            self.erc721_address.write(address);
        }

        fn mint_all(ref self: ContractState, mut quantity: usize) {
            let admin = self._admim.read();
            assert(get_caller_address() == admin, 'caller is not admin');
            let mut token_id = 1;
            loop {
                if quantity == 0 {
                    break;
                }
                IERC721Dispatcher {
                    contract_address: self.erc721_address.read()
                }.mint(token_id.into());
                quantity -= 1;
                token_id += 1;
            }
        }
    }
}
