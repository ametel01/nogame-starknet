use starknet::testing::cheatcode;
use starknet::info::get_contract_address;
use starknet::{ContractAddress, contract_address_const};
use snforge_std::PrintTrait;
use snforge_std::{start_prank, start_warp};

use nogame::game::interface::{INoGameDispatcher, INoGameDispatcherTrait};
use nogame::libraries::compounds::{Production,Compounds};
use nogame::libraries::types::CompoundsLevels;
use nogame::tests::utils::{
    E18, HOUR, Dispatchers, ACCOUNT1, ACCOUNT2, ACCOUNT3, ACCOUNT4, ACCOUNT5, init_game, set_up,
    build_basic_mines
};

#[test]
fn test_energy_available_positive() {
    let dsp = set_up();
    init_game(dsp);
    start_prank(dsp.game.contract_address, ACCOUNT1());
    dsp.game.generate_planet();

    build_basic_mines(dsp.game);
    let energy = dsp.game.get_energy_available(1879);
    energy.print();
    assert(energy == 95, 'wrong pos energy');
}

#[test]
fn test_energy_available_negative() {
    let dsp = set_up();
    init_game(dsp);
    start_prank(dsp.game.contract_address, ACCOUNT1());
    dsp.game.generate_planet();

    assert(dsp.game.get_energy_available(1879) == 0, 'wrong energy');
    dsp.game.steel_mine_upgrade();
    dsp.game.quartz_mine_upgrade();
    let energy = dsp.game.get_energy_available(1879);

    assert(energy == 0, 'wrong neg energy');
}

#[test]
fn test_get_compounds_levels() {
    let dsp = set_up();
    init_game(dsp);
    start_prank(dsp.game.contract_address, ACCOUNT1());
    dsp.game.generate_planet();

    let compounds = dsp.game.get_compounds_levels(1879);
    assert(compounds.steel == 0, 'wrong steel lev');
    assert(compounds.quartz == 0, 'wrong quartz lev');
    assert(compounds.tritium == 0, 'wrong quartz lev');
    assert(compounds.energy == 0, 'wrong energy lev');
    assert(compounds.lab == 0, 'wrong energy lev');
    assert(compounds.dockyard == 0, 'wrong energy lev');
}

#[test]
fn test_get_compounds_upgrade_cost() {
    let dsp = set_up();
    init_game(dsp);
    start_prank(dsp.game.contract_address, ACCOUNT1());
    dsp.game.generate_planet();

    let costs = dsp.game.get_compounds_upgrade_cost(1879);
    assert(costs.steel.steel == 60 && costs.steel.quartz == 15, 'wrong steel cost');
    assert(costs.quartz.steel == 48 && costs.quartz.quartz == 24, 'wrong quartz cost');
    assert(costs.tritium.steel == 225 && costs.tritium.quartz == 75, 'wrong tritium cost');
    assert(costs.energy.steel == 75 && costs.energy.quartz == 30, 'wrong energy cost');
    assert(
        costs.lab.steel == 200 && costs.lab.quartz == 400 && costs.lab.tritium == 200,
        'wrong lab cost'
    );
    assert(
        costs.dockyard.steel == 400
            && costs.dockyard.quartz == 200
            && costs.dockyard.tritium == 100,
        'wrong dockyard cost'
    );
}

#[test]
fn test_get_energy_for_upgrade() {
    let dsp = set_up();
    init_game(dsp);
    start_prank(dsp.game.contract_address, ACCOUNT1());
    dsp.game.generate_planet();

    let costs = dsp.game.get_energy_for_upgrade(1879);
    assert(costs.steel == 11, 'wrong steel energy');
    assert(costs.quartz == 11, 'wrong quartz energy');
    assert(costs.tritium == 22, 'wrong tritium energy');
}

#[test]
fn test_get_energy_gain_after_upgrade() {
    let dsp = set_up();
    init_game(dsp);
    start_prank(dsp.game.contract_address, ACCOUNT1());
    dsp.game.generate_planet();
    build_basic_mines(dsp.game);

    let compounds = dsp.game.get_compounds_levels(1879);
    let current_production = Production::energy(compounds.energy);
    let upgraded_production = Production::energy(compounds.energy + 1);
    let actual_value_returned = dsp.game.get_energy_gain_after_upgrade(1879);
    assert(actual_value_returned == upgraded_production - current_production, 'wrong energy gain');
}

#[test]
fn test_get_celestia_production() {
    let dsp = set_up();
    init_game(dsp);
    start_prank(dsp.game.contract_address, ACCOUNT1());
    dsp.game.generate_planet();
    start_prank(dsp.game.contract_address, ACCOUNT2());
    dsp.game.generate_planet();
    start_prank(dsp.game.contract_address, ACCOUNT3());
    dsp.game.generate_planet();
    start_prank(dsp.game.contract_address, ACCOUNT4());
    dsp.game.generate_planet();
    start_prank(dsp.game.contract_address, ACCOUNT5());
    dsp.game.generate_planet();

    (dsp.game.get_celestia_production(1879) == 14, 'wrong energy produced');
    (dsp.game.get_celestia_production(1552) == 41, 'wrong energy produced');
    (dsp.game.get_celestia_production(601) == 48, 'wrong energy produced');
    (dsp.game.get_celestia_production(1312) == 41, 'wrong energy produced');
    (dsp.game.get_celestia_production(659) == 14, 'wrong energy produced');
}
