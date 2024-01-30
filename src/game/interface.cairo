use nogame::libraries::types::{
    DefencesCost, Defences, EnergyCost, ERC20s, CompoundsCost, CompoundsLevels, ShipsLevels,
    ShipsCost, TechLevels, TechsCost, Tokens, PlanetPosition, Cargo, Debris, Fleet, Mission,
    SimulationResult, IncomingMission, ColonyUpgradeType, ColonyBuildType
};
use starknet::{ContractAddress, class_hash::ClassHash};

#[starknet::interface]
trait INoGame<TState> {
    fn initializer(ref self: TState, owner: ContractAddress, storage: ContractAddress,);
    fn generate_planet(ref self: TState);
    fn get_current_planet_price(self: @TState) -> u128;
}

