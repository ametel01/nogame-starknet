use nogame::colony::contract::IColonyDispatcherTrait;
use nogame::defence::contract::IDefenceDispatcherTrait;
use nogame::defence::library as defence;
use nogame::dockyard::contract::IDockyardDispatcherTrait;
use nogame::dockyard::library as dockyard;
use nogame::fleet_movements::{battle_settlement, library as fleet};
use nogame::libraries::colony_identity::{self, ResolvedPlanetId};
use nogame::libraries::types::{
    Contracts, Debris, Defences, ERC20s, FLEET_DECAY_THRESHOLD, Fleet, IncomingMission, Mission,
    MissionCategory, PlanetPosition, TechLevels, WEEK, erc20_mul,
};
use nogame::planet::contract::IPlanetDispatcherTrait;
use nogame::tech::contract::ITechDispatcherTrait;
use starknet::ContractAddress;

#[derive(Copy, Drop)]
struct SendMissionPlan {
    planet_id: u32,
    origin_id: u32,
    incoming_bucket: u32,
    mission: Mission,
    fuel_cost: ERC20s,
}

#[derive(Copy, Drop)]
struct DefenderAssets {
    fleet: Fleet,
    defences: Defences,
    techs: TechLevels,
    celestia: u32,
}

#[derive(Copy, Drop)]
struct AttackMissionPlan {
    target: ResolvedPlanetId,
    defender_assets: DefenderAssets,
    settlement: battle_settlement::BattleSettlement,
    loot_spendable: ERC20s,
    total_loot: ERC20s,
}

#[derive(Copy, Drop)]
struct DebrisCollectionPlan {
    collector_fleet: Fleet,
    collectible_debris: Debris,
    remaining_debris: Debris,
    resource_grant: ERC20s,
}

fn plan_send_mission(
    contracts: Contracts,
    caller: ContractAddress,
    f: Fleet,
    destination: PlanetPosition,
    mission_type: u8,
    speed_modifier: u32,
    colony_id: u8,
    active_missions: usize,
    time_now: u64,
) -> SendMissionPlan {
    let destination_id = contracts.planet.get_position_to_planet(destination);
    assert!(!destination_id.is_zero(), "Fleet:E_DESTINATION_NOT_FOUND");

    let planet_id = contracts.planet.get_owned_planet(caller);
    let origin_id = if colony_id.is_zero() {
        planet_id
    } else {
        colony_identity::encode_colony_id(planet_id, colony_id)
    };
    let target = resolve_target(contracts, destination_id);

    assert_send_target(target, planet_id, destination_id, mission_type);
    assert_enough_ships(contracts, planet_id, colony_id, f);

    let distance = fleet::get_distance(
        contracts.planet.get_planet_position(origin_id), destination,
    );
    let techs = contracts.tech.get_tech_levels(planet_id);
    let speed = fleet::get_fleet_speed(f, techs);
    assert!(speed_modifier > 0 && speed_modifier <= 100, "Fleet:E_SPEED_MODIFIER");
    let travel_time = fleet::get_flight_time(speed, distance, speed_modifier);

    let max_missions = techs.digital.into() + 1;
    assert!(active_missions < max_missions, "Fleet:E_ACTIVE_MISSIONS_LIMIT");

    let mut fuel_cost: ERC20s = Default::default();
    fuel_cost.tritium = fleet::get_fuel_consumption(f, distance) * 100 / speed_modifier.into();

    let mut mission: Mission = Default::default();
    mission.time_start = time_now;
    mission.origin = origin_id;
    mission.destination = destination_id;
    mission.time_arrival = time_now + travel_time;
    mission.fleet = f;
    mission.category = mission_type;

    if mission_type == MissionCategory::DEBRIS {
        let debris_field = contracts.planet.get_planet_debris_field(destination_id);
        assert!(!debris_field.is_zero(), "Fleet:E_DEBRIS_FIELD_EMPTY");
        assert!(f.scraper >= 1, "Fleet:E_SCRAPER_REQUIRED");
    } else if mission_type == MissionCategory::ATTACK {
        let is_inactive = time_now - contracts.planet.get_last_active(destination_id) > WEEK;
        if !is_inactive {
            let noob_protected = contracts.planet.get_is_noob_protected(planet_id, destination_id);
            assert!(!noob_protected, "Fleet:E_NOOB_PROTECTION");
        }
    }

    SendMissionPlan {
        planet_id,
        origin_id,
        incoming_bucket: colony_identity::incoming_mission_bucket(target),
        mission,
        fuel_cost,
    }
}

fn plan_attack(
    contracts: Contracts, origin: u32, mission: Mission, time_now: u64,
) -> AttackMissionPlan {
    assert!(!mission.is_zero(), "Fleet:E_MISSION_EMPTY");
    assert!(mission.category == MissionCategory::ATTACK, "Fleet:E_WRONG_CATEGORY");
    assert!(mission.destination != origin, "Fleet:E_ATTACK_OWN_PLANET");
    assert!(time_now >= mission.time_arrival, "Fleet:E_ARRIVAL_PENDING");

    let target = resolve_target(contracts, mission.destination);
    let attacker_techs = contracts.tech.get_tech_levels(origin);
    let defender_assets = get_defender_assets(contracts, mission.destination);
    let settlement = battle_settlement::settle(
        mission.fleet,
        defender_assets.fleet,
        defender_assets.defences,
        attacker_techs,
        defender_assets.techs,
        defender_assets.celestia,
        time_now - mission.time_arrival,
    );
    let (loot_spendable, loot_collectible) = calculate_loot_amount(
        contracts, mission.destination, settlement.attacker_fleet,
    );

    AttackMissionPlan {
        target,
        defender_assets,
        settlement,
        loot_spendable,
        total_loot: loot_spendable + loot_collectible,
    }
}

fn plan_debris_collection(mission: Mission, time_now: u64, debris: Debris) -> DebrisCollectionPlan {
    assert!(!mission.is_zero(), "Fleet:E_MISSION_EMPTY");
    assert!(mission.category == MissionCategory::DEBRIS, "Fleet:E_WRONG_CATEGORY");
    assert!(time_now >= mission.time_arrival, "Fleet:E_ARRIVAL_PENDING");

    let time_since_arrived = time_now - mission.time_arrival;
    let mut collector_fleet = mission.fleet;
    if time_since_arrived > FLEET_DECAY_THRESHOLD {
        let decay_amount = fleet::calculate_fleet_loss(time_since_arrived - FLEET_DECAY_THRESHOLD);
        collector_fleet = fleet::decay_fleet(mission.fleet, decay_amount);
    }

    let storage = fleet::get_fleet_cargo_capacity(collector_fleet);
    let collectible_debris = fleet::get_collectible_debris(storage, debris);
    DebrisCollectionPlan {
        collector_fleet,
        collectible_debris,
        remaining_debris: Debris {
            steel: debris.steel - collectible_debris.steel,
            quartz: debris.quartz - collectible_debris.quartz,
        },
        resource_grant: ERC20s {
            steel: collectible_debris.steel,
            quartz: collectible_debris.quartz,
            tritium: Zeroable::zero(),
        },
    }
}

fn incoming_mission(mission: Mission, mission_id: usize) -> IncomingMission {
    let mut incoming_mission: IncomingMission = Default::default();
    incoming_mission.origin = mission.origin;
    incoming_mission.id_at_origin = mission_id;
    incoming_mission.time_arrival = mission.time_arrival;
    incoming_mission
        .number_of_ships = fleet::calculate_number_of_ships(mission.fleet, Zeroable::zero());
    incoming_mission.destination = mission.destination;
    incoming_mission
}

fn battle_points(fleet: Fleet, defences: Defences) -> ERC20s {
    if fleet.is_zero() && defences.is_zero() {
        return Zeroable::zero();
    }

    let ships_cost = dockyard::get_ships_unit_cost();
    let defences_cost = defence::get_defences_unit_cost();
    let gross_damage = erc20_mul(ships_cost.carrier, fleet.carrier.into())
        + erc20_mul(ships_cost.scraper, fleet.scraper.into())
        + erc20_mul(ships_cost.sparrow, fleet.sparrow.into())
        + erc20_mul(ships_cost.frigate, fleet.frigate.into())
        + erc20_mul(ships_cost.armade, fleet.armade.into())
        + erc20_mul(defences_cost.celestia, defences.celestia.into())
        + erc20_mul(defences_cost.blaster, defences.blaster.into())
        + erc20_mul(defences_cost.beam, defences.beam.into())
        + erc20_mul(defences_cost.astral, defences.astral.into())
        + erc20_mul(defences_cost.plasma, defences.plasma.into());

    ERC20s { steel: gross_damage.steel, quartz: gross_damage.quartz, tritium: 0 }
}

fn resolve_target(contracts: Contracts, planet_id: u32) -> ResolvedPlanetId {
    colony_identity::resolve_planet(contracts.colony, planet_id)
}

fn assert_send_target(
    target: ResolvedPlanetId, planet_id: u32, destination_id: u32, mission_type: u8,
) {
    if target.is_colony && mission_type == MissionCategory::TRANSPORT {
        assert!(target.mother_planet_id == planet_id, "Fleet:E_COLONY_TRANSPORT_TARGET");
    }
    if mission_type == MissionCategory::ATTACK && target.is_colony {
        assert!(target.mother_planet_id != planet_id, "Fleet:E_ATTACK_OWN_COLONY");
    } else if mission_type == MissionCategory::ATTACK {
        assert!(destination_id != planet_id, "Fleet:E_ATTACK_OWN_PLANET");
    }
}

fn assert_enough_ships(contracts: Contracts, planet_id: u32, colony_id: u8, fleet: Fleet) {
    let ships_levels = if colony_id == 0 {
        contracts.dockyard.get_ships_levels(planet_id)
    } else {
        contracts.colony.get_colony_ships(planet_id, colony_id)
    };
    assert!(ships_levels.carrier >= fleet.carrier, "Fleet:E_SHIPS_INSUFFICIENT");
    assert!(ships_levels.scraper >= fleet.scraper, "Fleet:E_SHIPS_INSUFFICIENT");
    assert!(ships_levels.sparrow >= fleet.sparrow, "Fleet:E_SHIPS_INSUFFICIENT");
    assert!(ships_levels.frigate >= fleet.frigate, "Fleet:E_SHIPS_INSUFFICIENT");
    assert!(ships_levels.armade >= fleet.armade, "Fleet:E_SHIPS_INSUFFICIENT");
}

fn get_defender_assets(contracts: Contracts, planet_id: u32) -> DefenderAssets {
    let target = colony_identity::resolve_planet(contracts.colony, planet_id);
    if target.is_colony {
        let defences = contracts
            .colony
            .get_colony_defences(target.mother_planet_id, target.colony_id);
        return DefenderAssets {
            fleet: contracts
                .colony
                .get_colony_ships(target.mother_planet_id, target.colony_id)
                .into(),
            defences,
            techs: contracts.tech.get_tech_levels(target.mother_planet_id),
            celestia: defences.celestia,
        };
    }

    let defences = contracts.defence.get_defences_levels(planet_id);
    DefenderAssets {
        fleet: contracts.dockyard.get_ships_levels(planet_id).into(),
        defences,
        techs: contracts.tech.get_tech_levels(planet_id),
        celestia: defences.celestia,
    }
}

fn calculate_loot_amount(
    contracts: Contracts, destination_id: u32, attacker_fleet: Fleet,
) -> (ERC20s, ERC20s) {
    let mut loot_collectible: ERC20s = Default::default();
    let mut loot_spendable: ERC20s = Default::default();
    let storage = fleet::get_fleet_cargo_capacity(attacker_fleet);
    let mut spendable: ERC20s = Default::default();
    let mut collectible: ERC20s = Default::default();

    let target = colony_identity::resolve_planet(contracts.colony, destination_id);
    if target.is_colony {
        collectible = contracts
            .colony
            .get_colony_resources(target.mother_planet_id, target.colony_id);
    } else {
        spendable = contracts.planet.get_spendable_resources(destination_id);
        collectible = contracts.planet.get_collectible_resources(destination_id);
    }

    loot_collectible = fleet::load_resources(collectible, storage);
    let loaded_collectible = loot_collectible.steel
        + loot_collectible.quartz
        + loot_collectible.tritium;
    let remaining_storage = storage - loaded_collectible;

    if !spendable.is_zero() && remaining_storage != 0 {
        loot_spendable.steel = spendable.steel / 2;
        loot_spendable.quartz = spendable.quartz / 2;
        loot_spendable.tritium = spendable.tritium / 2;
        loot_spendable = fleet::load_resources(loot_spendable, remaining_storage);
    }
    (loot_spendable, loot_collectible)
}
