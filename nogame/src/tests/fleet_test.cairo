#[cfg(test)]
mod FleetTests {
    use core::array::ArrayTrait;
    use debug::PrintTrait;
    use option::OptionTrait;
    use nogame::fleet::library::{
        Fleet, FleetImpl, Ship, battle_round, get_ships_details, build_ships_array, unit_combat,
        calculate_debris, build_ships_struct
    };

    #[test]
    #[available_gas(1000000000)]
    fn run_battle_test() {
        let a = Fleet {
            n_ships: 100,
            carrier: 10,
            scraper: 20,
            celestia: 30,
            sparrow: 20,
            frigate: 10,
            armade: 10,
        };
        let b = Fleet {
            n_ships: 220,
            carrier: 100,
            scraper: 0,
            celestia: 10,
            sparrow: 0,
            frigate: 60,
            armade: 50,
        };
        let (new_a, new_b) = FleetImpl::run_battle(a, b);
        let debris_a = calculate_debris(a, new_a);
        let debris_b = calculate_debris(b, new_b);
        (debris_a.steel.low + debris_b.steel.low).print();
        (debris_a.quartz.low + debris_b.quartz.low).print();
    }
    #[test]
    fn unit_combat_test() {
        let ships = get_ships_details();
        let a = ships.frigate;
        let b = ships.carrier;
        let (a_after, b_after) = unit_combat(a, b);
        assert(b_after.integrity == 410, 'wrong result');
        assert(b_after.shield == 0, 'wrong result');
        let a = ships.armade;
        let b = ships.celestia;
        let (a_after, b_after) = unit_combat(a, b);
        let (a_after2, b_after2) = unit_combat(a_after, b_after);
        assert(b_after2.integrity == 0, 'wrong result');
        assert(b_after2.shield == 0, 'wrong result');
        let a = ships.celestia;
        let b = ships.armade;
        let (a_after, b_after) = unit_combat(a, b);
        let (a_after2, b_after2) = unit_combat(a_after, b_after);
        assert(a_after2.integrity == 0, 'wrong result');
        assert(a_after2.shield == 0, 'wrong result');
    }
    #[test]
    #[available_gas(1000000000000)]
    fn build_ships_array_test() {
        let fleet = Fleet {
            n_ships: 15, carrier: 10, scraper: 0, celestia: 0, sparrow: 5, frigate: 0, armade: 0, 
        };
        let mut array = build_ships_array(fleet);
        let ship1 = array.pop_front().unwrap();
        let ship2 = array.pop_front().unwrap();
    }
    #[test]
    #[available_gas(1000000000)]
    fn build_ships_struct_test() {
        let fleet = Fleet {
            n_ships: 34, carrier: 10, scraper: 9, celestia: 7, sparrow: 5, frigate: 2, armade: 1, 
        };
        let a = build_ships_array(fleet);
        let b = build_ships_struct(a);
        assert(b == fleet, 'wrong function')
    }
    #[test]
    #[available_gas(1000000000)]
    fn battle_round_test() {
        let fleet_a = Fleet {
            n_ships: 1049,
            carrier: 1025,
            scraper: 1,
            celestia: 2,
            sparrow: 1,
            frigate: 10,
            armade: 10,
        };
        let fleet_b = Fleet {
            n_ships: 501, carrier: 500, scraper: 0, celestia: 1, sparrow: 0, frigate: 0, armade: 0, 
        };
        let a = build_ships_array(fleet_a);
        let b = build_ships_array(fleet_b);
        let (mut new_a, mut new_b) = battle_round(a, b);
        let (mut new_a2, mut new_b2) = battle_round(new_a, new_b);
    }
}
