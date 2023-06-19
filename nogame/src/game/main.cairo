use starknet::ContractAddress;
use nogame::game::library::{MinesCost};

#[starknet::interface]
trait INoGame<TContractState> {
    fn get_tokens_addresses(
        self: @TContractState
    ) -> (ContractAddress, ContractAddress, ContractAddress, ContractAddress);
    fn get_number_of_planets(self: @TContractState) -> u32;
    fn get_planet_points(self: @TContractState, planet_id: u256) -> u128;
    fn get_mines_levels(self: @TContractState, planet_id: u256) -> (u32, u32, u32, u32);
    fn get_mines_upgrade_cost(self: @TContractState, planet_id: u256) -> MinesCost;
}

#[starknet::contract]
mod NoGame {
    use starknet::{ContractAddress, get_caller_address};
    use nogame::game::library::{Tokens, Cost, MinesCost};
    use nogame::mines::library::Mines;

    #[storage]
    struct Storage {
        // General.
        number_of_planets: u32,
        planet_spent_resources: u32,
        planet_points: LegacyMap::<u256, u128>,
        // Tokens.
        erc721_address: ContractAddress,
        steel_address: ContractAddress,
        quartz_address: ContractAddress,
        tritium_address: ContractAddress,
        // Ifrastructures.
        steel_mine_level: LegacyMap::<u256, u32>,
        quartz_mine_level: LegacyMap::<u256, u32>,
        tritium_mine_level: LegacyMap::<u256, u32>,
        energy_mine_level: LegacyMap::<u256, u32>,
    // dockyard_level: LegacyMap::<u256, u32>,
    // lab_level: LegacyMap::<u256, u32>,
    // microtech_level: LegacyMap::<u256, u32>,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        PlanetGenerated: PlanetGenerated,
        TotalResourcesSpent: TotalResourcesSpent,
        EconomySpent: EconomySpent,
        TechSpent: TechSpent,
        DefenceSpent: DefenceSpent,
        SteelMineUpgrade: SteelMineUpgrade,
        QuartzMineUpgrade: QuartzMineUpgrade,
        TritiumMineUpgrade: TritiumMineUpgrade,
        EnergyPlantUpgrade: EnergyPlantUpgrade
    }

    #[derive(Drop, starknet::Event)]
    struct PlanetGenerated {
        planet_id: u256
    }

    // Resources spending events.
    #[derive(Drop, starknet::Event)]
    struct TotalResourcesSpent {
        planet_id: u256,
        spent: u256
    }

    #[derive(Drop, starknet::Event)]
    struct EconomySpent {
        planet_id: u256,
        spent: u256
    }

    #[derive(Drop, starknet::Event)]
    struct TechSpent {
        planet_id: u256,
        spent: u256
    }

    #[derive(Drop, starknet::Event)]
    struct DefenceSpent {
        planet_id: u256,
        spent: u256
    }

    // Structures upgrade events.

    #[derive(Drop, starknet::Event)]
    struct SteelMineUpgrade {
        planet_id: u256
    }

    #[derive(Drop, starknet::Event)]
    struct QuartzMineUpgrade {
        planet_id: u256
    }

    #[derive(Drop, starknet::Event)]
    struct TritiumMineUpgrade {
        planet_id: u256
    }

    #[derive(Drop, starknet::Event)]
    struct EnergyPlantUpgrade {
        planet_id: u256
    }

    #[derive(Drop, starknet::Event)]
    struct DockyardUpgrade {
        planet_id: u256
    }

    #[derive(Drop, starknet::Event)]
    struct LabUpgrade {
        planet_id: u256
    }

    #[derive(Drop, starknet::Event)]
    struct MicroTechUpgrade {
        planet_id: u256
    }

    // Constructor
    #[constructor]
    fn constructor(
        ref self: ContractState,
        erc721: ContractAddress,
        steel: ContractAddress,
        quartz: ContractAddress,
        tritium: ContractAddress
    ) {
        self.erc721_address.write(erc721);
        self.steel_address.write(steel);
        self.quartz_address.write(quartz);
        self.tritium_address.write(tritium);
    }

    #[external(v0)]
    impl NoGame of super::INoGame<ContractState> {
        fn get_tokens_addresses(
            self: @ContractState
        ) -> (ContractAddress, ContractAddress, ContractAddress, ContractAddress) {
            (
                self.erc721_address.read(),
                self.steel_address.read(),
                self.quartz_address.read(),
                self.tritium_address.read()
            )
        }

        fn get_number_of_planets(self: @ContractState) -> u32 {
            self.number_of_planets.read()
        }


        fn get_planet_points(self: @ContractState, planet_id: u256) -> u128 {
            self.planet_points.read(planet_id)
        }


        fn get_mines_levels(self: @ContractState, planet_id: u256) -> (u32, u32, u32, u32) {
            (
                self.steel_mine_level.read(planet_id),
                self.quartz_mine_level.read(planet_id),
                self.tritium_mine_level.read(planet_id),
                self.energy_mine_level.read(planet_id)
            )
        }

        fn get_mines_upgrade_cost(self: @ContractState, planet_id: u256) -> MinesCost {
            let _steel: Cost = Mines::steel_mine_cost(planet_id.low);
            let _quartz: Cost = Mines::quartz_mine_cost(planet_id.low);
            let _tritium: Cost = Mines::tritium_mine_cost(planet_id.low);
            let _solar: Cost = Mines::solar_plant_cost(planet_id.low);
            MinesCost { steel: _steel, quartz: _quartz, tritium: _tritium, solar: _solar }
        }
    }
}
