use tests::utils::{
    ACCOUNT1, ACCOUNT2, set_up, init_game, advance_game_state, build_basic_mines, YEAR,
    warp_multiple, Dispatchers, E18
};
use nogame::game::interface::{INoGameDispatcher, INoGameDispatcherTrait};
use nogame::libraries::types::{ColonyUpgradeType, ColonyBuildType};
use snforge_std::{start_prank, CheatTarget, PrintTrait};

#[test]
fn test_generate_colony() {
    let dsp: Dispatchers = set_up();
    init_game(dsp);

    start_prank(CheatTarget::One(dsp.game.contract_address), ACCOUNT1());
    dsp.game.generate_planet();
    build_basic_mines(dsp.game);
    advance_game_state(dsp.game);

    dsp.game.generate_colony(0);
    dsp.game.generate_colony(0);
    dsp.game.generate_colony(0);
    let colonies = dsp.game.get_planet_colonies(1);

    let (id, position) = *colonies.at(0);
    assert(id == 1 && position.system == 188 && position.orbit == 10, 'wrong assert 1');
    let (id, position) = *colonies.at(1);
    assert(id == 2 && position.system == 182 && position.orbit == 2, 'wrong assert 2');
    let (id, position) = *colonies.at(2);
    assert(id == 3 && position.system == 69 && position.orbit == 8, 'wrong assert 3');
}

#[test]
fn test_process_colony_compound_upgrade() {
    let dsp: Dispatchers = set_up();
    init_game(dsp);

    start_prank(CheatTarget::One(dsp.game.contract_address), ACCOUNT1());
    dsp.game.generate_planet();
    build_basic_mines(dsp.game);
    advance_game_state(dsp.game);

    dsp.game.generate_colony(0);
    dsp.game.process_colony_compound_upgrade(1, ColonyUpgradeType::SteelMine, 1);
    let colony_compounds = dsp.game.get_colony_compounds(1, 1);
    colony_compounds.print();
}
