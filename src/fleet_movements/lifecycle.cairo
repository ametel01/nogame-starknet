use nogame::colony::contract::IColonyDispatcherTrait;
use nogame::defence::contract::IDefenceDispatcherTrait;
use nogame::dockyard::contract::IDockyardDispatcherTrait;
use nogame::fleet_movements::orchestration;
use nogame::game::interfaces::{IResourceManagerDispatcher, IResourceManagerDispatcherTrait};
use nogame::libraries::colony_identity;
use nogame::libraries::fleet_ops::{FleetOperation, update_fleet_levels};
use nogame::libraries::names::Names;
use nogame::libraries::types::{Contracts, Debris, Defences, ERC20s, Fleet, Mission, PlanetPosition};
use nogame::planet::contract::IPlanetDispatcherTrait;
use starknet::ContractAddress;

#[derive(Copy, Drop)]
struct AttackLifecycle {
    plan: orchestration::AttackMissionPlan,
    next_debris: Debris,
    incoming_bucket: u32,
    defender_points_id: u32,
    attacker_position: PlanetPosition,
    defender_position: PlanetPosition,
}

#[derive(Copy, Drop)]
struct BattleReportFacts {
    attacker_position: PlanetPosition,
    attacker_initial_fleet: Fleet,
    attacker_fleet_loss: Fleet,
    defender_position: PlanetPosition,
    defender_initial_fleet: Fleet,
    defender_fleet_loss: Fleet,
    initial_defences: Defences,
    defences_loss: Defences,
    loot: ERC20s,
    debris: Debris,
}

fn spend_send_fuel(
    contracts: Contracts, caller: ContractAddress, plan: orchestration::SendMissionPlan,
) {
    resource_manager(contracts).spend_resources(caller, plan.fuel_cost);
}

fn finish_send_mission(contracts: Contracts, plan: orchestration::SendMissionPlan) {
    contracts.planet.set_last_active(plan.planet_id);
    depart_fleet(contracts, plan.origin_id, plan.mission.fleet);
}

fn return_fleet(contracts: Contracts, planet_id: u32, fleet: Fleet) {
    update_fleet_levels(
        contracts.dockyard, contracts.colony, planet_id, fleet, FleetOperation::Add,
    );
}

fn plan_attack_lifecycle(
    contracts: Contracts, origin: u32, mission: Mission, time_now: u64,
) -> AttackLifecycle {
    let plan = orchestration::plan_attack(contracts, origin, mission, time_now);
    let current_debris = contracts.planet.get_planet_debris_field(mission.destination);
    let defender_points_id = if plan.target.is_colony {
        plan.target.mother_planet_id
    } else {
        mission.destination
    };

    AttackLifecycle {
        next_debris: current_debris + plan.settlement.debris,
        incoming_bucket: colony_identity::incoming_mission_bucket(plan.target),
        defender_points_id,
        attacker_position: contracts.planet.get_planet_position(origin),
        defender_position: contracts.planet.get_planet_position(mission.destination),
        plan,
    }
}

fn apply_attack_effects(
    contracts: Contracts,
    caller: ContractAddress,
    origin: u32,
    mission: Mission,
    lifecycle: AttackLifecycle,
) {
    contracts.planet.set_planet_debris_field(mission.destination, lifecycle.next_debris);
    update_defender_assets(contracts, mission.destination, lifecycle.plan);
    spend_attack_loot(contracts, mission.destination, lifecycle.plan);
    resource_manager(contracts).grant_resources(caller, lifecycle.plan.total_loot);
    reset_target_resource_timer(contracts, lifecycle.plan);
    return_fleet(contracts, mission.origin, lifecycle.plan.settlement.attacker_fleet);
    update_points_after_attack(
        contracts, origin, lifecycle.plan.settlement.attacker_loss, Zeroable::zero(),
    );
    update_points_after_attack(
        contracts,
        lifecycle.defender_points_id,
        lifecycle.plan.settlement.defender_loss,
        lifecycle.plan.settlement.defences_loss,
    );
    contracts.planet.set_last_active(origin);
}

fn battle_report_facts(mission: Mission, lifecycle: AttackLifecycle) -> BattleReportFacts {
    BattleReportFacts {
        attacker_position: lifecycle.attacker_position,
        attacker_initial_fleet: mission.fleet,
        attacker_fleet_loss: lifecycle.plan.settlement.attacker_loss,
        defender_position: lifecycle.defender_position,
        defender_initial_fleet: lifecycle.plan.defender_assets.fleet,
        defender_fleet_loss: lifecycle.plan.settlement.defender_loss,
        initial_defences: lifecycle.plan.defender_assets.defences,
        defences_loss: lifecycle.plan.settlement.defences_loss,
        loot: lifecycle.plan.total_loot,
        debris: lifecycle.plan.settlement.debris,
    }
}

fn apply_debris_collection_effects(
    contracts: Contracts,
    caller: ContractAddress,
    mission: Mission,
    plan: orchestration::DebrisCollectionPlan,
) {
    contracts.planet.set_planet_debris_field(mission.destination, plan.remaining_debris);
    resource_manager(contracts).grant_resources(caller, plan.resource_grant);
    return_fleet(contracts, mission.origin, plan.collector_fleet);
}

fn touch_origin(contracts: Contracts, origin: u32) {
    contracts.planet.set_last_active(origin);
}

fn resource_manager(contracts: Contracts) -> IResourceManagerDispatcher {
    IResourceManagerDispatcher { contract_address: contracts.game.contract_address }
}

fn depart_fleet(contracts: Contracts, planet_id: u32, fleet: Fleet) {
    update_fleet_levels(
        contracts.dockyard, contracts.colony, planet_id, fleet, FleetOperation::Remove,
    );
}

fn update_defender_assets(
    contracts: Contracts, destination_id: u32, plan: orchestration::AttackMissionPlan,
) {
    if plan.target.is_colony {
        contracts
            .colony
            .update_defences_after_attack(
                plan.target.mother_planet_id, plan.target.colony_id, plan.settlement.defences,
            );
    } else {
        write_planet_fleet(contracts, destination_id, plan.settlement.defender_fleet);
        write_planet_defences(contracts, destination_id, plan.settlement.defences);
    }
}

fn spend_attack_loot(
    contracts: Contracts, destination_id: u32, plan: orchestration::AttackMissionPlan,
) {
    if !plan.target.is_colony {
        resource_manager(contracts).spend_planet_resources(destination_id, plan.loot_spendable);
    }
}

fn reset_target_resource_timer(contracts: Contracts, plan: orchestration::AttackMissionPlan) {
    if plan.target.is_colony {
        contracts.colony.set_resource_timer(plan.target.mother_planet_id, plan.target.colony_id)
    } else {
        contracts.planet.set_resources_timer(plan.target.id);
    }
}

fn update_points_after_attack(
    contracts: Contracts, planet_id: u32, fleet: Fleet, defences: Defences,
) {
    let resources_points = orchestration::battle_points(fleet, defences);
    if resources_points.is_zero() {
        return;
    }

    contracts.planet.update_planet_points(planet_id, resources_points, true);
}

fn write_planet_fleet(contracts: Contracts, planet_id: u32, fleet: Fleet) {
    contracts.dockyard.set_ship_levels(planet_id, Names::Fleet::CARRIER, fleet.carrier);
    contracts.dockyard.set_ship_levels(planet_id, Names::Fleet::SCRAPER, fleet.scraper);
    contracts.dockyard.set_ship_levels(planet_id, Names::Fleet::SPARROW, fleet.sparrow);
    contracts.dockyard.set_ship_levels(planet_id, Names::Fleet::FRIGATE, fleet.frigate);
    contracts.dockyard.set_ship_levels(planet_id, Names::Fleet::ARMADE, fleet.armade);
}

fn write_planet_defences(contracts: Contracts, planet_id: u32, defences: Defences) {
    contracts.defence.set_defence_level(planet_id, Names::Defence::CELESTIA, defences.celestia);
    contracts.defence.set_defence_level(planet_id, Names::Defence::BLASTER, defences.blaster);
    contracts.defence.set_defence_level(planet_id, Names::Defence::BEAM, defences.beam);
    contracts.defence.set_defence_level(planet_id, Names::Defence::ASTRAL, defences.astral);
    contracts.defence.set_defence_level(planet_id, Names::Defence::PLASMA, defences.plasma);
}
