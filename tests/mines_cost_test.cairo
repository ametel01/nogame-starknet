use debug::PrintTrait;
use nogame::libraries::compounds::Compounds;
use nogame::libraries::types::ERC20s;

impl CostPrint of PrintTrait<ERC20s> {
    fn print(self: ERC20s) {
        self.steel.print();
        self.quartz.print();
        self.tritium.print();
    }
}

#[test]
fn steel_mine_cost_test() {
    let cost = Compounds::steel_mine_cost(0);
    assert(cost.steel == 60, 'wrong formula');
    assert(cost.quartz == 15, 'wrong formula');
    let cost = Compounds::steel_mine_cost(1);
    assert(cost.steel == 90, 'wrong formula');
    assert(cost.quartz == 22, 'wrong formula');
    let cost = Compounds::steel_mine_cost(4);
    assert(cost.steel == 303, 'wrong formula');
    assert(cost.quartz == 75, 'wrong formula');
    let cost = Compounds::steel_mine_cost(10);
    assert(cost.steel == 3459, 'wrong formula');
    assert(cost.quartz == 864, 'wrong formula');
    let cost = Compounds::steel_mine_cost(20);
    assert(cost.steel == 199515, 'wrong formula');
    assert(cost.quartz == 49878, 'wrong formula');
    let cost = Compounds::steel_mine_cost(30);
    assert(cost.steel == 11505063, 'wrong formula');
    let cost = Compounds::steel_mine_cost(63);
    assert(cost.steel == 7445614915178, 'wrong formula');
    assert(cost.quartz == 1861403728794, 'wrong formula');
}
#[test]
fn quartz_mine_cost_test() {
    let cost = Compounds::quartz_mine_cost(0);
    assert(cost.steel == 48, 'wrong formula');
    assert(cost.quartz == 24, 'wrong formula');
    let cost = Compounds::quartz_mine_cost(1);
    assert(cost.steel == 76, 'wrong formula');
    assert(cost.quartz == 38, 'wrong formula');
    let cost = Compounds::quartz_mine_cost(4);
    assert(cost.steel == 314, 'wrong formula');
    assert(cost.quartz == 157, 'wrong formula');
    let cost = Compounds::quartz_mine_cost(10);
    assert(cost.steel == 5277, 'wrong formula');
    assert(cost.quartz == 2638, 'wrong formula');
    let cost = Compounds::quartz_mine_cost(20);
    assert(cost.steel == 580284, 'wrong formula');
    assert(cost.quartz == 290142, 'wrong formula');
    let cost = Compounds::quartz_mine_cost(30);
    assert(cost.steel == 63802943, 'wrong formula');
    assert(cost.quartz == 31901471, 'wrong formula');
    let cost = Compounds::quartz_mine_cost(31);
    assert(cost.steel == 102084710, 'wrong formula');
    assert(cost.quartz == 51042355, 'wrong formula');
}
#[test]
fn tritium_mine_cost_test() {
    let cost = Compounds::tritium_mine_cost(0);
    assert(cost.steel == 225, 'wrong formula');
    assert(cost.quartz == 75, 'wrong formula');
    let cost = Compounds::tritium_mine_cost(1);
    assert(cost.steel == 337, 'wrong formula');
    assert(cost.quartz == 112, 'wrong formula');
    let cost = Compounds::tritium_mine_cost(4);
    assert(cost.steel == 1139, 'wrong formula');
    assert(cost.quartz == 379, 'wrong formula');
    let cost = Compounds::tritium_mine_cost(10);
    assert(cost.steel == 12974, 'wrong formula');
    assert(cost.quartz == 4324, 'wrong formula');
    let cost = Compounds::tritium_mine_cost(20);
    assert(cost.steel == 748182, 'wrong formula');
    assert(cost.quartz == 249394, 'wrong formula');
    let cost = Compounds::tritium_mine_cost(30);
    assert(cost.steel == 43143988, 'wrong formula');
    assert(cost.quartz == 14381329, 'wrong formula');
    let cost = Compounds::tritium_mine_cost(63);
    assert(cost.steel == 27921055931921, 'wrong formula');
    assert(cost.quartz == 9307018643973, 'wrong formula');
}
#[test]
fn solar_plant_cost_test() {
    let cost = Compounds::energy_plant_cost(0);
    assert(cost.steel == 75, 'wrong formula');
    assert(cost.quartz == 30, 'wrong formula');
    let cost = Compounds::energy_plant_cost(1);
    assert(cost.steel == 112, 'wrong formula');
    assert(cost.quartz == 45, 'wrong formula');
    let cost = Compounds::energy_plant_cost(4);
    assert(cost.steel == 379, 'wrong formula');
    assert(cost.quartz == 151, 'wrong formula');
    let cost = Compounds::energy_plant_cost(10);
    assert(cost.steel == 4324, 'wrong formula');
    assert(cost.quartz == 1729, 'wrong formula');
    let cost = Compounds::energy_plant_cost(20);
    assert(cost.steel == 249394, 'wrong formula');
    assert(cost.quartz == 99757, 'wrong formula');
    let cost = Compounds::energy_plant_cost(31);
    assert(cost.steel == 21571994, 'wrong formula');
    assert(cost.quartz == 8628797, 'wrong formula');
    let cost = Compounds::energy_plant_cost(63);
    assert(cost.steel == 9307018643973, 'wrong formula');
    assert(cost.quartz == 3722807457589, 'wrong formula');
}

