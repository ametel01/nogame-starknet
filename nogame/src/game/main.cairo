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
    fn total_resources_available(self: @TContractState, caller: ContractAddress) -> Resources;
    fn generate_planet(ref self: TContractState);
    fn collect_resources(ref self: TContractState);
    fn steel_mine_upgrade(ref self: TContractState);
    fn quartz_mine_upgrade(ref self: TContractState);
    fn tritium_mine_upgrade(ref self: TContractState);
    fn energy_plant_upgrade(ref self: TContractState);
    fn dockyard_upgrade(ref self: TContractState);
    fn lab_upgrade(ref self: TContractState);
}

#[starknet::contract]
#[generate_trait]
mod NoGame {
    use core::option::OptionTrait;
    use core::traits::Into;
    use core::traits::TryInto;
    use starknet::{ContractAddress, get_block_timestamp, get_caller_address, get_contract_address};
    use nogame::game::library::{Tokens, CostExtended, MinesCost, MinesLevels, Resources};
    use nogame::compounds::library::Compounds;
    use nogame::mines::library::Mines;
    use nogame::token::erc20::IERC20DispatcherTrait;
    use nogame::token::erc20::IERC20Dispatcher;
    use nogame::token::erc721::IERC721DispatcherTrait;
    use nogame::token::erc721::IERC721Dispatcher;

    #[storage]
    struct Storage {
        // General.
        number_of_planets: u32,
        planet_generated: LegacyMap::<u256, bool>,
        planet_points: LegacyMap::<u256, u128>,
        // Tokens.
        erc721_address: ContractAddress,
        steel_address: ContractAddress,
        quartz_address: ContractAddress,
        tritium_address: ContractAddress,
        // Infrastructures.
        steel_mine_level: LegacyMap::<u256, u128>,
        quartz_mine_level: LegacyMap::<u256, u128>,
        tritium_mine_level: LegacyMap::<u256, u128>,
        energy_plant_level: LegacyMap::<u256, u128>,
        dockyard_level: LegacyMap::<u256, u128>,
        lab_level: LegacyMap::<u256, u128>,
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
    }

    #[derive(Drop, starknet::Event)]
    struct PlanetGenerated {
        planet_id: u256
    }

    // Resources spending events.
    #[derive(Drop, starknet::Event)]
    struct TotalResourcesSpent {
        planet_id: u256,
        spent: CostExtended
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
        //#########################################################################################
        //                                      VIEW FUNCTIONS                                    #
        //#########################################################################################
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
                energy: self.energy_plant_level.read(planet_id)
            })
        }

        fn get_mines_upgrade_cost(self: @ContractState, planet_id: u256) -> MinesCost {
            let _steel: CostExtended = Mines::steel_mine_cost(planet_id.low);
            let _quartz: CostExtended = Mines::quartz_mine_cost(planet_id.low);
            let _tritium: CostExtended = Mines::tritium_mine_cost(planet_id.low);
            let _solar: CostExtended = Mines::energy_plant_cost(planet_id.low);
            MinesCost { steel: _steel, quartz: _quartz, tritium: _tritium, solar: _solar }
        }

        fn total_resources_available(self: @ContractState, caller: ContractAddress) -> Resources {
            let production: Resources = PrivateFunctions::calculate_production(self, caller);
            let erc20_available = PrivateFunctions::get_erc20s_available(self, caller);
            Resources {
                steel: production.steel + erc20_available.steel,
                quartz: production.quartz + erc20_available.quartz,
                tritium: production.tritium + erc20_available.tritium,
                energy: production.energy
            }
        }
        //#########################################################################################
        //                                      EXTERNAL FUNCTIONS                                #
        //#########################################################################################
        fn generate_planet(ref self: ContractState) {
            let game_address = get_contract_address();
            let caller = get_caller_address();
            let planet_id = PrivateFunctions::get_planet_id_from_address(@self, caller);
            if self.planet_generated.read(planet_id) == false {
                self.planet_generated.write(planet_id, true);
                IERC721Dispatcher {
                    contract_address: self.erc721_address.read()
                }.transfer(from: game_address, to: caller, token_id: planet_id);
            }
            let number_of_planets = self.number_of_planets.read();
            self.number_of_planets.write(number_of_planets + 1);
            PrivateFunctions::mint_initial_liquidity(@self, caller);
            self.emit(Event::PlanetGenerated(PlanetGenerated { planet_id: planet_id }))
        }


        fn collect_resources(ref self: ContractState) {
            let caller = get_caller_address();
            let planet_id = PrivateFunctions::get_planet_id_from_address(@self, caller);
            let production = PrivateFunctions::calculate_production(@self, caller);
            PrivateFunctions::send_resources_erc20(@self, caller, production);
            self.resources_timer.write(planet_id, get_block_timestamp());
        }
        //#########################################################################################
        //                               MINES UPGRADE FUNCTIONS                                  #
        //#########################################################################################
        fn steel_mine_upgrade(ref self: ContractState) {
            let caller = get_caller_address();
            let planet_id = PrivateFunctions::get_planet_id_from_address(@self, caller);
            let current_level = self.steel_mine_level.read(planet_id);
            let cost: CostExtended = Mines::steel_mine_cost(current_level);
            PrivateFunctions::check_enough_resources(@self, caller, cost);
            PrivateFunctions::pay_resources_erc20(@self, caller, cost);
            self.steel_mine_level.write(planet_id, current_level + 1);
            PrivateFunctions::update_planet_points(ref self, planet_id, cost);
            self
                .emit(
                    Event::TotalResourcesSpent(
                        TotalResourcesSpent { planet_id: planet_id, spent: cost }
                    )
                )
        }

        fn quartz_mine_upgrade(ref self: ContractState) {
            let caller = get_caller_address();
            let planet_id = PrivateFunctions::get_planet_id_from_address(@self, caller);
            let current_level = self.quartz_mine_level.read(planet_id);
            let cost: CostExtended = Mines::quartz_mine_cost(current_level);
            PrivateFunctions::check_enough_resources(@self, caller, cost);
            PrivateFunctions::pay_resources_erc20(@self, caller, cost);
            self.quartz_mine_level.write(planet_id, current_level + 1);
            PrivateFunctions::update_planet_points(ref self, planet_id, cost);
            self
                .emit(
                    Event::TotalResourcesSpent(
                        TotalResourcesSpent { planet_id: planet_id, spent: cost }
                    )
                )
        }

        fn tritium_mine_upgrade(ref self: ContractState) {
            let caller = get_caller_address();
            let planet_id = PrivateFunctions::get_planet_id_from_address(@self, caller);
            let current_level = self.steel_mine_level.read(planet_id);
            let cost: CostExtended = Mines::tritium_mine_cost(current_level);
            PrivateFunctions::check_enough_resources(@self, caller, cost);
            PrivateFunctions::pay_resources_erc20(@self, caller, cost);
            self.tritium_mine_level.write(planet_id, current_level + 1);
            PrivateFunctions::update_planet_points(ref self, planet_id, cost);
            self
                .emit(
                    Event::TotalResourcesSpent(
                        TotalResourcesSpent { planet_id: planet_id, spent: cost }
                    )
                )
        }

        fn energy_plant_upgrade(ref self: ContractState) {
            let caller = get_caller_address();
            let planet_id = PrivateFunctions::get_planet_id_from_address(@self, caller);
            let current_level = self.energy_plant_level.read(planet_id);
            let cost: CostExtended = Mines::energy_plant_cost(current_level);
            PrivateFunctions::check_enough_resources(@self, caller, cost);
            PrivateFunctions::pay_resources_erc20(@self, caller, cost);
            self.energy_plant_level.write(planet_id, current_level + 1);
            PrivateFunctions::update_planet_points(ref self, planet_id, cost);
            self
                .emit(
                    Event::TotalResourcesSpent(
                        TotalResourcesSpent { planet_id: planet_id, spent: cost }
                    )
                )
        }
        //#########################################################################################
        //                               COMPOUNDS UPGRADE FUNCTIONS                              #
        //#########################################################################################
        fn dockyard_upgrade(ref self: ContractState) {
            let caller = get_caller_address();
            let planet_id = PrivateFunctions::get_planet_id_from_address(@self, caller);
            let current_level = self.dockyard_level.read(planet_id);
            let cost: CostExtended = Compounds::dockyard_cost(current_level);
            PrivateFunctions::check_enough_resources(@self, caller, cost);
            PrivateFunctions::pay_resources_erc20(@self, caller, cost);
            self.dockyard_level.write(planet_id, current_level + 1);
            PrivateFunctions::update_planet_points(ref self, planet_id, cost);
            self
                .emit(
                    Event::TotalResourcesSpent(
                        TotalResourcesSpent { planet_id: planet_id, spent: cost }
                    )
                )
        }

        fn lab_upgrade(ref self: ContractState) {
            let caller = get_caller_address();
            let planet_id = PrivateFunctions::get_planet_id_from_address(@self, caller);
            let current_level = self.lab_level.read(planet_id);
            let cost: CostExtended = Compounds::lab_cost(current_level);
            PrivateFunctions::check_enough_resources(@self, caller, cost);
            PrivateFunctions::pay_resources_erc20(@self, caller, cost);
            self.lab_level.write(planet_id, current_level + 1);
            PrivateFunctions::update_planet_points(ref self, planet_id, cost);
            self
                .emit(
                    Event::TotalResourcesSpent(
                        TotalResourcesSpent { planet_id: planet_id, spent: cost }
                    )
                )
        }
    }

    //#########################################################################################
    //                                      PRIVATE FUNCTIONS                                 #
    //#########################################################################################

    #[generate_trait]
    impl PrivateFunctions of PrivateTrait {
        fn get_planet_id_from_address(self: @ContractState, caller: ContractAddress) -> u256 {
            let erc721 = self.erc721_address.read();
            let planet_id = IERC721Dispatcher { contract_address: erc721 }.owner_of(caller);
            planet_id
        }

        fn get_erc20s_available(self: @ContractState, caller: ContractAddress) -> Resources {
            let planet_id = PrivateFunctions::get_planet_id_from_address(self, caller);
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

        fn calculate_production(self: @ContractState, caller: ContractAddress) -> Resources {
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

        fn calculate_net_energy(self: @ContractState, planet_id: u256) -> u128 {
            let energy = Mines::solar_plant_production(self.energy_plant_level.read(planet_id));
            let energy_needed = Mines::base_mine_consumption(self.steel_mine_level.read(planet_id))
                + Mines::base_mine_consumption(self.quartz_mine_level.read(planet_id))
                + Mines::tritium_mine_consumption(self.tritium_mine_level.read(planet_id));
            if energy < energy_needed {
                return 0;
            } else {
                energy - energy_needed
            }
        }

        fn send_resources_erc20(self: @ContractState, to: ContractAddress, amounts: Resources) {
            let tokens: Tokens = PrivateFunctions::get_tokens_addresses(self);
            IERC20Dispatcher { contract_address: tokens.steel }.mint(to, amounts.steel);
            IERC20Dispatcher { contract_address: tokens.quartz }.mint(to, amounts.quartz);
            IERC20Dispatcher { contract_address: tokens.tritium }.mint(to, amounts.tritium)
        }

        fn pay_resources_erc20(
            self: @ContractState, account: ContractAddress, amounts: CostExtended
        ) {
            let tokens: Tokens = PrivateFunctions::get_tokens_addresses(self);
            IERC20Dispatcher { contract_address: tokens.steel }.burn(account, amounts.steel);
            IERC20Dispatcher { contract_address: tokens.quartz }.burn(account, amounts.quartz);
            IERC20Dispatcher { contract_address: tokens.tritium }.burn(account, amounts.tritium)
        }

        fn mint_initial_liquidity(self: @ContractState, account: ContractAddress) {
            let tokens: Tokens = PrivateFunctions::get_tokens_addresses(self);
            IERC20Dispatcher {
                contract_address: tokens.steel
            }.mint(recipient: account, amount: u256 { low: 500, high: 0 });
            IERC20Dispatcher {
                contract_address: tokens.quartz
            }.mint(recipient: account, amount: u256 { low: 300, high: 0 });
            IERC20Dispatcher {
                contract_address: tokens.tritium
            }.mint(recipient: account, amount: u256 { low: 100, high: 0 });
        }

        fn check_enough_resources(
            self: @ContractState, caller: ContractAddress, amounts: CostExtended
        ) {
            let available: Resources = PrivateFunctions::get_erc20s_available(self, caller);
            assert(amounts.steel <= available.steel, 'Not enough steel');
            assert(amounts.quartz <= available.quartz, 'Not enough quartz');
            assert(amounts.tritium <= available.tritium, 'Not enough tritium');
        }

        fn get_tokens_addresses(self: @ContractState) -> Tokens {
            Tokens {
                steel: self.steel_address.read(),
                quartz: self.quartz_address.read(),
                tritium: self.tritium_address.read()
            }
        }

        fn update_planet_points(ref self: ContractState, planet_id: u256, spent: CostExtended) {
            let current_points = self.planet_points.read(planet_id);
            let acquired_points = (spent.steel.low + spent.quartz.low) / 1000;
            self.planet_points.write(planet_id, current_points + acquired_points);
        }
    }
}
