use core::traits::Into;
use starknet::ContractAddress;

#[starknet::interface]
trait IERC721<TContractState> {
    fn token_to_owner(self: @TContractState, token_id: u256) -> ContractAddress;
    fn owner_of(self: @TContractState, account: ContractAddress) -> u256;
    fn transfer(
        ref self: TContractState, from: ContractAddress, to: ContractAddress, token_id: u256
    );
}

#[starknet::contract]
mod ERC721 {
    use starknet::ContractAddress;
    use core::zeroable::Zeroable;
    use core::traits::Into;

    #[storage]
    struct Storage {
        _owners: LegacyMap<u256, ContractAddress>,
        _tokens: LegacyMap::<ContractAddress, u256>,
        _balances: LegacyMap<ContractAddress, u256>,
        _token_approvals: LegacyMap<u256, ContractAddress>,
    }

    #[constructor]
    fn init(ref self: ContractState) {}

    #[external(v0)]
    impl ERC721 of super::IERC721<ContractState> {
        fn token_to_owner(self: @ContractState, token_id: u256) -> ContractAddress {
            self._owners.read(token_id)
        }

        fn owner_of(self: @ContractState, account: ContractAddress) -> u256 {
            self._tokens.read(account)
        }

        fn transfer(
            ref self: ContractState, from: ContractAddress, to: ContractAddress, token_id: u256
        ) {
            assert(!to.is_zero(), 'ERC721: invalid receiver');
            let owner = self._owners.read(token_id);
            match owner.is_zero() {
                bool::False(()) => owner,
                bool::True(()) => panic_with_felt252('ERC721: invalid token ID')
            }
            assert(from == owner, 'ERC721: wrong sender');

            // Implicit clear approvals, no need to emit an event
            self._token_approvals.write(token_id, Zeroable::zero());

            // Update balances
            self._balances.write(from, self._balances.read(from) - 1.into());
            self._balances.write(to, self._balances.read(to) + 1.into());

            // Update token_id owner
            self._owners.write(token_id, to);
        }
    }
}
