use core::integer::U256Mul;
use core::traits::Into;

use nogame::game::library::CostExtended;
use nogame::libraries::math::pow;


#[generate_trait]
impl Compounds of CompoundsTrait {
    #[inline(always)]
    fn dockyard_cost(current_level: u128) -> CostExtended {
        let base_steel = 400;
        let base_quartz = 200;
        let base_tritium = 100;
        if current_level == 0 {
            CostExtended { steel: base_steel, quartz: base_quartz, tritium: base_tritium }
        } else {
            CostExtended {
                steel: base_steel * pow(2, current_level).into(),
                quartz: base_quartz * pow(2, current_level).into(),
                tritium: base_tritium * pow(2, current_level).into()
            }
        }
    }

    #[inline(always)]
    fn lab_cost(current_level: u128) -> CostExtended {
        let base_steel = 200;
        let base_quartz = 400;
        let base_tritium = 200;
        if current_level == 0 {
            CostExtended { steel: base_steel, quartz: base_quartz, tritium: base_tritium }
        } else {
            CostExtended {
                steel: base_steel * pow(2, current_level).into(),
                quartz: base_quartz * pow(2, current_level).into(),
                tritium: base_tritium * pow(2, current_level).into()
            }
        }
    }
}

