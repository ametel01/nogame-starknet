use starknet::testing::cheatcode;
use starknet::info::get_contract_address;
use starknet::{ContractAddress, contract_address_const};
use snforge_std::io::PrintTrait;

use snforge_std::{start_prank, start_warp};

use nogame::game::interface::{INoGameDispatcher, INoGameDispatcherTrait};
use nogame::libraries::types::{
    ERC20s, EnergyCost, TechLevels, TechsCost, ShipsLevels, ShipsCost, DefencesLevels, DefencesCost
};
use nogame::token::erc20::{INGERC20Dispatcher, INGERC20DispatcherTrait};
use nogame::token::erc721::{INGERC721Dispatcher, INGERC721DispatcherTrait};
use tests::utils::{E18, HOUR, Dispatchers, ACCOUNT1, ACCOUNT2, init_game, set_up};

#[test]
fn test_energy_available() {
    // TODO: test for i128 values
    let dsp = set_up();
    init_game(dsp);
    start_prank(dsp.game.contract_address, ACCOUNT1());
    dsp.game.generate_planet();

    assert(dsp.game.get_energy_available(1) == 0, 'wrong energy');
}

#[test]
fn test_get_compounds_levels() {
    let dsp = set_up();
    init_game(dsp);
    start_prank(dsp.game.contract_address, ACCOUNT1());
    dsp.game.generate_planet();

    let compounds = dsp.game.get_compounds_levels(1);
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

    let costs = dsp.game.get_compounds_upgrade_cost(1);
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

    let costs = dsp.game.get_energy_for_upgrade(1);
    assert(costs.steel == 11, 'wrong steel energy');
    assert(costs.quartz == 11, 'wrong quartz energy');
    assert(costs.tritium == 22, 'wrong tritium energy');
}

#[test]
fn test_get_energy_gain_after_upgrade() { // TODO
    assert(0 == 0, 'todo');
}

#[test]
fn test_get_celestia_production() { // TODO
    assert(0 == 0, 'todo');
}
