use nogame::libraries::math::BitShift;

#[test]
fn test_power() {
    assert(BitShift::fpow(10_000_000_u128, 3) == 1_000_000_000_000_000_000_000, 'wrong assert #1');
    assert(BitShift::fpow(20_000_000_u128, 3) == 8_000_000_000_000_000_000_000, 'wrong assert #2');
    assert(
        BitShift::fpow(123_456_789_u128, 3) == 1_881_676_371_789_154_860_897_069, 'wrong assert #2'
    );
}
