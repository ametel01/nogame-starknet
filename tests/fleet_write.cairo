use starknet::info::{get_block_timestamp, get_contract_address};
use starknet::contract_address_const;

use snforge_std::{
    declare, ContractClassTrait, PrintTrait, start_prank, start_warp, spy_events, SpyOn, EventSpy,
    EventAssertions, EventFetcher, event_name_hash, Event, CheatTarget
};

use nogame::game::main::NoGame;

use nogame::game::interface::{INoGameDispatcher, INoGameDispatcherTrait};
use nogame::libraries::types::{Fleet, Unit, TechLevels, PlanetPosition, ERC20s, DefencesLevels};
use nogame::libraries::fleet;

use tests::utils::{
    ACCOUNT1, ACCOUNT2, set_up, init_game, advance_game_state, build_basic_mines, YEAR,
    warp_multiple, Dispatchers, HOUR, WEEK
};

#[test]
fn test_send_fleet_success() {
    let dsp: Dispatchers = set_up();
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

    dsp.game.carrier_build(1);
    dsp.game.scraper_build(1);
    dsp.game.sparrow_build(1);

    let p2_position = dsp.game.get_planet_position(2);

    let mut fleet: Fleet = Default::default();
    fleet.carrier = 1;
    fleet.scraper = 1;
    fleet.sparrow = 1;

    assert(dsp.game.get_ships_levels(1).carrier == 1, 'wrong ships before');
    assert(dsp.game.get_ships_levels(1).scraper == 1, 'wrong ships before');
    assert(dsp.game.get_ships_levels(1).sparrow == 1, 'wrong ships before');

    let tritium_before = dsp.game.get_spendable_resources(1).tritium;

    dsp.game.send_fleet(fleet, p2_position, false);

    let tritium_after = dsp.game.get_spendable_resources(1).tritium;

    assert(dsp.game.get_ships_levels(2).carrier == 0, 'wrong ships after');
    assert(dsp.game.get_ships_levels(2).scraper == 0, 'wrong ships after');
    assert(dsp.game.get_ships_levels(2).sparrow == 0, 'wrong ships after');

    let p1_position = dsp.game.get_planet_position(1);
    let distance = fleet::get_distance(p1_position, p2_position);

    let fuel_consumption = fleet::get_fuel_consumption(fleet, distance);
    assert(tritium_after == tritium_before - fuel_consumption, 'wrong fuel consumption');

    let mission = dsp.game.get_mission_details(1, 1);

    assert(mission.fleet.carrier == 1, 'wrong carrier');
    assert(mission.fleet.scraper == 1, 'wrong scraper');
    assert(mission.fleet.sparrow == 1, 'wrong sparrow');
}

#[test]
#[should_panic(expected: ('no planet at destination',))]
fn test_send_fleet_fails_no_planet_at_destination() {
    let dsp = set_up();
    init_game(dsp);

    start_prank(CheatTarget::One(dsp.game.contract_address), ACCOUNT1());
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

    start_prank(CheatTarget::One(dsp.game.contract_address), ACCOUNT1());
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

    start_prank(CheatTarget::One(dsp.game.contract_address), ACCOUNT2());
    dsp.game.generate_planet();
    start_prank(CheatTarget::One(dsp.game.contract_address), ACCOUNT1());
    dsp.game.generate_planet();
    build_basic_mines(dsp.game);
    start_prank(CheatTarget::One(dsp.game.contract_address), ACCOUNT2());
    build_basic_mines(dsp.game);
    advance_game_state(dsp.game);

    start_prank(CheatTarget::One(dsp.game.contract_address), ACCOUNT1());
    dsp.game.steel_mine_upgrade(1);

    start_prank(CheatTarget::One(dsp.game.contract_address), ACCOUNT2());
    dsp.game.carrier_build(100);

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

    start_prank(CheatTarget::One(dsp.game.contract_address), ACCOUNT2());
    dsp.game.generate_planet();
    start_prank(CheatTarget::One(dsp.game.contract_address), ACCOUNT1());
    dsp.game.generate_planet();
    build_basic_mines(dsp.game);
    advance_game_state(dsp.game);
    start_prank(CheatTarget::One(dsp.game.contract_address), ACCOUNT2());
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
fn test_collect_debris_success() {
    let dsp = set_up();
    init_game(dsp);

    start_prank(CheatTarget::One(dsp.game.contract_address), ACCOUNT1());
    dsp.game.generate_planet();
    start_prank(CheatTarget::One(dsp.game.contract_address), ACCOUNT2());
    dsp.game.generate_planet();
    build_basic_mines(dsp.game);
    advance_game_state(dsp.game);
    dsp.game.beam_build(5);
    start_prank(CheatTarget::One(dsp.game.contract_address), ACCOUNT1());
    build_basic_mines(dsp.game);
    advance_game_state(dsp.game);
    dsp.game.digital_systems_upgrade(1);
    dsp.game.carrier_build(10);
    dsp.game.scraper_build(1);
    let p2_position = dsp.game.get_planet_position(2);

    let mut fleet: Fleet = Default::default();
    fleet.carrier = 5;

    dsp.game.send_fleet(fleet, p2_position, false);
    let mission = dsp.game.get_mission_details(1, 1);
    warp_multiple(dsp.game.contract_address, get_contract_address(), mission.time_arrival + 1);
    dsp.game.attack_planet(1);

    let mut fleet: Fleet = Default::default();
    fleet.scraper = 1;
    let debris = dsp.game.get_debris_field(2);
    dsp.game.send_fleet(fleet, p2_position, true);
    let missions = dsp.game.get_active_missions(1);
    let mission = dsp.game.get_mission_details(1, 1);
    warp_multiple(dsp.game.contract_address, get_contract_address(), mission.time_arrival + 1);
    let resources_before = dsp.game.get_spendable_resources(1);
    dsp.game.collect_debris(1);
    assert(dsp.game.get_ships_levels(1).scraper == 1, 'wrong scraper back');
    let resources_after = dsp.game.get_spendable_resources(1);
    assert(resources_after.steel == resources_before.steel + debris.steel, 'wrong steel collected');
    assert(
        resources_after.quartz == resources_before.quartz + debris.quartz, 'wrong quartz collected'
    );
    let debris_after_collection = dsp.game.get_debris_field(2);
    assert(debris_after_collection.is_zero(), 'wrong debris after');
}

#[test]
fn test_collect_debris_own_planet() {
    let dsp = set_up();
    init_game(dsp);

    start_prank(CheatTarget::One(dsp.game.contract_address), ACCOUNT1());
    dsp.game.generate_planet();
    start_prank(CheatTarget::One(dsp.game.contract_address), ACCOUNT2());
    dsp.game.generate_planet();
    build_basic_mines(dsp.game);
    advance_game_state(dsp.game);
    dsp.game.beam_build(10);
    dsp.game.scraper_build(1);
    dsp.game.digital_systems_upgrade(1);
    start_prank(CheatTarget::One(dsp.game.contract_address), ACCOUNT1());
    build_basic_mines(dsp.game);
    advance_game_state(dsp.game);
    dsp.game.digital_systems_upgrade(1);
    dsp.game.carrier_build(1);
    let p2_position = dsp.game.get_planet_position(2);

    let mut fleet: Fleet = Default::default();
    fleet.carrier = 1;

    dsp.game.send_fleet(fleet, p2_position, false);
    let mission = dsp.game.get_mission_details(1, 1);
    warp_multiple(dsp.game.contract_address, get_contract_address(), mission.time_arrival + 1);
    dsp.game.attack_planet(1);

    let mut fleet: Fleet = Default::default();
    fleet.scraper = 1;
    let debris = dsp.game.get_debris_field(2);
    start_prank(CheatTarget::One(dsp.game.contract_address), ACCOUNT2());
    dsp.game.send_fleet(fleet, p2_position, true);
    let missions = dsp.game.get_active_missions(2);
    let mission = dsp.game.get_mission_details(2, 1);
    warp_multiple(dsp.game.contract_address, get_contract_address(), mission.time_arrival + 1);
    let resources_before = dsp.game.get_spendable_resources(2);
    dsp.game.collect_debris(1);
    assert(dsp.game.get_ships_levels(2).scraper == 1, 'wrong scraper back');
    let resources_after = dsp.game.get_spendable_resources(2);
    assert(resources_after.steel == resources_before.steel + debris.steel, 'wrong steel collected');
    assert(
        resources_after.quartz == resources_before.quartz + debris.quartz, 'wrong quartz collected'
    );
    let debris_after_collection = dsp.game.get_debris_field(2);
    assert(debris_after_collection.is_zero(), 'wrong debris after');
}

#[test]
fn test_collect_debris_fleet_decay() {
    let dsp = set_up();
    init_game(dsp);

    start_prank(CheatTarget::One(dsp.game.contract_address), ACCOUNT1());
    dsp.game.generate_planet();
    start_prank(CheatTarget::One(dsp.game.contract_address), ACCOUNT2());
    dsp.game.generate_planet();
    build_basic_mines(dsp.game);
    advance_game_state(dsp.game);
    dsp.game.beam_build(10);
    start_prank(CheatTarget::One(dsp.game.contract_address), ACCOUNT1());
    build_basic_mines(dsp.game);
    advance_game_state(dsp.game);
    dsp.game.digital_systems_upgrade(1);
    dsp.game.carrier_build(100);
    dsp.game.scraper_build(10);
    let p2_position = dsp.game.get_planet_position(2);

    let mut fleet: Fleet = Default::default();
    fleet.carrier = 100;

    dsp.game.send_fleet(fleet, p2_position, false);
    let mission = dsp.game.get_mission_details(1, 1);
    warp_multiple(dsp.game.contract_address, get_contract_address(), mission.time_arrival + 1);
    dsp.game.attack_planet(1);

    let mut fleet: Fleet = Default::default();
    fleet.scraper = 10;
    let debris = dsp.game.get_debris_field(2);
    dsp.game.send_fleet(fleet, p2_position, true);
    let missions = dsp.game.get_active_missions(1);
    let mission = dsp.game.get_mission_details(1, 1);
    warp_multiple(dsp.game.contract_address, get_contract_address(), mission.time_arrival + 9000);
    let resources_before = dsp.game.get_spendable_resources(1);

    dsp.game.collect_debris(1);

    assert(dsp.game.get_ships_levels(1).scraper == 5, 'wrong scraper back');

    let resources_after = dsp.game.get_spendable_resources(1);

    assert(resources_after.steel == resources_before.steel + 50000, 'wrong steel collected');
    assert(resources_after.quartz == resources_before.quartz + 50000, 'wrong quartz collected');
    let debris_after_collection = dsp.game.get_debris_field(2);
    assert(debris_after_collection.steel == debris.steel - 50000, 'wrong steel after');
    assert(debris_after_collection.quartz == debris.quartz - 50000, 'wrong quartz after');
}

#[test]
#[should_panic(expected: ('empty debris fiels',))]
fn test_send_fleet_debris_fails_empty_debris_field() {
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
    dsp.game.digital_systems_upgrade(1);
    dsp.game.carrier_build(10);
    dsp.game.scraper_build(1);
    let p2_position = dsp.game.get_planet_position(2);

    let mut fleet: Fleet = Default::default();
    fleet.scraper = 1;

    dsp.game.send_fleet(fleet, p2_position, true);
    let mission = dsp.game.get_mission_details(1, 1);
    warp_multiple(dsp.game.contract_address, get_contract_address(), mission.time_arrival + 1);
    dsp.game.collect_debris(2);
}

#[test]
#[should_panic(expected: ('no scrapers for collection',))]
fn test_send_fleet_debris_fails_no_scrapers() {
    let dsp = set_up();
    init_game(dsp);

    start_prank(CheatTarget::One(dsp.game.contract_address), ACCOUNT1());
    dsp.game.generate_planet();
    start_prank(CheatTarget::One(dsp.game.contract_address), ACCOUNT2());
    dsp.game.generate_planet();
    build_basic_mines(dsp.game);
    advance_game_state(dsp.game);
    dsp.game.beam_build(10);
    start_prank(CheatTarget::One(dsp.game.contract_address), ACCOUNT1());
    build_basic_mines(dsp.game);
    advance_game_state(dsp.game);
    dsp.game.digital_systems_upgrade(1);
    dsp.game.carrier_build(2);
    let p1_position = dsp.game.get_planet_position(2);

    let mut fleet: Fleet = Default::default();
    fleet.carrier = 1;

    dsp.game.send_fleet(fleet, p1_position, false);
    let mission = dsp.game.get_mission_details(1, 1);
    warp_multiple(dsp.game.contract_address, get_contract_address(), mission.time_arrival + 1);
    dsp.game.attack_planet(1);

    dsp.game.send_fleet(fleet, p1_position, true);
}

#[test]
#[should_panic(expected: ('only scraper can collect',))]
fn test_send_fleet_debris_fails_not_only_scrapers() {
    let dsp = set_up();
    init_game(dsp);

    start_prank(CheatTarget::One(dsp.game.contract_address), ACCOUNT1());
    dsp.game.generate_planet();
    start_prank(CheatTarget::One(dsp.game.contract_address), ACCOUNT2());
    dsp.game.generate_planet();
    build_basic_mines(dsp.game);
    advance_game_state(dsp.game);
    dsp.game.beam_build(10);
    start_prank(CheatTarget::One(dsp.game.contract_address), ACCOUNT1());
    build_basic_mines(dsp.game);
    advance_game_state(dsp.game);
    dsp.game.digital_systems_upgrade(1);
    dsp.game.carrier_build(2);
    dsp.game.scraper_build(1);
    let p1_position = dsp.game.get_planet_position(2);

    let mut fleet: Fleet = Default::default();
    fleet.carrier = 1;

    dsp.game.send_fleet(fleet, p1_position, false);
    let mission = dsp.game.get_mission_details(1, 1);
    warp_multiple(dsp.game.contract_address, get_contract_address(), mission.time_arrival + 1);
    dsp.game.attack_planet(1);

    fleet.scraper = 1;
    dsp.game.send_fleet(fleet, p1_position, true);
}

#[test]
#[fork(
    url: "https://starknet-sepolia.blastapi.io/e88cff07-b7b6-48d0-8be6-292f660dc735/rpc/v0_6",
    block_id: BlockId::Number(17355)
)]
fn test_attack_forked() {
    let contract_address = contract_address_const::<
        0x07287f2df129f8869638b5e7bf1b9e5961e57836f9762c8caa80e9e7831eeadc
    >();
    let account = contract_address_const::<
        0x02e492bffa91eb61dbebb7b70c4520f9a1ec2a66ec8559a943a87d299b2782c7
    >();
    let game = INoGameDispatcher { contract_address };
    start_prank(CheatTarget::One(contract_address), account);
    let mut fleet: Fleet = Default::default();
    fleet.carrier = 1;
    let mut position: PlanetPosition = Default::default();
    position.system = 73;
    position.orbit = 2;
    game.send_fleet(fleet, position, false);
    let mission = game.get_mission_details(1, 1);
    start_warp(CheatTarget::All, mission.time_arrival + 60);
    game.attack_planet(1);
}
#[test]
fn test_attack_planet_bug_fix() {
    let dsp = set_up();
    init_game(dsp);

    start_prank(CheatTarget::One(dsp.game.contract_address), ACCOUNT1());
    dsp.game.generate_planet();
    start_prank(CheatTarget::One(dsp.game.contract_address), ACCOUNT2());
    dsp.game.generate_planet();
    build_basic_mines(dsp.game);
    // dsp.game.carrier_build(7385);
    start_prank(CheatTarget::One(dsp.game.contract_address), ACCOUNT1());
    build_basic_mines(dsp.game);
    dsp.game.dockyard_upgrade(2);
    dsp.game.lab_upgrade(2);
    dsp.game.energy_innovation_upgrade(1);
    dsp.game.combustive_engine_upgrade(2);
    dsp.game.carrier_build(1);

    let p2_position = dsp.game.get_planet_position(2);
    let mut fleet_a: Fleet = Default::default();
    fleet_a.carrier = 1;
    dsp.game.send_fleet(fleet_a, p2_position, false);
    let mission = dsp.game.get_mission_details(1, 1);
    warp_multiple(dsp.game.contract_address, get_contract_address(), mission.time_arrival + 1);

    dsp.game.attack_planet(1);
}

#[test]
fn test_attack_planet_fleet_decay() {
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
    dsp.game.carrier_build(10);
    let fleetA_before = dsp.game.get_ships_levels(1);

    let p2_position = dsp.game.get_planet_position(2);
    let mut fleet_a: Fleet = Default::default();
    let fleet_b: Fleet = Zeroable::zero();
    fleet_a.carrier = 10;
    dsp.game.send_fleet(fleet_a, p2_position, false);
    let mission = dsp.game.get_mission_details(1, 1);

    // warping 2100 seconds over an hour to create fleet decay
    warp_multiple(dsp.game.contract_address, get_contract_address(), mission.time_arrival + 9000);

    let points_before = dsp.game.get_planet_points(1);

    let before = dsp.game.get_ships_levels(1);
    assert(before.carrier == 0, 'wrong #1');

    dsp.game.attack_planet(1);

    let after = dsp.game.get_ships_levels(1);
    after.print();
    assert(after.carrier == 5, 'wrong #2');

    let points_after = dsp.game.get_planet_points(1);
    assert(points_before - points_after == 20, 'wrong #3');
}

#[test]
#[should_panic(expected: ('the mission is empty',))]
fn test_attack_planet_fails_empty_mission() {
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
    dsp.game.sparrow_build(1);
    let fleetA_before = dsp.game.get_ships_levels(1);

    let p2_position = dsp.game.get_planet_position(2);
    let mut fleet_a: Fleet = Default::default();
    fleet_a.sparrow = 1;

    dsp.game.send_fleet(fleet_a, p2_position, false);
    let mission = dsp.game.get_mission_details(1, 1);

    warp_multiple(dsp.game.contract_address, get_contract_address(), mission.time_arrival + 1);
    dsp.game.attack_planet(2)
}

#[test]
#[should_panic(expected: ('destination not reached yet',))]
fn test_attack_planet_fails_destination_not_reached() {
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
    dsp.game.sparrow_build(1);
    let mut fleet_a: Fleet = Default::default();
    fleet_a.sparrow = 1;

    let p2_position = dsp.game.get_planet_position(2);
    dsp.game.send_fleet(fleet_a, p2_position, false);

    let mission = dsp.game.get_mission_details(1, 1);
    dsp.game.attack_planet(1)
}

#[test]
fn test_recall_fleet() {
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
    dsp.game.sparrow_build(1);
    let fleet_before = dsp.game.get_ships_levels(1);
    let mut fleet_a: Fleet = Default::default();
    fleet_a.sparrow = 1;

    let p2_position = dsp.game.get_planet_position(2);
    dsp.game.send_fleet(fleet_a, p2_position, false);
    warp_multiple(dsp.game.contract_address, get_contract_address(), get_block_timestamp() + 60);
    dsp.game.recall_fleet(1);
    let fleet_after = dsp.game.get_ships_levels(1);
    assert(fleet_after == fleet_before, 'wrong fleet after');
    let mission_after = dsp.game.get_mission_details(1, 1);
    assert(mission_after == Zeroable::zero(), 'wrong mission after');
    assert(dsp.game.get_active_missions(1).len() == 0, 'wrong active missions');
}

#[test]
#[should_panic(expected: ('no fleet to recall',))]
fn test_recall_fleet_fails_no_fleet_to_recall() {
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
    dsp.game.sparrow_build(1);
    let fleet_before = dsp.game.get_ships_levels(1);
    let mut fleet_a: Fleet = Default::default();
    fleet_a.sparrow = 1;

    let p2_position = dsp.game.get_planet_position(2);
    dsp.game.send_fleet(fleet_a, p2_position, false);
    warp_multiple(dsp.game.contract_address, get_contract_address(), get_block_timestamp() + 60);
    dsp.game.recall_fleet(2);
}

