use starknet::testing::cheatcode;
use starknet::info::get_contract_address;
use starknet::{ContractAddress, contract_address_const};
use snforge_std::{start_prank, start_warp, CheatTarget, PrintTrait};

use nogame::game::interface::{INoGameDispatcher, INoGameDispatcherTrait};
use nogame::libraries::types::{
    ERC20s, EnergyCost, TechLevels, TechsCost, ShipsLevels, ShipsCost, DefencesLevels, DefencesCost,
    Fleet
};
use tests::utils::{
    E18, HOUR, Dispatchers, ACCOUNT1, ACCOUNT2, ACCOUNT3, ACCOUNT4, init_game, set_up,
    build_basic_mines, advance_game_state
};

#[test]
fn test_is_noob_protected() {
    let dsp = set_up();
    init_game(dsp);

    start_prank(CheatTarget::One(dsp.game.contract_address), ACCOUNT1());
    dsp.game.generate_planet();
    start_prank(CheatTarget::One(dsp.game.contract_address), ACCOUNT2());
    dsp.game.generate_planet();
    build_basic_mines(dsp.game);
    advance_game_state(dsp.game);
    start_prank(CheatTarget::One(dsp.game.contract_address), ACCOUNT1());
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
fn test_get_hostile_missions() {
    let dsp = set_up();
    init_game(dsp);

    start_prank(CheatTarget::One(dsp.game.contract_address), ACCOUNT1());
    dsp.game.generate_planet();
    start_prank(CheatTarget::One(dsp.game.contract_address), ACCOUNT2());
    dsp.game.generate_planet();
    build_basic_mines(dsp.game);
    advance_game_state(dsp.game);
    start_prank(CheatTarget::One(dsp.game.contract_address), ACCOUNT1());
    build_basic_mines(dsp.game);
    advance_game_state(dsp.game);
    dsp.game.digital_systems_upgrade(4);

    dsp.game.carrier_build(5);

    let p2_position = dsp.game.get_planet_position(2);

    let mut fleet: Fleet = Default::default();
    fleet.carrier = 1;

    dsp.game.send_fleet(fleet, p2_position, false);
    dsp.game.send_fleet(fleet, p2_position, false);
    dsp.game.send_fleet(fleet, p2_position, false);

    let mut missions = dsp.game.get_hostile_missions(2);
    assert(missions.len() == 3, 'wrong missions len #1');
    assert(*missions.at(0).origin == 1, 'wrong origin #2');
    assert(*missions.at(0).id_at_origin == 1, 'wrong id at origin #3');
    assert(*missions.at(1).origin == 1, 'wrong origin #4');
    assert(*missions.at(1).id_at_origin == 2, 'wrong id at origin #5');
    assert(*missions.at(2).origin == 1, 'wrong origin #6');
    assert(*missions.at(2).id_at_origin == 3, 'wrong id at origin #7');

    dsp.game.recall_fleet(1);
    let mut missions = dsp.game.get_hostile_missions(2);
    assert(missions.len() == 2, 'wrong missions len 2 #8');
    assert(*missions.at(0).origin == 1, 'wrong origin #9');
    assert(*missions.at(0).id_at_origin == 2, 'wrong id at origin #10');
    assert(*missions.at(1).origin == 1, 'wrong origin #11');
    assert(*missions.at(1).id_at_origin == 3, 'wrong id at origin #12');

    dsp.game.recall_fleet(3);
    let mut missions = dsp.game.get_hostile_missions(2);
    assert(missions.len() == 1, 'wrong missions len 1 #13');
    assert(*missions.at(0).origin == 1, 'wrong origin #14');
    assert(*missions.at(0).id_at_origin == 2, 'wrong id at origin #15');

    dsp.game.send_fleet(fleet, p2_position, false);
    let mut missions = dsp.game.get_hostile_missions(2);
    assert(missions.len() == 2, 'wrong missions len 2 #16');
    assert(*missions.at(0).origin == 1, 'wrong origin #17');
    assert(*missions.at(0).id_at_origin == 1, 'wrong id at origin 2 #18');
    assert(*missions.at(1).origin == 1, 'wrong origin #19');
    assert(*missions.at(1).id_at_origin == 2, 'wrong id at origin 1 #20');

    dsp.game.recall_fleet(2);
    let mut missions = dsp.game.get_hostile_missions(2);
    assert(missions.len() == 1, 'wrong missions len 1 #21');
    assert(*missions.at(0).origin == 1, 'wrong origin #22');
    assert(*missions.at(0).id_at_origin == 1, 'wrong id at origin 1 #23');

    dsp.game.recall_fleet(1);
    let mut missions = dsp.game.get_hostile_missions(2);
    assert(missions.len() == 0, 'wrong missions len 1 #24');
}

#[test]
fn test_get_active_missions() {
    let dsp = set_up();
    init_game(dsp);

    start_prank(CheatTarget::One(dsp.game.contract_address), ACCOUNT1());
    dsp.game.generate_planet();
    start_prank(CheatTarget::One(dsp.game.contract_address), ACCOUNT2());
    dsp.game.generate_planet();
    build_basic_mines(dsp.game);
    advance_game_state(dsp.game);
    start_prank(CheatTarget::One(dsp.game.contract_address), ACCOUNT1());
    build_basic_mines(dsp.game);
    advance_game_state(dsp.game);
    dsp.game.digital_systems_upgrade(4);

    dsp.game.carrier_build(5);

    let p2_position = dsp.game.get_planet_position(2);

    let mut fleet: Fleet = Default::default();
    fleet.carrier = 1;

    dsp.game.send_fleet(fleet, p2_position, false);
    dsp.game.send_fleet(fleet, p2_position, false);
    dsp.game.send_fleet(fleet, p2_position, false);

    let mut missions = dsp.game.get_active_missions(1);
    assert(missions.len() == 3, 'wrong assert #1');
    assert(*missions.at(0).id == 1, 'wrong assert #2');
    assert(*missions.at(0).destination == 2, 'wrong assert #3');
    assert(*missions.at(0).is_debris == false, 'wrong assert #4');

    assert(*missions.at(1).id == 2, 'wrong assert #5');
    assert(*missions.at(1).destination == 2, 'wrong assert #6');
    assert(*missions.at(1).is_debris == false, 'wrong assert #7');

    assert(*missions.at(2).id == 3, 'wrong assert #8');
    assert(*missions.at(2).destination == 2, 'wrong assert #9');
    assert(*missions.at(2).is_debris == false, 'wrong assert #10');

    dsp.game.recall_fleet(1);
    let mut missions = dsp.game.get_active_missions(1);
    assert(missions.len() == 2, 'wrong assert #11');

    assert(*missions.at(0).id == 2, 'wrong assert #12');
    assert(*missions.at(0).is_debris == false, 'wrong assert #13');

    assert(*missions.at(1).id == 3, 'wrong assert #14');
    assert(*missions.at(1).is_debris == false, 'wrong assert #15');

    dsp.game.recall_fleet(3);
    let mut missions = dsp.game.get_active_missions(1);
    assert(missions.len() == 1, 'wrong assert #16');

    assert(*missions.at(0).id == 2, 'wrong assert #17');
    assert(*missions.at(0).is_debris == false, 'wrong assert #18');

    dsp.game.send_fleet(fleet, p2_position, false);
    let mut missions = dsp.game.get_active_missions(1);
    assert(missions.len() == 2, 'wrong assert #19');

    assert(*missions.at(0).id == 1, 'wrong assert #20');
    assert(*missions.at(0).is_debris == false, 'wrong assert #21');

    assert(*missions.at(1).id == 2, 'wrong assert #22');
    assert(*missions.at(1).is_debris == false, 'wrong assert #23');

    dsp.game.recall_fleet(1);
    let mut missions = dsp.game.get_active_missions(1);
    assert(missions.len() == 1, 'wrong assert #24');

    assert(*missions.at(0).id == 2, 'wrong assert #25');
    assert(*missions.at(0).is_debris == false, 'wrong assert #26');

    dsp.game.recall_fleet(2);
    let mut missions = dsp.game.get_active_missions(1);
    assert(missions.len() == 0, 'wrong assert #27');
}
