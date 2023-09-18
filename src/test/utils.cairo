use array::ArrayTrait;
use starknet::{ContractAddress, contract_address_const};

use xoroshiro::xoroshiro::{IXoroshiroDispatcher, IXoroshiroDispatcherTrait, Xoroshiro};

use nogame::game::interface::{INoGameDispatcher, INoGameDispatcherTrait};
use nogame::token::erc20::{INGERC20Dispatcher, INGERC20DispatcherTrait};
use nogame::token::erc721::{INGERC721Dispatcher, INGERC721DispatcherTrait};

use snforge_std::{declare, ContractClassTrait};

const E18: u128 = 1000000000000000000;
const HOUR: u64 = 3600;

#[derive(Copy, Drop, Serde)]
struct Dispatchers {
    erc721: INGERC721Dispatcher,
    steel: INGERC20Dispatcher,
    quartz: INGERC20Dispatcher,
    tritium: INGERC20Dispatcher,
    rand: IXoroshiroDispatcher,
    game: INoGameDispatcher,
}

fn ACCOUNT1() -> ContractAddress {
    contract_address_const::<1>()
}
fn ACCOUNT2() -> ContractAddress {
    contract_address_const::<2>()
}

fn set_up() -> Dispatchers {
    let contract = declare('NoGame');
    let calldata: Array<felt252> = array![];
    let _game = contract.deploy(@calldata).unwrap();

    let contract = declare('NGERC721');
    let calldata: Array<felt252> = array!['nogame-planet', 'NGPL', _game.into()];
    let _erc721 = contract.deploy(@calldata).unwrap();

    let contract = declare('NGERC20');
    let calldata: Array<felt252> = array!['Nogame Steel', 'NGST', _game.into()];
    let _steel = contract.deploy(@calldata).unwrap();

    let calldata: Array<felt252> = array!['Nogame Quartz', 'NGQZ', _game.into()];
    let _quartz = contract.deploy(@calldata).unwrap();

    let calldata: Array<felt252> = array!['Nogame Tritium', 'NGTR', _game.into()];
    let _tritium = contract.deploy(@calldata).unwrap();

    let contract = declare('Xoroshiro');
    let calldata: Array<felt252> = array![81];
    let _xoroshiro = contract.deploy(@calldata).unwrap();

    Dispatchers {
        erc721: INGERC721Dispatcher { contract_address: _erc721 },
        steel: INGERC20Dispatcher { contract_address: _steel },
        quartz: INGERC20Dispatcher { contract_address: _quartz },
        tritium: INGERC20Dispatcher { contract_address: _tritium },
        rand: IXoroshiroDispatcher { contract_address: _xoroshiro },
        game: INoGameDispatcher { contract_address: _game }
    }
}

fn init_game(dsp: Dispatchers) {
    dsp
        .game
        ._initializer(
            dsp.erc721.contract_address,
            dsp.steel.contract_address,
            dsp.quartz.contract_address,
            dsp.tritium.contract_address,
            dsp.rand.contract_address
        )
}
