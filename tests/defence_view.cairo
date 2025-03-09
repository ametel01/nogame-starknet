use nogame::defence::contract::{IDefenceDispatcher, IDefenceDispatcherTrait};
use nogame::libraries::types::{
    Defences, DefencesCost, ERC20s, EnergyCost, Names, ShipsCost, ShipsLevels, TechLevels,
    TechsCost,
};
use nogame::planet::contract::{IPlanetDispatcher, IPlanetDispatcherTrait};
use snforge_std::{map_entry_address, start_cheat_caller_address_global, store};
use starknet::ContractAddress;
use starknet::info::get_contract_address;
use starknet::testing::cheatcode;
use super::utils::{ACCOUNT1, ACCOUNT2, Dispatchers, E18, HOUR, init_game, set_up};

#[test]
fn test_get_defences_levels() {
    let dsp = set_up();
    init_game(dsp);
    start_cheat_caller_address_global(ACCOUNT1());
    dsp.planet.generate_planet();
    store(
        dsp.defence.contract_address,
        map_entry_address(
            selector!("defences_level"), // Providing variable name
            array![1, Names::CELESTIA].span() // Providing mapping key 
        ),
        array![1800].span(),
    );
    store(
        dsp.defence.contract_address,
        map_entry_address(
            selector!("defences_level"), // Providing variable name
            array![1, Names::BLASTER].span() // Providing mapping key 
        ),
        array![18].span(),
    );
    store(
        dsp.defence.contract_address,
        map_entry_address(
            selector!("defences_level"), // Providing variable name
            array![1, Names::BEAM].span() // Providing mapping key 
        ),
        array![8].span(),
    );
    store(
        dsp.defence.contract_address,
        map_entry_address(
            selector!("defences_level"), // Providing variable name
            array![1, Names::ASTRAL].span() // Providing mapping key 
        ),
        array![28].span(),
    );
    store(
        dsp.defence.contract_address,
        map_entry_address(
            selector!("defences_level"), // Providing variable name
            array![1, Names::PLASMA].span() // Providing mapping key 
        ),
        array![38].span(),
    );

    let def = dsp.defence.get_defences_levels(1);
    assert(def.celestia == 1800, 'wrong blaster');
    assert(def.blaster == 18, 'wrong blaster');
    assert(def.beam == 8, 'wrong beam');
    assert(def.astral == 28, 'wrong astral');
    assert(def.plasma == 38, 'wrong plasma');
}

