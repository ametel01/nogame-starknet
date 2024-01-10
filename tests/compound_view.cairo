use starknet::testing::cheatcode;
use starknet::info::get_contract_address;
use starknet::{ContractAddress, contract_address_const};
use snforge_std::PrintTrait;
use snforge_std::{start_prank, start_warp, CheatTarget};

use nogame::game::interface::{INoGameDispatcher, INoGameDispatcherTrait};
use nogame::libraries::compounds::{Production, Compounds};
use nogame::libraries::types::{CompoundsLevels, Names};
use tests::utils::{
    E18, HOUR, Dispatchers, ACCOUNT1, ACCOUNT2, ACCOUNT3, ACCOUNT4, ACCOUNT5, init_game, set_up,
    build_basic_mines
};
use nogame::game::main::NoGame;
use nogame::game::main::NoGame::compounds_levelContractMemberStateTrait;

#[test]
fn test_get_compounds_levels() {
    let mut state = NoGame::contract_state_for_testing(); // <--- Ad. 3
    state.compounds_level.write((1, Names::STEEL), 1);
    state.compounds_level.write((1, Names::QUARTZ),2);
    state.compounds_level.write((1, Names::TRITIUM),3);
    state.compounds_level.write((1, Names::ENERGY_PLANT),4);
    state.compounds_level.write((1, Names::DOCKYARD),5);
    state.compounds_level.write((1,Names::LAB), 6);

    let compounds = NoGame::InternalImpl::get_compounds_levels(@state, 1); // <--- Ad. 2

    assert(compounds.steel == 1, 'wrong steel lev');
    assert(compounds.quartz == 2, 'wrong quartz lev');
    assert(compounds.tritium == 3, 'wrong quartz lev');
    assert(compounds.energy == 4, 'wrong energy lev');
    assert(compounds.dockyard == 5, 'wrong dockyard lev');
    assert(compounds.lab == 6, 'wrong lab lev');
}


