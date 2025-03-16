use nogame::colony::contract::{IColonyDispatcher, IColonyDispatcherTrait};
use nogame::compound::contract::{ICompoundDispatcher, ICompoundDispatcherTrait};
use nogame::dockyard::contract::{IDockyardDispatcher, IDockyardDispatcherTrait};
use nogame::fleet_movements::contract::{IFleetMovementsDispatcher, IFleetMovementsDispatcherTrait};
use nogame::libraries::types::{
    ColonyBuildType, ColonyUpgradeType, CompoundsLevels, DAY, Debris, Defences, ERC20s, Fleet,
    MissionCategory, PlanetPosition, ShipBuildType, ShipsLevels, TechUpgradeType,
};
use nogame::planet::contract::{IPlanetDispatcher, IPlanetDispatcherTrait};
use snforge_std::{
    map_entry_address, start_cheat_block_timestamp, start_cheat_block_timestamp_global,
    start_cheat_caller_address, stop_cheat_caller_address, store,
};
use super::utils::{ACCOUNT1, ACCOUNT2, Dispatchers, E18, YEAR, init_game, init_storage, set_up};

#[test]
fn test_generate_colony() {
    let dsp: Dispatchers = set_up();
    init_game(dsp);

    start_cheat_caller_address(dsp.planet.contract_address, ACCOUNT1());
    dsp.planet.generate_planet();
    stop_cheat_caller_address(dsp.planet.contract_address);
    init_storage(dsp, 1);

    start_cheat_caller_address(dsp.colony.contract_address, ACCOUNT1());
    dsp.colony.generate_colony();
    dsp.colony.generate_colony();
    dsp.colony.generate_colony();
    let colonies = dsp.colony.get_colonies_for_planet(1);

    let position_a = PlanetPosition { system: 188, orbit: 10 };
    let position_b = PlanetPosition { system: 182, orbit: 2 };
    let position_c = PlanetPosition { system: 69, orbit: 8 };

    let (id, position) = *colonies.at(0);
    assert(id == 1 && position.system == 188 && position.orbit == 10, 'wrong assert 1');
    let (id, position) = *colonies.at(1);
    assert(id == 2 && position.system == 182 && position.orbit == 2, 'wrong assert 2');
    let (id, position) = *colonies.at(2);
    assert(id == 3 && position.system == 69 && position.orbit == 8, 'wrong assert 3');
    assert(dsp.planet.get_position_to_planet(position_a) == 1001, 'wrong assert 4');
    assert(dsp.planet.get_position_to_planet(position_b) == 1002, 'wrong assert 5');
    assert(dsp.planet.get_position_to_planet(position_c) == 1003, 'wrong assert 6');
}
#[test]
fn test_collect_resources_all_planets() {
    let dsp: Dispatchers = set_up();
    init_game(dsp);

    start_cheat_caller_address(dsp.planet.contract_address, ACCOUNT1());
    dsp.planet.generate_planet();
    stop_cheat_caller_address(dsp.planet.contract_address);
    init_storage(dsp, 1);

    start_cheat_caller_address(dsp.colony.contract_address, ACCOUNT1());
    dsp.colony.generate_colony();
    dsp.colony.generate_colony();
    dsp.colony.generate_colony();
    stop_cheat_caller_address(dsp.colony.contract_address);

    start_cheat_caller_address(dsp.planet.contract_address, ACCOUNT1());
    let planet_collectible = dsp.planet.get_collectible_resources(1);
    let colony1_collectible = dsp.colony.get_colony_resources(1, 1);
    let colony2_collectible = dsp.colony.get_colony_resources(1, 2);
    let colony3_collectible = dsp.colony.get_colony_resources(1, 3);
    let planet_spendable = dsp.planet.get_spendable_resources(1);

    start_cheat_caller_address(dsp.planet.contract_address, dsp.compound.contract_address);
    dsp.planet.collect_resources(ACCOUNT1());
    let planet_spendable_after = dsp.planet.get_spendable_resources(1);
    assert(
        planet_spendable_after == planet_spendable
            + planet_collectible
            + colony1_collectible
            + colony2_collectible
            + colony3_collectible,
        'wrong planet spendable',
    );
}

#[test]
fn test_send_fleet_to_colony() {
    let dsp: Dispatchers = set_up();
    init_game(dsp);

    start_cheat_caller_address(dsp.planet.contract_address, ACCOUNT1());
    dsp.planet.generate_planet();
    stop_cheat_caller_address(dsp.planet.contract_address);
    init_storage(dsp, 1);

    start_cheat_caller_address(dsp.colony.contract_address, ACCOUNT1());
    dsp.colony.generate_colony();
    stop_cheat_caller_address(dsp.colony.contract_address);

    start_cheat_caller_address(dsp.dockyard.contract_address, ACCOUNT1());
    dsp.dockyard.process_ship_build(ShipBuildType::Carrier(()), 1);
    stop_cheat_caller_address(dsp.dockyard.contract_address);
    let mut fleet: Fleet = Default::default();
    fleet.carrier = 1;

    let mut p2_position: PlanetPosition = Default::default();
    p2_position.system = 188;
    p2_position.orbit = 10;

    start_cheat_caller_address(dsp.fleet.contract_address, ACCOUNT1());
    dsp.fleet.send_fleet(fleet, p2_position, MissionCategory::TRANSPORT, 100, 0);
    stop_cheat_caller_address(dsp.fleet.contract_address);
    let missions = dsp.fleet.get_active_missions(1);
    let mission = *missions.at(0);
    assert(mission.destination == 1001, 'wrong hostile mission');
    assert(mission.category == MissionCategory::TRANSPORT, 'wrong hostile mission');
    start_cheat_block_timestamp_global(mission.time_arrival + 1);

    start_cheat_caller_address(dsp.fleet.contract_address, ACCOUNT1());
    dsp.fleet.dock_fleet(1, 0);
    stop_cheat_caller_address(dsp.fleet.contract_address);
    assert(dsp.colony.get_colony_ships(1, 1).carrier == 1, 'wrong colony ships levels');
}

#[test]
fn test_send_fleet_from_colony() {
    let dsp: Dispatchers = set_up();
    init_game(dsp);

    start_cheat_caller_address(dsp.planet.contract_address, ACCOUNT1());
    dsp.planet.generate_planet();
    stop_cheat_caller_address(dsp.planet.contract_address);
    init_storage(dsp, 1);

    start_cheat_caller_address(dsp.colony.contract_address, ACCOUNT1());
    dsp.colony.generate_colony();
    stop_cheat_caller_address(dsp.colony.contract_address);

    start_cheat_caller_address(dsp.colony.contract_address, ACCOUNT1());
    dsp.colony.process_colony_compound_upgrade(1, ColonyUpgradeType::Dockyard, 2);
    dsp.colony.process_colony_unit_build(1, ColonyBuildType::Carrier, 1);
    stop_cheat_caller_address(dsp.colony.contract_address);

    let mut fleet: Fleet = Default::default();
    fleet.carrier = 1;
    let mut p2_position: PlanetPosition = dsp.planet.get_planet_position(1);

    start_cheat_caller_address(dsp.fleet.contract_address, ACCOUNT1());
    dsp.fleet.send_fleet(fleet, p2_position, MissionCategory::TRANSPORT, 100, 1);
    stop_cheat_caller_address(dsp.fleet.contract_address);

    let missions = dsp.fleet.get_active_missions(1);
    println!("missions: {:?}", missions);
    let mission = *missions.at(0);
    assert(mission.destination == 1, 'wrong mission destination');
    assert(mission.category == MissionCategory::TRANSPORT, 'wrong mission category');
    start_cheat_block_timestamp_global(mission.time_arrival + 1);
    start_cheat_caller_address(dsp.fleet.contract_address, ACCOUNT1());
    dsp.fleet.dock_fleet(1, 1);
    stop_cheat_caller_address(dsp.fleet.contract_address);
    assert(dsp.dockyard.get_ships_levels(1).carrier == 1, 'wrong ships levels');
    assert(dsp.colony.get_colony_ships(1, 1).carrier == 0, 'wrong colony ships levels');
}

#[test]
fn test_attack_from_colony() {
    let dsp: Dispatchers = set_up();
    init_game(dsp);

    start_cheat_caller_address(dsp.planet.contract_address, ACCOUNT1());
    dsp.planet.generate_planet();
    stop_cheat_caller_address(dsp.planet.contract_address);
    init_storage(dsp, 1);

    start_cheat_caller_address(dsp.planet.contract_address, ACCOUNT2());
    dsp.planet.generate_planet();
    stop_cheat_caller_address(dsp.planet.contract_address);
    init_storage(dsp, 2);

    let mut fleet: Fleet = Default::default();
    fleet.carrier = 1;

    let p2_position = dsp.planet.get_planet_position(2);

    start_cheat_caller_address(dsp.colony.contract_address, ACCOUNT1());
    dsp.colony.generate_colony();
    dsp.colony.process_colony_compound_upgrade(1, ColonyUpgradeType::Dockyard, 2);
    dsp.colony.process_colony_unit_build(1, ColonyBuildType::Carrier, 1);
    stop_cheat_caller_address(dsp.colony.contract_address);

    start_cheat_block_timestamp_global(starknet::get_block_timestamp() + DAY * 7);
    start_cheat_caller_address(dsp.fleet.contract_address, ACCOUNT1());
    dsp.fleet.send_fleet(fleet, p2_position, MissionCategory::ATTACK, 100, 1);
    let missions = dsp.fleet.get_active_missions(1);
    println!("missions: {:?}", missions);
    let mission = *missions.at(0);
    assert(mission.destination == 2, 'wrong mission destination');
    assert(mission.category == MissionCategory::ATTACK, 'wrong mission category');
    start_cheat_block_timestamp_global(mission.time_arrival + 1);

    start_cheat_caller_address(dsp.fleet.contract_address, ACCOUNT1());
    dsp.fleet.attack_planet(1);
    stop_cheat_caller_address(dsp.fleet.contract_address);
}

#[test]
fn test_process_colony_compound_upgrade() {
    let dsp: Dispatchers = set_up();
    init_game(dsp);

    start_cheat_caller_address(dsp.planet.contract_address, ACCOUNT1());
    dsp.planet.generate_planet();
    stop_cheat_caller_address(dsp.planet.contract_address);
    init_storage(dsp, 1);

    let mut expected_compounds: CompoundsLevels = Default::default();
    expected_compounds.steel = 1;
    expected_compounds.quartz = 2;
    expected_compounds.tritium = 3;
    expected_compounds.energy = 4;
    expected_compounds.dockyard = 1;

    start_cheat_caller_address(dsp.colony.contract_address, ACCOUNT1());
    dsp.colony.generate_colony();
    dsp.colony.process_colony_compound_upgrade(1, ColonyUpgradeType::SteelMine, 1);
    dsp.colony.process_colony_compound_upgrade(1, ColonyUpgradeType::QuartzMine, 2);
    dsp.colony.process_colony_compound_upgrade(1, ColonyUpgradeType::TritiumMine, 3);
    dsp.colony.process_colony_compound_upgrade(1, ColonyUpgradeType::EnergyPlant, 4);
    dsp.colony.process_colony_compound_upgrade(1, ColonyUpgradeType::Dockyard, 1);
    let colony1_compounds = dsp.colony.get_colony_compounds(1, 1);
    assert(colony1_compounds == expected_compounds, 'wrong c1 compounds');

    dsp.colony.generate_colony();
    dsp.colony.process_colony_compound_upgrade(2, ColonyUpgradeType::SteelMine, 1);
    dsp.colony.process_colony_compound_upgrade(2, ColonyUpgradeType::QuartzMine, 2);
    dsp.colony.process_colony_compound_upgrade(2, ColonyUpgradeType::TritiumMine, 3);
    dsp.colony.process_colony_compound_upgrade(2, ColonyUpgradeType::EnergyPlant, 4);
    dsp.colony.process_colony_compound_upgrade(2, ColonyUpgradeType::Dockyard, 1);
    let colony2_compounds = dsp.colony.get_colony_compounds(1, 2);
    assert(colony2_compounds == expected_compounds, 'wrong c2 compounds');
}

#[test]
fn process_colony_unit_build_defences_test() {
    let dsp: Dispatchers = set_up();
    init_game(dsp);

    start_cheat_caller_address(dsp.planet.contract_address, ACCOUNT1());
    dsp.planet.generate_planet();
    stop_cheat_caller_address(dsp.planet.contract_address);
    init_storage(dsp, 1);

    let mut expected: Defences = Default::default();
    expected.blaster = 1;
    expected.beam = 1;
    expected.astral = 1;
    expected.plasma = 1;
    expected.celestia = 1;

    start_cheat_caller_address(dsp.colony.contract_address, ACCOUNT1());
    dsp.colony.generate_colony();
    dsp.colony.process_colony_compound_upgrade(1, ColonyUpgradeType::Dockyard, 8);
    dsp.colony.process_colony_unit_build(1, ColonyBuildType::Blaster, 1);
    dsp.colony.process_colony_unit_build(1, ColonyBuildType::Beam, 1);
    dsp.colony.process_colony_unit_build(1, ColonyBuildType::Astral, 1);
    dsp.colony.process_colony_unit_build(1, ColonyBuildType::Plasma, 1);
    dsp.colony.process_colony_unit_build(1, ColonyBuildType::Celestia, 1);
    let actual = dsp.colony.get_colony_defences(1, 1);
    assert(actual == expected, 'wrong c1 defences');
}

#[test]
fn process_colony_unit_build_fleet_test() {
    let dsp: Dispatchers = set_up();
    init_game(dsp);

    start_cheat_caller_address(dsp.planet.contract_address, ACCOUNT1());
    dsp.planet.generate_planet();
    stop_cheat_caller_address(dsp.planet.contract_address);
    init_storage(dsp, 1);

    let mut expected: ShipsLevels = Default::default();
    expected.carrier = 1;
    expected.scraper = 1;
    expected.sparrow = 1;
    expected.frigate = 1;
    expected.armade = 1;

    start_cheat_caller_address(dsp.colony.contract_address, ACCOUNT1());
    dsp.colony.generate_colony();
    dsp.colony.process_colony_compound_upgrade(1, ColonyUpgradeType::Dockyard, 8);
    dsp.colony.process_colony_unit_build(1, ColonyBuildType::Carrier, 1);
    dsp.colony.process_colony_unit_build(1, ColonyBuildType::Scraper, 1);
    dsp.colony.process_colony_unit_build(1, ColonyBuildType::Sparrow, 1);
    dsp.colony.process_colony_unit_build(1, ColonyBuildType::Frigate, 1);
    dsp.colony.process_colony_unit_build(1, ColonyBuildType::Armade, 1);
    let actual = dsp.colony.get_colony_ships(1, 1);
    assert(actual == expected, 'wrong c1 ships');
}

#[test]
fn test_collect_colony_resources() {
    let dsp: Dispatchers = set_up();
    init_game(dsp);

    start_cheat_caller_address(dsp.planet.contract_address, ACCOUNT1());
    dsp.planet.generate_planet();
    stop_cheat_caller_address(dsp.planet.contract_address);
    init_storage(dsp, 1);

    start_cheat_caller_address(dsp.colony.contract_address, ACCOUNT1());
    dsp.colony.generate_colony();
    dsp.colony.process_colony_compound_upgrade(1, ColonyUpgradeType::SteelMine, 1);
    dsp.colony.process_colony_compound_upgrade(1, ColonyUpgradeType::QuartzMine, 2);
    dsp.colony.process_colony_compound_upgrade(1, ColonyUpgradeType::TritiumMine, 3);
    dsp.colony.process_colony_compound_upgrade(1, ColonyUpgradeType::EnergyPlant, 4);

    let planet_spendable_resources = dsp.planet.get_spendable_resources(1);
    start_cheat_block_timestamp(dsp.planet.contract_address, starknet::get_block_timestamp() + DAY);
    let colony_collectible = dsp.colony.get_colony_resources(1, 1);

    dsp.colony.collect_resources(1);
    let planet_spendable_resources_after = dsp.planet.get_spendable_resources(1);
    let colony_collectible_after = dsp.colony.get_colony_resources(1, 1);

    assert(
        planet_spendable_resources_after == planet_spendable_resources + colony_collectible,
        'wrong planet spendable',
    );
    assert(colony_collectible_after == Default::default(), 'wrong colony collectible');
}

#[test]
fn test_attack_colony() {
    let dsp = set_up();
    init_game(dsp);

    start_cheat_caller_address(dsp.planet.contract_address, ACCOUNT1());
    dsp.planet.generate_planet();
    stop_cheat_caller_address(dsp.planet.contract_address);
    start_cheat_caller_address(dsp.planet.contract_address, ACCOUNT2());
    dsp.planet.generate_planet();
    stop_cheat_caller_address(dsp.planet.contract_address);
    init_storage(dsp, 2);

    start_cheat_caller_address(dsp.planet.contract_address, ACCOUNT1());
    init_storage(dsp, 1);
    start_cheat_caller_address(dsp.dockyard.contract_address, ACCOUNT1());

    start_cheat_caller_address(dsp.dockyard.contract_address, ACCOUNT1());
    dsp.dockyard.process_ship_build(ShipBuildType::Carrier(()), 10);
    stop_cheat_caller_address(dsp.dockyard.contract_address);

    start_cheat_caller_address(dsp.colony.contract_address, ACCOUNT2());
    dsp.colony.generate_colony();
    dsp.colony.process_colony_compound_upgrade(1, ColonyUpgradeType::EnergyPlant, 4);
    dsp.colony.process_colony_compound_upgrade(1, ColonyUpgradeType::SteelMine, 1);
    dsp.colony.process_colony_compound_upgrade(1, ColonyUpgradeType::QuartzMine, 2);
    dsp.colony.process_colony_compound_upgrade(1, ColonyUpgradeType::TritiumMine, 1);
    dsp.colony.process_colony_compound_upgrade(1, ColonyUpgradeType::Dockyard, 1);
    dsp.colony.process_colony_unit_build(1, ColonyBuildType::Blaster, 1);
    stop_cheat_caller_address(dsp.colony.contract_address);

    let colony_position = dsp.colony.get_colony_position(2, 1);
    println!("colony_position: {:?}", colony_position);
    let mut fleet_a: Fleet = Default::default();
    fleet_a.carrier = 10;

    store(
        dsp.planet.contract_address,
        map_entry_address(
            selector!("resources_spent"), // Providing variable name
            array![2].span() // Providing mapping key 
        ),
        array![1_000_000_000].span(),
    );
    start_cheat_caller_address(dsp.fleet.contract_address, ACCOUNT1());
    start_cheat_block_timestamp_global(starknet::get_block_timestamp() + DAY * 7);
    dsp.fleet.send_fleet(fleet_a, colony_position, MissionCategory::ATTACK, 100, 0);
    let mission = dsp.fleet.get_active_missions(1);
    let mission = *mission.at(0);
    start_cheat_block_timestamp_global(mission.time_arrival + 1);
    let attacker_resources = dsp.planet.get_spendable_resources(1);
    dsp.fleet.attack_planet(1);
    stop_cheat_caller_address(dsp.fleet.contract_address);
    let attacker_resources_after = dsp.planet.get_spendable_resources(1);
    println!("expected_attacker_resources: {:?}", attacker_resources_after - attacker_resources);

    let mut expected_attacker_resources: ERC20s = Default::default();
    expected_attacker_resources.steel = 5657;
    expected_attacker_resources.quartz = 8228;
    expected_attacker_resources.tritium = 2228;

    let mut expected_debris: Debris = Default::default();
    expected_debris.steel = 666;
    expected_debris.quartz = 666;

    assert(
        (attacker_resources_after - attacker_resources) == expected_attacker_resources,
        'wrong attacker resources',
    );
    assert(dsp.planet.get_planet_debris_field(2001) == expected_debris, 'wrong debris');
}

