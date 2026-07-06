use nogame::libraries::types::ERC20s;

const U128_MAX: u128 = 340282366920938463463374607431768211455;

#[test]
fn test_erc20s_adds_all_resource_components() {
    let lhs = ERC20s { steel: 7, quartz: 11, tritium: 13 };
    let rhs = ERC20s { steel: 3, quartz: 5, tritium: 8 };

    assert(lhs + rhs == ERC20s { steel: 10, quartz: 16, tritium: 21 }, 'wrong erc20s add');
}

#[test]
fn test_erc20s_subtracts_all_resource_components() {
    let lhs = ERC20s { steel: 10, quartz: 16, tritium: 21 };
    let rhs = ERC20s { steel: 3, quartz: 5, tritium: 8 };

    assert(lhs - rhs == ERC20s { steel: 7, quartz: 11, tritium: 13 }, 'wrong erc20s sub');
}

#[test]
#[should_panic]
fn test_erc20s_add_panics_on_component_overflow() {
    ERC20s { steel: U128_MAX, quartz: 0, tritium: 0 } + ERC20s { steel: 1, quartz: 0, tritium: 0 };
}

#[test]
#[should_panic]
fn test_erc20s_sub_panics_on_component_underflow() {
    ERC20s { steel: 0, quartz: 0, tritium: 0 } - ERC20s { steel: 1, quartz: 0, tritium: 0 };
}
