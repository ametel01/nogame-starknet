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
fn test_get_token_addresses() {
    let dsp = set_up();
    init_game(dsp);
    start_prank(dsp.game.contract_address, ACCOUNT1());
    dsp.game.generate_planet();

    let tokens = dsp.game.get_token_addresses();
    assert(tokens.erc721 == dsp.erc721.contract_address, 'wrong address');
    assert(tokens.steel == dsp.steel.contract_address, 'wrong address');
    assert(tokens.quartz == dsp.quartz.contract_address, 'wrong address');
    assert(tokens.tritium == dsp.tritium.contract_address, 'wrong address');
}

#[test]
fn test_get_number_of_planets() {
    let dsp = set_up();
    init_game(dsp);
    start_prank(dsp.game.contract_address, ACCOUNT1());
    dsp.game.generate_planet();
    assert(dsp.game.get_number_of_planets() == 1, 'wrong n planets');
}

#[test]
fn test_get_planet_position() {
    let dsp = set_up();
    init_game(dsp);
    start_prank(dsp.game.contract_address, ACCOUNT1());
    dsp.game.generate_planet();

    dsp.game.get_planet_position(1).print();
}

#[test]
fn test_get_position_slot_occupant() {
    let dsp = set_up();
    init_game(dsp);
    start_prank(dsp.game.contract_address, ACCOUNT1());
    dsp.game.generate_planet();

    let position = dsp.game.get_planet_position(1);
    dsp.game.get_position_slot_occupant(position).print();
}

#[test]
fn test_get_spendable_resources() {
    let dsp = set_up();
    init_game(dsp);
    start_prank(dsp.game.contract_address, ACCOUNT1());
    dsp.game.generate_planet();

    let spendable = dsp.game.get_spendable_resources(1);
    spendable.print();
    assert(spendable.steel == 500, 'wrong spendable');
    assert(spendable.quartz == 300, 'wrong spendable ');
    assert(spendable.tritium == 100, 'wrong spendable ');
}


#[test]
fn test_get_collectible_resources() {
    let dsp = set_up();
    init_game(dsp);
    start_prank(dsp.game.contract_address, ACCOUNT1());
    dsp.game.generate_planet();

    start_warp(dsp.game.contract_address, HOUR * 3);
    let collectible = dsp.game.get_collectible_resources(1);
    collectible.print();
    assert(collectible.steel == 30, 'wrong collectible ');
    assert(collectible.quartz == 30, 'wrong collectible ');
    assert(collectible.tritium == 0, 'wrong collectible ');
}

#[test]
fn test_energy_available() {
    let dsp = set_up();
    init_game(dsp);
    start_prank(dsp.game.contract_address, ACCOUNT1());
    dsp.game.generate_planet();

    assert(dsp.game.get_energy_available(1) == 0, 'wrong energy');
}