use nogame::dockyard::contract::{IDockyardDispatcher, IDockyardDispatcherTrait};
use nogame::libraries::names::Names;
use nogame::libraries::types::{
    Defences, DefencesCost, ERC20s, EnergyCost, ShipsCost, ShipsLevels, TechLevels, TechsCost,
};
use nogame::planet::contract::{IPlanetDispatcher, IPlanetDispatcherTrait};
use nogame::token::erc721::interface::{IERC721NoGameDispatcher, IERC721NoGameDispatcherTrait};
use snforge_std::{map_entry_address, start_cheat_caller_address_global, store};
use starknet::ContractAddress;
use starknet::info::get_contract_address;
use starknet::testing::cheatcode;
use super::utils::{ACCOUNT1, ACCOUNT2, Dispatchers, E18, HOUR, init_game, set_up};

#[test]
fn test_get_ships_level() {
    let dsp = set_up();
    init_game(dsp);
    start_cheat_caller_address_global(ACCOUNT1());
    dsp.planet.generate_planet();

    store(
        dsp.dockyard.contract_address,
        map_entry_address(
            selector!("ships_level"), // Providing variable name
            array![1, Names::Fleet::CARRIER.into()].span() // Providing mapping key 
        ),
        array![1800].span(),
    );
    store(
        dsp.dockyard.contract_address,
        map_entry_address(
            selector!("ships_level"), // Providing variable name
            array![1, Names::Fleet::SCRAPER.into()].span() // Providing mapping key 
        ),
        array![18].span(),
    );
    store(
        dsp.dockyard.contract_address,
        map_entry_address(
            selector!("ships_level"), // Providing variable name
            array![1, Names::Fleet::SPARROW.into()].span() // Providing mapping key 
        ),
        array![8].span(),
    );
    store(
        dsp.dockyard.contract_address,
        map_entry_address(
            selector!("ships_level"), // Providing variable name
            array![1, Names::Fleet::FRIGATE.into()].span() // Providing mapping key 
        ),
        array![28].span(),
    );
    store(
        dsp.dockyard.contract_address,
        map_entry_address(
            selector!("ships_level"), // Providing variable name
            array![1, Names::Fleet::ARMADE.into()].span() // Providing mapping key 
        ),
        array![38].span(),
    );

    let ships = dsp.dockyard.get_ships_levels(1);
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

