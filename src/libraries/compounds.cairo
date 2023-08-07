use core::integer::U256Mul;
use core::traits::Into;
use integer::U128Div;

use nogame::game::library::Cost;
use nogame::libraries::math::power;


#[generate_trait]
impl Compounds of CompoundsTrait {
    #[inline(always)]
    fn steel_mine_cost(current_level: u128) -> Cost {
        let base_steel = 60;
        let base_quarz = 15;
        if current_level == 0 {
            Cost { steel: base_steel, quartz: base_quarz, tritium: 0,  }
        } else {
            let steel = base_steel * (power(2, current_level));
            let quartz = base_quarz * (power(2, current_level));
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
            let steel = base_steel * (power(2, current_level));
            let quartz = base_quarz * (power(2, current_level));
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
            let steel = base_steel * (power(2, current_level));
            let quartz = base_quarz * (power(2, current_level));
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
            let steel = base_steel * (power(2, current_level));
            let quartz = base_quarz * (power(2, current_level));
            Cost { steel: steel, quartz: quartz, tritium: 0,  }
        }
    }

    #[inline(always)]
    fn dockyard_cost(current_level: u128) -> Cost {
        let base_steel = 400;
        let base_quartz = 200;
        let base_tritium = 100;
        if current_level == 0 {
            Cost { steel: base_steel, quartz: base_quartz, tritium: base_tritium }
        } else {
            Cost {
                steel: base_steel * power(2, current_level).into(),
                quartz: base_quartz * power(2, current_level).into(),
                tritium: base_tritium * power(2, current_level).into()
            }
        }
    }

    #[inline(always)]
    fn lab_cost(current_level: u128) -> Cost {
        let base_steel = 200;
        let base_quartz = 400;
        let base_tritium = 200;
        if current_level == 0 {
            Cost { steel: base_steel, quartz: base_quartz, tritium: base_tritium }
        } else {
            Cost {
                steel: base_steel * power(2, current_level).into(),
                quartz: base_quartz * power(2, current_level).into(),
                tritium: base_tritium * power(2, current_level).into()
            }
        }
    }

    #[inline(always)]
    fn steel_production(current_level: u128) -> u128 {
        if current_level == 0 {
            return 0;
        } else if current_level <= 31 {
            return U128Div::div(
                30 * current_level * power(11, current_level), power(10, current_level)
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
                20 * current_level * power(11, current_level), power(10, current_level)
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
                10 * current_level * power(11, current_level), power(10, current_level)
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
            U128Div::div(20 * current_level * power(11, current_level), power(10, current_level))
        } else {
            return power(49, current_level);
        }
    }

    #[inline(always)]
    fn base_mine_consumption(current_level: u128) -> u128 {
        if current_level == 0 {
            0
        } else if current_level <= 31 {
            U128Div::div(10 * current_level * power(11, current_level), power(10, current_level))
        } else {
            return power(49, current_level) / 2;
        }
    }

    #[inline(always)]
    fn tritium_mine_consumption(current_level: u128) -> u128 {
        if current_level == 0 {
            0
        } else if current_level <= 31 {
            U128Div::div(20 * current_level * power(11, current_level), power(10, current_level))
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

