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
// use nogame::token::erc721::interface::{IERC721NoGameDispatcher, IERC721NoGameDispatcherTrait};
// use nogame::tests::utils::{E18, HOUR, Dispatchers, ACCOUNT1, ACCOUNT2, DEPLOYER, init_game, set_up};

// #[test]
// fn test_energy_upgrade() { // TODO
//     assert(0 == 0, 'todo');
// }

// #[test]
// fn test_energy_upgrade_fails_lab_level() { // TODO
//     assert(0 == 0, 'todo');
// }

// #[test]
// fn test_digital_upgrade() {
//     let dsp = set_up();
//     init_game(dsp);

//     start_prank(CheatTarget::One(dsp.game.contract_address), ACCOUNT1());
//     dsp.game.generate_planet();

//     dsp.game.energy_plant_upgrade(1);
//     dsp.game.tritium_mine_upgrade(1);
//     start_warp(CheatTarget::All, HOUR * 2400000);
//     dsp.game.lab_upgrade(1);

//     dsp.game.digital_systems_upgrade(1);
//     let techs = dsp.game.get_techs_levels(1);
//     assert(techs.digital == 1, 'wrong digital level');
// }

// #[test]
// fn test_digital_upgrade_fails_lab_level() { // TODO
//     assert(0 == 0, 'todo');
// }

// #[test]
// fn test_beam_upgrade() {
//     let dsp = set_up();
//     init_game(dsp);

//     start_prank(CheatTarget::One(dsp.game.contract_address), ACCOUNT1());
//     dsp.game.generate_planet();

//     dsp.game.energy_plant_upgrade(1);
//     dsp.game.tritium_mine_upgrade(1);
//     start_warp(CheatTarget::All, HOUR * 2400000);
//     dsp.game.lab_upgrade(1);
//     dsp.game.energy_innovation_upgrade(2);

//     dsp.game.beam_technology_upgrade(1);
//     let techs = dsp.game.get_techs_levels(1);
//     assert(techs.beam == 1, 'wrong beam level');
// }

// #[test]
// fn test_beam_upgrade_fails_lab_level() { // TODO
//     assert(0 == 0, 'todo');
// }

// #[test]
// fn test_beam_upgrade_fails_energy_tech_level() { // TODO
//     assert(0 == 0, 'todo');
// }

// #[test]
// fn test_armour_upgrade() {
//     let dsp = set_up();
//     init_game(dsp);

//     start_prank(CheatTarget::One(dsp.game.contract_address), ACCOUNT1());
//     dsp.game.generate_planet();

//     dsp.game.energy_plant_upgrade(1);
//     dsp.game.tritium_mine_upgrade(1);
//     start_warp(CheatTarget::All, HOUR * 2400000);
//     dsp.game.lab_upgrade(2);

//     dsp.game.armour_innovation_upgrade(1);
//     let techs = dsp.game.get_techs_levels(1);
//     assert(techs.armour == 1, 'wrong armour level');
// }

// #[test]
// fn test_armour_upgrade_fails_lab_level() { // TODO
//     assert(0 == 0, 'todo');
// }

// #[test]
// fn test_ion_upgrade() {
//     let dsp = set_up();
//     init_game(dsp);

//     start_prank(CheatTarget::One(dsp.game.contract_address), ACCOUNT1());
//     dsp.game.generate_planet();

//     dsp.game.energy_plant_upgrade(1);
//     dsp.game.tritium_mine_upgrade(1);
//     start_warp(CheatTarget::All, HOUR * 2400000);
//     dsp.game.lab_upgrade(4);
//     dsp.game.energy_innovation_upgrade(4);

//     dsp.game.beam_technology_upgrade(5);

//     dsp.game.ion_systems_upgrade(1);
//     let techs = dsp.game.get_techs_levels(1);
//     assert(techs.ion == 1, 'wrong ion level');
// }

// #[test]
// fn test_ion_upgrade_fails_lab_level() { // TODO
//     assert(0 == 0, 'todo');
// }

// #[test]
// fn test_ion_upgrade_fails_energy_level() { // TODO
//     assert(0 == 0, 'todo');
// }

// #[test]
// fn test_ion_upgrade_fails_beam_level() { // TODO
//     assert(0 == 0, 'todo');
// }

// #[test]
// fn test_plasma_upgrade() {
//     let dsp = set_up();
//     init_game(dsp);

//     start_prank(CheatTarget::One(dsp.game.contract_address), ACCOUNT1());
//     dsp.game.generate_planet();

//     dsp.game.energy_plant_upgrade(1);
//     dsp.game.tritium_mine_upgrade(1);
//     start_warp(CheatTarget::All, HOUR * 2400000);
//     dsp.game.lab_upgrade(4);
//     dsp.game.energy_innovation_upgrade(8);
//     dsp.game.beam_technology_upgrade(10);
//     dsp.game.ion_systems_upgrade(5);

//     dsp.game.plasma_engineering_upgrade(1);
//     let techs = dsp.game.get_techs_levels(1);
//     assert(techs.plasma == 1, 'wrong plasma level');
// }

// #[test]
// fn test_plasma_upgrade_fails_lab_level() { // TODO
//     assert(0 == 0, 'todo');
// }

// #[test]
// fn test_plasma_upgrade_fails_energy_level() { // TODO
//     assert(0 == 0, 'todo');
// }

// #[test]
// fn test_plasma_upgrade_fails_beam_level() { // TODO
//     assert(0 == 0, 'todo');
// }

// #[test]
// fn test_plasma_upgrade_fails_ion_level() { // TODO
//     assert(0 == 0, 'todo');
// }

// #[test]
// fn test_weapons_upgrade() {
//     let dsp = set_up();
//     init_game(dsp);

//     start_prank(CheatTarget::One(dsp.game.contract_address), ACCOUNT1());
//     dsp.game.generate_planet();

//     dsp.game.energy_plant_upgrade(1);
//     dsp.game.tritium_mine_upgrade(1);
//     start_warp(CheatTarget::All, HOUR * 2400000);
//     dsp.game.lab_upgrade(4);

//     dsp.game.weapons_development_upgrade(1);
//     let techs = dsp.game.get_techs_levels(1);
//     assert(techs.weapons == 1, 'wrong weapons level');
// }

// #[test]
// fn test_weapons_upgrade_fails_lab_level() { // TODO
//     assert(0 == 0, 'todo');
// }

// #[test]
// fn test_combustion_upgrade() {
//     let dsp = set_up();
//     init_game(dsp);

//     start_prank(CheatTarget::One(dsp.game.contract_address), ACCOUNT1());
//     dsp.game.generate_planet();

//     dsp.game.energy_plant_upgrade(1);
//     dsp.game.tritium_mine_upgrade(1);
//     start_warp(CheatTarget::All, HOUR * 2400000);
//     dsp.game.lab_upgrade(1);
//     dsp.game.energy_innovation_upgrade(1);

//     dsp.game.combustive_engine_upgrade(1);
//     let techs = dsp.game.get_techs_levels(1);
//     assert(techs.combustion == 1, 'wrong combustion level');
// }

// #[test]
// fn test_combustion_upgrade_fails_lab_level() { // TODO
//     assert(0 == 0, 'todo');
// }

// #[test]
// fn test_combustion_upgrade_fails_energy_level() { // TODO
//     assert(0 == 0, 'todo');
// }

// #[test]
// fn test_thrust_upgrade() {
//     let dsp = set_up();
//     init_game(dsp);

//     start_prank(CheatTarget::One(dsp.game.contract_address), ACCOUNT1());
//     dsp.game.generate_planet();

//     dsp.game.energy_plant_upgrade(1);
//     dsp.game.tritium_mine_upgrade(1);
//     start_warp(CheatTarget::All, HOUR * 2400000);
//     dsp.game.lab_upgrade(2);
//     dsp.game.energy_innovation_upgrade(1);

//     dsp.game.thrust_propulsion_upgrade(1);
//     let techs = dsp.game.get_techs_levels(1);
//     assert(techs.thrust == 1, 'wrong thrust level');
// }

// #[test]
// fn test_thrust_upgrade_fails_lab_level() { // TODO
//     assert(0 == 0, 'todo');
// }

// #[test]
// fn test_thrust_upgrade_fails_energy_level() { // TODO
//     assert(0 == 0, 'todo');
// }

// #[test]
// fn test_warp_upgrade() {
//     let dsp = set_up();
//     init_game(dsp);

//     start_prank(CheatTarget::One(dsp.game.contract_address), ACCOUNT1());
//     dsp.game.generate_planet();

//     dsp.game.energy_plant_upgrade(1);
//     dsp.game.tritium_mine_upgrade(1);
//     start_warp(CheatTarget::All, HOUR * 2400000);
//     dsp.game.lab_upgrade(7);
//     dsp.game.energy_innovation_upgrade(5);
//     dsp.game.shield_tech_upgrade(5);
//     dsp.game.spacetime_warp_upgrade(3);

//     dsp.game.warp_drive_upgrade(1);
//     let techs = dsp.game.get_techs_levels(1);
//     assert(techs.warp == 1, 'wrong warp level');
// }

// #[test]
// fn test_warp_upgrade_fails_lab_level() { // TODO
//     assert(0 == 0, 'todo');
// }

// #[test]
// fn test_warp_upgrade_fails_energy_level() { // TODO
//     assert(0 == 0, 'todo');
// }

// #[test]
// fn test_warp_upgrade_fails_spacetime_level() { // TODO
//     assert(0 == 0, 'todo');
// }

// #[test]
// fn test_shield_upgrade() {
//     let dsp = set_up();
//     init_game(dsp);

//     start_prank(CheatTarget::One(dsp.game.contract_address), ACCOUNT1());
//     dsp.game.generate_planet();

//     dsp.game.energy_plant_upgrade(1);
//     dsp.game.tritium_mine_upgrade(1);
//     start_warp(CheatTarget::All, HOUR * 2400000);
//     dsp.game.lab_upgrade(6);
//     dsp.game.energy_innovation_upgrade(3);

//     dsp.game.shield_tech_upgrade(1);
//     let techs = dsp.game.get_techs_levels(1);
//     assert(techs.shield == 1, 'wrong shield level');
// }

// #[test]
// fn test_shield_upgrade_fails_lab_level() { // TODO
//     assert(0 == 0, 'todo');
// }

// #[test]
// fn test_shield_upgrade_fails_energy_level() { // TODO
//     assert(0 == 0, 'todo');
// }

// #[test]
// fn test_spacetime_upgrade() {
//     let dsp = set_up();
//     init_game(dsp);

//     start_prank(CheatTarget::One(dsp.game.contract_address), ACCOUNT1());
//     dsp.game.generate_planet();

//     dsp.game.energy_plant_upgrade(1);
//     dsp.game.tritium_mine_upgrade(1);
//     start_warp(CheatTarget::All, HOUR * 2400000);
//     dsp.game.lab_upgrade(7);
//     dsp.game.energy_innovation_upgrade(5);
//     dsp.game.shield_tech_upgrade(5);

//     dsp.game.spacetime_warp_upgrade(1);
//     let techs = dsp.game.get_techs_levels(1);
//     assert(techs.spacetime == 1, 'wrong spacetime level');
// }

// #[test]
// fn test_spacetime_upgrade_fails_lab_level() { // TODO
//     assert(0 == 0, 'todo');
// }

// #[test]
// fn test_spacetime_upgrade_fails_energy_level() { // TODO
//     assert(0 == 0, 'todo');
// }

// #[test]
// fn test_spacetime_upgrade_fails_shield_level() { // TODO
//     assert(0 == 0, 'todo');
// }
