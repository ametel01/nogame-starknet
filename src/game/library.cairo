use starknet::ContractAddress;

const E18: u128 = 1000000000000000000;


#[derive(Copy, Drop, Serde)]
struct Tokens {
    erc721: ContractAddress,
    steel: ContractAddress,
    quartz: ContractAddress,
    tritium: ContractAddress,
}

#[derive(Copy, Drop, Serde)]
struct Resources {
    steel: u128,
    quartz: u128,
    tritium: u128,
    energy: u128
}

#[derive(Copy, Drop, Serde)]
struct ERC20s {
    steel: u128,
    quartz: u128,
    tritium: u128,
}

#[derive(Copy, Drop, Serde)]
struct CompoundsLevelsPacked {
    steel: u8,
    quartz: u8,
    tritium: u8,
    energy: u8,
    lab: u8,
    dockyard: u8,
}

#[derive(Copy, Drop, Serde)]
struct CompoundsLevels {
    steel: u128,
    quartz: u128,
    tritium: u128,
    energy: u128,
    lab: u128,
    dockyard: u128,
}

#[derive(Copy, Drop, Serde)]
struct CompoundsCost {
    steel: ERC20s,
    quartz: ERC20s,
    tritium: ERC20s,
    energy: ERC20s,
    lab: ERC20s,
    dockyard: ERC20s,
}

#[derive(Copy, Drop, Serde)]
struct TechLevels {
    energy_innovation: u128,
    digital_systems: u128,
    beam_technology: u128,
    armour_innovation: u128,
    ion_systems: u128,
    plasma_engineering: u128,
    weapons_development: u128,
    shield_tech: u128,
    spacetime_warp: u128,
    combustion_drive: u128,
    thrust_propulsion: u128,
    warp_drive: u128,
}

#[derive(Copy, Drop, Serde)]
struct TechsCost {
    energy_innovation: ERC20s,
    digital_systems: ERC20s,
    beam_technology: ERC20s,
    armour_innovation: ERC20s,
    ion_systems: ERC20s,
    plasma_engineering: ERC20s,
    weapons_development: ERC20s,
    shield_tech: ERC20s,
    spacetime_warp: ERC20s,
    combustion_drive: ERC20s,
    thrust_propulsion: ERC20s,
    warp_drive: ERC20s,
}

#[derive(Copy, Drop, Serde)]
struct ShipsLevels {
    carrier: u128,
    celestia: u128,
    scraper: u128,
    sparrow: u128,
    frigate: u128,
    armade: u128,
}

#[derive(Copy, Drop, Serde)]
struct ShipsCost {
    carrier: ERC20s,
    celestia: ERC20s,
    scraper: ERC20s,
    sparrow: ERC20s,
    frigate: ERC20s,
    armade: ERC20s,
}

#[derive(Copy, Drop, Serde)]
struct DefencesLevels {
    blaster: u128,
    beam: u128,
    astral: u128,
    plasma: u128
}

#[derive(Copy, Drop, Serde)]
struct DefencesCost {
    blaster: ERC20s,
    beam: ERC20s,
    astral: ERC20s,
    plasma: ERC20s,
}

#[derive(Copy, Drop, Serde)]
struct EnergyCost {
    steel: u128,
    quartz: u128,
    tritium: u128,
}

#[derive(Copy, Drop, Serde)]
struct LeaderBoard {
    point_leader: u128,
    tech_leader: u128,
    fleet_leader: u128,
}

