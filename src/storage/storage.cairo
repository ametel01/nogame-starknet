use starknet::ContractAddress;
use nogame::libraries::types::{
    Tokens, PlanetPosition, Debris, Mission, IncomingMission, CompoundsLevels, TechLevels, Fleet
};

#[starknet::interface]
trait IStorage<TState> {
    fn initializer(
        ref self: TState,
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
    fn set_planet_debris_field(ref self: TState, planet_id: u32, debris: Debris,);
    fn set_universe_start_time(ref self: TState, universe_start_time: u64,);
    fn set_resources_spent(ref self: TState, planet_id: u32, resources_spent: u128,);
    fn set_compound_level(ref self: TState, planet_id: u32, compound_id: felt252, level: u8,);
    fn set_tech_level(ref self: TState, planet_id: u32, tech_id: felt252, level: u8,);
    fn set_ship_level(ref self: TState, planet_id: u32, ship_id: felt252, level: u32,);

    fn get_token_addresses(self: @TState) -> Tokens;
    fn get_number_of_planets(self: @TState) -> u32;
    fn get_is_testnet(self: @TState) -> bool;
    fn get_uni_speed(self: @TState) -> u128;
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
}

#[starknet::contract]
mod Storage {
    use super::{
        ContractAddress, Tokens, PlanetPosition, Debris, Mission, IncomingMission, CompoundsLevels,
        Fleet, TechLevels
    };
    use openzeppelin::token::erc20::interface::IERC20CamelDispatcher;
    use nogame::token::erc20::interface::IERC20NoGameDispatcher;
    use nogame::token::erc721::interface::IERC721NoGameDispatcher;
    use nogame::libraries::types::{Names};

    #[storage]
    struct Storage {
        game: ContractAddress,
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
        // General.
        number_of_planets: u32,
        planet_position: LegacyMap::<u32, PlanetPosition>,
        position_to_planet: LegacyMap::<PlanetPosition, u32>,
        planet_debris_field: LegacyMap::<u32, Debris>,
        universe_start_time: u64,
        resources_spent: LegacyMap::<u32, u128>,
        // mapping colony_planet_id to mother planet id
        colony_owner: LegacyMap::<u32, u32>,
        // Tokens.
        resources_timer: LegacyMap::<u32, u64>,
        last_active: LegacyMap::<u32, u64>,
        compounds_level: LegacyMap::<(u32, felt252), u8>,
        techs_level: LegacyMap::<(u32, felt252), u8>,
        ships_level: LegacyMap::<(u32, felt252), u32>,
        defences_level: LegacyMap::<(u32, felt252), u32>,
        active_missions: LegacyMap::<(u32, u32), Mission>,
        active_missions_len: LegacyMap<u32, usize>,
        hostile_missions: LegacyMap<(u32, u32), IncomingMission>,
        hostile_missions_len: LegacyMap<u32, usize>,
    }

    #[constructor]
    fn constructor(ref self: ContractState, game: ContractAddress) {
        self.universe_start_time.write(starknet::get_block_timestamp());
        self.game.write(game);
    }

    #[abi(embed_v0)]
    impl StorageImpl of super::IStorage<ContractState> {
        fn initializer(
            ref self: ContractState,
            erc721: ContractAddress,
            steel: ContractAddress,
            quartz: ContractAddress,
            tritium: ContractAddress,
            eth: ContractAddress,
            fees_receiver: ContractAddress,
            uni_speed: u128,
            token_price: u128,
            is_testnet: bool
        ) {
            assert(!self.initialized.read(), 'already initialized');
            self.erc721.write(IERC721NoGameDispatcher { contract_address: erc721 });
            self.steel.write(IERC20NoGameDispatcher { contract_address: steel });
            self.quartz.write(IERC20NoGameDispatcher { contract_address: quartz });
            self.tritium.write(IERC20NoGameDispatcher { contract_address: tritium });
            self.ETH.write(IERC20CamelDispatcher { contract_address: eth });
            self.fees_receiver.write(fees_receiver);
            self.uni_speed.write(uni_speed);
            self.initialized.write(true);
            self.token_price.write(token_price);
            self.is_testnet.write(is_testnet);
        }

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
                self.resources_timer.write(colony_id, starknet::get_block_timestamp());
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
    }
}
