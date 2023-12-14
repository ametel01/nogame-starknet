use starknet::ContractAddress;

#[starknet::interface]
trait IERC721NoGame<TState> {
    // IERC721NoGame
    fn token_of(self: @TState, address: ContractAddress) -> u256;
    fn mint(ref self: TState, to: ContractAddress, token_id: u256);
    fn get_base_uri(self: @TState) -> Array<felt252>;
    fn set_base_uri(ref self: TState, base_uri: Span<felt252>);
    // fn token_uri(self: @TState, token_id: u256) -> Array<felt252>;
    fn balanceOf(self: @TState, account: ContractAddress) -> u256;
    fn ownerOf(self: @TState, tokenId: u256) -> ContractAddress;
    fn safeTransferFrom(
        ref self: TState,
        from: ContractAddress,
        to: ContractAddress,
        tokenId: u256,
        data: Span<felt252>
    );
    fn transferFrom(ref self: TState, from: ContractAddress, to: ContractAddress, tokenId: u256);
    // IERC721MetadataCamelOnly
    fn tokenURI(self: @TState, tokenId: u256) -> Array<felt252>;
}
