use snforge_std::io::PrintTrait;

use starknet::ContractAddress;

const E18: u128 = 1000000000000000000;
const MAX_NUMBER_OF_PLANETS: u16 = 1000;


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

impl ERC20Print of PrintTrait<ERC20s> {
    fn print(self: ERC20s) {
        self.steel.print();
        self.quartz.print();
        self.tritium.print();
    }
}

#[derive(Copy, Drop, Serde)]
struct CompoundsLevelsPacked {
    steel: u8,
    quartz: u8,
    tritium: u8,
    energy: u8,
    lab: u8,
    dockyard: u8,
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

#[derive(Copy, Drop, Serde)]
struct DefencesLevels {
    blaster: u32,
    beam: u32,
    astral: u32,
    plasma: u32
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

impl DebrisPrint of PrintTrait<Debris> {
    fn print(self: Debris) {
        self.steel.print();
        self.quartz.print();
    }
}

#[derive(Default, Drop, Copy, PartialEq, Serde)]
struct Fleet {
    n_ships: u32,
    carrier: u32,
    scraper: u32,
    sparrow: u32,
    frigate: u32,
    armade: u32,
}

#[derive(Default, Drop, Copy, PartialEq, Serde, starknet::Store)]
struct Unit {
    id: u8,
    hull: u32,
    shield: u32,
    weapon: u32,
    speed: u32,
    cargo: u32,
    fuel_consumption: u32,
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
    destination: u16,
    number_of_ships: u32,
    time_arrival: u64,
}

impl MissionPrint of PrintTrait<Mission> {
    fn print(self: Mission) {
        self.destination.print();
        self.number_of_ships.print();
        self.time_arrival.print();
    }
}
