use starknet::{ContractAddress, class_hash::ClassHash};
use nogame::libraries::types::{
    DefencesCost, DefencesLevels, EnergyCost, ERC20s, CompoundsCost, CompoundsLevels, ShipsLevels,
    ShipsCost, TechLevels, TechsCost, Tokens, PlanetPosition, Cargo, Debris, Fleet, Mission,
    HostileMission
};

#[starknet::interface]
trait INoGame<TState> {
    fn initializer(
        ref self: TState,
        erc721: ContractAddress,
        steel: ContractAddress,
        quartz: ContractAddress,
        tritium: ContractAddress,
        rand: ContractAddress,
        eth: ContractAddress,
        receiver: ContractAddress,
        uni_speed: u128,
    );
    // Upgradable
    fn upgrade(ref self: TState, impl_hash: ClassHash);
    fn version(self: @TState) -> u8;
    // Write functions
    fn generate_planet(ref self: TState);
    fn collect_resources(ref self: TState);
    fn steel_mine_upgrade(ref self: TState, quantity: u32);
    fn quartz_mine_upgrade(ref self: TState, quantity: u32);
    fn tritium_mine_upgrade(ref self: TState, quantity: u32);
    fn energy_plant_upgrade(ref self: TState, quantity: u32);
    fn dockyard_upgrade(ref self: TState, quantity: u32);
    fn lab_upgrade(ref self: TState, quantity: u32);
    fn energy_innovation_upgrade(ref self: TState, quantity: u32);
    fn digital_systems_upgrade(ref self: TState, quantity: u32);
    fn beam_technology_upgrade(ref self: TState, quantity: u32);
    fn armour_innovation_upgrade(ref self: TState, quantity: u32);
    fn ion_systems_upgrade(ref self: TState, quantity: u32);
    fn plasma_engineering_upgrade(ref self: TState, quantity: u32);
    fn weapons_development_upgrade(ref self: TState, quantity: u32);
    fn shield_tech_upgrade(ref self: TState, quantity: u32);
    fn spacetime_warp_upgrade(ref self: TState, quantity: u32);
    fn combustive_engine_upgrade(ref self: TState, quantity: u32);
    fn thrust_propulsion_upgrade(ref self: TState, quantity: u32);
    fn warp_drive_upgrade(ref self: TState, quantity: u32);
    // Dockyard functions
    fn carrier_build(ref self: TState, quantity: u32);
    fn scraper_build(ref self: TState, quantity: u32);
    fn celestia_build(ref self: TState, quantity: u32);
    fn sparrow_build(ref self: TState, quantity: u32);
    fn frigate_build(ref self: TState, quantity: u32);
    fn armade_build(ref self: TState, quantity: u32);
    // Defences functions
    fn blaster_build(ref self: TState, quantity: u32);
    fn beam_build(ref self: TState, quantity: u32);
    fn astral_launcher_build(ref self: TState, quantity: u32);
    fn plasma_projector_build(ref self: TState, quantity: u32);
    // Fleet functions
    fn send_fleet(
        ref self: TState, f: Fleet, destination: PlanetPosition, is_debris_collection: bool
    );
    // fn dock_fleet(ref self: TState, mission_id: u8);
    fn attack_planet(ref self: TState, mission_id: usize);
    fn recall_fleet(ref self: TState, mission_id: usize);
    fn collect_debris(ref self: TState, mission_id: usize);
    // View functions
    fn get_receiver(self: @TState) -> ContractAddress;
    fn get_token_addresses(self: @TState) -> Tokens;
    fn get_current_planet_price(self: @TState) -> u128;
    fn get_number_of_planets(self: @TState) -> u16;
    fn get_generated_planets_positions(self: @TState) -> Array<PlanetPosition>;
    fn get_planet_position(self: @TState, planet_id: u16) -> PlanetPosition;
    fn get_position_slot_occupant(self: @TState, position: PlanetPosition) -> u16;
    fn get_debris_field(self: @TState, planet_id: u16) -> Debris;
    fn get_last_active(self: @TState, planet_id: u16) -> u64;
    fn get_spendable_resources(self: @TState, planet_id: u16) -> ERC20s;
    fn get_collectible_resources(self: @TState, planet_id: u16) -> ERC20s;
    fn get_planet_points(self: @TState, planet_id: u16) -> u128;
    fn get_energy_available(self: @TState, planet_id: u16) -> u128;
    fn get_compounds_levels(self: @TState, planet_id: u16) -> CompoundsLevels;
    fn get_compounds_upgrade_cost(self: @TState, planet_id: u16) -> CompoundsCost;
    fn get_energy_for_upgrade(self: @TState, planet_id: u16) -> EnergyCost;
    fn get_energy_gain_after_upgrade(self: @TState, planet_id: u16) -> u128;
    fn get_celestia_production(self: @TState, planet_id: u16) -> u16;
    fn get_techs_levels(self: @TState, planet_id: u16) -> TechLevels;
    fn get_techs_upgrade_cost(self: @TState, planet_id: u16) -> TechsCost;
    fn get_ships_levels(self: @TState, planet_id: u16) -> Fleet;
    fn get_ships_cost(self: @TState) -> ShipsCost;
    fn get_celestia_available(self: @TState, planet_id: u16) -> u32;
    fn get_defences_levels(self: @TState, planet_id: u16) -> DefencesLevels;
    fn get_defences_cost(self: @TState) -> DefencesCost;
    fn is_noob_protected(self: @TState, planet1_id: u16, planet2_id: u16) -> bool;
    fn get_mission_details(self: @TState, planet_id: u16, mission_id: usize) -> Mission;
    fn get_hostile_missions(self: @TState, planet_id: u16) -> Array<HostileMission>;
    fn get_active_missions(self: @TState, planet_id: u16) -> Array<Mission>;
    fn get_travel_time(
        self: @TState,
        origin: PlanetPosition,
        destination: PlanetPosition,
        fleet: Fleet,
        techs: TechLevels
    ) -> u64;
    fn get_fuel_consumption(
        self: @TState, origin: PlanetPosition, destination: PlanetPosition, fleet: Fleet
    ) -> u128;
}

