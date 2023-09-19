use traits::Into;
use nogame::compounds::Compounds;

#[test]
#[available_gas(1000000000)]
fn base_consumption_test() {
    let consumption = Compounds::base_mine_consumption(0);
    assert(consumption == 0, 'wrong result');
    let consumption = Compounds::base_mine_consumption(1);
    assert(consumption == 11, 'wrong result');
    let consumption = Compounds::base_mine_consumption(5);
    assert(consumption == 80, 'wrong result');
    let consumption = Compounds::base_mine_consumption(10);
    assert(consumption == 259, 'wrong result');
    let consumption = Compounds::base_mine_consumption(20);
    assert(consumption == 1345, 'wrong result');
    let consumption = Compounds::base_mine_consumption(31);
    assert(consumption == 5950, 'wrong result');
    let consumption = Compounds::base_mine_consumption(60);
    assert(consumption == 182688, 'wrong result');
}
#[test]
#[available_gas(1000000000)]
fn tritium_consumption_test() {
    let consumption = Compounds::tritium_mine_consumption(0);
    assert(consumption == 0, 'wrong result');
    let consumption = Compounds::tritium_mine_consumption(1);
    assert(consumption == 22, 'wrong result');
    let consumption = Compounds::tritium_mine_consumption(5);
    assert(consumption == 161, 'wrong result');
    let consumption = Compounds::tritium_mine_consumption(10);
    assert(consumption == 518, 'wrong result');
    let consumption = Compounds::tritium_mine_consumption(20);
    assert(consumption == 2690, 'wrong result');
    let consumption = Compounds::tritium_mine_consumption(31);
    assert(consumption == 11900, 'wrong result');
    let consumption = Compounds::tritium_mine_consumption(61);
    assert(consumption == 408614, 'wrong result');
}

