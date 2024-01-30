use core::testing::get_available_gas;

use nogame::game::interface::{INoGameDispatcher, INoGameDispatcherTrait};
use nogame::libraries::types::{
    ERC20s, EnergyCost, TechLevels, TechsCost, ShipsLevels, ShipsCost, Defences, DefencesCost,
    UpgradeType, BuildType
};
use nogame::storage::storage::{IStorageDispatcher, IStorageDispatcherTrait};

use nogame::token::erc721::interface::{IERC721NoGameDispatcher, IERC721NoGameDispatcherTrait};
use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};

use snforge_std::{declare, ContractClassTrait, start_prank, start_warp, PrintTrait, CheatTarget};
use starknet::info::{get_contract_address, get_block_timestamp};
use starknet::testing::cheatcode;
use starknet::{ContractAddress, contract_address_const};
use tests::utils::{
    E18, HOUR, Dispatchers, ACCOUNT1, ACCOUNT2, DEPLOYER, init_game, set_up, build_basic_mines,
    YEAR, warp_multiple, init_storage,
};

#[test]
fn test_blaster_build() {
    let dsp = set_up();
    init_game(dsp);

    start_prank(CheatTarget::One(dsp.nogame.contract_address), ACCOUNT1());
    dsp.nogame.generate_planet();

    build_basic_mines(dsp.nogame);
    start_warp(CheatTarget::All, HOUR * 2400000);
    dsp.nogame.process_compound_upgrade(UpgradeType::Dockyard(()), 1);

    dsp.nogame.process_defence_build(BuildType::Blaster(()), 10);
    let def = dsp.storage.get_defences_levels(1);
    assert(def.blaster == 10, 'wrong blaster level');
}

#[test]
#[should_panic(expected: ('dockyard 1 required',))]
fn test_blaster_build_fails_dockyard_level() {
    let dsp = set_up();
    init_game(dsp);

    start_prank(CheatTarget::One(dsp.nogame.contract_address), ACCOUNT1());
    dsp.nogame.generate_planet();
    build_basic_mines(dsp.nogame);
    // advance_game_state(dsp.nogame);

    dsp.nogame.process_defence_build(BuildType::Blaster(()), 1);
}

#[test]
fn test_beam_build() {
    let dsp = set_up();
    init_game(dsp);

    start_prank(CheatTarget::One(dsp.nogame.contract_address), ACCOUNT1());
    dsp.nogame.generate_planet();
    init_storage(dsp, 1);

    dsp.nogame.process_defence_build(BuildType::Beam(()), 10);
    let def = dsp.storage.get_defences_levels(1);
    assert(def.beam == 10, 'wrong beam level');
}

#[test]
#[should_panic(expected: ('dockyard 4 required',))]
fn test_beam_build_fails_dockyard_level() {
    let dsp = set_up();
    init_game(dsp);

    start_prank(CheatTarget::One(dsp.nogame.contract_address), ACCOUNT1());
    dsp.nogame.generate_planet();
    build_basic_mines(dsp.nogame);

    dsp.nogame.process_defence_build(BuildType::Beam(()), 2);
}

#[test]
#[should_panic(expected: ('energy innovation 3 required',))]
fn test_beam_build_fails_energy_tech_level() {
    let dsp = set_up();
    init_game(dsp);

    start_prank(CheatTarget::One(dsp.nogame.contract_address), ACCOUNT1());
    dsp.nogame.generate_planet();
    build_basic_mines(dsp.nogame);
    warp_multiple(
        dsp.nogame.contract_address, get_contract_address(), get_block_timestamp() + YEAR
    );
    dsp.nogame.process_compound_upgrade(UpgradeType::Dockyard(()), 4);

    dsp.nogame.process_defence_build(BuildType::Beam(()), 2);
}

#[test]
fn test_astral_build_fails_beam_tech_level() {
    // TODO
    assert(0 == 0, 'todo');
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

#[test]
fn test_plasma_build() {
    let dsp = set_up();
    init_game(dsp);

    start_prank(CheatTarget::One(dsp.nogame.contract_address), ACCOUNT1());
    dsp.nogame.generate_planet();
    init_storage(dsp, 1);

    dsp.nogame.process_defence_build(BuildType::Plasma(()), 1);
    let def = dsp.storage.get_defences_levels(1);
    assert(def.plasma == 1, 'wrong plasma level');
}

#[test]
fn test_plasma_build_fails_dockyard_level() { // TODO
    assert(0 == 0, 'todo');
}

#[test]
fn test_plasma_build_fails_plasma_tech_level() { // TODO
    assert(0 == 0, 'todo');
}
