use starknet::testing::cheatcode;
use starknet::info::get_contract_address;
use starknet::{ContractAddress, contract_address_const};
use snforge_std::PrintTrait;
use snforge_std::{start_prank, start_warp, CheatTarget};

use nogame::game::interface::{INoGameDispatcher, INoGameDispatcherTrait};
use nogame::libraries::compounds::{Production, Compounds};
use nogame::libraries::types::CompoundsLevels;
use tests::utils::{
    E18, HOUR, Dispatchers, ACCOUNT1, ACCOUNT2, ACCOUNT3, ACCOUNT4, ACCOUNT5, init_game, set_up,
    build_basic_mines
};
use nogame::game::main::NoGame;
use nogame::game::main::NoGame::steel_mine_levelContractMemberStateTrait;
use nogame::game::main::NoGame::quartz_mine_levelContractMemberStateTrait;
use nogame::game::main::NoGame::tritium_mine_levelContractMemberStateTrait;
use nogame::game::main::NoGame::energy_plant_levelContractMemberStateTrait;
use nogame::game::main::NoGame::dockyard_levelContractMemberStateTrait;
use nogame::game::main::NoGame::lab_levelContractMemberStateTrait;

#[test]
fn test_get_compounds_levels() {
    let mut state = NoGame::contract_state_for_testing(); // <--- Ad. 3
    state.steel_mine_level.write(1, 1);
    state.quartz_mine_level.write(1, 2);
    state.tritium_mine_level.write(1, 3);
    state.energy_plant_level.write(1, 4);
    state.dockyard_level.write(1, 5);
    state.lab_level.write(1, 6);

    let compounds = NoGame::InternalImpl::get_compounds_levels(@state, 1); // <--- Ad. 2

    assert(compounds.steel == 1, 'wrong steel lev');
    assert(compounds.quartz == 2, 'wrong quartz lev');
    assert(compounds.tritium == 3, 'wrong quartz lev');
    assert(compounds.energy == 4, 'wrong energy lev');
    assert(compounds.dockyard == 5, 'wrong dockyard lev');
    assert(compounds.lab == 6, 'wrong lab lev');
}

#[test]
fn test_get_compounds_upgrade_cost() {
    let mut state = NoGame::contract_state_for_testing();

    let costs = NoGame::InternalImpl::get_compounds_upgrade_cost(@state, 1);
    assert(costs.steel.steel == 60 && costs.steel.quartz == 15, 'wrong steel cost');
    assert(costs.quartz.steel == 48 && costs.quartz.quartz == 24, 'wrong quartz cost');
    assert(costs.tritium.steel == 225 && costs.tritium.quartz == 75, 'wrong tritium cost');
    assert(costs.energy.steel == 75 && costs.energy.quartz == 30, 'wrong energy cost');
    assert(
        costs.lab.steel == 200 && costs.lab.quartz == 400 && costs.lab.tritium == 200,
        'wrong lab cost'
    );
    assert(
        costs.dockyard.steel == 400
            && costs.dockyard.quartz == 200
            && costs.dockyard.tritium == 100,
        'wrong dockyard cost'
    );
}

