use starknet::ContractAddress;
use nogame::game::library::{MinesCost, MinesLevels, Resources};

#[starknet::interface]
trait INoGame<TContractState> {
    fn get_tokens_addresses(
        self: @TContractState
    ) -> (ContractAddress, ContractAddress, ContractAddress, ContractAddress);
    fn get_number_of_planets(self: @TContractState) -> u32;
    fn get_planet_points(self: @TContractState, planet_id: u256) -> u128;
    fn get_mines_levels(self: @TContractState, planet_id: u256) -> MinesLevels;
    fn get_mines_upgrade_cost(self: @TContractState, planet_id: u256) -> MinesCost;
    fn resources_available(self: @TContractState, caller: ContractAddress) -> Resources;
}

#[starknet::contract]
mod NoGame {
    use core::option::OptionTrait;
    use core::traits::Into;
    use core::traits::TryInto;
    use starknet::{ContractAddress, get_caller_address, get_block_timestamp};
    use nogame::game::library::{Tokens, Cost, MinesCost, MinesLevels, Resources};
    use nogame::mines::library::Mines;
    use nogame::token::erc20::IERC20DispatcherTrait;
    use nogame::token::erc20::IERC20Dispatcher;
    use nogame::token::erc721::IERC721DispatcherTrait;
    use nogame::token::erc721::IERC721Dispatcher;

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
        steel_mine_level: LegacyMap::<u256, u128>,
        quartz_mine_level: LegacyMap::<u256, u128>,
        tritium_mine_level: LegacyMap::<u256, u128>,
        energy_mine_level: LegacyMap::<u256, u128>,
        // dockyard_level: LegacyMap::<u256, u32>,
        // lab_level: LegacyMap::<u256, u32>,
        // microtech_level: LegacyMap::<u256, u32>,
        resources_timer: LegacyMap::<u256, u64>,
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
    fn init(
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


        fn get_mines_levels(self: @ContractState, planet_id: u256) -> MinesLevels {
            (MinesLevels {
                steel: self.steel_mine_level.read(planet_id),
                quartz: self.quartz_mine_level.read(planet_id),
                tritium: self.tritium_mine_level.read(planet_id),
                solar: self.energy_mine_level.read(planet_id)
            })
        }

        fn get_mines_upgrade_cost(self: @ContractState, planet_id: u256) -> MinesCost {
            let _steel: Cost = Mines::steel_mine_cost(planet_id.low);
            let _quartz: Cost = Mines::quartz_mine_cost(planet_id.low);
            let _tritium: Cost = Mines::tritium_mine_cost(planet_id.low);
            let _solar: Cost = Mines::solar_plant_cost(planet_id.low);
            MinesCost { steel: _steel, quartz: _quartz, tritium: _tritium, solar: _solar }
        }

        fn resources_available(self: @ContractState, caller: ContractAddress) -> Resources {
            let planet_id = PrivateFunctions::get_planet_id_from_address(self, caller);
            let time_now = get_block_timestamp();
            let last_collection_time = self.resources_timer.read(planet_id);
            let time_elapsed = time_now - last_collection_time;

            let steel_available: u256 = u256 {
                low: Mines::steel_production(self.steel_mine_level.read(planet_id)).low
                    * time_elapsed.into(),
                high: 0
            };

            let quartz_available: u256 = u256 {
                low: Mines::quartz_production(self.quartz_mine_level.read(planet_id)).low
                    * time_elapsed.into(),
                high: 0
            };

            let tritium_available: u256 = u256 {
                low: Mines::tritium_production(self.tritium_mine_level.read(planet_id)).low
                    * time_elapsed.into(),
                high: 0
            };

            let energy_available = PrivateFunctions::calculate_net_energy(self, planet_id);

            Resources {
                steel: steel_available,
                quartz: quartz_available,
                tritium: tritium_available,
                energy: energy_available
            }
        }
    }

    #[generate_trait]
    impl PrivateFunctions of PrivateTrait {
        fn get_planet_id_from_address(self: @ContractState, caller: ContractAddress) -> u256 {
            let erc721 = self.erc721_address.read();
            let planet_id = IERC721Dispatcher { contract_address: erc721 }.token_to_owner(caller);
            planet_id
        }

        fn get_resources_available(self: @ContractState, caller: ContractAddress) -> Resources {
            let planet_id = PrivateFunctions::get_planet_id_from_address(self, caller);
            // let time_now = get_block_timestamp();
            // let previous_time = self.resources_timer.read(planet_id);
            // let time_elapsed = time_now - previous_time;

            let steel_level = self.steel_mine_level.read(planet_id);
            let quartz_level = self.quartz_mine_level.read(planet_id);
            let tritium_level = self.tritium_mine_level.read(planet_id);

            let _steel = IERC20Dispatcher {
                contract_address: self.steel_address.read()
            }.balances(caller);
            // let steel_total = Mines::steel_production(steel_level) + steel_available;

            let _quartz = IERC20Dispatcher {
                contract_address: self.quartz_address.read()
            }.balances(caller);
            // let quartz_total = Mines::quartz_production(quartz_level) + quartz_available;

            let _tritium = IERC20Dispatcher {
                contract_address: self.tritium_address.read()
            }.balances(caller);
            // let steel_produced = Mines::steel_production(steel_level) + steel_available;
            let _energy = PrivateFunctions::calculate_net_energy(self, planet_id);
            Resources { steel: _steel, quartz: _quartz, tritium: _tritium, energy: _energy }
        }
        // fn calculate_production(self: ContractState, caller: ContractAddress) -> Resources {

        // }

        fn calculate_net_energy(self: @ContractState, planet_id: u256) -> u128 {
            let energy = Mines::solar_plant_production(self.energy_mine_level.read(planet_id));
            let energy_needed = Mines::base_mine_consumption(self.steel_mine_level.read(planet_id))
                + Mines::base_mine_consumption(self.quartz_mine_level.read(planet_id))
                + Mines::tritium_mine_consumption(self.tritium_mine_level.read(planet_id));
            if energy < energy_needed {
                return 0;
            } else {
                energy - energy_needed
            }
        }
    }
}
