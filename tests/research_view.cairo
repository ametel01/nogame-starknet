use nogame::libraries::types::{
    Defences, DefencesCost, ERC20s, EnergyCost, ShipsCost, ShipsLevels, TechLevels, TechsCost,
};
use nogame::planet::contract::{IPlanetDispatcher, IPlanetDispatcherTrait};
use nogame::tech::contract::{ITechDispatcher, ITechDispatcherTrait};
use snforge_std::{start_cheat_block_timestamp_global, start_cheat_caller_address_global};
use starknet::ContractAddress;
use starknet::info::get_contract_address;
use starknet::testing::cheatcode;
use super::utils::{ACCOUNT1, ACCOUNT2, Dispatchers, E18, HOUR, init_game, set_up};

#[test]
fn test_get_tech_levels() {
    let dsp = set_up();
    init_game(dsp);
    start_cheat_caller_address_global(ACCOUNT1());
    dsp.planet.generate_planet();

    let techs = dsp.tech.get_tech_levels(1);
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

