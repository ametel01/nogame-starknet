use nogame::libraries::types::{ERC20s, TechLevels};

#[generate_trait]
impl Defences of DefencesTrait {
    fn get_defences_cost(quantity: u32, _steel: u128, _quartz: u128, _tritium: u128) -> ERC20s {
        ERC20s {
            steel: _steel * quantity.into(),
            quartz: _quartz * quantity.into(),
            tritium: _tritium * quantity.into()
        }
    }

    #[inline(always)]
    fn blaster_requirements_check(dockyard_level: u8, techs: TechLevels) {
        assert(dockyard_level >= 1, 'Dockyard 1 required');
    }

    #[inline(always)]
    fn beam_requirements_check(dockyard_level: u8, techs: TechLevels) {
        assert(dockyard_level >= 2, 'Dockyard 2 required');
        assert(techs.energy >= 2, 'Energy Innovation 2 required');
        assert(techs.beam >= 3, 'Beam Technology 3 required');
    }

    #[inline(always)]
    fn astral_launcher_requirements_check(dockyard_level: u8, techs: TechLevels) {
        assert(dockyard_level >= 6, 'Dockyard 6 required');
        assert(techs.energy >= 6, 'Energy Innovation 6 required');
        assert(techs.weapons >= 3, 'Armour Innovation 3 required');
        assert(techs.shield >= 1, 'Shield Tech 1 required')
    }

    #[inline(always)]
    fn plasma_beam_requirements_check(dockyard_level: u8, techs: TechLevels) {
        assert(dockyard_level >= 8, 'Dockyard 8 required');
        assert(techs.plasma >= 7, 'Plasma Engineering 7 required');
    }
}

