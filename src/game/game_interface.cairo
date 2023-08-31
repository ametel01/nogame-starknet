use starknet::ContractAddress;
use nogame::game::game_library::{
    DefencesCost, DefencesLevels, EnergyCost, ERC20s, CompoundsCost, CompoundsLevels, Resources,
    ShipsLevels, ShipsCost, TechLevels, TechsCost, Tokens, LeaderBoard
};

#[starknet::interface]
trait INoGame<T> {
    fn _initializer(
        ref self: T,
        erc721: ContractAddress,
        steel: ContractAddress,
        quartz: ContractAddress,
        tritium: ContractAddress
    );
    // View functions
    fn get_token_addresses(self: @T) -> Tokens;
    fn get_number_of_planets(self: @T) -> u32;
    fn get_leaderboard(self: @T) -> LeaderBoard;
    fn get_spendable_resources(self: @T, planet_id: u128) -> ERC20s;
    fn get_collectible_resources(self: @T, planet_id: u128) -> ERC20s;
    fn get_energy_available(self: @T, planet_id: u128) -> u128;
    fn get_planet_points(self: @T, planet_id: u128) -> u128;
    fn get_compounds_levels(self: @T, planet_id: u128) -> CompoundsLevels;
    fn get_compounds_upgrade_cost(self: @T, planet_id: u128) -> CompoundsCost;
    fn get_energy_for_upgrade(self: @T, planet_id: u128) -> EnergyCost;
    fn get_techs_levels(self: @T, planet_id: u128) -> TechLevels;
    fn get_techs_upgrade_cost(self: @T, planet_id: u128) -> TechsCost;
    fn get_ships_levels(self: @T, planet_id: u128) -> ShipsLevels;
    fn get_ships_cost(self: @T) -> ShipsCost;
    fn get_defences_levels(self: @T, planet_id: u128) -> DefencesLevels;
    fn get_defences_cost(self: @T) -> DefencesCost;
    // Write functions
    fn generate_planet(ref self: T);
    fn collect_resources(ref self: T);
    fn steel_mine_upgrade(ref self: T);
    fn quartz_mine_upgrade(ref self: T);
    fn tritium_mine_upgrade(ref self: T);
    fn energy_plant_upgrade(ref self: T);
    fn dockyard_upgrade(ref self: T);
    fn lab_upgrade(ref self: T);
    fn energy_innovation_upgrade(ref self: T);
    fn digital_systems_upgrade(ref self: T);
    fn beam_technology_upgrade(ref self: T);
    fn armour_innovation_upgrade(ref self: T);
    fn ion_systems_upgrade(ref self: T);
    fn plasma_engineering_upgrade(ref self: T);
    fn weapons_development_upgrade(ref self: T);
    fn shield_tech_upgrade(ref self: T);
    fn spacetime_warp_upgrade(ref self: T);
    fn combustive_engine_upgrade(ref self: T);
    fn thrust_propulsion_upgrade(ref self: T);
    fn warp_drive_upgrade(ref self: T);
    // Dockyard functions
    fn carrier_build(ref self: T, quantity: u128);
    fn scraper_build(ref self: T, quantity: u128);
    fn celestia_build(ref self: T, quantity: u128);
    fn sparrow_build(ref self: T, quantity: u128);
    fn frigate_build(ref self: T, quantity: u128);
    fn armade_build(ref self: T, quantity: u128);
    // Defences functions
    fn blaster_build(ref self: T, quantity: u128);
    fn beam_build(ref self: T, quantity: u128);
    fn astral_launcher_build(ref self: T, quantity: u128);
    fn plasma_projector_build(ref self: T, quantity: u128);
}
