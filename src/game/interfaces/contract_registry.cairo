use nogame::libraries::types::Contracts;

/// Contract registry interface - provides access to all game contract dispatchers
/// This is a facade that allows contract discovery without tight coupling
#[starknet::interface]
trait IContractRegistry<TState> {
    /// Get all contract dispatchers
    /// Note: This method exists for backward compatibility during migration.
    /// New code should use specific contract getters when possible.
    fn get_contracts(self: @TState) -> Contracts;
}
