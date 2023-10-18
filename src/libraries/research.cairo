use nogame::libraries::math::power;
use nogame::libraries::types::{ERC20s, TechLevels};

#[generate_trait]
impl Lab of LabTrait {
    #[inline(always)]
    fn get_tech_cost(current_level: u8, steel: u128, quartz: u128, tritium: u128) -> ERC20s {
        if current_level == 0 {
            ERC20s { steel: steel, quartz: quartz, tritium: tritium }
        } else {
            ERC20s {
                steel: (steel * power(2, current_level.into())),
                quartz: (quartz * power(2, current_level.into())),
                tritium: (tritium * power(2, current_level.into()))
            }
        }
    }

    #[inline(always)]
    fn energy_innovation_requirements_check(lab_level: u8, techs: TechLevels) {
        assert(lab_level >= 1, 'Lab 1 required');
    }

    #[inline(always)]
    fn digital_systems_requirements_check(lab_level: u8, techs: TechLevels) {
        assert(lab_level >= 1, 'Lab 1 required');
    }

    #[inline(always)]
    fn beam_technology_requirements_check(lab_level: u8, techs: TechLevels) {
        assert(lab_level >= 1, 'Lab level 1 required');
        assert(techs.energy >= 2, 'Energy innovation 2 required');
    }

    #[inline(always)]
    fn armour_innovation_requirements_check(lab_level: u8, techs: TechLevels) {
        assert(lab_level >= 2, 'Lab 2 required');
    }

    #[inline(always)]
    fn ion_systems_requirements_check(lab_level: u8, techs: TechLevels) {
        assert(lab_level >= 4, 'Lab 4 required');
        assert(techs.energy >= 4, 'Energy innovation 4 required');
        assert(techs.beam >= 5, 'Beam tech 5 required');
    }

    #[inline(always)]
    fn plasma_engineering_requirements_check(lab_level: u8, techs: TechLevels) {
        assert(lab_level >= 4, 'Lab 4 required');
        assert(techs.energy >= 8, 'Energy innovation 8 required');
        assert(techs.beam >= 10, 'Beam tech 10 required');
        assert(techs.ion >= 5, 'ion systems 5 required');
    }

    #[inline(always)]
    fn stellar_physics_requirements_check(lab_level: u8, techs: TechLevels) {
        assert(lab_level >= 3, 'Lab 7 required');
        assert(techs.energy >= 5, 'Energy innovation 5 required');
        assert(techs.thrust >= 3, 'Thrust prop tech 3 required');
    }

    #[inline(always)]
    fn weapons_development_requirements_check(lab_level: u8, techs: TechLevels) {
        assert(lab_level >= 4, 'Lab 4 required');
    }

    #[inline(always)]
    fn shield_tech_requirements_check(lab_level: u8, techs: TechLevels) {
        assert(lab_level >= 6, 'Lab 6 required');
        assert(techs.energy >= 3, 'Energy innovation 3 required')
    }

    #[inline(always)]
    fn spacetime_warp_requirements_check(lab_level: u8, techs: TechLevels) {
        assert(lab_level >= 7, 'Lab 7 required');
        assert(techs.energy >= 5, 'Energy innovation 5 required');
        assert(techs.shield >= 5, 'Shield tech 5 required');
    }

    #[inline(always)]
    fn combustive_engine_requirements_check(lab_level: u8, techs: TechLevels) {
        assert(lab_level >= 1, 'Lab 1 required');
        assert(techs.energy >= 1, 'Energy innovation 1 required')
    }

    #[inline(always)]
    fn thrust_propulsion_requirements_check(lab_level: u8, techs: TechLevels) {
        assert(lab_level >= 2, 'Lab 2 required');
        assert(techs.energy >= 1, 'Energy innovation 1 required')
    }

    #[inline(always)]
    fn warp_drive_requirements_check(lab_level: u8, techs: TechLevels) {
        assert(lab_level >= 7, 'Lab 7 required');
        assert(techs.energy >= 5, 'Energy innovation 5 required');
        assert(techs.spacetime >= 3, 'Spacetime Warp 3 required');
    }
}

