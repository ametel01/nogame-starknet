use array::ArrayTrait;
use option::OptionTrait;
use result::ResultTrait;
use traits::Into;
use traits::TryInto;
use starknet::testing::cheatcode;
use starknet::info::get_contract_address;
use starknet::{ContractAddress, contract_address_const};

use forge_print::PrintTrait;
use cheatcodes::start_prank;

use nogame::game::interface::{INoGameDispatcher, INoGameDispatcherTrait};
use nogame::game::library::{
    ERC20s, EnergyCost, TechLevels, TechsCost, LeaderBoard, ShipsLevels, ShipsCost, DefencesLevels,
    DefencesCost
};
use nogame::token::erc20::{INGERC20Dispatcher, INGERC20DispatcherTrait};
use nogame::token::erc721::{INGERC721Dispatcher, INGERC721DispatcherTrait};

const E18: u128 = 1000000000000000000;
const HOUR: u64 = 3600;

#[test]
fn test_generate() {
    let dsp = set_up();
    init_game(dsp);

    start_prank(dsp.game.contract_address, ACCOUNT1());
    dsp.game.generate_planet();
    assert(dsp.erc721.balance_of(ACCOUNT1()).low == 1, 'wrong nft balance');
    assert(dsp.steel.balance_of(ACCOUNT1()).low == 500 * E18, 'wrong steel balance');
    assert(dsp.quartz.balance_of(ACCOUNT1()).low == 300 * E18, 'wrong quartz balance');
    assert(dsp.tritium.balance_of(ACCOUNT1()).low == 100 * E18, 'wrong steel balance');

    start_prank(dsp.game.contract_address, ACCOUNT2());
    dsp.game.generate_planet();
    assert(dsp.erc721.balance_of(ACCOUNT2()).low == 1, 'wrong nft balance');
    assert(dsp.steel.balance_of(ACCOUNT2()).low == 500 * E18, 'wrong steel balance');
    assert(dsp.quartz.balance_of(ACCOUNT2()).low == 300 * E18, 'wrong quartz balance');
    assert(dsp.tritium.balance_of(ACCOUNT2()).low == 100 * E18, 'wrong steel balance');

    assert(dsp.game.get_number_of_planets() == 2, 'wrong n planets');
}

fn ACCOUNT1() -> ContractAddress {
    contract_address_const::<1>()
}
fn ACCOUNT2() -> ContractAddress {
    contract_address_const::<2>()
}

#[derive(Copy, Drop, Serde)]
struct Dispatchers {
    erc721: INGERC721Dispatcher,
    steel: INGERC20Dispatcher,
    quartz: INGERC20Dispatcher,
    tritium: INGERC20Dispatcher,
    game: INoGameDispatcher,
}

fn set_up() -> Dispatchers {
    let class_hash = declare('NoGame');
    let prepared = PreparedContract {
        class_hash: class_hash, constructor_calldata: @ArrayTrait::new()
    };
    let _game = deploy(prepared).unwrap();

    let class_hash = declare('NGERC721');
    let mut call_data = array!['nogame-planet', 'NGPL', _game.into()];
    let prepared = PreparedContract { class_hash: class_hash, constructor_calldata: @call_data };
    let _erc721 = deploy(prepared).unwrap();

    let class_hash = declare('NGERC20');
    let mut call_data = array!['Nogame Steel', 'NGST', _game.into()];
    let prepared = PreparedContract { class_hash: class_hash, constructor_calldata: @call_data };
    let _steel = deploy(prepared).unwrap();

    let mut call_data = array!['Nogame Quartz', 'NGQZ', _game.into()];
    let prepared = PreparedContract { class_hash: class_hash, constructor_calldata: @call_data };
    let _quartz = deploy(prepared).unwrap();

    let mut call_data = array!['Nogame Tritium', 'NGTR', _game.into()];
    let prepared = PreparedContract { class_hash: class_hash, constructor_calldata: @call_data };
    let _tritium = deploy(prepared).unwrap();

    Dispatchers {
        erc721: INGERC721Dispatcher {
            contract_address: _erc721
            }, steel: INGERC20Dispatcher {
            contract_address: _steel
            }, quartz: INGERC20Dispatcher {
            contract_address: _quartz
            }, tritium: INGERC20Dispatcher {
            contract_address: _tritium
            }, game: INoGameDispatcher {
            contract_address: _game
        }
    }
}

fn init_game(dsp: Dispatchers) {
    dsp
        .game
        ._initializer(
            dsp.erc721.contract_address,
            dsp.steel.contract_address,
            dsp.quartz.contract_address,
            dsp.tritium.contract_address
        )
}