#[cfg(test)]
mod MinesConsumptionTest {
    use debug::PrintTrait;
    use traits::Into;
    use nogame::libraries::mines::Mines;

    #[test]
    #[available_gas(1000000000)]
    fn base_consumption_test() {
        let consumption = Mines::base_mine_consumption(0);
        assert(consumption == 0, 'wrong result');
        let consumption = Mines::base_mine_consumption(1);
        assert(consumption == 11, 'wrong result');
        let consumption = Mines::base_mine_consumption(5);
        assert(consumption == 80, 'wrong result');
        let consumption = Mines::base_mine_consumption(10);
        assert(consumption == 259, 'wrong result');
        let consumption = Mines::base_mine_consumption(20);
        assert(consumption == 1345, 'wrong result');
        // Max level at which overflow occures with regular formula.
        let consumption = Mines::base_mine_consumption(31);
        assert(consumption == 5950, 'wrong result');
        let consumption = Mines::base_mine_consumption(61);
        assert(consumption == 178500, 'wrong result');
    }

    #[test]
    #[available_gas(1000000000)]
    fn tritium_consumption_test() {
        let consumption = Mines::tritium_mine_consumption(0);
        assert(consumption == 0, 'wrong result');
        let consumption = Mines::tritium_mine_consumption(1);
        assert(consumption == 22, 'wrong result');
        let consumption = Mines::tritium_mine_consumption(5);
        assert(consumption == 161, 'wrong result');
        let consumption = Mines::tritium_mine_consumption(10);
        assert(consumption == 518, 'wrong result');
        let consumption = Mines::tritium_mine_consumption(20);
        assert(consumption == 2690, 'wrong result');
        // Max level at which overflow occures with regular formula.
        let consumption = Mines::tritium_mine_consumption(31);
        assert(consumption == 11900, 'wrong result');
        let consumption = Mines::tritium_mine_consumption(61);
        assert(consumption == 357000, 'wrong result');
    }
}
