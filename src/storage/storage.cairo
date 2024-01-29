use starknet::ContractAddress;

#[starknet::interface]
trait IStorage<TState> {
    fn initializer(
        ref self: TState,
        erc721: ContractAddress,
        steel: ContractAddress,
        quartz: ContractAddress,
        tritium: ContractAddress,
        eth: ContractAddress,
        owner: ContractAddress,
        uni_speed: u128,
        token_price: u128,
        is_testnet: bool,
    );
}

#[starknet::contract]
mod Storage {
    use super::ContractAddress;

    #[storage]
    struct Storage {
        owner: ContractAddress,
        initialized: bool,
        is_testnet: bool,
        receiver: ContractAddress,
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
        erc721: IERC721NoGameDispatcher,
        steel: IERC20NoGameDispatcher,
        quartz: IERC20NoGameDispatcher,
        tritium: IERC20NoGameDispatcher,
        ETH: IERC20CamelDispatcher,
        pioneer_nft_key: LegacyMap<ContractAddress, felt252>,
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
    fn constructor(ref self: ContractState, owner: ContractAddress) {
        self.owner.write(owner);
    }
}
