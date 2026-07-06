use nogame::compound::library as compound;
use nogame::libraries::types::{CompoundsLevels, ERC20s, HOUR, PlanetPosition};

fn calculate_resource_production(
    mines_levels: CompoundsLevels,
    position: PlanetPosition,
    celestia_count: u32,
    uni_speed: u128,
    time_elapsed: u64,
) -> ERC20s {
    let temp = compound::calculate_avg_temperature(position.orbit);
    let steel_available = compound::production::steel(mines_levels.steel)
        * uni_speed
        * time_elapsed.into()
        / HOUR.into();

    let quartz_available = compound::production::quartz(mines_levels.quartz)
        * uni_speed
        * time_elapsed.into()
        / HOUR.into();

    let tritium_available = compound::production::tritium(mines_levels.tritium, temp, uni_speed)
        * time_elapsed.into()
        / HOUR.into();

    let celestia_production: u128 = compound::position_to_celestia_production(position.orbit)
        .into();
    let total_energy = compound::production::energy(mines_levels.energy)
        + celestia_count.into() * celestia_production;
    let energy_required = compound::consumption::base(mines_levels.steel)
        + compound::consumption::base(mines_levels.quartz)
        + compound::consumption::base(mines_levels.tritium);

    if total_energy < energy_required {
        return ERC20s {
            steel: compound::production_scaler(steel_available, total_energy, energy_required),
            quartz: compound::production_scaler(quartz_available, total_energy, energy_required),
            tritium: compound::production_scaler(tritium_available, total_energy, energy_required),
        };
    }

    ERC20s { steel: steel_available, quartz: quartz_available, tritium: tritium_available }
}
