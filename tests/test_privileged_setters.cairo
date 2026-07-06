use nogame::defence::contract::{IDefenceDispatcher, IDefenceDispatcherTrait};
use nogame::dockyard::contract::{IDockyardDispatcher, IDockyardDispatcherTrait};
use nogame::libraries::names::Names;
use nogame::libraries::types::{Debris, ERC20s, PlanetPosition};
use nogame::planet::contract::{IPlanetDispatcher, IPlanetDispatcherTrait};
use snforge_std::{
    start_cheat_block_timestamp_global, start_cheat_caller_address, stop_cheat_caller_address,
};
use super::utils::{ACCOUNT1, Dispatchers, set_up_game};

#[test]
#[should_panic]
fn test_privileged_setters_account_cannot_set_planet_debris_field() {
    let dsp: Dispatchers = set_up_game();

    start_cheat_caller_address(dsp.planet.contract_address, ACCOUNT1());
    dsp.planet.set_planet_debris_field(1, Debris { steel: 10, quartz: 20 });
}

#[test]
#[should_panic]
fn test_privileged_setters_account_cannot_update_planet_points() {
    let dsp: Dispatchers = set_up_game();

    start_cheat_caller_address(dsp.planet.contract_address, ACCOUNT1());
    dsp.planet.update_planet_points(1, ERC20s { steel: 1_000, quartz: 1_000, tritium: 0 }, false);
}

#[test]
#[should_panic]
fn test_privileged_setters_account_cannot_set_ship_levels() {
    let dsp: Dispatchers = set_up_game();

    start_cheat_caller_address(dsp.dockyard.contract_address, ACCOUNT1());
    dsp.dockyard.set_ship_levels(1, Names::Fleet::CARRIER, 7);
}

#[test]
#[should_panic]
fn test_privileged_setters_account_cannot_set_defence_level() {
    let dsp: Dispatchers = set_up_game();

    start_cheat_caller_address(dsp.defence.contract_address, ACCOUNT1());
    dsp.defence.set_defence_level(1, Names::Defence::BLASTER, 9);
}

#[test]
fn test_privileged_setters_registered_planet_callers_can_update_state() {
    let dsp: Dispatchers = set_up_game();
    let debris = Debris { steel: 30, quartz: 40 };
    let colony_position = PlanetPosition { system: 777, orbit: 7 };

    start_cheat_block_timestamp_global(1_000);
    start_cheat_caller_address(dsp.planet.contract_address, dsp.fleet.contract_address);
    dsp.planet.set_planet_debris_field(1, debris);
    dsp.planet.set_last_active(1);
    dsp.planet.set_resources_timer(1);
    dsp.planet.update_planet_points(1, ERC20s { steel: 2_000, quartz: 3_000, tritium: 0 }, false);
    stop_cheat_caller_address(dsp.planet.contract_address);

    start_cheat_caller_address(dsp.planet.contract_address, dsp.colony.contract_address);
    dsp.planet.add_colony_planet(1_001, colony_position, 1);
    stop_cheat_caller_address(dsp.planet.contract_address);

    assert(dsp.planet.get_planet_debris_field(1) == debris, 'debris not updated');
    assert(dsp.planet.get_planet_points(1) == 5, 'points not updated');
    assert(dsp.planet.get_last_active(1) != 0, 'last active not set');
    assert(dsp.planet.get_position_to_planet(colony_position) == 1_001, 'position not mapped');
    assert(dsp.planet.get_planet_position(1_001) == colony_position, 'planet not mapped');
}

#[test]
fn test_privileged_setters_registered_fleet_can_set_ship_levels() {
    let dsp: Dispatchers = set_up_game();

    start_cheat_caller_address(dsp.dockyard.contract_address, dsp.fleet.contract_address);
    dsp.dockyard.set_ship_levels(1, Names::Fleet::CARRIER, 7);
    stop_cheat_caller_address(dsp.dockyard.contract_address);

    assert(dsp.dockyard.get_ships_levels(1).carrier == 7, 'ship level not set');
}

#[test]
fn test_privileged_setters_registered_fleet_can_set_defence_level() {
    let dsp: Dispatchers = set_up_game();

    start_cheat_caller_address(dsp.defence.contract_address, dsp.fleet.contract_address);
    dsp.defence.set_defence_level(1, Names::Defence::BLASTER, 9);
    stop_cheat_caller_address(dsp.defence.contract_address);

    assert(dsp.defence.get_defences_levels(1).blaster == 9, 'defence level not set');
}
