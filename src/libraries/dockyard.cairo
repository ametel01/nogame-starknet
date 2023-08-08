use core::traits::Into;
use nogame::game::library::{ERC20s, TechLevels};

#[generate_trait]
impl Dockyard of DockyardTrait {
    fn get_ships_cost(quantity: u128, cost: ERC20s) -> ERC20s {
        ERC20s {
            steel: (cost.steel * quantity),
            quartz: (cost.quartz * quantity),
            tritium: (cost.tritium * quantity)
        }
    }

    #[inline(always)]
    fn carrier_requirements_check(dockyard_level: u128, techs: TechLevels) {
        assert(dockyard_level >= 2, 'Dockyard 2 required');
        assert(techs.combustion_drive >= 2, 'Combustive Engine 2 required');
    }

    #[inline(always)]
    fn scraper_requirements_check(dockyard_level: u128, techs: TechLevels) {
        assert(dockyard_level >= 4, 'Dockyard 4 required');
        assert(techs.combustion_drive >= 6, 'Combustive Engine 6 required');
        assert(techs.shield_tech >= 2, 'Shield Tech 2 required');
    }

    #[inline(always)]
    fn celestia_requirements_check(dockyard_level: u128, techs: TechLevels) {
        assert(dockyard_level >= 1, 'Dockyard 1 required');
        assert(techs.combustion_drive >= 1, 'Combustive Engine 1 required');
    }

    #[inline(always)]
    fn sparrow_requirements_check(dockyard_level: u128, techs: TechLevels) {
        assert(dockyard_level >= 1, 'Dockyard 1 required');
    }

    #[inline(always)]
    fn frigate_requirements_check(dockyard_level: u128, techs: TechLevels) {
        assert(dockyard_level >= 5, 'Dockyard 5 required');
        assert(techs.ion_systems >= 2, 'Ion Systems 2 required');
        assert(techs.thrust_propulsion >= 4, 'Thrust Propulsion 4 required');
    }

    #[inline(always)]
    fn armade_requirements_check(dockyard_level: u128, techs: TechLevels) {
        assert(dockyard_level >= 7, 'Dockyard 7 required');
        assert(techs.warp_drive >= 4, 'Warp Drive 4 required');
    }
}
