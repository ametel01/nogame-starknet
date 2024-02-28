use core::testing::get_available_gas;
use nogame::libraries::types::{
    ERC20s, EnergyCost, TechLevels, TechsCost, ShipsLevels, ShipsCost, Defences, DefencesCost
};

use nogame::planet::planet::{IPlanetDispatcher, IPlanetDispatcherTrait};
use nogame::storage::storage::{IStorageDispatcher, IStorageDispatcherTrait};
use nogame::token::erc20::interface::{IERC20NoGameDispatcher, IERC20NoGameDispatcherTrait};
use nogame::token::erc721::interface::{IERC721NoGameDispatcher, IERC721NoGameDispatcherTrait};
use openzeppelin::token::erc20::interface::{IERC20CamelDispatcher, IERC20CamelDispatcherTrait};

use snforge_std::{declare, ContractClassTrait, start_prank, start_warp,  CheatTarget};
use starknet::info::{get_contract_address, get_block_timestamp};
use starknet::testing::cheatcode;
use starknet::{ContractAddress, contract_address_const};
use tests::utils::{
    E18, HOUR, Dispatchers, ACCOUNT1, ACCOUNT2, DEPLOYER, init_game, set_up, prank_contracts
};

#[test]
fn test_generate() {
    let dsp = set_up();
    init_game(dsp);
    let owner_balance_before = dsp.eth.balanceOf(DEPLOYER());
    let planet_price = dsp.planet.get_current_planet_price();
    prank_contracts(dsp, ACCOUNT1());

    dsp.planet.generate_planet();
    assert(
        dsp.eth.balanceOf(DEPLOYER()) == owner_balance_before + planet_price.into(),
        'planet1 not paid'
    );
    assert(dsp.erc721.balanceOf(ACCOUNT1()).low == 1, 'wrong nft balance');
    assert(dsp.steel.balance_of(ACCOUNT1()).low == 500 * E18, 'wrong steel balance');
    assert(dsp.quartz.balance_of(ACCOUNT1()).low == 300 * E18, 'wrong quartz balance');
    assert(dsp.tritium.balance_of(ACCOUNT1()).low == 100 * E18, 'wrong steel balance');

    let owner_balance_before = dsp.eth.balanceOf(DEPLOYER());
    let planet_price = dsp.planet.get_current_planet_price();
    start_prank(CheatTarget::One(dsp.planet.contract_address), ACCOUNT2());
    dsp.planet.generate_planet();
    assert(
        dsp.eth.balanceOf(DEPLOYER()) == owner_balance_before + planet_price.into(),
        'planet2 not paid'
    );
    assert(dsp.erc721.balanceOf(ACCOUNT2()).low == 1, 'wrong nft balance');
    assert(dsp.steel.balance_of(ACCOUNT2()).low == 500 * E18, 'wrong steel balance');
    assert(dsp.quartz.balance_of(ACCOUNT2()).low == 300 * E18, 'wrong quartz balance');
    assert(dsp.tritium.balance_of(ACCOUNT2()).low == 100 * E18, 'wrong steel balance');
    assert(dsp.storage.get_number_of_planets() == 2, 'wrong n planets');
}

#[test]
fn test_collect_resources() {
    let dsp = set_up();
    init_game(dsp);

    prank_contracts(dsp, ACCOUNT1());
    dsp.planet.generate_planet();
    dsp.planet.collect_resources();
}

#[test]
fn test_collect() {
    let dsp = set_up();
    init_game(dsp);

    prank_contracts(dsp, ACCOUNT1());
    dsp.planet.generate_planet();
}
// #[test]
// fn test_planet_position() {
//     let dsp = set_up();
//     init_game(dsp);
//     let mut len = 1;
//     loop {
//         if len == 3 {
//             break;
//         }
//         start_prank(CheatTarget::All, len.try_into().unwrap());
//         dsp.planet.generate_planet();
//         let position = dsp.planet.get_planet_position((len).try_into().unwrap());
//         assert(position.system <= 200, 'system out of bound');
//         assert(position.orbit <= 10, 'orbit out of bound');
//         len += 1;
//     };
//     let positions = dsp.planet.get_generated_planets_positions();
//     assert(*positions.at(0).orbit == 2 && *positions.at(0).system == 156, 'wrong assertion #1');
//     assert(*positions.at(1).orbit == 9 && *positions.at(1).system == 388, 'wrong assertion #2');
// }


