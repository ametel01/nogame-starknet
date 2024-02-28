use nogame::libraries::types::{
    ERC20s, EnergyCost, TechLevels, TechsCost, ShipsLevels, ShipsCost, Defences, DefencesCost
};
use nogame::planet::planet::{IPlanetDispatcher, IPlanetDispatcherTrait};
use nogame::storage::storage::{IStorageDispatcher, IStorageDispatcherTrait};

use snforge_std::{start_prank, start_warp, CheatTarget};
use starknet::info::get_contract_address;
use starknet::testing::cheatcode;
use starknet::{ContractAddress, contract_address_const};
use tests::utils::{E18, HOUR, Dispatchers, ACCOUNT1, ACCOUNT2, init_game, set_up, prank_contracts};

#[test]
fn test_get_tech_levels() {
    let dsp = set_up();
    init_game(dsp);
    prank_contracts(dsp, ACCOUNT1());
    dsp.planet.generate_planet();

    let techs = dsp.storage.get_tech_levels(1);
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

