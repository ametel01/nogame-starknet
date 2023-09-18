use starknet::{ContractAddress, contract_address_const, get_block_timestamp};

use xoroshiro::xoroshiro::{IXoroshiroDispatcher, IXoroshiroDispatcherTrait};

use nogame::game::library::{TechLevels, Debris};
use debug::PrintTrait;

fn RAND() -> ContractAddress {
    contract_address_const::<0x7c60937c7d7228fced85709fdf9ffcd2c159bd4a734f7a31fd0c13f5668c0b5>()
}

#[derive(Drop, Copy, PartialEq)]
struct Fleet {
    n_ships: u32,
    carrier: u32,
    scraper: u32,
    sparrow: u32,
    frigate: u32,
    armade: u32,
}

#[derive(Drop, Copy, Debug, PartialEq)]
struct Unit {
    id: u8,
    hull: u32,
    shield: u32,
    weapon: u32,
    exists: bool,
}

extern fn alloc_local<Unit>() -> Unit nopanic;

fn CARRIER_RF() -> Array<u8> {
    array![0, 0, 0, 0, 0]
}
fn CARRIER() -> Unit {
    Unit { id: 0, weapon: 30, shield: 10, hull: 4000, exists: true, }
}
fn SCRAPER_RF() -> Array<u8> {
    array![0, 0, 0, 0, 0]
}
fn SCRAPER() -> Unit {
    Unit { id: 1, weapon: 2, shield: 10, hull: 16000, exists: true, }
}
fn SPARROW_RF() -> Array<u8> {
    array![0, 0, 0, 0, 0]
}
fn SPARROW() -> Unit {
    Unit { id: 2, weapon: 50, shield: 20, hull: 4000, exists: true, }
}
fn FRIGATE_RF() -> Array<u8> {
    array![0, 0, 6, 0, 0]
}
fn FRIGATE() -> Unit {
    Unit { id: 3, weapon: 1600, shield: 100, hull: 27000, exists: true, }
}
fn ARMADE_RF() -> Array<u8> {
    array![0, 0, 0, 0, 0]
}
fn ARMADE() -> Unit {
    Unit { id: 4, weapon: 3000, shield: 400, hull: 60000, exists: true, }
}

fn CELESTIA_RF() -> Array<u8> {
    array![0, 0, 0, 0, 0]
}
fn CELESTIA() -> Unit {
    Unit { id: 5, weapon: 2, shield: 1, hull: 2000, exists: true, }
}


fn combat(
    attackers: Fleet, a_techs: TechLevels, defenders: Fleet, d_techs: TechLevels
) -> (Fleet, Fleet) {
    let mut attackers = build_ships_array(attackers, a_techs);
    let mut defenders = build_ships_array(defenders, d_techs);
    let mut rounds = 6;
    loop {
        if rounds == 0 {
            break;
        }
        let mut len = attackers.len();
        loop {
            if attackers.len() == 0 || defenders.len() == 0 {
                break;
            }
            if len == 0 {
                break;
            }
            let attacker = attackers.pop_front().unwrap();
            let mut target = defenders.pop_front().unwrap();
            target = perform_combat(attacker, target);
            let (is_rapidfire, mut rapidfire) = rapid_fire(attacker, target);
            if is_rapidfire {
                loop {
                    if defenders.len() == 0 {
                        break;
                    }
                    if rapidfire == 0 {
                        break;
                    }
                    let mut target_rf = defenders.pop_front().unwrap();
                    target_rf = perform_combat(attacker, target_rf);
                    defenders.append(target_rf);
                    rapidfire -= 1;
                }
            }
            if target.exists {
                defenders.append(target);
            }
            len -= 1;
            attackers.append(attacker);
        };
        let mut len = defenders.len();
        loop {
            if attackers.len() == 0 || defenders.len() == 0 {
                break;
            }
            if len == 0 {
                break;
            }
            let attacker = defenders.pop_front().unwrap();
            let mut target = attackers.pop_front().unwrap();
            target = perform_combat(attacker, target);
            let (is_rapidfire, mut rapidfire) = rapid_fire(attacker, target);
            if is_rapidfire {
                loop {
                    if attackers.len() == 0 {
                        break;
                    }
                    if rapidfire == 0 {
                        break;
                    }
                    let mut target_rf = attackers.pop_front().unwrap();
                    target_rf = perform_combat(attacker, target_rf);
                    attackers.append(target_rf);
                    rapidfire -= 1;
                }
            }
            if target.exists {
                attackers.append(target);
            }
            len -= 1;
            defenders.append(attacker);
        };

        rounds -= 1;
    };

    (build_fleet_struct(attackers), build_fleet_struct(defenders))
}


fn perform_combat(mut attacker: Unit, mut defender: Unit) -> Unit {
    if attacker.weapon < (defender.shield / 100) {
        return defender;
    } else if attacker.weapon < defender.shield {
        defender.shield -= attacker.weapon;
    } else if defender.hull < attacker.weapon - defender.shield {
        defender.hull = 0;
        defender.exists = false;
    } else {
        let initial_hull = get_unit(defender.id).hull;
        defender.hull -= (attacker.weapon - defender.shield);
        if (defender.hull * 10000 / initial_hull) < 7500 {
            let prob = 10000 - (defender.hull * 10000 / initial_hull);
            let rand = IXoroshiroDispatcher { contract_address: RAND() }.next() % 10000;
            if (rand < prob.into()) {
                defender.hull = 0;
                defender.exists = false;
            }
        }
    }
    defender
}

fn build_fleet_struct(mut a: Array<Unit>) -> Fleet {
    let mut fleet = Fleet {
        n_ships: 0, carrier: 0, scraper: 0, sparrow: 0, frigate: 0, armade: 0,
    };
    let mut len = a.len();
    loop {
        if len == 0 {
            break;
        }
        let u = a.pop_front().unwrap();
        if u.id == 0 {
            if u.exists {
                fleet.carrier += 1;
                fleet.n_ships += 1;
            }
        } else if u.id == 1 {
            if u.exists {
                fleet.scraper += 1;
                fleet.n_ships += 1;
            }
        } else if u.id == 2 {
            if u.exists {
                fleet.sparrow += 1;
                fleet.n_ships += 1;
            }
        } else if u.id == 3 {
            if u.exists {
                fleet.frigate += 1;
                fleet.n_ships += 1;
            }
        } else if u.id == 4 {
            if u.exists {
                fleet.armade += 1;
                fleet.n_ships += 1;
            }
        }
        len -= 1;
    };
    fleet
}

fn rapid_fire(a: Unit, b: Unit) -> (bool, u8) {
    let rapid_fire = get_rapid_fire(a.id, b.id);
    (rapid_fire > 0, rapid_fire)
}

fn get_rapid_fire(a_id: u8, b_id: u8) -> u8 {
    if a_id == 0 {
        let rf = CARRIER_RF();
        return *rf.at(b_id.into());
    } else if a_id == 1 {
        return 0;
    } else if a_id == 2 {
        let rf = SCRAPER_RF();
        return *rf.at(b_id.into());
    } else if a_id == 3 {
        let rf = SPARROW_RF();
        return *rf.at(b_id.into());
    } else if a_id == 4 {
        let rf = FRIGATE_RF();
        return *rf.at(b_id.into());
    } else {
        let rf = ARMADE_RF();
        return *rf.at(b_id.into());
    }
}

fn get_unit(id: u8) -> Unit {
    if id == 0 {
        return CARRIER();
    } else if id == 1 {
        return SCRAPER();
    } else if id == 2 {
        return SPARROW();
    } else if id == 3 {
        return FRIGATE();
    } else {
        return ARMADE();
    }
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

use box::BoxTrait;

impl PrintUnit of PrintTrait<Unit> {
    fn print(self: Unit) {
        self.weapon.print();
        self.shield.print();
        self.hull.print();
    }
}

use starknet::testing::set_block_timestamp;

fn TEST_TECHS_1() -> TechLevels {
    TechLevels {
        energy: 0,
        digital: 0,
        beam: 0,
        armour: 1,
        ion: 0,
        plasma: 0,
        weapons: 2,
        shield: 3,
        spacetime: 0,
        combustion: 0,
        thrust: 0,
        warp: 0,
    }
}
fn TEST_TECHS_2() -> TechLevels {
    TechLevels {
        energy: 0,
        digital: 0,
        beam: 0,
        armour: 10,
        ion: 0,
        plasma: 0,
        weapons: 10,
        shield: 10,
        spacetime: 0,
        combustion: 0,
        thrust: 0,
        warp: 0,
    }
}

fn TEST_FLEET_1() -> Fleet {
    Fleet { n_ships: 4, carrier: 0, scraper: 0, sparrow: 0, frigate: 0, armade: 4, }
}

fn TEST_FLEET_2() -> Fleet {
    Fleet { n_ships: 100, carrier: 0, scraper: 0, sparrow: 50, frigate: 50, armade: 0, }
}

use snforge_std::{declare, ContractClassTrait};

// #[test]
// fn test_build_array() {
//     let fleet = TEST_FLEET_1();
//     let a = build_ships_array(fleet);
//     a.len().print();
// }

#[test]
#[available_gas(20000000000)]
fn test_combat() {
    let contract = declare('Xoroshiro');
    let calldata: Array<felt252> = array![64];
    let rand = contract.deploy(@calldata).unwrap();
    let mut attackers = TEST_FLEET_1();
    let mut defenders = TEST_FLEET_2();
    let (attackers, defenders) = combat(attackers, TEST_TECHS_2(), defenders, TEST_TECHS_1());
}
