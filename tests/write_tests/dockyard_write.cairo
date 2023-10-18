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
fn test_carrier_build() {
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
    dsp.game.combustive_engine_upgrade();
    dsp.game.combustive_engine_upgrade();

    dsp.game.carrier_build(10);
    let ships = dsp.game.get_ships_levels(1);
    assert(ships.carrier == 10, 'wrong carrier level');
}

#[test]
fn test_celestia_build() {
    let dsp = set_up();
    init_game(dsp);

    start_prank(dsp.game.contract_address, ACCOUNT1());
    dsp.game.generate_planet();

    dsp.game.energy_plant_upgrade();
    dsp.game.tritium_mine_upgrade();
    start_warp(dsp.game.contract_address, HOUR * 2400000);
    dsp.game.dockyard_upgrade();
    dsp.game.lab_upgrade();
    dsp.game.energy_innovation_upgrade();
    dsp.game.combustive_engine_upgrade();

    dsp.game.celestia_build(10);
    let ships = dsp.game.get_ships_levels(1);
}

#[test]
fn test_sparrow_build() {
    let dsp = set_up();
    init_game(dsp);

    start_prank(dsp.game.contract_address, ACCOUNT1());
    dsp.game.generate_planet();

    dsp.game.energy_plant_upgrade();
    dsp.game.tritium_mine_upgrade();
    start_warp(dsp.game.contract_address, HOUR * 2400000);
    dsp.game.dockyard_upgrade();
    dsp.game.lab_upgrade();
    dsp.game.energy_innovation_upgrade();
    dsp.game.combustive_engine_upgrade();

    dsp.game.sparrow_build(10);
    let ships = dsp.game.get_ships_levels(1);
    assert(ships.sparrow == 10, 'wrong sparrow level');
}

#[test]
fn test_scraper_build() {
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
    dsp.game.lab_upgrade();
    dsp.game.energy_innovation_upgrade();
    dsp.game.combustive_engine_upgrade();
    dsp.game.combustive_engine_upgrade();
    dsp.game.combustive_engine_upgrade();
    dsp.game.combustive_engine_upgrade();
    dsp.game.combustive_engine_upgrade();
    dsp.game.combustive_engine_upgrade();
    dsp.game.lab_upgrade();
    dsp.game.lab_upgrade();
    dsp.game.lab_upgrade();
    dsp.game.lab_upgrade();
    dsp.game.lab_upgrade();
    dsp.game.energy_innovation_upgrade();
    dsp.game.energy_innovation_upgrade();
    dsp.game.shield_tech_upgrade();
    dsp.game.shield_tech_upgrade();

    dsp.game.scraper_build(10);
    let ships = dsp.game.get_ships_levels(1);
    assert(ships.scraper == 10, 'wrong scraper level');
}

#[test]
fn test_frigate_build() {
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
    dsp.game.lab_upgrade();
    dsp.game.lab_upgrade();
    dsp.game.lab_upgrade();
    dsp.game.lab_upgrade();
    dsp.game.energy_innovation_upgrade();
    dsp.game.energy_innovation_upgrade();
    dsp.game.energy_innovation_upgrade();
    dsp.game.energy_innovation_upgrade();
    dsp.game.beam_technology_upgrade();
    dsp.game.beam_technology_upgrade();
    dsp.game.beam_technology_upgrade();
    dsp.game.beam_technology_upgrade();
    dsp.game.beam_technology_upgrade();
    dsp.game.ion_systems_upgrade();
    dsp.game.ion_systems_upgrade();
    dsp.game.thrust_propulsion_upgrade();
    dsp.game.thrust_propulsion_upgrade();
    dsp.game.thrust_propulsion_upgrade();
    dsp.game.thrust_propulsion_upgrade();

    dsp.game.frigate_build(10);
    let ships = dsp.game.get_ships_levels(1);
    assert(ships.frigate == 10, 'wrong frigate level');
}

#[test]
fn test_armade_build() {
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
    dsp.game.lab_upgrade();
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
    dsp.game.shield_tech_upgrade();
    dsp.game.shield_tech_upgrade();
    dsp.game.shield_tech_upgrade();
    dsp.game.shield_tech_upgrade();
    dsp.game.shield_tech_upgrade();
    dsp.game.spacetime_warp_upgrade();
    dsp.game.spacetime_warp_upgrade();
    dsp.game.spacetime_warp_upgrade();
    dsp.game.warp_drive_upgrade();
    dsp.game.warp_drive_upgrade();
    dsp.game.warp_drive_upgrade();
    dsp.game.warp_drive_upgrade();

    dsp.game.armade_build(10);
    let ships = dsp.game.get_ships_levels(1);
    assert(ships.armade == 10, 'wrong armade level');
}