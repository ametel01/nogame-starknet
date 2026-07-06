use nogame::fleet_movements::contract::IFleetMovementsDispatcherTrait;
use nogame::fleet_movements::library as fleet;
use nogame::libraries::types::{Defences, Fleet, TechLevels};
use super::utils::set_up;

#[test]
fn test_war_armade_clears_carrier() {
    let mut attackers: Fleet = Default::default();
    attackers.armade = 1;
    let mut defenders: Fleet = Default::default();
    defenders.carrier = 1;
    let defences: Defences = Default::default();

    let (attackers_after, defenders_after, defences_after) = fleet::war(
        attackers, Default::default(), defenders, defences, Default::default(),
    );

    assert(attackers_after.armade == 1, 'wrong armade after');
    assert(defenders_after.is_zero(), 'wrong defender fleet');
    assert(defences_after.is_zero(), 'wrong defences');
}

#[test]
fn test_war_armade_clears_blaster() {
    let mut attackers: Fleet = Default::default();
    attackers.armade = 1;
    let defenders: Fleet = Default::default();
    let mut defences: Defences = Default::default();
    defences.blaster = 1;

    let (attackers_after, defenders_after, defences_after) = fleet::war(
        attackers, Default::default(), defenders, defences, Default::default(),
    );

    assert(attackers_after.armade == 1, 'wrong armade after');
    assert(defenders_after.is_zero(), 'wrong defender fleet');
    assert(defences_after.is_zero(), 'wrong defences');
}

#[test]
fn test_fleet_speed_and_flight_time_characterization() {
    let mut carrier_fleet: Fleet = Default::default();
    carrier_fleet.carrier = 1;
    let mut techs: TechLevels = Default::default();

    assert(fleet::get_fleet_speed(carrier_fleet, techs) == 5000, 'wrong speed 5000');
    techs.combustion = 9;
    assert(fleet::get_fleet_speed(carrier_fleet, techs) == 9500, 'wrong speed 9500');
    techs.thrust = 4;
    assert(fleet::get_fleet_speed(carrier_fleet, techs) == 10000, 'wrong speed 10000');

    assert(fleet::get_flight_time(10000, 21605, 50) == 32556, 'wrong flight time');
}

#[test]
fn test_simulate_attack_pins_zero_tech_losses() {
    let dsp = set_up();
    let mut attackers: Fleet = Default::default();
    attackers.armade = 1;
    let mut defenders: Fleet = Default::default();
    defenders.carrier = 1;
    let defences: Defences = Default::default();

    let result = dsp.fleet.simulate_attack(attackers, defenders, defences);
    let compatibility_result = dsp
        .fleet
        .simulate_attack_with_techs(
            attackers, defenders, defences, Default::default(), Default::default(),
        );

    assert(result.attacker_carrier == 0, 'wrong attacker carrier');
    assert(result.attacker_scraper == 0, 'wrong attacker scraper');
    assert(result.attacker_sparrow == 0, 'wrong attacker sparrow');
    assert(result.attacker_frigate == 0, 'wrong attacker frigate');
    assert(result.attacker_armade == 0, 'wrong attacker armade');
    assert(result.defender_carrier == 1, 'wrong defender carrier');
    assert(result.defender_scraper == 0, 'wrong defender scraper');
    assert(result.defender_sparrow == 0, 'wrong defender sparrow');
    assert(result.defender_frigate == 0, 'wrong defender frigate');
    assert(result.defender_armade == 0, 'wrong defender armade');
    assert(result.celestia == 0, 'wrong celestia');
    assert(result.blaster == 0, 'wrong blaster');
    assert(result.beam == 0, 'wrong beam');
    assert(result.astral == 0, 'wrong astral');
    assert(result.plasma == 0, 'wrong plasma');
    assert(result == compatibility_result, 'zero tech mismatch');
}

#[test]
fn test_simulate_attack_with_techs_uses_asymmetric_techs() {
    let dsp = set_up();
    let mut attackers: Fleet = Default::default();
    attackers.carrier = 1;
    let mut defenders: Fleet = Default::default();
    defenders.carrier = 3;
    let defences: Defences = Default::default();
    let mut attacker_techs: TechLevels = Default::default();
    attacker_techs.weapons = 10;
    attacker_techs.armour = 20;
    let mut defender_techs: TechLevels = Default::default();
    defender_techs.armour = 1;

    let result = dsp
        .fleet
        .simulate_attack_with_techs(attackers, defenders, defences, attacker_techs, defender_techs);

    assert(result.attacker_carrier == 1, 'wrong attacker carrier');
    assert(result.attacker_scraper == 0, 'wrong attacker scraper');
    assert(result.attacker_sparrow == 0, 'wrong attacker sparrow');
    assert(result.attacker_frigate == 0, 'wrong attacker frigate');
    assert(result.attacker_armade == 0, 'wrong attacker armade');
    assert(result.defender_carrier == 1, 'wrong defender carrier');
    assert(result.defender_scraper == 0, 'wrong defender scraper');
    assert(result.defender_sparrow == 0, 'wrong defender sparrow');
    assert(result.defender_frigate == 0, 'wrong defender frigate');
    assert(result.defender_armade == 0, 'wrong defender armade');
    assert(result.celestia == 0, 'wrong celestia');
    assert(result.blaster == 0, 'wrong blaster');
    assert(result.beam == 0, 'wrong beam');
    assert(result.astral == 0, 'wrong astral');
    assert(result.plasma == 0, 'wrong plasma');
}
