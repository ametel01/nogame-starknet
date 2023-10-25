use snforge_std::PrintTrait;

use nogame::libraries::math::BitShift;

#[test]
fn test_power() {
    BitShift::fpow(10000000_u128, 3).print();
}
