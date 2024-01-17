use tests::utils::{
    ACCOUNT1, ACCOUNT2, set_up, init_game, advance_game_state, build_basic_mines, YEAR,
    warp_multiple, Dispatchers, E18
};
use nogame::game::interface::{INoGameDispatcher, INoGameDispatcherTrait};
use nogame::libraries::types::{ColonyUpgradeType, ColonyBuildType, DefencesLevels, CompoundsLevels};
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

    let actual_generated_planets = dsp.game.get_generated_planets_positions();
    (*actual_generated_planets.at(0)).print();
    (*actual_generated_planets.at(1)).print();
    (*actual_generated_planets.at(2)).print();
// assert(id == 1 && position.system == 188 && position.orbit == 10, 'wrong assert 1');
// assert(id == 2 && position.system == 182 && position.orbit == 2, 'wrong assert 2');
// assert(id == 3 && position.system == 69 && position.orbit == 8, 'wrong assert 3');
}

#[test]
fn test_process_colony_compound_upgrade() {
    let dsp: Dispatchers = set_up();
    init_game(dsp);

    start_prank(CheatTarget::One(dsp.game.contract_address), ACCOUNT1());
    dsp.game.generate_planet();
    build_basic_mines(dsp.game);
    advance_game_state(dsp.game);

    let mut expected_compounds: CompoundsLevels = Default::default();
    expected_compounds.steel = 1;
    expected_compounds.quartz = 2;
    expected_compounds.tritium = 3;
    expected_compounds.energy = 4;
    expected_compounds.dockyard = 1;

    dsp.game.generate_colony(0);
    dsp.game.process_colony_compound_upgrade(1, ColonyUpgradeType::SteelMine, 1);
    dsp.game.process_colony_compound_upgrade(1, ColonyUpgradeType::QuartzMine, 2);
    dsp.game.process_colony_compound_upgrade(1, ColonyUpgradeType::TritiumMine, 3);
    dsp.game.process_colony_compound_upgrade(1, ColonyUpgradeType::EnergyPlant, 4);
    dsp.game.process_colony_compound_upgrade(1, ColonyUpgradeType::Dockyard, 1);
    let colony1_compounds = dsp.game.get_colony_compounds(1, 1);
    assert(colony1_compounds == expected_compounds, 'wrong c1 compounds');

    dsp.game.generate_colony(0);
    dsp.game.process_colony_compound_upgrade(2, ColonyUpgradeType::SteelMine, 1);
    dsp.game.process_colony_compound_upgrade(2, ColonyUpgradeType::QuartzMine, 2);
    dsp.game.process_colony_compound_upgrade(2, ColonyUpgradeType::TritiumMine, 3);
    dsp.game.process_colony_compound_upgrade(2, ColonyUpgradeType::EnergyPlant, 4);
    dsp.game.process_colony_compound_upgrade(2, ColonyUpgradeType::Dockyard, 1);
    let colony2_compounds = dsp.game.get_colony_compounds(1, 2);
    assert(colony2_compounds == expected_compounds, 'wrong c2 compounds');
}

#[test]
fn process_colony_unit_build_test() {
    let dsp: Dispatchers = set_up();
    init_game(dsp);

    start_prank(CheatTarget::One(dsp.game.contract_address), ACCOUNT1());
    dsp.game.generate_planet();
    build_basic_mines(dsp.game);
    advance_game_state(dsp.game);

    let mut expected: DefencesLevels = Default::default();
    expected.blaster = 2;

    dsp.game.generate_colony(0);
    dsp.game.process_colony_compound_upgrade(1, ColonyUpgradeType::Dockyard, 1);
    dsp.game.process_colony_unit_build(1, ColonyBuildType::Blaster, 2);
    let actual = dsp.game.get_colony_defences_levels(1, 1);
    assert(actual == expected, 'wrong c1 defences');
}
