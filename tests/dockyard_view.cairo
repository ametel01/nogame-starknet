use starknet::testing::cheatcode;
use starknet::info::get_contract_address;
use starknet::{ContractAddress, contract_address_const};
use snforge_std::PrintTrait;

use snforge_std::{start_prank, start_warp, CheatTarget};

use nogame::game::interface::{INoGameDispatcher, INoGameDispatcherTrait};
use nogame::libraries::types::{
    ERC20s, EnergyCost, TechLevels, TechsCost, ShipsLevels, ShipsCost, DefencesLevels, DefencesCost
};
use tests::utils::{
    E18, HOUR, Dispatchers, ACCOUNT1, ACCOUNT2, init_game, set_up, build_basic_mines,
    advance_game_state
};
use nogame::game::main::NoGame;

#[test]
fn test_get_ships_levels() {
    let dsp = set_up();
    init_game(dsp);
    start_prank(CheatTarget::One(dsp.game.contract_address), ACCOUNT1());
    dsp.game.generate_planet();

    let ships = dsp.game.get_ships_levels(1);
    assert(ships.carrier == 0, 'wrong carrier`');
    assert(ships.scraper == 0, 'wrong scraper');
    assert(ships.sparrow == 0, 'wrong sparrow');
    assert(ships.frigate == 0, 'wrong frigate');
    assert(ships.armade == 0, 'wrong armade');
}

#[test]
fn test_get_ships_cost() {
    let mut state = NoGame::contract_state_for_testing();

    let ships = NoGame::InternalImpl::get_ships_cost(@state);
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
fn test_get_celestia_available() {
    let dsp = set_up();
    init_game(dsp);
    start_prank(CheatTarget::One(dsp.game.contract_address), ACCOUNT1());
    dsp.game.generate_planet();
    build_basic_mines(dsp.game);
    advance_game_state(dsp.game);
    dsp.game.celestia_build(10);

    let celestia = dsp.game.get_celestia_available(1);
    assert(celestia == 10, 'wrong celestia');
}

use starknet::testing::cheatcode;
use starknet::info::get_contract_address;
use starknet::{ContractAddress, contract_address_const};
use snforge_std::PrintTrait;

use snforge_std::{start_prank, start_warp, CheatTarget};

use nogame::game::interface::{INoGameDispatcher, INoGameDispatcherTrait};
use nogame::libraries::types::{
    ERC20s, EnergyCost, TechLevels, TechsCost, ShipsLevels, ShipsCost, DefencesLevels, DefencesCost
};
use nogame::token::erc721::interface::{IERC721NoGameDispatcher, IERC721NoGameDispatcherTrait};
use nogame::tests::utils::{E18, HOUR, Dispatchers, ACCOUNT1, ACCOUNT2, init_game, set_up};

#[test]
fn test_get_ships_levels() {
    let dsp = set_up();
    init_game(dsp);
    start_prank(CheatTarget::One(dsp.game.contract_address), ACCOUNT1());
    dsp.game.generate_planet();

    let ships = dsp.game.get_ships_levels(1);
    assert(ships.carrier == 0, 'wrong carrier`');
    assert(ships.scraper == 0, 'wrong scraper');
    assert(ships.sparrow == 0, 'wrong sparrow');
    assert(ships.frigate == 0, 'wrong frigate');
    assert(ships.armade == 0, 'wrong armade');
}

#[test]
fn test_get_ships_cost() {
    let dsp = set_up();
    init_game(dsp);
    start_prank(CheatTarget::One(dsp.game.contract_address), ACCOUNT1());
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
fn test_get_celestia_available() { // TODO
    assert(0 == 0, 'todo');
}
