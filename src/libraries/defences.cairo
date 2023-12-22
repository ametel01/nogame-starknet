use nogame::libraries::types::{ERC20s, TechLevels};

#[generate_trait]
impl Defences of DefencesTrait {
    fn get_defences_cost(quantity: u32, base_cost: ERC20s) -> ERC20s {
        ERC20s {
            steel: base_cost.steel * quantity.into(),
            quartz: base_cost.quartz * quantity.into(),
            tritium: base_cost.tritium * quantity.into()
        }
    }

    #[inline(always)]
    fn blaster_requirements_check(dockyard_level: u8, techs: TechLevels) {
        assert(dockyard_level >= 1, 'dockyard 1 required');
    }

    #[inline(always)]
    fn beam_requirements_check(dockyard_level: u8, techs: TechLevels) {
        assert(dockyard_level >= 2, 'dockyard 2 required');
        assert(techs.energy >= 2, 'energy innovation 2 required');
        assert(techs.beam >= 3, 'beam technology 3 required');
    }

    #[inline(always)]
    fn astral_launcher_requirements_check(dockyard_level: u8, techs: TechLevels) {
        assert(dockyard_level >= 6, 'dockyard 6 required');
        assert(techs.energy >= 6, 'energy innovation 6 required');
        assert(techs.weapons >= 3, 'weapons tech 3 required');
        assert(techs.shield >= 1, 'shield tech 1 required')
    }

    #[inline(always)]
    fn plasma_beam_requirements_check(dockyard_level: u8, techs: TechLevels) {
        assert(dockyard_level >= 8, 'dockyard 8 required');
        assert(techs.plasma >= 7, 'plasma engineering 7 required');
    }
}

