use core::testing::get_available_gas;
use nogame::libraries::types::{
    Defences, DefencesCost, ERC20s, EnergyCost, ShipsCost, ShipsLevels, TechLevels, TechsCost,
};
use nogame::planet::contract::{IPlanetDispatcher, IPlanetDispatcherTrait};
use nogame::token::erc20::interface::{IERC20NoGameDispatcher, IERC20NoGameDispatcherTrait};
use nogame::token::erc721::interface::{IERC721NoGameDispatcher, IERC721NoGameDispatcherTrait};
use openzeppelin_token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
use snforge_std::{
    ContractClassTrait, declare, start_cheat_block_timestamp_global, start_cheat_caller_address,
    start_cheat_caller_address_global,
};
use starknet::ContractAddress;
use starknet::info::{get_block_timestamp, get_contract_address};
use starknet::testing::cheatcode;
use super::utils::{ACCOUNT1, ACCOUNT2, DEPLOYER, Dispatchers, E18, HOUR, init_game, set_up};

#[test]
fn test_generate() {
    let dsp = set_up();
    init_game(dsp);
    let owner_balance_before = dsp.eth.balance_of(DEPLOYER());
    let planet_price = dsp.planet.get_current_planet_price();
    start_cheat_caller_address(dsp.planet.contract_address, ACCOUNT1());

    dsp.planet.generate_planet();
    assert(
        dsp.eth.balance_of(DEPLOYER()) == owner_balance_before + planet_price.into(),
        'planet1 not paid',
    );
    assert(dsp.erc721.balance_of(ACCOUNT1()).low == 1, 'wrong nft balance');
    assert(dsp.steel.balance_of(ACCOUNT1()).low == 500 * E18, 'wrong steel balance');
    assert(dsp.quartz.balance_of(ACCOUNT1()).low == 300 * E18, 'wrong quartz balance');
    assert(dsp.tritium.balance_of(ACCOUNT1()).low == 100 * E18, 'wrong steel balance');

    let owner_balance_before = dsp.eth.balance_of(DEPLOYER());
    let planet_price = dsp.planet.get_current_planet_price();
    start_cheat_caller_address(dsp.planet.contract_address, ACCOUNT2());
    dsp.planet.generate_planet();
    assert(
        dsp.eth.balance_of(DEPLOYER()) == owner_balance_before + planet_price.into(),
        'planet2 not paid',
    );
    assert(dsp.erc721.balance_of(ACCOUNT2()).low == 1, 'wrong nft balance');
    assert(dsp.steel.balance_of(ACCOUNT2()).low == 500 * E18, 'wrong steel balance');
    assert(dsp.quartz.balance_of(ACCOUNT2()).low == 300 * E18, 'wrong quartz balance');
    assert(dsp.tritium.balance_of(ACCOUNT2()).low == 100 * E18, 'wrong steel balance');
    assert(dsp.planet.get_number_of_planets() == 2, 'wrong n planets');
}

#[test]
fn test_collect_resources() {
    let dsp = set_up();
    init_game(dsp);

    start_cheat_caller_address(dsp.planet.contract_address, ACCOUNT1());
    dsp.planet.generate_planet();

    start_cheat_caller_address(dsp.planet.contract_address, dsp.compound.contract_address);
    dsp.planet.collect_resources(ACCOUNT1());
}

#[test]
fn test_collect() {
    let dsp = set_up();
    init_game(dsp);

    start_cheat_caller_address(dsp.planet.contract_address, ACCOUNT1());
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
//         start_cheat_caller_address(CheatTarget::All, len.try_into().unwrap());
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


