use starknet::ContractAddress;


#[derive(Copy, Drop, Serde)]
struct CostExtended {
    steel: u256,
    quartz: u256,
    tritium: u256,
}

#[derive(Drop, Serde)]
struct Tokens {
    steel: ContractAddress,
    quartz: ContractAddress,
    tritium: ContractAddress,
}

#[derive(Drop, Serde)]
struct Resources {
    steel: u256,
    quartz: u256,
    tritium: u256,
    energy: u128
}

#[derive(Drop, Serde)]
struct MinesCost {
    steel: CostExtended,
    quartz: CostExtended,
    tritium: CostExtended,
    solar: CostExtended,
}

#[derive(Drop, Serde)]
struct MinesLevels {
    steel: u128,
    quartz: u128,
    tritium: u128,
    energy: u128
}

struct Compounds {}

#[derive(Copy, Drop)]
struct Techs {
    energy_innovation: u128,
    digital_systems: u128,
    beam_technology: u128,
    armour_innovation: u128,
    ion_systems: u128,
    plasma_engineering: u128,
    stellar_physics: u128,
    arms_development: u128,
    shield_tech: u128,
    spacetime_warp: u128,
    combustive_engine: u128,
    thrust_propulsion: u128,
    warp_drive: u128,
}


struct Ships {
    carrier: u128,
    scraper: u128,
    celestia: u128,
    sparrow: u128,
    frigate: u128,
    armade: u128,
}

struct Defences {
    blaster: u128,
    beam: u128,
    astral_launcher: u128,
    plasma_beam: u128
}

