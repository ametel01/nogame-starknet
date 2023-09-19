#[cfg(test)]
mod CompoundsTest {
    // use debug::PrintTrait;
    use nogame::compounds::Compounds;
    use nogame::ERC20s;
    use debug::PrintTrait;

    #[test]
    #[available_gas(100000000)]
    fn dockyard_cost_test() {
        let cost = Compounds::dockyard_cost(0);
        assert(cost.steel == 400, 'wrong formula');
        assert(cost.quartz == 200, 'wrong formula');
        assert(cost.tritium == 100, 'wrong formula');
        let cost = Compounds::dockyard_cost(1);
        assert(cost.steel == 800, 'wrong formula');
        assert(cost.quartz == 400, 'wrong formula');
        assert(cost.tritium == 200, 'wrong formula');
        let cost = Compounds::dockyard_cost(5);
        assert(cost.steel == 12800, 'wrong formula');
        assert(cost.quartz == 6400, 'wrong formula');
        assert(cost.tritium == 3200, 'wrong formula');
        let cost = Compounds::dockyard_cost(10);
        assert(cost.steel == 409600, 'wrong formula');
        assert(cost.quartz == 204800, 'wrong formula');
        assert(cost.tritium == 102400, 'wrong formula');
        let cost = Compounds::dockyard_cost(30);
        assert(cost.steel == 429496729600, 'wrong formula');
        assert(cost.quartz == 214748364800, 'wrong formula');
        assert(cost.tritium == 107374182400, 'wrong formula');
    }
    #[test]
    #[available_gas(1000000000)]
    fn lab_cost_test() {
        let cost = Compounds::lab_cost(0);
        assert(cost.steel == 200, 'wrong formula');
        assert(cost.quartz == 400, 'wrong formula');
        assert(cost.tritium == 200, 'wrong formula');
        let cost = Compounds::lab_cost(1);
        assert(cost.steel == 400, 'wrong formula');
        assert(cost.quartz == 800, 'wrong formula');
        assert(cost.tritium == 400, 'wrong formula');
        let cost = Compounds::lab_cost(5);
        assert(cost.steel == 6400, 'wrong formula');
        assert(cost.quartz == 12800, 'wrong formula');
        assert(cost.tritium == 6400, 'wrong formula');
        let cost = Compounds::lab_cost(10);
        assert(cost.steel == 204800, 'wrong formula');
        assert(cost.quartz == 409600, 'wrong formula');
        assert(cost.tritium == 204800, 'wrong formula');
        let cost = Compounds::lab_cost(20);
        assert(cost.steel == 209715200, 'wrong formula');
        assert(cost.quartz == 419430400, 'wrong formula');
        assert(cost.tritium == 209715200, 'wrong formula');
        let cost = Compounds::lab_cost(30);
        assert(cost.steel == 214748364800, 'wrong formula');
        assert(cost.quartz == 429496729600, 'wrong formula');
        assert(cost.tritium == 214748364800, 'wrong formula');
    }
}
