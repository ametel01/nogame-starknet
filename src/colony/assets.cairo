use nogame::defence::library as defence;
use nogame::dockyard::library as dockyard;
use nogame::libraries::types::{
    ColonyBuildType, ColonyUpgradeType, CompoundsLevels, Defences, Fleet, ShipsLevels, TechLevels,
};

#[derive(Copy, Drop)]
struct ColonyAssetState {
    compounds: CompoundsLevels,
    ships: ShipsLevels,
    defences: Defences,
}

fn upgrade_compounds(
    current: CompoundsLevels, component: ColonyUpgradeType, quantity: u8,
) -> CompoundsLevels {
    let mut next = current;
    match component {
        ColonyUpgradeType::SteelMine => { next.steel += quantity; },
        ColonyUpgradeType::QuartzMine => { next.quartz += quantity; },
        ColonyUpgradeType::TritiumMine => { next.tritium += quantity; },
        ColonyUpgradeType::EnergyPlant => { next.energy += quantity; },
        ColonyUpgradeType::Dockyard => { next.dockyard += quantity; },
    }
    next
}

fn build_units(
    mut current: ColonyAssetState, techs: TechLevels, component: ColonyBuildType, quantity: u32,
) -> ColonyAssetState {
    let dockyard_level = current.compounds.dockyard;
    match component {
        ColonyBuildType::Carrier => {
            dockyard::requirements::carrier(dockyard_level, techs);
            current.ships.carrier += quantity;
        },
        ColonyBuildType::Scraper => {
            dockyard::requirements::scraper(dockyard_level, techs);
            current.ships.scraper += quantity;
        },
        ColonyBuildType::Sparrow => {
            dockyard::requirements::sparrow(dockyard_level, techs);
            current.ships.sparrow += quantity;
        },
        ColonyBuildType::Frigate => {
            dockyard::requirements::frigate(dockyard_level, techs);
            current.ships.frigate += quantity;
        },
        ColonyBuildType::Armade => {
            dockyard::requirements::armade(dockyard_level, techs);
            current.ships.armade += quantity;
        },
        ColonyBuildType::Celestia => {
            defence::requirements::celestia(dockyard_level, techs);
            current.defences.celestia += quantity;
        },
        ColonyBuildType::Blaster => {
            defence::requirements::blaster(dockyard_level, techs);
            current.defences.blaster += quantity;
        },
        ColonyBuildType::Beam => {
            defence::requirements::beam(dockyard_level, techs);
            current.defences.beam += quantity;
        },
        ColonyBuildType::Astral => {
            defence::requirements::astral(dockyard_level, techs);
            current.defences.astral += quantity;
        },
        ColonyBuildType::Plasma => {
            defence::requirements::plasma(dockyard_level, techs);
            current.defences.plasma += quantity;
        },
    }
    current
}

fn add_fleet(current: ShipsLevels, fleet: Fleet) -> ShipsLevels {
    ShipsLevels {
        carrier: current.carrier + fleet.carrier,
        scraper: current.scraper + fleet.scraper,
        sparrow: current.sparrow + fleet.sparrow,
        frigate: current.frigate + fleet.frigate,
        armade: current.armade + fleet.armade,
    }
}

fn remove_fleet(current: ShipsLevels, fleet: Fleet) -> ShipsLevels {
    ShipsLevels {
        carrier: current.carrier - fleet.carrier,
        scraper: current.scraper - fleet.scraper,
        sparrow: current.sparrow - fleet.sparrow,
        frigate: current.frigate - fleet.frigate,
        armade: current.armade - fleet.armade,
    }
}
