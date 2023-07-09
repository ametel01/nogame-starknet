#[cfg(test)]
mod CompoundsTest {
    use core::traits::Into;
    use debug::PrintTrait;
    use nogame::libraries::compounds::Compounds;
    use nogame::game::library::CostExtended;

    impl Print of PrintTrait<CostExtended> {
        fn print(self: CostExtended) {
            self.steel.low.print();
            self.quartz.low.print();
            self.tritium.low.print();
        }
    }

    #[test]
    #[available_gas(1000000000)]
    fn dockyard_cost_test() {
        let cost = Compounds::dockyard_cost(0);
        assert(cost.steel == 400.into(), 'wrong formula');
        assert(cost.quartz == 200.into(), 'wrong formula');
        assert(cost.tritium == 100.into(), 'wrong formula');
        let cost = Compounds::dockyard_cost(1);
        assert(cost.steel == 800.into(), 'wrong formula');
        assert(cost.quartz == 400.into(), 'wrong formula');
        assert(cost.tritium == 200.into(), 'wrong formula');
        let cost = Compounds::dockyard_cost(5);
        assert(cost.steel == 12800.into(), 'wrong formula');
        assert(cost.quartz == 6400.into(), 'wrong formula');
        assert(cost.tritium == 3200.into(), 'wrong formula');
        let cost = Compounds::dockyard_cost(10);
        assert(cost.steel == 409600.into(), 'wrong formula');
        assert(cost.quartz == 204800.into(), 'wrong formula');
        assert(cost.tritium == 102400.into(), 'wrong formula');
        let cost = Compounds::dockyard_cost(30);
        assert(cost.steel == 429496729600.into(), 'wrong formula');
        assert(cost.quartz == 214748364800.into(), 'wrong formula');
        assert(cost.tritium == 107374182400.into(), 'wrong formula');
        let cost = Compounds::dockyard_cost(60);
        assert(cost.steel == 461168601842738790400.into(), 'wrong formula');
        assert(cost.quartz == 230584300921369395200.into(), 'wrong formula');
        assert(cost.tritium == 115292150460684697600.into(), 'wrong formula');
    }

    #[test]
    #[available_gas(1000000000)]
    fn lab_cost_test() {
        let cost = Compounds::lab_cost(0);
        assert(cost.steel == 200.into(), 'wrong formula');
        assert(cost.quartz == 400.into(), 'wrong formula');
        assert(cost.tritium == 200.into(), 'wrong formula');
        let cost = Compounds::lab_cost(1);
        assert(cost.steel == 400.into(), 'wrong formula');
        assert(cost.quartz == 800.into(), 'wrong formula');
        assert(cost.tritium == 400.into(), 'wrong formula');
        let cost = Compounds::lab_cost(5);
        assert(cost.steel == 6400.into(), 'wrong formula');
        assert(cost.quartz == 12800.into(), 'wrong formula');
        assert(cost.tritium == 6400.into(), 'wrong formula');
        let cost = Compounds::lab_cost(10);
        assert(cost.steel == 204800.into(), 'wrong formula');
        assert(cost.quartz == 409600.into(), 'wrong formula');
        assert(cost.tritium == 204800.into(), 'wrong formula');
        let cost = Compounds::lab_cost(20);
        assert(cost.steel == 209715200.into(), 'wrong formula');
        assert(cost.quartz == 419430400.into(), 'wrong formula');
        assert(cost.tritium == 209715200.into(), 'wrong formula');
        let cost = Compounds::lab_cost(20);
        assert(cost.steel == 209715200.into(), 'wrong formula');
        assert(cost.quartz == 419430400.into(), 'wrong formula');
        assert(cost.tritium == 209715200.into(), 'wrong formula');
        let cost = Compounds::lab_cost(60);
        assert(cost.steel == 230584300921369395200.into(), 'wrong formula');
        assert(cost.quartz == 461168601842738790400.into(), 'wrong formula');
        assert(cost.tritium == 230584300921369395200.into(), 'wrong formula');
    }
}
