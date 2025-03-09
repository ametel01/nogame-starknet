use nogame::libraries::auction::{LinearVRGDA, LinearVRGDATrait};
use nogame_fixed::f128::types::{Fixed, FixedTrait, ONE_u128 as ONE};

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

    assert(
        auction.get_vrgda_price(FixedTrait::ZERO(), FixedTrait::ZERO()).mag
            * PRECISION
            / ONE == 11999999999999998,
        'wrong assert # 1',
    );

    assert(
        auction.get_vrgda_price(FixedTrait::ZERO(), FixedTrait::new_unscaled(11, false)).mag
            * PRECISION
            / ONE == 14952920766475353,
        'wrong assert # 2',
    );

    assert(
        auction.get_vrgda_price(FixedTrait::ZERO(), FixedTrait::new_unscaled(20, false)).mag
            * PRECISION
            / ONE == 17901896371284823,
        'wrong assert # 3',
    );

    assert(
        auction.get_vrgda_price(FixedTrait::ZERO(), FixedTrait::new_unscaled(30, false)).mag
            * PRECISION
            / ONE == 21865425604302498,
        'wrong assert # 4',
    );

    assert(
        auction.get_vrgda_price(FixedTrait::ZERO(), FixedTrait::new_unscaled(40, false)).mag
            * PRECISION
            / ONE == 26706491141297844,
        'wrong assert # 5',
    );

    assert(
        auction.get_vrgda_price(FixedTrait::ZERO(), FixedTrait::new_unscaled(50, false)).mag
            * PRECISION
            / ONE == 32619381940644807,
        'wrong assert # 6',
    );

    assert(
        auction.get_vrgda_price(FixedTrait::ZERO(), FixedTrait::new_unscaled(200, false)).mag
            * PRECISION
            / ONE == 655177800382777271,
        'wrong assert # 7',
    );
}

#[test]
fn test_auction_price_decreasing() {
    let auction = LinearVRGDA {
        target_price: FixedTrait::new(PRICE, false),
        decay_constant: FixedTrait::new(_0_10, true),
        per_time_unit: FixedTrait::new_unscaled(10, false),
    };

    assert(
        auction.get_vrgda_price(FixedTrait::ZERO(), FixedTrait::ZERO()).mag
            * PRECISION
            / ONE == 11999999999999998,
        'wrong assert # 1',
    );

    assert(
        auction.get_vrgda_price(FixedTrait::new_unscaled(1, false), FixedTrait::ZERO()).mag
            * PRECISION
            / ONE == 9824769037297713,
        'wrong assert # 2',
    );

    assert(
        auction.get_vrgda_price(FixedTrait::new_unscaled(2, false), FixedTrait::ZERO()).mag
            * PRECISION
            / ONE == 8043840552612083,
        'wrong assert # 3',
    );

    assert(
        auction.get_vrgda_price(FixedTrait::new_unscaled(3, false), FixedTrait::ZERO()).mag
            * PRECISION
            / ONE == 6585739633243856,
        'wrong assert # 4',
    );

    assert(
        auction.get_vrgda_price(FixedTrait::new_unscaled(4, false), FixedTrait::ZERO()).mag
            * PRECISION
            / ONE == 5391947569530171,
        'wrong assert # 5',
    );

    assert(
        auction.get_vrgda_price(FixedTrait::new_unscaled(5, false), FixedTrait::ZERO()).mag
            * PRECISION
            / ONE == 4414553294174200,
        'wrong assert # 6',
    );
    (
        auction.get_vrgda_price(FixedTrait::new_unscaled(6, false), FixedTrait::ZERO()).mag
            * PRECISION
            / ONE == 3614330543041306,
        'wrong assert # 7',
    );
}
