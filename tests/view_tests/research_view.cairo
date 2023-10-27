use starknet::testing::cheatcode;
use starknet::info::get_contract_address;
use starknet::{ContractAddress, contract_address_const};
use snforge_std::PrintTrait;

use snforge_std::{start_prank, start_warp};

use nogame::game::interface::{INoGameDispatcher, INoGameDispatcherTrait};
use nogame::libraries::types::{
    ERC20s, EnergyCost, TechLevels, TechsCost, ShipsLevels, ShipsCost, DefencesLevels, DefencesCost
};
use nogame::token::erc20::{INGERC20Dispatcher, INGERC20DispatcherTrait};
use nogame::token::erc721::{IERC721NoGameDispatcher, IERC721NoGameDispatcherTrait};
use tests::utils::{E18, HOUR, Dispatchers, ACCOUNT1, ACCOUNT2, init_game, set_up};

#[test]
fn test_get_tech_levels() {
    let dsp = set_up();
    init_game(dsp);
    start_prank(dsp.game.contract_address, ACCOUNT1());
    dsp.game.generate_planet();

    let techs = dsp.game.get_techs_levels(1);
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

#[test]
fn test_get_tech_upgrade_cost() {
    let dsp = set_up();
    init_game(dsp);
    start_prank(dsp.game.contract_address, ACCOUNT1());
    dsp.game.generate_planet();

    let techs = dsp.game.get_techs_upgrade_cost(1);
    assert(techs.energy.quartz == 800 && techs.energy.tritium == 400, 'wrong cost');
    assert(techs.digital.quartz == 400 && techs.digital.tritium == 600, 'wrong cost');
    assert(techs.beam.quartz == 800 && techs.beam.tritium == 400, 'wrong cost');
    assert(
        techs.ion.steel == 1000 && techs.ion.quartz == 300 && techs.ion.tritium == 1000,
        'wrong cost'
    );
    assert(
        techs.plasma.steel == 2000 && techs.plasma.quartz == 4000 && techs.plasma.tritium == 1000,
        'wrong cost'
    );
    assert(techs.spacetime.quartz == 4000 && techs.spacetime.tritium == 2000, 'wrong cost');
    assert(techs.combustion.steel == 400 && techs.combustion.tritium == 600, 'wrong cost');
    assert(
        techs.thrust.steel == 2000 && techs.thrust.quartz == 4000 && techs.thrust.tritium == 600,
        'wrong cost'
    );
    assert(
        techs.warp.steel == 10000 && techs.warp.quartz == 2000 && techs.warp.tritium == 6000,
        'wrong cost'
    );
    assert(techs.armour.steel == 1000, 'wrong cost');
    assert(techs.weapons.steel == 800 && techs.weapons.quartz == 200, 'wrong cost');
    assert(techs.shield.steel == 200 && techs.shield.quartz == 600, 'wrong cost');
}
