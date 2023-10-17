use cubit::f128::types::fixed::{Fixed, FixedTrait, ONE_u128 as ONE};
use nogame::libraries::auction::{LinearVRGDA, LinearVRGDATrait};

use snforge_std::io::PrintTrait;

const _0_31: u128 = 5718490662849961000;
const _0_10: u128 = 3689348814741911000;
const PRICE: u128 = 221360928884514600;
const PRECISION: u128 = 1_000_000_000_000_000_000;

#[test]
fn test_auction_price_increasing() {
    let auction = LinearVRGDA {
        target_price: FixedTrait::new(PRICE, false),
        decay_constant: FixedTrait::new(_0_10, true),
        per_time_unit: FixedTrait::new_unscaled(10, false),
    };
    (auction.get_vrgda_price(FixedTrait::ZERO(), FixedTrait::ZERO()).mag * PRECISION / ONE).print();
    (auction.get_vrgda_price(FixedTrait::ZERO(), FixedTrait::new_unscaled(11, false)).mag
        * PRECISION
        / ONE)
        .print();
    (auction.get_vrgda_price(FixedTrait::ZERO(), FixedTrait::new_unscaled(20, false)).mag
        * PRECISION
        / ONE)
        .print();
    (auction.get_vrgda_price(FixedTrait::ZERO(), FixedTrait::new_unscaled(30, false)).mag
        * PRECISION
        / ONE)
        .print();
    (auction.get_vrgda_price(FixedTrait::ZERO(), FixedTrait::new_unscaled(40, false)).mag
        * PRECISION
        / ONE)
        .print();
    (auction.get_vrgda_price(FixedTrait::ZERO(), FixedTrait::new_unscaled(50, false)).mag
        * PRECISION
        / ONE)
        .print();
    (auction.get_vrgda_price(FixedTrait::ZERO(), FixedTrait::new_unscaled(200, false)).mag
        * PRECISION
        / ONE)
        .print();
}

#[test]
fn test_auction_price_decreasing() {
    let auction = LinearVRGDA {
        target_price: FixedTrait::new(PRICE, false),
        decay_constant: FixedTrait::new(_0_10, true),
        per_time_unit: FixedTrait::new_unscaled(10, false),
    };
    (auction.get_vrgda_price(FixedTrait::ZERO(), FixedTrait::ZERO()).mag * PRECISION / ONE).print();
    (auction.get_vrgda_price(FixedTrait::new_unscaled(1, false), FixedTrait::ZERO()).mag
        * PRECISION
        / ONE)
        .print();
    (auction.get_vrgda_price(FixedTrait::new_unscaled(2, false), FixedTrait::ZERO()).mag
        * PRECISION
        / ONE)
        .print();
    (auction.get_vrgda_price(FixedTrait::new_unscaled(3, false), FixedTrait::ZERO()).mag
        * PRECISION
        / ONE)
        .print();
    (auction.get_vrgda_price(FixedTrait::new_unscaled(4, false), FixedTrait::ZERO()).mag
        * PRECISION
        / ONE)
        .print();
    (auction.get_vrgda_price(FixedTrait::new_unscaled(5, false), FixedTrait::ZERO()).mag
        * PRECISION
        / ONE)
        .print();
    (auction.get_vrgda_price(FixedTrait::new_unscaled(6, false), FixedTrait::ZERO()).mag
        * PRECISION
        / ONE)
        .print();
}
