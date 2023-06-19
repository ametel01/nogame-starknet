#[cfg(test)]
mod MineCostTest {
    use debug::PrintTrait;
    use nogame::mines::library::Mines;
    use nogame::game::library::Cost;

    #[test]
    #[available_gas(1000000000)]
    fn steel_mine_cost_test() {
        let cost = Mines::steel_mine_cost(0);
        assert(cost.steel.low == 60 & cost.quartz.low == 15, 'wrong formula');
        let cost = Mines::steel_mine_cost(1);
        assert(cost.steel.low == 120 & cost.quartz.low == 30, 'wrong formula');
        let cost = Mines::steel_mine_cost(4);
        assert(cost.steel.low == 960 & cost.quartz.low == 240, 'wrong formula');
        let cost = Mines::steel_mine_cost(10);
        assert(cost.steel.low == 61440 & cost.quartz.low == 15360, 'wrong formula');
        let cost = Mines::steel_mine_cost(20);
        assert(cost.steel.low == 62914560 & cost.quartz.low == 15728640, 'wrong formula');
        let cost = Mines::steel_mine_cost(30);
        assert(cost.steel.low == 64424509440 & cost.quartz.low == 16106127360, 'wrong formula');
        let cost = Mines::steel_mine_cost(63);
        // Max level before overflow.
        assert(
            cost.steel.low == 553402322211286548480 & cost.quartz.low == 138350580552821637120,
            'wrong formula'
        );
    }
    #[test]
    #[available_gas(1000000000)]
    fn quartz_mine_cost_test() {
        let cost = Mines::quartz_mine_cost(0);
        assert(cost.steel.low == 48 & cost.quartz.low == 24, 'wrong formula');
        let cost = Mines::quartz_mine_cost(1);
        assert(cost.steel.low == 96 & cost.quartz.low == 48, 'wrong formula');
        let cost = Mines::quartz_mine_cost(4);
        assert(cost.steel.low == 768 & cost.quartz.low == 384, 'wrong formula');
        let cost = Mines::quartz_mine_cost(10);
        assert(cost.steel.low == 49152 & cost.quartz.low == 24576, 'wrong formula');
        let cost = Mines::quartz_mine_cost(20);
        assert(cost.steel.low == 50331648 & cost.quartz.low == 25165824, 'wrong formula');
        let cost = Mines::quartz_mine_cost(30);
        assert(cost.steel.low == 51539607552 & cost.quartz.low == 25769803776, 'wrong formula');
        let cost = Mines::quartz_mine_cost(63);
        // Max level before overflow.
        assert(
            cost.steel.low == 442721857769029238784 & cost.quartz.low == 221360928884514619392,
            'wrong formula'
        );
    }
    #[test]
    #[available_gas(1000000000)]
    fn tritium_mine_cost_test() {
        let cost = Mines::tritium_mine_cost(0);
        assert(cost.steel.low == 225 & cost.quartz.low == 75, 'wrong formula');
        let cost = Mines::tritium_mine_cost(1);
        assert(cost.steel.low == 450 & cost.quartz.low == 150, 'wrong formula');
        let cost = Mines::tritium_mine_cost(4);
        assert(cost.steel.low == 3600 & cost.quartz.low == 1200, 'wrong formula');
        let cost = Mines::tritium_mine_cost(10);
        assert(cost.steel.low == 230400 & cost.quartz.low == 76800, 'wrong formula');
        let cost = Mines::tritium_mine_cost(20);
        assert(cost.steel.low == 235929600 & cost.quartz.low == 78643200, 'wrong formula');
        let cost = Mines::tritium_mine_cost(30);
        assert(cost.steel.low == 241591910400 & cost.quartz.low == 80530636800, 'wrong formula');
        // Max level before overflow.
        let cost = Mines::tritium_mine_cost(63);
        assert(
            cost.steel.low == 2075258708292324556800 & cost.quartz.low == 691752902764108185600,
            'wrong formula'
        );
    }
    #[test]
    #[available_gas(1000000000)]
    fn solar_plant_cost_test() {
        let cost = Mines::solar_plant_cost(0);
        assert(cost.steel.low == 75 & cost.quartz.low == 30, 'wrong formula');
        let cost = Mines::solar_plant_cost(1);
        assert(cost.steel.low == 150 & cost.quartz.low == 60, 'wrong formula');
        let cost = Mines::solar_plant_cost(4);
        assert(cost.steel.low == 1200 & cost.quartz.low == 480, 'wrong formula');
        let cost = Mines::solar_plant_cost(10);
        assert(cost.steel.low == 76800 & cost.quartz.low == 30720, 'wrong formula');
        let cost = Mines::solar_plant_cost(20);
        assert(cost.steel.low == 78643200 & cost.quartz.low == 31457280, 'wrong formula');
        let cost = Mines::solar_plant_cost(31);
        assert(cost.steel.low == 161061273600 & cost.quartz.low == 64424509440, 'wrong formula');
        // Max level before overflow.
        let cost = Mines::solar_plant_cost(63);
        assert(
            cost.steel.low == 691752902764108185600 & cost.quartz.low == 276701161105643274240,
            'wrong formula'
        );
    }
}

