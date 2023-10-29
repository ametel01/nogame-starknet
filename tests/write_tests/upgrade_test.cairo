use snforge_std::{start_prank, PrintTrait};

use nogame::game::interface::{INoGameDispatcher, INoGameDispatcherTrait};
use nogame::mocks::mock_upgradable::{INoGameUpgradedDispatcher, INoGameUpgradedDispatcherTrait};

use tests::utils::{init_game, set_up, declare_upgradable, ACCOUNT1, build_everything};

#[test]
fn test_upgradable() {
    let dsp = set_up();
    init_game(dsp);

    start_prank(dsp.game.contract_address, ACCOUNT1());
    dsp.game.generate_planet();

    let class_hash = declare_upgradable();
    dsp.game.upgrade(class_hash);
    let upgraded = INoGameUpgradedDispatcher { contract_address: dsp.game.contract_address };
    assert(upgraded.get_number().is_zero(), 'wrong assert #1');
    upgraded.write_number(3);
    assert(upgraded.get_number() == 3, 'wrong assert #2');

    build_everything(upgraded);

    let compounds = dsp.game.get_compounds_levels(1);
    assert(compounds.steel == 3, 'wrong assert #1');
    assert(compounds.quartz == 4, 'wrong assert #2');
    assert(compounds.tritium == 3, 'wrong assert #3');
    assert(compounds.energy == 6, 'wrong assert #4');
    assert(compounds.lab == 7, 'wrong assert #5');
    assert(compounds.dockyard == 8, 'wrong assert #6');

    let techs = dsp.game.get_techs_levels(1);
    assert(techs.energy == 8, 'wrong assert #7');
    assert(techs.digital == 0, 'wrong assert #8');
    assert(techs.beam == 10, 'wrong assert #9');
    assert(techs.armour == 0, 'wrong assert #10');
    assert(techs.ion == 5, 'wrong assert #11');
    assert(techs.plasma == 7, 'wrong assert #12');
    assert(techs.weapons == 3, 'wrong assert #13');
    assert(techs.shield == 5, 'wrong assert #14');
    assert(techs.spacetime == 3, 'wrong assert #15');
    assert(techs.combustion == 6, 'wrong assert #16');
    assert(techs.thrust == 4, 'wrong assert #17');
    assert(techs.warp == 4, 'wrong assert #18');
}
