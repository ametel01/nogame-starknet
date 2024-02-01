use debug::PrintTrait;
use nogame::compound::library as compound;
use nogame::libraries::types::ERC20s;

#[test]
fn steel_mine_cost_test() {
    let cost = compound::cost::steel(0, 1);
    assert(cost.steel == 60, 'wrong 1');
    assert(cost.quartz == 15, 'wrong 1');
    let cost = compound::cost::steel(1, 1);
    assert(cost.steel == 90, 'wrong 2');
    assert(cost.quartz == 22, 'wrong 2');
    let cost = compound::cost::steel(4, 1);
    assert(cost.steel == 303, 'wrong 3');
    assert(cost.quartz == 75, 'wrong 3');
    let cost = compound::cost::steel(10, 1);
    assert(cost.steel == 3459, 'wrong 4');
    assert(cost.quartz == 864, 'wrong 4');
    let cost = compound::cost::steel(20, 1);
    assert(cost.steel == 199515, 'wrong 5');
    assert(cost.quartz == 49878, 'wrong 5');
    let cost = compound::cost::steel(30, 1);
    assert(cost.steel == 11505063, 'wrong 6');
    assert(cost.quartz == 2876265, 'wrong 6');
    let cost = compound::cost::steel(59, 1);
    assert(cost.steel == 1470738748677, 'wrong 7');
    assert(cost.quartz == 367684687169, 'wrong 7');
}

#[test]
fn quartz_cost_test() {
    let cost = compound::cost::quartz(0, 1);
    assert(cost.steel == 48, 'wrong formula');
    assert(cost.quartz == 24, 'wrong formula');
    let cost = compound::cost::quartz(1, 1);
    assert(cost.steel == 76, 'wrong formula');
    assert(cost.quartz == 38, 'wrong formula');
    let cost = compound::cost::quartz(4, 1);
    assert(cost.steel == 314, 'wrong formula');
    assert(cost.quartz == 157, 'wrong formula');
    let cost = compound::cost::quartz(10, 1);
    assert(cost.steel == 5277, 'wrong formula');
    assert(cost.quartz == 2638, 'wrong formula');
    let cost = compound::cost::quartz(20, 1);
    assert(cost.steel == 580284, 'wrong formula');
    assert(cost.quartz == 290142, 'wrong formula');
    let cost = compound::cost::quartz(30, 1);
    assert(cost.steel == 63802943, 'wrong formula');
    assert(cost.quartz == 31901471, 'wrong formula');
    let cost = compound::cost::quartz(31, 1);
    assert(cost.steel == 102084710, 'wrong formula');
    assert(cost.quartz == 51042355, 'wrong formula');
}

#[test]
fn tritium_cost_test() {
    let cost = compound::cost::tritium(0, 1);
    assert(cost.steel == 225, 'wrong formula');
    assert(cost.quartz == 75, 'wrong formula');
    let cost = compound::cost::tritium(1, 1);
    assert(cost.steel == 337, 'wrong formula');
    assert(cost.quartz == 112, 'wrong formula');
    let cost = compound::cost::tritium(4, 1);
    assert(cost.steel == 1139, 'wrong formula');
    assert(cost.quartz == 379, 'wrong formula');
    let cost = compound::cost::tritium(10, 1);
    assert(cost.steel == 12974, 'wrong formula');
    assert(cost.quartz == 4324, 'wrong formula');
    let cost = compound::cost::tritium(20, 1);
    assert(cost.steel == 748182, 'wrong formula');
    assert(cost.quartz == 249394, 'wrong formula');
    let cost = compound::cost::tritium(30, 1);
    assert(cost.steel == 43143988, 'wrong formula');
    assert(cost.quartz == 14381329, 'wrong formula');
    let cost = compound::cost::tritium(63, 1);
    assert(cost.steel == 27921055931921, 'wrong formula');
    assert(cost.quartz == 9307018643973, 'wrong formula');
}

#[test]
fn solar_plant_cost_test() {
    let cost = compound::cost::energy(0, 1);
    assert(cost.steel == 75, 'wrong formula');
    assert(cost.quartz == 30, 'wrong formula');
    let cost = compound::cost::energy(1, 1);
    assert(cost.steel == 112, 'wrong formula');
    assert(cost.quartz == 45, 'wrong formula');
    let cost = compound::cost::energy(4, 1);
    assert(cost.steel == 379, 'wrong formula');
    assert(cost.quartz == 151, 'wrong formula');
    let cost = compound::cost::energy(10, 1);
    assert(cost.steel == 4324, 'wrong formula');
    assert(cost.quartz == 1729, 'wrong formula');
    let cost = compound::cost::energy(20, 1);
    assert(cost.steel == 249394, 'wrong formula');
    assert(cost.quartz == 99757, 'wrong formula');
    let cost = compound::cost::energy(31, 1);
    assert(cost.steel == 21571994, 'wrong formula');
    assert(cost.quartz == 8628797, 'wrong formula');
    let cost = compound::cost::energy(63, 1);
    assert(cost.steel == 9307018643973, 'wrong formula');
    assert(cost.quartz == 3722807457589, 'wrong formula');
}

#[test]
fn dockyard_cost_test() {
    let cost = compound::cost::dockyard(0, 1);
    assert(cost.steel == 400, 'wrong formula');
    assert(cost.quartz == 200, 'wrong formula');
    assert(cost.tritium == 100, 'wrong formula');
    let cost = compound::cost::dockyard(1, 1);
    assert(cost.steel == 800, 'wrong formula');
    assert(cost.quartz == 400, 'wrong formula');
    assert(cost.tritium == 200, 'wrong formula');
    let cost = compound::cost::dockyard(5, 1);
    assert(cost.steel == 12800, 'wrong formula');
    assert(cost.quartz == 6400, 'wrong formula');
    assert(cost.tritium == 3200, 'wrong formula');
    let cost = compound::cost::dockyard(10, 1);
    assert(cost.steel == 409600, 'wrong formula');
    assert(cost.quartz == 204800, 'wrong formula');
    assert(cost.tritium == 102400, 'wrong formula');
    let cost = compound::cost::dockyard(30, 1);
    assert(cost.steel == 429496729600, 'wrong formula');
    assert(cost.quartz == 214748364800, 'wrong formula');
    assert(cost.tritium == 107374182400, 'wrong formula');
}
#[test]
fn lab_cost_test() {
    let cost = compound::cost::lab(0, 1);
    assert(cost.steel == 200, 'wrong formula 1');
    assert(cost.quartz == 400, 'wrong formula');
    assert(cost.tritium == 200, 'wrong formula');
    let cost = compound::cost::lab(1, 1);
    assert(cost.steel == 400, 'wrong formula 2');
    assert(cost.quartz == 800, 'wrong formula');
    assert(cost.tritium == 400, 'wrong formula');
    let cost = compound::cost::lab(5, 1);
    assert(cost.steel == 6400, 'wrong formula 3');
    assert(cost.quartz == 12800, 'wrong formula');
    assert(cost.tritium == 6400, 'wrong formula');
    let cost = compound::cost::lab(10, 1);
    assert(cost.steel == 204800, 'wrong formula 4');
    assert(cost.quartz == 409600, 'wrong formula');
    assert(cost.tritium == 204800, 'wrong formula');
    let cost = compound::cost::lab(20, 1);
    assert(cost.steel == 209715200, 'wrong formula 5');
    assert(cost.quartz == 419430400, 'wrong formula');
    assert(cost.tritium == 209715200, 'wrong formula');
    let cost = compound::cost::lab(30, 1);
    assert(cost.steel == 214748364800, 'wrong formula 6');
    assert(cost.quartz == 429496729600, 'wrong formula');
    assert(cost.tritium == 214748364800, 'wrong formula');
}

#[test]
fn test_compounds_multilevel_cost() {
    compound::cost::lab(8, 3);
}

