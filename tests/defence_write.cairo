use core::testing::get_available_gas;
use nogame::compound::compound::{ICompoundDispatcher, ICompoundDispatcherTrait};
use nogame::defence::defence::{IDefenceDispatcher, IDefenceDispatcherTrait};
use nogame::libraries::types::{
    ERC20s, EnergyCost, TechLevels, TechsCost, ShipsLevels, ShipsCost, Defences, DefencesCost,
    ShipBuildType, DefenceBuildType, CompoundUpgradeType
};

use nogame::planet::planet::{IPlanetDispatcher, IPlanetDispatcherTrait};
use nogame::storage::storage::{IStorageDispatcher, IStorageDispatcherTrait};
use nogame::token::erc721::interface::{IERC721NoGameDispatcher, IERC721NoGameDispatcherTrait};
use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};

use snforge_std::{declare, ContractClassTrait, start_prank, start_warp, PrintTrait, CheatTarget};
use starknet::info::{get_contract_address, get_block_timestamp};
use starknet::testing::cheatcode;
use starknet::{ContractAddress, contract_address_const};
use tests::utils::{
    E18, HOUR, Dispatchers, ACCOUNT1, ACCOUNT2, DEPLOYER, init_game, set_up, YEAR, warp_multiple,
    init_storage, prank_contracts
};

#[test]
fn test_blaster_build() {
    let dsp = set_up();
    init_game(dsp);

    prank_contracts(dsp, ACCOUNT1());
    dsp.planet.generate_planet();

    init_storage(dsp, 1);
    start_warp(CheatTarget::All, HOUR * 2400000);
    dsp.compound.process_upgrade(CompoundUpgradeType::Dockyard(()), 1);

    dsp.defence.process_defence_build(DefenceBuildType::Blaster(()), 10);
    let def = dsp.storage.get_defences_levels(1);
    assert(def.blaster == 10, 'wrong blaster level');
}

// #[test]
// #[should_panic(expected: ('dockyard 1 required',))]
// fn test_blaster_build_fails_dockyard_level() {
//     let dsp = set_up();
//     init_game(dsp);

//     prank_contracts(dsp, ACCOUNT1());
//     dsp.planet.generate_planet();
//     init_storage(dsp, 1);

//     dsp.defence.process_defence_build(DefenceBuildType::Blaster(()), 1);
// }

#[test]
fn test_beam_build() {
    let dsp = set_up();
    init_game(dsp);

    prank_contracts(dsp, ACCOUNT1());
    dsp.planet.generate_planet();
    init_storage(dsp, 1);

    dsp.defence.process_defence_build(DefenceBuildType::Beam(()), 10);
    let def = dsp.storage.get_defences_levels(1);
    assert(def.beam == 10, 'wrong beam level');
}

// #[test]
// #[should_panic(expected: ('dockyard 4 required',))]
// fn test_beam_build_fails_dockyard_level() {
//     let dsp = set_up();
//     init_game(dsp);

//     prank_contracts(dsp, ACCOUNT1());
//     dsp.planet.generate_planet();
//     init_storage(dsp, 1);

//     dsp.defence.process_defence_build(DefenceBuildType::Beam(()), 2);
// }

// #[test]
// #[should_panic(expected: ('energy innovation 3 required',))]
// fn test_beam_build_fails_energy_tech_level() {
//     let dsp = set_up();
//     init_game(dsp);

//     prank_contracts(dsp, ACCOUNT1());
//     dsp.planet.generate_planet();
//     init_storage(dsp, 1);
//     warp_multiple(
//         dsp.planet.contract_address, get_contract_address(), get_block_timestamp() + YEAR
//     );
//     dsp.compound.process_upgrade(CompoundUpgradeType::Dockyard(()), 4);

//     dsp.defence.process_defence_build(DefenceBuildType::Beam(()), 2);
// }

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

    prank_contracts(dsp, ACCOUNT1());
    dsp.planet.generate_planet();
    init_storage(dsp, 1);

    dsp.defence.process_defence_build(DefenceBuildType::Plasma(()), 1);
    let def = dsp.storage.get_defences_levels(1);
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

