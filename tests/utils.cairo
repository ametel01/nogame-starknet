use array::ArrayTrait;
use starknet::{
    ContractAddress, contract_address_const, get_block_timestamp, get_contract_address,
    get_caller_address, class_hash::ClassHash
};
use openzeppelin::token::erc20::interface::{IERC20CamelDispatcher, IERC20CamelDispatcherTrait};

use cubit::f128::types::fixed::{Fixed, FixedTrait, ONE_u128 as ONE};

use nogame::game::interface::{INoGameDispatcher, INoGameDispatcherTrait};
use nogame::libraries::types::PRICE;
use nogame::token::erc20::interface::{IERC20NoGameDispatcher, IERC20NoGameDispatcherTrait};
use nogame::token::erc20::erc20::ERC20;
use nogame::token::erc721::interface::{IERC721NoGameDispatcher, IERC721NoGameDispatcherTrait};

use snforge_std::{
    declare, ContractClassTrait, start_warp, start_prank, stop_prank, PrintTrait, CheatTarget
};

const E18: u128 = 1_000_000_000_000_000_000;
const ETH_SUPPLY: felt252 = 1_000_000_000_000_000_000_000;
const HOUR: u64 = 3_600;
const DAY: u64 = 86_400;
const WEEK: u64 = 604_800;
const YEAR: u64 = 31_557_600;

#[derive(Copy, Drop, Serde)]
struct Dispatchers {
    erc721: IERC721NoGameDispatcher,
    steel: IERC20NoGameDispatcher,
    quartz: IERC20NoGameDispatcher,
    tritium: IERC20NoGameDispatcher,
    eth: IERC20CamelDispatcher,
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
    let _game = contract.deploy(@calldata).expect('failed nogame');

    let contract = declare('ERC721NoGame');
    let calldata: Array<felt252> = array!['nogame-planet', 'NGPL', _game.into(), DEPLOYER().into()];
    let _erc721 = contract.deploy(@calldata).expect('failed erc721');

    let contract = declare('ERC20NoGame');
    let calldata: Array<felt252> = array!['Nogame Steel', 'NGST', _game.into(), _erc721.into()];
    let _steel = contract.deploy(@calldata).expect('failed steel');

    let calldata: Array<felt252> = array!['Nogame Quartz', 'NGQZ', _game.into(), _erc721.into()];
    let _quartz = contract.deploy(@calldata).expect('failed quartz');

    let calldata: Array<felt252> = array!['Nogame Tritium', 'NGTR', _game.into(), _erc721.into()];
    let _tritium = contract.deploy(@calldata).expect('failed tritium');

    let contract = declare('ERC20');
    let calldata: Array<felt252> = array!['ETHER', 'ETH', ETH_SUPPLY, 0, DEPLOYER().into()];
    let _eth = contract.deploy(@calldata).expect('failed to deploy eth');

    Dispatchers {
        erc721: IERC721NoGameDispatcher { contract_address: _erc721 },
        steel: IERC20NoGameDispatcher { contract_address: _steel },
        quartz: IERC20NoGameDispatcher { contract_address: _quartz },
        tritium: IERC20NoGameDispatcher { contract_address: _tritium },
        eth: IERC20CamelDispatcher { contract_address: _eth },
        game: INoGameDispatcher { contract_address: _game }
    }
}

fn init_game(dsp: Dispatchers) {
    start_prank(CheatTarget::All, DEPLOYER());
    dsp
        .game
        .initializer(
            dsp.erc721.contract_address,
            dsp.steel.contract_address,
            dsp.quartz.contract_address,
            dsp.tritium.contract_address,
            dsp.eth.contract_address,
            DEPLOYER(),
            1,
            ONE,
            false
        );
    start_prank(CheatTarget::One(dsp.eth.contract_address), DEPLOYER());
    dsp.eth.transfer(ACCOUNT1(), (10 * E18).into());
    dsp.eth.transfer(ACCOUNT2(), (10 * E18).into());
    dsp.eth.transfer(ACCOUNT3(), (10 * E18).into());
    dsp.eth.transfer(ACCOUNT4(), (10 * E18).into());
    dsp.eth.transfer(ACCOUNT5(), (10 * E18).into());
    stop_prank(CheatTarget::One(dsp.eth.contract_address));

    start_prank(CheatTarget::One(dsp.eth.contract_address), ACCOUNT1());
    dsp.eth.approve(dsp.game.contract_address, (2 * E18).into());
    stop_prank(CheatTarget::One(dsp.eth.contract_address));

    start_prank(CheatTarget::One(dsp.eth.contract_address), ACCOUNT2());
    dsp.eth.approve(dsp.game.contract_address, (2 * E18).into());
    stop_prank(CheatTarget::One(dsp.eth.contract_address));

    start_prank(CheatTarget::One(dsp.eth.contract_address), ACCOUNT3());
    dsp.eth.approve(dsp.game.contract_address, (2 * E18).into());
    stop_prank(CheatTarget::One(dsp.eth.contract_address));

    start_prank(CheatTarget::One(dsp.eth.contract_address), ACCOUNT4());
    dsp.eth.approve(dsp.game.contract_address, (2 * E18).into());
    stop_prank(CheatTarget::One(dsp.eth.contract_address));

    start_prank(CheatTarget::One(dsp.eth.contract_address), ACCOUNT5());
    dsp.eth.approve(dsp.game.contract_address, (2 * E18).into());
    stop_prank(CheatTarget::One(dsp.eth.contract_address));
    start_prank(CheatTarget::One(dsp.erc721.contract_address), dsp.game.contract_address);
    start_prank(CheatTarget::One(dsp.steel.contract_address), dsp.game.contract_address);
    start_prank(CheatTarget::One(dsp.quartz.contract_address), dsp.game.contract_address);
    start_prank(CheatTarget::One(dsp.tritium.contract_address), dsp.game.contract_address);
}

#[test]
fn test_deploy_and_init() {
    let dsp: Dispatchers = set_up();
    init_game(dsp);
    start_prank(CheatTarget::All, dsp.game.contract_address);
    dsp.eth.transferFrom(ACCOUNT1(), DEPLOYER(), 1.into());
}

// builds:
// - steel_mine: 3
// - quartz_mine: 4
// - tritium_mine: 7
// - energy_plant: 8
fn build_basic_mines(game: INoGameDispatcher) {
    game.energy_plant_upgrade(1);
    game.steel_mine_upgrade(2);
    warp_multiple(game.contract_address, get_contract_address(), get_block_timestamp() + DAY);
    game.energy_plant_upgrade(1);
    game.steel_mine_upgrade(2);
    warp_multiple(game.contract_address, get_contract_address(), get_block_timestamp() + DAY);
    game.energy_plant_upgrade(2);
    game.quartz_mine_upgrade(4);
    warp_multiple(game.contract_address, get_contract_address(), get_block_timestamp() + DAY);
    game.energy_plant_upgrade(4);
    game.tritium_mine_upgrade(6);
    warp_multiple(game.contract_address, get_contract_address(), get_block_timestamp() + WEEK * 4);
}

fn advance_game_state(game: INoGameDispatcher) {
    warp_multiple(game.contract_address, get_contract_address(), get_block_timestamp() + 2 * YEAR);
    game.dockyard_upgrade(8); // dockyard #8
    game.lab_upgrade(7); // lab #7
    game.energy_innovation_upgrade(8); // energy #8
    game.combustive_engine_upgrade(6); // combustive #6
    game.beam_technology_upgrade(10); // beam 10
    game.shield_tech_upgrade(5); // shield #5
    game.thrust_propulsion_upgrade(4); // impulse #4
    game.weapons_development_upgrade(3); // weapons #3
}


fn warp_multiple(a: ContractAddress, b: ContractAddress, time: u64) {
    start_warp(CheatTarget::All, time);
    start_warp(CheatTarget::All, time);
}

fn declare_upgradable() -> ClassHash {
    declare('NoGameUpgraded').class_hash
}

