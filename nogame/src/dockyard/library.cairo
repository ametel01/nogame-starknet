use core::traits::Into;
use nogame::game::library::{CostExtended, Techs};

#[generate_trait]
impl Dockyard of DockyardTrait {
    fn get_ships_cost(quantity: u128, _steel: u128, _quartz: u128, _tritium: u128) -> CostExtended {
        CostExtended {
            steel: (_steel * quantity).into(),
            quartz: (_quartz * quantity).into(),
            tritium: (_tritium * quantity).into()
        }
    }

    fn carrier_requirements_check(dockyard_level: u128, techs: Techs) {
        assert(dockyard_level >= 2, 'Dockyard 2 required');
        assert(techs.combustive_engine >= 2, 'Combustive engine 2 required');
    }

    fn scraper_requirements_check(dockyard_level: u128, techs: Techs) {
        assert(dockyard_level >= 4, 'Dockyard 4 required');
        assert(techs.combustive_engine >= 6, 'Combustive engine 6 required');
        assert(techs.shield_tech >= 2, 'Shield tech 2 required');
    }

    fn celestia_requirements_check(dockyard_level: u128, techs: Techs) {
        assert(dockyard_level >= 1, 'Dockyard 1 required');
        assert(techs.combustive_engine >= 1, 'Combustive engine 1 required');
    }

    fn sparrow_requirements_check(dockyard_level: u128, techs: Techs) {
        assert(dockyard_level >= 1, 'Dockyard 1 required');
    }

    fn frigate_requirements_check(dockyard_level: u128, techs: Techs) {
        assert(dockyard_level >= 5, 'Dockyard 5 required');
        assert(techs.ion_systems >= 2, 'Ion Systems 2 required');
        assert(techs.thrust_propulsion >= 4, 'Thrust Propulsion 4 required');
    }

    fn armade_requirements_check(dockyard_level: u128, techs: Techs) {
        assert(dockyard_level >= 7, 'Dockyard 7 required');
        assert(techs.warp_drive >= 4, 'Warp Drive 4 required');
    }
}
