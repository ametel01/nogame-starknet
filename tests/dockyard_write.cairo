// use core::testing::get_available_gas;
// use starknet::testing::cheatcode;
// use starknet::info::{get_contract_address, get_block_timestamp};
// use starknet::{ContractAddress, contract_address_const};
// use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};

// use snforge_std::{declare, ContractClassTrait, start_prank, start_warp, PrintTrait, CheatTarget};

// use nogame::game::interface::{INoGameDispatcher, INoGameDispatcherTrait};
// use nogame::libraries::types::{
//     ERC20s, EnergyCost, TechLevels, TechsCost, ShipsLevels, ShipsCost, DefencesLevels, DefencesCost
// };
// use tests::utils::{E18, HOUR, Dispatchers, ACCOUNT1, ACCOUNT2, DEPLOYER, init_game, set_up};

// #[test]
// fn test_carrier_build() {
//     let dsp = set_up();
//     init_game(dsp);

//     start_prank(CheatTarget::One(dsp.nogame.contract_address), ACCOUNT1());
//     dsp.nogame.generate_planet();

//     dsp.nogame.energy_plant_upgrade(1);
//     dsp.nogame.tritium_mine_upgrade(1);
//     start_warp(CheatTarget::All, HOUR * 2400000);
//     dsp.nogame.dockyard_upgrade(1);
//     dsp.nogame.dockyard_upgrade(1);
//     dsp.nogame.lab_upgrade(1);
//     dsp.nogame.energy_innovation_upgrade(1);
//     dsp.nogame.combustive_engine_upgrade(1);
//     dsp.nogame.combustive_engine_upgrade(1);

//     dsp.nogame.carrier_build(10);
//     let ships = dsp.nogame.get_ships_levels(1);
//     assert(ships.carrier == 10, 'wrong carrier level');
// }

// #[test]
// fn test_carrier_build_fails_dockyard_level() { // TODO
//     assert(0 == 0, 'todo');
// }

// #[test]
// fn test_carrier_build_fails_combustion_level() { // TODO
//     assert(0 == 0, 'todo');
// }

// #[test]
// fn test_celestia_build() {
//     let dsp = set_up();
//     init_game(dsp);

//     start_prank(CheatTarget::One(dsp.nogame.contract_address), ACCOUNT1());
//     dsp.nogame.generate_planet();

//     dsp.nogame.energy_plant_upgrade(1);
//     dsp.nogame.tritium_mine_upgrade(1);
//     start_warp(CheatTarget::All, HOUR * 2400000);
//     dsp.nogame.dockyard_upgrade(1);
//     dsp.nogame.lab_upgrade(1);
//     dsp.nogame.energy_innovation_upgrade(1);
//     dsp.nogame.combustive_engine_upgrade(1);

//     dsp.nogame.celestia_build(10);
//     let ships = dsp.nogame.get_ships_levels(1);
// }

// #[test]
// fn test_celestia_build_fails_dockyard_level() { // TODO
//     assert(0 == 0, 'todo');
// }

// #[test]
// fn test_celestia_build_fails_combustion_level() { // TODO
//     assert(0 == 0, 'todo');
// }

// #[test]
// fn test_sparrow_build() {
//     let dsp = set_up();
//     init_game(dsp);

//     start_prank(CheatTarget::One(dsp.nogame.contract_address), ACCOUNT1());
//     dsp.nogame.generate_planet();

//     dsp.nogame.energy_plant_upgrade(1);
//     dsp.nogame.tritium_mine_upgrade(1);
//     start_warp(CheatTarget::All, HOUR * 2400000);
//     dsp.nogame.dockyard_upgrade(1);
//     dsp.nogame.lab_upgrade(1);
//     dsp.nogame.energy_innovation_upgrade(1);
//     dsp.nogame.combustive_engine_upgrade(1);

//     dsp.nogame.sparrow_build(10);
//     let ships = dsp.nogame.get_ships_levels(1);
//     assert(ships.sparrow == 10, 'wrong sparrow level');
// }

// #[test]
// fn test_sparrow_build_fails_dockyard_level() { // TODO
//     assert(0 == 0, 'todo');
// }

// #[test]
// fn test_sparrow_build_fails_combustion_level() { // TODO
//     assert(0 == 0, 'todo');
// }

// #[test]
// fn test_scraper_build() {
//     let dsp = set_up();
//     init_game(dsp);

//     start_prank(CheatTarget::One(dsp.nogame.contract_address), ACCOUNT1());
//     dsp.nogame.generate_planet();

//     dsp.nogame.energy_plant_upgrade(1);
//     dsp.nogame.tritium_mine_upgrade(1);
//     start_warp(CheatTarget::All, HOUR * 2400000);
//     dsp.nogame.dockyard_upgrade(4);
//     dsp.nogame.lab_upgrade(1);
//     dsp.nogame.energy_innovation_upgrade(1);
//     dsp.nogame.combustive_engine_upgrade(6);
//     dsp.nogame.lab_upgrade(5);
//     dsp.nogame.energy_innovation_upgrade(2);
//     dsp.nogame.shield_tech_upgrade(2);

//     dsp.nogame.scraper_build(10);
//     let ships = dsp.nogame.get_ships_levels(1);
//     assert(ships.scraper == 10, 'wrong scraper level');
// }

// #[test]
// fn test_scraper_build_fails_dockyard_level() { // TODO
//     assert(0 == 0, 'todo');
// }

// #[test]
// fn test_scraper_build_fails_combustion_level() { // TODO
//     assert(0 == 0, 'todo');
// }

// #[test]
// fn test_scraper_build_fails_shield_level() { // TODO
//     assert(0 == 0, 'todo');
// }

// #[test]
// fn test_frigate_build() {
//     let dsp = set_up();
//     init_game(dsp);

//     start_prank(CheatTarget::One(dsp.nogame.contract_address), ACCOUNT1());
//     dsp.nogame.generate_planet();

//     dsp.nogame.energy_plant_upgrade(1);
//     dsp.nogame.tritium_mine_upgrade(1);
//     start_warp(CheatTarget::All, HOUR * 2400000);
//     dsp.nogame.dockyard_upgrade(5);
//     dsp.nogame.lab_upgrade(4);
//     dsp.nogame.energy_innovation_upgrade(4);
//     dsp.nogame.beam_technology_upgrade(5);
//     dsp.nogame.ion_systems_upgrade(2);
//     dsp.nogame.thrust_propulsion_upgrade(4);

//     dsp.nogame.frigate_build(10);
//     let ships = dsp.nogame.get_ships_levels(1);
//     assert(ships.frigate == 10, 'wrong frigate level');
// }

// #[test]
// fn test_frigate_build_fails_dockyard_level() { // TODO
//     assert(0 == 0, 'todo');
// }

// #[test]
// fn test_frigate_build_fails_ion_level() { // TODO
//     assert(0 == 0, 'todo');
// }

// #[test]
// fn test_frigate_build_fails_thrust_level() { // TODO
//     assert(0 == 0, 'todo');
// }

// #[test]
// fn test_armade_build() {
//     let dsp = set_up();
//     init_game(dsp);

//     start_prank(CheatTarget::One(dsp.nogame.contract_address), ACCOUNT1());
//     dsp.nogame.generate_planet();

//     dsp.nogame.energy_plant_upgrade(1);
//     dsp.nogame.tritium_mine_upgrade(1);
//     start_warp(CheatTarget::All, HOUR * 2400000);
//     dsp.nogame.dockyard_upgrade(7);
//     dsp.nogame.lab_upgrade(7);
//     dsp.nogame.energy_innovation_upgrade(5);
//     dsp.nogame.shield_tech_upgrade(5);
//     dsp.nogame.spacetime_warp_upgrade(3);
//     dsp.nogame.warp_drive_upgrade(4);

//     dsp.nogame.armade_build(10);
//     let ships = dsp.nogame.get_ships_levels(1);
//     assert(ships.armade == 10, 'wrong armade level');
// }

// #[test]
// fn test_armade_build_fails_dockyard_level() { // TODO
//     assert(0 == 0, 'todo');
// }

// #[test]
// fn test_armade_build_fails_warp_level() { // TODO
//     assert(0 == 0, 'todo');
// }


