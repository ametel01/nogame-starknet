#[starknet::contract]
mod NoGame {
    use starknet::{ContractAddress, get_caller_address};
    use nogame::game::library;

    #[Derive(starknet::StorageAccess)]
    #[storage]
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
    #[derive(Drop, starknet::Event)]
    fn PlanetGenerated(planet_id: u256) {}

    // Resources spending events.
    #[derive(Drop, starknet::Event)]
    fn TotalResourcesSpent(planet_id: u256, spent: u256) {}

    #[derive(Drop, starknet::Event)]
    fn EconomySpent(planet_id: u256, spent: u256) {}

    #[event]
    // fn TechSpent(planet_id: u256, spent: u256) {}

    // #[event]
    // fn DefenceSpent(planet_id: u256, spent: u256) {}

    // Structures upgrade events.
    #[event]
    #[derive(Drop, starknet::Event)]
    fn SteelMineUpgrade(planet_id: u256) {}

    #[derive(Drop, starknet::Event)]
    fn QuarzMineUpgrade(planet_id: u256) {}

    #[derive(Drop, starknet::Event)]
    fn TritiumMineUpgrade(planet_id: u256) {}

    #[derive(Drop, starknet::Event)]
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
        ref self: ContractState,
        erc721: ContractAddress,
        steel: ContractAddress,
        quarz: ContractAddress,
        tritium: ContractAddress
    ) {
        self.erc721_address.write(erc721);
        self.steel_address.write(steel);
        self.quarz_address.write(quarz);
        self.tritium_address.write(tritium);
    }

    // View functions.
    #[view]
    fn get_tokens_addresses(
        self: @ContractState
    ) -> (ContractAddress, ContractAddress, ContractAddress, ContractAddress) {
        (
            self.erc721_address.read(),
            self.steel_address.read(),
            self.quarz_address.read(),
            self.tritium_address.read()
        )
    }

    #[view]
    fn get_number_of_planets(self: @ContractState) -> u32 {
        self.number_of_planets.read()
    }

    #[view]
    fn get_planet_points(self: @ContractState, planet_id: u256) -> u128 {
        self.planet_points.read(planet_id)
    }

    #[view]
    fn get_mines_levels(self: @ContractState, planet_id: u256) -> (u32, u32, u32, u32) {
        (
            self.steel_mine_level.read(planet_id),
            self.quarz_mine_level.read(planet_id),
            self.tritium_mine_level.read(planet_id),
            self.energy_mine_level.read(planet_id)
        )
    }
}
