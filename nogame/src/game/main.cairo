#[contract]
mod NoGame {
    use starknet::{ContractAddress, get_caller_address};
    use nogame::game::library;

    struct Storage {
        // General.
        number_of_planets: u32,
        planet_spent_resources: u32,
        // Tokens.
        steel_address: ContractAddress,
        quarz_address: ContractAddress,
        // Ifrastructures.
        steel_mine_level: LegacyMap::<u256, u32>,
        quarz_mine_level: LegacyMap::<u256, u32>,
        librium_mine_level: LegacyMap::<u256, u32>,
        energy_mine_level: LegacyMap::<u256, u32>,
    // dockyard_level: LegacyMap::<u256, u32>,
    // lab_level: LegacyMap::<u256, u32>,
    // microtech_level: LegacyMap::<u256, u32>,
    }

    #[event]
    fn PlanetGenerated(planet_id: u256) {}

    // Resources spending events.
    #[event]
    fn TotalResourcesSpent(planet_id: u256, spent: u256) {}

    #[external]
    fn EconomySpent(planet_id: u256, spent: u256) {}

    #[event]
    // fn TechSpent(planet_id: u256, spent: u256) {}

    // #[event]
    // fn DefenceSpent(planet_id: u256, spent: u256) {}

    // Structures upgrade events.
    #[event]
    fn SteelMineUpgrade(planet_id: u256) {}

    #[event]
    fn QuarzMineUpgrade(planet_id: u256) {}

    #[event]
    fn LibriumMineUpgrade(planet_id: u256) {}

    #[event]
    fn EnergyMine(planet_id: u256) {}
// #[event]
// fn DockyardUpgrade(planet_id: u256) {}

// #[event]
// fn LabUpgrade(planet_id: u256) {}

// #[event]
// fn MicroTechUpgrade(planet_id: u256) {}
// // Constructor
// #[constructor]
// fn constructor()
}
