use core::testing::get_available_gas;
use starknet::testing::cheatcode;
use starknet::info::{get_contract_address, get_block_timestamp};
use starknet::{ContractAddress, contract_address_const};
use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};

use snforge_std::{declare, ContractClassTrait, start_prank, start_warp, PrintTrait, CheatTarget};

use nogame::game::interface::{INoGameDispatcher, INoGameDispatcherTrait};
use nogame::libraries::types::{
    ERC20s, EnergyCost, TechLevels, TechsCost, ShipsLevels, ShipsCost, DefencesLevels, DefencesCost
};
use nogame::token::erc20::interface::{IERC20NGDispatcher, IERC20NGDispatcherTrait};
use nogame::token::erc721::interface::{IERC721NoGameDispatcher, IERC721NoGameDispatcherTrait};
use nogame::tests::utils::{
    E18, HOUR, Dispatchers, ACCOUNT1, ACCOUNT2, DEPLOYER, init_game, set_up, build_basic_mines,
    YEAR, warp_multiple, advance_game_state
};

#[test]
fn test_blaster_build() {
    let dsp = set_up();
    init_game(dsp);

    start_prank(CheatTarget::One(dsp.game.contract_address), ACCOUNT1());
    dsp.game.generate_planet();

    dsp.game.energy_plant_upgrade(1);
    dsp.game.tritium_mine_upgrade(1);
    start_warp(CheatTarget::All, HOUR * 2400000);
    dsp.game.dockyard_upgrade(1);

    dsp.game.blaster_build(10);
    let def = dsp.game.get_defences_levels(1);
    assert(def.blaster == 10, 'wrong blaster level');
}

#[test]
#[should_panic(expected: ('dockyard 1 required',))]
fn test_blaster_build_fails_dockyard_level() {
    let dsp = set_up();
    init_game(dsp);

    start_prank(CheatTarget::One(dsp.game.contract_address), ACCOUNT1());
    dsp.game.generate_planet();
    build_basic_mines(dsp.game);
    // advance_game_state(dsp.game);

    dsp.game.blaster_build(1);
}

#[test]
fn test_beam_build() {
    let dsp = set_up();
    init_game(dsp);

    start_prank(CheatTarget::One(dsp.game.contract_address), ACCOUNT1());
    dsp.game.generate_planet();

    dsp.game.energy_plant_upgrade(1);
    dsp.game.tritium_mine_upgrade(1);
    start_warp(CheatTarget::All, HOUR * 2400000);
    dsp.game.dockyard_upgrade(2);
    dsp.game.lab_upgrade(1);
    dsp.game.energy_innovation_upgrade(2);
    dsp.game.beam_technology_upgrade(3);

    dsp.game.beam_build(10);
    let def = dsp.game.get_defences_levels(1);
    assert(def.beam == 10, 'wrong beam level');
}

#[test]
#[should_panic(expected: ('dockyard 2 required',))]
fn test_beam_build_fails_dockyard_level() {
    let dsp = set_up();
    init_game(dsp);

    start_prank(CheatTarget::One(dsp.game.contract_address), ACCOUNT1());
    dsp.game.generate_planet();
    build_basic_mines(dsp.game);

    dsp.game.beam_build(1);
}

#[test]
#[should_panic(expected: ('energy innovation 2 required',))]
fn test_beam_build_fails_energy_tech_level() {
    let dsp = set_up();
    init_game(dsp);

    start_prank(CheatTarget::One(dsp.game.contract_address), ACCOUNT1());
    dsp.game.generate_planet();
    build_basic_mines(dsp.game);
    warp_multiple(dsp.game.contract_address, get_contract_address(), get_block_timestamp() + YEAR);
    dsp.game.dockyard_upgrade(1);
    dsp.game.dockyard_upgrade(1);

    dsp.game.beam_build(1);
}

#[test]
fn test_beam_build_fails_beam_tech_level() { // TODO
    assert(0 == 0, 'todo');
}

fn test_astral_build() {
    let dsp = set_up();
    init_game(dsp);

    start_prank(CheatTarget::One(dsp.game.contract_address), ACCOUNT1());
    dsp.game.generate_planet();

    dsp.game.astral_launcher_build(10);
    let def = dsp.game.get_defences_levels(1);
    assert(def.astral == 10, 'wrong astral level');
}

#[test]
fn test_astral_build_fails_dockyard_level() { // TODO
    assert(0 == 0, 'todo');
}

#[test]
fn test_astral_build_fails_energy_tech_level() { // TODO
    assert(0 == 0, 'todo');
}

#[test]
fn test_astral_build_fails_weapons_tech_level() { // TODO
    assert(0 == 0, 'todo');
}

#[test]
fn test_astral_build_fails_shield_tech_level() { // TODO
    assert(0 == 0, 'todo');
}

fn test_plasma_build() {
    let dsp = set_up();
    init_game(dsp);

    start_prank(CheatTarget::One(dsp.game.contract_address), ACCOUNT1());
    dsp.game.generate_planet();

    dsp.game.energy_plant_upgrade(1);
    dsp.game.tritium_mine_upgrade(1);
    start_warp(CheatTarget::All, HOUR * 2400000);
    dsp.game.dockyard_upgrade(1);
    dsp.game.dockyard_upgrade(1);
    dsp.game.dockyard_upgrade(1);
    dsp.game.dockyard_upgrade(1);
    dsp.game.dockyard_upgrade(1);
    dsp.game.dockyard_upgrade(1);
    dsp.game.dockyard_upgrade(1);
    dsp.game.dockyard_upgrade(1); // dockyard #8
    dsp.game.lab_upgrade(1);
    dsp.game.lab_upgrade(1);
    dsp.game.lab_upgrade(1);
    dsp.game.lab_upgrade(1); // lab #4
    dsp.game.energy_innovation_upgrade(1);
    dsp.game.energy_innovation_upgrade(1);
    dsp.game.energy_innovation_upgrade(1);
    dsp.game.energy_innovation_upgrade(1);
    dsp.game.energy_innovation_upgrade(1);
    dsp.game.energy_innovation_upgrade(1);
    dsp.game.energy_innovation_upgrade(1);
    dsp.game.energy_innovation_upgrade(1); // energy #8
    dsp.game.beam_technology_upgrade(1);
    dsp.game.beam_technology_upgrade(1);
    dsp.game.beam_technology_upgrade(1);
    dsp.game.beam_technology_upgrade(1);
    dsp.game.beam_technology_upgrade(1);
    dsp.game.beam_technology_upgrade(1);
    dsp.game.beam_technology_upgrade(1);
    dsp.game.beam_technology_upgrade(1);
    dsp.game.beam_technology_upgrade(1);
    dsp.game.beam_technology_upgrade(1); // beam 10
    dsp.game.ion_systems_upgrade(1);
    dsp.game.ion_systems_upgrade(1);
    dsp.game.ion_systems_upgrade(1);
    dsp.game.ion_systems_upgrade(1);
    dsp.game.ion_systems_upgrade(1); // ion #5
    dsp.game.plasma_engineering_upgrade(1);
    dsp.game.plasma_engineering_upgrade(1);
    dsp.game.plasma_engineering_upgrade(1);
    dsp.game.plasma_engineering_upgrade(1);
    dsp.game.plasma_engineering_upgrade(1);
    dsp.game.plasma_engineering_upgrade(1);
    dsp.game.plasma_engineering_upgrade(1); // plasma #7

    dsp.game.plasma_projector_build(10);
    let def = dsp.game.get_defences_levels(1);
    assert(def.plasma == 10, 'wrong plasma level');
}

#[test]
fn test_plasma_build_fails_dockyard_level() { // TODO
    assert(0 == 0, 'todo');
}

#[test]
fn test_plasma_build_fails_plasma_tech_level() { // TODO
    assert(0 == 0, 'todo');
}
