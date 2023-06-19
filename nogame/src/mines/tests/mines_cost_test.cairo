#[cfg(test)]
mod MineCostTest {
    use debug::PrintTrait;
    use nogame::mines::library::Mines;

    #[test]
    #[available_gas(1000000000)]
    fn steel_mine_cost_test() {
        let (steel, quartz) = Mines::steel_mine_cost(0);
        assert(steel.low == 60 & quartz.low == 15, 'wrong formula');
        let (steel, quartz) = Mines::steel_mine_cost(1);
        assert(steel.low == 120 & quartz.low == 30, 'wrong formula');
        let (steel, quartz) = Mines::steel_mine_cost(4);
        assert(steel.low == 960 & quartz.low == 240, 'wrong formula');
        let (steel, quartz) = Mines::steel_mine_cost(10);
        assert(steel.low == 61440 & quartz.low == 15360, 'wrong formula');
        let (steel, quartz) = Mines::steel_mine_cost(20);
        assert(steel.low == 62914560 & quartz.low == 15728640, 'wrong formula');
        let (steel, quartz) = Mines::steel_mine_cost(30);
        assert(steel.low == 64424509440 & quartz.low == 16106127360, 'wrong formula');
        let (steel, quartz) = Mines::steel_mine_cost(63);
        // Max level before overflow.
        assert(
            steel.low == 553402322211286548480 & quartz.low == 138350580552821637120,
            'wrong formula'
        );
    }
    #[test]
    #[available_gas(1000000000)]
    fn quartz_mine_cost_test() {
        let (steel, quartz) = Mines::quartz_mine_cost(0);
        assert(steel.low == 48 & quartz.low == 24, 'wrong formula');
        let (steel, quartz) = Mines::quartz_mine_cost(1);
        assert(steel.low == 96 & quartz.low == 48, 'wrong formula');
        let (steel, quartz) = Mines::quartz_mine_cost(4);
        assert(steel.low == 768 & quartz.low == 384, 'wrong formula');
        let (steel, quartz) = Mines::quartz_mine_cost(10);
        assert(steel.low == 49152 & quartz.low == 24576, 'wrong formula');
        let (steel, quartz) = Mines::quartz_mine_cost(20);
        assert(steel.low == 50331648 & quartz.low == 25165824, 'wrong formula');
        let (steel, quartz) = Mines::quartz_mine_cost(30);
        assert(steel.low == 51539607552 & quartz.low == 25769803776, 'wrong formula');
        let (steel, quartz) = Mines::quartz_mine_cost(63);
        // Max level before overflow.
        assert(
            steel.low == 442721857769029238784 & quartz.low == 221360928884514619392,
            'wrong formula'
        );
    }
    #[test]
    #[available_gas(1000000000)]
    fn tritium_mine_cost_test() {
        let (steel, quartz) = Mines::tritium_mine_cost(0);
        assert(steel.low == 225 & quartz.low == 75, 'wrong formula');
        let (steel, quartz) = Mines::tritium_mine_cost(1);
        assert(steel.low == 450 & quartz.low == 150, 'wrong formula');
        let (steel, quartz) = Mines::tritium_mine_cost(4);
        assert(steel.low == 3600 & quartz.low == 1200, 'wrong formula');
        let (steel, quartz) = Mines::tritium_mine_cost(10);
        assert(steel.low == 230400 & quartz.low == 76800, 'wrong formula');
        let (steel, quartz) = Mines::tritium_mine_cost(20);
        assert(steel.low == 235929600 & quartz.low == 78643200, 'wrong formula');
        let (steel, quartz) = Mines::tritium_mine_cost(30);
        assert(steel.low == 241591910400 & quartz.low == 80530636800, 'wrong formula');
        // Max level before overflow.
        let (steel, quartz) = Mines::tritium_mine_cost(63);
        assert(
            steel.low == 2075258708292324556800 & quartz.low == 691752902764108185600,
            'wrong formula'
        );
    }
    #[test]
    #[available_gas(1000000000)]
    fn solar_plant_cost_test() {
        let (steel, quartz) = Mines::solar_plant_cost(0);
        assert(steel.low == 75 & quartz.low == 30, 'wrong formula');
        let (steel, quartz) = Mines::solar_plant_cost(1);
        assert(steel.low == 150 & quartz.low == 60, 'wrong formula');
        let (steel, quartz) = Mines::solar_plant_cost(4);
        assert(steel.low == 1200 & quartz.low == 480, 'wrong formula');
        let (steel, quartz) = Mines::solar_plant_cost(10);
        assert(steel.low == 76800 & quartz.low == 30720, 'wrong formula');
        let (steel, quartz) = Mines::solar_plant_cost(20);
        assert(steel.low == 78643200 & quartz.low == 31457280, 'wrong formula');
        let (steel, quartz) = Mines::solar_plant_cost(31);
        assert(steel.low == 161061273600 & quartz.low == 64424509440, 'wrong formula');
        // Max level before overflow.
        let (steel, quartz) = Mines::solar_plant_cost(63);
        assert(
            steel.low == 691752902764108185600 & quartz.low == 276701161105643274240,
            'wrong formula'
        );
    }
}

