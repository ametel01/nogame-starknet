use core::traits::AddEq;
use traits::Into;
use debug::PrintTrait;
// use traits::{Into, TryInto};
use option::OptionTrait;
use integer::U128Div;
use nogame::game::library::Cost;
use nogame::libraries::math::{pow, power};

const MAX_STEEL_OVERFLOW: u128 = 17850;
const MAX_QUARZ_OVERFLOW: u128 = 11900;
const MAX_TRITIUM_OVERFLOW: u128 = 5950;


#[generate_trait]
impl Mines of MinesTrait {
    #[inline(always)]
    fn steel_mine_cost(current_level: u128) -> Cost {
        let base_steel = 60;
        let base_quarz = 15;
        if current_level == 0 {
            Cost { steel: base_steel, quartz: base_quarz, tritium: 0,  }
        } else {
            let steel = base_steel * (pow(2, current_level));
            let quartz = base_quarz * (pow(2, current_level));
            Cost { steel: steel, quartz: quartz, tritium: 0 }
        }
    }

    #[inline(always)]
    fn quartz_mine_cost(current_level: u128) -> Cost {
        let base_steel = 48;
        let base_quarz = 24;
        if current_level == 0 {
            Cost { steel: base_steel, quartz: base_quarz, tritium: 0,  }
        } else {
            let steel = base_steel * (pow(2, current_level));
            let quartz = base_quarz * (pow(2, current_level));
            Cost { steel: steel, quartz: quartz, tritium: 0,  }
        }
    }

    #[inline(always)]
    fn tritium_mine_cost(current_level: u128) -> Cost {
        let base_steel = 225;
        let base_quarz = 75;
        if current_level == 0 {
            Cost { steel: base_steel, quartz: base_quarz, tritium: 0,  }
        } else {
            let steel = base_steel * (pow(2, current_level));
            let quartz = base_quarz * (pow(2, current_level));
            Cost { steel: steel, quartz: quartz, tritium: 0,  }
        }
    }

    #[inline(always)]
    fn energy_plant_cost(current_level: u128) -> Cost {
        let base_steel = 75;
        let base_quarz = 30;
        if current_level == 0 {
            Cost { steel: base_steel, quartz: base_quarz, tritium: 0,  }
        } else {
            let steel = base_steel * (pow(2, current_level));
            let quartz = base_quarz * (pow(2, current_level));
            Cost { steel: steel, quartz: quartz, tritium: 0,  }
        }
    }

    #[inline(always)]
    fn steel_production(current_level: u128) -> u128 {
        if current_level == 0 {
            return 0;
        } else if current_level <= 31 {
            return U128Div::div(
                30 * current_level * pow(11, current_level), pow(10, current_level)
            );
        } else {
            return power(70, current_level);
        }
    }

    #[inline(always)]
    fn quartz_production(current_level: u128) -> u128 {
        if current_level == 0 {
            return 0;
        } else if current_level <= 31 {
            return U128Div::div(
                20 * current_level * pow(11, current_level), pow(10, current_level)
            );
        } else {
            return power(49, current_level);
        }
    }

    #[inline(always)]
    fn tritium_production(current_level: u128) -> u128 {
        if current_level == 0 {
            return 0;
        } else if current_level <= 31 {
            return U128Div::div(
                10 * current_level * pow(11, current_level), pow(10, current_level)
            );
        } else {
            return power(24, current_level);
        }
    }

    #[inline(always)]
    fn energy_plant_production(current_level: u128) -> u128 {
        if current_level == 0 {
            0
        } else if current_level <= 31 {
            U128Div::div(20 * current_level * pow(11, current_level), pow(10, current_level))
        } else {
            return power(49, current_level);
        }
    }

    #[inline(always)]
    fn base_mine_consumption(current_level: u128) -> u128 {
        if current_level == 0 {
            0
        } else if current_level <= 31 {
            U128Div::div(10 * current_level * pow(11, current_level), pow(10, current_level))
        } else {
            return power(49, current_level) / 2;
        }
    }

    #[inline(always)]
    fn tritium_mine_consumption(current_level: u128) -> u128 {
        if current_level == 0 {
            0
        } else if current_level <= 31 {
            U128Div::div(20 * current_level * pow(11, current_level), pow(10, current_level))
        } else {
            return power(49, current_level);
        }
    }

    #[inline(always)]
    fn production_scaler(production: u128, available: u128, required: u128) -> u128 {
        if available > required {
            return production;
        } else {
            return ((((available * 100) / required) * production) / 100);
        }
    }
}

