#[cfg(test)]
mod MineProductionTest {
    use debug::PrintTrait;
    use traits::Into;
    use nogame::libraries::mines::Mines;

    #[test]
    #[available_gas(1000000000)]
    fn steel_production_test() {
        let production = Mines::steel_production(0);
        assert(production == 0.into(), 'wrong result');
        let production = Mines::steel_production(1);
        assert(production == 33.into(), 'wrong result');
        let production = Mines::steel_production(5);
        assert(production == 241.into(), 'wrong result');
        let production = Mines::steel_production(10);
        assert(production == 778.into(), 'wrong result');
        let production = Mines::steel_production(20);
        assert(production == 4036.into(), 'wrong result');
        // Max level at which overflow occures with regular formula.
        let production = Mines::steel_production(31);
        assert(production == 17850.into(), 'wrong result');
        let production = Mines::steel_production(61);
        assert(production == 535500.into(), 'wrong result');
    }
    #[test]
    #[available_gas(1000000000)]
    fn quartz_production_test() {
        let production = Mines::quartz_production(0);
        assert(production == 0.into(), 'wrong result');
        let production = Mines::quartz_production(1);
        assert(production == 22.into(), 'wrong result');
        let production = Mines::quartz_production(5);
        assert(production == 161.into(), 'wrong result');
        let production = Mines::quartz_production(10);
        assert(production == 518.into(), 'wrong result');
        let production = Mines::quartz_production(20);
        assert(production == 2690.into(), 'wrong result');
        // Max level at which overflow occures with regular formula.
        let production = Mines::quartz_production(31);
        assert(production == 11900.into(), 'wrong result');
        let production = Mines::quartz_production(61);
        assert(production == 357000.into(), 'wrong result');
    }
    #[test]
    #[available_gas(1000000000)]
    fn tritium_production_test() {
        let production = Mines::tritium_production(0);
        assert(production == 0.into(), 'wrong result');
        let production = Mines::tritium_production(1);
        assert(production == 11.into(), 'wrong result');
        let production = Mines::tritium_production(5);
        assert(production == 80.into(), 'wrong result');
        let production = Mines::tritium_production(10);
        assert(production == 259.into(), 'wrong result');
        let production = Mines::tritium_production(20);
        assert(production == 1345.into(), 'wrong result');
        // Max level at which overflow occures with regular formula.
        let production = Mines::tritium_production(31);
        assert(production == 5950.into(), 'wrong result');
        let production = Mines::tritium_production(61);
        assert(production == 178500.into(), 'wrong result');
    }
    #[test]
    #[available_gas(1000000000)]
    fn energy_plant_production_test() {
        let production = Mines::energy_plant_production(0);
        assert(production == 30, 'wrong result');
        let production = Mines::energy_plant_production(1);
        assert(production == 52, 'wrong result');
        let production = Mines::energy_plant_production(5);
        assert(production == 191, 'wrong result');
        let production = Mines::energy_plant_production(10);
        assert(production == 548, 'wrong result');
        let production = Mines::energy_plant_production(20);
        assert(production == 2720, 'wrong result');
        // Max level at which overflow occures with regular formula.
        let production = Mines::energy_plant_production(31);
        assert(production == 11930, 'wrong result');
        let production = Mines::energy_plant_production(61);
        assert(production == 357000, 'wrong result');
    }
    #[test]
    #[available_gas(1000000000)]
    fn production_scaler_test() {
        let scaled = Mines::production_scaler(52.into(), 100, 50);
        assert(scaled == 52, '');
        let scaled = Mines::production_scaler(52.into(), 80, 100);
        assert(scaled == 41, '');
        let scaled = Mines::production_scaler(52.into(), 60, 100);
        assert(scaled == 31, '');
        let scaled = Mines::production_scaler(52.into(), 20, 100);
        assert(scaled == 10, '');
    }
}
