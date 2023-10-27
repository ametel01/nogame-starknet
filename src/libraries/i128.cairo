use serde::Serde;
use core::integer::i128;

/// Converts the given unsigned integer to a signed integer.
/// # Arguments
/// * `a` - first number.
/// * `b` - second number.
/// # Return
/// The signed integer.
fn to_signed(a: u128, is_positive: bool) -> i128 {
    let a_felt: felt252 = a.into();
    let a_signed = a_felt.try_into().expect('i128 Overflow');
    if is_positive {
        a_signed
    } else {
        -a_signed
    }
}
// impl I128Serde of Serde<i128> {
//     fn serialize(self: @i128, ref output: Array<felt252>) {
//         output.append((*self).into());
//     }
//     fn deserialize(ref serialized: Span<felt252>) -> Option<i128> {
//         let felt_val = *(serialized.pop_front().expect('i128 deserialize'));
//         let i128_val = felt_val.try_into().expect('i128 Overflow');
//         Option::Some(i128_val)
//     }
// }


