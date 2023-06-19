use core::integer::U256Mul;

use nogame::game::library::CostExtended;
use nogame::math::library::pow;

fn dockyard_cost(current_level: u128) -> CostExtended {
    let base_steel = 400;
    let base_quartz = 200;
    let base_tritium = 100;
    if current_level == 0 {
        CostExtended { steel: base_steel, quartz: base_quartz, tritium: base_tritium }
    } else {
        let multiplier = u256 { low: pow(2, current_level), high: 0 };
        CostExtended {
            steel: base_steel * multiplier,
            quartz: base_quartz * multiplier,
            tritium: base_tritium * multiplier
        }
    }
}

fn lab_cost(current_level: u128) -> CostExtended {
    let base_steel = 200;
    let base_quartz = 400;
    let base_tritium = 200;
    if current_level == 0 {
        CostExtended { steel: base_steel, quartz: base_quartz, tritium: base_tritium }
    } else {
        let multiplier = u256 { low: pow(2, current_level), high: 0 };
        CostExtended {
            steel: base_steel * multiplier,
            quartz: base_quartz * multiplier,
            tritium: base_tritium * multiplier
        }
    }
}

