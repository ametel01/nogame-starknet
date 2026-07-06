use nogame::libraries::types::{COLONY_ID_MULTIPLIER, COLONY_PLANET_THRESHOLD};

#[derive(Copy, Drop)]
struct ResolvedPlanetId {
    id: u32,
    is_colony: bool,
    mother_planet_id: u32,
    colony_id: u8,
}

fn encode_colony_id(mother_planet_id: u32, colony_id: u8) -> u32 {
    (mother_planet_id * COLONY_ID_MULTIPLIER) + colony_id.into()
}

fn is_colony_id(planet_id: u32) -> bool {
    planet_id > COLONY_PLANET_THRESHOLD
}

fn decode_colony_id(colony_planet_id: u32, mother_planet_id: u32) -> u8 {
    (colony_planet_id - mother_planet_id * COLONY_ID_MULTIPLIER).try_into().unwrap()
}

fn resolve_home_planet(planet_id: u32) -> ResolvedPlanetId {
    ResolvedPlanetId { id: planet_id, is_colony: false, mother_planet_id: planet_id, colony_id: 0 }
}

fn resolve_colony(colony_planet_id: u32, mother_planet_id: u32) -> ResolvedPlanetId {
    ResolvedPlanetId {
        id: colony_planet_id,
        is_colony: true,
        mother_planet_id,
        colony_id: decode_colony_id(colony_planet_id, mother_planet_id),
    }
}

fn incoming_mission_bucket(target: ResolvedPlanetId) -> u32 {
    if target.is_colony {
        target.mother_planet_id
    } else {
        target.id
    }
}
