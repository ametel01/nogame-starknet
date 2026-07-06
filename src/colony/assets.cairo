use nogame::compound::library as compound;
use nogame::defence::library as defence;
use nogame::dockyard::library as dockyard;
use nogame::libraries::types::{
    ColonyBuildType, ColonyUpgradeType, CompoundsLevels, Defences, ERC20s, Fleet, ShipsLevels,
    TechLevels,
};

#[derive(Copy, Drop)]
struct ColonyAssetState {
    compounds: CompoundsLevels,
    ships: ShipsLevels,
    defences: Defences,
}

fn upgrade_compounds(
    current: CompoundsLevels, component: ColonyUpgradeType, quantity: u8,
) -> (CompoundsLevels, ERC20s) {
    let mut next = current;
    let mut cost: ERC20s = Default::default();
    match component {
        ColonyUpgradeType::SteelMine => {
            cost = compound::cost::steel(current.steel, quantity);
            next.steel += quantity;
        },
        ColonyUpgradeType::QuartzMine => {
            cost = compound::cost::quartz(current.quartz, quantity);
            next.quartz += quantity;
        },
        ColonyUpgradeType::TritiumMine => {
            cost = compound::cost::tritium(current.tritium, quantity);
            next.tritium += quantity;
        },
        ColonyUpgradeType::EnergyPlant => {
            cost = compound::cost::energy(current.energy, quantity);
            next.energy += quantity;
        },
        ColonyUpgradeType::Dockyard => {
            cost = compound::cost::dockyard(current.dockyard, quantity);
            next.dockyard += quantity;
        },
    }
    (next, cost)
}

fn build_units(
    mut current: ColonyAssetState, techs: TechLevels, component: ColonyBuildType, quantity: u32,
) -> (ColonyAssetState, ERC20s) {
    let dockyard_level = current.compounds.dockyard;
    let mut cost: ERC20s = Default::default();
    match component {
        ColonyBuildType::Carrier => {
            dockyard::requirements::carrier(dockyard_level, techs);
            cost = dockyard::get_ships_cost(quantity, dockyard::get_ships_unit_cost().carrier);
            current.ships.carrier += quantity;
        },
        ColonyBuildType::Scraper => {
            dockyard::requirements::scraper(dockyard_level, techs);
            cost = dockyard::get_ships_cost(quantity, dockyard::get_ships_unit_cost().scraper);
            current.ships.scraper += quantity;
        },
        ColonyBuildType::Sparrow => {
            dockyard::requirements::sparrow(dockyard_level, techs);
            cost = dockyard::get_ships_cost(quantity, dockyard::get_ships_unit_cost().sparrow);
            current.ships.sparrow += quantity;
        },
        ColonyBuildType::Frigate => {
            dockyard::requirements::frigate(dockyard_level, techs);
            cost = dockyard::get_ships_cost(quantity, dockyard::get_ships_unit_cost().frigate);
            current.ships.frigate += quantity;
        },
        ColonyBuildType::Armade => {
            dockyard::requirements::armade(dockyard_level, techs);
            cost = dockyard::get_ships_cost(quantity, dockyard::get_ships_unit_cost().armade);
            current.ships.armade += quantity;
        },
        ColonyBuildType::Celestia => {
            defence::requirements::celestia(dockyard_level, techs);
            cost = dockyard::get_ships_cost(quantity, defence::get_defences_unit_cost().celestia);
            current.defences.celestia += quantity;
        },
        ColonyBuildType::Blaster => {
            defence::requirements::blaster(dockyard_level, techs);
            cost = dockyard::get_ships_cost(quantity, defence::get_defences_unit_cost().blaster);
            current.defences.blaster += quantity;
        },
        ColonyBuildType::Beam => {
            defence::requirements::beam(dockyard_level, techs);
            cost = dockyard::get_ships_cost(quantity, defence::get_defences_unit_cost().beam);
            current.defences.beam += quantity;
        },
        ColonyBuildType::Astral => {
            defence::requirements::astral(dockyard_level, techs);
            cost = dockyard::get_ships_cost(quantity, defence::get_defences_unit_cost().astral);
            current.defences.astral += quantity;
        },
        ColonyBuildType::Plasma => {
            defence::requirements::plasma(dockyard_level, techs);
            cost = dockyard::get_ships_cost(quantity, defence::get_defences_unit_cost().plasma);
            current.defences.plasma += quantity;
        },
    }
    (current, cost)
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
