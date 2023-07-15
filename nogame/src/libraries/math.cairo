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

fn power(x: u128, y: u128) -> u128 {
    let mut result = x;
    let mut n = 1;
    loop {
        if n == y {
            break;
        }
        result = result * 11 / 10;
        n += 1;
    };
    result * ((100 / 19) * y) / 10 + (700 / 190)
}
