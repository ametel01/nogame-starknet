#[cfg(test)]
mod MineCostTest {
    use nogame::mines::library::{pow, steel_mine_cost, quarz_mine_cost, tritium_mine_cost};

    #[test]
    #[available_gas(1000000000)]
    fn fast_power_test() {
        assert(pow(2, 1) == 2, 'invalid result');
        assert(pow(2, 2) == 4, 'invalid result');
        assert(pow(2, 3) == 8, 'invalid result');
        assert(pow(3, 4) == 81, 'invalid result');
        assert(pow(2, 30) == 1073741824, 'invalid result');
        assert(pow(5, 5) == 3125, 'invalid result');
    }

    #[test]
    #[available_gas(1000000000)]
    fn steel_mine_cost_test() {
        let (steel, quarz) = steel_mine_cost(0);
        assert(steel.low == 60 & quarz.low == 15, 'wrong formula');
        let (steel, quarz) = steel_mine_cost(1);
        assert(steel.low == 90 & quarz.low == 22, 'wrong formula');
        let (steel, quarz) = steel_mine_cost(4);
        assert(steel.low == 303 & quarz.low == 75, 'wrong formula');
        let (steel, quarz) = steel_mine_cost(10);
        assert(steel.low == 3459 & quarz.low == 864, 'wrong formula');
        let (steel, quarz) = steel_mine_cost(20);
        assert(steel.low == 199515 & quarz.low == 49878, 'wrong formula');
        let (steel, quarz) = steel_mine_cost(30);
        assert(steel.low == 11505063 & quarz.low == 2876265, 'wrong formula');
        // Currently the max level before overflow.
        // TODO: add scaling for levels > 32
        let (steel, quarz) = steel_mine_cost(31);
        assert(steel.low == 17257595 & quarz.low == 4314398, 'wrong formula');
    }

    #[test]
    #[available_gas(1000000000)]
    fn quarz_mine_cost_test() {
        let (steel, quarz) = quarz_mine_cost(0);
        assert(steel.low == 48 & quarz.low == 24, 'wrong formula');
        let (steel, quarz) = quarz_mine_cost(1);
        assert(steel.low == 76 & quarz.low == 38, 'wrong formula');
        let (steel, quarz) = quarz_mine_cost(4);
        assert(steel.low == 314 & quarz.low == 157, 'wrong formula');
        let (steel, quarz) = quarz_mine_cost(10);
        assert(steel.low == 5277 & quarz.low == 2638, 'wrong formula');
        // Currently the max level before overflow.
        // TODO: add scaling for levels > 16
        let (steel, quarz) = quarz_mine_cost(15);
        assert(steel.low == 55340 & quarz.low == 27670, 'wrong formula');
    }

    #[test]
    #[available_gas(1000000000)]
    fn tritium_mine_cost_test() {
        let (steel, quarz) = tritium_mine_cost(0);
        assert(steel.low == 225 & quarz.low == 75, 'wrong formula');
        let (steel, quarz) = tritium_mine_cost(1);
        assert(steel.low == 337 & quarz.low == 112, 'wrong formula');
        let (steel, quarz) = tritium_mine_cost(4);
        assert(steel.low == 1139 & quarz.low == 379, 'wrong formula');
        let (steel, quarz) = tritium_mine_cost(10);
        assert(steel.low == 12974 & quarz.low == 4324, 'wrong formula');
        let (steel, quarz) = tritium_mine_cost(15);
        assert(steel.low == 98526 & quarz.low == 32842, 'wrong formula');
        let (steel, quarz) = tritium_mine_cost(20);
        assert(steel.low == 748182 & quarz.low == 249394, 'wrong formula');
        // Currently the max level before overflow.
        // TODO: add scaling for levels > 31
        let (steel, quarz) = tritium_mine_cost(30);
        assert(steel.low == 43143988 & quarz.low == 14381329, 'wrong formula');
    }
}
