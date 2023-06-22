#[cfg(test)]
mod MineCostTest {
    use core::traits::Into;
    use debug::PrintTrait;
    use nogame::mines::library::Mines;
    use nogame::game::library::CostExtended;

    #[test]
    #[available_gas(1000000000)]
    fn steel_mine_cost_test() {
        let cost = Mines::steel_mine_cost(0);
        assert(cost.steel == 60.into(), 'wrong formula');
        assert(cost.quartz == 15.into(), 'wrong formula');
        let cost = Mines::steel_mine_cost(1);
        assert(cost.steel == 120.into(), 'wrong formula');
        assert(cost.quartz == 30.into(), 'wrong formula');
        let cost = Mines::steel_mine_cost(4);
        assert(cost.steel == 960.into(), 'wrong formula');
        assert(cost.quartz == 240.into(), 'wrong formula');
        let cost = Mines::steel_mine_cost(10);
        assert(cost.steel == 61440.into(), 'wrong formula');
        assert(cost.quartz == 15360.into(), 'wrong formula');
        let cost = Mines::steel_mine_cost(20);
        assert(cost.steel == 62914560.into(), 'wrong formula');
        assert(cost.quartz == 15728640.into(), 'wrong formula');
        let cost = Mines::steel_mine_cost(30);
        assert(cost.steel == 64424509440.into(), 'wrong formula');
        assert(cost.quartz == 16106127360.into(), 'wrong formula');
        let cost = Mines::steel_mine_cost(63);
        assert(cost.steel == 553402322211286548480.into(), 'wrong formula');
        assert(cost.quartz == 138350580552821637120.into(), 'wrong formula');
    }
    #[test]
    #[available_gas(1000000000)]
    fn quartz_mine_cost_test() {
        let cost = Mines::quartz_mine_cost(0);
        assert(cost.steel == 48.into(), 'wrong formula');
        assert(cost.quartz == 24.into(), 'wrong formula');
        let cost = Mines::quartz_mine_cost(1);
        assert(cost.steel == 96.into(), 'wrong formula');
        assert(cost.quartz == 48.into(), 'wrong formula');
        let cost = Mines::quartz_mine_cost(4);
        assert(cost.steel == 768.into(), 'wrong formula');
        assert(cost.quartz == 384.into(), 'wrong formula');
        let cost = Mines::quartz_mine_cost(10);
        assert(cost.steel == 49152.into(), 'wrong formula');
        assert(cost.quartz == 24576.into(), 'wrong formula');
        let cost = Mines::quartz_mine_cost(20);
        assert(cost.steel == 50331648.into(), 'wrong formula');
        assert(cost.quartz == 25165824.into(), 'wrong formula');
        let cost = Mines::quartz_mine_cost(30);
        assert(cost.steel == 51539607552.into(), 'wrong formula');
        assert(cost.quartz == 25769803776.into(), 'wrong formula');
        let cost = Mines::quartz_mine_cost(63);
        // Max level before overflow.
        assert(cost.steel == 442721857769029238784.into(), 'wrong formula');
        assert(cost.quartz == 221360928884514619392.into(), 'wrong formula');
    }
    #[test]
    #[available_gas(1000000000)]
    fn tritium_mine_cost_test() {
        let cost = Mines::tritium_mine_cost(0);
        assert(cost.steel == 225.into(), 'wrong formula');
        assert(cost.quartz == 75.into(), 'wrong formula');
        let cost = Mines::tritium_mine_cost(1);
        assert(cost.steel == 450.into(), 'wrong formula');
        assert(cost.quartz == 150.into(), 'wrong formula');
        let cost = Mines::tritium_mine_cost(4);
        assert(cost.steel == 3600.into(), 'wrong formula');
        assert(cost.quartz == 1200.into(), 'wrong formula');
        let cost = Mines::tritium_mine_cost(10);
        assert(cost.steel == 230400.into(), 'wrong formula');
        assert(cost.quartz == 76800.into(), 'wrong formula');
        let cost = Mines::tritium_mine_cost(20);
        assert(cost.steel == 235929600.into(), 'wrong formula');
        assert(cost.quartz == 78643200.into(), 'wrong formula');
        let cost = Mines::tritium_mine_cost(30);
        assert(cost.steel == 241591910400.into(), 'wrong formula');
        assert(cost.quartz == 80530636800.into(), 'wrong formula');
        // Max level before overflow.
        let cost = Mines::tritium_mine_cost(63);
        assert(cost.steel == 2075258708292324556800.into(), 'wrong formula');
        assert(cost.quartz == 691752902764108185600.into(), 'wrong formula');
    }
    #[test]
    #[available_gas(1000000000)]
    fn solar_plant_cost_test() {
        let cost = Mines::energy_plant_cost(0);
        assert(cost.steel == 75.into(), 'wrong formula');
        assert(cost.quartz == 30.into(), 'wrong formula');
        let cost = Mines::energy_plant_cost(1);
        assert(cost.steel.low == 150, 'wrong formula');
        assert(cost.quartz.low == 60, 'wrong formula');
        let cost = Mines::energy_plant_cost(4);
        assert(cost.steel == 1200.into(), 'wrong formula');
        assert(cost.quartz == 480.into(), 'wrong formula');
        let cost = Mines::energy_plant_cost(10);
        assert(cost.steel == 76800.into(), 'wrong formula');
        assert(cost.quartz == 30720.into(), 'wrong formula');
        let cost = Mines::energy_plant_cost(20);
        assert(cost.steel == 78643200.into(), 'wrong formula');
        assert(cost.quartz == 31457280.into(), 'wrong formula');
        let cost = Mines::energy_plant_cost(31);
        assert(cost.steel == 161061273600.into(), 'wrong formula');
        assert(cost.quartz == 64424509440.into(), 'wrong formula');
        // Max level before overflow.
        let cost = Mines::energy_plant_cost(63);
        assert(cost.steel == 691752902764108185600.into(), 'wrong formula');
        assert(cost.quartz == 276701161105643274240.into(), 'wrong formula');
    }
}

