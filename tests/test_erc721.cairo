use array::ArrayTrait;
use array::SpanTrait;
use clone::Clone;
use option::OptionTrait;
use result::ResultTrait;
use traits::Into;
use traits::TryInto;
use starknet::testing::cheatcode;
use starknet::info::get_contract_address;
use starknet::ClassHash;
use starknet::ContractAddress;
use starknet::ClassHashIntoFelt252;
use starknet::ContractAddressIntoFelt252;
use starknet::Felt252TryIntoClassHash;
use starknet::Felt252TryIntoContractAddress;

use openzeppelin::account::account::Account;
use openzeppelin::token::erc20::erc20::ERC20;

use forge_print::PrintTrait;
use cheatcodes::start_prank;

use nogame::token::erc721::{INGERC721Dispatcher, INGERC721DispatcherTrait, NGERC721};
use nogame::game::main::NoGame;

const PK1: felt252 = 0x1;
const PK2: felt252 = 0x2;

fn set_up() -> (ContractAddress, ContractAddress) {
    let class_hash = declare('Account');
    let mut call_data: Array<felt252> = ArrayTrait::new();
    call_data.append(PK1);
    let prepared = PreparedContract { class_hash: class_hash, constructor_calldata: @call_data };
    let account1 = deploy(prepared).unwrap();

    // let mut call_data: Array<felt252> = ArrayTrait::new();
    // call_data.append(PK2);
    // let prepared = PreparedContract { class_hash: class_hash, constructor_calldata: @call_data };
    // let account2 = deploy(prepared).unwrap();

    let class_hash = declare('NGERC721');
    let mut call_data: Array<felt252> = ArrayTrait::new();
    call_data.append('nogame-planet');
    call_data.append('NGPL');
    let prepared = PreparedContract { class_hash: class_hash, constructor_calldata: @call_data };
    let erc721 = deploy(prepared).unwrap();
    return (erc721, account1);
// return (account1, account2, erc721);
}

#[test]
fn erc721_test() {
    // let (account1, account2, erc721) = set_up();
    let (erc721_address, account) = set_up();
    let erc721 = INGERC721Dispatcher { contract_address: erc721_address };

    erc721.name().print();
    erc721.symbol().print();

    erc721.set_minter(account);
    start_prank(erc721_address, account);
    erc721.mint(account, 1.into());
    erc721.token_of(account).low.print();
}
