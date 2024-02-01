use nogame::compound::compound::{ICompoundDispatcher, ICompoundDispatcherTrait};
use nogame::defence::defence::{IDefenceDispatcher, IDefenceDispatcherTrait};
use nogame::dockyard::dockyard::{IDockyardDispatcher, IDockyardDispatcherTrait};
use nogame::fleet_movements::fleet_movements::{
    IFleetMovementsDispatcher, IFleetMovementsDispatcherTrait
};
use nogame::libraries::types::{Fleet, ShipBuildType, DefenceBuildType, MissionCategory};
use nogame::planet::planet::{IPlanetDispatcher, IPlanetDispatcherTrait};
use nogame::storage::storage::{IStorageDispatcher, IStorageDispatcherTrait};
use snforge_std::PrintTrait;

use snforge_std::{start_prank, start_warp, CheatTarget};
use starknet::testing::cheatcode;
use starknet::{ContractAddress, contract_address_const, get_block_timestamp, get_contract_address};
use tests::utils::{
    E18, HOUR, DAY, Dispatchers, ACCOUNT1, ACCOUNT2, ACCOUNT3, ACCOUNT4, ACCOUNT5, init_game,
    set_up, DEPLOYER, warp_multiple, init_storage, prank_contracts
};

#[test]
fn test_get_current_planet_price() {
    let dsp = set_up();
    init_game(dsp);

    (dsp.planet.get_current_planet_price() == 11999999999999998, 'wrong price-1');
    prank_contracts(dsp, ACCOUNT1());
    dsp.planet.generate_planet();

    (dsp.planet.get_current_planet_price() == 12060150250085595, 'wrong price-1');
    prank_contracts(dsp, ACCOUNT2());
    dsp.planet.generate_planet();

    (dsp.planet.get_current_planet_price() == 12120602004610750, 'wrong price-1');
    prank_contracts(dsp, ACCOUNT3());
    dsp.planet.generate_planet();

    start_warp(CheatTarget::All, DAY * 13);

    (dsp.planet.get_current_planet_price() == 6359225859946644, 'wrong price-1');
    prank_contracts(dsp, ACCOUNT4());
    dsp.planet.generate_planet();

    (dsp.planet.get_current_planet_price() == 6391101612214528, 'wrong price-1');
    prank_contracts(dsp, ACCOUNT5());
    dsp.planet.generate_planet();
}

#[test]
fn test_get_number_of_planets() {
    let dsp = set_up();
    init_game(dsp);
    prank_contracts(dsp, ACCOUNT1());
    dsp.planet.generate_planet();
    assert(dsp.storage.get_number_of_planets() == 1, 'wrong n planets');
}

#[test]
fn test_get_planet_position() {
    let dsp = set_up();
    init_game(dsp);
    prank_contracts(dsp, ACCOUNT1());

    assert(dsp.storage.get_planet_position(1).is_zero(), 'wrong assert #1');
}

#[test]
fn test_get_debris_field() {
    let dsp = set_up();
    init_game(dsp);
    prank_contracts(dsp, ACCOUNT1());
    dsp.planet.generate_planet();
    prank_contracts(dsp, ACCOUNT2());
    dsp.planet.generate_planet();

    assert(dsp.storage.get_planet_debris_field(1).is_zero(), 'wrong debris field');
    assert(dsp.storage.get_planet_debris_field(2).is_zero(), 'wrong debris field');

    prank_contracts(dsp, ACCOUNT1());
    init_storage(dsp, 1);
    dsp.dockyard.process_ship_build(ShipBuildType::Carrier(()), 100);

    prank_contracts(dsp, ACCOUNT2());
    init_storage(dsp, 2);
    dsp.defence.process_defence_build(DefenceBuildType::Astral(()), 5);

    prank_contracts(dsp, ACCOUNT1());
    let mut fleet: Fleet = Default::default();
    let position = dsp.storage.get_planet_position(2);
    fleet.carrier = 100;
    dsp.fleet.send_fleet(fleet, position, MissionCategory::ATTACK, 100, 0);
    warp_multiple(dsp.planet.contract_address, get_contract_address(), get_block_timestamp() + DAY);
    dsp.fleet.attack_planet(1);

    assert(dsp.storage.get_planet_debris_field(1).is_zero(), 'wrong debris field');
    let debris = dsp.storage.get_planet_debris_field(2);
    assert(debris.steel == 66666 && debris.quartz == 66666, 'wrong debris field');
}

#[test]
fn test_get_spendable_resources() {
    let dsp = set_up();
    init_game(dsp);
    prank_contracts(dsp, ACCOUNT1());
    dsp.planet.generate_planet();

    let spendable = dsp.compound.get_spendable_resources(1);
    assert(spendable.steel == 500, 'wrong spendable');
    assert(spendable.quartz == 300, 'wrong spendable ');
    assert(spendable.tritium == 100, 'wrong spendable ');
}

#[test]
fn test_get_collectible_resources() {
    let dsp = set_up();
    init_game(dsp);
    prank_contracts(dsp, ACCOUNT1());
    dsp.planet.generate_planet();
    init_storage(dsp, 1);

    start_warp(CheatTarget::All, get_block_timestamp() + HOUR / 6);
    let collectible = dsp.compound.get_collectible_resources(1);
    assert(collectible.steel == 672, 'wrong collectible ');
    assert(collectible.quartz == 448, 'wrong collectible ');
    assert(collectible.tritium == 98, 'wrong collectible ');
}

#[test]
fn test_get_planet_points() {
    let dsp = set_up();
    init_game(dsp);
    prank_contracts(dsp, ACCOUNT1());
    dsp.planet.generate_planet();
    prank_contracts(dsp, ACCOUNT2());
    dsp.planet.generate_planet();
    init_storage(dsp, 2);
    start_prank(CheatTarget::One(dsp.planet.contract_address), ACCOUNT3());
    dsp.planet.generate_planet();
    init_storage(dsp, 3);

    (dsp.storage.get_planet_points(1) == 0, 'wrong points 0');
    (dsp.storage.get_planet_points(2) == 5, 'wrong points 5');
    (dsp.storage.get_planet_points(3) == 972, 'wrong points 972');
}

