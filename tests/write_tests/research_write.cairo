use core::testing::get_available_gas;
use starknet::testing::cheatcode;
use starknet::info::{get_contract_address, get_block_timestamp};
use starknet::{ContractAddress, contract_address_const};
use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};

use snforge_std::{declare, ContractClassTrait, start_prank, start_warp, PrintTrait};

use nogame::game::interface::{INoGameDispatcher, INoGameDispatcherTrait};
use nogame::libraries::types::{
    ERC20s, EnergyCost, TechLevels, TechsCost, ShipsLevels, ShipsCost, DefencesLevels, DefencesCost
};
use nogame::token::erc20::{INGERC20Dispatcher, INGERC20DispatcherTrait};
use nogame::token::erc721::{IERC721NoGameDispatcher, IERC721NoGameDispatcherTrait};
use tests::utils::{E18, HOUR, Dispatchers, ACCOUNT1, ACCOUNT2, DEPLOYER, init_game, set_up};

#[test]
fn test_energy_upgrade() { // TODO
    assert(0 == 0, 'todo');
}

#[test]
fn test_energy_upgrade_fails_lab_level() { // TODO
    assert(0 == 0, 'todo');
}

#[test]
fn test_digital_upgrade() {
    let dsp = set_up();
    init_game(dsp);

    start_prank(dsp.game.contract_address, ACCOUNT1());
    dsp.game.generate_planet();

    dsp.game.energy_plant_upgrade();
    dsp.game.tritium_mine_upgrade();
    start_warp(dsp.game.contract_address, HOUR * 2400000);
    dsp.game.lab_upgrade();

    dsp.game.digital_systems_upgrade();
    let techs = dsp.game.get_techs_levels(1);
    assert(techs.digital == 1, 'wrong digital level');
}

#[test]
fn test_digital_upgrade_fails_lab_level() { // TODO
    assert(0 == 0, 'todo');
}

#[test]
fn test_beam_upgrade() {
    let dsp = set_up();
    init_game(dsp);

    start_prank(dsp.game.contract_address, ACCOUNT1());
    dsp.game.generate_planet();

    dsp.game.energy_plant_upgrade();
    dsp.game.tritium_mine_upgrade();
    start_warp(dsp.game.contract_address, HOUR * 2400000);
    dsp.game.lab_upgrade();
    dsp.game.energy_innovation_upgrade();
    dsp.game.energy_innovation_upgrade();

    dsp.game.beam_technology_upgrade();
    let techs = dsp.game.get_techs_levels(1);
    assert(techs.beam == 1, 'wrong beam level');
}

#[test]
fn test_beam_upgrade_fails_lab_level() { // TODO
    assert(0 == 0, 'todo');
}

#[test]
fn test_beam_upgrade_fails_energy_tech_level() { // TODO
    assert(0 == 0, 'todo');
}

#[test]
fn test_armour_upgrade() {
    let dsp = set_up();
    init_game(dsp);

    start_prank(dsp.game.contract_address, ACCOUNT1());
    dsp.game.generate_planet();

    dsp.game.energy_plant_upgrade();
    dsp.game.tritium_mine_upgrade();
    start_warp(dsp.game.contract_address, HOUR * 2400000);
    dsp.game.lab_upgrade();
    dsp.game.lab_upgrade();

    dsp.game.armour_innovation_upgrade();
    let techs = dsp.game.get_techs_levels(1);
    assert(techs.armour == 1, 'wrong armour level');
}

#[test]
fn test_armour_upgrade_fails_lab_level() { // TODO
    assert(0 == 0, 'todo');
}

#[test]
fn test_ion_upgrade() {
    let dsp = set_up();
    init_game(dsp);

    start_prank(dsp.game.contract_address, ACCOUNT1());
    dsp.game.generate_planet();

    dsp.game.energy_plant_upgrade();
    dsp.game.tritium_mine_upgrade();
    start_warp(dsp.game.contract_address, HOUR * 2400000);
    dsp.game.lab_upgrade();
    dsp.game.lab_upgrade();
    dsp.game.lab_upgrade();
    dsp.game.lab_upgrade();
    dsp.game.energy_innovation_upgrade();
    dsp.game.energy_innovation_upgrade();
    dsp.game.energy_innovation_upgrade();
    dsp.game.energy_innovation_upgrade();

    dsp.game.beam_technology_upgrade();
    dsp.game.beam_technology_upgrade();
    dsp.game.beam_technology_upgrade();
    dsp.game.beam_technology_upgrade();
    dsp.game.beam_technology_upgrade();

    dsp.game.ion_systems_upgrade();
    let techs = dsp.game.get_techs_levels(1);
    assert(techs.ion == 1, 'wrong ion level');
}

#[test]
fn test_ion_upgrade_fails_lab_level() { // TODO
    assert(0 == 0, 'todo');
}

#[test]
fn test_ion_upgrade_fails_energy_level() { // TODO
    assert(0 == 0, 'todo');
}

#[test]
fn test_ion_upgrade_fails_beam_level() { // TODO
    assert(0 == 0, 'todo');
}

#[test]
fn test_plasma_upgrade() {
    let dsp = set_up();
    init_game(dsp);

    start_prank(dsp.game.contract_address, ACCOUNT1());
    dsp.game.generate_planet();

    dsp.game.energy_plant_upgrade();
    dsp.game.tritium_mine_upgrade();
    start_warp(dsp.game.contract_address, HOUR * 2400000);
    dsp.game.lab_upgrade();
    dsp.game.lab_upgrade();
    dsp.game.lab_upgrade();
    dsp.game.lab_upgrade();
    dsp.game.energy_innovation_upgrade();
    dsp.game.energy_innovation_upgrade();
    dsp.game.energy_innovation_upgrade();
    dsp.game.energy_innovation_upgrade();
    dsp.game.energy_innovation_upgrade();
    dsp.game.energy_innovation_upgrade();
    dsp.game.energy_innovation_upgrade();
    dsp.game.energy_innovation_upgrade();
    dsp.game.beam_technology_upgrade();
    dsp.game.beam_technology_upgrade();
    dsp.game.beam_technology_upgrade();
    dsp.game.beam_technology_upgrade();
    dsp.game.beam_technology_upgrade();
    dsp.game.beam_technology_upgrade();
    dsp.game.beam_technology_upgrade();
    dsp.game.beam_technology_upgrade();
    dsp.game.beam_technology_upgrade();
    dsp.game.beam_technology_upgrade();
    dsp.game.ion_systems_upgrade();
    dsp.game.ion_systems_upgrade();
    dsp.game.ion_systems_upgrade();
    dsp.game.ion_systems_upgrade();
    dsp.game.ion_systems_upgrade();

    dsp.game.plasma_engineering_upgrade();
    let techs = dsp.game.get_techs_levels(1);
    assert(techs.plasma == 1, 'wrong plasma level');
}

#[test]
fn test_plasma_upgrade_fails_lab_level() { // TODO
    assert(0 == 0, 'todo');
}

#[test]
fn test_plasma_upgrade_fails_energy_level() { // TODO
    assert(0 == 0, 'todo');
}

#[test]
fn test_plasma_upgrade_fails_beam_level() { // TODO
    assert(0 == 0, 'todo');
}

#[test]
fn test_plasma_upgrade_fails_ion_level() { // TODO
    assert(0 == 0, 'todo');
}

#[test]
fn test_weapons_upgrade() {
    let dsp = set_up();
    init_game(dsp);

    start_prank(dsp.game.contract_address, ACCOUNT1());
    dsp.game.generate_planet();

    dsp.game.energy_plant_upgrade();
    dsp.game.tritium_mine_upgrade();
    start_warp(dsp.game.contract_address, HOUR * 2400000);
    dsp.game.lab_upgrade();
    dsp.game.lab_upgrade();
    dsp.game.lab_upgrade();
    dsp.game.lab_upgrade();

    dsp.game.weapons_development_upgrade();
    let techs = dsp.game.get_techs_levels(1);
    assert(techs.weapons == 1, 'wrong weapons level');
}

#[test]
fn test_weapons_upgrade_fails_lab_level() { // TODO
    assert(0 == 0, 'todo');
}

#[test]
fn test_combustion_upgrade() {
    let dsp = set_up();
    init_game(dsp);

    start_prank(dsp.game.contract_address, ACCOUNT1());
    dsp.game.generate_planet();

    dsp.game.energy_plant_upgrade();
    dsp.game.tritium_mine_upgrade();
    start_warp(dsp.game.contract_address, HOUR * 2400000);
    dsp.game.lab_upgrade();
    dsp.game.energy_innovation_upgrade();

    dsp.game.combustive_engine_upgrade();
    let techs = dsp.game.get_techs_levels(1);
    assert(techs.combustion == 1, 'wrong combustion level');
}

#[test]
fn test_combustion_upgrade_fails_lab_level() { // TODO
    assert(0 == 0, 'todo');
}

#[test]
fn test_combustion_upgrade_fails_energy_level() { // TODO
    assert(0 == 0, 'todo');
}

#[test]
fn test_thrust_upgrade() {
    let dsp = set_up();
    init_game(dsp);

    start_prank(dsp.game.contract_address, ACCOUNT1());
    dsp.game.generate_planet();

    dsp.game.energy_plant_upgrade();
    dsp.game.tritium_mine_upgrade();
    start_warp(dsp.game.contract_address, HOUR * 2400000);
    dsp.game.lab_upgrade();
    dsp.game.lab_upgrade();
    dsp.game.energy_innovation_upgrade();

    dsp.game.thrust_propulsion_upgrade();
    let techs = dsp.game.get_techs_levels(1);
    assert(techs.thrust == 1, 'wrong thrust level');
}

#[test]
fn test_thrust_upgrade_fails_lab_level() { // TODO
    assert(0 == 0, 'todo');
}

#[test]
fn test_thrust_upgrade_fails_energy_level() { // TODO
    assert(0 == 0, 'todo');
}

#[test]
fn test_warp_upgrade() {
    let dsp = set_up();
    init_game(dsp);

    start_prank(dsp.game.contract_address, ACCOUNT1());
    dsp.game.generate_planet();

    dsp.game.energy_plant_upgrade();
    dsp.game.tritium_mine_upgrade();
    start_warp(dsp.game.contract_address, HOUR * 2400000);
    dsp.game.lab_upgrade();
    dsp.game.lab_upgrade();
    dsp.game.lab_upgrade();
    dsp.game.lab_upgrade();
    dsp.game.lab_upgrade();
    dsp.game.lab_upgrade();
    dsp.game.lab_upgrade();
    dsp.game.energy_innovation_upgrade();
    dsp.game.energy_innovation_upgrade();
    dsp.game.energy_innovation_upgrade();
    dsp.game.energy_innovation_upgrade();
    dsp.game.energy_innovation_upgrade();
    dsp.game.shield_tech_upgrade();
    dsp.game.shield_tech_upgrade();
    dsp.game.shield_tech_upgrade();
    dsp.game.shield_tech_upgrade();
    dsp.game.shield_tech_upgrade();
    dsp.game.spacetime_warp_upgrade();
    dsp.game.spacetime_warp_upgrade();
    dsp.game.spacetime_warp_upgrade();

    dsp.game.warp_drive_upgrade();
    let techs = dsp.game.get_techs_levels(1);
    assert(techs.warp == 1, 'wrong warp level');
}

#[test]
fn test_warp_upgrade_fails_lab_level() { // TODO
    assert(0 == 0, 'todo');
}

#[test]
fn test_warp_upgrade_fails_energy_level() { // TODO
    assert(0 == 0, 'todo');
}

#[test]
fn test_warp_upgrade_fails_spacetime_level() { // TODO
    assert(0 == 0, 'todo');
}

#[test]
fn test_shield_upgrade() {
    let dsp = set_up();
    init_game(dsp);

    start_prank(dsp.game.contract_address, ACCOUNT1());
    dsp.game.generate_planet();

    dsp.game.energy_plant_upgrade();
    dsp.game.tritium_mine_upgrade();
    start_warp(dsp.game.contract_address, HOUR * 2400000);
    dsp.game.lab_upgrade();
    dsp.game.lab_upgrade();
    dsp.game.lab_upgrade();
    dsp.game.lab_upgrade();
    dsp.game.lab_upgrade();
    dsp.game.lab_upgrade();
    dsp.game.energy_innovation_upgrade();
    dsp.game.energy_innovation_upgrade();
    dsp.game.energy_innovation_upgrade();

    dsp.game.shield_tech_upgrade();
    let techs = dsp.game.get_techs_levels(1);
    assert(techs.shield == 1, 'wrong shield level');
}

#[test]
fn test_shield_upgrade_fails_lab_level() { // TODO
    assert(0 == 0, 'todo');
}

#[test]
fn test_shield_upgrade_fails_energy_level() { // TODO
    assert(0 == 0, 'todo');
}

#[test]
fn test_spacetime_upgrade() {
    let dsp = set_up();
    init_game(dsp);

    start_prank(dsp.game.contract_address, ACCOUNT1());
    dsp.game.generate_planet();

    dsp.game.energy_plant_upgrade();
    dsp.game.tritium_mine_upgrade();
    start_warp(dsp.game.contract_address, HOUR * 2400000);
    dsp.game.lab_upgrade();
    dsp.game.lab_upgrade();
    dsp.game.lab_upgrade();
    dsp.game.lab_upgrade();
    dsp.game.lab_upgrade();
    dsp.game.lab_upgrade();
    dsp.game.lab_upgrade();
    dsp.game.energy_innovation_upgrade();
    dsp.game.energy_innovation_upgrade();
    dsp.game.energy_innovation_upgrade();
    dsp.game.energy_innovation_upgrade();
    dsp.game.energy_innovation_upgrade();
    dsp.game.shield_tech_upgrade();
    dsp.game.shield_tech_upgrade();
    dsp.game.shield_tech_upgrade();
    dsp.game.shield_tech_upgrade();
    dsp.game.shield_tech_upgrade();

    dsp.game.spacetime_warp_upgrade();
    let techs = dsp.game.get_techs_levels(1);
    assert(techs.spacetime == 1, 'wrong spacetime level');
}

#[test]
fn test_spacetime_upgrade_fails_lab_level() { // TODO
    assert(0 == 0, 'todo');
}

#[test]
fn test_spacetime_upgrade_fails_energy_level() { // TODO
    assert(0 == 0, 'todo');
}

#[test]
fn test_spacetime_upgrade_fails_shield_level() { // TODO
    assert(0 == 0, 'todo');
}
