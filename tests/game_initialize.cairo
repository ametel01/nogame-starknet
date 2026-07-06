use nogame::game::contract::IGameDispatcherTrait;
use snforge_std::{start_cheat_block_timestamp_global, start_cheat_caller_address};
use super::utils::{ACCOUNT1, DEPLOYER, Dispatchers, TOKEN_PRICE, UNI_SPEED, set_up};

fn initialize_game(dsp: Dispatchers) {
    dsp
        .game
        .initialize(
            dsp.colony.contract_address,
            dsp.compound.contract_address,
            dsp.defence.contract_address,
            dsp.dockyard.contract_address,
            dsp.fleet.contract_address,
            dsp.planet.contract_address,
            dsp.tech.contract_address,
            dsp.erc721.contract_address,
            dsp.steel.contract_address,
            dsp.quartz.contract_address,
            dsp.tritium.contract_address,
            dsp.eth.contract_address,
            UNI_SPEED,
            TOKEN_PRICE,
        );
}

#[test]
fn test_game_initialize_owner_sets_universe_start_time() {
    let dsp = set_up();
    let start_time = 1_777_777;

    start_cheat_block_timestamp_global(start_time);
    start_cheat_caller_address(dsp.game.contract_address, DEPLOYER());
    initialize_game(dsp);

    assert(dsp.game.get_universe_start_time() == start_time, 'wrong universe start time');
}

#[test]
#[should_panic(expected: ('Caller is not the owner',))]
fn test_game_initialize_rejects_non_owner() {
    let dsp = set_up();

    start_cheat_caller_address(dsp.game.contract_address, ACCOUNT1());
    initialize_game(dsp);
}

#[test]
#[should_panic]
fn test_game_initialize_rejects_second_initialize() {
    let dsp = set_up();

    start_cheat_caller_address(dsp.game.contract_address, DEPLOYER());
    initialize_game(dsp);
    initialize_game(dsp);
}
