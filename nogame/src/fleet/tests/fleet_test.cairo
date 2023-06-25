#[cfg(test)]
mod FleetTests {
    use core::array::ArrayTrait;
    use debug::PrintTrait;
    use option::OptionTrait;
    use nogame::fleet::library::{Fleet, FleetImpl, Ship};

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

    #[test]
    fn unit_combat_test() {
        let ships = FleetImpl::get_ships_details();
        let a = ships.frigate;
        let b = ships.carrier;
        let (a_after, b_after) = FleetImpl::unit_combat(a, b);
        assert(b_after.integrity == 3610, 'wrong result');
        assert(b_after.shield == 0, 'wrong result');

        let a = ships.armade;
        let b = ships.celestia;
        let (a_after, b_after) = FleetImpl::unit_combat(a, b);
        let (a_after2, b_after2) = FleetImpl::unit_combat(a_after, b_after);
        assert(b_after2.integrity == 0, 'wrong result');
        assert(b_after2.shield == 0, 'wrong result');

        let a = ships.celestia;
        let b = ships.armade;
        let (a_after, b_after) = FleetImpl::unit_combat(a, b);
        let (a_after2, b_after2) = FleetImpl::unit_combat(a_after, b_after);
        assert(a_after2.integrity == 0, 'wrong result');
        assert(a_after2.shield == 0, 'wrong result');
    }

    #[test]
    #[available_gas(1000000000)]
    fn build_ships_array_test() {
        let fleet = Fleet {
            n_ships: 34, carrier: 10, scraper: 9, celestia: 7, sparrow: 5, frigate: 2, armade: 1, 
        };
        let mut array = FleetImpl::build_ships_array(fleet);
        let ship1 = array.pop_front().unwrap();
        let ship2 = array.pop_front().unwrap();
    }
}
