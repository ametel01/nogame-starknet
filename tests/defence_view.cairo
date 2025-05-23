use nogame::defence::contract::{IDefenceDispatcher, IDefenceDispatcherTrait};
use nogame::libraries::names::Names;
use nogame::libraries::types::{
    Defences, DefencesCost, ERC20s, EnergyCost, ShipsCost, ShipsLevels, TechLevels, TechsCost,
};
use nogame::planet::contract::{IPlanetDispatcher, IPlanetDispatcherTrait};
use snforge_std::{map_entry_address, start_cheat_caller_address, store};
use starknet::ContractAddress;
use starknet::info::get_contract_address;
use starknet::testing::cheatcode;
use super::utils::{ACCOUNT1, ACCOUNT2, Dispatchers, E18, HOUR, init_game, set_up};

#[test]
fn test_get_defences_levels() {
    let dsp = set_up();
    init_game(dsp);
    start_cheat_caller_address(dsp.planet.contract_address, ACCOUNT1());
    dsp.planet.generate_planet();
    store(
        dsp.defence.contract_address,
        map_entry_address(
            selector!("defence_level"), // Providing variable name
            array![1, Names::Defence::CELESTIA.into()].span() // Providing mapping key 
        ),
        array![1800].span(),
    );
    store(
        dsp.defence.contract_address,
        map_entry_address(
            selector!("defence_level"), // Providing variable name
            array![1, Names::Defence::BLASTER.into()].span() // Providing mapping key 
        ),
        array![18].span(),
    );
    store(
        dsp.defence.contract_address,
        map_entry_address(
            selector!("defence_level"), // Providing variable name
            array![1, Names::Defence::BEAM.into()].span() // Providing mapping key 
        ),
        array![8].span(),
    );
    store(
        dsp.defence.contract_address,
        map_entry_address(
            selector!("defence_level"), // Providing variable name
            array![1, Names::Defence::ASTRAL.into()].span() // Providing mapping key 
        ),
        array![28].span(),
    );
    store(
        dsp.defence.contract_address,
        map_entry_address(
            selector!("defence_level"), // Providing variable name
            array![1, Names::Defence::PLASMA.into()].span() // Providing mapping key 
        ),
        array![38].span(),
    );

    let def = dsp.defence.get_defences_levels(1);
    assert!(def.celestia == 1800, "wrong celestia: expected 1800, got {}", def.celestia);
    assert!(def.blaster == 18, "wrong blaster: expected 18, got {}", def.blaster);
    assert!(def.beam == 8, "wrong beam: expected 8, got {}", def.beam);
    assert!(def.astral == 28, "wrong astral: expected 28, got {}", def.astral);
    assert!(def.plasma == 38, "wrong plasma: expected 38, got {}", def.plasma);
}

