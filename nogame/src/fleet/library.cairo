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
        if len == 0 {
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
            }
        } else if ship.consumption == 300 {
            fleet = Fleet {
                n_ships: fleet.n_ships,
                carrier: fleet.carrier,
                scraper: fleet.scraper + 1,
                celestia: fleet.celestia,
                sparrow: fleet.sparrow,
                frigate: fleet.frigate,
                armade: fleet.armade,
            }
        } else if ship.consumption == 1 {
            fleet = Fleet {
                n_ships: fleet.n_ships,
                carrier: fleet.carrier,
                scraper: fleet.scraper,
                celestia: fleet.celestia + 1,
                sparrow: fleet.sparrow,
                frigate: fleet.frigate,
                armade: fleet.armade,
            }
        } else if ship.consumption == 20 {
            fleet = Fleet {
                n_ships: fleet.n_ships,
                carrier: fleet.carrier,
                scraper: fleet.scraper,
                celestia: fleet.celestia,
                sparrow: fleet.sparrow + 1,
                frigate: fleet.frigate,
                armade: fleet.armade,
            }
        } else if ship.consumption == 350 {
            fleet = Fleet {
                n_ships: fleet.n_ships,
                carrier: fleet.carrier,
                scraper: fleet.scraper,
                celestia: fleet.celestia,
                sparrow: fleet.sparrow,
                frigate: fleet.frigate + 1,
                armade: fleet.armade,
            }
        } else {
            fleet = Fleet {
                n_ships: fleet.n_ships,
                carrier: fleet.carrier,
                scraper: fleet.scraper,
                celestia: fleet.celestia,
                sparrow: fleet.sparrow,
                frigate: fleet.frigate,
                armade: fleet.armade + 1,
            }
        }
        len -= 1;
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
                n_ships: fleet.n_ships,
                carrier: fleet.carrier,
                scraper: fleet.scraper,
                celestia: fleet.celestia,
                sparrow: fleet.sparrow,
                frigate: fleet.frigate,
                armade: fleet.armade - 1,
            }
        } else if fleet.frigate > 0 {
            array.append(ships.frigate);
            fleet = Fleet {
                n_ships: fleet.n_ships,
                carrier: fleet.carrier,
                scraper: fleet.scraper,
                celestia: fleet.celestia,
                sparrow: fleet.sparrow,
                frigate: fleet.frigate - 1,
                armade: fleet.armade,
            }
        } else if fleet.sparrow > 0 {
            array.append(ships.sparrow);
            fleet = Fleet {
                n_ships: fleet.n_ships,
                carrier: fleet.carrier,
                scraper: fleet.scraper,
                celestia: fleet.celestia,
                sparrow: fleet.sparrow - 1,
                frigate: fleet.frigate,
                armade: fleet.armade,
            }
        } else if fleet.scraper > 0 {
            array.append(ships.scraper);
            fleet = Fleet {
                n_ships: fleet.n_ships,
                carrier: fleet.carrier,
                scraper: fleet.scraper - 1,
                celestia: fleet.celestia,
                sparrow: fleet.sparrow,
                frigate: fleet.frigate,
                armade: fleet.armade,
            }
        } else if fleet.carrier > 0 {
            array.append(ships.carrier);
            fleet = Fleet {
                n_ships: fleet.n_ships,
                carrier: fleet.carrier - 1,
                scraper: fleet.scraper,
                celestia: fleet.celestia,
                sparrow: fleet.sparrow,
                frigate: fleet.frigate,
                armade: fleet.armade,
            }
        } else if fleet.celestia > 0 {
            array.append(ships.celestia);
            fleet = Fleet {
                n_ships: fleet.n_ships,
                carrier: fleet.carrier,
                scraper: fleet.scraper,
                celestia: fleet.celestia - 1,
                sparrow: fleet.sparrow,
                frigate: fleet.frigate,
                armade: fleet.armade,
            }
        }
        fleet.n_ships -= 1;
    };
    array
}

fn unit_combat(mut a: Ship, mut b: Ship) -> (Ship, Ship) {
    if a.weapon > b.integrity + b.shield {
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
    if b
        .shield > a
        .weapon {} else {
            a.weapon -= b.shield;
            let updated_integrity = b.integrity - a.weapon;
            final_b = Ship {
                integrity: updated_integrity,
                shield: 0,
                weapon: b.weapon,
                cargo: b.cargo,
                speed: b.speed,
                consumption: b.consumption
            };
        }
    if a
        .shield > b
        .weapon {} else {
            b.weapon -= a.shield;
            let updated_integrity = a.integrity - b.weapon;
            final_a = Ship {
                integrity: updated_integrity,
                shield: 0,
                weapon: a.weapon,
                cargo: a.cargo,
                speed: a.speed,
                consumption: a.consumption
            };
        }

    (final_a, final_b)
}
