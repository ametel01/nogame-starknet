use nogame::compound::contract::{ICompoundDispatcher, ICompoundDispatcherTrait};
use nogame::defence::contract::{IDefenceDispatcher, IDefenceDispatcherTrait};
use nogame::dockyard::contract::{IDockyardDispatcher, IDockyardDispatcherTrait};
use nogame::fleet_movements::contract::{IFleetMovementsDispatcher, IFleetMovementsDispatcherTrait};
use nogame::fleet_movements::library as fleet;
use nogame::libraries::names::Names;
use nogame::libraries::types::{
    CompoundUpgradeType, Debris, DefenceBuildType, Defences, ERC20s, Fleet, MissionCategory,
    PlanetPosition, ShipBuildType, TechLevels, TechUpgradeType, Unit,
};
use nogame::planet::contract::{IPlanetDispatcher, IPlanetDispatcherTrait};
use nogame::tech::contract::{ITechDispatcher, ITechDispatcherTrait};
use snforge_std::{
    ContractClassTrait, Event, EventSpy, declare, map_entry_address, spy_events,
    start_cheat_block_timestamp_global, start_cheat_caller_address, stop_cheat_caller_address,
    store,
};
use starknet::info::{get_block_timestamp, get_contract_address};
use super::utils::{
    ACCOUNT1, ACCOUNT2, DAY, Dispatchers, WEEK, YEAR, build_carriers_for, build_starter_fleet_for,
    debris_field_ready_for, init_game, init_storage, set_up, set_up_two_started_planets,
};

#[test]
fn test_send_fleet_success() {
    let dsp: Dispatchers = set_up_two_started_planets();
    let fleet = build_starter_fleet_for(dsp, ACCOUNT1());
    let p2_position = dsp.planet.get_planet_position(2);

    assert(dsp.dockyard.get_ships_levels(1).carrier == 1, 'wrong ships before');
    assert(dsp.dockyard.get_ships_levels(1).scraper == 1, 'wrong ships before');
    assert(dsp.dockyard.get_ships_levels(1).sparrow == 1, 'wrong ships before');
    assert(dsp.dockyard.get_ships_levels(1).frigate == 1, 'wrong ships before');
    assert(dsp.dockyard.get_ships_levels(1).armade == 1, 'wrong ships before');

    let tritium_before = dsp.planet.get_spendable_resources(1).tritium;

    start_cheat_caller_address(dsp.fleet.contract_address, ACCOUNT1());
    dsp.fleet.send_fleet(fleet, p2_position, MissionCategory::ATTACK, 100, 0);
    stop_cheat_caller_address(dsp.fleet.contract_address);

    let tritium_after = dsp.planet.get_spendable_resources(1).tritium;

    assert(dsp.dockyard.get_ships_levels(2).carrier == 0, 'wrong ships after');
    assert(dsp.dockyard.get_ships_levels(2).scraper == 0, 'wrong ships after');
    assert(dsp.dockyard.get_ships_levels(2).sparrow == 0, 'wrong ships after');
    assert(dsp.dockyard.get_ships_levels(2).frigate == 0, 'wrong ships after');
    assert(dsp.dockyard.get_ships_levels(2).armade == 0, 'wrong ships after');
    let p1_position = dsp.planet.get_planet_position(1);
    let p2_position = dsp.planet.get_planet_position(2);

    let distance = fleet::get_distance(p1_position, p2_position);

    let fuel_consumption = fleet::get_fuel_consumption(fleet, distance);

    assert(tritium_after == tritium_before - fuel_consumption, 'wrong fuel consumption');

    let mission = dsp.fleet.get_mission_details(1, 1);

    assert(mission.fleet.carrier == 1, 'wrong carrier');
    assert(mission.fleet.scraper == 1, 'wrong scraper');
    assert(mission.fleet.sparrow == 1, 'wrong sparrow');
    assert(mission.fleet.frigate == 1, 'wrong frigate');
    assert(mission.fleet.armade == 1, 'wrong armade');
}

#[test]
#[should_panic]
fn test_send_fleet_fails_no_planet_at_destination() {
    let dsp = set_up();
    init_game(dsp);

    start_cheat_caller_address(dsp.planet.contract_address, ACCOUNT1());
    dsp.planet.generate_planet();
    init_storage(dsp, 1);
    stop_cheat_caller_address(dsp.planet.contract_address);

    start_cheat_caller_address(dsp.dockyard.contract_address, ACCOUNT1());
    dsp.dockyard.process_ship_build(ShipBuildType::Carrier(()), 1);
    stop_cheat_caller_address(dsp.dockyard.contract_address);

    let p2_position = dsp.planet.get_planet_position(2);

    let mut fleet: Fleet = Default::default();
    fleet.carrier = 1;

    start_cheat_caller_address(dsp.fleet.contract_address, ACCOUNT1());
    dsp.fleet.send_fleet(fleet, p2_position, MissionCategory::ATTACK, 100, 0);
}

#[test]
#[should_panic]
fn test_send_fleet_fails_origin_is_destination() {
    let dsp = set_up();
    init_game(dsp);

    start_cheat_caller_address(dsp.planet.contract_address, ACCOUNT1());
    dsp.planet.generate_planet();
    init_storage(dsp, 1);
    stop_cheat_caller_address(dsp.planet.contract_address);

    start_cheat_caller_address(dsp.dockyard.contract_address, ACCOUNT1());
    dsp.dockyard.process_ship_build(ShipBuildType::Carrier(()), 1);
    stop_cheat_caller_address(dsp.dockyard.contract_address);

    let p1_position = dsp.planet.get_planet_position(1);

    let mut fleet: Fleet = Default::default();
    fleet.carrier = 1;

    start_cheat_caller_address(dsp.fleet.contract_address, ACCOUNT1());
    dsp.fleet.send_fleet(fleet, p1_position, MissionCategory::ATTACK, 100, 0);
}

#[test]
#[should_panic]
fn test_send_fleet_fails_noob_protection() {
    let dsp = set_up();
    init_game(dsp);

    start_cheat_caller_address(dsp.planet.contract_address, ACCOUNT2());
    dsp.planet.generate_planet();
    start_cheat_caller_address(dsp.planet.contract_address, ACCOUNT1());
    dsp.planet.generate_planet();
    start_cheat_caller_address(dsp.planet.contract_address, ACCOUNT2());
    init_storage(dsp, 1);
    stop_cheat_caller_address(dsp.planet.contract_address);

    start_cheat_caller_address(dsp.dockyard.contract_address, ACCOUNT2());
    dsp.dockyard.process_ship_build(ShipBuildType::Carrier(()), 10);
    stop_cheat_caller_address(dsp.dockyard.contract_address);

    let p2_position = dsp.planet.get_planet_position(2);

    let mut fleet: Fleet = Default::default();
    fleet.carrier = 5;

    start_cheat_caller_address(dsp.compound.contract_address, ACCOUNT1());
    dsp.compound.process_upgrade(CompoundUpgradeType::SteelMine(()), 1);
    stop_cheat_caller_address(dsp.compound.contract_address);

    start_cheat_block_timestamp_global(starknet::get_block_timestamp() + WEEK);
    start_cheat_caller_address(dsp.fleet.contract_address, ACCOUNT2());
    dsp.fleet.send_fleet(fleet, p2_position, MissionCategory::ATTACK, 100, 0);
}

#[test]
fn test_send_speed_modifier() {
    let dsp = set_up();
    init_game(dsp);

    start_cheat_caller_address(dsp.planet.contract_address, ACCOUNT2());
    dsp.planet.generate_planet();
    start_cheat_caller_address(dsp.planet.contract_address, ACCOUNT1());
    dsp.planet.generate_planet();
    init_storage(dsp, 1);
    start_cheat_caller_address(dsp.planet.contract_address, ACCOUNT2());
    init_storage(dsp, 2);
    stop_cheat_caller_address(dsp.planet.contract_address);

    start_cheat_caller_address(dsp.dockyard.contract_address, ACCOUNT2());
    dsp.dockyard.process_ship_build(ShipBuildType::Carrier(()), 10);
    stop_cheat_caller_address(dsp.dockyard.contract_address);
    let p2_position = dsp.planet.get_planet_position(2);

    let mut fleet: Fleet = Default::default();
    fleet.carrier = 5;

    start_cheat_caller_address(dsp.compound.contract_address, ACCOUNT1());
    dsp.compound.process_upgrade(CompoundUpgradeType::SteelMine(()), 1);
    stop_cheat_caller_address(dsp.compound.contract_address);

    start_cheat_block_timestamp_global(starknet::get_block_timestamp() + WEEK);
    start_cheat_caller_address(dsp.fleet.contract_address, ACCOUNT2());
    dsp.fleet.send_fleet(fleet, p2_position, MissionCategory::ATTACK, 50, 0);
    let mission = dsp.fleet.get_mission_details(1, 1);
    assert((mission.time_arrival - get_block_timestamp()) == 18125, 'wrong time arrival');
}

#[test]
#[should_panic]
fn test_send_speed_modifier_fails_zero() {
    let dsp = set_up();
    init_game(dsp);

    start_cheat_caller_address(dsp.planet.contract_address, ACCOUNT2());
    dsp.planet.generate_planet();
    start_cheat_caller_address(dsp.planet.contract_address, ACCOUNT1());
    dsp.planet.generate_planet();
    init_storage(dsp, 1);
    start_cheat_caller_address(dsp.planet.contract_address, ACCOUNT2());
    init_storage(dsp, 2);
    stop_cheat_caller_address(dsp.planet.contract_address);

    start_cheat_caller_address(dsp.dockyard.contract_address, ACCOUNT2());
    dsp.dockyard.process_ship_build(ShipBuildType::Carrier(()), 10);
    stop_cheat_caller_address(dsp.dockyard.contract_address);
    let p2_position = dsp.planet.get_planet_position(2);

    let mut fleet: Fleet = Default::default();
    fleet.carrier = 5;

    start_cheat_caller_address(dsp.compound.contract_address, ACCOUNT1());
    dsp.compound.process_upgrade(CompoundUpgradeType::SteelMine(()), 1);
    stop_cheat_caller_address(dsp.compound.contract_address);

    start_cheat_block_timestamp_global(starknet::get_block_timestamp() + WEEK);
    start_cheat_caller_address(dsp.fleet.contract_address, ACCOUNT2());
    dsp.fleet.send_fleet(fleet, p2_position, MissionCategory::ATTACK, 0, 0);
}

#[test]
#[should_panic]
fn test_send_speed_modifier_fails_above_100() {
    let dsp = set_up();
    init_game(dsp);

    start_cheat_caller_address(dsp.planet.contract_address, ACCOUNT2());
    dsp.planet.generate_planet();
    start_cheat_caller_address(dsp.planet.contract_address, ACCOUNT1());
    dsp.planet.generate_planet();
    init_storage(dsp, 1);
    start_cheat_caller_address(dsp.planet.contract_address, ACCOUNT2());
    init_storage(dsp, 2);
    stop_cheat_caller_address(dsp.planet.contract_address);

    start_cheat_caller_address(dsp.dockyard.contract_address, ACCOUNT2());
    dsp.dockyard.process_ship_build(ShipBuildType::Carrier(()), 10);
    stop_cheat_caller_address(dsp.dockyard.contract_address);
    let p2_position = dsp.planet.get_planet_position(2);

    let mut fleet: Fleet = Default::default();
    fleet.carrier = 5;

    start_cheat_caller_address(dsp.compound.contract_address, ACCOUNT1());
    dsp.compound.process_upgrade(CompoundUpgradeType::SteelMine(()), 1);
    stop_cheat_caller_address(dsp.compound.contract_address);

    start_cheat_block_timestamp_global(starknet::get_block_timestamp() + WEEK);
    start_cheat_caller_address(dsp.fleet.contract_address, ACCOUNT2());
    dsp.fleet.send_fleet(fleet, p2_position, MissionCategory::ATTACK, 101, 0);
}

#[test]
#[should_panic]
fn test_send_fleet_fails_not_enough_fleet_slots() {
    let dsp = set_up();
    init_game(dsp);

    start_cheat_caller_address(dsp.planet.contract_address, ACCOUNT2());
    dsp.planet.generate_planet();
    start_cheat_caller_address(dsp.planet.contract_address, ACCOUNT1());
    dsp.planet.generate_planet();
    init_storage(dsp, 1);
    start_cheat_caller_address(dsp.planet.contract_address, ACCOUNT2());
    init_storage(dsp, 2);
    stop_cheat_caller_address(dsp.planet.contract_address);

    start_cheat_caller_address(dsp.dockyard.contract_address, ACCOUNT2());
    dsp.dockyard.process_ship_build(ShipBuildType::Carrier(()), 10);
    stop_cheat_caller_address(dsp.dockyard.contract_address);
    let p2_position = dsp.planet.get_planet_position(2);

    let mut fleet: Fleet = Default::default();
    fleet.carrier = 5;

    start_cheat_caller_address(dsp.fleet.contract_address, ACCOUNT2());
    dsp.fleet.send_fleet(fleet, p2_position, MissionCategory::ATTACK, 100, 0);
    dsp.fleet.send_fleet(fleet, p2_position, MissionCategory::ATTACK, 100, 0);
}

#[test]
fn test_collect_debris_success() {
    let dsp = set_up_two_started_planets();

    start_cheat_caller_address(dsp.tech.contract_address, ACCOUNT1());
    dsp.tech.process_tech_upgrade(TechUpgradeType::Digital(()), 1);
    stop_cheat_caller_address(dsp.tech.contract_address);

    start_cheat_caller_address(dsp.dockyard.contract_address, ACCOUNT1());
    dsp.dockyard.process_ship_build(ShipBuildType::Scraper(()), 1);
    stop_cheat_caller_address(dsp.dockyard.contract_address);

    let debris = Debris { steel: 100, quartz: 200 };
    debris_field_ready_for(dsp, 2, debris);
    let p2_position = dsp.planet.get_planet_position(2);
    let mut fleet: Fleet = Default::default();
    fleet.scraper = 1;

    start_cheat_caller_address(dsp.fleet.contract_address, ACCOUNT1());
    dsp.fleet.send_fleet(fleet, p2_position, MissionCategory::DEBRIS, 100, 0);
    let mission = dsp.fleet.get_mission_details(1, 1);
    start_cheat_block_timestamp_global(mission.time_arrival + 1);
    let resources_before = dsp.planet.get_spendable_resources(1);
    dsp.fleet.collect_debris(1);
    let scraper_back = dsp.dockyard.get_ships_levels(1).scraper;
    assert!(scraper_back == 1, "scraper back are {}, it should be 1", scraper_back);
    let resources_after = dsp.planet.get_spendable_resources(1);
    assert(resources_after.steel == resources_before.steel + debris.steel, 'wrong steel collected');
    assert(
        resources_after.quartz == resources_before.quartz + debris.quartz, 'wrong quartz collected',
    );
    let debris_after_collection = dsp.planet.get_planet_debris_field(2);
    assert(debris_after_collection.is_zero(), 'wrong debris after');
}

#[test]
fn test_collect_debris_own_planet() {
    let dsp = set_up();
    init_game(dsp);

    start_cheat_caller_address(dsp.planet.contract_address, ACCOUNT1());
    dsp.planet.generate_planet();
    start_cheat_caller_address(dsp.planet.contract_address, ACCOUNT2());
    dsp.planet.generate_planet();
    stop_cheat_caller_address(dsp.planet.contract_address);
    init_storage(dsp, 1);
    init_storage(dsp, 2);

    start_cheat_caller_address(dsp.defence.contract_address, ACCOUNT2());
    dsp.defence.process_defence_build(DefenceBuildType::Plasma(()), 1);
    stop_cheat_caller_address(dsp.defence.contract_address);

    start_cheat_caller_address(dsp.dockyard.contract_address, ACCOUNT2());
    dsp.dockyard.process_ship_build(ShipBuildType::Scraper(()), 1);
    stop_cheat_caller_address(dsp.dockyard.contract_address);

    start_cheat_caller_address(dsp.tech.contract_address, ACCOUNT1());
    dsp.tech.process_tech_upgrade(TechUpgradeType::Digital(()), 1);
    stop_cheat_caller_address(dsp.tech.contract_address);

    start_cheat_caller_address(dsp.dockyard.contract_address, ACCOUNT1());
    dsp.dockyard.process_ship_build(ShipBuildType::Carrier(()), 1);
    stop_cheat_caller_address(dsp.dockyard.contract_address);

    let p2_position = dsp.planet.get_planet_position(2);

    let mut fleet: Fleet = Default::default();
    fleet.carrier = 1;

    start_cheat_caller_address(dsp.fleet.contract_address, ACCOUNT1());
    dsp.fleet.send_fleet(fleet, p2_position, MissionCategory::ATTACK, 100, 0);
    let mission = dsp.fleet.get_mission_details(1, 1);
    start_cheat_block_timestamp_global(mission.time_arrival + 1);
    dsp.fleet.attack_planet(1);
    stop_cheat_caller_address(dsp.fleet.contract_address);

    let mut fleet: Fleet = Default::default();
    fleet.scraper = 1;
    let debris = dsp.planet.get_planet_debris_field(2);

    start_cheat_caller_address(dsp.fleet.contract_address, ACCOUNT2());
    dsp.fleet.send_fleet(fleet, p2_position, MissionCategory::DEBRIS, 100, 0);
    let mission = dsp.fleet.get_mission_details(2, 1);
    start_cheat_block_timestamp_global(mission.time_arrival + 1);
    let resources_before = dsp.planet.get_spendable_resources(2);
    dsp.fleet.collect_debris(1);
    assert(dsp.dockyard.get_ships_levels(2).scraper == 1, 'wrong scraper back');
    let resources_after = dsp.planet.get_spendable_resources(2);
    assert(resources_after.steel == resources_before.steel + debris.steel, 'wrong steel collected');
    assert(
        resources_after.quartz == resources_before.quartz + debris.quartz, 'wrong quartz collected',
    );
    let debris_after_collection = dsp.planet.get_planet_debris_field(2);
    assert(debris_after_collection.is_zero(), 'wrong debris after');
}

#[test]
fn test_collect_debris_fleet_decay() {
    let dsp = set_up();
    init_game(dsp);

    start_cheat_caller_address(dsp.planet.contract_address, ACCOUNT1());
    dsp.planet.generate_planet();
    start_cheat_caller_address(dsp.planet.contract_address, ACCOUNT2());
    dsp.planet.generate_planet();
    init_storage(dsp, 2);
    stop_cheat_caller_address(dsp.planet.contract_address);

    start_cheat_caller_address(dsp.defence.contract_address, ACCOUNT2());
    dsp.defence.process_defence_build(DefenceBuildType::Plasma(()), 1);
    stop_cheat_caller_address(dsp.defence.contract_address);

    start_cheat_caller_address(dsp.planet.contract_address, ACCOUNT1());
    init_storage(dsp, 1);
    stop_cheat_caller_address(dsp.planet.contract_address);

    start_cheat_caller_address(dsp.tech.contract_address, ACCOUNT1());
    dsp.tech.process_tech_upgrade(TechUpgradeType::Digital(()), 1);
    stop_cheat_caller_address(dsp.tech.contract_address);

    start_cheat_caller_address(dsp.dockyard.contract_address, ACCOUNT1());
    dsp.dockyard.process_ship_build(ShipBuildType::Carrier(()), 100);
    dsp.dockyard.process_ship_build(ShipBuildType::Scraper(()), 10);
    stop_cheat_caller_address(dsp.dockyard.contract_address);

    let p2_position = dsp.planet.get_planet_position(2);

    let mut fleet: Fleet = Default::default();
    fleet.carrier = 100;

    start_cheat_caller_address(dsp.fleet.contract_address, ACCOUNT1());
    dsp.fleet.send_fleet(fleet, p2_position, MissionCategory::ATTACK, 100, 0);
    let mission = dsp.fleet.get_mission_details(1, 1);
    start_cheat_block_timestamp_global(mission.time_arrival + 1);
    dsp.fleet.attack_planet(1);

    let mut fleet: Fleet = Default::default();
    fleet.scraper = 10;
    let debris = dsp.planet.get_planet_debris_field(2);
    dsp.fleet.send_fleet(fleet, p2_position, MissionCategory::DEBRIS, 100, 0);
    let mission = dsp.fleet.get_mission_details(1, 1);
    start_cheat_block_timestamp_global(mission.time_arrival + 9000);
    let resources_before = dsp.planet.get_spendable_resources(1);

    dsp.fleet.collect_debris(1);

    assert(dsp.dockyard.get_ships_levels(1).scraper == 5, 'wrong scraper back');

    let resources_after = dsp.planet.get_spendable_resources(1);
    assert(resources_after.steel == resources_before.steel + 50000, 'wrong steel collected');
    assert(resources_after.quartz == resources_before.quartz + 50000, 'wrong quartz collected');
    let debris_after_collection = dsp.planet.get_planet_debris_field(2);
    assert(debris_after_collection.steel == debris.steel - 50000, 'wrong steel after');
    assert(debris_after_collection.quartz == debris.quartz - 50000, 'wrong quartz after');
}

#[test]
fn test_get_debris_uses_large_ship_unit_costs() {
    let mut frigate_before: Fleet = Default::default();
    frigate_before.frigate = 1;
    let frigate_after: Fleet = Default::default();

    let frigate_debris = fleet::get_debris(frigate_before, frigate_after, 0);
    assert(frigate_debris.steel == 20000 / 3, 'wrong frigate steel');
    assert(frigate_debris.quartz == 7000 / 3, 'wrong frigate quartz');

    let mut armade_before: Fleet = Default::default();
    armade_before.armade = 1;
    let armade_after: Fleet = Default::default();

    let armade_debris = fleet::get_debris(armade_before, armade_after, 0);
    assert(armade_debris.steel == 45000 / 3, 'wrong armade steel');
    assert(armade_debris.quartz == 15000 / 3, 'wrong armade quartz');
}

#[test]
#[should_panic]
fn test_send_fleet_debris_fails_empty_debris_field() {
    let dsp = set_up();
    init_game(dsp);

    start_cheat_caller_address(dsp.planet.contract_address, ACCOUNT1());
    dsp.planet.generate_planet();
    start_cheat_caller_address(dsp.planet.contract_address, ACCOUNT2());
    dsp.planet.generate_planet();
    init_storage(dsp, 2);
    start_cheat_caller_address(dsp.planet.contract_address, ACCOUNT1());
    init_storage(dsp, 1);
    stop_cheat_caller_address(dsp.planet.contract_address);

    start_cheat_caller_address(dsp.tech.contract_address, ACCOUNT1());
    dsp.tech.process_tech_upgrade(TechUpgradeType::Digital(()), 1);
    stop_cheat_caller_address(dsp.tech.contract_address);

    start_cheat_caller_address(dsp.dockyard.contract_address, ACCOUNT1());
    dsp.dockyard.process_ship_build(ShipBuildType::Carrier(()), 10);
    dsp.dockyard.process_ship_build(ShipBuildType::Scraper(()), 1);
    stop_cheat_caller_address(dsp.dockyard.contract_address);

    let p2_position = dsp.planet.get_planet_position(2);

    let mut fleet: Fleet = Default::default();
    fleet.scraper = 1;

    start_cheat_caller_address(dsp.fleet.contract_address, ACCOUNT1());
    dsp.fleet.send_fleet(fleet, p2_position, MissionCategory::DEBRIS, 100, 0);
    let mission = dsp.fleet.get_mission_details(1, 1);
    start_cheat_block_timestamp_global(mission.time_arrival + 1);
    dsp.fleet.collect_debris(2);
}

#[test]
#[should_panic]
fn test_send_fleet_debris_fails_no_scrapers() {
    let dsp = set_up();
    init_game(dsp);

    start_cheat_caller_address(dsp.planet.contract_address, ACCOUNT1());
    dsp.planet.generate_planet();
    start_cheat_caller_address(dsp.planet.contract_address, ACCOUNT2());
    dsp.planet.generate_planet();
    init_storage(dsp, 2);
    start_cheat_caller_address(dsp.defence.contract_address, ACCOUNT2());
    dsp.defence.process_defence_build(DefenceBuildType::Plasma(()), 1);
    start_cheat_caller_address(dsp.planet.contract_address, ACCOUNT1());
    init_storage(dsp, 1);
    stop_cheat_caller_address(dsp.planet.contract_address);

    start_cheat_caller_address(dsp.tech.contract_address, ACCOUNT1());
    dsp.tech.process_tech_upgrade(TechUpgradeType::Digital(()), 1);
    stop_cheat_caller_address(dsp.tech.contract_address);

    start_cheat_caller_address(dsp.dockyard.contract_address, ACCOUNT1());
    dsp.dockyard.process_ship_build(ShipBuildType::Carrier(()), 2);
    stop_cheat_caller_address(dsp.dockyard.contract_address);
    let p1_position = dsp.planet.get_planet_position(2);

    let mut fleet: Fleet = Default::default();
    fleet.carrier = 1;

    start_cheat_caller_address(dsp.fleet.contract_address, ACCOUNT1());
    dsp.fleet.send_fleet(fleet, p1_position, MissionCategory::ATTACK, 100, 0);
    let mission = dsp.fleet.get_mission_details(1, 1);
    start_cheat_block_timestamp_global(mission.time_arrival + 1);
    dsp.fleet.attack_planet(1);

    dsp.fleet.send_fleet(fleet, p1_position, MissionCategory::DEBRIS, 100, 0);
}

#[test]
fn test_attack_planet() {
    let dsp = set_up();
    init_game(dsp);

    start_cheat_caller_address(dsp.planet.contract_address, ACCOUNT1());
    dsp.planet.generate_planet();
    stop_cheat_caller_address(dsp.planet.contract_address);
    start_cheat_caller_address(dsp.planet.contract_address, ACCOUNT2());
    dsp.planet.generate_planet();
    stop_cheat_caller_address(dsp.planet.contract_address);
    init_storage(dsp, 2);

    start_cheat_caller_address(dsp.defence.contract_address, ACCOUNT2());
    dsp.defence.process_defence_build(DefenceBuildType::Celestia(()), 100);
    stop_cheat_caller_address(dsp.defence.contract_address);

    init_storage(dsp, 1);

    start_cheat_caller_address(dsp.dockyard.contract_address, ACCOUNT1());
    dsp.dockyard.process_ship_build(ShipBuildType::Armade(()), 10);
    stop_cheat_caller_address(dsp.dockyard.contract_address);

    let p2_position = dsp.planet.get_planet_position(2);
    let mut fleet_a: Fleet = Default::default();
    fleet_a.armade = 10;

    start_cheat_caller_address(dsp.fleet.contract_address, ACCOUNT1());
    dsp.fleet.send_fleet(fleet_a, p2_position, MissionCategory::ATTACK, 100, 0);
    let mission = dsp.fleet.get_mission_details(1, 1);
    start_cheat_block_timestamp_global(mission.time_arrival + 1);

    dsp.fleet.attack_planet(1);
}

#[test]
fn test_attack_planet_fleet_decay() {
    let dsp = set_up();
    init_game(dsp);

    start_cheat_caller_address(dsp.planet.contract_address, ACCOUNT1());
    dsp.planet.generate_planet();
    start_cheat_caller_address(dsp.planet.contract_address, ACCOUNT2());
    dsp.planet.generate_planet();
    init_storage(dsp, 2);
    start_cheat_caller_address(dsp.planet.contract_address, ACCOUNT1());
    init_storage(dsp, 1);
    stop_cheat_caller_address(dsp.planet.contract_address);

    start_cheat_caller_address(dsp.dockyard.contract_address, ACCOUNT1());
    dsp.dockyard.process_ship_build(ShipBuildType::Carrier(()), 10);
    stop_cheat_caller_address(dsp.dockyard.contract_address);

    let p2_position = dsp.planet.get_planet_position(2);
    let mut fleet_a: Fleet = Default::default();
    fleet_a.carrier = 10;

    start_cheat_caller_address(dsp.fleet.contract_address, ACCOUNT1());
    dsp.fleet.send_fleet(fleet_a, p2_position, MissionCategory::ATTACK, 100, 0);
    let mission = dsp.fleet.get_mission_details(1, 1);

    // warping 2100 seconds over an hour to create fleet decay
    start_cheat_block_timestamp_global(mission.time_arrival + 9000);

    let points_before = dsp.planet.get_planet_points(1);

    let before = dsp.dockyard.get_ships_levels(1);
    assert(before.carrier == 0, 'wrong #1');

    dsp.fleet.attack_planet(1);

    let after = dsp.dockyard.get_ships_levels(1);
    assert(after.carrier == 5, 'wrong #2');

    let points_after = dsp.planet.get_planet_points(1);
    assert(points_before - points_after == 20, 'wrong #3');
}

#[test]
#[should_panic]
fn test_attack_planet_fails_empty_mission() {
    let dsp = set_up();
    init_game(dsp);

    start_cheat_caller_address(dsp.planet.contract_address, ACCOUNT1());
    dsp.planet.generate_planet();
    start_cheat_caller_address(dsp.planet.contract_address, ACCOUNT2());
    dsp.planet.generate_planet();
    init_storage(dsp, 2);
    start_cheat_caller_address(dsp.planet.contract_address, ACCOUNT1());
    init_storage(dsp, 1);
    stop_cheat_caller_address(dsp.planet.contract_address);

    start_cheat_caller_address(dsp.dockyard.contract_address, ACCOUNT1());
    dsp.dockyard.process_ship_build(ShipBuildType::Sparrow(()), 1);
    stop_cheat_caller_address(dsp.dockyard.contract_address);

    let p2_position = dsp.planet.get_planet_position(2);
    let mut fleet_a: Fleet = Default::default();
    fleet_a.sparrow = 1;

    start_cheat_caller_address(dsp.fleet.contract_address, ACCOUNT1());
    dsp.fleet.send_fleet(fleet_a, p2_position, MissionCategory::ATTACK, 100, 0);
    let mission = dsp.fleet.get_mission_details(1, 1);

    start_cheat_block_timestamp_global(mission.time_arrival + 1);
    dsp.fleet.attack_planet(2)
}

#[test]
#[should_panic]
fn test_attack_planet_fails_destination_not_reached() {
    let dsp = set_up();
    init_game(dsp);

    start_cheat_caller_address(dsp.planet.contract_address, ACCOUNT1());
    dsp.planet.generate_planet();
    start_cheat_caller_address(dsp.planet.contract_address, ACCOUNT2());
    dsp.planet.generate_planet();
    init_storage(dsp, 2);
    start_cheat_caller_address(dsp.planet.contract_address, ACCOUNT1());
    init_storage(dsp, 1);
    stop_cheat_caller_address(dsp.planet.contract_address);

    start_cheat_caller_address(dsp.dockyard.contract_address, ACCOUNT1());
    dsp.dockyard.process_ship_build(ShipBuildType::Sparrow(()), 1);
    stop_cheat_caller_address(dsp.dockyard.contract_address);

    let mut fleet_a: Fleet = Default::default();
    fleet_a.sparrow = 1;

    let p2_position = dsp.planet.get_planet_position(2);

    start_cheat_caller_address(dsp.fleet.contract_address, ACCOUNT1());
    dsp.fleet.send_fleet(fleet_a, p2_position, MissionCategory::ATTACK, 100, 0);

    dsp.fleet.attack_planet(1)
}

#[test]
fn test_attack_planet_loot_amount() {
    let dsp = set_up();
    init_game(dsp);

    start_cheat_caller_address(dsp.planet.contract_address, ACCOUNT1());
    dsp.planet.generate_planet();
    start_cheat_caller_address(dsp.planet.contract_address, ACCOUNT2());
    dsp.planet.generate_planet();
    init_storage(dsp, 2);
    start_cheat_caller_address(dsp.planet.contract_address, ACCOUNT1());
    init_storage(dsp, 1);
    stop_cheat_caller_address(dsp.planet.contract_address);

    start_cheat_caller_address(dsp.dockyard.contract_address, ACCOUNT1());
    dsp.dockyard.process_ship_build(ShipBuildType::Carrier(()), 5);
    stop_cheat_caller_address(dsp.dockyard.contract_address);
    let mut fleet_a: Fleet = Default::default();
    fleet_a.carrier = 1;

    let p2_position = dsp.planet.get_planet_position(2);

    start_cheat_caller_address(dsp.fleet.contract_address, ACCOUNT1());
    dsp.fleet.send_fleet(fleet_a, p2_position, MissionCategory::ATTACK, 100, 0);

    let attacker_spendable_before = dsp.planet.get_spendable_resources(1);

    let mission = dsp.fleet.get_mission_details(1, 1);
    start_cheat_block_timestamp_global(mission.time_arrival + 1);
    dsp.fleet.attack_planet(1);

    let attacker_spendable_after = dsp.planet.get_spendable_resources(1);
    let mut expected: ERC20s = Default::default();

    expected.steel = 3333;
    expected.quartz = 3333;
    expected.tritium = 3333;

    assert(
        (attacker_spendable_after - attacker_spendable_before) == expected, 'wrong attacker loot',
    );
}

#[test]
fn test_attack_planet_attacker_victory_grants_loot_after_clearing_defenders() {
    let dsp = set_up_two_started_planets();

    start_cheat_caller_address(dsp.dockyard.contract_address, ACCOUNT1());
    dsp.dockyard.process_ship_build(ShipBuildType::Armade(()), 1);
    stop_cheat_caller_address(dsp.dockyard.contract_address);
    build_carriers_for(dsp, ACCOUNT2(), 1);

    let mut fleet_a: Fleet = Default::default();
    fleet_a.armade = 1;
    let p2_position = dsp.planet.get_planet_position(2);

    start_cheat_caller_address(dsp.fleet.contract_address, ACCOUNT1());
    dsp.fleet.send_fleet(fleet_a, p2_position, MissionCategory::ATTACK, 100, 0);

    let attacker_spendable_before = dsp.planet.get_spendable_resources(1);
    let mission = dsp.fleet.get_mission_details(1, 1);
    start_cheat_block_timestamp_global(mission.time_arrival + 1);
    dsp.fleet.attack_planet(1);

    let attacker_gain = dsp.planet.get_spendable_resources(1) - attacker_spendable_before;
    let defender_fleet_after = dsp.dockyard.get_ships_levels(2);

    assert(!attacker_gain.is_zero(), 'attacker victory no loot');
    assert(defender_fleet_after.carrier == 0, 'defender carrier survived');
}

#[test]
fn test_attack_planet_draw_grants_zero_loot() {
    let dsp = set_up_two_started_planets();

    build_carriers_for(dsp, ACCOUNT1(), 12);
    build_carriers_for(dsp, ACCOUNT2(), 10);

    let mut fleet_a: Fleet = Default::default();
    fleet_a.carrier = 12;
    let p2_position = dsp.planet.get_planet_position(2);

    start_cheat_caller_address(dsp.fleet.contract_address, ACCOUNT1());
    dsp.fleet.send_fleet(fleet_a, p2_position, MissionCategory::ATTACK, 100, 0);

    let attacker_spendable_before = dsp.planet.get_spendable_resources(1);
    let mission = dsp.fleet.get_mission_details(1, 1);
    start_cheat_block_timestamp_global(mission.time_arrival + 1);
    dsp.fleet.attack_planet(1);

    let attacker_gain = dsp.planet.get_spendable_resources(1) - attacker_spendable_before;
    let attacker_fleet_after = dsp.dockyard.get_ships_levels(1);
    let defender_fleet_after = dsp.dockyard.get_ships_levels(2);

    assert(attacker_gain.is_zero(), 'draw granted loot');
    assert(attacker_fleet_after.carrier > 0, 'draw lost attackers');
    assert(defender_fleet_after.carrier > 0, 'draw cleared defenders');
}

#[test]
fn test_attack_planet_defender_victory_grants_zero_loot_and_returns_no_destroyed_attackers() {
    let dsp = set_up_two_started_planets();

    build_carriers_for(dsp, ACCOUNT1(), 1);
    start_cheat_caller_address(dsp.defence.contract_address, ACCOUNT2());
    dsp.defence.process_defence_build(DefenceBuildType::Plasma(()), 1);
    stop_cheat_caller_address(dsp.defence.contract_address);

    let mut fleet_a: Fleet = Default::default();
    fleet_a.carrier = 1;
    let p2_position = dsp.planet.get_planet_position(2);

    start_cheat_caller_address(dsp.fleet.contract_address, ACCOUNT1());
    dsp.fleet.send_fleet(fleet_a, p2_position, MissionCategory::ATTACK, 100, 0);

    let attacker_spendable_before = dsp.planet.get_spendable_resources(1);
    let mission = dsp.fleet.get_mission_details(1, 1);
    start_cheat_block_timestamp_global(mission.time_arrival + 1);
    dsp.fleet.attack_planet(1);

    let attacker_gain = dsp.planet.get_spendable_resources(1) - attacker_spendable_before;
    let attacker_fleet_after = dsp.dockyard.get_ships_levels(1);

    assert(attacker_gain.is_zero(), 'defender victory granted loot');
    assert(attacker_fleet_after.carrier == 0, 'destroyed attacker returned');
}

#[test]
fn test_attack_planet_loot_low_cargo_does_not_mint_spendable() {
    let dsp = set_up();
    init_game(dsp);

    start_cheat_caller_address(dsp.planet.contract_address, ACCOUNT1());
    dsp.planet.generate_planet();
    start_cheat_caller_address(dsp.planet.contract_address, ACCOUNT2());
    dsp.planet.generate_planet();
    init_storage(dsp, 2);
    set_compound_level(dsp, 2, Names::Compound::QUARTZ, 0);
    set_compound_level(dsp, 2, Names::Compound::TRITIUM, 0);
    start_cheat_caller_address(dsp.planet.contract_address, ACCOUNT1());
    init_storage(dsp, 1);
    stop_cheat_caller_address(dsp.planet.contract_address);

    start_cheat_caller_address(dsp.dockyard.contract_address, ACCOUNT1());
    dsp.dockyard.process_ship_build(ShipBuildType::Sparrow(()), 1);
    stop_cheat_caller_address(dsp.dockyard.contract_address);

    let mut fleet_a: Fleet = Default::default();
    fleet_a.sparrow = 1;
    let p2_position = dsp.planet.get_planet_position(2);

    start_cheat_caller_address(dsp.fleet.contract_address, ACCOUNT1());
    dsp.fleet.send_fleet(fleet_a, p2_position, MissionCategory::ATTACK, 100, 0);

    let attacker_spendable_before = dsp.planet.get_spendable_resources(1);
    let defender_spendable_before = dsp.planet.get_spendable_resources(2);

    let mission = dsp.fleet.get_mission_details(1, 1);
    start_cheat_block_timestamp_global(mission.time_arrival + 1);
    let defender_collectible_before = dsp.planet.get_collectible_resources(2);
    let expected_collectible_loot = fleet::load_resources(defender_collectible_before, 50);
    dsp.fleet.attack_planet(1);

    let attacker_spendable_after = dsp.planet.get_spendable_resources(1);
    let defender_spendable_after = dsp.planet.get_spendable_resources(2);
    let attacker_gain = attacker_spendable_after - attacker_spendable_before;
    let defender_spendable_loss = defender_spendable_before - defender_spendable_after;

    assert(
        attacker_gain.quartz == expected_collectible_loot.quartz + defender_spendable_loss.quartz,
        'wrong quartz loot source',
    );
    assert(
        attacker_gain.tritium == expected_collectible_loot.tritium
            + defender_spendable_loss.tritium,
        'wrong tritium loot source',
    );
    assert(
        attacker_gain.steel + attacker_gain.quartz + attacker_gain.tritium <= 50,
        'loot exceeds cargo',
    );
}

fn set_compound_level(dsp: Dispatchers, planet_id: u32, compound_id: u8, level: u8) {
    store(
        dsp.compound.contract_address,
        map_entry_address(
            selector!("compound_level"), array![planet_id.into(), compound_id.into()].span(),
        ),
        array![level.into()].span(),
    );
}

#[test]
fn test_recall_fleet() {
    let dsp = set_up();
    init_game(dsp);

    start_cheat_caller_address(dsp.planet.contract_address, ACCOUNT1());
    dsp.planet.generate_planet();
    start_cheat_caller_address(dsp.planet.contract_address, ACCOUNT2());
    dsp.planet.generate_planet();
    init_storage(dsp, 2);
    start_cheat_caller_address(dsp.planet.contract_address, ACCOUNT1());
    init_storage(dsp, 1);
    stop_cheat_caller_address(dsp.planet.contract_address);

    start_cheat_caller_address(dsp.dockyard.contract_address, ACCOUNT1());
    dsp.dockyard.process_ship_build(ShipBuildType::Sparrow(()), 1);
    stop_cheat_caller_address(dsp.dockyard.contract_address);

    let fleet_before = dsp.dockyard.get_ships_levels(1);
    let mut fleet_a: Fleet = Default::default();
    fleet_a.sparrow = 1;

    let p2_position = dsp.planet.get_planet_position(2);

    start_cheat_caller_address(dsp.fleet.contract_address, ACCOUNT1());
    dsp.fleet.send_fleet(fleet_a, p2_position, MissionCategory::ATTACK, 100, 0);
    start_cheat_block_timestamp_global(get_block_timestamp() + 60);
    dsp.fleet.recall_fleet(1);
    let fleet_after = dsp.dockyard.get_ships_levels(1);
    assert(fleet_after == fleet_before, 'wrong fleet after');
    let mission_after = dsp.fleet.get_mission_details(1, 1);
    assert(mission_after == Zeroable::zero(), 'wrong mission after');
    assert(dsp.fleet.get_active_missions(1).len() == 0, 'wrong active missions');
}

#[test]
#[should_panic]
fn test_recall_fleet_fails_no_fleet_to_recall() {
    let dsp = set_up();
    init_game(dsp);

    start_cheat_caller_address(dsp.planet.contract_address, ACCOUNT1());
    dsp.planet.generate_planet();
    start_cheat_caller_address(dsp.planet.contract_address, ACCOUNT2());
    dsp.planet.generate_planet();
    init_storage(dsp, 2);
    start_cheat_caller_address(dsp.planet.contract_address, ACCOUNT1());
    init_storage(dsp, 1);
    stop_cheat_caller_address(dsp.planet.contract_address);

    start_cheat_caller_address(dsp.dockyard.contract_address, ACCOUNT1());
    dsp.dockyard.process_ship_build(ShipBuildType::Sparrow(()), 1);
    stop_cheat_caller_address(dsp.dockyard.contract_address);

    let mut fleet_a: Fleet = Default::default();
    fleet_a.sparrow = 1;

    let p2_position = dsp.planet.get_planet_position(2);

    start_cheat_caller_address(dsp.fleet.contract_address, ACCOUNT1());
    dsp.fleet.send_fleet(fleet_a, p2_position, MissionCategory::ATTACK, 100, 0);
    start_cheat_block_timestamp_global(get_block_timestamp() + 60);
    dsp.fleet.recall_fleet(2);
}
