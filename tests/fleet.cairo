use nogame::fleet_movements::contract::IFleetMovementsDispatcherTrait;
use nogame::fleet_movements::library as fleet;
use nogame::libraries::types::{Defences, Fleet, TechLevels, Unit};
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
fn test_war_defender_fodder_dilutes_armade_targeting() {
    let mut attackers: Fleet = Default::default();
    attackers.armade = 1;
    let mut defender_without_fodder: Fleet = Default::default();
    defender_without_fodder.armade = 1;
    let defences: Defences = Default::default();

    let (_, defender_without_fodder_after, _) = fleet::war(
        attackers, Default::default(), defender_without_fodder, defences, Default::default(),
    );

    let mut defender_with_fodder = defender_without_fodder;
    defender_with_fodder.carrier = 5000;
    let (_, defender_with_fodder_after, _) = fleet::war(
        attackers, Default::default(), defender_with_fodder, defences, Default::default(),
    );

    assert(defender_without_fodder_after.armade == 0, 'unweighted armade survived');
    assert(defender_with_fodder_after.armade == 1, 'fodder did not dilute');
}

#[test]
fn test_war_attacker_fodder_dilutes_armade_targeting() {
    let mut attacker_without_fodder: Fleet = Default::default();
    attacker_without_fodder.armade = 1;
    let mut defenders: Fleet = Default::default();
    defenders.armade = 1;
    let defences: Defences = Default::default();

    let (attacker_without_fodder_after, _, _) = fleet::war(
        attacker_without_fodder, Default::default(), defenders, defences, Default::default(),
    );

    let mut attacker_with_fodder = attacker_without_fodder;
    attacker_with_fodder.carrier = 5000;
    let (attacker_with_fodder_after, _, _) = fleet::war(
        attacker_with_fodder, Default::default(), defenders, defences, Default::default(),
    );

    assert(attacker_without_fodder_after.armade == 0, 'unweighted attacker survived');
    assert(attacker_with_fodder_after.armade == 1, 'attacker fodder did not dilute');
}

#[test]
fn test_war_class_weighting_is_deterministic() {
    let mut attackers: Fleet = Default::default();
    attackers.carrier = 7;
    attackers.frigate = 2;
    attackers.armade = 1;
    let mut defenders: Fleet = Default::default();
    defenders.carrier = 17;
    defenders.scraper = 3;
    defenders.armade = 1;
    let mut defences: Defences = Default::default();
    defences.celestia = 11;
    defences.beam = 2;

    let first = fleet::war(attackers, Default::default(), defenders, defences, Default::default());
    let second = fleet::war(attackers, Default::default(), defenders, defences, Default::default());

    assert(first == second, 'weighted war drifted');
}

#[test]
fn test_rapid_fire_value_uses_bounded_lookup() {
    assert(fleet::rapid_fire_value(3, 2) == 2, 'wrong frigate rf');
    assert(fleet::rapid_fire_value(3, 0) == 1, 'wrong non sparrow rf');
    assert(fleet::rapid_fire_value(4, 2) == 1, 'wrong non frigate rf');
}

#[test]
fn test_rapid_fire_does_not_instant_kill_before_damage() {
    let mut frigate: Unit = Unit {
        id: 3, weapon: 1, shield: 0, hull: 1000, speed: 0, cargo: 0, consumption: 0,
    };
    let mut sparrow: Unit = Unit {
        id: 2, weapon: 0, shield: 0, hull: 1000, speed: 0, cargo: 0, consumption: 0,
    };

    let (_, sparrow_after) = fleet::unit_combat(ref frigate, ref sparrow);

    assert(sparrow_after.hull == 998, 'rapid fire instant killed');
}

#[test]
fn test_rapid_fire_increases_damage_for_matching_pair() {
    let mut frigate: Unit = Unit {
        id: 3, weapon: 100, shield: 0, hull: 1000, speed: 0, cargo: 0, consumption: 0,
    };
    let mut carrier: Unit = Unit {
        id: 0, weapon: 100, shield: 0, hull: 1000, speed: 0, cargo: 0, consumption: 0,
    };
    let mut sparrow_with_rf: Unit = Unit {
        id: 2, weapon: 0, shield: 0, hull: 1000, speed: 0, cargo: 0, consumption: 0,
    };
    let mut sparrow_without_rf = sparrow_with_rf;

    let (_, sparrow_after_rf) = fleet::unit_combat(ref frigate, ref sparrow_with_rf);
    let (_, sparrow_after_no_rf) = fleet::unit_combat(ref carrier, ref sparrow_without_rf);

    assert(sparrow_after_rf.hull == 800, 'wrong rf damage');
    assert(sparrow_after_no_rf.hull == 900, 'wrong non rf damage');
    assert(sparrow_after_rf.hull < sparrow_after_no_rf.hull, 'rf did not add damage');
}

#[test]
fn test_non_rapid_fire_combat_is_unchanged() {
    let mut attacker: Unit = Unit {
        id: 0, weapon: 100, shield: 0, hull: 1000, speed: 0, cargo: 0, consumption: 0,
    };
    let mut defender: Unit = Unit {
        id: 2, weapon: 0, shield: 0, hull: 1000, speed: 0, cargo: 0, consumption: 0,
    };

    let (_, defender_after) = fleet::unit_combat(ref attacker, ref defender);

    assert(defender_after.hull == 900, 'non rf damage changed');
}

#[test]
fn test_rapid_fire_weighted_war_is_deterministic() {
    let mut attackers: Fleet = Default::default();
    attackers.frigate = 3;
    let mut defenders: Fleet = Default::default();
    defenders.sparrow = 17;
    defenders.carrier = 5;
    let defences: Defences = Default::default();

    let first = fleet::war(attackers, Default::default(), defenders, defences, Default::default());
    let second = fleet::war(attackers, Default::default(), defenders, defences, Default::default());

    assert(first == second, 'rapid fire war drifted');
}

#[test]
fn test_restore_round_shields_keeps_hull_damage() {
    let mut units: Array<Unit> = array![];
    units
        .append(
            Unit { id: 0, weapon: 100, shield: 0, hull: 1500, speed: 0, cargo: 0, consumption: 0 },
        );

    fleet::restore_round_shields(ref units, Default::default());
    let restored = units.pop_front().unwrap();

    assert(restored.weapon == 100, 'wrong restored weapon');
    assert(restored.shield == 20, 'shield did not reset');
    assert(restored.hull == 1500, 'hull damage did not persist');
}

#[test]
fn test_deterministic_explosions_pin_exact_threshold_values() {
    assert(fleet::apply_deterministic_explosions(700, 1000, 1) == 700, 'equal threshold exploded');
    assert(fleet::apply_deterministic_explosions(701, 1000, 1) == 701, 'above threshold exploded');
    assert(fleet::apply_deterministic_explosions(699, 1000, 1) == 0, 'below threshold survived');
    assert(
        fleet::apply_deterministic_explosions(6500, 1000, 10) == 6000,
        'wrong rounded explosion loss',
    );
    assert(
        fleet::apply_deterministic_explosions(6000, 1000, 10) == 6000, 'double counted hull losses',
    );
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
    attackers.carrier = 3;
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
}
