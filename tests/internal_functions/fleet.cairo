use starknet::info::get_block_timestamp;

use snforge_std::{declare, ContractClassTrait, io::PrintTrait, start_prank, start_warp};

use nogame::game::interface::{INoGameDispatcher, INoGameDispatcherTrait};
use nogame::libraries::types::{Fleet, Unit, TechLevels, PlanetPosition, ERC20s, DefencesLevels};
use nogame::libraries::fleet;

use tests::utils::{
    ACCOUNT1, ACCOUNT2, set_up, init_game, advance_game_state, build_basic_mines, YEAR,
    warp_multiple
};

#[test]
fn test_war_basic() {
    let mut attackers: Fleet = Default::default();
    let mut defenders: Fleet = Default::default();
    let mut defences: DefencesLevels = Default::default();
    let (res1, res2, def) = fleet::war(
        attackers, Default::default(), defenders, defences, Default::default()
    );
}
#[test]
fn test_cargo_speed() {
    let mut fleet: Fleet = Default::default();
    let mut techs: TechLevels = Default::default();
    fleet.carrier = 1;
    assert(fleet::get_fleet_speed(fleet, techs) == 5000, 'wrong_speed 5000');
    techs.combustion = 1;
    assert(fleet::get_fleet_speed(fleet, techs) == 5500, 'wrong_speed 5500');
    techs.combustion = 9;
    assert(fleet::get_fleet_speed(fleet, techs) == 9500, 'wrong_speed 9500');
    techs.thrust = 4;
    assert(fleet::get_fleet_speed(fleet, techs) == 10000, 'wrong_speed 10000');
    techs.thrust = 8;
    assert(fleet::get_fleet_speed(fleet, techs) == 18000, 'wrong_speed 18000');
}

#[test]
fn test_scraper_speed() {
    let mut fleet: Fleet = Default::default();
    let mut techs: TechLevels = Default::default();
    fleet.scraper = 1;
    assert(fleet::get_fleet_speed(fleet, techs) == 2000, 'wrong_speed');
    techs.combustion = 1;
    assert(fleet::get_fleet_speed(fleet, techs) == 2200, 'wrong_speed');
    techs.combustion = 9;
    assert(fleet::get_fleet_speed(fleet, techs) == 3800, 'wrong_speed');
}

#[test]
fn test_sparrow_speed() {
    let mut fleet: Fleet = Default::default();
    let mut techs: TechLevels = Default::default();
    fleet.sparrow = 1;
    assert(fleet::get_fleet_speed(fleet, techs) == 12500, 'wrong_speed');
    techs.combustion = 1;
    assert(fleet::get_fleet_speed(fleet, techs) == 13750, 'wrong_speed');
    techs.combustion = 9;
    assert(fleet::get_fleet_speed(fleet, techs) == 23750, 'wrong_speed');
}

#[test]
fn test_frigate_speed() {
    let mut fleet: Fleet = Default::default();
    let mut techs: TechLevels = Default::default();
    fleet.frigate = 1;
    techs.thrust = 4;
    assert(fleet::get_fleet_speed(fleet, techs) == 15000, 'wrong_speed');
    techs.thrust = 5;
    assert(fleet::get_fleet_speed(fleet, techs) == 18000, 'wrong_speed');
    techs.thrust = 9;
    assert(fleet::get_fleet_speed(fleet, techs) == 30000, 'wrong_speed');
}

#[test]
fn test_armade_speed() {
    let mut fleet: Fleet = Default::default();
    let mut techs: TechLevels = Default::default();
    fleet.armade = 1;
    techs.spacetime = 3;
    assert(fleet::get_fleet_speed(fleet, techs) == 10000, 'wrong_speed');
    techs.spacetime = 5;
    assert(fleet::get_fleet_speed(fleet, techs) == 16000, 'wrong_speed');
    techs.spacetime = 9;
    fleet::get_fleet_speed(fleet, techs).print();
    assert(fleet::get_fleet_speed(fleet, techs) == 28000, 'wrong_speed');
}

#[test]
fn test_mixed_speed() {
    let mut fleet: Fleet = Default::default();
    let mut techs: TechLevels = Default::default();
    fleet.carrier = 1;
    fleet.frigate = 1;
    fleet.armade = 1;
    techs.thrust = 4;
    techs.spacetime = 4;
    assert(fleet::get_fleet_speed(fleet, techs) == 10000, 'wrong_speed');
}

#[test]
fn test_basic_speed() {
    let mut fleet: Fleet = Default::default();
    fleet::get_flight_time(30000, 1005).print();
    fleet::get_flight_time(15000, 1005).print();
    fleet::get_flight_time(10000, 1005).print();
    fleet::get_flight_time(4000, 1005).print();
    fleet::get_flight_time(2000, 1005).print();
}

#[test]
fn test_long_speed() {
    let mut fleet: Fleet = Default::default();
    fleet::get_flight_time(30000, 21605).print();
    fleet::get_flight_time(15000, 21605).print();
    fleet::get_flight_time(10000, 21605).print();
    fleet::get_flight_time(4000, 21605).print();
    fleet::get_flight_time(2000, 21605).print();
}

#[test]
fn test_distance() {
    let mut start: PlanetPosition = Default::default();
    let mut end: PlanetPosition = Default::default();

    start.system = 1;
    start.orbit = 1;
    end.system = 1;
    end.orbit = 2;
    assert(fleet::get_distance(start, end) == 1005, 'wrong distance 1005');

    end.orbit = 10;
    assert(fleet::get_distance(start, end) == 1045, 'wrong distance 1045');

    start.system = 1;
    end.system = 2;
    assert(fleet::get_distance(start, end) == 2795, 'wrong distance 2795');

    start.system = 2;
    end.system = 1;
    assert(fleet::get_distance(start, end) == 2795, 'wrong distance 2795');

    start.system = 5;
    end.system = 241;
    assert(fleet::get_distance(start, end) == 25120, 'wrong distance 25120');

    start.system = 241;
    end.system = 5;
    assert(fleet::get_distance(start, end) == 25120, 'wrong distance 25120');
}

#[test]
fn test_fuel_consumption() {
    let mut fleet: Fleet = Default::default();
    fleet.carrier = 1;
    fleet.armade = 1;
    fleet::get_fuel_consumption(fleet, 2700);
}

#[test]
fn test_get_debris() {
    let mut before: Fleet = Default::default();
    let mut after: Fleet = Default::default();
    before.carrier = 10;
    after.carrier = 0;
    let res = fleet::get_debris(before, after);
}

