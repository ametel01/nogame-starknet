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
use nogame::tests::utils::{E18, HOUR, Dispatchers, ACCOUNT1, ACCOUNT2, DEPLOYER, init_game, set_up};

#[test]
fn test_steel_mine_upgrade() {
    let initial = testing::get_available_gas();
    let dsp = set_up();
    init_game(dsp);

    start_prank(CheatTarget::One(dsp.game.contract_address), ACCOUNT1());
    dsp.game.generate_planet();
    dsp.game.steel_mine_upgrade(1);
    let compounds = dsp.game.get_compounds_levels(1);
    assert(compounds.steel == 1, 'wrong steel level');
    (initial - testing::get_available_gas()).print();
}

#[test]
fn test_quartz_mine_upgrade() {
    let dsp = set_up();
    init_game(dsp);

    start_prank(CheatTarget::One(dsp.game.contract_address), ACCOUNT1());
    dsp.game.generate_planet();

    dsp.game.quartz_mine_upgrade(1);
    let compounds = dsp.game.get_compounds_levels(1);
    assert(compounds.quartz == 1, 'wrong quartz level');
}

#[test]
fn test_tritium_mine_upgrade() {
    let dsp = set_up();
    init_game(dsp);

    start_prank(CheatTarget::One(dsp.game.contract_address), ACCOUNT1());
    dsp.game.generate_planet();

    dsp.game.tritium_mine_upgrade(1);
    let compounds = dsp.game.get_compounds_levels(1);
    assert(compounds.tritium == 1, 'wrong tritium level');
}

#[test]
fn test_energy_plant_upgrade() {
    let dsp = set_up();
    init_game(dsp);

    start_prank(CheatTarget::One(dsp.game.contract_address), ACCOUNT1());
    dsp.game.generate_planet();

    dsp.game.energy_plant_upgrade(1);
    let compounds = dsp.game.get_compounds_levels(1);
    assert(compounds.energy == 1, 'wrong plant level');
}

#[test]
fn test_dockyard_upgrade() {
    let dsp = set_up();
    init_game(dsp);

    start_prank(CheatTarget::One(dsp.game.contract_address), ACCOUNT1());
    dsp.game.generate_planet();

    dsp.game.dockyard_upgrade(1);
    let compounds = dsp.game.get_compounds_levels(1);
    assert(compounds.dockyard == 1, 'wrong dockyard level');
}

#[test]
fn test_lab_upgrade() {
    let dsp = set_up();
    init_game(dsp);

    start_prank(CheatTarget::One(dsp.game.contract_address), ACCOUNT1());
    dsp.game.generate_planet();

    dsp.game.energy_plant_upgrade(1);
    dsp.game.tritium_mine_upgrade(1);
    start_warp(CheatTarget::All, HOUR * 240);
    dsp.game.lab_upgrade(1);
    let compounds = dsp.game.get_compounds_levels(1);
    assert(compounds.lab == 1, 'wrong lab level');
}

#[test]
fn test_energy_upgrade() {
    let dsp = set_up();
    init_game(dsp);

    start_prank(CheatTarget::One(dsp.game.contract_address), ACCOUNT1());
    dsp.game.generate_planet();

    dsp.game.energy_plant_upgrade(1);
    dsp.game.tritium_mine_upgrade(1);
    start_warp(CheatTarget::All, HOUR * 2400000);
    dsp.game.lab_upgrade(1);

    dsp.game.energy_innovation_upgrade(1);
    let techs = dsp.game.get_techs_levels(1);
    assert(techs.energy == 1, 'wrong energy level');
}
