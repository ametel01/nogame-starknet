use core::traits::Into;
use core::debug::PrintTrait;
use core::array::ArrayTrait;
use option::OptionTrait;

impl PrintShip of PrintTrait<Ship> {
    fn print(self: Ship) {
        self.integrity.print();
        self.shield.print();
        self.weapon.print();
        self.cargo.print();
        self.speed.print();
        self.consumption.print();
    }
}

impl PrintFleet of PrintTrait<Fleet> {
    fn print(self: Fleet) {
        self.n_ships.print();
        self.carrier.print();
        self.scraper.print();
        self.celestia.print();
        self.sparrow.print();
        self.frigate.print();
        self.armade.print();
    }
}

impl PrintArray of PrintTrait<Array<Ship>> {
    fn print(mut self: Array<Ship>) {
        loop {
            if self.len() == 0 {
                break;
            }
            self.pop_front().unwrap().print();
        }
    }
}

#[derive(Drop, Copy)]
struct ShipsList {
    carrier: Ship,
    scraper: Ship,
    celestia: Ship,
    sparrow: Ship,
    frigate: Ship,
    armade: Ship,
}

#[derive(Drop, Copy, PartialEq)]
struct Fleet {
    n_ships: u128,
    carrier: u128,
    scraper: u128,
    celestia: u128,
    sparrow: u128,
    frigate: u128,
    armade: u128,
}

#[derive(Drop, Copy, Debug, PartialEq)]
struct Ship {
    integrity: u128,
    shield: u128,
    weapon: u128,
    cargo: u128,
    speed: u128,
    consumption: u128
}

#[derive(Drop)]
struct Debris {
    steel: u256,
    quartz: u256
}


#[generate_trait]
impl FleetImpl of FleetTrait {
    fn run_battle(a: Fleet, b: Fleet) -> (Fleet, Fleet) {
        let a_array = build_ships_array(a);
        let b_array = build_ships_array(b);
        let (a1, b1) = battle_round(a_array, b_array);
        let (a2, b2) = battle_round(a1, b1);
        let (a3, b3) = battle_round(a2, b2);
        let (a4, b4) = battle_round(a3, b3);
        let (a5, b5) = battle_round(a4, b4);
        // let (a6, b6) = battle_round(a5, b5);
        // let (a7, b7) = battle_round(a6, b6);
        // let (a8, b8) = battle_round(a7, b7);
        // let (a9, b9) = battle_round(a8, b8);
        // let (a10, b10) = battle_round(a9, b9);
        // let (a11, b11) = battle_round(a10, b10);
        // let (a12, b12) = battle_round(a11, b11);
        // let (a13, b13) = battle_round(a12, b12);
        // let (a14, b14) = battle_round(a13, b13);
        // let (a15, b15) = battle_round(a14, b14);
        // let (a16, b16) = battle_round(a15, b15);

        let a_struct = build_ships_struct(a5);

        let b_struct = build_ships_struct(b5);
        (a_struct, b_struct)
    }
}

fn battle_round(mut a: Array<Ship>, mut b: Array<Ship>) -> (Array<Ship>, Array<Ship>) {
    let mut len = 0;
    if a.len() < b.len() {
        len = a.len();
    } else {
        len = b.len();
    }
    loop {
        if len == 0  {
            break;
        }
         
        let a_ship = a.pop_front().unwrap();
        let b_ship = b.pop_front().unwrap();
        let (new_a, new_b) = unit_combat(a_ship, b_ship);
        if new_a.integrity != 0 {
            a.append(new_a);
        }
        if new_b.integrity != 0 {
            b.append(new_b);
        }
        len -= 1;
    };
    (a, b)
}

fn get_ships_details() -> ShipsList {
    let _carrier = Ship {
        integrity: 800, shield: 10, weapon: 5, cargo: 15000, speed: 5000, consumption: 10
    };
    let _scraper = Ship {
        integrity: 3200, shield: 10, weapon: 1, cargo: 20000, speed: 2000, consumption: 300
    };
    let _celestia = Ship {
        integrity: 400, shield: 0, weapon: 0, cargo: 5, speed: 0, consumption: 1
    };
    let _sparrow = Ship {
        integrity: 800, shield: 10, weapon: 50, cargo: 50, speed: 12500, consumption: 20
    };
    let _frigate = Ship {
        integrity: 5500, shield: 50, weapon: 400, cargo: 800, speed: 15000, consumption: 350
    };
    let _armade = Ship {
        integrity: 12000, shield: 200, weapon: 1000, cargo: 15000, speed: 10000, consumption: 500
    };

    ShipsList {
        carrier: _carrier,
        scraper: _scraper,
        celestia: _celestia,
        sparrow: _sparrow,
        frigate: _frigate,
        armade: _armade
    }
}

fn build_ships_struct(mut a: Array<Ship>) -> Fleet {
    let mut len = a.len();
    let mut fleet = Fleet {
        n_ships: len.into(), carrier: 0, scraper: 0, celestia: 0, sparrow: 0, frigate: 0, armade: 0, 
    };
    loop {
        if len == 0 {
            break;
        }
        let ship = a.pop_front().unwrap();
        if ship.consumption == 10 {
            fleet = Fleet {
                n_ships: fleet.n_ships,
                carrier: fleet.carrier + 1,
                scraper: fleet.scraper,
                celestia: fleet.celestia,
                sparrow: fleet.sparrow,
                frigate: fleet.frigate,
                armade: fleet.armade,
            };
            len -= 1;
        } 
        if ship.consumption == 300 {
            fleet = Fleet {
                n_ships: fleet.n_ships,
                carrier: fleet.carrier,
                scraper: fleet.scraper + 1,
                celestia: fleet.celestia,
                sparrow: fleet.sparrow,
                frigate: fleet.frigate,
                armade: fleet.armade,
            };
            len -= 1;
        }
        if ship.consumption == 1 {
            fleet = Fleet {
                n_ships: fleet.n_ships,
                carrier: fleet.carrier,
                scraper: fleet.scraper,
                celestia: fleet.celestia + 1,
                sparrow: fleet.sparrow,
                frigate: fleet.frigate,
                armade: fleet.armade,
            };
            len -= 1;
        } 
        if ship.consumption == 20 {
            fleet = Fleet {
                n_ships: fleet.n_ships,
                carrier: fleet.carrier,
                scraper: fleet.scraper,
                celestia: fleet.celestia,
                sparrow: fleet.sparrow + 1,
                frigate: fleet.frigate,
                armade: fleet.armade,
            };
            len -= 1;
        } 
        if ship.consumption == 350 {
            fleet = Fleet {
                n_ships: fleet.n_ships,
                carrier: fleet.carrier,
                scraper: fleet.scraper,
                celestia: fleet.celestia,
                sparrow: fleet.sparrow,
                frigate: fleet.frigate + 1,
                armade: fleet.armade,
            };
            len -= 1;
        } 
        if ship.consumption == 500 {
            fleet = Fleet {
                n_ships: fleet.n_ships,
                carrier: fleet.carrier,
                scraper: fleet.scraper,
                celestia: fleet.celestia,
                sparrow: fleet.sparrow,
                frigate: fleet.frigate,
                armade: fleet.armade + 1,
            };
            len -= 1;
        }
        len = len;
    };
    fleet
}

fn build_ships_array(mut fleet: Fleet) -> Array<Ship> {
    let mut array = ArrayTrait::<Ship>::new();
    let ships = get_ships_details();
    loop {
        if fleet.n_ships == 0 {
            break;
        }
        if fleet.armade > 0 {
            array.append(ships.armade);
            fleet = Fleet {
                n_ships: fleet.n_ships - 1,
                carrier: fleet.carrier,
                scraper: fleet.scraper,
                celestia: fleet.celestia,
                sparrow: fleet.sparrow,
                frigate: fleet.frigate,
                armade: fleet.armade - 1,
            };
        }
        if fleet.frigate > 0 {
            array.append(ships.frigate);
            fleet = Fleet {
                n_ships: fleet.n_ships - 1,
                carrier: fleet.carrier,
                scraper: fleet.scraper,
                celestia: fleet.celestia,
                sparrow: fleet.sparrow,
                frigate: fleet.frigate - 1,
                armade: fleet.armade,
            };
        }
        if fleet.sparrow > 0 {
            array.append(ships.sparrow);
            fleet = Fleet {
                n_ships: fleet.n_ships - 1,
                carrier: fleet.carrier,
                scraper: fleet.scraper,
                celestia: fleet.celestia,
                sparrow: fleet.sparrow - 1,
                frigate: fleet.frigate,
                armade: fleet.armade,
            };
        }
        if fleet.scraper > 0 {
            array.append(ships.scraper);
            fleet = Fleet {
                n_ships: fleet.n_ships - 1,
                carrier: fleet.carrier,
                scraper: fleet.scraper - 1,
                celestia: fleet.celestia,
                sparrow: fleet.sparrow,
                frigate: fleet.frigate,
                armade: fleet.armade,
            };
        }
        if fleet.carrier > 0 {
            array.append(ships.carrier);
            fleet = Fleet {
                n_ships: fleet.n_ships - 1,
                carrier: fleet.carrier - 1,
                scraper: fleet.scraper,
                celestia: fleet.celestia,
                sparrow: fleet.sparrow,
                frigate: fleet.frigate,
                armade: fleet.armade,
            };
        }
        if fleet.celestia > 0 {
            array.append(ships.celestia);
            fleet = Fleet {
                n_ships: fleet.n_ships - 1,
                carrier: fleet.carrier,
                scraper: fleet.scraper,
                celestia: fleet.celestia - 1,
                sparrow: fleet.sparrow,
                frigate: fleet.frigate,
                armade: fleet.armade,
            };
        }
        let a = 0;
    };
    array
}

fn unit_combat(mut a: Ship, mut b: Ship) -> (Ship, Ship) {
    if a.weapon > b.integrity + b.shield && b.weapon > a.integrity + a.shield {
        return (
            Ship {
                integrity: 0,
                shield: 0,
                weapon: a.weapon,
                cargo: a.cargo,
                speed: a.speed,
                consumption: a.consumption
                }, Ship {
                integrity: 0,
                shield: 0,
                weapon: b.weapon,
                cargo: b.cargo,
                speed: b.speed,
                consumption: b.consumption
            }
        );
    } else if a.weapon > b.integrity + b.shield {
        return (
            a, Ship {
                integrity: 0,
                shield: 0,
                weapon: b.weapon,
                cargo: b.cargo,
                speed: b.speed,
                consumption: b.consumption
            }
        );
    } else if b.weapon > a.integrity + a.shield {
        return (
            Ship {
                integrity: 0,
                shield: 0,
                weapon: a.weapon,
                cargo: a.cargo,
                speed: a.speed,
                consumption: a.consumption
            }, b
        );
    }
    let mut final_b = b;
    let mut final_a = a;
    let mut a_weapon = a.weapon;
    let mut b_weapon = b.weapon;
    let mut a_shield = a.shield;
    let mut b_shield = b.shield;
    if b.shield > a.weapon {
        a_weapon = 0;
    }
    if a.shield > b.weapon {
        b_weapon = 0;
    }
    if a.weapon > b.shield {
        a_weapon = a.weapon - b.shield;
        b_shield = 0;
    }
    if b.weapon > a.shield {
        b_weapon = b.weapon - a.shield;
        a_shield = 0;
    }
    final_a = Ship {
        integrity: a.integrity - b_weapon,
        shield: a_shield,
        weapon: a.weapon,
        cargo: a.cargo,
        speed: a.speed,
        consumption: a.consumption
    };
    final_b = Ship {
        integrity: b.integrity - a_weapon,
        shield: b_shield,
        weapon: b.weapon,
        cargo: b.cargo,
        speed: b.speed,
        consumption: b.consumption
    };
    (final_a, final_b)
}

fn calculate_debris(before: Fleet, after: Fleet) -> Debris {
    let _armade = before.armade - after.armade;
    let _carrier = before.carrier - after.carrier;
    let _celestia = before.celestia - after.celestia;
    let _frigate = before.frigate - after.frigate;
    let _scraper = before.scraper - after.scraper;
    let _sparrow = before.sparrow - after.sparrow;
    let total_steel: u256 = ((45000 * _armade
        + 2000 * _carrier
        + 20000 * _frigate
        + 10000 * _scraper
        + 3000 * _sparrow)
        / 3)
        .into();
    let total_quartz: u256 = ((15000 * _armade
        + 2000 * _carrier
        + 7000 * _frigate
        + 6000 * _scraper
        + 1000 * _sparrow
        + 2000 * _celestia)
        / 3)
        .into();
    Debris { steel: total_steel, quartz: total_quartz }
}
