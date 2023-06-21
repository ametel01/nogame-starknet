use core::traits::AddEq;
use debug::PrintTrait;
use traits::{Into, TryInto};
use option::OptionTrait;
use integer::U128Div;
use nogame::game::library::CostExtended;
use nogame::math::library::pow;

const MAX_STEEL_OVERFLOW: u128 = 17850;
const MAX_QUARZ_OVERFLOW: u128 = 11900;
const MAX_TRITIUM_OVERFLOW: u128 = 5950;


#[generate_trait]
impl Mines of MinesTrait {
    fn steel_mine_cost(current_level: u128) -> CostExtended {
        let base_steel = 60;
        let base_quarz = 15;
        if current_level == 0 {
            CostExtended {
                steel: base_steel.into(), quartz: base_quarz.into(), tritium: 0.into(), 
            }
        } else {
            let steel = base_steel * (pow(2, current_level));
            let quartz = base_quarz * (pow(2, current_level));
            CostExtended { steel: steel.into(), quartz: quartz.into(), tritium: 0.into() }
        }
    }

    fn quartz_mine_cost(current_level: u128) -> CostExtended {
        let base_steel = 48;
        let base_quarz = 24;
        if current_level == 0 {
            CostExtended {
                steel: base_steel.into(), quartz: base_quarz.into(), tritium: 0.into(), 
            }
        } else {
            let steel = base_steel * (pow(2, current_level));
            let quartz = base_quarz * (pow(2, current_level));
            CostExtended { steel: steel.into(), quartz: quartz.into(), tritium: 0.into(),  }
        }
    }

    fn tritium_mine_cost(current_level: u128) -> CostExtended {
        let base_steel = 225;
        let base_quarz = 75;
        if current_level == 0 {
            CostExtended {
                steel: base_steel.into(), quartz: base_quarz.into(), tritium: 0.into(), 
            }
        } else {
            let steel = base_steel * (pow(2, current_level));
            let quartz = base_quarz * (pow(2, current_level));
            CostExtended { steel: steel.into(), quartz: quartz.into(), tritium: 0.into(),  }
        }
    }

    fn energy_plant_cost(current_level: u128) -> CostExtended {
        let base_steel = 75;
        let base_quarz = 30;
        if current_level == 0 {
            CostExtended {
                steel: base_steel.into(), quartz: base_quarz.into(), tritium: 0.into(), 
            }
        } else {
            let steel = base_steel * (pow(2, current_level));
            let quartz = base_quarz * (pow(2, current_level));
            CostExtended { steel: steel.into(), quartz: quartz.into(), tritium: 0.into(),  }
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
            u256 { low: production / 3600, high: 0 }
        }
    }

    fn quartz_production(current_level: u128) -> u256 {
        if current_level == 0 {
            u256 { low: 22, high: 0 }
        } else if current_level <= 31 {
            let production = U128Div::div(
                20 * current_level * pow(11, current_level), pow(10, current_level)
            );
            u256 { low: production, high: 0 }
        } else {
            let production = MAX_QUARZ_OVERFLOW * (current_level - 31);
            u256 { low: production / 3600, high: 0 }
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
            u256 { low: production / 3600, high: 0 }
        }
    }

    fn solar_plant_production(current_level: u128) -> u128 {
        if current_level == 0 {
            0
        } else if current_level <= 31 {
            U128Div::div(20 * current_level * pow(11, current_level), pow(10, current_level))
        } else {
            MAX_QUARZ_OVERFLOW * (current_level - 31)
        }
    }

    fn base_mine_consumption(current_level: u128) -> u128 {
        if current_level == 0 {
            0
        } else if current_level <= 31 {
            U128Div::div(10 * current_level * pow(11, current_level), pow(10, current_level))
        } else {
            MAX_TRITIUM_OVERFLOW * (current_level - 31)
        }
    }

    fn tritium_mine_consumption(current_level: u128) -> u128 {
        if current_level == 0 {
            0
        } else if current_level <= 31 {
            U128Div::div(20 * current_level * pow(11, current_level), pow(10, current_level))
        } else {
            MAX_QUARZ_OVERFLOW * (current_level - 31)
        }
    }
}

