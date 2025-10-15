use nogame::libraries::types::{ERC20s, ShipsCost, TechLevels};

fn get_ships_cost(quantity: u32, cost: ERC20s) -> ERC20s {
    ERC20s {
        steel: (cost.steel * quantity.into()),
        quartz: (cost.quartz * quantity.into()),
        tritium: (cost.tritium * quantity.into()),
    }
}

fn get_ships_unit_cost() -> ShipsCost {
    ShipsCost {
        carrier: ERC20s { steel: 2000, quartz: 2000, tritium: 0 },
        celestia: ERC20s { steel: 0, quartz: 2000, tritium: 500 },
        scraper: ERC20s { steel: 10000, quartz: 6000, tritium: 2000 },
        sparrow: ERC20s { steel: 3000, quartz: 1000, tritium: 0 },
        frigate: ERC20s { steel: 20000, quartz: 7000, tritium: 2000 },
        armade: ERC20s { steel: 45000, quartz: 15000, tritium: 0 },
    }
}

mod requirements {
    use nogame::libraries::types::TechLevels;

    fn carrier(dockyard_level: u8, techs: TechLevels) {
        assert!(dockyard_level >= 2_u8, "Dockyard:E_DOCKYARD_LEVEL");
        assert!(techs.combustion >= 2_u8, "Dockyard:E_COMBUSTION_LEVEL");
    }

    fn sparrow(dockyard_level: u8, techs: TechLevels) {
        assert!(dockyard_level >= 1_u8, "Dockyard:E_DOCKYARD_LEVEL");
        assert!(techs.combustion >= 1_u8, "Dockyard:E_COMBUSTION_LEVEL");
    }

    fn scraper(dockyard_level: u8, techs: TechLevels) {
        assert!(dockyard_level >= 4_u8, "Dockyard:E_DOCKYARD_LEVEL");
        assert!(techs.combustion >= 6_u8, "Dockyard:E_COMBUSTION_LEVEL");
        assert!(techs.shield >= 2_u8, "Dockyard:E_SHIELD_LEVEL");
    }

    fn frigate(dockyard_level: u8, techs: TechLevels) {
        assert!(dockyard_level >= 5_u8, "Dockyard:E_DOCKYARD_LEVEL");
        assert!(techs.ion >= 2_u8, "Dockyard:E_ION_LEVEL");
        assert!(techs.thrust >= 4_u8, "Dockyard:E_THRUST_LEVEL");
    }

    fn armade(dockyard_level: u8, techs: TechLevels) {
        assert!(dockyard_level >= 7_u8, "Dockyard:E_DOCKYARD_LEVEL");
        assert!(techs.warp >= 4_u8, "Dockyard:E_WARP_LEVEL");
    }
}
