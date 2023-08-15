// use array::ArrayTrait;
// use array::SpanTrait;
// use clone::Clone;
// use option::OptionTrait;
// use result::ResultTrait;
// use traits::Into;
// use traits::TryInto;
// use starknet::testing::cheatcode;
// use starknet::info::get_contract_address;
// use starknet::ClassHash;
// use starknet::ContractAddress;
// use starknet::ClassHashIntoFelt252;
// use starknet::ContractAddressIntoFelt252;
// use starknet::Felt252TryIntoClassHash;
// use starknet::Felt252TryIntoContractAddress;

// use forge_print::PrintTrait;
// use cheatcodes::start_prank;

// use nogame::token::erc721::{INGERC721Dispatcher, INGERC721DispatcherTrait, NGERC721};
// use nogame::game::main::NoGame;

// #[test]
// fn erc721_test() {
//     let contracts = set_up();
//     let erc721 = INGERC721Dispatcher { contract_address: contracts.erc721 };

//     erc721.set_minter(contracts.account1);
//     start_prank(contracts.erc721, contracts.account1);
//     erc721.mint(contracts.account2, 1.into());
// }

// const PK1: felt252 = 0x1;
// const PK2: felt252 = 0x2;
// const PK3: felt252 = 0x3;

// struct Contracts {
//     account1: ContractAddress,
//     account2: ContractAddress,
//     account3: ContractAddress,
//     erc721: ContractAddress,
//     steel: ContractAddress,
//     quartz: ContractAddress,
//     tritium: ContractAddress,
//     game: ContractAddress,
// }

// fn set_up() -> Contracts {
//     let class_hash = declare('Account');
//     let mut call_data: Array<felt252> = ArrayTrait::new();
//     call_data.append(PK1);
//     let prepared = PreparedContract { class_hash: class_hash, constructor_calldata: @call_data };
//     let _account1 = deploy(prepared).unwrap();

//     let mut call_data: Array<felt252> = ArrayTrait::new();
//     call_data.append(PK2);
//     let prepared = PreparedContract { class_hash: class_hash, constructor_calldata: @call_data };
//     let _account2 = deploy(prepared).unwrap();

//     let mut call_data: Array<felt252> = ArrayTrait::new();
//     call_data.append(PK3);
//     let prepared = PreparedContract { class_hash: class_hash, constructor_calldata: @call_data };
//     let _account3 = deploy(prepared).unwrap();

//     let class_hash = declare('NGERC721');
//     let mut call_data: Array<felt252> = ArrayTrait::new();
//     call_data.append('nogame-planet');
//     call_data.append('NGPL');
//     let prepared = PreparedContract { class_hash: class_hash, constructor_calldata: @call_data };
//     let _erc721 = deploy(prepared).unwrap();

//     let class_hash = declare('NoGame');
//     let prepared = PreparedContract {
//         class_hash: class_hash, constructor_calldata: @ArrayTrait::new()
//     };
//     let _game = deploy(prepared).unwrap();

//     let class_hash = declare('NGERC20');
//     let mut call_data: Array<felt252> = ArrayTrait::new();
//     call_data.append('Nogame Steel');
//     call_data.append('NGST');
//     call_data.append(_game.into());
//     let prepared = PreparedContract { class_hash: class_hash, constructor_calldata: @call_data };
//     let _steel = deploy(prepared).unwrap();

//     let mut call_data: Array<felt252> = ArrayTrait::new();
//     call_data.append('Nogame Quartz');
//     call_data.append('NGQZ');
//     call_data.append(_game.into());
//     let prepared = PreparedContract { class_hash: class_hash, constructor_calldata: @call_data };
//     let _quartz = deploy(prepared).unwrap();

//     let mut call_data: Array<felt252> = ArrayTrait::new();
//     call_data.append('Nogame Tritium');
//     call_data.append('NGTR');
//     call_data.append(_game.into());
//     let prepared = PreparedContract { class_hash: class_hash, constructor_calldata: @call_data };
//     let _tritium = deploy(prepared).unwrap();

//     Contracts {
//         account1: _account1,
//         account2: _account2,
//         account3: _account3,
//         erc721: _erc721,
//         steel: _steel,
//         quartz: _quartz,
//         tritium: _tritium,
//         game: _game
//     }
// }


