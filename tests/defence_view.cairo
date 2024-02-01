use nogame::libraries::types::{
    ERC20s, EnergyCost, TechLevels, TechsCost, ShipsLevels, ShipsCost, Defences, DefencesCost, Names
};
use nogame::planet::planet::{IPlanetDispatcher, IPlanetDispatcherTrait};
use nogame::storage::storage::{IStorageDispatcher, IStorageDispatcherTrait};
use snforge_std::PrintTrait;

use snforge_std::{start_prank, start_warp, CheatTarget, store, map_entry_address};
use starknet::info::get_contract_address;
use starknet::testing::cheatcode;
use starknet::{ContractAddress, contract_address_const};
use tests::utils::{E18, HOUR, Dispatchers, ACCOUNT1, ACCOUNT2, init_game, set_up};

#[test]
fn test_get_defences_levels() {
    let dsp = set_up();
    init_game(dsp);
    start_prank(CheatTarget::One(dsp.planet.contract_address), ACCOUNT1());
    dsp.planet.generate_planet();
    store(
        dsp.storage.contract_address,
        map_entry_address(
            selector!("defences_level"), // Providing variable name
            array![1, Names::CELESTIA].span(), // Providing mapping key 
        ),
        array![1800].span()
    );
    store(
        dsp.storage.contract_address,
        map_entry_address(
            selector!("defences_level"), // Providing variable name
            array![1, Names::BLASTER].span(), // Providing mapping key 
        ),
        array![18].span()
    );
    store(
        dsp.storage.contract_address,
        map_entry_address(
            selector!("defences_level"), // Providing variable name
            array![1, Names::BEAM].span(), // Providing mapping key 
        ),
        array![8].span()
    );
    store(
        dsp.storage.contract_address,
        map_entry_address(
            selector!("defences_level"), // Providing variable name
            array![1, Names::ASTRAL].span(), // Providing mapping key 
        ),
        array![28].span()
    );
    store(
        dsp.storage.contract_address,
        map_entry_address(
            selector!("defences_level"), // Providing variable name
            array![1, Names::PLASMA].span(), // Providing mapping key 
        ),
        array![38].span()
    );

    let def = dsp.storage.get_defences_levels(1);
    assert(def.celestia == 1800, 'wrong blaster');
    assert(def.blaster == 18, 'wrong blaster');
    assert(def.beam == 8, 'wrong beam');
    assert(def.astral == 28, 'wrong astral');
    assert(def.plasma == 38, 'wrong plasma');
}

