use nogame::game::interfaces::{IResourceManagerDispatcher, IResourceManagerDispatcherTrait};
use nogame::libraries::types::ERC20s;
use nogame::planet::contract::IPlanetDispatcherTrait;
use snforge_std::{start_cheat_caller_address, stop_cheat_caller_address};
use super::utils::{ACCOUNT1, Dispatchers, init_game, set_up};

fn resource_manager(dsp: Dispatchers) -> IResourceManagerDispatcher {
    IResourceManagerDispatcher { contract_address: dsp.game.contract_address }
}

#[test]
#[should_panic]
fn test_game_resource_manager_rejects_direct_grant_resources() {
    let dsp = set_up();
    init_game(dsp);
    let resources = ERC20s { steel: 1, quartz: 1, tritium: 1 };

    start_cheat_caller_address(dsp.game.contract_address, ACCOUNT1());
    resource_manager(dsp).grant_resources(ACCOUNT1(), resources);
}

#[test]
#[should_panic]
fn test_game_resource_manager_rejects_direct_receive_resources_erc20() {
    let dsp = set_up();
    init_game(dsp);
    let resources = ERC20s { steel: 1, quartz: 1, tritium: 1 };

    start_cheat_caller_address(dsp.game.contract_address, ACCOUNT1());
    resource_manager(dsp).receive_resources_erc20(ACCOUNT1(), resources);
}

#[test]
#[should_panic]
fn test_game_resource_manager_rejects_direct_pay_resources_erc20() {
    let dsp = set_up();
    init_game(dsp);
    let resources = ERC20s { steel: 1, quartz: 1, tritium: 1 };

    start_cheat_caller_address(dsp.game.contract_address, ACCOUNT1());
    resource_manager(dsp).pay_resources_erc20(ACCOUNT1(), resources);
}

#[test]
fn test_game_resource_manager_keeps_read_only_queries_public() {
    let dsp = set_up();
    init_game(dsp);

    start_cheat_caller_address(dsp.game.contract_address, ACCOUNT1());
    let resources = resource_manager(dsp).get_account_resources(ACCOUNT1());
    stop_cheat_caller_address(dsp.game.contract_address);

    assert(resources.steel == 0, 'unexpected steel');
    assert(resources.quartz == 0, 'unexpected quartz');
    assert(resources.tritium == 0, 'unexpected tritium');
}

#[test]
fn test_game_resource_manager_allows_planet_generation_resource_grant() {
    let dsp = set_up();
    init_game(dsp);

    start_cheat_caller_address(dsp.planet.contract_address, ACCOUNT1());
    dsp.planet.generate_planet();
    stop_cheat_caller_address(dsp.planet.contract_address);

    let resources = resource_manager(dsp).get_account_resources(ACCOUNT1());
    assert(resources.steel == 500, 'wrong steel');
    assert(resources.quartz == 300, 'wrong quartz');
    assert(resources.tritium == 100, 'wrong tritium');
}
