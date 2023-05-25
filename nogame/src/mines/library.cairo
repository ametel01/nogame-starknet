use debug::PrintTrait;
use traits::{Into, TryInto};
use option::OptionTrait;
use integer::U128Div;

const MAX_STEEL_OVERFLOW: u128 = 17850;
const MAX_QUARZ_OVERFLOW: u128 = 11900;
const MAX_TRITIUM_OVERFLOW: u128 = 5950;

fn steel_mine_cost(current_level: u128) -> (u256, u256) {
    let base_steel = 60;
    let base_quarz = 15;
    if current_level == 0 {
        (u256 { low: base_steel, high: 0 }, u256 { low: base_quarz, high: 0 })
    } else {
        let steel = base_steel * (pow(2, current_level));
        let quarz = base_quarz * (pow(2, current_level));
        (u256 { low: steel, high: 0 }, u256 { low: quarz, high: 0 })
    }
}

fn quarz_mine_cost(current_level: u128) -> (u256, u256) {
    let base_steel = 48;
    let base_quarz = 24;
    if current_level == 0 {
        (u256 { low: base_steel, high: 0 }, u256 { low: base_quarz, high: 0 })
    } else {
        let steel = base_steel * (pow(2, current_level));
        let quarz = base_quarz * (pow(2, current_level));
        (u256 { low: steel, high: 0 }, u256 { low: quarz, high: 0 })
    }
}

fn tritium_mine_cost(current_level: u128) -> (u256, u256) {
    let base_steel = 225;
    let base_quarz = 75;
    if current_level == 0 {
        (u256 { low: base_steel, high: 0 }, u256 { low: base_quarz, high: 0 })
    } else {
        let steel = base_steel * (pow(2, current_level));
        let quarz = base_quarz * (pow(2, current_level));
        (u256 { low: steel, high: 0 }, u256 { low: quarz, high: 0 })
    }
}

fn steel_production(current_level: u128) -> u256 {
    if current_level == 0 {
        u256 { low: 30, high: 0 }
    } else if current_level <= 31 {
        let production = U128Div::div(
            30 * current_level * pow(11, current_level), pow(10, current_level)
        );
        u256 { low: production, high: 0 }
    } else {
        let production = MAX_STEEL_OVERFLOW * (current_level - 31);
        u256 { low: production, high: 0 }
    }
}

fn quarz_production(current_level: u128) -> u256 {
    if current_level == 0 {
        u256 { low: 22, high: 0 }
    } else if current_level <= 31 {
        let production = U128Div::div(
            20 * current_level * pow(11, current_level), pow(10, current_level)
        );
        u256 { low: production, high: 0 }
    } else {
        let production = MAX_QUARZ_OVERFLOW * (current_level - 31);
        u256 { low: production, high: 0 }
    }
}

fn tritium_production(current_level: u128) -> u256 {
    if current_level == 0 {
        u256 { low: 0, high: 0 }
    } else if current_level <= 31 {
        let production = U128Div::div(
            10 * current_level * pow(11, current_level), pow(10, current_level)
        );
        u256 { low: production, high: 0 }
    } else {
        let production = MAX_TRITIUM_OVERFLOW * (current_level - 31);
        u256 { low: production, high: 0 }
    }
}

fn pow(mut base: u128, mut power: u128) -> u128 {
    // Return invalid input error
    if base == 0 {
        panic_with_felt252('II')
    }

    let mut result = 1;
    loop {
        if power == 0 {
            break result;
        }

        if power % 2 != 0 {
            result = (result * base);
        }
        base = (base * base);
        power = power / 2;
    }
}

