use core::traits::Into;
use starknet::ContractAddress;

#[starknet::interface]
trait IERC721<TContractState> {
    fn token_to_owner(self: @TContractState, account: ContractAddress) -> u256;
    fn owner_of(self: @TContractState, token_id: u256) -> ContractAddress;
}

#[starknet::contract]
mod ERC721 {
    use starknet::ContractAddress;

    #[storage]
    struct Storage {
        owners: LegacyMap<ContractAddress, u256>,
        tokens: LegacyMap::<u256, ContractAddress>,
    }

    #[constructor]
    fn init(ref self: ContractState) {}

    #[external(v0)]
    impl ERC721 of super::IERC721<ContractState> {
        fn token_to_owner(self: @ContractState, account: ContractAddress) -> u256 {
            self.owners.read(account)
        }

        fn owner_of(self: @ContractState, token_id: u256) -> ContractAddress {
            self.tokens.read(token_id)
        }
    }
}
