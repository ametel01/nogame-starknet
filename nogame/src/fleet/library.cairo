use core::debug::PrintTrait;
use core::array::ArrayTrait;
use option::OptionTrait;

#[derive(Drop, Copy)] //, storage_access::StoragAccess)]
struct ShipsList {
    carrier: Ship,
    scraper: Ship,
    celestia: Ship,
    sparrow: Ship,
    frigate: Ship,
    armade: Ship,
}

#[derive(Drop, Copy)]
struct Fleet {
    n_ships: u128,
    carrier: u128,
    scraper: u128,
    celestia: u128,
    sparrow: u128,
    frigate: u128,
    armade: u128,
}

#[derive(Drop, Copy, Debug, PartialEq)] //, Debug, storage_access::StoragAccess)]
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
    fn get_ships_details() -> ShipsList {
        let _carrier = Ship {
            integrity: 4000, shield: 10, weapon: 5, cargo: 15000, speed: 5000, consumption: 10
        };
        let _scraper = Ship {
            integrity: 16000, shield: 10, weapon: 1, cargo: 20000, speed: 2000, consumption: 300
        };
        let _celestia = Ship {
            integrity: 2000, shield: 0, weapon: 0, cargo: 5, speed: 100000000, consumption: 1
        };
        let _sparrow = Ship {
            integrity: 4000, shield: 10, weapon: 50, cargo: 50, speed: 12500, consumption: 20
        };
        let _frigate = Ship {
            integrity: 27000, shield: 50, weapon: 400, cargo: 800, speed: 15000, consumption: 300
        };
        let _armade = Ship {
            integrity: 60000,
            shield: 200,
            weapon: 1000,
            cargo: 15000,
            speed: 10000,
            consumption: 500
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

    fn build_ships_array(mut fleet: Fleet) -> Array<Ship> {
        let mut array = ArrayTrait::<Ship>::new();
        let ships = FleetImpl::get_ships_details();
        loop {
            if fleet.n_ships == 0 {
                break;
            }
            if fleet.carrier > 0 {
                array.append(ships.carrier);
                fleet.carrier -= 1;
            }
            if fleet.celestia > 0 {
                array.append(ships.celestia);
                fleet.celestia -= 1;
            }
            if fleet.scraper > 0 {
                array.append(ships.scraper);
                fleet.scraper -= 1;
            }
            if fleet.sparrow > 0 {
                array.append(ships.sparrow);
                fleet.sparrow -= 1;
            }
            if fleet.frigate > 0 {
                array.append(ships.frigate);
                fleet.frigate -= 1;
            }
            if fleet.armade > 0 {
                array.append(ships.armade);
                fleet.armade -= 1;
            }
            fleet.n_ships -= 1;
        };
        array
    }

    fn unit_combat(mut a: Ship, mut b: Ship) -> (Ship, Ship) {
        let mut final_b = b;
        let mut final_a = a;
        if b
            .shield > a
            .weapon {} else {
                a.weapon -= b.shield;
                final_b.integrity -= a.weapon;
                if final_b.integrity == 0 {
                    return (final_a, final_b);
                }
                let updated_integrity = b.integrity - a.weapon;
                final_b = Ship {
                    integrity: updated_integrity,
                    shield: 0,
                    weapon: b.weapon,
                    cargo: b.cargo,
                    speed: b.speed,
                    consumption: b.consumption
                };
            // final_b.integrity.print();

            }
        if a
            .shield > b
            .weapon {} else {
                b.weapon -= a.shield;
                final_a.integrity -= b.weapon;
                if final_a.integrity == 0 {
                    return (final_a, final_b);
                }
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

    
}
