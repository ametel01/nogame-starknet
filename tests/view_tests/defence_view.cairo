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
fn test_get_defences_levels() {
    let dsp = set_up();
    init_game(dsp);
    start_prank(dsp.game.contract_address, ACCOUNT1());
    dsp.game.generate_planet();

    let def = dsp.game.get_defences_levels(1);
    assert(def.blaster == 0, 'wrong blaster');
    assert(def.beam == 0, 'wrong beam');
    assert(def.astral == 0, 'wrong astral');
    assert(def.plasma == 0, 'wrong plasma');
}

#[test]
fn test_get_defences_cost() {
    let dsp = set_up();
    init_game(dsp);
    start_prank(dsp.game.contract_address, ACCOUNT1());
    dsp.game.generate_planet();

    let def = dsp.game.get_defences_cost();
    assert(def.blaster.steel == 2000, 'wrong blaster');
    assert(def.beam.steel == 6000 && def.beam.quartz == 2000, 'wrong beam');
    assert(
        def.astral.steel == 20000 && def.astral.quartz == 15000 && def.astral.tritium == 2000,
        'wrong astral'
    );
    assert(
        def.plasma.steel == 50000 && def.plasma.quartz == 50000 && def.plasma.tritium == 30000,
        'wrong plasma'
    );
}
