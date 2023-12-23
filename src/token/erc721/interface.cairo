use starknet::ContractAddress;

#[starknet::interface]
trait IERC721NoGame<TState> {
    fn name(self: @TState) -> felt252;
    fn symbol(self: @TState) -> felt252;
    fn get_base_uri(self: @TState) -> Array<felt252>;
    fn token_uri(self: @TState, token_id: u256) -> Array<felt252>;
    fn token_of(self: @TState, address: ContractAddress) -> u256;
    fn balance_of(self: @TState, account: ContractAddress) -> u256;
    fn owner_of(self: @TState, token_id: u256) -> ContractAddress;
    fn transfer_from(ref self: TState, from: ContractAddress, to: ContractAddress, token_id: u256);
    fn mint(ref self: TState, to: ContractAddress, token_id: u256);
    fn set_base_uri(ref self: TState, base_uri: Span<felt252>);

    fn tokenURI(self: @TState, tokenId: u256) -> Array<felt252>;
    fn balanceOf(self: @TState, account: ContractAddress) -> u256;
    fn ownerOf(self: @TState, tokenId: u256) -> ContractAddress;
    fn transferFrom(ref self: TState, from: ContractAddress, to: ContractAddress, tokenId: u256);
}

#[starknet::interface]
trait IERC721NGMetadata<TState> {
    fn name(self: @TState) -> felt252;
    fn symbol(self: @TState) -> felt252;
    fn token_uri(self: @TState, token_id: u256) -> Array<felt252>;
}

#[starknet::interface]
trait IERC721NGMetadataCamelOnly<TState> {
    fn tokenURI(self: @TState, tokenId: u256) -> Array<felt252>;
}
