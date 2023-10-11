use snforge_std::io::PrintTrait;

use nogame::libraries::math::BitShift;

#[test]
fn test_power() {
    BitShift::fpow(10000000000_u128, 3).print();
}
