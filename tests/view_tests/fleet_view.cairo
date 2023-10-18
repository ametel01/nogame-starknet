use starknet::testing::cheatcode;
use starknet::info::get_contract_address;
use starknet::{ContractAddress, contract_address_const};
use snforge_std::io::PrintTrait;

use snforge_std::{start_prank, start_warp};

use nogame::game::interface::{INoGameDispatcher, INoGameDispatcherTrait};
use nogame::libraries::types::{
    ERC20s, EnergyCost, TechLevels, TechsCost, ShipsLevels, ShipsCost, DefencesLevels, DefencesCost
};
use nogame::token::erc20::{INGERC20Dispatcher, INGERC20DispatcherTrait};
use nogame::token::erc721::{INGERC721Dispatcher, INGERC721DispatcherTrait};
use tests::utils::{E18, HOUR, Dispatchers, ACCOUNT1, ACCOUNT2, init_game, set_up};

#[tests]
fn test_is_noob_protected() { // TODO
    assert(0 == 0, 'todo');
}

#[test]
fn test_get_mission_details() { // TODO
    assert(0 == 0, 'todo');
}

#[test]
fn test_get_hostile_missions() { // TODO
    assert(0 == 0, 'todo');
}

#[test]
fn test_get_active_missions() { // TODO
    assert(0 == 0, 'todo');
}

#[test]
fn test_get_travel_time() { // TODO
    assert(0 == 0, 'todo');
}

#[test]
fn test_get_fuel_consumption() { // TODO
    assert(0 == 0, 'todo');
}
