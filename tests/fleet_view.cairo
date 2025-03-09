use nogame::dockyard::contract::{IDockyardDispatcher, IDockyardDispatcherTrait};
use nogame::fleet_movements::contract::{IFleetMovementsDispatcher, IFleetMovementsDispatcherTrait};
use nogame::libraries::types::{Fleet, MissionCategory, ShipBuildType, TechUpgradeType};
use nogame::planet::contract::{IPlanetDispatcher, IPlanetDispatcherTrait};
use nogame::tech::contract::{ITechDispatcher, ITechDispatcherTrait};
use snforge_std::start_cheat_caller_address_global;
use super::utils::{ACCOUNT1, ACCOUNT2, init_game, init_storage, set_up};

#[test]
fn test_is_noob_protected() {
    let dsp = set_up();
    init_game(dsp);

    start_cheat_caller_address_global(ACCOUNT1());
    dsp.planet.generate_planet();
    start_cheat_caller_address_global(ACCOUNT2());
    dsp.planet.generate_planet();

    start_cheat_caller_address_global(ACCOUNT1());
    init_storage(dsp, 1);

    assert(dsp.planet.get_is_noob_protected(1, 2) == true, 'wrong noob true');
    assert(dsp.planet.get_is_noob_protected(2, 1) == true, 'wrong noob true');
}

#[test]
fn test_get_mission_details() { // TODO
    assert(0 == 0, 'todo');
}

#[test]
fn test_get_hostile_missions() {
    let dsp = set_up();
    init_game(dsp);

    start_cheat_caller_address_global(ACCOUNT1());
    dsp.planet.generate_planet();
    start_cheat_caller_address_global(ACCOUNT2());
    dsp.planet.generate_planet();
    init_storage(dsp, 2);
    start_cheat_caller_address_global(ACCOUNT1());
    init_storage(dsp, 1);
    dsp.tech.process_tech_upgrade(TechUpgradeType::Digital(()), 4);

    dsp.dockyard.process_ship_build(ShipBuildType::Carrier(()), 5);

    let p2_position = dsp.planet.get_planet_position(2);

    let mut fleet: Fleet = Default::default();
    fleet.carrier = 1;

    dsp.fleet.send_fleet(fleet, p2_position, MissionCategory::ATTACK, 100, 0);
    dsp.fleet.send_fleet(fleet, p2_position, MissionCategory::ATTACK, 100, 0);
    dsp.fleet.send_fleet(fleet, p2_position, MissionCategory::ATTACK, 100, 0);

    let mut missions = dsp.fleet.get_incoming_missions(2);
    assert(missions.len() == 3, 'wrong missions len #1');
    assert(*missions.at(0).origin == 1, 'wrong origin #2');
    assert(*missions.at(0).id_at_origin == 1, 'wrong id at origin #3');
    assert(*missions.at(1).origin == 1, 'wrong origin #4');
    assert(*missions.at(1).id_at_origin == 2, 'wrong id at origin #5');
    assert(*missions.at(2).origin == 1, 'wrong origin #6');
    assert(*missions.at(2).id_at_origin == 3, 'wrong id at origin #7');

    dsp.fleet.recall_fleet(1);
    let mut missions = dsp.fleet.get_incoming_missions(2);
    assert(missions.len() == 2, 'wrong missions len 2 #8');
    assert(*missions.at(0).origin == 1, 'wrong origin #9');
    assert(*missions.at(0).id_at_origin == 2, 'wrong id at origin #10');
    assert(*missions.at(1).origin == 1, 'wrong origin #11');
    assert(*missions.at(1).id_at_origin == 3, 'wrong id at origin #12');

    dsp.fleet.recall_fleet(3);
    let mut missions = dsp.fleet.get_incoming_missions(2);
    assert(missions.len() == 1, 'wrong missions len 1 #13');
    assert(*missions.at(0).origin == 1, 'wrong origin #14');
    assert(*missions.at(0).id_at_origin == 2, 'wrong id at origin #15');

    dsp.fleet.send_fleet(fleet, p2_position, MissionCategory::ATTACK, 100, 0);
    let mut missions = dsp.fleet.get_incoming_missions(2);
    assert(missions.len() == 2, 'wrong missions len 2 #16');
    assert(*missions.at(0).origin == 1, 'wrong origin #17');
    assert(*missions.at(0).id_at_origin == 1, 'wrong id at origin 2 #18');
    assert(*missions.at(1).origin == 1, 'wrong origin #19');
    assert(*missions.at(1).id_at_origin == 2, 'wrong id at origin 1 #20');

    dsp.fleet.recall_fleet(2);
    let mut missions = dsp.fleet.get_incoming_missions(2);
    assert(missions.len() == 1, 'wrong missions len 1 #21');
    assert(*missions.at(0).origin == 1, 'wrong origin #22');
    assert(*missions.at(0).id_at_origin == 1, 'wrong id at origin 1 #23');

    dsp.fleet.recall_fleet(1);
    let mut missions = dsp.fleet.get_incoming_missions(2);
    assert(missions.len() == 0, 'wrong missions len 1 #24');
}

#[test]
fn test_get_active_missions() {
    let dsp = set_up();
    init_game(dsp);

    start_cheat_caller_address_global(ACCOUNT1());
    dsp.planet.generate_planet();
    start_cheat_caller_address_global(ACCOUNT2());
    dsp.planet.generate_planet();
    init_storage(dsp, 2);
    start_cheat_caller_address_global(ACCOUNT1());
    init_storage(dsp, 1);
    dsp.tech.process_tech_upgrade(TechUpgradeType::Digital(()), 4);

    dsp.dockyard.process_ship_build(ShipBuildType::Carrier(()), 5);

    let p2_position = dsp.planet.get_planet_position(2);

    let mut fleet: Fleet = Default::default();
    fleet.carrier = 1;

    dsp.fleet.send_fleet(fleet, p2_position, MissionCategory::ATTACK, 100, 0);
    dsp.fleet.send_fleet(fleet, p2_position, MissionCategory::ATTACK, 100, 0);
    dsp.fleet.send_fleet(fleet, p2_position, MissionCategory::ATTACK, 100, 0);

    let mut missions = dsp.fleet.get_active_missions(1);
    assert(missions.len() == 3, 'wrong assert #1');
    assert(*missions.at(0).id == 1, 'wrong assert #2');
    assert(*missions.at(0).destination == 2, 'wrong assert #3');
    assert(*missions.at(0).category == MissionCategory::ATTACK, 'wrong assert #4');

    assert(*missions.at(1).id == 2, 'wrong assert #5');
    assert(*missions.at(1).destination == 2, 'wrong assert #6');
    assert(*missions.at(1).category == MissionCategory::ATTACK, 'wrong assert #7');

    assert(*missions.at(2).id == 3, 'wrong assert #8');
    assert(*missions.at(2).destination == 2, 'wrong assert #9');
    assert(*missions.at(2).category == MissionCategory::ATTACK, 'wrong assert #10');

    dsp.fleet.recall_fleet(1);
    let mut missions = dsp.fleet.get_active_missions(1);
    assert(missions.len() == 2, 'wrong assert #11');

    assert(*missions.at(0).id == 2, 'wrong assert #12');
    assert(*missions.at(0).category == MissionCategory::ATTACK, 'wrong assert #13');

    assert(*missions.at(1).id == 3, 'wrong assert #14');
    assert(*missions.at(1).category == MissionCategory::ATTACK, 'wrong assert #15');

    dsp.fleet.recall_fleet(3);
    let mut missions = dsp.fleet.get_active_missions(1);
    assert(missions.len() == 1, 'wrong assert #16');

    assert(*missions.at(0).id == 2, 'wrong assert #17');
    assert(*missions.at(0).category == MissionCategory::ATTACK, 'wrong assert #18');

    dsp.fleet.send_fleet(fleet, p2_position, MissionCategory::ATTACK, 100, 0);
    let mut missions = dsp.fleet.get_active_missions(1);
    assert(missions.len() == 2, 'wrong assert #19');

    assert(*missions.at(0).id == 1, 'wrong assert #20');
    assert(*missions.at(0).category == MissionCategory::ATTACK, 'wrong assert #21');

    assert(*missions.at(1).id == 2, 'wrong assert #22');
    assert(*missions.at(1).category == MissionCategory::ATTACK, 'wrong assert #23');

    dsp.fleet.recall_fleet(1);
    let mut missions = dsp.fleet.get_active_missions(1);
    assert(missions.len() == 1, 'wrong assert #24');

    assert(*missions.at(0).id == 2, 'wrong assert #25');
    assert(*missions.at(0).category == MissionCategory::ATTACK, 'wrong assert #26');

    dsp.fleet.recall_fleet(2);
    let mut missions = dsp.fleet.get_active_missions(1);
    assert(missions.len() == 0, 'wrong assert #27');
}

