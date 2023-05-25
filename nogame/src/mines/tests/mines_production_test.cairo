#[cfg(test)]
mod MineProductionTest {
    use debug::PrintTrait;
    use traits::Into;
    use nogame::mines::library::Mines;

    #[test]
    #[available_gas(1000000000)]
    fn steel_production_test() {
        let production = Mines::steel_production(0);
        assert(production == 30.into(), 'wrong result');
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
    fn quarz_production_test() {
        let production = Mines::quarz_production(0);
        assert(production == 22.into(), 'wrong result');
        let production = Mines::quarz_production(1);
        assert(production == 22.into(), 'wrong result');
        let production = Mines::quarz_production(5);
        assert(production == 161.into(), 'wrong result');
        let production = Mines::quarz_production(10);
        assert(production == 518.into(), 'wrong result');
        let production = Mines::quarz_production(20);
        assert(production == 2690.into(), 'wrong result');
        // Max level at which overflow occures with regular formula.
        let production = Mines::quarz_production(31);
        assert(production == 11900.into(), 'wrong result');
        let production = Mines::quarz_production(61);
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
    fn solar_plant_production_test() {
        let production = Mines::solar_plant_production(0);
        assert(production == 0, 'wrong result');
        let production = Mines::solar_plant_production(1);
        assert(production == 22, 'wrong result');
        let production = Mines::solar_plant_production(5);
        assert(production == 161, 'wrong result');
        let production = Mines::solar_plant_production(10);
        assert(production == 518, 'wrong result');
        let production = Mines::solar_plant_production(20);
        assert(production == 2690, 'wrong result');
        // Max level at which overflow occures with regular formula.
        let production = Mines::solar_plant_production(31);
        assert(production == 11900, 'wrong result');
        let production = Mines::solar_plant_production(61);
        assert(production == 357000, 'wrong result');
    }
}
