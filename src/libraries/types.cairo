use core::num::traits::{OverflowingAdd, OverflowingSub};
use nogame::colony::contract::IColonyDispatcher;
use nogame::compound::contract::ICompoundDispatcher;
use nogame::defence::contract::IDefenceDispatcher;
use nogame::dockyard::contract::IDockyardDispatcher;
use nogame::fleet_movements::contract::IFleetMovementsDispatcher;
use nogame::game::contract::IGameDispatcher;
use nogame::planet::contract::IPlanetDispatcher;
use nogame::tech::contract::ITechDispatcher;
use nogame::token::erc20::interface::IERC20NoGameDispatcher;
use nogame::token::erc721::interface::IERC721NoGameDispatcher;
use openzeppelin_token::erc20::interface::IERC20Dispatcher;
use starknet::ContractAddress;

const E18: u128 = 1000000000000000000;
const MAX_NUMBER_OF_PLANETS: u32 = 500;
const ETH_ADDRESS: felt252 =
    2087021424722619777119509474943472645767659996348769578120564519014510906823;
// const BANK_ADDRESS: felt252 =
// 1860366167800154921415928660539590774912334121378072733158434352123488366392;
const _0_05: u128 = 922337203685477600;
const PRICE: u128 = 221360928884514600;
const PRECISION: u128 = 1_000_000_000_000_000_000;
const WEEK: u64 = 604_800;
const DAY: u64 = 86_400;
const HOUR: u64 = 3_600;

#[derive(Copy, Drop, Serde)]
struct Contracts {
    colony: IColonyDispatcher,
    compound: ICompoundDispatcher,
    dockyard: IDockyardDispatcher,
    defence: IDefenceDispatcher,
    planet: IPlanetDispatcher,
    fleet: IFleetMovementsDispatcher,
    game: IGameDispatcher,
    tech: ITechDispatcher,
}

#[derive(Copy, Debug, Default, Drop, Serde, PartialEq)]
struct ERC20s {
    steel: u128,
    quartz: u128,
    tritium: u128,
}

impl ERC20LevelsZeroable of Zeroable<ERC20s> {
    fn zero() -> ERC20s {
        ERC20s { steel: 0, quartz: 0, tritium: 0 }
    }
    fn is_zero(self: ERC20s) -> bool {
        self.steel == 0 && self.quartz == 0 && self.tritium == 0
    }
    fn is_non_zero(self: ERC20s) -> bool {
        !self.is_zero()
    }
}

impl ERC20sAdd of Add<ERC20s> {
    fn add(lhs: ERC20s, rhs: ERC20s) -> ERC20s {
        let (steel, _) = lhs.steel.overflowing_add(rhs.steel);
        let (quartz, _) = lhs.quartz.overflowing_add(rhs.quartz);
        let (tritium, _) = lhs.tritium.overflowing_add(rhs.tritium);
        ERC20s { steel: steel, quartz: quartz, tritium: tritium }
    }
}
impl ERC20sSub of Sub<ERC20s> {
    fn sub(lhs: ERC20s, rhs: ERC20s) -> ERC20s {
        let (steel, _) = lhs.steel.overflowing_sub(rhs.steel);
        let (quartz, _) = lhs.quartz.overflowing_sub(rhs.quartz);
        let (tritium, _) = lhs.tritium.overflowing_sub(rhs.tritium);
        ERC20s { steel: steel, quartz: quartz, tritium: tritium }
    }
}

impl ERC20sPartialOrd of PartialOrd<ERC20s> {
    fn le(lhs: ERC20s, rhs: ERC20s) -> bool {
        return (lhs.steel <= rhs.steel && lhs.quartz <= rhs.quartz && lhs.tritium <= rhs.tritium);
    }
    fn ge(lhs: ERC20s, rhs: ERC20s) -> bool {
        return (lhs.steel >= rhs.steel && lhs.quartz >= rhs.quartz && lhs.tritium >= rhs.tritium);
    }
    fn lt(lhs: ERC20s, rhs: ERC20s) -> bool {
        return (lhs.steel < rhs.steel && lhs.quartz < rhs.quartz && lhs.tritium < rhs.tritium);
    }
    fn gt(lhs: ERC20s, rhs: ERC20s) -> bool {
        return (lhs.steel > rhs.steel && lhs.quartz > rhs.quartz && lhs.tritium > rhs.tritium);
    }
}

fn erc20_mul(a: ERC20s, multiplicator: u128) -> ERC20s {
    ERC20s {
        steel: a.steel * multiplicator,
        quartz: a.quartz * multiplicator,
        tritium: a.tritium * multiplicator,
    }
}

#[derive(Copy, Default, Drop, Serde, PartialEq)]
struct CompoundsLevels {
    steel: u8,
    quartz: u8,
    tritium: u8,
    energy: u8,
    lab: u8,
    dockyard: u8,
}

#[derive(Copy, Drop, Serde)]
struct CompoundsCost {
    steel: ERC20s,
    quartz: ERC20s,
    tritium: ERC20s,
    energy: ERC20s,
    lab: ERC20s,
    dockyard: ERC20s,
}

#[derive(Copy, Debug, Default, Drop, Serde)]
struct TechLevels {
    energy: u8,
    digital: u8,
    beam: u8,
    armour: u8,
    ion: u8,
    plasma: u8,
    weapons: u8,
    shield: u8,
    spacetime: u8,
    combustion: u8,
    thrust: u8,
    warp: u8,
    exocraft: u8,
}

#[derive(Copy, Drop, Serde)]
struct TechsCost {
    energy: ERC20s,
    digital: ERC20s,
    beam: ERC20s,
    armour: ERC20s,
    ion: ERC20s,
    plasma: ERC20s,
    weapons: ERC20s,
    shield: ERC20s,
    spacetime: ERC20s,
    combustion: ERC20s,
    thrust: ERC20s,
    warp: ERC20s,
}

#[derive(Copy, Default, Drop, PartialEq, Serde)]
struct ShipsLevels {
    carrier: u32,
    scraper: u32,
    sparrow: u32,
    frigate: u32,
    armade: u32,
}

impl ShipsLevelsIntoFleet of Into<ShipsLevels, Fleet> {
    fn into(self: ShipsLevels) -> Fleet {
        Fleet {
            carrier: self.carrier,
            scraper: self.scraper,
            sparrow: self.sparrow,
            frigate: self.frigate,
            armade: self.armade,
        }
    }
}

#[derive(Copy, Drop, Serde)]
struct ShipsCost {
    carrier: ERC20s,
    celestia: ERC20s,
    scraper: ERC20s,
    sparrow: ERC20s,
    frigate: ERC20s,
    armade: ERC20s,
}

#[derive(Copy, Default, PartialEq, Drop, Serde)]
struct Defences {
    celestia: u32,
    blaster: u32,
    beam: u32,
    astral: u32,
    plasma: u32,
}

impl DefencesZeroable of Zeroable<Defences> {
    fn zero() -> Defences {
        Defences { celestia: 0, blaster: 0, beam: 0, astral: 0, plasma: 0 }
    }
    fn is_zero(self: Defences) -> bool {
        self.celestia == 0
            && self.blaster == 0
            && self.beam == 0
            && self.astral == 0
            && self.plasma == 0
    }
    fn is_non_zero(self: Defences) -> bool {
        !self.is_zero()
    }
}

#[derive(Copy, Drop, Serde)]
struct DefencesCost {
    celestia: ERC20s,
    blaster: ERC20s,
    beam: ERC20s,
    astral: ERC20s,
    plasma: ERC20s,
}

#[derive(Copy, Drop, Serde)]
struct EnergyCost {
    steel: u128,
    quartz: u128,
    tritium: u128,
}

#[derive(Copy, Debug, Default, Drop, PartialEq, Serde, starknet::Store, Hash)]
struct PlanetPosition {
    system: u32,
    orbit: u8,
}

impl PlanetPositionZeroable of Zeroable<PlanetPosition> {
    fn zero() -> PlanetPosition {
        PlanetPosition { system: 0, orbit: 0 }
    }
    fn is_zero(self: PlanetPosition) -> bool {
        self.system == 0 && self.orbit == 0
    }
    fn is_non_zero(self: PlanetPosition) -> bool {
        !self.is_zero()
    }
}

#[derive(Copy, Drop, Serde)]
struct Cargo {
    steel: u128,
    quartz: u128,
    tritium: u128,
}

#[derive(Copy, Default, Drop, PartialEq, Serde, starknet::Store)]
struct Debris {
    steel: u128,
    quartz: u128,
}

impl DebrisZeroable of Zeroable<Debris> {
    fn zero() -> Debris {
        Debris { steel: 0, quartz: 0 }
    }
    fn is_zero(self: Debris) -> bool {
        self.steel == 0 && self.quartz == 0
    }
    fn is_non_zero(self: Debris) -> bool {
        !self.is_zero()
    }
}

impl DebrisAdd of Add<Debris> {
    fn add(lhs: Debris, rhs: Debris) -> Debris {
        let (steel, _) = lhs.steel.overflowing_add(rhs.steel);
        let (quartz, _) = lhs.quartz.overflowing_add(rhs.quartz);
        Debris { steel: steel, quartz: quartz }
    }
}

#[derive(Default, Debug, Drop, Copy, PartialEq, Serde, starknet::Store)]
struct Fleet {
    carrier: u32,
    scraper: u32,
    sparrow: u32,
    frigate: u32,
    armade: u32,
}

impl FleetZeroable of Zeroable<Fleet> {
    fn zero() -> Fleet {
        Fleet { carrier: 0, scraper: 0, sparrow: 0, frigate: 0, armade: 0 }
    }
    fn is_zero(self: Fleet) -> bool {
        self.carrier == 0
            && self.scraper == 0
            && self.sparrow == 0
            && self.frigate == 0
            && self.armade == 0
    }
    fn is_non_zero(self: Fleet) -> bool {
        !self.is_zero()
    }
}

#[derive(Default, Drop, Copy, PartialEq, Serde, starknet::Store)]
struct Unit {
    id: u8,
    hull: u32,
    shield: u32,
    weapon: u32,
    speed: u32,
    cargo: u32,
    consumption: u32,
}

#[generate_trait]
impl UnitImpl of UnitTrait {
    fn is_destroyed(self: Unit) -> bool {
        self.hull == 0
    }
}

#[derive(Copy, Default, PartialEq, Drop, Serde, starknet::Store)]
struct IncomingMission {
    origin: u32,
    id_at_origin: usize,
    time_arrival: u64,
    number_of_ships: u32,
    destination: u32,
}

impl IncomingMissionZeroable of Zeroable<IncomingMission> {
    fn zero() -> IncomingMission {
        IncomingMission {
            origin: Zeroable::zero(),
            id_at_origin: Zeroable::zero(),
            time_arrival: Zeroable::zero(),
            number_of_ships: Zeroable::zero(),
            destination: Zeroable::zero(),
        }
    }
    fn is_zero(self: IncomingMission) -> bool {
        self.origin.is_zero() || self.number_of_ships.is_zero() || self.time_arrival.is_zero()
    }
    fn is_non_zero(self: IncomingMission) -> bool {
        !self.is_zero()
    }
}

#[derive(Copy, Debug, Default, PartialEq, Drop, Serde, starknet::Store)]
struct Mission {
    id: u32,
    time_start: u64,
    origin: u32,
    destination: u32,
    time_arrival: u64,
    fleet: Fleet,
    category: u8,
}

impl MissionZeroable of Zeroable<Mission> {
    fn zero() -> Mission {
        Mission {
            id: 0,
            time_start: 0,
            origin: 0,
            destination: 0,
            time_arrival: 0,
            fleet: Zeroable::zero(),
            category: 0,
        }
    }
    fn is_zero(self: Mission) -> bool {
        self.destination == 0 || self.time_arrival == 0 || self.fleet == Zeroable::zero()
    }
    fn is_non_zero(self: Mission) -> bool {
        !self.is_zero()
    }
}

#[derive(Drop, Serde)]
enum CompoundUpgradeType {
    SteelMine,
    QuartzMine,
    TritiumMine,
    EnergyPlant,
    Lab,
    Dockyard,
}
#[derive(Drop, Serde)]
enum TechUpgradeType {
    EnergyTech,
    Digital,
    BeamTech,
    Armour,
    Ion,
    PlasmaTech,
    Weapons,
    Shield,
    Spacetime,
    Combustion,
    Thrust,
    Warp,
    Exocraft,
}


trait UpgradeTrait<TState, UpgradeType> {
    fn upgrade(ref self: TState, component: UpgradeType, planet_id: u32) -> ERC20s;
}

#[derive(Drop, Serde)]
enum ShipBuildType {
    Carrier,
    Scraper,
    Sparrow,
    Frigate,
    Armade,
}
#[derive(Drop, Serde)]
enum DefenceBuildType {
    Celestia,
    Blaster,
    Beam,
    Astral,
    Plasma,
}

// mod Names {
//     const STEEL: felt252 = 1;
//     const QUARTZ: felt252 = 2;
//     const TRITIUM: felt252 = 3;
//     const ENERGY_PLANT: felt252 = 4;
//     const LAB: felt252 = 5;
//     const DOCKYARD: felt252 = 6;
//     const ENERGY_TECH: felt252 = 7;
//     const DIGITAL: felt252 = 8;
//     const BEAM_TECH: felt252 = 9;
//     const ARMOUR: felt252 = 10;
//     const ION: felt252 = 11;
//     const PLASMA_TECH: felt252 = 12;
//     const WEAPONS: felt252 = 13;
//     const SHIELD: felt252 = 14;
//     const SPACETIME: felt252 = 15;
//     const COMBUSTION: felt252 = 16;
//     const THRUST: felt252 = 17;
//     const WARP: felt252 = 18;
//     const CARRIER: felt252 = 19;
//     const SCRAPER: felt252 = 20;
//     const CELESTIA: felt252 = 21;
//     const SPARROW: felt252 = 22;
//     const FRIGATE: felt252 = 23;
//     const ARMADE: felt252 = 24;
//     const BLASTER: felt252 = 25;
//     const BEAM: felt252 = 26;
//     const ASTRAL: felt252 = 27;
//     const PLASMA: felt252 = 28;
//     const EXOCRAFT: felt252 = 29;
// }

#[derive(Default, Drop, Copy, PartialEq, Serde)]
struct SimulationResult {
    attacker_carrier: u32,
    attacker_scraper: u32,
    attacker_sparrow: u32,
    attacker_frigate: u32,
    attacker_armade: u32,
    defender_carrier: u32,
    defender_scraper: u32,
    defender_sparrow: u32,
    defender_frigate: u32,
    defender_armade: u32,
    celestia: u32,
    blaster: u32,
    beam: u32,
    astral: u32,
    plasma: u32,
}

#[derive(Copy, Drop, Serde)]
enum ColonyUpgradeType {
    SteelMine,
    QuartzMine,
    TritiumMine,
    EnergyPlant,
    Dockyard,
}

#[derive(Copy, Drop, Serde, PartialEq)]
enum ColonyBuildType {
    Carrier,
    Scraper,
    Sparrow,
    Frigate,
    Armade,
    Celestia,
    Blaster,
    Beam,
    Astral,
    Plasma,
}

mod MissionCategory {
    const ATTACK: u8 = 1;
    const TRANSPORT: u8 = 2;
    const DEBRIS: u8 = 3;
}

#[derive(Copy, Drop, Serde)]
struct Tokens {
    erc721: IERC721NoGameDispatcher,
    steel: IERC20NoGameDispatcher,
    quartz: IERC20NoGameDispatcher,
    tritium: IERC20NoGameDispatcher,
    eth: IERC20Dispatcher,
}

