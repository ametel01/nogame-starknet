use starknet::ContractAddress;

#[derive(Drop, Serde)]
struct Cost {
    steel: u256,
    quartz: u256
}

#[derive(Drop, Serde)]
struct Tokens {
    steel: Cost,
    quartz: Cost,
    tritium: Cost,
}

struct Mines {}

struct Compounds {}

struct Techs {}

struct Fleet {}

struct Defences {}

struct Resources {}

