use array::ArrayTrait;

use starknet::ContractAddress;
use starknet::Felt252TryIntoContractAddress;
use result::ResultTrait;
use option::OptionTrait;
use traits::TryInto;
use cheatcodes::PreparedContract;
use debug::PrintTrait;
use nogame::token::erc721::{ERC721, IERC721Dispatcher, IERC721DispatcherTrait};

fn set_up() -> ContractAddress {
    let class_hash = declare('ERC721').unwrap();
    let mut call_data: Array<felt252> = ArrayTrait::new();
    call_data.append('nogam-nft');
    call_data.append('NFT');
    call_data.append(0x1);
    let prepared = PreparedContract { class_hash: class_hash, constructor_calldata: @call_data };
    let contract_address = deploy(prepared).unwrap();
    let contract_address: ContractAddress = contract_address.try_into().unwrap();
    contract_address
}

#[test]
fn erc721_test() {
    let address = set_up();
    let erc721 = IERC721Dispatcher { contract_address: address };
    let name = erc721.name();
    name.print();
}

