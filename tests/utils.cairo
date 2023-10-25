use array::ArrayTrait;
use starknet::{ContractAddress, contract_address_const, get_block_timestamp, get_contract_address};
use openzeppelin::token::erc20::erc20::ERC20;
use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};

use xoroshiro::xoroshiro::{IXoroshiroDispatcher, IXoroshiroDispatcherTrait, Xoroshiro};

use nogame::game::interface::{INoGameDispatcher, INoGameDispatcherTrait};
use nogame::token::erc20::{INGERC20Dispatcher, INGERC20DispatcherTrait};
use nogame::token::erc721::{INGERC721Dispatcher, INGERC721DispatcherTrait};

use snforge_std::{declare, ContractClassTrait, start_warp, start_prank, stop_prank, io::PrintTrait};

const E18: u128 = 1_000_000_000_000_000_000;
const ETH_SUPPLY: felt252 = 1_000_000_000_000_000_000_000;
const HOUR: u64 = 3_600;
const DAY: u64 = 86_400;
const WEEK: u64 = 604_800;
const YEAR: u64 = 31_557_600;

#[derive(Copy, Drop, Serde)]
struct Dispatchers {
    erc721: INGERC721Dispatcher,
    steel: INGERC20Dispatcher,
    quartz: INGERC20Dispatcher,
    tritium: INGERC20Dispatcher,
    rand: IXoroshiroDispatcher,
    eth: IERC20Dispatcher,
    game: INoGameDispatcher,
}

fn DEPLOYER() -> ContractAddress {
    contract_address_const::<'DEPLOYER'>()
}
fn ACCOUNT1() -> ContractAddress {
    contract_address_const::<1>()
}
fn ACCOUNT2() -> ContractAddress {
    contract_address_const::<2>()
}
fn ACCOUNT3() -> ContractAddress {
    contract_address_const::<3>()
}
fn ACCOUNT4() -> ContractAddress {
    contract_address_const::<4>()
}
fn ACCOUNT5() -> ContractAddress {
    contract_address_const::<5>()
}

fn set_up() -> Dispatchers {
    let contract = declare('NoGame');
    let calldata: Array<felt252> = array![];
    let contract_address = contract.precalculate_address(@calldata);
    start_prank(contract_address, DEPLOYER());
    let _game = contract.deploy(@calldata).unwrap();
    stop_prank(contract_address);

    let contract = declare('NGERC721');
    let calldata: Array<felt252> = array!['nogame-planet', 'NGPL', _game.into()];
    let _erc721 = contract.deploy(@calldata).unwrap();

    let contract = declare('NGERC20');
    let calldata: Array<felt252> = array!['Nogame Steel', 'NGST', _game.into(), _erc721.into()];
    let _steel = contract.deploy(@calldata).unwrap();

    let calldata: Array<felt252> = array!['Nogame Quartz', 'NGQZ', _game.into(), _erc721.into()];
    let _quartz = contract.deploy(@calldata).unwrap();

    let calldata: Array<felt252> = array!['Nogame Tritium', 'NGTR', _game.into(), _erc721.into()];
    let _tritium = contract.deploy(@calldata).unwrap();

    let contract = declare('Xoroshiro');
    let calldata: Array<felt252> = array![81];
    let _xoroshiro = contract.deploy(@calldata).unwrap();

    let contract = declare('ERC20');
    let calldata: Array<felt252> = array!['ETHER', 'ETH', ETH_SUPPLY, 0, DEPLOYER().into()];
    let _eth = contract.deploy(@calldata).expect('failed to deploy eth');

    Dispatchers {
        erc721: INGERC721Dispatcher { contract_address: _erc721 },
        steel: INGERC20Dispatcher { contract_address: _steel },
        quartz: INGERC20Dispatcher { contract_address: _quartz },
        tritium: INGERC20Dispatcher { contract_address: _tritium },
        rand: IXoroshiroDispatcher { contract_address: _xoroshiro },
        eth: IERC20Dispatcher { contract_address: _eth },
        game: INoGameDispatcher { contract_address: _game }
    }
}

fn init_game(dsp: Dispatchers) {
    start_prank(dsp.game.contract_address, DEPLOYER());
    dsp
        .game
        .initializer(
            dsp.erc721.contract_address,
            dsp.steel.contract_address,
            dsp.quartz.contract_address,
            dsp.tritium.contract_address,
            dsp.rand.contract_address,
            dsp.eth.contract_address,
        );
    start_prank(dsp.eth.contract_address, DEPLOYER());
    dsp.eth.transfer(ACCOUNT1(), (10 * E18).into());
    dsp.eth.transfer(ACCOUNT2(), (10 * E18).into());
    dsp.eth.transfer(ACCOUNT3(), (10 * E18).into());
    dsp.eth.transfer(ACCOUNT4(), (10 * E18).into());
    dsp.eth.transfer(ACCOUNT5(), (10 * E18).into());

    start_prank(dsp.eth.contract_address, ACCOUNT1());
    dsp.eth.approve(dsp.game.contract_address, (2 * E18).into());
    stop_prank(dsp.eth.contract_address);

    start_prank(dsp.eth.contract_address, ACCOUNT2());
    dsp.eth.approve(dsp.game.contract_address, (2 * E18).into());
    stop_prank(dsp.eth.contract_address);

    start_prank(dsp.eth.contract_address, ACCOUNT3());
    dsp.eth.approve(dsp.game.contract_address, (2 * E18).into());
    stop_prank(dsp.eth.contract_address);

    start_prank(dsp.eth.contract_address, ACCOUNT4());
    dsp.eth.approve(dsp.game.contract_address, (2 * E18).into());
    stop_prank(dsp.eth.contract_address);

    start_prank(dsp.eth.contract_address, ACCOUNT5());
    dsp.eth.approve(dsp.game.contract_address, (2 * E18).into());
    stop_prank(dsp.eth.contract_address);
}

#[test]
fn test_deploy_and_init() {
    let dsp = set_up();
    init_game(dsp);
    start_prank(dsp.eth.contract_address, dsp.game.contract_address);
    dsp.eth.transfer_from(ACCOUNT1(), DEPLOYER(), 1.into());
}

// builds:
// - steel_mine: 3
// - quartz_mine: 4
// - tritium_mine: 4
// - energy_plant: 6
fn build_basic_mines(game: INoGameDispatcher) {
    warp_multiple(game.contract_address, get_contract_address(), get_block_timestamp() + YEAR);
    game.energy_plant_upgrade();
    game.energy_plant_upgrade();
    game.steel_mine_upgrade();
    game.steel_mine_upgrade();
    game.quartz_mine_upgrade();
    // warp_multiple(game.contract_address, get_contract_address(), get_block_timestamp() + YEAR);
    game.energy_plant_upgrade();
    game.energy_plant_upgrade();
    game.energy_plant_upgrade();
    game.quartz_mine_upgrade();
    game.quartz_mine_upgrade();
    game.quartz_mine_upgrade();
    game.tritium_mine_upgrade();
    game.tritium_mine_upgrade();
    game.tritium_mine_upgrade();
    game.energy_plant_upgrade();
    game.tritium_mine_upgrade();
    game.steel_mine_upgrade();
}

fn advance_game_state(game: INoGameDispatcher) {
    warp_multiple(game.contract_address, get_contract_address(), get_block_timestamp() + YEAR);
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
    game.weapons_development_upgrade();
    game.weapons_development_upgrade();
    game.weapons_development_upgrade(); // weapons #3
    warp_multiple(game.contract_address, get_contract_address(), get_block_timestamp() + YEAR * 3);
}


fn warp_multiple(a: ContractAddress, b: ContractAddress, time: u64) {
    start_warp(a, time);
    start_warp(b, time);
}
