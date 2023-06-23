use core::traits::Into;
use nogame::game::library::{CostExtended, Techs};

#[generate_trait]
impl Defences of DefencesTrait {
    fn get_defences_cost(
        quantity: u128, _steel: u128, _quartz: u128, _tritium: u128
    ) -> CostExtended {
        CostExtended {
            steel: (_steel * quantity).into(),
            quartz: (_quartz * quantity).into(),
            tritium: (_tritium * quantity).into()
        }
    }

    fn blaster_requirements_check(dockyard_level: u128, techs: Techs) {
        assert(dockyard_level >= 1, 'Dockyard 1 required');
    }

    fn beam_requirements_check(dockyard_level: u128, techs: Techs) {
        assert(dockyard_level >= 2, 'Dockyard 1 required');
        assert(techs.energy_innovation >= 2, 'Energy Innovation 2 required');
        assert(techs.beam_technology >= 3, 'Beam Technology 3 required');
    }

    fn astral_launcher_requirements_check(dockyard_level: u128, techs: Techs) {
        assert(dockyard_level >= 6, 'Dockyard 6 required');
        assert(techs.energy_innovation >= 6, 'Energy Innovation 6 required');
        assert(techs.armour_innovation >= 3, 'Armour Innovation 3 required');
        assert(techs.shield_tech >= 1, 'Shield Tech 1 required')
    }

    fn plasma_beam_requirements_check(dockyard_level: u128, techs: Techs) {
        assert(dockyard_level >= 8, 'Dockyard 8 required');
        assert(techs.plasma_engineering >= 7, 'Plasma Engineering 7 required');
    }
}
