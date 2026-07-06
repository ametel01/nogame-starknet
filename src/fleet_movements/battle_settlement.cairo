use nogame::fleet_movements::library as fleet;
use nogame::libraries::types::{Debris, Defences, FLEET_DECAY_THRESHOLD, Fleet, TechLevels};

#[derive(Copy, Drop, PartialEq)]
enum BattleOutcome {
    AttackerVictory: (),
    DefenderVictory: (),
    Draw: (),
}

#[derive(Copy, Drop)]
struct BattleSettlement {
    attacker_fleet: Fleet,
    defender_fleet: Fleet,
    defences: Defences,
    outcome: BattleOutcome,
    attacker_loss: Fleet,
    defender_loss: Fleet,
    defences_loss: Defences,
    debris: Debris,
}

fn settle(
    attacker_initial_fleet: Fleet,
    defender_initial_fleet: Fleet,
    initial_defences: Defences,
    attacker_techs: TechLevels,
    defender_techs: TechLevels,
    initial_celestia: u32,
    time_since_arrived: u64,
) -> BattleSettlement {
    let attacker_fleet = decay_attacker_fleet(attacker_initial_fleet, time_since_arrived);
    let (attacker_after, defender_after, defences_after) = fleet::war(
        attacker_fleet, attacker_techs, defender_initial_fleet, initial_defences, defender_techs,
    );
    let outcome = battle_outcome(attacker_after, defender_after, defences_after);
    let attacker_loss = fleet_loss(attacker_initial_fleet, attacker_after);
    let defender_loss = fleet_loss(defender_initial_fleet, defender_after);
    let defences_loss = defences_loss(initial_defences, defences_after);
    let debris = battle_debris(
        attacker_initial_fleet,
        attacker_after,
        defender_initial_fleet,
        defender_after,
        initial_celestia - defences_after.celestia,
    );

    BattleSettlement {
        attacker_fleet: attacker_after,
        defender_fleet: defender_after,
        defences: defences_after,
        outcome,
        attacker_loss,
        defender_loss,
        defences_loss,
        debris,
    }
}

fn battle_outcome(
    attacker_after: Fleet, defender_after: Fleet, defences_after: Defences,
) -> BattleOutcome {
    if attacker_after.is_zero() {
        return BattleOutcome::DefenderVictory(());
    }
    if defender_after.is_zero() && defences_after.is_zero() {
        return BattleOutcome::AttackerVictory(());
    }
    BattleOutcome::Draw(())
}

fn decay_attacker_fleet(fleet_to_decay: Fleet, time_since_arrived: u64) -> Fleet {
    if time_since_arrived > FLEET_DECAY_THRESHOLD {
        let decay_amount = fleet::calculate_fleet_loss(time_since_arrived - FLEET_DECAY_THRESHOLD);
        return fleet::decay_fleet(fleet_to_decay, decay_amount);
    }
    fleet_to_decay
}

fn battle_debris(
    attacker_before: Fleet,
    attacker_after: Fleet,
    defender_before: Fleet,
    defender_after: Fleet,
    celestia_destroyed: u32,
) -> Debris {
    fleet::get_debris(attacker_before, attacker_after, 0)
        + fleet::get_debris(defender_before, defender_after, celestia_destroyed)
}

fn fleet_loss(before: Fleet, after: Fleet) -> Fleet {
    Fleet {
        carrier: before.carrier - after.carrier,
        scraper: before.scraper - after.scraper,
        sparrow: before.sparrow - after.sparrow,
        frigate: before.frigate - after.frigate,
        armade: before.armade - after.armade,
    }
}

fn defences_loss(before: Defences, after: Defences) -> Defences {
    Defences {
        celestia: before.celestia - after.celestia,
        blaster: before.blaster - after.blaster,
        beam: before.beam - after.beam,
        astral: before.astral - after.astral,
        plasma: before.plasma - after.plasma,
    }
}
