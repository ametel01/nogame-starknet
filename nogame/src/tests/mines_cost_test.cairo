#[cfg(test)]
mod MineCostTest {
    use debug::PrintTrait;
    use nogame::libraries::mines::Mines;
    use nogame::game::library::Cost;

    #[test]
    #[available_gas(1000000000)]
    fn steel_mine_cost_test() {
        let cost = Mines::steel_mine_cost(0);
        assert(cost.steel == 60, 'wrong formula');
        assert(cost.quartz == 15, 'wrong formula');
        let cost = Mines::steel_mine_cost(1);
        assert(cost.steel == 120, 'wrong formula');
        assert(cost.quartz == 30, 'wrong formula');
        let cost = Mines::steel_mine_cost(4);
        assert(cost.steel == 960, 'wrong formula');
        assert(cost.quartz == 240, 'wrong formula');
        let cost = Mines::steel_mine_cost(10);
        assert(cost.steel == 61440, 'wrong formula');
        assert(cost.quartz == 15360, 'wrong formula');
        let cost = Mines::steel_mine_cost(20);
        assert(cost.steel == 62914560, 'wrong formula');
        assert(cost.quartz == 15728640, 'wrong formula');
        let cost = Mines::steel_mine_cost(30);
        assert(cost.steel == 64424509440, 'wrong formula');
        assert(cost.quartz == 16106127360, 'wrong formula');
        let cost = Mines::steel_mine_cost(63);
        assert(cost.steel == 553402322211286548480, 'wrong formula');
        assert(cost.quartz == 138350580552821637120, 'wrong formula');
    }
    #[test]
    #[available_gas(1000000000)]
    fn quartz_mine_cost_test() {
        let cost = Mines::quartz_mine_cost(0);
        assert(cost.steel == 48, 'wrong formula');
        assert(cost.quartz == 24, 'wrong formula');
        let cost = Mines::quartz_mine_cost(1);
        assert(cost.steel == 96, 'wrong formula');
        assert(cost.quartz == 48, 'wrong formula');
        let cost = Mines::quartz_mine_cost(4);
        assert(cost.steel == 768, 'wrong formula');
        assert(cost.quartz == 384, 'wrong formula');
        let cost = Mines::quartz_mine_cost(10);
        assert(cost.steel == 49152, 'wrong formula');
        assert(cost.quartz == 24576, 'wrong formula');
        let cost = Mines::quartz_mine_cost(20);
        assert(cost.steel == 50331648, 'wrong formula');
        assert(cost.quartz == 25165824, 'wrong formula');
        let cost = Mines::quartz_mine_cost(30);
        assert(cost.steel == 51539607552, 'wrong formula');
        assert(cost.quartz == 25769803776, 'wrong formula');
        let cost = Mines::quartz_mine_cost(63);
        // Max level before overflow.
        assert(cost.steel == 442721857769029238784, 'wrong formula');
        assert(cost.quartz == 221360928884514619392, 'wrong formula');
    }
    #[test]
    #[available_gas(1000000000)]
    fn tritium_mine_cost_test() {
        let cost = Mines::tritium_mine_cost(0);
        assert(cost.steel == 225, 'wrong formula');
        assert(cost.quartz == 75, 'wrong formula');
        let cost = Mines::tritium_mine_cost(1);
        assert(cost.steel == 450, 'wrong formula');
        assert(cost.quartz == 150, 'wrong formula');
        let cost = Mines::tritium_mine_cost(4);
        assert(cost.steel == 3600, 'wrong formula');
        assert(cost.quartz == 1200, 'wrong formula');
        let cost = Mines::tritium_mine_cost(10);
        assert(cost.steel == 230400, 'wrong formula');
        assert(cost.quartz == 76800, 'wrong formula');
        let cost = Mines::tritium_mine_cost(20);
        assert(cost.steel == 235929600, 'wrong formula');
        assert(cost.quartz == 78643200, 'wrong formula');
        let cost = Mines::tritium_mine_cost(30);
        assert(cost.steel == 241591910400, 'wrong formula');
        assert(cost.quartz == 80530636800, 'wrong formula');
        // Max level before overflow.
        let cost = Mines::tritium_mine_cost(63);
        assert(cost.steel == 2075258708292324556800, 'wrong formula');
        assert(cost.quartz == 691752902764108185600, 'wrong formula');
    }
    #[test]
    #[available_gas(1000000000)]
    fn solar_plant_cost_test() {
        let cost = Mines::energy_plant_cost(0);
        assert(cost.steel == 75, 'wrong formula');
        assert(cost.quartz == 30, 'wrong formula');
        let cost = Mines::energy_plant_cost(1);
        assert(cost.steel == 150, 'wrong formula');
        assert(cost.quartz == 60, 'wrong formula');
        let cost = Mines::energy_plant_cost(4);
        assert(cost.steel == 1200, 'wrong formula');
        assert(cost.quartz == 480, 'wrong formula');
        let cost = Mines::energy_plant_cost(10);
        assert(cost.steel == 76800, 'wrong formula');
        assert(cost.quartz == 30720, 'wrong formula');
        let cost = Mines::energy_plant_cost(20);
        assert(cost.steel == 78643200, 'wrong formula');
        assert(cost.quartz == 31457280, 'wrong formula');
        let cost = Mines::energy_plant_cost(31);
        assert(cost.steel == 161061273600, 'wrong formula');
        assert(cost.quartz == 64424509440, 'wrong formula');
        // Max level before overflow.
        let cost = Mines::energy_plant_cost(63);
        assert(cost.steel == 691752902764108185600, 'wrong formula');
        assert(cost.quartz == 276701161105643274240, 'wrong formula');
    }
}

