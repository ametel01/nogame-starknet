use nogame::libraries::types::{
    Tokens, PlanetPosition, Debris, Mission, IncomingMission, CompoundsLevels, TechLevels, Fleet,
    Defences, ERC20s, Contracts
};
use starknet::ContractAddress;

#[starknet::interface]
trait IStorage<TState> {
    fn initializer(
        ref self: TState,
        colony: ContractAddress,
        compound: ContractAddress,
        defence: ContractAddress,
        dockyard: ContractAddress,
        fleet: ContractAddress,
        nogame: ContractAddress,
        tech: ContractAddress,
        erc721: ContractAddress,
        steel: ContractAddress,
        quartz: ContractAddress,
        tritium: ContractAddress,
        eth: ContractAddress,
        fees_receiver: ContractAddress,
        uni_speed: u128,
        token_price: u128,
        is_testnet: bool,
    );
    fn add_new_planet(
        ref self: TState,
        planet_id: u32,
        position: PlanetPosition,
        new_planet_count: u32,
        colony_id: u32
    );
    fn update_resources_timer(ref self: TState, planet_id: u32, new_resources_timer: u64,);
    fn set_last_active(ref self: TState, planet_id: u32, last_active: u64,);
    fn update_planet_points(ref self: TState, planet_id: u32, spent: ERC20s);
    fn set_planet_debris_field(ref self: TState, planet_id: u32, debris: Debris,);
    fn set_universe_start_time(ref self: TState, universe_start_time: u64,);
    fn set_resources_spent(ref self: TState, planet_id: u32, resources_spent: u128,);
    fn set_compound_level(ref self: TState, planet_id: u32, compound_id: felt252, level: u8,);
    fn set_tech_level(ref self: TState, planet_id: u32, tech_id: felt252, level: u8,);
    fn set_ship_level(ref self: TState, planet_id: u32, ship_id: felt252, level: u32,);
    fn set_defence_level(ref self: TState, planet_id: u32, defence_id: felt252, level: u32,);
    fn set_mission(ref self: TState, planet_id: u32, mission_id: usize, mission: Mission,);
    fn add_active_mission(ref self: TState, planet_id: u32, mission: Mission) -> usize;
    fn add_incoming_mission(ref self: TState, planet_id: u32, mission: IncomingMission);
    fn remove_incoming_mission(ref self: TState, planet_id: u32, id_to_remove: usize);
    fn set_colony_count(ref self: TState, colony_count: usize);
    fn set_planet_colonies_count(ref self: TState, planet_id: u32, colony_count: u8);
    fn set_colony_position(
        ref self: TState, planet_id: u32, colony_id: u8, position: PlanetPosition
    );
    fn set_colony_resource_timer(ref self: TState, planet_id: u32, colony_id: u8, timer: u64);
    fn set_colony_compound(
        ref self: TState, planet_id: u32, colony_id: u8, compound_id: felt252, level: u8,
    );
    fn set_colony_ship(
        ref self: TState, planet_id: u32, colony_id: u8, ship_id: felt252, level: u32,
    );
    fn set_colony_defence(
        ref self: TState, planet_id: u32, colony_id: u8, defence_id: felt252, level: u32,
    );

    fn get_contracts(self: @TState) -> Contracts;
    fn get_token_addresses(self: @TState) -> Tokens;
    fn get_number_of_planets(self: @TState) -> u32;
    fn get_is_testnet(self: @TState) -> bool;
    fn get_uni_speed(self: @TState) -> u128;
    fn get_planet_points(self: @TState, planet_id: u32) -> u128;
    fn get_position_to_planet(self: @TState, position: PlanetPosition) -> u32;
    fn get_planet_position(self: @TState, planet_id: u32) -> PlanetPosition;
    fn get_last_active(self: @TState, planet_id: u32) -> u64;
    fn get_colony_mother_planet(self: @TState, colony_planet_id: u32) -> u32;
    fn get_token_price(self: @TState) -> u128;
    fn get_resources_timer(self: @TState, planet_id: u32) -> u64;
    fn get_planet_debris_field(self: @TState, planet_id: u32) -> Debris;
    fn get_universe_start_time(self: @TState) -> u64;
    fn get_resources_spent(self: @TState, planet_id: u32) -> u128;
    fn get_compounds_levels(self: @TState, planet_id: u32) -> CompoundsLevels;
    fn get_tech_levels(self: @TState, planet_id: u32) -> TechLevels;
    fn get_ships_levels(self: @TState, planet_id: u32) -> Fleet;
    fn get_defences_levels(self: @TState, planet_id: u32) -> Defences;
    // Missions.
    fn get_active_missions(self: @TState, planet_id: u32) -> Array<Mission>;
    fn get_mission_details(self: @TState, planet_id: u32, mission_id: usize) -> Mission;
    fn get_incoming_missions(self: @TState, planet_id: u32) -> Array<IncomingMission>;
    fn get_is_noob_protected(self: @TState, planet1_id: u32, planet2_id: u32) -> bool;
    // Colonies.
    fn get_colony_count(self: @TState) -> u32;
    fn get_planet_colonies_count(self: @TState, planet_id: u32) -> u8;
    fn get_colonies_for_planet(self: @TState, planet_id: u32) -> Array<(u8, PlanetPosition)>;
    fn get_colony_position(self: @TState, planet_id: u32, colony_id: u8) -> PlanetPosition;
    fn get_position_to_colony(self: @TState, position: PlanetPosition) -> (u32, u8);
    fn get_colony_resource_timer(self: @TState, planet_id: u32, colony_id: u8) -> u64;
    fn get_colony_compounds(self: @TState, planet_id: u32, colony_id: u8) -> CompoundsLevels;
    fn get_colony_ships(self: @TState, planet_id: u32, colony_id: u8) -> Fleet;
    fn get_colony_defences(self: @TState, planet_id: u32, colony_id: u8) -> Defences;
}

#[starknet::contract]
mod Storage {
    use nogame::component::shared::SharedComponent;
    use nogame::libraries::types::{Names, ERC20s};
    use nogame::token::erc20::interface::IERC20NoGameDispatcher;
    use nogame::token::erc721::interface::IERC721NoGameDispatcher;
    use openzeppelin::token::erc20::interface::IERC20CamelDispatcher;
    use snforge_std::PrintTrait;
    use super::{
        ContractAddress, Tokens, PlanetPosition, Debris, Mission, IncomingMission, CompoundsLevels,
        Fleet, TechLevels, Defences, Contracts
    };

    component!(path: SharedComponent, storage: shared, event: SharedEvent);
    impl SharedInternalImpl = SharedComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        shared: SharedComponent::Storage,
        // Settings.
        game: ContractAddress,
        fleet: ContractAddress,
        colony: ContractAddress,
        compound: ContractAddress,
        tech: ContractAddress,
        dockyard: ContractAddress,
        defence: ContractAddress,
        erc721: IERC721NoGameDispatcher,
        steel: IERC20NoGameDispatcher,
        quartz: IERC20NoGameDispatcher,
        tritium: IERC20NoGameDispatcher,
        ETH: IERC20CamelDispatcher,
        initialized: bool,
        is_testnet: bool,
        fees_receiver: ContractAddress,
        token_price: u128,
        uni_speed: u128,
        // Planets.
        number_of_planets: u32,
        planet_position: LegacyMap::<u32, PlanetPosition>,
        position_to_planet: LegacyMap::<PlanetPosition, u32>,
        resources_timer: LegacyMap::<u32, u64>,
        last_active: LegacyMap::<u32, u64>,
        planet_debris_field: LegacyMap::<u32, Debris>,
        universe_start_time: u64,
        resources_spent: LegacyMap::<u32, u128>,
        // Levels.
        compounds_level: LegacyMap::<(u32, felt252), u8>,
        techs_level: LegacyMap::<(u32, felt252), u8>,
        ships_level: LegacyMap::<(u32, felt252), u32>,
        defences_level: LegacyMap::<(u32, felt252), u32>,
        // Missions.
        active_missions: LegacyMap::<(u32, u32), Mission>,
        active_missions_len: LegacyMap<u32, usize>,
        incoming_missions: LegacyMap<(u32, u32), IncomingMission>,
        incoming_missions_len: LegacyMap<u32, usize>,
        // Colonies.
        colony_owner: LegacyMap::<u32, u32>,
        colony_count: usize,
        planet_colonies_count: LegacyMap::<u32, u8>,
        colony_position: LegacyMap::<(u32, u8), PlanetPosition>,
        position_to_colony: LegacyMap::<PlanetPosition, (u32, u8)>,
        colony_resource_timer: LegacyMap<(u32, u8), u64>,
        colony_compounds: LegacyMap::<(u32, u8, felt252), u8>,
        colony_ships: LegacyMap::<(u32, u8, felt252), u32>,
        colony_defences: LegacyMap::<(u32, u8, felt252), u32>,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        SharedEvent: SharedComponent::Event,
    }

    #[constructor]
    fn constructor(ref self: ContractState) {
        self.universe_start_time.write(starknet::get_block_timestamp());
    }

    #[abi(embed_v0)]
    impl StorageImpl of super::IStorage<ContractState> {
        fn add_new_planet(
            ref self: ContractState,
            planet_id: u32,
            position: PlanetPosition,
            new_planet_count: u32,
            colony_id: u32
        ) {
            if !colony_id.is_zero() {
                self.colony_owner.write(colony_id, planet_id);
                self.planet_position.write(colony_id, position);
                self.position_to_planet.write(position, colony_id);
            } else {
                self.position_to_planet.write(position, planet_id);
                self.planet_position.write(planet_id, position);
                self.resources_timer.write(planet_id, starknet::get_block_timestamp());
            }
            self.number_of_planets.write(new_planet_count);
        }

        fn update_resources_timer(
            ref self: ContractState, planet_id: u32, new_resources_timer: u64,
        ) {
            self.resources_timer.write(planet_id, new_resources_timer);
        }

        fn set_last_active(ref self: ContractState, planet_id: u32, last_active: u64,) {
            self.last_active.write(planet_id, last_active);
        }

        fn update_planet_points(ref self: ContractState, planet_id: u32, spent: ERC20s) {
            self.set_last_active(planet_id, starknet::get_block_timestamp());
            self
                .set_resources_spent(
                    planet_id, self.get_resources_spent(planet_id) + spent.steel + spent.quartz
                );
        }

        fn set_planet_debris_field(ref self: ContractState, planet_id: u32, debris: Debris,) {
            self.planet_debris_field.write(planet_id, debris);
        }

        fn set_universe_start_time(ref self: ContractState, universe_start_time: u64,) {
            self.universe_start_time.write(universe_start_time);
        }

        fn set_resources_spent(ref self: ContractState, planet_id: u32, resources_spent: u128,) {
            self.resources_spent.write(planet_id, resources_spent);
        }

        fn set_compound_level(
            ref self: ContractState, planet_id: u32, compound_id: felt252, level: u8,
        ) {
            self.compounds_level.write((planet_id, compound_id), level);
        }

        fn set_tech_level(ref self: ContractState, planet_id: u32, tech_id: felt252, level: u8,) {
            self.techs_level.write((planet_id, tech_id), level);
        }

        fn set_ship_level(ref self: ContractState, planet_id: u32, ship_id: felt252, level: u32,) {
            self.ships_level.write((planet_id, ship_id), level);
        }

        fn set_defence_level(
            ref self: ContractState, planet_id: u32, defence_id: felt252, level: u32,
        ) {
            self.defences_level.write((planet_id, defence_id), level);
        }

        fn set_mission(
            ref self: ContractState, planet_id: u32, mission_id: usize, mission: Mission,
        ) {
            self.active_missions.write((planet_id, mission_id), mission);
        }

        fn add_active_mission(
            ref self: ContractState, planet_id: u32, mut mission: Mission
        ) -> usize {
            let len = self.active_missions_len.read(planet_id);
            let mut i = 1;
            loop {
                if i > len {
                    mission.id = i.try_into().expect('add active mission fail');
                    self.active_missions.write((planet_id, i), mission);
                    self.active_missions_len.write(planet_id, i);
                    break;
                }
                let read_mission = self.active_missions.read((planet_id, i));
                if read_mission.is_zero() {
                    mission.id = i.try_into().expect('add active mission fail');
                    self.active_missions.write((planet_id, i), mission);
                    break;
                }
                i += 1;
            };
            i
        }

        fn add_incoming_mission(ref self: ContractState, planet_id: u32, mission: IncomingMission) {
            let len = self.incoming_missions_len.read(planet_id);
            let mut i = 1;
            loop {
                if i > len {
                    self.incoming_missions.write((planet_id, i), mission);
                    self.incoming_missions_len.write(planet_id, i);
                    break;
                }
                let read_mission = self.incoming_missions.read((planet_id, i));
                if read_mission.is_zero() {
                    self.incoming_missions.write((planet_id, i), mission);
                    break;
                }
                i += 1;
            };
        }

        fn remove_incoming_mission(ref self: ContractState, planet_id: u32, id_to_remove: usize) {
            let len = self.incoming_missions_len.read(planet_id);
            let mut i = 1;
            loop {
                if i > len {
                    break;
                }
                let mission = self.incoming_missions.read((planet_id, i));
                if mission.id_at_origin == id_to_remove {
                    self.incoming_missions.write((planet_id, i), Zeroable::zero());
                    break;
                }
                i += 1;
            }
        }

        fn set_colony_count(ref self: ContractState, colony_count: usize) {
            self.colony_count.write(colony_count);
        }

        fn set_planet_colonies_count(ref self: ContractState, planet_id: u32, colony_count: u8) {
            self.planet_colonies_count.write(planet_id, colony_count);
        }

        fn set_colony_position(
            ref self: ContractState, planet_id: u32, colony_id: u8, position: PlanetPosition,
        ) {
            self.colony_position.write((planet_id, colony_id), position);
            self.position_to_colony.write(position, (planet_id, colony_id));
            self
                .colony_resource_timer
                .write((planet_id, colony_id), starknet::get_block_timestamp());
        }

        fn set_colony_resource_timer(
            ref self: ContractState, planet_id: u32, colony_id: u8, timer: u64,
        ) {
            self.colony_resource_timer.write((planet_id, colony_id), timer);
        }

        fn set_colony_compound(
            ref self: ContractState, planet_id: u32, colony_id: u8, compound_id: felt252, level: u8,
        ) {
            self.colony_compounds.write((planet_id, colony_id, compound_id), level);
        }

        fn set_colony_ship(
            ref self: ContractState, planet_id: u32, colony_id: u8, ship_id: felt252, level: u32,
        ) {
            self.colony_ships.write((planet_id, colony_id, ship_id), level);
        }

        fn set_colony_defence(
            ref self: ContractState, planet_id: u32, colony_id: u8, defence_id: felt252, level: u32,
        ) {
            self.colony_defences.write((planet_id, colony_id, defence_id), level);
        }

        fn get_contracts(self: @ContractState) -> Contracts {
            Contracts {
                colony: self.colony.read(),
                game: self.game.read(),
                fleet: self.fleet.read(),
                compound: self.compound.read(),
                tech: self.tech.read(),
                dockyard: self.dockyard.read(),
                defence: self.defence.read(),
            }
        }

        fn get_token_addresses(self: @ContractState) -> Tokens {
            Tokens {
                erc721: self.erc721.read(),
                steel: self.steel.read(),
                quartz: self.quartz.read(),
                tritium: self.tritium.read(),
                eth: self.ETH.read(),
            }
        }

        fn get_number_of_planets(self: @ContractState) -> u32 {
            self.number_of_planets.read()
        }

        fn get_is_testnet(self: @ContractState) -> bool {
            self.is_testnet.read()
        }

        fn get_uni_speed(self: @ContractState) -> u128 {
            self.uni_speed.read()
        }

        fn get_planet_points(self: @ContractState, planet_id: u32) -> u128 {
            self.resources_spent.read(planet_id) / 1000
        }

        fn get_position_to_planet(self: @ContractState, position: PlanetPosition) -> u32 {
            self.position_to_planet.read(position)
        }

        fn get_planet_position(self: @ContractState, planet_id: u32) -> PlanetPosition {
            self.planet_position.read(planet_id)
        }

        fn get_last_active(self: @ContractState, planet_id: u32) -> u64 {
            self.last_active.read(planet_id)
        }

        fn get_colony_mother_planet(self: @ContractState, colony_planet_id: u32) -> u32 {
            self.colony_owner.read(colony_planet_id)
        }

        fn get_token_price(self: @ContractState) -> u128 {
            self.token_price.read()
        }

        fn get_resources_timer(self: @ContractState, planet_id: u32) -> u64 {
            self.resources_timer.read(planet_id)
        }

        fn get_planet_debris_field(self: @ContractState, planet_id: u32) -> Debris {
            self.planet_debris_field.read(planet_id)
        }

        fn get_universe_start_time(self: @ContractState) -> u64 {
            self.universe_start_time.read()
        }

        fn get_resources_spent(self: @ContractState, planet_id: u32) -> u128 {
            self.resources_spent.read(planet_id)
        }

        fn get_compounds_levels(self: @ContractState, planet_id: u32) -> CompoundsLevels {
            CompoundsLevels {
                steel: self.compounds_level.read((planet_id, Names::STEEL)),
                quartz: self.compounds_level.read((planet_id, Names::QUARTZ)),
                tritium: self.compounds_level.read((planet_id, Names::TRITIUM)),
                energy: self.compounds_level.read((planet_id, Names::ENERGY_PLANT)),
                lab: self.compounds_level.read((planet_id, Names::LAB)),
                dockyard: self.compounds_level.read((planet_id, Names::DOCKYARD))
            }
        }

        fn get_tech_levels(self: @ContractState, planet_id: u32) -> TechLevels {
            TechLevels {
                energy: self.techs_level.read((planet_id, Names::ENERGY_TECH)),
                digital: self.techs_level.read((planet_id, Names::DIGITAL)),
                beam: self.techs_level.read((planet_id, Names::BEAM_TECH)),
                armour: self.techs_level.read((planet_id, Names::ARMOUR)),
                ion: self.techs_level.read((planet_id, Names::ION)),
                plasma: self.techs_level.read((planet_id, Names::PLASMA_TECH)),
                weapons: self.techs_level.read((planet_id, Names::WEAPONS)),
                shield: self.techs_level.read((planet_id, Names::SHIELD)),
                spacetime: self.techs_level.read((planet_id, Names::SPACETIME)),
                combustion: self.techs_level.read((planet_id, Names::COMBUSTION)),
                thrust: self.techs_level.read((planet_id, Names::THRUST)),
                warp: self.techs_level.read((planet_id, Names::WARP)),
                exocraft: self.techs_level.read((planet_id, Names::EXOCRAFT)),
            }
        }

        fn get_ships_levels(self: @ContractState, planet_id: u32) -> Fleet {
            Fleet {
                carrier: self.ships_level.read((planet_id, Names::CARRIER)),
                scraper: self.ships_level.read((planet_id, Names::SCRAPER)),
                sparrow: self.ships_level.read((planet_id, Names::SPARROW)),
                frigate: self.ships_level.read((planet_id, Names::FRIGATE)),
                armade: self.ships_level.read((planet_id, Names::ARMADE)),
            }
        }

        fn get_defences_levels(self: @ContractState, planet_id: u32) -> Defences {
            Defences {
                celestia: self.defences_level.read((planet_id, Names::CELESTIA)),
                blaster: self.defences_level.read((planet_id, Names::BLASTER)),
                beam: self.defences_level.read((planet_id, Names::BEAM)),
                astral: self.defences_level.read((planet_id, Names::ASTRAL)),
                plasma: self.defences_level.read((planet_id, Names::PLASMA)),
            }
        }

        fn get_active_missions(self: @ContractState, planet_id: u32) -> Array<Mission> {
            let mut arr: Array<Mission> = array![];
            let len = self.active_missions_len.read(planet_id);
            let mut i = 1;
            loop {
                if i > len {
                    break;
                }
                let mission = self.active_missions.read((planet_id, i));
                if !mission.is_zero() {
                    arr.append(mission);
                }
                i += 1;
            };
            arr
        }

        fn get_mission_details(self: @ContractState, planet_id: u32, mission_id: usize) -> Mission {
            self.active_missions.read((planet_id, mission_id))
        }

        fn get_incoming_missions(self: @ContractState, planet_id: u32) -> Array<IncomingMission> {
            let mut arr: Array<IncomingMission> = array![];
            let len = self.incoming_missions_len.read(planet_id);
            let mut i = 1;
            loop {
                if i > len {
                    break;
                }
                let mission = self.incoming_missions.read((planet_id, i));
                if !mission.is_zero() {
                    arr.append(mission);
                }
                i += 1;
            };
            arr
        }

        fn get_is_noob_protected(self: @ContractState, planet1_id: u32, planet2_id: u32) -> bool {
            let p1_points = self.get_planet_points(planet1_id);
            let p2_points = self.get_planet_points(planet2_id);
            if p1_points > p2_points {
                return p1_points > p2_points * 5;
            } else {
                return p2_points > p1_points * 5;
            }
        }

        fn get_colony_count(self: @ContractState) -> u32 {
            self.colony_count.read()
        }

        fn get_planet_colonies_count(self: @ContractState, planet_id: u32) -> u8 {
            self.planet_colonies_count.read(planet_id)
        }

        fn get_colonies_for_planet(
            self: @ContractState, planet_id: u32
        ) -> Array<(u8, PlanetPosition)> {
            let mut arr: Array<(u8, PlanetPosition)> = array![];
            let mut i = 1;
            loop {
                let colony_position = self.colony_position.read((planet_id, i));
                if colony_position.is_zero() {
                    break;
                }
                arr.append((i, colony_position));
                i += 1;
            };
            arr
        }

        fn get_colony_position(
            self: @ContractState, planet_id: u32, colony_id: u8
        ) -> PlanetPosition {
            self.colony_position.read((planet_id, colony_id))
        }

        fn get_position_to_colony(self: @ContractState, position: PlanetPosition) -> (u32, u8) {
            self.position_to_colony.read(position)
        }

        fn get_colony_resource_timer(self: @ContractState, planet_id: u32, colony_id: u8) -> u64 {
            self.colony_resource_timer.read((planet_id, colony_id))
        }

        fn get_colony_compounds(
            self: @ContractState, planet_id: u32, colony_id: u8
        ) -> CompoundsLevels {
            CompoundsLevels {
                steel: self.colony_compounds.read((planet_id, colony_id, Names::STEEL)),
                quartz: self.colony_compounds.read((planet_id, colony_id, Names::QUARTZ)),
                tritium: self.colony_compounds.read((planet_id, colony_id, Names::TRITIUM)),
                energy: self.colony_compounds.read((planet_id, colony_id, Names::ENERGY_PLANT)),
                lab: self.colony_compounds.read((planet_id, colony_id, Names::LAB)),
                dockyard: self.colony_compounds.read((planet_id, colony_id, Names::DOCKYARD))
            }
        }

        fn get_colony_ships(self: @ContractState, planet_id: u32, colony_id: u8) -> Fleet {
            Fleet {
                carrier: self.colony_ships.read((planet_id, colony_id, Names::CARRIER)),
                scraper: self.colony_ships.read((planet_id, colony_id, Names::SCRAPER)),
                sparrow: self.colony_ships.read((planet_id, colony_id, Names::SPARROW)),
                frigate: self.colony_ships.read((planet_id, colony_id, Names::FRIGATE)),
                armade: self.colony_ships.read((planet_id, colony_id, Names::ARMADE)),
            }
        }

        fn get_colony_defences(self: @ContractState, planet_id: u32, colony_id: u8) -> Defences {
            Defences {
                celestia: self.colony_defences.read((planet_id, colony_id, Names::CELESTIA)),
                blaster: self.colony_defences.read((planet_id, colony_id, Names::BLASTER)),
                beam: self.colony_defences.read((planet_id, colony_id, Names::BEAM)),
                astral: self.colony_defences.read((planet_id, colony_id, Names::ASTRAL)),
                plasma: self.colony_defences.read((planet_id, colony_id, Names::PLASMA)),
            }
        }

        fn initializer(
            ref self: ContractState,
            colony: ContractAddress,
            compound: ContractAddress,
            defence: ContractAddress,
            dockyard: ContractAddress,
            fleet: ContractAddress,
            nogame: ContractAddress,
            tech: ContractAddress,
            erc721: ContractAddress,
            steel: ContractAddress,
            quartz: ContractAddress,
            tritium: ContractAddress,
            eth: ContractAddress,
            fees_receiver: ContractAddress,
            uni_speed: u128,
            token_price: u128,
            is_testnet: bool,
        ) {
            assert(!self.initialized.read(), 'already initialized');
            self.colony.write(colony);
            self.compound.write(compound);
            self.defence.write(defence);
            self.dockyard.write(dockyard);
            self.fleet.write(fleet);
            self.game.write(nogame);
            self.tech.write(tech);
            self.erc721.write(IERC721NoGameDispatcher { contract_address: erc721 });
            self.steel.write(IERC20NoGameDispatcher { contract_address: steel });
            self.quartz.write(IERC20NoGameDispatcher { contract_address: quartz });
            self.tritium.write(IERC20NoGameDispatcher { contract_address: tritium });
            self.ETH.write(IERC20CamelDispatcher { contract_address: eth });
            self.fees_receiver.write(fees_receiver);
            self.uni_speed.write(uni_speed);
            self.token_price.write(token_price);
            self.is_testnet.write(is_testnet);
            self.initialized.write(true);
        }
    }
}
