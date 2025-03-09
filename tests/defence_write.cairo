use core::testing::get_available_gas;
use nogame::compound::contract::{ICompoundDispatcher, ICompoundDispatcherTrait};
use nogame::defence::contract::{IDefenceDispatcher, IDefenceDispatcherTrait};
use nogame::libraries::types::{
    CompoundUpgradeType, DefenceBuildType, Defences, DefencesCost, ERC20s, EnergyCost,
    ShipBuildType, ShipsCost, ShipsLevels, TechLevels, TechsCost,
};
use nogame::planet::contract::{IPlanetDispatcher, IPlanetDispatcherTrait};
use nogame::token::erc721::interface::{IERC721NoGameDispatcher, IERC721NoGameDispatcherTrait};
use openzeppelin_token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
use snforge_std::{
    ContractClassTrait, declare, start_cheat_block_timestamp_global,
    start_cheat_caller_address_global,
};
use starknet::ContractAddress;
use starknet::info::{get_block_timestamp, get_contract_address};
use starknet::testing::cheatcode;
use super::utils::{
    ACCOUNT1, ACCOUNT2, DEPLOYER, Dispatchers, E18, HOUR, YEAR, init_game, init_storage, set_up,
};

#[test]
fn test_blaster_build() {
    let dsp = set_up();
    init_game(dsp);

    start_cheat_caller_address_global(ACCOUNT1());
    dsp.planet.generate_planet();

    init_storage(dsp, 1);
    start_cheat_block_timestamp_global(HOUR * 2400000);
    dsp.compound.process_upgrade(CompoundUpgradeType::Dockyard(()), 1);

    dsp.defence.process_defence_build(DefenceBuildType::Blaster(()), 10);
    let def = dsp.defence.get_defences_levels(1);
    assert(def.blaster == 10, 'wrong blaster level');
}

#[test]
#[should_panic(expected: ('dockyard 1 required',))]
fn test_blaster_build_fails_dockyard_level() {
    let dsp = set_up();
    init_game(dsp);

    start_cheat_caller_address_global(ACCOUNT1());
    dsp.planet.generate_planet();
    init_storage(dsp, 1);

    dsp.defence.process_defence_build(DefenceBuildType::Blaster(()), 1);
}

#[test]
fn test_beam_build() {
    let dsp = set_up();
    init_game(dsp);

    start_cheat_caller_address_global(ACCOUNT1());
    dsp.planet.generate_planet();
    init_storage(dsp, 1);

    dsp.defence.process_defence_build(DefenceBuildType::Beam(()), 10);
    let def = dsp.defence.get_defences_levels(1);
    assert(def.beam == 10, 'wrong beam level');
}

#[test]
#[should_panic(expected: ('dockyard 4 required',))]
fn test_beam_build_fails_dockyard_level() {
    let dsp = set_up();
    init_game(dsp);

    start_cheat_caller_address_global(ACCOUNT1());
    dsp.planet.generate_planet();
    init_storage(dsp, 1);

    dsp.defence.process_defence_build(DefenceBuildType::Beam(()), 2);
}

#[test]
#[should_panic(expected: ('energy innovation 3 required',))]
fn test_beam_build_fails_energy_tech_level() {
    let dsp = set_up();
    init_game(dsp);

    start_cheat_caller_address_global(ACCOUNT1());
    dsp.planet.generate_planet();
    init_storage(dsp, 1);
    start_cheat_block_timestamp_global(HOUR * 2400000);
    dsp.compound.process_upgrade(CompoundUpgradeType::Dockyard(()), 4);

    dsp.defence.process_defence_build(DefenceBuildType::Beam(()), 2);
}

#[test]
fn test_astral_build_fails_beam_tech_level() {
    // TODO
    assert(0 == 0, 'todo');
}

#[test]
fn test_astral_build_fails_dockyard_level() { // TODO
    assert(0 == 0, 'todo');
}

#[test]
fn test_astral_build_fails_energy_tech_level() { // TODO
    assert(0 == 0, 'todo');
}

#[test]
fn test_astral_build_fails_weapons_tech_level() { // TODO
    assert(0 == 0, 'todo');
}

#[test]
fn test_astral_build_fails_shield_tech_level() { // TODO
    assert(0 == 0, 'todo');
}

#[test]
fn test_plasma_build() {
    let dsp = set_up();
    init_game(dsp);

    start_cheat_caller_address_global(ACCOUNT1());
    dsp.planet.generate_planet();
    init_storage(dsp, 1);

    dsp.defence.process_defence_build(DefenceBuildType::Plasma(()), 1);
    let def = dsp.defence.get_defences_levels(1);
    assert(def.plasma == 1, 'wrong plasma level');
}

#[test]
fn test_plasma_build_fails_dockyard_level() { // TODO
    assert(0 == 0, 'todo');
}

#[test]
fn test_plasma_build_fails_plasma_tech_level() { // TODO
    assert(0 == 0, 'todo');
}

