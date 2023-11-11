use starknet::info::{get_block_timestamp, get_contract_address};

use snforge_std::{
    declare, ContractClassTrait, PrintTrait, start_prank, start_warp, spy_events, SpyOn, EventSpy,
    EventAssertions, EventFetcher, event_name_hash, Event
};

use nogame::game::main::NoGame;

use nogame::game::interface::{INoGameDispatcher, INoGameDispatcherTrait};
use nogame::libraries::types::{Fleet, Unit, TechLevels, PlanetPosition, ERC20s, DefencesLevels};
use nogame::libraries::fleet;

use nogame::tests::utils::{
    ACCOUNT1, ACCOUNT2, set_up, init_game, advance_game_state, build_basic_mines, YEAR,
    warp_multiple, Dispatchers
};

#[test]
fn test_send_fleet_success() {
    let dsp: Dispatchers = set_up();
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

    dsp.game.carrier_build(1);
    dsp.game.scraper_build(1);
    dsp.game.sparrow_build(1);
    dsp.game.frigate_build(1);
    dsp.game.armade_build(1);

    let p2_position = dsp.game.get_planet_position(1552);

    let mut fleet: Fleet = Default::default();
    fleet.carrier = 1;
    fleet.scraper = 1;
    fleet.sparrow = 1;
    fleet.frigate = 1;
    fleet.armade = 1;

    assert(dsp.game.get_ships_levels(1879).carrier == 1, 'wrong ships before');
    assert(dsp.game.get_ships_levels(1879).scraper == 1, 'wrong ships before');
    assert(dsp.game.get_ships_levels(1879).sparrow == 1, 'wrong ships before');
    assert(dsp.game.get_ships_levels(1879).frigate == 1, 'wrong ships before');
    assert(dsp.game.get_ships_levels(1879).armade == 1, 'wrong ships before');

    let tritium_before = dsp.game.get_spendable_resources(1879).tritium;

    dsp.game.send_fleet(fleet, p2_position, false);

    let tritium_after = dsp.game.get_spendable_resources(1879).tritium;

    assert(dsp.game.get_ships_levels(1552).carrier == 0, 'wrong ships after');
    assert(dsp.game.get_ships_levels(1552).scraper == 0, 'wrong ships after');
    assert(dsp.game.get_ships_levels(1552).sparrow == 0, 'wrong ships after');
    assert(dsp.game.get_ships_levels(1552).frigate == 0, 'wrong ships after');
    assert(dsp.game.get_ships_levels(1552).armade == 0, 'wrong ships after');

    let techs = dsp.game.get_techs_levels(1879);
    let fleet_speed = fleet::get_fleet_speed(fleet, techs);

    let p1_position = dsp.game.get_planet_position(1879);
    let distance = fleet::get_distance(p1_position, p2_position);
    let flight_time = fleet::get_flight_time(fleet_speed, distance);

    let fuel_consumption = fleet::get_fuel_consumption(fleet, distance);
    assert(tritium_after == tritium_before - fuel_consumption, 'wrong fuel consumption');

    let mission = dsp.game.get_mission_details(1879, 1);
    assert(mission.time_arrival == get_block_timestamp() + flight_time, 'wrong flight time');

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

    let p2_position = dsp.game.get_planet_position(1552);

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

    let p1_position = dsp.game.get_planet_position(1879);

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

    let p2_position = dsp.game.get_planet_position(1552);

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

    let p2_position = dsp.game.get_planet_position(1552);

    let mut fleet: Fleet = Default::default();
    fleet.carrier = 5;

    dsp.game.send_fleet(fleet, p2_position, false);
    dsp.game.send_fleet(fleet, p2_position, false);
}

#[test]
fn test_send_fleet_debris_success() {
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
    let p2_position = dsp.game.get_planet_position(1552);

    let mut fleet: Fleet = Default::default();
    fleet.carrier = 5;

    dsp.game.send_fleet(fleet, p2_position, false);
    let mission = dsp.game.get_mission_details(1879, 1);
    warp_multiple(dsp.game.contract_address, get_contract_address(), mission.time_arrival + 1);
    dsp.game.attack_planet(1);

    let mut fleet: Fleet = Default::default();
    fleet.scraper = 1;
    let debris = dsp.game.get_debris_field(1552);
    dsp.game.send_fleet(fleet, p2_position, true);
    let missions = dsp.game.get_active_missions(1879);
    let mission = dsp.game.get_mission_details(1879, 1);
    warp_multiple(dsp.game.contract_address, get_contract_address(), mission.time_arrival + 1);
    let resources_before = dsp.game.get_spendable_resources(1879);
    dsp.game.collect_debris(1);
    assert(dsp.game.get_ships_levels(1879).scraper == 1, 'wrong scraper back');
    let resources_after = dsp.game.get_spendable_resources(1879);
    assert(resources_after.steel == resources_before.steel + debris.steel, 'wrong steel collected');
    assert(
        resources_after.quartz == resources_before.quartz + debris.quartz, 'wrong quartz collected'
    );
    let debris_after_collection = dsp.game.get_debris_field(1552);
    assert(debris_after_collection.is_zero(), 'wrong debris after');
}

#[test]
#[should_panic(expected: ('empty debris fiels',))]
fn test_send_fleet_debris_fails_empty_debris_field() {
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
    dsp.game.carrier_build(10);
    dsp.game.scraper_build(1);
    let p2_position = dsp.game.get_planet_position(1552);

    let mut fleet: Fleet = Default::default();
    fleet.scraper = 1;

    dsp.game.send_fleet(fleet, p2_position, true);
    let mission = dsp.game.get_mission_details(1879, 1);
    warp_multiple(dsp.game.contract_address, get_contract_address(), mission.time_arrival + 1);
    dsp.game.collect_debris(1552);
}

#[test]
#[should_panic(expected: ('no scrapers for collection',))]
fn test_send_fleet_debris_fails_no_scrapers() {
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
    dsp.game.carrier_build(2);
    let p1_position = dsp.game.get_planet_position(1552);

    let mut fleet: Fleet = Default::default();
    fleet.carrier = 1;

    dsp.game.send_fleet(fleet, p1_position, false);
    let mission = dsp.game.get_mission_details(1879, 1);
    warp_multiple(dsp.game.contract_address, get_contract_address(), mission.time_arrival + 1);
    dsp.game.attack_planet(1);

    dsp.game.send_fleet(fleet, p1_position, true);
}

#[test]
#[should_panic(expected: ('only scraper can collect',))]
fn test_send_fleet_debris_fails_not_only_scrapers() {
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
    dsp.game.carrier_build(2);
    dsp.game.scraper_build(1);
    let p1_position = dsp.game.get_planet_position(1552);

    let mut fleet: Fleet = Default::default();
    fleet.carrier = 1;

    dsp.game.send_fleet(fleet, p1_position, false);
    let mission = dsp.game.get_mission_details(1879, 1);
    warp_multiple(dsp.game.contract_address, get_contract_address(), mission.time_arrival + 1);
    dsp.game.attack_planet(1);

    fleet.scraper = 1;
    dsp.game.send_fleet(fleet, p1_position, true);
}

#[test]
fn test_attack_planet() {
    let dsp = set_up();
    init_game(dsp);

    start_prank(dsp.game.contract_address, ACCOUNT1());
    dsp.game.generate_planet();
    start_prank(dsp.game.contract_address, ACCOUNT2());
    dsp.game.generate_planet();
    build_basic_mines(dsp.game);
    advance_game_state(dsp.game);
    dsp.game.celestia_build(100);
    let defences_before = dsp.game.get_defences_levels(1552);
    start_prank(dsp.game.contract_address, ACCOUNT1());
    build_basic_mines(dsp.game);
    advance_game_state(dsp.game);
    dsp.game.armade_build(10);
    let fleetA_before = dsp.game.get_ships_levels(1879);

    let p2_position = dsp.game.get_planet_position(1552);
    let mut fleet_a: Fleet = Default::default();
    let fleet_b: Fleet = Zeroable::zero();
    fleet_a.armade = 10;
    dsp.game.send_fleet(fleet_a, p2_position, false);
    let mission = dsp.game.get_mission_details(1879, 1);
    warp_multiple(dsp.game.contract_address, get_contract_address(), mission.time_arrival + 1);

    let points_before = dsp.game.get_planet_points(1552);

    let celestia_before = dsp.game.get_celestia_available(1552);
    dsp.game.attack_planet(1);
    let celestia_after = dsp.game.get_celestia_available(1552);

    let defences_after = dsp.game.get_defences_levels(1552);
    let a_techs = dsp.game.get_techs_levels(1879);
    let b_techs = dsp.game.get_techs_levels(1552);
    let (fleetA_after, fleetB_after, defences_after) = fleet::war(
        fleet_a, a_techs, fleet_b, defences_before, b_techs
    );
    let expected_debris = fleet::get_debris(
        fleet_a, fleetA_after, celestia_before - celestia_after
    );
    let debris_field = dsp.game.get_debris_field(1552);
    assert(debris_field == expected_debris, 'wrong after debris');

    let fleet_a = dsp.game.get_ships_levels(1879);
    let fleet_b = dsp.game.get_ships_levels(1552);
    let defences = dsp.game.get_defences_levels(1552);
    let points_after = dsp.game.get_planet_points(1552);
    assert(fleet_a == fleetA_after, 'wrong fleet_a after');
    assert(fleet_b == fleetB_after, 'wrong fleet_b after');
    assert(defences == defences_after, 'wrong fleet_b after');
}

#[test]
#[should_panic(expected: ('the mission is empty',))]
fn test_attack_planet_fails_empty_mission() {
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
    dsp.game.sparrow_build(1);
    let fleetA_before = dsp.game.get_ships_levels(1879);

    let p2_position = dsp.game.get_planet_position(1552);
    let mut fleet_a: Fleet = Default::default();
    fleet_a.sparrow = 1;

    dsp.game.send_fleet(fleet_a, p2_position, false);
    let mission = dsp.game.get_mission_details(1879, 1);

    warp_multiple(dsp.game.contract_address, get_contract_address(), mission.time_arrival + 1);
    dsp.game.attack_planet(2)
}

#[test]
#[should_panic(expected: ('destination not reached yet',))]
fn test_attack_planet_fails_destination_not_reached() {
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
    dsp.game.sparrow_build(1);
    let mut fleet_a: Fleet = Default::default();
    fleet_a.sparrow = 1;

    let p2_position = dsp.game.get_planet_position(1552);
    dsp.game.send_fleet(fleet_a, p2_position, false);

    let mission = dsp.game.get_mission_details(1879, 1);
    dsp.game.attack_planet(1)
}

#[test]
fn test_recall_fleet() {
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
    dsp.game.sparrow_build(1);
    let fleet_before = dsp.game.get_ships_levels(1879);
    let mut fleet_a: Fleet = Default::default();
    fleet_a.sparrow = 1;

    let p2_position = dsp.game.get_planet_position(1552);
    dsp.game.send_fleet(fleet_a, p2_position, false);
    warp_multiple(dsp.game.contract_address, get_contract_address(), get_block_timestamp() + 60);
    dsp.game.recall_fleet(1);
    let fleet_after = dsp.game.get_ships_levels(1879);
    assert(fleet_after == fleet_before, 'wrong fleet after');
    let mission_after = dsp.game.get_mission_details(1879, 1);
    assert(mission_after == Zeroable::zero(), 'wrong mission after');
    assert(dsp.game.get_active_missions(1879).len() == 0, 'wrong active missions');
}

#[test]
#[should_panic(expected: ('no fleet to recall',))]
fn test_recall_fleet_fails_no_fleet_to_recall() {
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
    dsp.game.sparrow_build(1);
    let fleet_before = dsp.game.get_ships_levels(1);
    let mut fleet_a: Fleet = Default::default();
    fleet_a.sparrow = 1;

    let p2_position = dsp.game.get_planet_position(1552);
    dsp.game.send_fleet(fleet_a, p2_position, false);
    warp_multiple(dsp.game.contract_address, get_contract_address(), get_block_timestamp() + 60);
    dsp.game.recall_fleet(2);
}

