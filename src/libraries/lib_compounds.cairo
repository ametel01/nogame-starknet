use core::integer::U256Mul;
use core::traits::Into;
use integer::U128Div;

use nogame::game::game_library::ERC20s;
use nogame::libraries::lib_math::{power, BitShift};


#[generate_trait]
impl Compounds of CompoundsTrait {
    #[inline(always)]
    fn steel_mine_cost(current_level: u128) -> ERC20s {
        if current_level == 0 {
            return ERC20s { steel: 60, quartz: 15, tritium: 0 };
        }
        let base_steel: u256 = 60;
        let base_quartz: u256 = 15;
        let steel: u128 = (base_steel
            * BitShift::fpow(15.into(), current_level.into())
            / BitShift::fpow(10.into(), current_level.into()))
            .low;
        let quartz: u128 = (base_quartz
            * BitShift::fpow(15.into(), current_level.into())
            / BitShift::fpow(10.into(), current_level.into()))
            .low;

        ERC20s { steel: steel, quartz: quartz, tritium: 0 }
    }

    #[inline(always)]
    fn quartz_mine_cost(current_level: u128) -> ERC20s {
        if current_level == 0 {
            return ERC20s { steel: 48, quartz: 24, tritium: 0 };
        }
        let base_steel: u256 = 48;
        let base_quartz: u256 = 24;
        let steel = (base_steel
            * BitShift::fpow(16.into(), current_level.into())
            / BitShift::fpow(10.into(), current_level.into()))
            .low;
        let quartz = (base_quartz
            * BitShift::fpow(16.into(), current_level.into())
            / BitShift::fpow(10.into(), current_level.into()))
            .low;

        ERC20s { steel: steel, quartz: quartz, tritium: 0 }
    }

    #[inline(always)]
    fn tritium_mine_cost(current_level: u128) -> ERC20s {
        if current_level == 0 {
            return ERC20s { steel: 225, quartz: 75, tritium: 0 };
        }
        let base_steel: u256 = 225;
        let base_quartz: u256 = 75;
        let steel = (base_steel
            * BitShift::fpow(15.into(), current_level.into())
            / BitShift::fpow(10.into(), current_level.into()))
            .low;
        let quartz = (base_quartz
            * BitShift::fpow(15.into(), current_level.into())
            / BitShift::fpow(10.into(), current_level.into()))
            .low;

        ERC20s { steel: steel, quartz: quartz, tritium: 0 }
    }

    #[inline(always)]
    fn energy_plant_cost(current_level: u128) -> ERC20s {
        if current_level == 0 {
            return ERC20s { steel: 75, quartz: 30, tritium: 0 };
        }
        let base_steel: u256 = 75;
        let base_quartz: u256 = 30;
        let steel = (base_steel
            * BitShift::fpow(15.into(), current_level.into())
            / BitShift::fpow(10.into(), current_level.into()))
            .low;
        let quartz = (base_quartz
            * BitShift::fpow(15.into(), current_level.into())
            / BitShift::fpow(10.into(), current_level.into()))
            .low;

        ERC20s { steel: steel, quartz: quartz, tritium: 0 }
    }

    #[inline(always)]
    fn dockyard_cost(current_level: u128) -> ERC20s {
        ERC20s {
            steel: 400 * BitShift::fpow(2, current_level).into(),
            quartz: 200 * BitShift::fpow(2, current_level).into(),
            tritium: 100 * BitShift::fpow(2, current_level).into()
        }
    }

    #[inline(always)]
    fn lab_cost(current_level: u128) -> ERC20s {
        let base_steel = 200;
        let base_quartz = 400;
        let base_tritium = 200;
        if current_level == 0 {
            ERC20s { steel: base_steel, quartz: base_quartz, tritium: base_tritium }
        } else {
            ERC20s {
                steel: base_steel * BitShift::fpow(2, current_level).into(),
                quartz: base_quartz * BitShift::fpow(2, current_level).into(),
                tritium: base_tritium * BitShift::fpow(2, current_level).into()
            }
        }
    }

    #[inline(always)]
    fn steel_production(current_level: u128) -> u128 {
        if current_level == 0 {
            return 10;
        }
        let base: u256 = 30;
        (base
            * current_level.into()
            * BitShift::fpow(11.into(), current_level.into())
            / BitShift::fpow(10.into(), current_level.into()))
            .low
    }

    #[inline(always)]
    fn quartz_production(current_level: u128) -> u128 {
        if current_level == 0 {
            return 10;
        }
        let base: u256 = 20;
        (base
            * current_level.into()
            * BitShift::fpow(11.into(), current_level.into())
            / BitShift::fpow(10.into(), current_level.into()))
            .low
    }

    #[inline(always)]
    fn tritium_production(current_level: u128) -> u128 {
        let base: u256 = 10;
        (base
            * current_level.into()
            * BitShift::fpow(11.into(), current_level.into())
            / BitShift::fpow(10.into(), current_level.into()))
            .low
    }

    #[inline(always)]
    fn energy_plant_production(current_level: u128) -> u128 {
        let base: u256 = 20;
        (base
            * current_level.into()
            * BitShift::fpow(11.into(), current_level.into())
            / BitShift::fpow(10.into(), current_level.into()))
            .low
    }

    #[inline(always)]
    fn base_mine_consumption(current_level: u128) -> u128 {
        let base: u256 = 10;
        (base
            * current_level.into()
            * BitShift::fpow(11.into(), current_level.into())
            / BitShift::fpow(10.into(), current_level.into()))
            .low
    }

    #[inline(always)]
    fn tritium_mine_consumption(current_level: u128) -> u128 {
        let base: u256 = 20;
        (base
            * current_level.into()
            * BitShift::fpow(11.into(), current_level.into())
            / BitShift::fpow(10.into(), current_level.into()))
            .low
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

