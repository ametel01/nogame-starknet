use nogame::libraries::math::power;
use nogame::game::library::{ERC20s, TechLevels};

#[generate_trait]
impl Lab of LabTrait {
    fn get_tech_cost(current_level: u128, steel: u128, quartz: u128, tritium: u128) -> ERC20s {
        if current_level == 0 {
            ERC20s { steel: steel, quartz: quartz, tritium: tritium }
        } else {
            ERC20s {
                steel: (steel * power(2, current_level)),
                quartz: (quartz * power(2, current_level)),
                tritium: (tritium * power(2, current_level))
            }
        }
    }

    fn energy_innovation_requirements_check(lab_level: u128, techs: TechLevels) {
        assert(lab_level >= 1, 'Lab 1 required');
    }

    fn digital_systems_requirements_check(lab_level: u128, techs: TechLevels) {
        assert(lab_level >= 1, 'Lab 1 required');
    }

    fn beam_technology_requirements_check(lab_level: u128, techs: TechLevels) {
        assert(lab_level >= 1, 'Lab level 1 required');
        assert(techs.energy_innovation == 2, 'Energy innovation 2 required')
    }

    fn armour_innovation_requirements_check(lab_level: u128, techs: TechLevels) {
        assert(lab_level >= 2, 'Lab 2 required');
    }

    fn ion_systems_requirements_check(lab_level: u128, techs: TechLevels) {
        assert(lab_level == 4, 'Lab 4 required');
        assert(techs.beam_technology >= 5, 'Beam tech 5 required');
        assert(techs.energy_innovation >= 4, 'Energy innovation 4 required')
    }

    fn plasma_engineering_requirements_check(lab_level: u128, techs: TechLevels) {
        assert(lab_level == 4, 'Lab 4 required');
        assert(techs.beam_technology >= 10, 'Beam tech 10 required');
        assert(techs.energy_innovation >= 8, 'Energy innovation 8 required');
        assert(techs.spacetime_warp >= 5, 'Spacetime warp 5 required');
    }

    fn stellar_physics_requirements_check(lab_level: u128, techs: TechLevels) {
        assert(lab_level == 3, 'Lab 7 required');
        assert(techs.thrust_propulsion >= 3, 'Thrust prop tech 3 required');
        assert(techs.energy_innovation >= 5, 'Energy innovation 5 required');
    }

    fn arms_development_requirements_check(lab_level: u128, techs: TechLevels) {
        assert(lab_level == 4, 'Lab 4 required');
    }

    fn shield_tech_requirements_check(lab_level: u128, techs: TechLevels) {
        assert(lab_level == 6, 'Lab 6 required');
        assert(techs.energy_innovation >= 3, 'Energy innovation 3 required')
    }

    fn spacetime_warp_requirements_check(lab_level: u128, techs: TechLevels) {
        assert(lab_level == 7, 'Lab 7 required');
        assert(techs.shield_tech >= 5, 'Shield tech 5 required');
        assert(techs.energy_innovation >= 5, 'Energy innovation 5 required')
    }

    fn combustive_engine_requirements_check(lab_level: u128, techs: TechLevels) {
        assert(lab_level == 1, 'Lab 1 required');
        assert(techs.energy_innovation >= 1, 'Energy innovation 1 required')
    }

    fn thrust_propulsion_requirements_check(lab_level: u128, techs: TechLevels) {
        assert(lab_level == 2, 'Lab 2 required');
        assert(techs.energy_innovation >= 1, 'Energy innovation 1 required')
    }

    fn warp_drive_requirements_check(lab_level: u128, techs: TechLevels) {
        assert(lab_level == 7, 'Lab 7 required');
        assert(techs.energy_innovation >= 5, 'Energy innovation 5 required');
        assert(techs.spacetime_warp >= 3, 'Spacetime Warp 3 required');
    }
}

