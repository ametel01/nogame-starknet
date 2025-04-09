use nogame::compound::contract::{ICompoundDispatcher, ICompoundDispatcherTrait};
use nogame::libraries::types::CompoundsLevels;
use nogame::planet::contract::{IPlanetDispatcher, IPlanetDispatcherTrait};
use snforge_std::{start_cheat_block_timestamp, start_cheat_caller_address};
use starknet::ContractAddress;
use starknet::info::get_contract_address;
use starknet::testing::cheatcode;
use super::utils::{
    ACCOUNT1, ACCOUNT2, ACCOUNT3, ACCOUNT4, ACCOUNT5, Dispatchers, E18, HOUR, init_game,
    init_storage, set_up,
};

#[test]
fn test_get_compounds_levels() {
    let dsp = set_up();
    init_game(dsp);
    start_cheat_caller_address(dsp.planet.contract_address, ACCOUNT1());
    dsp.planet.generate_planet();
    init_storage(dsp, 1);

    let compounds = dsp.compound.get_compounds_levels(1);
    assert(compounds.steel == 20, 'wrong steel lev');
    assert(compounds.quartz == 20, 'wrong quartz lev');
    assert(compounds.tritium == 20, 'wrong quartz lev');
    assert(compounds.energy == 30, 'wrong energy lev');
    assert(compounds.lab == 10, 'wrong energy lev');
    assert(compounds.dockyard == 8, 'wrong energy lev');
}

