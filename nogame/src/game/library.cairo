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
struct MinesCost {
    steel: Cost,
    quartz: Cost,
    tritium: Cost,
    solar: Cost,
}

struct Compounds {}

struct Techs {}

struct Fleet {}

struct Defences {}

struct Resources {}

