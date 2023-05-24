use starknet::ContractAddress;

struct Tokens {
    titanium: u256,
    quarz: u256,
    librium: u256,
}

struct Mines {}

struct Compounds {}

struct Techs {}

struct Fleet {}

struct Defences {}

struct Resources {}


trait NoGameTrait {
    fn get_number_of_planets() -> u32;
    fn owner_of(address: ContractAddress) -> u256;
    fn get_tokens_addr() -> Tokens;
    fn get_mines_levels(caller: ContractAddress) -> Mines;
    fn get_compounds_levels(caller: ContractAddress) -> Compounds;
    fn get_research_levels(caller: ContractAddress) -> Techs;
    fn get_fleet_levels(caller: ContractAddress) -> Fleet;
    fn get_defences_levels(caller: ContractAddress) -> Defences;
    fn get_resources_available(caller: ContractAddress) -> Resources;
}

