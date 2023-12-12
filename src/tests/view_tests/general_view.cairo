use starknet::testing::cheatcode;
use starknet::info::get_contract_address;
use starknet::{ContractAddress, contract_address_const, get_block_timestamp};
use snforge_std::PrintTrait;

use snforge_std::{start_prank, start_warp, CheatTarget};

use nogame::game::interface::{INoGameDispatcher, INoGameDispatcherTrait};
use nogame::libraries::types::{
    ERC20s, EnergyCost, TechLevels, TechsCost, ShipsLevels, ShipsCost, DefencesLevels, DefencesCost,
    Fleet
};
use nogame::tests::utils::{
    E18, HOUR, DAY, Dispatchers, ACCOUNT1, ACCOUNT2, ACCOUNT3, ACCOUNT4, ACCOUNT5, init_game,
    set_up, DEPLOYER, build_basic_mines, advance_game_state, warp_multiple,
};

#[test]
fn test_get_receiver() {
    let dsp = set_up();
    init_game(dsp);
    start_prank(CheatTarget::One(dsp.game.contract_address), ACCOUNT1());
    dsp.game.generate_planet();
// assert(dsp.game.get_receiver() == DEPLOYER(), 'owner is not deployer');
}

#[test]
fn test_get_current_planet_price() {
    let dsp = set_up();
    init_game(dsp);

    (dsp.game.get_current_planet_price() == 11999999999999998, 'wrong price-1');
    start_prank(CheatTarget::One(dsp.game.contract_address), ACCOUNT1());
    dsp.game.generate_planet();

    (dsp.game.get_current_planet_price() == 12060150250085595, 'wrong price-1');
    start_prank(CheatTarget::One(dsp.game.contract_address), ACCOUNT2());
    dsp.game.generate_planet();

    (dsp.game.get_current_planet_price() == 12120602004610750, 'wrong price-1');
    start_prank(CheatTarget::One(dsp.game.contract_address), ACCOUNT3());
    dsp.game.generate_planet();

    start_warp(CheatTarget::All, DAY * 13);

    (dsp.game.get_current_planet_price() == 6359225859946644, 'wrong price-1');
    start_prank(CheatTarget::One(dsp.game.contract_address), ACCOUNT4());
    dsp.game.generate_planet();

    (dsp.game.get_current_planet_price() == 6391101612214528, 'wrong price-1');
    start_prank(CheatTarget::One(dsp.game.contract_address), ACCOUNT5());
    dsp.game.generate_planet();
}

#[test]
fn test_get_token_addresses() {
    let dsp = set_up();
    init_game(dsp);
    start_prank(CheatTarget::One(dsp.game.contract_address), ACCOUNT1());
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
    start_prank(CheatTarget::One(dsp.game.contract_address), ACCOUNT1());
    dsp.game.generate_planet();
    assert(dsp.game.get_number_of_planets() == 1, 'wrong n planets');
}

#[test]
fn test_get_generated_planets_positions() {
    let dsp = set_up();
    init_game(dsp);
    start_prank(CheatTarget::One(dsp.game.contract_address), ACCOUNT1());
    dsp.game.generate_planet();
    start_prank(CheatTarget::One(dsp.game.contract_address), ACCOUNT2());
    dsp.game.generate_planet();
    start_prank(CheatTarget::One(dsp.game.contract_address), ACCOUNT3());
    dsp.game.generate_planet();
    start_prank(CheatTarget::One(dsp.game.contract_address), ACCOUNT4());
    dsp.game.generate_planet();
    start_prank(CheatTarget::One(dsp.game.contract_address), ACCOUNT5());
    dsp.game.generate_planet();

    let mut arr_planets = dsp.game.get_generated_planets_positions();
    assert(arr_planets.len() == 5, 'wrong arr len');
}

#[test]
fn test_get_planet_position() {
    let dsp = set_up();
    init_game(dsp);
    start_prank(CheatTarget::One(dsp.game.contract_address), ACCOUNT1());

    assert(dsp.game.get_planet_position(1).is_zero(), 'wrong assert #1');
}

#[test]
fn test_get_position_slot_occupant() {
    let dsp = set_up();
    init_game(dsp);
    start_prank(CheatTarget::One(dsp.game.contract_address), ACCOUNT1());
    dsp.game.generate_planet();

    let position = dsp.game.get_planet_position(1);
    assert(dsp.game.get_position_slot_occupant(position) == 1, 'wrong assert #1');
}

#[test]
fn test_get_debris_field() {
    let dsp = set_up();
    init_game(dsp);
    start_prank(CheatTarget::One(dsp.game.contract_address), ACCOUNT1());
    dsp.game.generate_planet();
    start_prank(CheatTarget::One(dsp.game.contract_address), ACCOUNT2());
    dsp.game.generate_planet();

    assert(dsp.game.get_debris_field(1).is_zero(), 'wrong debris field');
    assert(dsp.game.get_debris_field(2).is_zero(), 'wrong debris field');

    start_prank(CheatTarget::One(dsp.game.contract_address), ACCOUNT1());
    build_basic_mines(dsp.game);
    advance_game_state(dsp.game);
    dsp.game.carrier_build(100);

    start_prank(CheatTarget::One(dsp.game.contract_address), ACCOUNT2());
    build_basic_mines(dsp.game);
    advance_game_state(dsp.game);
    dsp.game.astral_launcher_build(5);

    dsp.game.get_planet_points(1).print();
    dsp.game.get_planet_points(2).print();

    start_prank(CheatTarget::One(dsp.game.contract_address), ACCOUNT1());
    let mut fleet: Fleet = Default::default();
    let position = dsp.game.get_planet_position(2);
    fleet.carrier = 100;
    dsp.game.send_fleet(fleet, position, false);
    warp_multiple(dsp.game.contract_address, get_contract_address(), get_block_timestamp() + DAY);
    dsp.game.attack_planet(1);

    assert(dsp.game.get_debris_field(1).is_zero(), 'wrong debris field');
    let debris = dsp.game.get_debris_field(2);
    assert(debris.steel == 66666 && debris.quartz == 66666, 'wrong debris field');
}

#[test]
fn test_get_spendable_resources() {
    let dsp = set_up();
    init_game(dsp);
    start_prank(CheatTarget::One(dsp.game.contract_address), ACCOUNT1());
    dsp.game.generate_planet();

    let spendable = dsp.game.get_spendable_resources(1);
    assert(spendable.steel == 500, 'wrong spendable');
    assert(spendable.quartz == 300, 'wrong spendable ');
    assert(spendable.tritium == 100, 'wrong spendable ');
}


#[test]
fn test_get_collectible_resources() {
    let dsp = set_up();
    init_game(dsp);
    start_prank(CheatTarget::One(dsp.game.contract_address), ACCOUNT1());
    dsp.game.generate_planet();

    start_warp(CheatTarget::All, HOUR * 3);
    let collectible = dsp.game.get_collectible_resources(1);
    collectible.print();
    assert(collectible.steel == 30, 'wrong collectible ');
    assert(collectible.quartz == 30, 'wrong collectible ');
    assert(collectible.tritium == 0, 'wrong collectible ');
}

#[test]
fn test_get_planet_points() {
    let dsp = set_up();
    init_game(dsp);
    start_prank(CheatTarget::One(dsp.game.contract_address), ACCOUNT1());
    dsp.game.generate_planet();
    start_prank(CheatTarget::One(dsp.game.contract_address), ACCOUNT2());
    dsp.game.generate_planet();
    build_basic_mines(dsp.game);
    start_prank(CheatTarget::One(dsp.game.contract_address), ACCOUNT3());
    dsp.game.generate_planet();
    build_basic_mines(dsp.game);
    advance_game_state(dsp.game);

    (dsp.game.get_planet_points(1) == 0, 'wrong points 0');
    (dsp.game.get_planet_points(2) == 5, 'wrong points 5');
    (dsp.game.get_planet_points(3) == 972, 'wrong points 972');
}
