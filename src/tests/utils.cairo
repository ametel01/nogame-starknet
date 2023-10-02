use array::ArrayTrait;
use starknet::{ContractAddress, contract_address_const, get_block_timestamp};

use xoroshiro::xoroshiro::{IXoroshiroDispatcher, IXoroshiroDispatcherTrait, Xoroshiro};

use nogame::game::interface::{INoGameDispatcher, INoGameDispatcherTrait};
use nogame::token::erc20::{INGERC20Dispatcher, INGERC20DispatcherTrait};
use nogame::token::erc721::{INGERC721Dispatcher, INGERC721DispatcherTrait};

use snforge_std::{declare, ContractClassTrait, start_warp, io::PrintTrait};

const E18: u128 = 1000000000000000000;
const HOUR: u64 = 3600;
const DAY: u64 = 86400;
const WEEK: u64 = 604800;
const YEAR: u64 = 31557600;

#[derive(Copy, Drop, Serde)]
struct Dispatchers {
    erc721: INGERC721Dispatcher,
    steel: INGERC20Dispatcher,
    quartz: INGERC20Dispatcher,
    tritium: INGERC20Dispatcher,
    rand: IXoroshiroDispatcher,
    game: INoGameDispatcher,
}

fn ACCOUNT1() -> ContractAddress {
    contract_address_const::<1>()
}
fn ACCOUNT2() -> ContractAddress {
    contract_address_const::<2>()
}

fn set_up() -> Dispatchers {
    let contract = declare('NoGame');
    let calldata: Array<felt252> = array![];
    let _game = contract.deploy(@calldata).unwrap();

    let contract = declare('NGERC721');
    let calldata: Array<felt252> = array!['nogame-planet', 'NGPL', _game.into()];
    let _erc721 = contract.deploy(@calldata).unwrap();

    let contract = declare('NGERC20');
    let calldata: Array<felt252> = array!['Nogame Steel', 'NGST', _game.into()];
    let _steel = contract.deploy(@calldata).unwrap();

    let calldata: Array<felt252> = array!['Nogame Quartz', 'NGQZ', _game.into()];
    let _quartz = contract.deploy(@calldata).unwrap();

    let calldata: Array<felt252> = array!['Nogame Tritium', 'NGTR', _game.into()];
    let _tritium = contract.deploy(@calldata).unwrap();

    let contract = declare('Xoroshiro');
    let calldata: Array<felt252> = array![81];
    let _xoroshiro = contract.deploy(@calldata).unwrap();

    Dispatchers {
        erc721: INGERC721Dispatcher { contract_address: _erc721 },
        steel: INGERC20Dispatcher { contract_address: _steel },
        quartz: INGERC20Dispatcher { contract_address: _quartz },
        tritium: INGERC20Dispatcher { contract_address: _tritium },
        rand: IXoroshiroDispatcher { contract_address: _xoroshiro },
        game: INoGameDispatcher { contract_address: _game }
    }
}

fn init_game(dsp: Dispatchers) {
    dsp
        .game
        ._initializer(
            dsp.erc721.contract_address,
            dsp.steel.contract_address,
            dsp.quartz.contract_address,
            dsp.tritium.contract_address,
            dsp.rand.contract_address
        )
}

fn build_basic_mines(game: INoGameDispatcher, multiplier: u64) {
    start_warp(game.contract_address, WEEK * multiplier);
    game.energy_plant_upgrade();
    game.energy_plant_upgrade();
    game.steel_mine_upgrade();
    game.steel_mine_upgrade();
    game.quartz_mine_upgrade();
    start_warp(game.contract_address, WEEK * 2 * multiplier);
    game.energy_plant_upgrade();
    game.energy_plant_upgrade();
    game.energy_plant_upgrade();
    game.quartz_mine_upgrade();
    game.quartz_mine_upgrade();
    game.quartz_mine_upgrade();
    start_warp(game.contract_address, WEEK * 3 * multiplier);
    game.tritium_mine_upgrade();
    start_warp(game.contract_address, WEEK * 4 * multiplier);
    game.tritium_mine_upgrade();
    game.tritium_mine_upgrade();
    game.energy_plant_upgrade();
    game.tritium_mine_upgrade();
    game.steel_mine_upgrade();
}

fn advance_game_state(game: INoGameDispatcher, multiplier: u64) {
    start_warp(game.contract_address, YEAR * multiplier);
    game.dockyard_upgrade();
    game.dockyard_upgrade();
    game.dockyard_upgrade();
    game.dockyard_upgrade();
    game.dockyard_upgrade();
    game.dockyard_upgrade();
    game.dockyard_upgrade();
    game.dockyard_upgrade(); // dockyard #8
    game.lab_upgrade();
    game.lab_upgrade();
    game.lab_upgrade();
    game.lab_upgrade();
    game.lab_upgrade();
    game.lab_upgrade();
    game.lab_upgrade(); // lab #7
    game.energy_innovation_upgrade();
    game.energy_innovation_upgrade();
    game.energy_innovation_upgrade();
    game.energy_innovation_upgrade();
    game.energy_innovation_upgrade();
    game.energy_innovation_upgrade();
    game.energy_innovation_upgrade();
    game.energy_innovation_upgrade(); // energy #8
    game.combustive_engine_upgrade();
    game.combustive_engine_upgrade();
    game.combustive_engine_upgrade();
    game.combustive_engine_upgrade();
    game.combustive_engine_upgrade();
    game.combustive_engine_upgrade(); // combustive #6
    game.beam_technology_upgrade();
    game.beam_technology_upgrade();
    game.beam_technology_upgrade();
    game.beam_technology_upgrade();
    game.beam_technology_upgrade();
    game.beam_technology_upgrade();
    game.beam_technology_upgrade();
    game.beam_technology_upgrade();
    game.beam_technology_upgrade();
    game.beam_technology_upgrade(); // beam 10
    game.shield_tech_upgrade();
    game.shield_tech_upgrade();
    game.shield_tech_upgrade();
    game.shield_tech_upgrade();
    game.shield_tech_upgrade(); // shield #5
    game.spacetime_warp_upgrade();
    game.spacetime_warp_upgrade();
    game.spacetime_warp_upgrade(); // spacetime #3
    game.warp_drive_upgrade();
    game.warp_drive_upgrade();
    game.warp_drive_upgrade();
    game.warp_drive_upgrade(); // warp #4
    game.ion_systems_upgrade();
    game.ion_systems_upgrade();
    game.ion_systems_upgrade();
    game.ion_systems_upgrade();
    game.ion_systems_upgrade(); // ion #5
    game.thrust_propulsion_upgrade();
    game.thrust_propulsion_upgrade();
    game.thrust_propulsion_upgrade();
    game.thrust_propulsion_upgrade(); // impulse #4
    game.plasma_engineering_upgrade();
    game.plasma_engineering_upgrade();
    game.plasma_engineering_upgrade();
    game.plasma_engineering_upgrade();
    game.plasma_engineering_upgrade();
    game.plasma_engineering_upgrade();
    game.plasma_engineering_upgrade(); // plasma #7
}
