use debug::PrintTrait;
use starknet::testing::cheatcode;
use starknet::info::get_contract_address;
use starknet::{ContractAddress, contract_address_const};

use snforge_std::{start_prank, start_warp};

use nogame::game::game_interface::{INoGameDispatcher, INoGameDispatcherTrait};
use nogame::game::game_library::{
    ERC20s, EnergyCost, TechLevels, TechsCost, LeaderBoard, ShipsLevels, ShipsCost, DefencesLevels,
    DefencesCost
};
use nogame::token::token_erc20::{INGERC20Dispatcher, INGERC20DispatcherTrait};
use nogame::token::token_erc721::{INGERC721Dispatcher, INGERC721DispatcherTrait};
use nogame::test::utils::{E18, HOUR, Dispatchers, ACCOUNT1, ACCOUNT2, init_game, set_up};

#[test]
fn test_get_token_addresses() {
    let dsp = set_up();
    init_game(dsp);
    start_prank(dsp.game.contract_address, ACCOUNT1());
    dsp.game.generate_planet();

    let tokens = dsp.game.get_token_addresses();
    assert(tokens.erc721 == dsp.erc721.contract_address, 'wrong address');
    assert(tokens.steel == dsp.steel.contract_address, 'wrong address');
    assert(tokens.quartz == dsp.quartz.contract_address, 'wrong address');
    assert(tokens.tritium == dsp.tritium.contract_address, 'wrong address');
}

#[test]
fn test_get_number_of_planets() {
    let dsp = set_up();
    init_game(dsp);
    start_prank(dsp.game.contract_address, ACCOUNT1());
    dsp.game.generate_planet();
    assert(dsp.game.get_number_of_planets() == 1, 'wrong n planets');
}

#[test]
fn test_get_spendable_resources() {
    let dsp = set_up();
    init_game(dsp);
    start_prank(dsp.game.contract_address, ACCOUNT1());
    dsp.game.generate_planet();

    let spendable = dsp.game.get_spendable_resources(104);
    assert(spendable.steel == 500 * E18, 'wrong spendable');
    assert(spendable.quartz == 300 * E18, 'wrong spendable ');
    assert(spendable.tritium == 100 * E18, 'wrong spendable ');
}

#[test]
fn test_get_collectible_resources() {
    let dsp = set_up();
    init_game(dsp);
    start_prank(dsp.game.contract_address, ACCOUNT1());
    dsp.game.generate_planet();

    start_warp(dsp.game.contract_address, HOUR * 3);
    let collectible = dsp.game.get_collectible_resources(104);
    assert(collectible.steel == 30, 'wrong collectible ');
    assert(collectible.quartz == 30, 'wrong collectible ');
    assert(collectible.tritium == 0, 'wrong collectible ');
}

#[test]
fn test_energy_available() {
    let dsp = set_up();
    init_game(dsp);
    start_prank(dsp.game.contract_address, ACCOUNT1());
    dsp.game.generate_planet();

    assert(dsp.game.get_energy_available(104) == 0, 'wrong energy');
}

#[test]
fn test_get_compounds_levels() {
    let dsp = set_up();
    init_game(dsp);
    start_prank(dsp.game.contract_address, ACCOUNT1());
    dsp.game.generate_planet();

    let compounds = dsp.game.get_compounds_levels(104);
    assert(compounds.steel == 0, 'wrong steel lev');
    assert(compounds.quartz == 0, 'wrong quartz lev');
    assert(compounds.tritium == 0, 'wrong quartz lev');
    assert(compounds.energy == 0, 'wrong energy lev');
    assert(compounds.lab == 0, 'wrong energy lev');
    assert(compounds.dockyard == 0, 'wrong energy lev');
}

#[test]
fn test_get_compounds_upgrade_cost() {
    let dsp = set_up();
    init_game(dsp);
    start_prank(dsp.game.contract_address, ACCOUNT1());
    dsp.game.generate_planet();

    let costs = dsp.game.get_compounds_upgrade_cost(104);
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

#[test]
fn test_get_energy_for_upgrade() {
    let dsp = set_up();
    init_game(dsp);
    start_prank(dsp.game.contract_address, ACCOUNT1());
    dsp.game.generate_planet();

    let costs = dsp.game.get_energy_for_upgrade(104);
    assert(costs.steel == 11, 'wrong steel energy');
    assert(costs.quartz == 11, 'wrong quartz energy');
    assert(costs.tritium == 22, 'wrong tritium energy');
}

#[test]
fn test_get_tech_levels() {
    let dsp = set_up();
    init_game(dsp);
    start_prank(dsp.game.contract_address, ACCOUNT1());
    dsp.game.generate_planet();

    let techs = dsp.game.get_techs_levels(104);
    assert(techs.energy == 0, 'wrong level');
    assert(techs.digital == 0, 'wrong level');
    assert(techs.beam == 0, 'wrong level');
    assert(techs.armour == 0, 'wrong level');
    assert(techs.ion == 0, 'wrong level');
    assert(techs.plasma == 0, 'wrong level');
    assert(techs.weapons == 0, 'wrong level');
    assert(techs.shield == 0, 'wrong level');
    assert(techs.spacetime == 0, 'wrong level');
    assert(techs.combustion == 0, 'wrong level');
    assert(techs.thrust == 0, 'wrong level');
    assert(techs.warp == 0, 'wrong level');
}

#[test]
fn test_get_tech_upgrade_cost() {
    let dsp = set_up();
    init_game(dsp);
    start_prank(dsp.game.contract_address, ACCOUNT1());
    dsp.game.generate_planet();

    let techs = dsp.game.get_techs_upgrade_cost(104);
    assert(techs.energy.quartz == 800 && techs.energy.tritium == 400, 'wrong cost');
    assert(techs.digital.quartz == 400 && techs.digital.tritium == 600, 'wrong cost');
    assert(techs.beam.quartz == 800 && techs.beam.tritium == 400, 'wrong cost');
    assert(
        techs.ion.steel == 1000 && techs.ion.quartz == 300 && techs.ion.tritium == 1000,
        'wrong cost'
    );
    assert(
        techs.plasma.steel == 2000 && techs.plasma.quartz == 4000 && techs.plasma.tritium == 1000,
        'wrong cost'
    );
    assert(techs.spacetime.quartz == 4000 && techs.spacetime.tritium == 2000, 'wrong cost');
    assert(techs.combustion.steel == 400 && techs.combustion.tritium == 600, 'wrong cost');
    assert(
        techs.thrust.steel == 2000 && techs.thrust.quartz == 4000 && techs.thrust.tritium == 600,
        'wrong cost'
    );
    assert(
        techs.warp.steel == 10000 && techs.warp.quartz == 2000 && techs.warp.tritium == 6000,
        'wrong cost'
    );
    assert(techs.armour.steel == 1000, 'wrong cost');
    assert(techs.weapons.steel == 800 && techs.weapons.quartz == 200, 'wrong cost');
    assert(techs.shield.steel == 200 && techs.shield.quartz == 600, 'wrong cost');
}

#[test]
fn test_get_ships_levels() {
    let dsp = set_up();
    init_game(dsp);
    start_prank(dsp.game.contract_address, ACCOUNT1());
    dsp.game.generate_planet();

    let ships = dsp.game.get_ships_levels(104);
    assert(ships.carrier == 0, 'wrong carrier`');
    assert(ships.celestia == 0, 'wrong celestia');
    assert(ships.scraper == 0, 'wrong scraper');
    assert(ships.sparrow == 0, 'wrong sparrow');
    assert(ships.frigate == 0, 'wrong frigate');
    assert(ships.armade == 0, 'wrong armade');
}

#[test]
fn test_get_ships_cost() {
    let dsp = set_up();
    init_game(dsp);
    start_prank(dsp.game.contract_address, ACCOUNT1());
    dsp.game.generate_planet();

    let ships = dsp.game.get_ships_cost();
    assert(ships.carrier.steel == 2000 && ships.carrier.quartz == 2000, 'wrong carrier`');
    assert(ships.celestia.quartz == 2000 && ships.celestia.tritium == 500, 'wrong celestia');
    assert(
        ships.scraper.steel == 10000
            && ships.scraper.quartz == 6000
            && ships.scraper.tritium == 2000,
        'wrong scraper'
    );
    assert(ships.sparrow.steel == 3000 && ships.sparrow.quartz == 1000, 'wrong sparrow');
    assert(
        ships.frigate.steel == 20000
            && ships.frigate.quartz == 7000
            && ships.frigate.tritium == 2000,
        'wrong frigate'
    );
    assert(ships.armade.steel == 45000 && ships.armade.quartz == 15000, 'wrong armade');
}

#[test]
fn test_get_defences_levels() {
    let dsp = set_up();
    init_game(dsp);
    start_prank(dsp.game.contract_address, ACCOUNT1());
    dsp.game.generate_planet();

    let def = dsp.game.get_defences_levels(104);
    assert(def.blaster == 0, 'wrong blaster');
    assert(def.beam == 0, 'wrong beam');
    assert(def.astral == 0, 'wrong astral');
    assert(def.plasma == 0, 'wrong plasma');
}

#[test]
fn test_get_defences_cost() {
    let dsp = set_up();
    init_game(dsp);
    start_prank(dsp.game.contract_address, ACCOUNT1());
    dsp.game.generate_planet();

    let def = dsp.game.get_defences_cost();
    assert(def.blaster.steel == 2000, 'wrong blaster');
    assert(def.beam.steel == 6000 && def.beam.quartz == 2000, 'wrong beam');
    assert(
        def.astral.steel == 20000 && def.astral.quartz == 15000 && def.astral.tritium == 2000,
        'wrong astral'
    );
    assert(
        def.plasma.steel == 50000 && def.plasma.quartz == 50000 && def.plasma.tritium == 30000,
        'wrong plasma'
    );
}

