#[cfg(test)]
mod MineProductionTest {
    use debug::PrintTrait;
    use traits::Into;
    use nogame::mines::library::steel_production;

    #[test]
    #[available_gas(1000000000)]
    fn steel_production_test() {
        let production = steel_production(0);
        assert(production == 30.into(), 'wrong result');
        let production = steel_production(1);
        assert(production == 33.into(), 'wrong result');
        let production = steel_production(5);
        assert(production == 241.into(), 'wrong result');
        let production = steel_production(10);
        assert(production == 778.into(), 'wrong result');
        let production = steel_production(20);
        assert(production == 4036.into(), 'wrong result');
        let production = steel_production(31);
        assert(production == 17850.into(), 'wrong result');
        let production = steel_production(61);
        production.low.print();
        assert(production == 535500.into(), 'wrong result');
    }
}
