use array::ArrayTrait;
use debug::PrintTrait;
use option::OptionTrait;
use result::ResultTrait;
use traits::Into;
use traits::TryInto;
use starknet::testing::cheatcode;
use starknet::info::get_contract_address;
use starknet::{ContractAddress, contract_address_const};

// use forge_print::PrintTrait;
use cheatcodes::start_prank;

use nogame::game::interface::{INoGameDispatcher, INoGameDispatcherTrait};
use nogame::game::library::{
    ERC20s, EnergyCost, TechLevels, TechsCost, LeaderBoard, ShipsLevels, ShipsCost, DefencesLevels,
    DefencesCost
};
use nogame::token::erc20::{INGERC20Dispatcher, INGERC20DispatcherTrait};
use nogame::token::erc721::{INGERC721Dispatcher, INGERC721DispatcherTrait};
// use nogame::test::test_utils::{set_up, init_game, ACCOUNT1, ACCOUNT2, Dispatchers, Contracts, E18, HOUR};
const E18: u128 = 1000000000000000000;
const HOUR: u64 = 3600;

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
fn test_get_leaderboard() {
    let dsp = set_up();
    init_game(dsp);
    start_prank(dsp.game.contract_address, ACCOUNT1());
    dsp.game.generate_planet();

    let board = dsp.game.get_leaderboard();
    assert(
        board.point_leader == 0 && board.tech_leader == 0 && board.fleet_leader == 0,
        'wrong leaderboard'
    );
}

#[test]
fn test_get_spendable_resources() {
    let dsp = set_up();
    init_game(dsp);
    start_prank(dsp.game.contract_address, ACCOUNT1());
    dsp.game.generate_planet();

    let spendable = dsp.game.get_spendable_resources(1);
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
    let collectible = dsp.game.get_collectible_resources(1);
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

    assert(dsp.game.get_energy_available(1) == 0, 'wrong energy');
}

#[test]
fn test_get_compounds_levels() {
    let dsp = set_up();
    init_game(dsp);
    start_prank(dsp.game.contract_address, ACCOUNT1());
    dsp.game.generate_planet();

    let compounds = dsp.game.get_compounds_levels(1);
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

    let costs = dsp.game.get_compounds_upgrade_cost(1);
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

    let costs = dsp.game.get_energy_for_upgrade(1);
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

    let techs = dsp.game.get_techs_levels(1);
    assert(techs.energy_innovation == 0, 'wrong level');
    assert(techs.digital_systems == 0, 'wrong level');
    assert(techs.beam_technology == 0, 'wrong level');
    assert(techs.armour_innovation == 0, 'wrong level');
    assert(techs.ion_systems == 0, 'wrong level');
    assert(techs.plasma_engineering == 0, 'wrong level');
    assert(techs.weapons_development == 0, 'wrong level');
    assert(techs.shield_tech == 0, 'wrong level');
    assert(techs.spacetime_warp == 0, 'wrong level');
    assert(techs.combustion_drive == 0, 'wrong level');
    assert(techs.thrust_propulsion == 0, 'wrong level');
    assert(techs.warp_drive == 0, 'wrong level');
}

#[test]
fn test_get_tech_upgrade_cost() {
    let dsp = set_up();
    init_game(dsp);
    start_prank(dsp.game.contract_address, ACCOUNT1());
    dsp.game.generate_planet();

    let techs = dsp.game.get_techs_upgrade_cost(1);
    assert(
        techs.energy_innovation.quartz == 800 && techs.energy_innovation.tritium == 400,
        'wrong cost'
    );
    assert(
        techs.digital_systems.quartz == 400 && techs.digital_systems.tritium == 600, 'wrong cost'
    );
    assert(
        techs.beam_technology.quartz == 800 && techs.beam_technology.tritium == 400, 'wrong cost'
    );
    assert(
        techs.ion_systems.steel == 1000
            && techs.ion_systems.quartz == 300
            && techs.ion_systems.tritium == 1000,
        'wrong cost'
    );
    assert(
        techs.plasma_engineering.steel == 2000
            && techs.plasma_engineering.quartz == 4000
            && techs.plasma_engineering.tritium == 1000,
        'wrong cost'
    );
    assert(
        techs.spacetime_warp.quartz == 4000 && techs.spacetime_warp.tritium == 2000, 'wrong cost'
    );
    assert(
        techs.combustion_drive.steel == 400 && techs.combustion_drive.tritium == 600, 'wrong cost'
    );
    assert(
        techs.thrust_propulsion.steel == 2000
            && techs.thrust_propulsion.quartz == 4000
            && techs.thrust_propulsion.tritium == 600,
        'wrong cost'
    );
    assert(
        techs.warp_drive.steel == 10000
            && techs.warp_drive.quartz == 2000
            && techs.warp_drive.tritium == 6000,
        'wrong cost'
    );
    assert(techs.armour_innovation.steel == 1000, 'wrong cost');
    assert(
        techs.weapons_development.steel == 800 && techs.weapons_development.quartz == 200,
        'wrong cost'
    );
    assert(techs.shield_tech.steel == 200 && techs.shield_tech.quartz == 600, 'wrong cost');
}

#[test]
fn test_get_ships_levels() {
    let dsp = set_up();
    init_game(dsp);
    start_prank(dsp.game.contract_address, ACCOUNT1());
    dsp.game.generate_planet();

    let ships = dsp.game.get_ships_levels(1);
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

    let def = dsp.game.get_defences_levels(1);
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

