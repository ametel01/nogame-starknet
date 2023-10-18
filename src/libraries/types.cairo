use snforge_std::io::PrintTrait;

use integer::u128_overflowing_add;
use starknet::ContractAddress;


const E18: u128 = 1000000000000000000;
const MAX_NUMBER_OF_PLANETS: u16 = 1000;
const ETH_ADDRESS: felt252 =
    2087021424722619777119509474943472645767659996348769578120564519014510906823;
const BANK_ADDRESS: felt252 =
    1860366167800154921415928660539590774912334121378072733158434352123488366392;
const _0_05: u128 = 922337203685477600;
const PRICE: u128 = 221360928884514600;
const PRECISION: u128 = 1_000_000_000_000_000_000;
const DAY: u64 = 86400;

#[derive(Copy, Drop, Serde)]
struct Tokens {
    erc721: ContractAddress,
    steel: ContractAddress,
    quartz: ContractAddress,
    tritium: ContractAddress,
}

#[derive(Copy, Default, Drop, Serde)]
struct ERC20s {
    steel: u128,
    quartz: u128,
    tritium: u128,
}

impl ERC20sAdd of Add<ERC20s> {
    fn add(lhs: ERC20s, rhs: ERC20s) -> ERC20s {
        ERC20s {
            steel: u128_overflowing_add(lhs.steel, rhs.steel).expect('u128_add Overflow'),
            quartz: u128_overflowing_add(lhs.quartz, rhs.quartz).expect('u128_add Overflow'),
            tritium: u128_overflowing_add(lhs.tritium, rhs.tritium).expect('u128_add Overflow'),
        }
    }
}

impl ERC20Print of PrintTrait<ERC20s> {
    fn print(self: ERC20s) {
        self.steel.print();
        self.quartz.print();
        self.tritium.print();
    }
}

#[derive(Copy, Drop, Serde)]
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

impl CompoundsCostPrint of PrintTrait<CompoundsCost> {
    fn print(self: CompoundsCost) {
        self.steel.print();
        self.quartz.print();
        self.tritium.print();
        self.energy.print();
        self.lab.print();
        self.dockyard.print();
    }
}

#[derive(Copy, Default, Drop, Serde)]
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

#[derive(Copy, Drop, Serde)]
struct ShipsLevels {
    carrier: u32,
    scraper: u32,
    sparrow: u32,
    frigate: u32,
    armade: u32,
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

#[derive(Copy, Default, Drop, Serde)]
struct DefencesLevels {
    celestia: u32,
    blaster: u32,
    beam: u32,
    astral: u32,
    plasma: u32
}

impl DefencesLevelsPrint of PrintTrait<DefencesLevels> {
    fn print(self: DefencesLevels) {
        self.celestia.print();
        self.blaster.print();
        self.beam.print();
        self.astral.print();
        self.plasma.print();
    }
}

impl DefencesLevelsZeroable of Zeroable<DefencesLevels> {
    fn zero() -> DefencesLevels {
        DefencesLevels { celestia: 0, blaster: 0, beam: 0, astral: 0, plasma: 0, }
    }
    fn is_zero(self: DefencesLevels) -> bool {
        self.celestia == 0
            && self.blaster == 0
            && self.beam == 0
            && self.astral == 0
            && self.plasma == 0
    }
    fn is_non_zero(self: DefencesLevels) -> bool {
        !self.is_zero()
    }
}

#[derive(Copy, Drop, Serde)]
struct DefencesCost {
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

#[derive(Copy, Default, Drop, Serde, starknet::Store)]
struct PlanetPosition {
    system: u8,
    orbit: u8,
}

impl PlanetPositionPrint of PrintTrait<PlanetPosition> {
    fn print(self: PlanetPosition) {
        self.system.print();
        self.orbit.print();
    }
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

#[derive(Copy, Default, Drop, Serde, starknet::Store)]
struct Debris {
    steel: u128,
    quartz: u128
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

impl DebrisPrint of PrintTrait<Debris> {
    fn print(self: Debris) {
        self.steel.print();
        self.quartz.print();
    }
}

impl DebrisAdd of Add<Debris> {
    fn add(lhs: Debris, rhs: Debris) -> Debris {
        Debris {
            steel: u128_overflowing_add(lhs.steel, rhs.steel).expect('u128_add Overflow'),
            quartz: u128_overflowing_add(lhs.quartz, rhs.quartz).expect('u128_add Overflow')
        }
    }
}

#[derive(Default, Drop, Copy, PartialEq, Serde, starknet::Store)]
struct Fleet {
    carrier: u32,
    scraper: u32,
    sparrow: u32,
    frigate: u32,
    armade: u32,
}

impl FleetZeroable of Zeroable<Fleet> {
    fn zero() -> Fleet {
        Fleet { carrier: 0, scraper: 0, sparrow: 0, frigate: 0, armade: 0, }
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

impl FleetPrint of PrintTrait<Fleet> {
    fn print(self: Fleet) {
        self.carrier.print();
        self.scraper.print();
        self.sparrow.print();
        self.frigate.print();
        self.armade.print();
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

impl PrintUnit of PrintTrait<Unit> {
    fn print(self: Unit) {
        self.weapon.print();
        self.shield.print();
        self.hull.print();
    }
}

#[derive(Copy, Default, Drop, Serde, starknet::Store)]
struct Mission {
    time_start: u64,
    destination: u16,
    time_arrival: u64,
    fleet: Fleet,
    is_return: bool,
}

impl MissionZeroable of Zeroable<Mission> {
    fn zero() -> Mission {
        Mission {
            time_start: 0,
            destination: 0,
            time_arrival: 0,
            fleet: Zeroable::zero(),
            is_return: false,
        }
    }
    fn is_zero(self: Mission) -> bool {
        self.time_start == 0
            || self.destination == 0
            || self.time_arrival == 0
            || self.fleet == Zeroable::zero()
    }
    fn is_non_zero(self: Mission) -> bool {
        !self.is_zero()
    }
}

impl MissionPrint of PrintTrait<Mission> {
    fn print(self: Mission) {
        self.time_start.print();
        self.destination.print();
        self.time_arrival.print();
        self.fleet.print();
    }
}
