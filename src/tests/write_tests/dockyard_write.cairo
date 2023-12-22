use core::testing::get_available_gas;
use starknet::testing::cheatcode;
use starknet::info::{get_contract_address, get_block_timestamp};
use starknet::{ContractAddress, contract_address_const};
use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};

use snforge_std::{declare, ContractClassTrait, start_prank, start_warp, PrintTrait, CheatTarget};

use nogame::game::interface::{INoGameDispatcher, INoGameDispatcherTrait};
use nogame::libraries::types::{
    ERC20s, EnergyCost, TechLevels, TechsCost, ShipsLevels, ShipsCost, DefencesLevels, DefencesCost,
    BuildType, UpgradeType
};
use nogame::token::erc20::interface::{IERC20NGDispatcher, IERC20NGDispatcherTrait};
use nogame::token::erc721::interface::{IERC721NoGameDispatcher, IERC721NoGameDispatcherTrait};
use nogame::tests::utils::{
    E18, HOUR, Dispatchers, ACCOUNT1, ACCOUNT2, DEPLOYER, init_game, set_up, build_basic_mines,
    advance_game_state
};

#[test]
fn test_carrier_build() {
    let dsp = set_up();
    init_game(dsp);

    start_prank(CheatTarget::One(dsp.game.contract_address), ACCOUNT1());
    dsp.game.generate_planet();

    build_basic_mines(dsp.game);
    advance_game_state(dsp.game);

    dsp.game.process_ship_build(BuildType::Carrier(()), 10);
    let ships = dsp.game.get_ships_levels(1);
    assert(ships.carrier == 10, 'wrong carrier level');
}

#[test]
fn test_carrier_build_fails_dockyard_level() { // TODO
    assert(0 == 0, 'todo');
}

#[test]
fn test_carrier_build_fails_combustion_level() { // TODO
    assert(0 == 0, 'todo');
}

#[test]
fn test_celestia_build() {
    let dsp = set_up();
    init_game(dsp);

    start_prank(CheatTarget::One(dsp.game.contract_address), ACCOUNT1());
    dsp.game.generate_planet();

    build_basic_mines(dsp.game);
    advance_game_state(dsp.game);

    dsp.game.process_ship_build(BuildType::Celestia(()), 10);
    let celestia = dsp.game.get_celestia_available(1);
    assert!(celestia == 10, "wrong celestia amount");
}

#[test]
fn test_celestia_build_fails_dockyard_level() { // TODO
    assert(0 == 0, 'todo');
}

#[test]
fn test_celestia_build_fails_combustion_level() { // TODO
    assert(0 == 0, 'todo');
}

#[test]
fn test_sparrow_build() {
    let dsp = set_up();
    init_game(dsp);

    start_prank(CheatTarget::One(dsp.game.contract_address), ACCOUNT1());
    dsp.game.generate_planet();

    build_basic_mines(dsp.game);
    advance_game_state(dsp.game);
    dsp.game.process_ship_build(BuildType::Sparrow(()), 10);
    let ships = dsp.game.get_ships_levels(1);
    assert(ships.sparrow == 10, 'wrong sparrow level');
}

#[test]
fn test_sparrow_build_fails_dockyard_level() { // TODO
    assert(0 == 0, 'todo');
}

#[test]
fn test_sparrow_build_fails_combustion_level() { // TODO
    assert(0 == 0, 'todo');
}

#[test]
fn test_scraper_build() {
    let dsp = set_up();
    init_game(dsp);

    start_prank(CheatTarget::One(dsp.game.contract_address), ACCOUNT1());
    dsp.game.generate_planet();

    build_basic_mines(dsp.game);
    advance_game_state(dsp.game);

    dsp.game.process_ship_build(BuildType::Scraper(()), 10);
    let ships = dsp.game.get_ships_levels(1);
    assert(ships.scraper == 10, 'wrong scraper level');
}

#[test]
fn test_scraper_build_fails_dockyard_level() { // TODO
    assert(0 == 0, 'todo');
}

#[test]
fn test_scraper_build_fails_combustion_level() { // TODO
    assert(0 == 0, 'todo');
}

#[test]
fn test_scraper_build_fails_shield_level() { // TODO
    assert(0 == 0, 'todo');
}

#[test]
fn test_frigate_build() {
    let dsp = set_up();
    init_game(dsp);

    start_prank(CheatTarget::One(dsp.game.contract_address), ACCOUNT1());
    dsp.game.generate_planet();

    build_basic_mines(dsp.game);
    advance_game_state(dsp.game);

    dsp.game.process_ship_build(BuildType::Frigate(()), 10);
    let ships = dsp.game.get_ships_levels(1);
    assert(ships.frigate == 10, 'wrong frigate level');
}

#[test]
fn test_frigate_build_fails_dockyard_level() { // TODO
    assert(0 == 0, 'todo');
}

#[test]
fn test_frigate_build_fails_ion_level() { // TODO
    assert(0 == 0, 'todo');
}

#[test]
fn test_frigate_build_fails_thrust_level() { // TODO
    assert(0 == 0, 'todo');
}

#[test]
fn test_armade_build() {
    let dsp = set_up();
    init_game(dsp);

    start_prank(CheatTarget::One(dsp.game.contract_address), ACCOUNT1());
    dsp.game.generate_planet();

    build_basic_mines(dsp.game);
    advance_game_state(dsp.game);

    dsp.game.process_ship_build(BuildType::Armade(()), 10);
    let ships = dsp.game.get_ships_levels(1);
    assert(ships.armade == 10, 'wrong armade level');
}

#[test]
fn test_armade_build_fails_dockyard_level() { // TODO
    assert(0 == 0, 'todo');
}

#[test]
fn test_armade_build_fails_warp_level() { // TODO
    assert(0 == 0, 'todo');
}
