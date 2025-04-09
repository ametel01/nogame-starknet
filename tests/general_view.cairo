use nogame::compound::contract::{ICompoundDispatcher, ICompoundDispatcherTrait};
use nogame::defence::contract::{IDefenceDispatcher, IDefenceDispatcherTrait};
use nogame::dockyard::contract::{IDockyardDispatcher, IDockyardDispatcherTrait};
use nogame::fleet_movements::contract::{IFleetMovementsDispatcher, IFleetMovementsDispatcherTrait};
use nogame::libraries::types::{DefenceBuildType, Fleet, MissionCategory, ShipBuildType};
use nogame::planet::contract::{IPlanetDispatcher, IPlanetDispatcherTrait};
use snforge_std::{
    start_cheat_block_timestamp_global, start_cheat_caller_address, stop_cheat_caller_address,
};
use starknet::testing::cheatcode;
use starknet::{ContractAddress, get_block_timestamp, get_contract_address};
use super::utils::{
    ACCOUNT1, ACCOUNT2, ACCOUNT3, ACCOUNT4, ACCOUNT5, DAY, DEPLOYER, Dispatchers, E18, HOUR,
    init_game, init_storage, set_up,
};

#[test]
fn test_get_current_planet_price() {
    let dsp = set_up();
    init_game(dsp);

    assert!(
        dsp.planet.get_current_planet_price() == 54210108624275221,
        "expected 54210108624275221, got {:?}",
        dsp.planet.get_current_planet_price(),
    );
    start_cheat_caller_address(dsp.planet.contract_address, ACCOUNT1());
    dsp.planet.generate_planet();

    assert!(
        dsp.planet.get_current_planet_price() == 54481837923518346,
        "expected 54481837923518346, got {:?}",
        dsp.planet.get_current_planet_price(),
    );
    start_cheat_caller_address(dsp.planet.contract_address, ACCOUNT2());
    dsp.planet.generate_planet();

    assert!(
        dsp.planet.get_current_planet_price() == 54754929271796402,
        "expected 54754929271796402, got {:?}",
        dsp.planet.get_current_planet_price(),
    );
    start_cheat_caller_address(dsp.planet.contract_address, ACCOUNT3());
    dsp.planet.generate_planet();

    start_cheat_block_timestamp_global(DAY * 13);

    assert!(
        dsp.planet.get_current_planet_price() == 28727860386167302,
        "expected 28727860386167302, got {:?}",
        dsp.planet.get_current_planet_price(),
    );
    start_cheat_caller_address(dsp.planet.contract_address, ACCOUNT4());
    dsp.planet.generate_planet();

    assert!(
        dsp.planet.get_current_planet_price() == 28871859385577511,
        "expected 28871859385577511, got {:?}",
        dsp.planet.get_current_planet_price(),
    );
    start_cheat_caller_address(dsp.planet.contract_address, ACCOUNT5());
    dsp.planet.generate_planet();
}

#[test]
fn test_get_number_of_planets() {
    let dsp = set_up();
    init_game(dsp);
    start_cheat_caller_address(dsp.planet.contract_address, ACCOUNT1());
    dsp.planet.generate_planet();
    assert!(
        dsp.planet.get_number_of_planets() == 1,
        "expected 1, got {:?}",
        dsp.planet.get_number_of_planets(),
    );
}

#[test]
fn test_get_planet_position() {
    let dsp = set_up();
    init_game(dsp);
    start_cheat_caller_address(dsp.planet.contract_address, ACCOUNT1());

    assert!(
        dsp.planet.get_planet_position(1).is_zero(),
        "expected 0, got {:?}",
        dsp.planet.get_planet_position(1),
    );
}

#[test]
fn test_get_debris_field() {
    let dsp = set_up();
    init_game(dsp);
    start_cheat_caller_address(dsp.planet.contract_address, ACCOUNT1());
    dsp.planet.generate_planet();
    start_cheat_caller_address(dsp.planet.contract_address, ACCOUNT2());
    dsp.planet.generate_planet();
    stop_cheat_caller_address(dsp.planet.contract_address);

    assert!(
        dsp.planet.get_planet_debris_field(1).is_zero(),
        "wrong debris field: expected 0, got {:?}",
        dsp.planet.get_planet_debris_field(1),
    );
    assert!(
        dsp.planet.get_planet_debris_field(2).is_zero(),
        "wrong debris field: expected 0, got {:?}",
        dsp.planet.get_planet_debris_field(2),
    );

    init_storage(dsp, 1);
    start_cheat_caller_address(dsp.dockyard.contract_address, ACCOUNT1());
    dsp.dockyard.process_ship_build(ShipBuildType::Carrier(()), 100);
    stop_cheat_caller_address(dsp.dockyard.contract_address);

    init_storage(dsp, 2);
    start_cheat_caller_address(dsp.defence.contract_address, ACCOUNT2());
    dsp.defence.process_defence_build(DefenceBuildType::Astral(()), 5);
    stop_cheat_caller_address(dsp.defence.contract_address);

    let mut fleet: Fleet = Default::default();
    let position = dsp.planet.get_planet_position(2);
    fleet.carrier = 100;

    start_cheat_caller_address(dsp.fleet.contract_address, ACCOUNT1());
    dsp.fleet.send_fleet(fleet, position, MissionCategory::ATTACK, 100, 0);
    start_cheat_block_timestamp_global(get_block_timestamp() + DAY);
    dsp.fleet.attack_planet(1);

    assert!(
        dsp.planet.get_planet_debris_field(1).is_zero(),
        "wrong debris field: expected 0, got {:?}",
        dsp.planet.get_planet_debris_field(1),
    );
    let debris = dsp.planet.get_planet_debris_field(2);
    assert!(
        debris.steel == 66666 && debris.quartz == 66666,
        "wrong debris field: expected 66666, got {} {}",
        debris.steel,
        debris.quartz,
    );
}

#[test]
fn test_get_spendable_resources() {
    let dsp = set_up();
    init_game(dsp);
    start_cheat_caller_address(dsp.planet.contract_address, ACCOUNT1());
    dsp.planet.generate_planet();

    let spendable = dsp.planet.get_spendable_resources(1);
    assert!(spendable.steel == 500, "wrong spendable: expected 500, got {}", spendable.steel);
    assert!(spendable.quartz == 300, "wrong spendable: expected 300, got {}", spendable.quartz);
    assert!(spendable.tritium == 100, "wrong spendable: expected 100, got {}", spendable.tritium);
}

#[test]
fn test_get_collectible_resources() {
    let dsp = set_up();
    init_game(dsp);
    start_cheat_caller_address(dsp.planet.contract_address, ACCOUNT1());
    dsp.planet.generate_planet();
    init_storage(dsp, 1);

    start_cheat_block_timestamp_global(get_block_timestamp() + HOUR / 6);
    let collectible = dsp.planet.get_collectible_resources(1);
    assert!(collectible.steel == 672, "wrong collectible: expected 672, got {}", collectible.steel);
    assert!(
        collectible.quartz == 448, "wrong collectible: expected 448, got {}", collectible.quartz,
    );
    assert!(
        collectible.tritium == 98, "wrong collectible: expected 98, got {}", collectible.tritium,
    );
}

#[test]
fn test_get_planet_points() {
    let dsp = set_up();
    init_game(dsp);
    start_cheat_caller_address(dsp.planet.contract_address, ACCOUNT1());
    dsp.planet.generate_planet();
    start_cheat_caller_address(dsp.planet.contract_address, ACCOUNT2());
    dsp.planet.generate_planet();
    init_storage(dsp, 2);

    assert!(
        dsp.planet.get_planet_points(1) == 0,
        "wrong points: expected 0, got {}",
        dsp.planet.get_planet_points(1),
    );
    assert!(
        dsp.planet.get_planet_points(2) == 1000000,
        "wrong points: expected 5, got {}",
        dsp.planet.get_planet_points(2),
    );
}

