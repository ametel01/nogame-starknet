use nogame::colony::contract::IColonyDispatcher;
use nogame::compound::contract::ICompoundDispatcher;
use nogame::defence::contract::IDefenceDispatcher;
use nogame::dockyard::contract::IDockyardDispatcher;
use nogame::fleet_movements::contract::IFleetMovementsDispatcher;
use nogame::libraries::types::Contracts;
use nogame::planet::contract::IPlanetDispatcher;
use nogame::tech::contract::ITechDispatcher;

/// Contract registry interface - provides access to all game contract dispatchers
/// This is a facade that allows contract discovery without tight coupling
#[starknet::interface]
trait IContractRegistry<TState> {
    fn get_colony(self: @TState) -> IColonyDispatcher;
    fn get_compound(self: @TState) -> ICompoundDispatcher;
    fn get_defence(self: @TState) -> IDefenceDispatcher;
    fn get_dockyard(self: @TState) -> IDockyardDispatcher;
    fn get_fleet(self: @TState) -> IFleetMovementsDispatcher;
    fn get_planet(self: @TState) -> IPlanetDispatcher;
    fn get_tech(self: @TState) -> ITechDispatcher;

    /// Get all contract dispatchers
    /// Note: This method exists for backward compatibility during migration.
    /// New code should use specific contract getters when possible.
    fn get_contracts(self: @TState) -> Contracts;
}
