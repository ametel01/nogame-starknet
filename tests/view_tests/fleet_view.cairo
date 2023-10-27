use starknet::testing::cheatcode;
use starknet::info::get_contract_address;
use starknet::{ContractAddress, contract_address_const};
use snforge_std::PrintTrait;

use snforge_std::{start_prank, start_warp};

use nogame::game::interface::{INoGameDispatcher, INoGameDispatcherTrait};
use nogame::libraries::types::{
    ERC20s, EnergyCost, TechLevels, TechsCost, ShipsLevels, ShipsCost, DefencesLevels, DefencesCost,
    Fleet
};
use nogame::token::erc20::{INGERC20Dispatcher, INGERC20DispatcherTrait};
use nogame::token::erc721::{IERC721NoGameDispatcher, IERC721NoGameDispatcherTrait};
use tests::utils::{
    E18, HOUR, Dispatchers, ACCOUNT1, ACCOUNT2, init_game, set_up, build_basic_mines,
    advance_game_state
};

#[test]
fn test_is_noob_protected() {
    let dsp = set_up();
    init_game(dsp);

    start_prank(dsp.game.contract_address, ACCOUNT1());
    dsp.game.generate_planet();
    start_prank(dsp.game.contract_address, ACCOUNT2());
    dsp.game.generate_planet();
    build_basic_mines(dsp.game);
    advance_game_state(dsp.game);
    start_prank(dsp.game.contract_address, ACCOUNT1());
    build_basic_mines(dsp.game);

    assert(dsp.game.is_noob_protected(1, 2) == true, 'wrong noob true');
    assert(dsp.game.is_noob_protected(2, 1) == true, 'wrong noob true');

    advance_game_state(dsp.game);
    assert(dsp.game.is_noob_protected(2, 1) == false, 'wrong noob false');
    assert(dsp.game.is_noob_protected(2, 1) == false, 'wrong noob false');
}

#[test]
fn test_get_mission_details() { // TODO
    assert(0 == 0, 'todo');
}

#[test]
fn test_get_hostile_missions() { // TODO
    let dsp = set_up();
    init_game(dsp);

    start_prank(dsp.game.contract_address, ACCOUNT1());
    dsp.game.generate_planet();
    start_prank(dsp.game.contract_address, ACCOUNT2());
    dsp.game.generate_planet();
    build_basic_mines(dsp.game);
    advance_game_state(dsp.game);
    start_prank(dsp.game.contract_address, ACCOUNT1());
    build_basic_mines(dsp.game);
    advance_game_state(dsp.game);
    dsp.game.digital_systems_upgrade();
    dsp.game.digital_systems_upgrade();
    dsp.game.digital_systems_upgrade();
    dsp.game.digital_systems_upgrade();

    dsp.game.carrier_build(5);

    let p2_position = dsp.game.get_planet_position(2);

    let mut fleet: Fleet = Default::default();
    fleet.carrier = 1;

    dsp.game.send_fleet(fleet, p2_position, false);
    dsp.game.send_fleet(fleet, p2_position, false);
    // dsp.game.send_fleet(fleet, p2_position, false);
    dsp.game.recall_fleet(1);
    dsp.game.send_fleet(fleet, p2_position, false);
    let mut missions = dsp.game.get_hostile_missions(2);
    loop {
        if missions.len().is_zero() {
            break;
        }
        missions.pop_front().unwrap().print();
        '--------------'.print();
    }
}

#[test]
fn test_get_active_missions() { // TODO
    assert(0 == 0, 'todo');
}

#[test]
fn test_get_travel_time() { // TODO
    assert(0 == 0, 'todo');
}

#[test]
fn test_get_fuel_consumption() { // TODO
    assert(0 == 0, 'todo');
}
