use nogame::libraries::types::{DefencesCost, ERC20s, TechLevels};

fn get_defences_cost(quantity: u32, base_cost: ERC20s) -> ERC20s {
    ERC20s {
        steel: base_cost.steel * quantity.into(),
        quartz: base_cost.quartz * quantity.into(),
        tritium: base_cost.tritium * quantity.into(),
    }
}

fn get_defences_unit_cost() -> DefencesCost {
    DefencesCost {
        celestia: ERC20s { steel: 0, quartz: 2000, tritium: 500 },
        blaster: ERC20s { steel: 2000, quartz: 0, tritium: 0 },
        beam: ERC20s { steel: 6000, quartz: 2000, tritium: 0 },
        astral: ERC20s { steel: 20000, quartz: 15000, tritium: 2000 },
        plasma: ERC20s { steel: 50000, quartz: 50000, tritium: 30000 },
    }
}

mod requirements {
    use nogame::libraries::types::TechLevels;

    fn celestia(dockyard_level: u8, techs: TechLevels) {
        assert!(dockyard_level >= 1_u8, "Defence:E_DOCKYARD_LEVEL");
        assert!(techs.combustion >= 1_u8, "Defence:E_COMBUSTION_LEVEL");
    }


    fn blaster(dockyard_level: u8, techs: TechLevels) {
        assert!(dockyard_level >= 1_u8, "Defence:E_DOCKYARD_LEVEL");
    }

    fn beam(dockyard_level: u8, techs: TechLevels) {
        assert!(dockyard_level >= 4_u8, "Defence:E_DOCKYARD_LEVEL");
        assert!(techs.energy >= 3_u8, "Defence:E_ENERGY_LEVEL");
        assert!(techs.beam >= 6_u8, "Defence:E_BEAM_LEVEL");
    }

    fn astral(dockyard_level: u8, techs: TechLevels) {
        assert!(dockyard_level >= 6_u8, "Defence:E_DOCKYARD_LEVEL");
        assert!(techs.energy >= 6_u8, "Defence:E_ENERGY_LEVEL");
        assert!(techs.weapons >= 3_u8, "Defence:E_WEAPONS_LEVEL");
        assert!(techs.shield >= 1_u8, "Defence:E_SHIELD_LEVEL");
    }

    fn plasma(dockyard_level: u8, techs: TechLevels) {
        assert!(dockyard_level >= 8_u8, "Defence:E_DOCKYARD_LEVEL");
        assert!(techs.plasma >= 7_u8, "Defence:E_PLASMA_LEVEL");
    }
}
