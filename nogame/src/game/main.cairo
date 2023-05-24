#[contract]
mod NoGame {
    use starknet::{ContractAddress, get_caller_address};
    use nogame::game::library;

    struct Storage {
        // General.
        number_of_planets: u32,
        planet_spent_resources: u32,
        planet_points: LegacyMap::<u256, u128>,
        // Tokens.
        erc721_address: ContractAddress,
        steel_address: ContractAddress,
        quarz_address: ContractAddress,
        tritium_address: ContractAddress,
        // Ifrastructures.
        steel_mine_level: LegacyMap::<u256, u32>,
        quarz_mine_level: LegacyMap::<u256, u32>,
        tritium_mine_level: LegacyMap::<u256, u32>,
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
    fn TritiumMineUpgrade(planet_id: u256) {}

    #[event]
    fn EnergyMine(planet_id: u256) {}
    // #[event]
    // fn DockyardUpgrade(planet_id: u256) {}

    // #[event]
    // fn LabUpgrade(planet_id: u256) {}

    // #[event]
    // fn MicroTechUpgrade(planet_id: u256) {}

    // Constructor
    #[constructor]
    fn constructor(
        erc721: ContractAddress,
        steel: ContractAddress,
        quarz: ContractAddress,
        tritium: ContractAddress
    ) {
        erc721_address::write(erc721);
        steel_address::write(steel);
        quarz_address::write(quarz);
        tritium_address::write(tritium);
    }

    // View functions.
    #[view]
    fn get_tokens_addresses() -> (
        ContractAddress, ContractAddress, ContractAddress, ContractAddress
    ) {
        (
            erc721_address::read(),
            steel_address::read(),
            quarz_address::read(),
            tritium_address::read()
        )
    }

    #[view]
    fn get_number_of_planets() -> u32 {
        number_of_planets::read()
    }

    #[view]
    fn get_planet_points(planet_id: u256) -> u128 {
        planet_points::read(planet_id)
    }

    #[view]
    fn get_mines_levels(planet_id: u256) -> (u32, u32, u32, u32) {
        (
            steel_mine_level::read(planet_id),
            quarz_mine_level::read(planet_id),
            tritium_mine_level::read(planet_id),
            energy_mine_level::read(planet_id)
        )
    }
}
