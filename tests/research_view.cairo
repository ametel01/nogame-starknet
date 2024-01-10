use starknet::testing::cheatcode;
use starknet::info::get_contract_address;
use starknet::{ContractAddress, contract_address_const};
use snforge_std::PrintTrait;

use snforge_std::{start_prank, start_warp, CheatTarget};

use nogame::game::interface::{INoGameDispatcher, INoGameDispatcherTrait};
use nogame::game::main::NoGame;
use nogame::libraries::types::{
    ERC20s, EnergyCost, TechLevels, TechsCost, ShipsLevels, ShipsCost, DefencesLevels, DefencesCost, Names
};
use tests::utils::{E18, HOUR, Dispatchers, ACCOUNT1, ACCOUNT2, init_game, set_up};

use nogame::game::main::NoGame::techs_levelContractMemberStateTrait;

#[test]
fn test_get_tech_levels() {
    let mut state = NoGame::contract_state_for_testing(); // <--- Ad. 3
    state.techs_level.write((1,Names::ENERGY_TECH), 10);
    state.techs_level.write((1, Names::THRUST), 20);

    let techs = NoGame::InternalImpl::get_tech_levels(@state, 1);
    assert(techs.energy == 10, 'wrong level');
    assert(techs.digital == 0, 'wrong level');
    assert(techs.beam == 0, 'wrong level');
    assert(techs.armour == 0, 'wrong level');
    assert(techs.ion == 0, 'wrong level');
    assert(techs.plasma == 0, 'wrong level');
    assert(techs.weapons == 0, 'wrong level');
    assert(techs.shield == 0, 'wrong level');
    assert(techs.spacetime == 0, 'wrong level');
    assert(techs.combustion == 0, 'wrong level');
    assert(techs.thrust == 20, 'wrong level');
    assert(techs.warp == 0, 'wrong level');
}

