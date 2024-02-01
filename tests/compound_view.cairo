use nogame::game::game::{INoGameDispatcher, INoGameDispatcherTrait};
use nogame::libraries::types::{CompoundsLevels, Names};
use nogame::storage::storage::{IStorageDispatcher, IStorageDispatcherTrait};
use snforge_std::PrintTrait;
use snforge_std::{start_prank, start_warp, CheatTarget};
use starknet::info::get_contract_address;
use starknet::testing::cheatcode;
use starknet::{ContractAddress, contract_address_const};
use tests::utils::{
    init_storage, prank_contracts, E18, HOUR, Dispatchers, ACCOUNT1, ACCOUNT2, ACCOUNT3, ACCOUNT4,
    ACCOUNT5, init_game, set_up,
};

#[test]
fn test_get_compounds_levels() {
    let dsp = set_up();
    init_game(dsp);
    prank_contracts(dsp, ACCOUNT1());
    dsp.nogame.generate_planet();
    init_storage(dsp, 1);

    let compounds = dsp.storage.get_compounds_levels(1);
    assert(compounds.steel == 20, 'wrong steel lev');
    assert(compounds.quartz == 20, 'wrong quartz lev');
    assert(compounds.tritium == 20, 'wrong quartz lev');
    assert(compounds.energy == 30, 'wrong energy lev');
    assert(compounds.lab == 10, 'wrong energy lev');
    assert(compounds.dockyard == 8, 'wrong energy lev');
}

