// // use starknet::{ContractAddress, contract_address_const, get_block_timestamp};
// // use debug::PrintTrait;

use nogame::libraries::types::{TechLevels, Debris, Fleet, Unit, UnitTrait, PlanetPosition};

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

fn get_fleet_speed(fleet: Fleet, techs: TechLevels) -> u32 {
    let mut min_speed = 10000;
    if fleet.carrier > 0 {
        if techs.thrust > 4 {
            let base_speed = CARRIER().speed * 2;
            let level_diff = techs.thrust - 4;
            let speed = base_speed + (base_speed * level_diff * 2) / 100;
        } else {
            let base_speed = CARRIER().speed;
            let speed = base_speed + (base_speed * techs.combustion) / 100;
        }
        if speed < min_speed {
            min_speed = speed;
        }
    }
    0
}

// fn get_fleet_speed(fleet: Fleet, techs: TechLevels) -> u32 {
//     let mut min_speed = 10000000000;
//     if fleet.carrier > 0 {
//         if techs.thrust > 4 {
//             let base_speed = CARRIER().speed * 2;
//             let level_diff = techs.thrust - 4;
//             let speed = base_speed + (base_speed * level_diff * 2) / 100;
//         } else {
//             let base_speed = CARRIER().speed;
//             let speed = base_speed + (base_speed * techs.combustion) / 100;
//         }
//         if speed < min_speed {
//             min_speed = speed;
//         }
//     }
//     if fleet.scraper > 0 {
//         let base_speed = SCRAPER().speed;
//         let speed = base_speed + (base_speed * techs.combustion) / 100;

//         if speed < min_speed {
//             min_speed = speed;
//         }
//     }
//     if fleet.sparrow > 0 {
//         let base_speed = SPARROW().speed;
//         let speed = base_speed + (base_speed * techs.combustion) / 100;
//         if speed < min_speed {
//             min_speed = speed;
//         }
//     }
//     if fleet.frigate > 0 {
//         let base_speed = FRIGATE().speed;
//         let level_diff = techs.thrust - 4;
//         let speed = base_speed + (base_speed * level_diff * 2) / 100;
//         if speed < min_speed {
//             min_speed = speed;
//         }
//     }
//     if fleet.armade > 0 {
//         let base_speed = ARMADE().speed;
//         let level_diff = techs.spacetime - 4;
//         let speed = base_speed + (base_speed * level_diff * 3) / 100;
//         if speed < min_speed {
//             min_speed = speed;
//         }
//     }
//     min_speed
// }

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
// // // fn combat(
// // //     attackers: Fleet, a_techs: TechLevels, defenders: Fleet, d_techs: TechLevels
// // // ) -> (Fleet, Fleet) {
// // //     let mut attackers = build_ships_array(attackers, a_techs);
// // //     let mut defenders = build_ships_array(defenders, d_techs);
// // //     let mut rounds = 6;
// // //     loop {
// // //         if rounds == 0 {
// // //             break;
// // //         }
// // //         let mut len = attackers.len();
// // //         loop {
// // //             if attackers.len() == 0 || defenders.len() == 0 {
// // //                 break;
// // //             }
// // //             if len == 0 {
// // //                 break;
// // //             }
// // //             let attacker = attackers.pop_front().unwrap();
// // //             let mut target = defenders.pop_front().unwrap();
// // //             target = perform_combat(attacker, target);
// // //             let (is_rapidfire, mut rapidfire) = rapid_fire(attacker, target);
// // //             if is_rapidfire {
// // //                 loop {
// // //                     if defenders.len() == 0 {
// // //                         break;
// // //                     }
// // //                     if rapidfire == 0 {
// // //                         break;
// // //                     }
// // //                     let mut target_rf = defenders.pop_front().unwrap();
// // //                     target_rf = perform_combat(attacker, target_rf);
// // //                     defenders.append(target_rf);
// // //                     rapidfire -= 1;
// // //                 }
// // //             }
// // //             if target.exists {
// // //                 defenders.append(target);
// // //             }
// // //             len -= 1;
// // //             attackers.append(attacker);
// // //         };
// // //         let mut len = 0;
// // //         loop {
// // //             if attackers.len() == 0 || defenders.len() == 0 {
// // //                 break;
// // //             }
// // //             if len == 0 {
// // //                 break;
// // //             }
// // //             let attacker = defenders.pop_front().unwrap();
// // //             let mut target = attackers.pop_front().unwrap();
// // //             target = perform_combat(attacker, target);
// // //             let (is_rapidfire, mut rapidfire) = rapid_fire(attacker, target);
// // //             if is_rapidfire {
// // //                 loop {
// // //                     if attackers.len() == 0 {
// // //                         break;
// // //                     }
// // //                     if rapidfire == 0 {
// // //                         break;
// // //                     }
// // //                     let mut target_rf = attackers.pop_front().unwrap();
// // //                     target_rf = perform_combat(attacker, target_rf);
// // //                     attackers.append(target_rf);
// // //                     rapidfire -= 1;
// // //                 }
// // //             }
// // //             if target.exists {
// // //                 attackers.append(target);
// // //             }
// // //             len -= 1;
// // //             defenders.append(attacker);
// // //         };

// // //         rounds -= 1;
// // //     };

// // //     (build_fleet_struct(attackers), build_fleet_struct(defenders))
// // // }

// // // fn perform_combat(mut attacker: Unit, mut defender: Unit) -> Unit {
// // //     if attacker.weapon < (defender.shield / 100) {
// // //         return defender;
// // //     } else if attacker.weapon < defender.shield {
// // //         defender.shield -= attacker.weapon;
// // //     } else if defender.hull < attacker.weapon - defender.shield {
// // //         defender.hull = 0;
// // //         defender.exists = false;
// // //     } else {
// // //         let initial_hull = get_unit(defender.id).hull;
// // //         defender.hull -= (attacker.weapon - defender.shield);
// // //         if (defender.hull * 10000 / initial_hull) < 7500 {
// // //             let prob = 10000 - (defender.hull * 10000 / initial_hull);
// // //             let rand = IXoroshiroDispatcher { contract_address: RAND() }.next() % 10000;
// // //             if (rand < prob.into()) {
// // //                 defender.hull = 0;
// // //                 defender.exists = false;
// // //             }
// // //         }
// // //     }
// // //     defender
// // // }

// // // fn rapid_fire(a: Unit, b: Unit) -> (bool, u8) {
// // //     let rapid_fire = get_rapid_fire(a.id, b.id);
// // //     (rapid_fire > 0, rapid_fire)
// // // }

// // // fn get_rapid_fire(a_id: u8, b_id: u8) -> u8 {
// // //     if a_id == 0 {
// // //         let rf = CARRIER_RF();
// // //         return *rf.at(b_id.into());
// // //     } else if a_id == 1 {
// // //         return 0;
// // //     } else if a_id == 2 {
// // //         let rf = SCRAPER_RF();
// // //         return *rf.at(b_id.into());
// // //     } else if a_id == 3 {
// // //         let rf = SPARROW_RF();
// // //         return *rf.at(b_id.into());
// // //     } else if a_id == 4 {
// // //         let rf = FRIGATE_RF();
// // //         return *rf.at(b_id.into());
// // //     } else {
// // //         let rf = ARMADE_RF();
// // //         return *rf.at(b_id.into());
// // //     }
// // // }

// // // fn get_unit(id: u8) -> Unit {
// // //     if id == 0 {
// // //         return CARRIER();
// // //     } else if id == 1 {
// // //         return SCRAPER();
// // //     } else if id == 2 {
// // //         return SPARROW();
// // //     } else if id == 3 {
// // //         return FRIGATE();
// // //     } else {
// // //         return ARMADE();
// // //     }
// // // }


