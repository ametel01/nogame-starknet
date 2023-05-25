#[cfg(test)]
mod MinesConsumptionTest {
    use debug::PrintTrait;
    use traits::Into;
    use nogame::mines::library::{base_mine_consumption, quarz_mine_consumption};

    #[test]
    #[available_gas(1000000000)]
    fn base_consumption_test() {
        let consumption = base_mine_consumption(0);
        assert(consumption == 0.into(), 'wrong result');
        let consumption = base_mine_consumption(1);
        assert(consumption == 11.into(), 'wrong result');
        let consumption = base_mine_consumption(5);
        assert(consumption == 80.into(), 'wrong result');
        let consumption = base_mine_consumption(10);
        assert(consumption == 259.into(), 'wrong result');
        let consumption = base_mine_consumption(20);
        assert(consumption == 1345.into(), 'wrong result');
        // Max level at which overflow occures with regular formula.
        let consumption = base_mine_consumption(31);
        assert(consumption == 5950.into(), 'wrong result');
        let consumption = base_mine_consumption(61);
        assert(consumption == 178500.into(), 'wrong result');
    }

    #[test]
    #[available_gas(1000000000)]
    fn quarz_consumption_test() {
        let consumption = quarz_mine_consumption(0);
        assert(consumption == 0.into(), 'wrong result');
        let consumption = quarz_mine_consumption(1);
        assert(consumption == 22.into(), 'wrong result');
        let consumption = quarz_mine_consumption(5);
        assert(consumption == 161.into(), 'wrong result');
        let consumption = quarz_mine_consumption(10);
        assert(consumption == 518.into(), 'wrong result');
        let consumption = quarz_mine_consumption(20);
        assert(consumption == 2690.into(), 'wrong result');
        // Max level at which overflow occures with regular formula.
        let consumption = quarz_mine_consumption(31);
        assert(consumption == 11900.into(), 'wrong result');
        let consumption = quarz_mine_consumption(61);
        assert(consumption == 357000.into(), 'wrong result');
    }
}
