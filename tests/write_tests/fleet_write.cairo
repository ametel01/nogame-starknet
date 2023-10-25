use starknet::info::{get_block_timestamp, get_contract_address};

use snforge_std::{declare, ContractClassTrait, PrintTrait, start_prank, start_warp};

use nogame::game::interface::{INoGameDispatcher, INoGameDispatcherTrait};
use nogame::libraries::types::{Fleet, Unit, TechLevels, PlanetPosition, ERC20s, DefencesLevels};
use nogame::libraries::fleet;

use tests::utils::{
    ACCOUNT1, ACCOUNT2, set_up, init_game, advance_game_state, build_basic_mines, YEAR,
    warp_multiple
};

#[test]
fn test_send_fleet_success() {
    let dsp = set_up();
    init_game(dsp);

    start_prank(dsp.game.contract_address, ACCOUNT2());
    dsp.game.generate_planet();
    start_prank(dsp.game.contract_address, ACCOUNT1());
    dsp.game.generate_planet();
    build_basic_mines(dsp.game);
    advance_game_state(dsp.game);
    start_prank(dsp.game.contract_address, ACCOUNT2());
    build_basic_mines(dsp.game);
    advance_game_state(dsp.game);

    dsp.game.carrier_build(1);
    dsp.game.scraper_build(1);
    dsp.game.sparrow_build(1);
    dsp.game.frigate_build(1);
    dsp.game.armade_build(1);

    let p2_position = dsp.game.get_planet_position(2);

    let mut fleet: Fleet = Default::default();
    fleet.carrier = 1;
    fleet.scraper = 1;
    fleet.sparrow = 1;
    fleet.frigate = 1;
    fleet.armade = 1;

    assert(dsp.game.get_ships_levels(1).carrier == 1, 'wrong ships before');
    assert(dsp.game.get_ships_levels(1).scraper == 1, 'wrong ships before');
    assert(dsp.game.get_ships_levels(1).sparrow == 1, 'wrong ships before');
    assert(dsp.game.get_ships_levels(1).frigate == 1, 'wrong ships before');
    assert(dsp.game.get_ships_levels(1).armade == 1, 'wrong ships before');

    dsp.game.send_fleet(fleet, p2_position, false);

    assert(dsp.game.get_ships_levels(2).carrier == 0, 'wrong ships after');
    assert(dsp.game.get_ships_levels(2).scraper == 0, 'wrong ships after');
    assert(dsp.game.get_ships_levels(2).sparrow == 0, 'wrong ships after');
    assert(dsp.game.get_ships_levels(2).frigate == 0, 'wrong ships after');
    assert(dsp.game.get_ships_levels(2).armade == 0, 'wrong ships after');

    let mission = dsp.game.get_mission_details(1, 1);
    assert(mission.fleet.carrier == 1, 'wrong carrier');
    assert(mission.fleet.scraper == 1, 'wrong scraper');
    assert(mission.fleet.sparrow == 1, 'wrong sparrow');
    assert(mission.fleet.frigate == 1, 'wrong frigate');
    assert(mission.fleet.armade == 1, 'wrong armade');
}

#[test]
#[should_panic(expected: ('no planet at destination',))]
fn test_send_fleet_fails_no_planet_at_destination() {
    let dsp = set_up();
    init_game(dsp);

    start_prank(dsp.game.contract_address, ACCOUNT1());
    dsp.game.generate_planet();
    build_basic_mines(dsp.game);
    advance_game_state(dsp.game);

    dsp.game.carrier_build(1);

    let p2_position = dsp.game.get_planet_position(2);

    let mut fleet: Fleet = Default::default();
    fleet.carrier = 1;

    dsp.game.send_fleet(fleet, p2_position, false);
}

#[test]
#[should_panic(expected: ('cannot send to own planet',))]
fn test_send_fleet_fails_origin_is_destination() {
    let dsp = set_up();
    init_game(dsp);

    start_prank(dsp.game.contract_address, ACCOUNT1());
    dsp.game.generate_planet();
    build_basic_mines(dsp.game);
    advance_game_state(dsp.game);

    dsp.game.carrier_build(1);

    let p1_position = dsp.game.get_planet_position(1);

    let mut fleet: Fleet = Default::default();
    fleet.carrier = 1;

    dsp.game.send_fleet(fleet, p1_position, false);
}

#[test]
#[should_panic(expected: ('noob protection active',))]
fn test_send_fleet_fails_noob_protection() {
    let dsp = set_up();
    init_game(dsp);

    start_prank(dsp.game.contract_address, ACCOUNT2());
    dsp.game.generate_planet();
    start_prank(dsp.game.contract_address, ACCOUNT1());
    dsp.game.generate_planet();
    build_basic_mines(dsp.game);
    start_prank(dsp.game.contract_address, ACCOUNT2());
    build_basic_mines(dsp.game);
    advance_game_state(dsp.game);

    dsp.game.carrier_build(10);

    let p2_position = dsp.game.get_planet_position(2);

    let mut fleet: Fleet = Default::default();
    fleet.carrier = 5;

    dsp.game.send_fleet(fleet, p2_position, false);
}

#[test]
#[should_panic(expected: ('max active missions',))]
fn test_send_fleet_fails_not_enough_fleet_slots() {
    let dsp = set_up();
    init_game(dsp);

    start_prank(dsp.game.contract_address, ACCOUNT2());
    dsp.game.generate_planet();
    start_prank(dsp.game.contract_address, ACCOUNT1());
    dsp.game.generate_planet();
    build_basic_mines(dsp.game);
    advance_game_state(dsp.game);
    start_prank(dsp.game.contract_address, ACCOUNT2());
    build_basic_mines(dsp.game);
    advance_game_state(dsp.game);

    dsp.game.carrier_build(10);

    let p2_position = dsp.game.get_planet_position(2);

    let mut fleet: Fleet = Default::default();
    fleet.carrier = 5;

    dsp.game.send_fleet(fleet, p2_position, false);
    dsp.game.send_fleet(fleet, p2_position, false);
}

#[test]
fn test_send_fleet_debris_success() { // TODO
    let dsp = set_up();
    init_game(dsp);

    start_prank(dsp.game.contract_address, ACCOUNT1());
    dsp.game.generate_planet();
    start_prank(dsp.game.contract_address, ACCOUNT2());
    dsp.game.generate_planet();
    build_basic_mines(dsp.game);
    advance_game_state(dsp.game);
    dsp.game.plasma_projector_build(1);
    start_prank(dsp.game.contract_address, ACCOUNT1());
    build_basic_mines(dsp.game);
    advance_game_state(dsp.game);
    dsp.game.digital_systems_upgrade();
    dsp.game.carrier_build(10);
    dsp.game.scraper_build(1);
    let p1_position = dsp.game.get_planet_position(2);

    let mut fleet: Fleet = Default::default();
    fleet.carrier = 5;

    dsp.game.send_fleet(fleet, p1_position, false);
    let mission = dsp.game.get_mission_details(1, 1);
    warp_multiple(
        dsp.game.contract_address,
        get_contract_address(),
        get_block_timestamp() + mission.time_arrival + 1
    );
    dsp.game.attack_planet(1);

    let mut fleet: Fleet = Default::default();
    fleet.scraper = 1;
    let debris = dsp.game.get_debris_field(2);
    dsp.game.send_fleet(fleet, p1_position, true);
    let mission = dsp.game.get_mission_details(1, 2);
    warp_multiple(
        dsp.game.contract_address,
        get_contract_address(),
        get_block_timestamp() + mission.time_arrival + 1
    );
    let resources_before = dsp.game.get_spendable_resources(1);
    dsp.game.collect_debris(2);
    assert(dsp.game.get_ships_levels(1).scraper == 1, 'wrong scraper back');
    let resources_after = dsp.game.get_spendable_resources(1);
    assert(resources_after.steel == resources_before.steel + debris.steel, 'wrong steel collected');
    assert(
        resources_after.quartz == resources_before.quartz + debris.quartz, 'wrong quartz collected'
    );
    let debris_after_collection = dsp.game.get_debris_field(2);
    assert(
        debris_after_collection.steel.is_zero() && debris_after_collection.quartz.is_zero(),
        'wrong debris after'
    );
}

#[test]
fn test_send_fleet_debris_fails_empty_debris_field() { // TODO
    assert(0 == 0, 'todo');
}

#[test]
fn test_send_fleet_debris_fails_no_scrapers() { // TODO
    assert(0 == 0, 'todo');
}

#[test]
fn test_send_fleet_debris_fails_not_only_scrapers() { // TODO
    assert(0 == 0, 'todo');
}

#[test]
fn test_attack_planet() {
    let dsp = set_up();
    init_game(dsp);

    start_prank(dsp.game.contract_address, ACCOUNT2());
    dsp.game.generate_planet();
    start_prank(dsp.game.contract_address, ACCOUNT1());
    dsp.game.generate_planet();
    build_basic_mines(dsp.game);
    advance_game_state(dsp.game);
    start_prank(dsp.game.contract_address, ACCOUNT2());
    build_basic_mines(dsp.game);
    advance_game_state(dsp.game);

    dsp.game.sparrow_build(200);
    dsp.game.frigate_build(20);
    dsp.game.blaster_build(20);
    dsp.game.beam_build(20);
    dsp.game.astral_launcher_build(20);
    dsp.game.plasma_projector_build(1);

    start_prank(dsp.game.contract_address, ACCOUNT1());
    dsp.game.sparrow_build(100);
    dsp.game.armade_build(50);

    let p2_position = dsp.game.get_planet_position(1);
    let mut fleet_a: Fleet = Default::default();
    // fleet_a.sparrow = 100;
    fleet_a.armade = 50;
    dsp.game.send_fleet(fleet_a, p2_position, false);
    let mission = dsp.game.get_mission_details(2, 1);
    start_warp(dsp.game.contract_address, mission.time_arrival + 1);
    dsp.game.attack_planet(1);
    'P1 debris'.print();
    dsp.game.get_debris_field(1).print();
    'P1 ships'.print();
    dsp.game.get_ships_levels(1).print();
    'P1 defences'.print();
    dsp.game.get_defences_levels(1).print();
    let mission = dsp.game.get_mission_details(2, 1);
    start_warp(dsp.game.contract_address, mission.time_arrival + 1);
    'P2 ships'.print();
    dsp.game.get_ships_levels(2).print();
// dsp.game.get_mission_details(1, 1).print();
}

#[test]
fn test_attack_planet_fails_empty_mission() { // TODO
    assert(0 == 0, 'todo');
}

#[test]
fn test_attack_planet_fails_destination_not_reached() { // TODO
    assert(0 == 0, 'todo');
}

#[test]
fn test_recall_fleet() { // TODO
    assert(0 == 0, 'todo');
}

#[test]
fn test_recall_fleet_fails_no_fleet_to_recall() { // TODO
    assert(0 == 0, 'todo');
}

#[test]
fn test_recall_fleet_fails_mission_already_returning() { // TODO
    assert(0 == 0, 'todo');
}