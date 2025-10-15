use nogame::libraries::types::Tokens;

/// Token provider interface - provides access to ERC20 and ERC721 token dispatchers
#[starknet::interface]
trait ITokenProvider<TState> {
    /// Get all token dispatchers (ERC721, steel, quartz, tritium, eth)
    fn get_tokens(self: @TState) -> Tokens;
}
