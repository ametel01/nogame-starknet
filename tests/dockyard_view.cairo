use nogame::libraries::types::{
    ERC20s, EnergyCost, TechLevels, TechsCost, ShipsLevels, ShipsCost, Defences, DefencesCost, Names
};
use nogame::planet::planet::{IPlanetDispatcher, IPlanetDispatcherTrait};
use nogame::storage::storage::{IStorageDispatcher, IStorageDispatcherTrait};
use nogame::token::erc721::interface::{IERC721NoGameDispatcher, IERC721NoGameDispatcherTrait};
use snforge_std::PrintTrait;

use snforge_std::{start_prank, start_warp, CheatTarget, store, map_entry_address};
use starknet::info::get_contract_address;
use starknet::testing::cheatcode;
use starknet::{ContractAddress, contract_address_const};
use tests::utils::{E18, HOUR, Dispatchers, ACCOUNT1, ACCOUNT2, init_game, set_up};

#[test]
fn test_get_ships_level() {
    let dsp = set_up();
    init_game(dsp);
    start_prank(CheatTarget::One(dsp.planet.contract_address), ACCOUNT1());
    dsp.planet.generate_planet();

    store(
        dsp.storage.contract_address,
        map_entry_address(
            selector!("ships_level"), // Providing variable name
            array![1, Names::CARRIER].span(), // Providing mapping key 
        ),
        array![1800].span()
    );
    store(
        dsp.storage.contract_address,
        map_entry_address(
            selector!("ships_level"), // Providing variable name
            array![1, Names::SCRAPER].span(), // Providing mapping key 
        ),
        array![18].span()
    );
    store(
        dsp.storage.contract_address,
        map_entry_address(
            selector!("ships_level"), // Providing variable name
            array![1, Names::SPARROW].span(), // Providing mapping key 
        ),
        array![8].span()
    );
    store(
        dsp.storage.contract_address,
        map_entry_address(
            selector!("ships_level"), // Providing variable name
            array![1, Names::FRIGATE].span(), // Providing mapping key 
        ),
        array![28].span()
    );
    store(
        dsp.storage.contract_address,
        map_entry_address(
            selector!("ships_level"), // Providing variable name
            array![1, Names::ARMADE].span(), // Providing mapping key 
        ),
        array![38].span()
    );

    let ships = dsp.storage.get_ships_levels(1);
    assert(ships.carrier == 1800, 'wrong carrier`');
    assert(ships.scraper == 18, 'wrong scraper');
    assert(ships.sparrow == 8, 'wrong sparrow');
    assert(ships.frigate == 28, 'wrong frigate');
    assert(ships.armade == 38, 'wrong armade');
}

#[test]
fn test_get_celestia_available() { // TODO
    assert(0 == 0, 'todo');
}

