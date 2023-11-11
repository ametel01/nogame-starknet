use core::array::ArrayTrait;
use cubit::f128::types::fixed::{Fixed, FixedTrait, ONE_u128};
use cubit::f64::types::fixed::{FixedTrait as FixedU64, ONE};

use nogame::libraries::{math, dockyard::Dockyard};
use nogame::libraries::types::{
    ERC20s, TechLevels, Debris, Fleet, Unit, UnitTrait, ShipsCost, PlanetPosition, DefencesLevels,
};
use snforge_std::PrintTrait;

#[inline(always)]
fn CARRIER() -> Unit {
    Unit { id: 0, weapon: 50, shield: 10, hull: 1000, speed: 5000, cargo: 5000, consumption: 10 }
}

#[inline(always)]
fn SCRAPER() -> Unit {
    Unit { id: 1, weapon: 50, shield: 100, hull: 1600, speed: 2000, cargo: 20000, consumption: 300 }
}

#[inline(always)]
fn SPARROW() -> Unit {
    Unit { id: 2, weapon: 250, shield: 10, hull: 1000, speed: 12500, cargo: 50, consumption: 20 }
}

#[inline(always)]
fn FRIGATE() -> Unit {
    Unit { id: 3, weapon: 400, shield: 50, hull: 6750, speed: 15000, cargo: 800, consumption: 300 }
}

#[inline(always)]
fn ARMADE() -> Unit {
    Unit {
        id: 4, weapon: 600, shield: 200, hull: 15000, speed: 10000, cargo: 1500, consumption: 500
    }
}

#[inline(always)]
fn CELESTIA() -> Unit {
    Unit { id: 5, weapon: 1, shield: 1, hull: 500, speed: 0, cargo: 0, consumption: 0 }
}

#[inline(always)]
fn BLASTER() -> Unit {
    Unit { id: 6, weapon: 125, shield: 20, hull: 500, speed: 0, cargo: 0, consumption: 0 }
}

#[inline(always)]
fn BEAM() -> Unit {
    Unit { id: 7, weapon: 250, shield: 100, hull: 2000, speed: 0, cargo: 0, consumption: 0 }
}

#[inline(always)]
fn ASTRAL() -> Unit {
    Unit { id: 8, weapon: 1100, shield: 200, hull: 8750, speed: 0, cargo: 0, consumption: 0 }
}

#[inline(always)]
fn PLASMA() -> Unit {
    Unit { id: 9, weapon: 2000, shield: 300, hull: 20000, speed: 0, cargo: 0, consumption: 0 }
}


fn war(
    mut attackers: Fleet,
    a_techs: TechLevels,
    mut defenders: Fleet,
    defences: DefencesLevels,
    d_techs: TechLevels
) -> (Fleet, Fleet, DefencesLevels) {
    let mut attackers = build_ships_array(attackers, Zeroable::zero(), a_techs);
    let mut defenders = build_ships_array(defenders, defences, d_techs);
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
    let (attacker_fleet_struct, _) = build_fleet_struct(ref temp1);
    let (defender_fleet_struct, defences_struct) = build_fleet_struct(ref temp2);
    (attacker_fleet_struct, defender_fleet_struct, defences_struct)
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

fn build_fleet_struct(ref a: Array<Unit>) -> (Fleet, DefencesLevels) {
    let mut fleet: Fleet = Default::default();
    let mut d: DefencesLevels = Default::default();
    loop {
        if a.len().is_zero() {
            break;
        }
        let u = a.pop_front().unwrap();
        if u.id == 0 {
            if u.hull > 0 {
                fleet.carrier += 1;
            }
        }
        if u.id == 1 {
            if u.hull > 0 {
                fleet.scraper += 1;
            }
        }
        if u.id == 2 {
            if u.hull > 0 {
                fleet.sparrow += 1;
            }
        }
        if u.id == 3 {
            if u.hull > 0 {
                fleet.frigate += 1;
            }
        }
        if u.id == 4 {
            if u.hull > 0 {
                fleet.armade += 1;
            }
        }
        if u.id == 5 {
            if u.hull > 0 {
                d.celestia += 1;
            }
        }
        if u.id == 6 {
            if u.hull > 0 {
                d.blaster += 1;
            }
        }
        if u.id == 7 {
            if u.hull > 0 {
                d.beam += 1;
            }
        }
        if u.id == 8 {
            if u.hull > 0 {
                d.astral += 1;
            }
        }
        if u.id == 9 {
            if u.hull > 0 {
                d.plasma += 1;
            }
        }
        continue;
    };
    (fleet, d)
}

fn build_defences_struct(ref a: Array<Unit>) -> DefencesLevels {
    let mut d: DefencesLevels = Default::default();
    loop {
        if a.len().is_zero() {
            break;
        }
        let u = a.pop_front().unwrap();
        if u.id == 5 {
            if u.hull > 0 {
                d.celestia += 1;
            }
        }
        if u.id == 6 {
            if u.hull > 0 {
                d.blaster += 1;
            }
        }
        if u.id == 7 {
            if u.hull > 0 {
                d.beam += 1;
            }
        }
        if u.id == 8 {
            if u.hull > 0 {
                d.astral += 1;
            }
        }
        if u.id == 9 {
            if u.hull > 0 {
                d.plasma += 1;
            }
        }
        continue;
    };
    d
}

#[inline(always)]
fn calculate_number_of_ships(fleet: Fleet, defences: DefencesLevels) -> u32 {
    fleet.carrier
        + fleet.scraper
        + fleet.sparrow
        + fleet.frigate
        + fleet.armade
        + defences.celestia
        + defences.blaster
        + defences.beam
        + defences.astral
        + defences.plasma
}

fn build_ships_array(
    mut fleet: Fleet, mut defences: DefencesLevels, techs: TechLevels
) -> Array<Unit> {
    let mut array: Array<Unit> = array![];
    let mut n_ships = calculate_number_of_ships(fleet, defences);
    loop {
        if n_ships == 0 {
            break;
        }
        if defences.plasma > 0 {
            let mut defence = PLASMA();
            defence.weapon += defence.weapon * techs.weapons.into() / 10;
            defence.shield += defence.shield * techs.shield.into() / 10;
            defence.hull += defence.hull * techs.armour.into() / 10;
            array.append(defence);
            n_ships -= 1;
            defences.plasma -= 1;
        }
        if fleet.armade > 0 {
            let mut ship = ARMADE();
            ship.weapon += ship.weapon * techs.weapons.into() / 10;
            ship.shield += ship.shield * techs.shield.into() / 10;
            ship.hull += ship.hull * techs.armour.into() / 10;
            array.append(ship);
            n_ships -= 1;
            fleet.armade -= 1;
        }
        if defences.astral > 0 {
            let mut defence = ASTRAL();
            defence.weapon += defence.weapon * techs.weapons.into() / 10;
            defence.shield += defence.shield * techs.shield.into() / 10;
            defence.hull += defence.hull * techs.armour.into() / 10;
            array.append(defence);
            n_ships -= 1;
            defences.astral -= 1;
        }
        if fleet.frigate > 0 {
            let mut ship = FRIGATE();
            ship.weapon += ship.weapon * techs.weapons.into() / 10;
            ship.shield += ship.shield * techs.shield.into() / 10;
            ship.hull += ship.hull * techs.armour.into() / 10;
            array.append(ship);
            n_ships -= 1;
            fleet.frigate -= 1;
        }
        if defences.beam > 0 {
            let mut defence = BEAM();
            defence.weapon += defence.weapon * techs.weapons.into() / 10;
            defence.shield += defence.shield * techs.shield.into() / 10;
            defence.hull += defence.hull * techs.armour.into() / 10;
            array.append(defence);
            n_ships -= 1;
            defences.beam -= 1;
        }
        if fleet.sparrow > 0 {
            let mut ship = SPARROW();
            ship.weapon += ship.weapon * techs.weapons.into() / 10;
            ship.shield += ship.shield * techs.shield.into() / 10;
            ship.hull += ship.hull * techs.armour.into() / 10;
            array.append(ship);
            n_ships -= 1;
            fleet.sparrow -= 1;
        }
        if defences.blaster > 0 {
            let mut defence = BLASTER();
            defence.weapon += defence.weapon * techs.weapons.into() / 10;
            defence.shield += defence.shield * techs.shield.into() / 10;
            defence.hull += defence.hull * techs.armour.into() / 10;
            array.append(defence);
            n_ships -= 1;
            defences.blaster -= 1;
        }
        if fleet.scraper > 0 {
            let mut ship = SCRAPER();
            ship.weapon += ship.weapon * techs.weapons.into() / 10;
            ship.shield += ship.shield * techs.shield.into() / 10;
            ship.hull += ship.hull * techs.armour.into() / 10;
            array.append(ship);
            n_ships -= 1;
            fleet.scraper -= 1;
        }
        if defences.celestia > 0 {
            let mut defence = CELESTIA();
            defence.weapon += defence.weapon * techs.weapons.into() / 10;
            defence.shield += defence.shield * techs.shield.into() / 10;
            defence.hull += defence.hull * techs.armour.into() / 10;
            array.append(defence);
            n_ships -= 1;
            defences.celestia -= 1;
        }
        if fleet.carrier > 0 {
            let mut ship = CARRIER();
            ship.weapon += ship.weapon * techs.weapons.into() / 10;
            ship.shield += ship.shield * techs.shield.into() / 10;
            ship.hull += ship.hull * techs.armour.into() / 10;
            array.append(ship);
            n_ships -= 1;
            fleet.carrier -= 1;
        }
        let a = 0;
    };
    array
}

#[inline(always)]
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
        let level_diff = techs.spacetime - 3;
        let speed = base_speed + (base_speed * level_diff.into() * 3) / 10;
        if speed < min_speed {
            min_speed = speed;
        }
    }
    min_speed
}

#[inline(always)]
// TODO: implement speed modifier.
fn get_flight_time(speed: u32, distance: u32) -> u64 {
    let f_speed = FixedU64::new_unscaled(speed.into(), false);
    let f_distance = FixedU64::new_unscaled(distance.into(), false);
    let multiplier = FixedU64::new_unscaled(3500, false);
    let ten = FixedU64::new_unscaled(10, false);
    let res = ten
        + multiplier * FixedU64::sqrt(FixedU64::new_unscaled(10, false) * f_distance / f_speed);
    res.mag / ONE
}

#[inline(always)]
fn get_unit_consumption(ship: Unit, distance: u32) -> u128 {
    // TODO: when speed variation is available tweak this formula
    // https://ogame.fandom.com/wiki/Fuel_Consumption?so=search
    (ship.consumption * distance / 35000).into()
}

fn get_fuel_consumption(f: Fleet, distance: u32) -> u128 {
    f.carrier.into() * get_unit_consumption(CARRIER(), distance)
        + f.scraper.into() * get_unit_consumption(SCRAPER(), distance)
        + f.sparrow.into() * get_unit_consumption(SPARROW(), distance)
        + f.frigate.into() * get_unit_consumption(FRIGATE(), distance)
        + f.armade.into() * get_unit_consumption(ARMADE(), distance)
}

#[inline(always)]
fn get_distance(start: PlanetPosition, end: PlanetPosition) -> u32 {
    if start.system == end.system && start.system > end.system {
        return 5;
    }
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

#[inline(always)]
fn get_debris(f_before: Fleet, f_after: Fleet, celestia: u32) -> Debris {
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
        + ((f_before.armade - f_after.armade).into() * costs.sparrow.quartz)
        + (celestia * 2000).into();

    debris.steel = steel / 3;
    debris.quartz = quartz / 3;
    debris
}


fn load_resources(mut resources: ERC20s, mut storage: u128) -> ERC20s {
    // metal_loaded, crystal_loaded, deuterium_loaded = 0, 0, 0
    let mut steel_loaded = 0;
    let mut quartz_loaded = 0;
    let mut tritium_loaded = 0;

    // # Step 1: Load Metal
    // metal_to_load = metal / 2
    let mut steel_to_load = resources.steel / 2;
    // if metal_to_load <= storage / 3:
    if steel_to_load <= storage / 3 {
        //     metal_loaded += metal_to_load
        steel_loaded += steel_to_load;
        //     metal -= metal_to_load
        resources.steel -= steel_to_load
    } else {
        //     metal_loaded += storage / 3
        steel_loaded += storage / 3;
        //     metal -= storage / 3
        resources.steel -= storage / 3;
    }
    // storage -= metal_loaded
    storage -= steel_loaded;

    // # Step 2: Load Crystal
    // crystal_to_load = crystal / 2
    let mut quartz_to_load = resources.quartz / 2;
    // if crystal_to_load <= storage / 2:
    if quartz_to_load <= storage / 2 {
        //     crystal_loaded += crystal_to_load
        quartz_loaded += quartz_to_load;
        //     crystal -= crystal_to_load
        resources.quartz -= quartz_to_load;
    // else:
    } else {
        //     crystal_loaded += storage / 2
        quartz_loaded += storage / 2;
        //     crystal -= storage / 2
        resources.quartz -= storage / 2;
    }
    // storage -= crystal_loaded
    storage -= quartz_loaded;

    // # Step 3: Load Deuterium
    // deuterium_to_load = deuterium / 2
    let tritium_to_load = resources.tritium / 2;
    // if deuterium_to_load <= storage:
    if tritium_to_load <= storage {
        //     deuterium_loaded += deuterium_to_load
        tritium_loaded += tritium_to_load;
        //     deuterium -= deuterium_to_load
        resources.tritium -= tritium_to_load;
    // else:
    } else {
        //     deuterium_loaded += storage
        tritium_loaded += storage;
        //     deuterium -= storage
        resources.tritium -= storage;
    }
    // storage -= deuterium_loaded
    storage -= tritium_loaded;

    // # Step 4: Load remaining Metal if space is available
    // if storage > 0:
    if storage > 0 {
        //     metal_to_load = min(metal, storage / 2)
        steel_to_load = math::min(resources.steel, storage / 2);
        //     metal_loaded += metal_to_load
        steel_loaded += steel_to_load;
        //     metal -= metal_to_load
        resources.steel -= steel_to_load;
        //     storage -= metal_to_load
        storage -= steel_to_load;
    }

    // # Step 5: Load remaining Crystal if space is available
    // if storage > 0:
    if storage > 0 {
        //     crystal_to_load = min(crystal, storage)
        quartz_to_load = math::min(resources.quartz, storage);
        //     crystal_loaded += crystal_to_load
        quartz_loaded += quartz_to_load;
        //     crystal -= crystal_to_load
        resources.quartz -= quartz_to_load;
        //     storage -= crystal_to_load
        storage -= quartz_to_load;
    }
    ERC20s { steel: steel_loaded, quartz: quartz_loaded, tritium: tritium_loaded }
// return metal_loaded, crystal_loaded, deuterium_loaded, storage

}

#[inline(always)]
fn get_fleet_cargo_capacity(f: Fleet) -> u128 {
    (CARRIER().cargo * f.carrier
        + SCRAPER().cargo * f.scraper
        + SPARROW().cargo * f.sparrow
        + FRIGATE().cargo * f.frigate
        + ARMADE().cargo * f.armade)
        .into()
}

fn get_collectible_debris(cargo_capacity: u128, debris: Debris) -> Debris {
    let total_debris = debris.steel + debris.quartz;
    if cargo_capacity >= total_debris {
        return debris;
    }

    let half_capacity = cargo_capacity / 2;
    let mut collected_steel = math::min(debris.steel, half_capacity);
    let mut collected_quartz = math::min(debris.quartz, half_capacity);

    let remaining_capacity = cargo_capacity - collected_steel - collected_quartz;
    if collected_steel < half_capacity {
        collected_quartz += remaining_capacity;
    } else if collected_quartz < half_capacity {
        collected_steel += remaining_capacity;
    }
    return Debris { steel: collected_steel, quartz: collected_quartz };
}

const _0_02: u128 = 368934881474191000;

// loss = 100 * (1 - math.exp(-k * time_seconds / 60))
fn calculate_fleet_loss(time_seconds: u64) -> u32 {
    time_seconds.print();
    ((FixedTrait::new_unscaled(100_u128, false)
        * (FixedTrait::new(ONE_u128, false)
            - FixedTrait::exp(
                FixedTrait::new(_0_02, true)
                    * FixedTrait::new_unscaled(time_seconds.into(), false)
                    / FixedTrait::new_unscaled(60, false)
            )))
        .mag
        / ONE_u128)
        .try_into()
        .expect('fleet loss calc failed')
}

fn decay_fleet(fleet: Fleet, decay_amount: u32) -> Fleet {
    let mut res: Fleet = Default::default();
    res.carrier = fleet.carrier * (100 - decay_amount) / 100;
    res.scraper = fleet.scraper * (100 - decay_amount) / 100;
    res.sparrow = fleet.sparrow * (100 - decay_amount) / 100;
    res.frigate = fleet.frigate * (100 - decay_amount) / 100;
    res.armade = fleet.armade * (100 - decay_amount) / 100;
    res
}
