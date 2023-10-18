use core::testing::get_available_gas;
use starknet::testing::cheatcode;
use starknet::info::{get_contract_address, get_block_timestamp};
use starknet::{ContractAddress, contract_address_const};
use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};

use snforge_std::{declare, ContractClassTrait, start_prank, start_warp, io::PrintTrait};

use nogame::game::interface::{INoGameDispatcher, INoGameDispatcherTrait};
use nogame::libraries::types::{
    ERC20s, EnergyCost, TechLevels, TechsCost, ShipsLevels, ShipsCost, DefencesLevels, DefencesCost
};
use nogame::token::erc20::{INGERC20Dispatcher, INGERC20DispatcherTrait};
use nogame::token::erc721::{INGERC721Dispatcher, INGERC721DispatcherTrait};
use tests::utils::{E18, HOUR, Dispatchers, ACCOUNT1, ACCOUNT2, DEPLOYER, init_game, set_up};

#[test]
fn test_blaster_build() {
    let dsp = set_up();
    init_game(dsp);

    start_prank(dsp.game.contract_address, ACCOUNT1());
    dsp.game.generate_planet();

    dsp.game.energy_plant_upgrade();
    dsp.game.tritium_mine_upgrade();
    start_warp(dsp.game.contract_address, HOUR * 2400000);
    dsp.game.dockyard_upgrade();

    dsp.game.blaster_build(10);
    let def = dsp.game.get_defences_levels(1);
    assert(def.blaster == 10, 'wrong blaster level');
}

#[test]
fn test_beam_build() {
    let dsp = set_up();
    init_game(dsp);

    start_prank(dsp.game.contract_address, ACCOUNT1());
    dsp.game.generate_planet();

    dsp.game.energy_plant_upgrade();
    dsp.game.tritium_mine_upgrade();
    start_warp(dsp.game.contract_address, HOUR * 2400000);
    dsp.game.dockyard_upgrade();
    dsp.game.dockyard_upgrade();
    dsp.game.lab_upgrade();
    dsp.game.energy_innovation_upgrade();
    dsp.game.energy_innovation_upgrade();
    dsp.game.beam_technology_upgrade();
    dsp.game.beam_technology_upgrade();
    dsp.game.beam_technology_upgrade();

    dsp.game.beam_build(10);
    let def = dsp.game.get_defences_levels(1);
    assert(def.beam == 10, 'wrong beam level');
}

fn test_astral_build() {
    let dsp = set_up();
    init_game(dsp);

    start_prank(dsp.game.contract_address, ACCOUNT1());
    dsp.game.generate_planet();

    dsp.game.energy_plant_upgrade();
    dsp.game.tritium_mine_upgrade();
    start_warp(dsp.game.contract_address, HOUR * 2400000);
    dsp.game.dockyard_upgrade();
    dsp.game.dockyard_upgrade();
    dsp.game.dockyard_upgrade();
    dsp.game.dockyard_upgrade();
    dsp.game.dockyard_upgrade();
    dsp.game.dockyard_upgrade();
    dsp.game.lab_upgrade();
    dsp.game.lab_upgrade();
    dsp.game.lab_upgrade();
    dsp.game.lab_upgrade();
    dsp.game.lab_upgrade();
    dsp.game.lab_upgrade();
    dsp.game.energy_innovation_upgrade();
    dsp.game.energy_innovation_upgrade();
    dsp.game.energy_innovation_upgrade();
    dsp.game.energy_innovation_upgrade();
    dsp.game.energy_innovation_upgrade();
    dsp.game.energy_innovation_upgrade();
    dsp.game.armour_innovation_upgrade();
    dsp.game.armour_innovation_upgrade();
    dsp.game.armour_innovation_upgrade();
    dsp.game.beam_technology_upgrade();
    dsp.game.beam_technology_upgrade();
    dsp.game.beam_technology_upgrade();
    dsp.game.shield_tech_upgrade();

    dsp.game.astral_launcher_build(10);
    let def = dsp.game.get_defences_levels(1);
    assert(def.astral == 10, 'wrong astral level');
}

fn test_plasma_build() {
    let dsp = set_up();
    init_game(dsp);

    start_prank(dsp.game.contract_address, ACCOUNT1());
    dsp.game.generate_planet();

    dsp.game.energy_plant_upgrade();
    dsp.game.tritium_mine_upgrade();
    start_warp(dsp.game.contract_address, HOUR * 2400000);
    dsp.game.dockyard_upgrade();
    dsp.game.dockyard_upgrade();
    dsp.game.dockyard_upgrade();
    dsp.game.dockyard_upgrade();
    dsp.game.dockyard_upgrade();
    dsp.game.dockyard_upgrade();
    dsp.game.dockyard_upgrade();
    dsp.game.dockyard_upgrade(); // dockyard #8
    dsp.game.lab_upgrade();
    dsp.game.lab_upgrade();
    dsp.game.lab_upgrade();
    dsp.game.lab_upgrade(); // lab #4
    dsp.game.energy_innovation_upgrade();
    dsp.game.energy_innovation_upgrade();
    dsp.game.energy_innovation_upgrade();
    dsp.game.energy_innovation_upgrade();
    dsp.game.energy_innovation_upgrade();
    dsp.game.energy_innovation_upgrade();
    dsp.game.energy_innovation_upgrade();
    dsp.game.energy_innovation_upgrade(); // energy #8
    dsp.game.beam_technology_upgrade();
    dsp.game.beam_technology_upgrade();
    dsp.game.beam_technology_upgrade();
    dsp.game.beam_technology_upgrade();
    dsp.game.beam_technology_upgrade();
    dsp.game.beam_technology_upgrade();
    dsp.game.beam_technology_upgrade();
    dsp.game.beam_technology_upgrade();
    dsp.game.beam_technology_upgrade();
    dsp.game.beam_technology_upgrade(); // beam 10
    dsp.game.ion_systems_upgrade();
    dsp.game.ion_systems_upgrade();
    dsp.game.ion_systems_upgrade();
    dsp.game.ion_systems_upgrade();
    dsp.game.ion_systems_upgrade(); // ion #5
    dsp.game.plasma_engineering_upgrade();
    dsp.game.plasma_engineering_upgrade();
    dsp.game.plasma_engineering_upgrade();
    dsp.game.plasma_engineering_upgrade();
    dsp.game.plasma_engineering_upgrade();
    dsp.game.plasma_engineering_upgrade();
    dsp.game.plasma_engineering_upgrade(); // plasma #7

    dsp.game.plasma_projector_build(10);
    let def = dsp.game.get_defences_levels(1);
    assert(def.plasma == 10, 'wrong plasma level');
}