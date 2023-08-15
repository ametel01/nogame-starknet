#[cfg(test)]
mod MineProductionTest {
    use forge_print::PrintTrait;
    use traits::Into;
    use nogame::libraries::compounds::Compounds;

    #[test]
    #[available_gas(1000000000)]
    fn steel_production_test() {
        let production = Compounds::steel_production(0);
        assert(production == 10, 'wrong result');
        let production = Compounds::steel_production(1);
        assert(production == 33, 'wrong result');
        let production = Compounds::steel_production(5);
        assert(production == 241, 'wrong result');
        let production = Compounds::steel_production(10);
        assert(production == 778, 'wrong result');
        let production = Compounds::steel_production(20);
        assert(production == 4036, 'wrong result');
        let production = Compounds::steel_production(30);
        assert(production == 15704, 'wrong result');
        let production = Compounds::steel_production(60);
        assert(production == 548066, 'wrong result');
    }
    #[test]
    #[available_gas(1000000000)]
    fn quartz_production_test() {
        let production = Compounds::quartz_production(0);
        assert(production == 10, 'wrong result');
        let production = Compounds::quartz_production(1);
        assert(production == 22, 'wrong result');
        let production = Compounds::quartz_production(5);
        assert(production == 161, 'wrong result');
        let production = Compounds::quartz_production(10);
        assert(production == 518, 'wrong result');
        let production = Compounds::quartz_production(20);
        assert(production == 2690, 'wrong result');
        // Max level at which overflow occures with regular formula.
        let production = Compounds::quartz_production(31);
        assert(production == 11900, 'wrong result');
        let production = Compounds::quartz_production(60);
        assert(production == 365377, 'wrong result');
    }
    #[test]
    #[available_gas(1000000000)]
    fn tritium_production_test() {
        let production = Compounds::tritium_production(0);
        assert(production == 0, 'wrong result');
        let production = Compounds::tritium_production(1);
        assert(production == 11, 'wrong result');
        let production = Compounds::tritium_production(5);
        assert(production == 80, 'wrong result');
        let production = Compounds::tritium_production(10);
        assert(production == 259, 'wrong result');
        let production = Compounds::tritium_production(20);
        assert(production == 1345, 'wrong result');
        let production = Compounds::tritium_production(31);
        assert(production == 5950, 'wrong result');
        let production = Compounds::tritium_production(60);
        assert(production == 182688, 'wrong result');
    }
    #[test]
    #[available_gas(1000000000)]
    fn energy_plant_production_test() {
        let production = Compounds::energy_plant_production(0);
        assert(production == 0, 'wrong result');
        let production = Compounds::energy_plant_production(1);
        assert(production == 22, 'wrong result');
        let production = Compounds::energy_plant_production(5);
        assert(production == 161, 'wrong result');
        let production = Compounds::energy_plant_production(10);
        assert(production == 518, 'wrong result');
        let production = Compounds::energy_plant_production(20);
        assert(production == 2690, 'wrong result');
        let production = Compounds::energy_plant_production(31);
        assert(production == 11900, 'wrong result');
        let production = Compounds::energy_plant_production(60);
        assert(production == 365377, 'wrong result');
    }
    #[test]
    #[available_gas(1000000000)]
    fn production_scaler_test() {
        let scaled = Compounds::production_scaler(52, 100, 50);
        assert(scaled == 52, '');
        let scaled = Compounds::production_scaler(52, 80, 100);
        assert(scaled == 41, '');
        let scaled = Compounds::production_scaler(52, 60, 100);
        assert(scaled == 31, '');
        let scaled = Compounds::production_scaler(52, 20, 100);
        assert(scaled == 10, '');
    }
}

