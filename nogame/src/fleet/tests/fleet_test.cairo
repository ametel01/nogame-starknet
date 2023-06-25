#[cfg(test)]
mod FleetTests {
    use core::array::ArrayTrait;
    use debug::PrintTrait;
    use option::OptionTrait;
    use nogame::fleet::library::{
        Fleet, FleetImpl, Ship, battle_round, get_ships_details, build_ships_array, unit_combat,
        build_ships_struct
    };

    #[test]
    #[available_gas(1000000000)]
    fn run_battle_test() {
        let a = Fleet {
            n_ships: 39, carrier: 10, scraper: 9, celestia: 7, sparrow: 5, frigate: 2, armade: 16, 
        };
        let b = Fleet {
            n_ships: 20, carrier: 10, scraper: 0, celestia: 10, sparrow: 0, frigate: 0, armade: 0, 
        };
        let (new_a, new_b) = FleetImpl::run_battle(a, b);
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
    #[available_gas(1000000000)]
    fn build_ships_array_test() {
        let fleet = Fleet {
            n_ships: 39, carrier: 10, scraper: 9, celestia: 7, sparrow: 5, frigate: 2, armade: 6, 
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
            n_ships: 25, carrier: 6, scraper: 4, celestia: 0, sparrow: 6, frigate: 8, armade: 5, 
        };
        let fleet_b = Fleet {
            n_ships: 10, carrier: 0, scraper: 0, celestia: 10, sparrow: 0, frigate: 0, armade: 0, 
        };
        let a = build_ships_array(fleet_a);
        let b = build_ships_array(fleet_b);
        let (mut new_a, mut new_b) = battle_round(a, b);
        let (mut new_a2, mut new_b2) = battle_round(new_a, new_b);
    }
}
