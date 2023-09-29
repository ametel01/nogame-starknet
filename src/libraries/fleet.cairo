use cubit::f64::types::fixed::{Fixed, FixedTrait, ONE};

use nogame::libraries::dockyard::Dockyard;
use nogame::libraries::types::{
    TechLevels, Debris, Fleet, Unit, UnitTrait, ShipsCost, PlanetPosition
};
use debug::PrintTrait;

fn CARRIER() -> Unit {
    Unit {
        id: 0, weapon: 10, shield: 50, hull: 400, speed: 5000, cargo: 5000, fuel_consumption: 10
    }
}

fn SCRAPER() -> Unit {
    Unit {
        id: 1, weapon: 2, shield: 100, hull: 1600, speed: 2000, cargo: 20000, fuel_consumption: 300
    }
}

fn SPARROW() -> Unit {
    Unit {
        id: 2, weapon: 250, shield: 50, hull: 800, speed: 12500, cargo: 50, fuel_consumption: 20
    }
}

fn FRIGATE() -> Unit {
    Unit {
        id: 3, weapon: 800, shield: 100, hull: 5000, speed: 15000, cargo: 800, fuel_consumption: 300
    }
}

fn ARMADE() -> Unit {
    Unit {
        id: 4,
        weapon: 1500,
        shield: 200,
        hull: 9000,
        speed: 10000,
        cargo: 1500,
        fuel_consumption: 500
    }
}

fn war(
    mut attackers: Fleet, a_techs: TechLevels, mut defenders: Fleet, d_techs: TechLevels
) -> (Fleet, Fleet) {
    let mut attackers = build_ships_array(attackers, a_techs);
    let mut defenders = build_ships_array(defenders, d_techs);
    let mut temp1: Array<Unit> = array![];
    let mut temp2: Array<Unit> = array![];
    let mut u1: Unit = Default::default();
    let mut u2: Unit = Default::default();
    loop {
        if attackers.len().is_zero()
            && u1.hull.is_zero() || defenders.len().is_zero() & u2.hull.is_zero() {
            break;
        }
        if u1.hull.is_zero() {
            u1 = attackers.pop_front().unwrap();
        }
        if u2.hull.is_zero() {
            u2 = defenders.pop_front().unwrap();
        }

        unit_combat(ref u1, ref u2);
    };
    if u1.hull > 0 {
        temp1.append(u1);
    }
    if u2.hull > 0 {
        temp2.append(u2);
    }
    loop {
        if attackers.len().is_zero() {
            break;
        }
        temp1.append(attackers.pop_front().unwrap());
    };
    loop {
        if defenders.len().is_zero() {
            break;
        }
        temp2.append(defenders.pop_front().unwrap());
    };
    (build_fleet_struct(temp1), build_fleet_struct(temp2))
}

fn unit_combat(ref unit1: Unit, ref unit2: Unit) {
    loop {
        if unit1.is_destroyed() || unit2.is_destroyed() {
            break;
        }

        if unit1.weapon < unit2.shield / 100 {
            continue;
        } else if unit1.weapon < unit2.shield {
            unit2.shield -= unit1.weapon
        } else if unit2.hull < unit1.weapon - unit2.shield {
            unit2.hull = 0;
        } else {
            unit2.shield = 0;
            unit2.hull -= unit1.weapon - unit2.shield;
        }

        if unit2.weapon < unit1.shield / 100 {
            continue;
        } else if unit2.weapon < unit1.shield {
            unit1.shield -= unit2.weapon
        } else if unit1.hull < unit2.weapon - unit1.shield {
            unit1.hull = 0;
        } else {
            unit1.shield = 0;
            unit1.hull -= unit2.weapon - unit1.shield;
        }
        continue;
    };
}

fn build_fleet_struct(mut a: Array<Unit>) -> Fleet {
    let mut fleet: Fleet = Default::default();
    loop {
        if a.len().is_zero() {
            break;
        }
        let u = a.pop_front().unwrap();
        if u.id == 0 {
            if u.hull > 0 {
                fleet.carrier += 1;
                fleet.n_ships += 1;
            }
        }
        if u.id == 1 {
            if u.hull > 0 {
                fleet.scraper += 1;
                fleet.n_ships += 1;
            }
        }
        if u.id == 2 {
            if u.hull > 0 {
                fleet.sparrow += 1;
                fleet.n_ships += 1;
            }
        }
        if u.id == 3 {
            if u.hull > 0 {
                fleet.frigate += 1;
                fleet.n_ships += 1;
            }
        }
        if u.id == 4 {
            if u.hull > 0 {
                fleet.armade += 1;
                fleet.n_ships += 1;
            }
        }
        continue;
    };
    fleet
}

fn build_ships_array(mut fleet: Fleet, techs: TechLevels) -> Array<Unit> {
    let mut array: Array<Unit> = array![];
    loop {
        if fleet.n_ships == 0 {
            break;
        }
        if fleet.armade > 0 {
            let mut ship = ARMADE();
            ship.weapon += ship.weapon * techs.weapons.into() / 10;
            ship.shield += ship.shield * techs.shield.into() / 10;
            ship.hull += ship.hull * techs.armour.into() / 10;
            array.append(ship);
            fleet.n_ships -= 1;
            fleet.armade -= 1;
        }
        if fleet.frigate > 0 {
            let mut ship = FRIGATE();
            ship.weapon += ship.weapon * techs.weapons.into() / 10;
            ship.shield += ship.shield * techs.shield.into() / 10;
            ship.hull += ship.hull * techs.armour.into() / 10;
            array.append(ship);
            fleet.n_ships -= 1;
            fleet.frigate -= 1;
        }
        if fleet.sparrow > 0 {
            let mut ship = SPARROW();
            ship.weapon += ship.weapon * techs.weapons.into() / 10;
            ship.shield += ship.shield * techs.shield.into() / 10;
            ship.hull += ship.hull * techs.armour.into() / 10;
            array.append(ship);
            fleet.n_ships -= 1;
            fleet.sparrow -= 1;
        }
        if fleet.scraper > 0 {
            let mut ship = SCRAPER();
            ship.weapon += ship.weapon * techs.weapons.into() / 10;
            ship.shield += ship.shield * techs.shield.into() / 10;
            ship.hull += ship.hull * techs.armour.into() / 10;
            array.append(ship);
            fleet.n_ships -= 1;
            fleet.scraper -= 1;
        }
        if fleet.carrier > 0 {
            let mut ship = CARRIER();
            ship.weapon += ship.weapon * techs.weapons.into() / 10;
            ship.shield += ship.shield * techs.shield.into() / 10;
            ship.hull += ship.hull * techs.armour.into() / 10;
            array.append(ship);
            fleet.n_ships -= 1;
            fleet.carrier -= 1;
        }
        let a = 0;
    };
    array
}

fn get_fleet_speed(fleet: Fleet, techs: TechLevels) -> u32 {
    let mut min_speed = 4294967295;
    let combustion: u32 = techs.combustion.into();
    let thrust: u32 = techs.thrust.into();
    if fleet.carrier > 0 && thrust >= 4 {
        let base_speed = CARRIER().speed * 2;
        let level_diff = thrust - 4;
        let speed = base_speed + (base_speed * level_diff * 2) / 10;
        if speed < min_speed {
            min_speed = speed;
        }
    }
    if fleet.carrier > 0 && thrust < 4 {
        let base_speed = CARRIER().speed;
        let speed = base_speed + (base_speed * combustion) / 10;
        if speed < min_speed {
            min_speed = speed;
        }
    }
    if fleet.scraper > 0 {
        let base_speed = SCRAPER().speed;
        let speed = base_speed + (base_speed * combustion) / 10;
        if speed < min_speed {
            min_speed = speed;
        }
    }
    if fleet.sparrow > 0 {
        let base_speed = SPARROW().speed;
        let speed = base_speed + (base_speed * combustion) / 10;
        if speed < min_speed {
            min_speed = speed;
        }
    }
    if fleet.frigate > 0 {
        let base_speed = FRIGATE().speed;
        let level_diff = thrust - 4;
        let speed = base_speed + (base_speed * level_diff * 2) / 10;
        if speed < min_speed {
            min_speed = speed;
        }
    }
    if fleet.armade > 0 {
        let base_speed = ARMADE().speed;
        let level_diff = techs.spacetime - 4;
        let speed = base_speed + (base_speed * level_diff.into() * 3) / 10;
        if speed < min_speed {
            min_speed = speed;
        }
    }
    min_speed
}

// TODO: implement speed modifier.
fn get_flight_time(speed: u32, distance: u32) -> u64 {
    let f_speed = FixedTrait::new_unscaled(speed.into(), false);
    let f_distance = FixedTrait::new_unscaled(distance.into(), false);
    let multiplier = FixedTrait::new_unscaled(3510, false);
    let res = multiplier
        * FixedTrait::sqrt(FixedTrait::new_unscaled(10, false) * f_distance / f_speed);
    res.mag / ONE
}

fn get_distance(start: PlanetPosition, end: PlanetPosition) -> u32 {
    if start.system == end.system {
        if start.orbit > end.orbit {
            let dis: u32 = (start.orbit - end.orbit).into();
            return 1000 + 5 * dis;
        } else {
            let dis: u32 = (end.orbit - start.orbit).into();
            return 1000 + 5 * dis;
        }
    } else {
        if start.system > end.system {
            let dis: u32 = (start.system - end.system).into();
            return 2700 + 95 * dis;
        } else {
            let dis: u32 = (end.system - start.system).into();
            return 2700 + 95 * dis;
        }
    }
}

fn get_debris(f_before: Fleet, f_after: Fleet) -> Debris {
    let mut debris: Debris = Default::default();
    let costs = Dockyard::get_ships_unit_cost();
    let steel = ((f_before.carrier - f_after.carrier).into() * costs.carrier.steel)
        + ((f_before.scraper - f_after.scraper).into() * costs.scraper.steel)
        + ((f_before.sparrow - f_after.sparrow).into() * costs.sparrow.steel)
        + ((f_before.frigate - f_after.frigate).into() * costs.sparrow.steel)
        + ((f_before.armade - f_after.armade).into() * costs.sparrow.steel);

    let quartz = ((f_before.carrier - f_after.carrier).into() * costs.carrier.quartz)
        + ((f_before.scraper - f_after.scraper).into() * costs.scraper.quartz)
        + ((f_before.sparrow - f_after.sparrow).into() * costs.sparrow.quartz)
        + ((f_before.frigate - f_after.frigate).into() * costs.sparrow.quartz)
        + ((f_before.armade - f_after.armade).into() * costs.sparrow.quartz);

    debris.steel = steel / 3;
    debris.quartz = quartz / 3;
    debris
}
