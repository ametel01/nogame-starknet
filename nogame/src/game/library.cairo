use starknet::ContractAddress;

#[derive(Drop, Serde)]
struct Cost {
    steel: u256,
    quartz: u256
}

#[derive(Drop, Serde)]
struct CostExtended {
    steel: u256,
    quartz: u256,
    tritium: u256,
}

#[derive(Drop, Serde)]
struct Tokens {
    steel: Cost,
    quartz: Cost,
    tritium: Cost,
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
    steel: Cost,
    quartz: Cost,
    tritium: Cost,
    solar: Cost,
}

#[derive(Drop, Serde)]
struct MinesLevels {
    steel: u128,
    quartz: u128,
    tritium: u128,
    solar: u128
}

struct Compounds {}

struct Techs {}

struct Fleet {}

struct Defences {}

