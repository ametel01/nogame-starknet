use array::ArrayTrait;
use core::testing::get_available_gas;
use option::OptionTrait;
use result::ResultTrait;
use traits::Into;
use traits::TryInto;
use starknet::testing::cheatcode;
use starknet::info::get_contract_address;
use starknet::{ContractAddress, contract_address_const};

use forge_print::PrintTrait;
use cheatcodes::start_prank;

use nogame::game::interface::{INoGameDispatcher, INoGameDispatcherTrait};
use nogame::game::library::{
    ERC20s, EnergyCost, TechLevels, TechsCost, LeaderBoard, ShipsLevels, ShipsCost, DefencesLevels,
    DefencesCost
};
use nogame::token::erc20::{INGERC20Dispatcher, INGERC20DispatcherTrait};
use nogame::token::erc721::{INGERC721Dispatcher, INGERC721DispatcherTrait};

const E18: u128 = 1000000000000000000;
const HOUR: u64 = 3600;

#[test]
fn test_generate() {
    let dsp = set_up();
    init_game(dsp);

    start_prank(dsp.game.contract_address, ACCOUNT1());
    dsp.game.generate_planet();
    assert(dsp.erc721.balance_of(ACCOUNT1()).low == 1, 'wrong nft balance');
    assert(dsp.steel.balance_of(ACCOUNT1()).low == 500 * E18, 'wrong steel balance');
    assert(dsp.quartz.balance_of(ACCOUNT1()).low == 300 * E18, 'wrong quartz balance');
    assert(dsp.tritium.balance_of(ACCOUNT1()).low == 100 * E18, 'wrong steel balance');

    start_prank(dsp.game.contract_address, ACCOUNT2());
    dsp.game.generate_planet();
    assert(dsp.erc721.balance_of(ACCOUNT2()).low == 1, 'wrong nft balance');
    assert(dsp.steel.balance_of(ACCOUNT2()).low == 500 * E18, 'wrong steel balance');
    assert(dsp.quartz.balance_of(ACCOUNT2()).low == 300 * E18, 'wrong quartz balance');
    assert(dsp.tritium.balance_of(ACCOUNT2()).low == 100 * E18, 'wrong steel balance');
    assert(dsp.game.get_number_of_planets() == 2, 'wrong n planets');
}

#[test]
fn test_collect_resources() {
    let dsp = set_up();
    init_game(dsp);

    start_prank(dsp.game.contract_address, ACCOUNT1());
    dsp.game.generate_planet();

    dsp.game.collect_resources();
}

#[test]
fn test_steel_mine_upgrade() {
    let dsp = set_up();
    init_game(dsp);

    start_prank(dsp.game.contract_address, ACCOUNT1());
    dsp.game.generate_planet();

    dsp.game.steel_mine_upgrade();
    let compounds = dsp.game.get_compounds_levels(1);
    assert(compounds.steel == 1, 'wrong steel level');
}

#[test]
fn test_quartz_mine_upgrade() {
    let dsp = set_up();
    init_game(dsp);

    start_prank(dsp.game.contract_address, ACCOUNT1());
    dsp.game.generate_planet();

    dsp.game.quartz_mine_upgrade();
    let compounds = dsp.game.get_compounds_levels(1);
    assert(compounds.quartz == 1, 'wrong quartz level');
}

#[test]
fn test_tritium_mine_upgrade() {
    let dsp = set_up();
    init_game(dsp);

    start_prank(dsp.game.contract_address, ACCOUNT1());
    dsp.game.generate_planet();

    dsp.game.tritium_mine_upgrade();
    let compounds = dsp.game.get_compounds_levels(1);
    assert(compounds.tritium == 1, 'wrong tritium level');
}

#[test]
fn test_energy_plant_upgrade() {
    let dsp = set_up();
    init_game(dsp);

    start_prank(dsp.game.contract_address, ACCOUNT1());
    dsp.game.generate_planet();

    dsp.game.energy_plant_upgrade();
    let compounds = dsp.game.get_compounds_levels(1);
    assert(compounds.energy == 1, 'wrong plant level');
}

#[test]
fn test_dockyard_upgrade() {
    let dsp = set_up();
    init_game(dsp);

    start_prank(dsp.game.contract_address, ACCOUNT1());
    dsp.game.generate_planet();

    dsp.game.dockyard_upgrade();
    let compounds = dsp.game.get_compounds_levels(1);
    assert(compounds.dockyard == 1, 'wrong dockyard level');
}

#[test]
fn test_lab_upgrade() {
    let dsp = set_up();
    init_game(dsp);

    start_prank(dsp.game.contract_address, ACCOUNT1());
    dsp.game.generate_planet();

    dsp.game.energy_plant_upgrade();
    dsp.game.tritium_mine_upgrade();
    start_warp(dsp.game.contract_address, HOUR * 240);
    dsp.game.lab_upgrade();
    let compounds = dsp.game.get_compounds_levels(1);
    assert(compounds.lab == 1, 'wrong lab level');
}

#[test]
fn test_energy_upgrade() {
    let dsp = set_up();
    init_game(dsp);

    start_prank(dsp.game.contract_address, ACCOUNT1());
    dsp.game.generate_planet();

    dsp.game.energy_plant_upgrade();
    dsp.game.tritium_mine_upgrade();
    start_warp(dsp.game.contract_address, HOUR * 2400000);
    dsp.game.lab_upgrade();

    dsp.game.energy_innovation_upgrade();
    let techs = dsp.game.get_techs_levels(1);
    assert(techs.energy == 1, 'wrong energy level');
}

#[test]
fn test_digital_upgrade() {
    let dsp = set_up();
    init_game(dsp);

    start_prank(dsp.game.contract_address, ACCOUNT1());
    dsp.game.generate_planet();

    dsp.game.energy_plant_upgrade();
    dsp.game.tritium_mine_upgrade();
    start_warp(dsp.game.contract_address, HOUR * 2400000);
    dsp.game.lab_upgrade();

    dsp.game.digital_systems_upgrade();
    let techs = dsp.game.get_techs_levels(1);
    assert(techs.digital == 1, 'wrong digital level');
}

#[test]
fn test_beam_upgrade() {
    let dsp = set_up();
    init_game(dsp);

    start_prank(dsp.game.contract_address, ACCOUNT1());
    dsp.game.generate_planet();

    dsp.game.energy_plant_upgrade();
    dsp.game.tritium_mine_upgrade();
    start_warp(dsp.game.contract_address, HOUR * 2400000);
    dsp.game.lab_upgrade();
    dsp.game.energy_innovation_upgrade();
    dsp.game.energy_innovation_upgrade();

    dsp.game.beam_technology_upgrade();
    let techs = dsp.game.get_techs_levels(1);
    assert(techs.beam == 1, 'wrong beam level');
}

#[test]
fn test_armour_upgrade() {
    let dsp = set_up();
    init_game(dsp);

    start_prank(dsp.game.contract_address, ACCOUNT1());
    dsp.game.generate_planet();

    dsp.game.energy_plant_upgrade();
    dsp.game.tritium_mine_upgrade();
    start_warp(dsp.game.contract_address, HOUR * 2400000);
    dsp.game.lab_upgrade();
    dsp.game.lab_upgrade();

    dsp.game.armour_innovation_upgrade();
    let techs = dsp.game.get_techs_levels(1);
    assert(techs.armour == 1, 'wrong armour level');
}

#[test]
fn test_weapons_upgrade() {
    let dsp = set_up();
    init_game(dsp);

    start_prank(dsp.game.contract_address, ACCOUNT1());
    dsp.game.generate_planet();

    dsp.game.energy_plant_upgrade();
    dsp.game.tritium_mine_upgrade();
    start_warp(dsp.game.contract_address, HOUR * 2400000);
    dsp.game.lab_upgrade();
    dsp.game.lab_upgrade();
    dsp.game.lab_upgrade();
    dsp.game.lab_upgrade();

    dsp.game.weapons_development_upgrade();
    let techs = dsp.game.get_techs_levels(1);
    assert(techs.weapons == 1, 'wrong weapons level');
}

#[test]
fn test_combustion_upgrade() {
    let dsp = set_up();
    init_game(dsp);

    start_prank(dsp.game.contract_address, ACCOUNT1());
    dsp.game.generate_planet();

    dsp.game.energy_plant_upgrade();
    dsp.game.tritium_mine_upgrade();
    start_warp(dsp.game.contract_address, HOUR * 2400000);
    dsp.game.lab_upgrade();
    dsp.game.energy_innovation_upgrade();

    dsp.game.combustive_engine_upgrade();
    let techs = dsp.game.get_techs_levels(1);
    assert(techs.combustion == 1, 'wrong combustion level');
}

#[test]
fn test_thrust_upgrade() {
    let dsp = set_up();
    init_game(dsp);

    start_prank(dsp.game.contract_address, ACCOUNT1());
    dsp.game.generate_planet();

    dsp.game.energy_plant_upgrade();
    dsp.game.tritium_mine_upgrade();
    start_warp(dsp.game.contract_address, HOUR * 2400000);
    dsp.game.lab_upgrade();
    dsp.game.lab_upgrade();
    dsp.game.energy_innovation_upgrade();

    dsp.game.thrust_propulsion_upgrade();
    let techs = dsp.game.get_techs_levels(1);
    assert(techs.thrust == 1, 'wrong thrust level');
}

#[test]
fn test_warp_upgrade() {
    let dsp = set_up();
    init_game(dsp);

    start_prank(dsp.game.contract_address, ACCOUNT1());
    dsp.game.generate_planet();

    dsp.game.energy_plant_upgrade();
    dsp.game.tritium_mine_upgrade();
    start_warp(dsp.game.contract_address, HOUR * 2400000);
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
    let techs = dsp.game.get_techs_levels(1);
    assert(techs.warp == 1, 'wrong warp level');
}

#[test]
fn test_shield_upgrade() {
    let dsp = set_up();
    init_game(dsp);

    start_prank(dsp.game.contract_address, ACCOUNT1());
    dsp.game.generate_planet();

    dsp.game.energy_plant_upgrade();
    dsp.game.tritium_mine_upgrade();
    start_warp(dsp.game.contract_address, HOUR * 2400000);
    dsp.game.lab_upgrade();
    dsp.game.lab_upgrade();
    dsp.game.lab_upgrade();
    dsp.game.lab_upgrade();
    dsp.game.lab_upgrade();
    dsp.game.lab_upgrade();
    dsp.game.energy_innovation_upgrade();
    dsp.game.energy_innovation_upgrade();
    dsp.game.energy_innovation_upgrade();

    dsp.game.shield_tech_upgrade();
    let techs = dsp.game.get_techs_levels(1);
    assert(techs.shield == 1, 'wrong shield level');
}

#[test]
fn test_spacetime_upgrade() {
    let dsp = set_up();
    init_game(dsp);

    start_prank(dsp.game.contract_address, ACCOUNT1());
    dsp.game.generate_planet();

    dsp.game.energy_plant_upgrade();
    dsp.game.tritium_mine_upgrade();
    start_warp(dsp.game.contract_address, HOUR * 2400000);
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
    let techs = dsp.game.get_techs_levels(1);
    assert(techs.spacetime == 1, 'wrong spacetime level');
}

#[test]
fn test_ion_upgrade() {
    let dsp = set_up();
    init_game(dsp);

    start_prank(dsp.game.contract_address, ACCOUNT1());
    dsp.game.generate_planet();

    dsp.game.energy_plant_upgrade();
    dsp.game.tritium_mine_upgrade();
    start_warp(dsp.game.contract_address, HOUR * 2400000);
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
    let techs = dsp.game.get_techs_levels(1);
    assert(techs.ion == 1, 'wrong ion level');
}

#[test]
fn test_plasma_upgrade() {
    let dsp = set_up();
    init_game(dsp);

    start_prank(dsp.game.contract_address, ACCOUNT1());
    dsp.game.generate_planet();

    dsp.game.energy_plant_upgrade();
    dsp.game.tritium_mine_upgrade();
    start_warp(dsp.game.contract_address, HOUR * 2400000);
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
    dsp.game.energy_innovation_upgrade();
    dsp.game.energy_innovation_upgrade();
    dsp.game.beam_technology_upgrade();
    dsp.game.beam_technology_upgrade();
    dsp.game.beam_technology_upgrade();
    dsp.game.beam_technology_upgrade();
    dsp.game.beam_technology_upgrade();
    dsp.game.beam_technology_upgrade();
    dsp.game.beam_technology_upgrade();
    dsp.game.beam_technology_upgrade();
    dsp.game.beam_technology_upgrade();
    dsp.game.beam_technology_upgrade();
    dsp.game.ion_systems_upgrade();
    dsp.game.ion_systems_upgrade();
    dsp.game.ion_systems_upgrade();
    dsp.game.ion_systems_upgrade();
    dsp.game.ion_systems_upgrade();

    dsp.game.plasma_engineering_upgrade();
    let techs = dsp.game.get_techs_levels(1);
    assert(techs.plasma == 1, 'wrong plasma level');
}

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
    assert(ships.celestia == 10, 'wrong celestia level');
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
    dsp.game.dockyard_upgrade();
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
    dsp.game.energy_innovation_upgrade();
    dsp.game.energy_innovation_upgrade();
    dsp.game.beam_technology_upgrade();
    dsp.game.beam_technology_upgrade();
    dsp.game.beam_technology_upgrade();
    dsp.game.beam_technology_upgrade();
    dsp.game.beam_technology_upgrade();
    dsp.game.beam_technology_upgrade();
    dsp.game.beam_technology_upgrade();
    dsp.game.beam_technology_upgrade();
    dsp.game.beam_technology_upgrade();
    dsp.game.beam_technology_upgrade();
    dsp.game.ion_systems_upgrade();
    dsp.game.ion_systems_upgrade();
    dsp.game.ion_systems_upgrade();
    dsp.game.ion_systems_upgrade();
    dsp.game.ion_systems_upgrade();
    dsp.game.plasma_engineering_upgrade();
    dsp.game.plasma_engineering_upgrade();
    dsp.game.plasma_engineering_upgrade();
    dsp.game.plasma_engineering_upgrade();
    dsp.game.plasma_engineering_upgrade();
    dsp.game.plasma_engineering_upgrade();
    dsp.game.plasma_engineering_upgrade();

    dsp.game.plasma_projector_build(10);
    let def = dsp.game.get_defences_levels(1);
    assert(def.plasma == 10, 'wrong plasma level');
}

fn ACCOUNT1() -> ContractAddress {
    contract_address_const::<1>()
}
fn ACCOUNT2() -> ContractAddress {
    contract_address_const::<2>()
}

#[derive(Copy, Drop, Serde)]
struct Dispatchers {
    erc721: INGERC721Dispatcher,
    steel: INGERC20Dispatcher,
    quartz: INGERC20Dispatcher,
    tritium: INGERC20Dispatcher,
    game: INoGameDispatcher,
}

fn set_up() -> Dispatchers {
    let class_hash = declare('NoGame');
    let prepared = PreparedContract {
        class_hash: class_hash, constructor_calldata: @ArrayTrait::new()
    };
    let _game = deploy(prepared).unwrap();

    let class_hash = declare('NGERC721');
    let mut call_data = array!['nogame-planet', 'NGPL', _game.into()];
    let prepared = PreparedContract { class_hash: class_hash, constructor_calldata: @call_data };
    let _erc721 = deploy(prepared).unwrap();

    let class_hash = declare('NGERC20');
    let mut call_data = array!['Nogame Steel', 'NGST', _game.into()];
    let prepared = PreparedContract { class_hash: class_hash, constructor_calldata: @call_data };
    let _steel = deploy(prepared).unwrap();

    let mut call_data = array!['Nogame Quartz', 'NGQZ', _game.into()];
    let prepared = PreparedContract { class_hash: class_hash, constructor_calldata: @call_data };
    let _quartz = deploy(prepared).unwrap();

    let mut call_data = array!['Nogame Tritium', 'NGTR', _game.into()];
    let prepared = PreparedContract { class_hash: class_hash, constructor_calldata: @call_data };
    let _tritium = deploy(prepared).unwrap();

    Dispatchers {
        erc721: INGERC721Dispatcher {
            contract_address: _erc721
            }, steel: INGERC20Dispatcher {
            contract_address: _steel
            }, quartz: INGERC20Dispatcher {
            contract_address: _quartz
            }, tritium: INGERC20Dispatcher {
            contract_address: _tritium
            }, game: INoGameDispatcher {
            contract_address: _game
        }
    }
}

fn init_game(dsp: Dispatchers) {
    dsp
        .game
        ._initializer(
            dsp.erc721.contract_address,
            dsp.steel.contract_address,
            dsp.quartz.contract_address,
            dsp.tritium.contract_address
        )
}
