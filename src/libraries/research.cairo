use nogame::libraries::math::power;
use nogame::libraries::types::{ERC20s, TechLevels, TechsCost};

#[generate_trait]
impl Lab of LabTrait {
    fn get_tech_cost(current_level: u8, level_to_upgrade: u8, base_cost: ERC20s) -> ERC20s {
        if current_level == 0 {
            ERC20s { steel: base_cost.steel, quartz: base_cost.quartz, tritium: base_cost.tritium }
        } else {
            let mut cost: ERC20s = Default::default();

            let mut i = level_to_upgrade;
            loop {
                if i == current_level {
                    break;
                }

                cost = cost
                    + ERC20s {
                        steel: (base_cost.steel * power(2, i.into())),
                        quartz: (base_cost.quartz * power(2, i.into())),
                        tritium: (base_cost.tritium * power(2, i.into()))
                    };
                i -= 1;
            };
            cost
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

    #[inline(always)]
    fn base_tech_costs() -> TechsCost {
        TechsCost {
            energy: ERC20s { steel: 0, quartz: 800, tritium: 400 },
            digital: ERC20s { steel: 0, quartz: 400, tritium: 600 },
            beam: ERC20s { steel: 0, quartz: 800, tritium: 400 },
            armour: ERC20s { steel: 1000, quartz: 0, tritium: 0 },
            ion: ERC20s { steel: 1000, quartz: 300, tritium: 1000 },
            plasma: ERC20s { steel: 2000, quartz: 4000, tritium: 1000 },
            weapons: ERC20s { steel: 800, quartz: 200, tritium: 0 },
            shield: ERC20s { steel: 200, quartz: 600, tritium: 0 },
            spacetime: ERC20s { steel: 0, quartz: 4000, tritium: 2000 },
            combustion: ERC20s { steel: 400, quartz: 0, tritium: 600 },
            thrust: ERC20s { steel: 2000, quartz: 4000, tritium: 600 },
            warp: ERC20s { steel: 10000, quartz: 2000, tritium: 6000 },
        }
    }
}

