// Fleet operations utility library
// Provides shared functions for fleet management across FleetMovements and Colony contracts

use nogame::colony::contract::{IColonyDispatcher, IColonyDispatcherTrait};
use nogame::dockyard::contract::{IDockyardDispatcher, IDockyardDispatcherTrait};
use nogame::libraries::colony_identity;
use nogame::libraries::names::Names;
use nogame::libraries::types::Fleet;

#[derive(Drop, Copy)]
enum FleetOperation {
    Add,
    Remove,
}

/// Updates fleet levels for a planet or colony using batch operations
/// Handles both planet and colony scenarios.
pub fn update_fleet_levels(
    dockyard: IDockyardDispatcher,
    colony: IColonyDispatcher,
    planet_id: u32,
    fleet: Fleet,
    operation: FleetOperation,
) {
    if colony_identity::is_colony_id(planet_id) {
        update_colony_fleet(colony, planet_id, fleet, operation);
    } else {
        update_planet_fleet(dockyard, planet_id, fleet, operation);
    }
}

/// Updates fleet levels for a planet (internal helper)
fn update_planet_fleet(
    dockyard: IDockyardDispatcher, planet_id: u32, fleet: Fleet, operation: FleetOperation,
) {
    // Cache current fleet levels to avoid multiple storage reads
    let current_levels = dockyard.get_ships_levels(planet_id);

    // Calculate new levels based on operation
    let (new_carrier, new_scraper, new_sparrow, new_frigate, new_armade) = match operation {
        FleetOperation::Add => (
            current_levels.carrier + fleet.carrier,
            current_levels.scraper + fleet.scraper,
            current_levels.sparrow + fleet.sparrow,
            current_levels.frigate + fleet.frigate,
            current_levels.armade + fleet.armade,
        ),
        FleetOperation::Remove => (
            current_levels.carrier - fleet.carrier,
            current_levels.scraper - fleet.scraper,
            current_levels.sparrow - fleet.sparrow,
            current_levels.frigate - fleet.frigate,
            current_levels.armade - fleet.armade,
        ),
    };

    // Batch update ship levels - only update if the fleet type has ships
    if fleet.carrier > 0 {
        dockyard.set_ship_levels(planet_id, Names::Fleet::CARRIER, new_carrier);
    }
    if fleet.scraper > 0 {
        dockyard.set_ship_levels(planet_id, Names::Fleet::SCRAPER, new_scraper);
    }
    if fleet.sparrow > 0 {
        dockyard.set_ship_levels(planet_id, Names::Fleet::SPARROW, new_sparrow);
    }
    if fleet.frigate > 0 {
        dockyard.set_ship_levels(planet_id, Names::Fleet::FRIGATE, new_frigate);
    }
    if fleet.armade > 0 {
        dockyard.set_ship_levels(planet_id, Names::Fleet::ARMADE, new_armade);
    }
}

/// Updates fleet levels for a colony (internal helper)
fn update_colony_fleet(
    colony: IColonyDispatcher, adjusted_planet_id: u32, fleet: Fleet, operation: FleetOperation,
) {
    let colony_mother_planet = colony.get_colony_mother_planet(adjusted_planet_id);
    let colony_id = colony_identity::decode_colony_id(adjusted_planet_id, colony_mother_planet);

    match operation {
        FleetOperation::Add => colony.fleet_arrives(colony_mother_planet, colony_id, fleet),
        FleetOperation::Remove => colony.fleet_leaves(colony_mother_planet, colony_id, fleet),
    }
}
