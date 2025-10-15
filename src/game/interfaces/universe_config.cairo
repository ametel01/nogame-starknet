/// Universe configuration interface - provides game-wide settings
#[starknet::interface]
trait IUniverseConfig<TState> {
    /// Get the universe speed multiplier
    fn get_uni_speed(self: @TState) -> u128;

    /// Get the universe start timestamp
    fn get_universe_start_time(self: @TState) -> u64;

    /// Get the token price for planet purchases
    fn get_token_price(self: @TState) -> u128;
}
