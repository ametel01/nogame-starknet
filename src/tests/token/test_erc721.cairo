use core::result::ResultTrait;
use snforge_std::{declare, ContractClassTrait, start_prank, PrintTrait, CheatTarget};

use nogame::token::erc721::interface::{IERC721NoGameDispatcher, IERC721NoGameDispatcherTrait};
use nogame::tests::utils::{DEPLOYER, ACCOUNT1};

#[test]
fn test_token_uri() {
    let contract = declare('NGERC721');
    let calldata: Array<felt252> = array![
        'nogamenft', 'NGNFT', DEPLOYER().into(), DEPLOYER().into()
    ];
    let contract_address = contract.precalculate_address(@calldata);
    start_prank(CheatTarget::All, DEPLOYER());
    let contract_address = contract.deploy(@calldata).unwrap();
    let erc721 = IERC721NoGameDispatcher { contract_address };
    let erc721_metadata = IERC721NoGameDispatcher { contract_address };

    erc721.set_base_uri(base_uri_array().span());
    erc721.mint(ACCOUNT1(), 32);
    let token_uri = erc721_metadata.tokenURI(32);
}


fn base_uri_array() -> Array<felt252> {
    array![
        104,
        116,
        116,
        112,
        115,
        58,
        47,
        47,
        115,
        99,
        97,
        114,
        108,
        101,
        116,
        45,
        98,
        105,
        111,
        108,
        111,
        103,
        105,
        99,
        97,
        108,
        45,
        99,
        104,
        105,
        112,
        109,
        117,
        110,
        107,
        45,
        49,
        54,
        56,
        46,
        109,
        121,
        112,
        105,
        110,
        97,
        116,
        97,
        46,
        99,
        108,
        111,
        117,
        100,
        47,
        105,
        112,
        102,
        115,
        47,
        81,
        109,
        100,
        53,
        106,
        49,
        103,
        110,
        85,
        66,
        116,
        98,
        102,
        112,
        72,
        67,
        77,
        110,
        87,
        68,
        69,
        56,
        72,
        82,
        72,
        117,
        49,
        71,
        51,
        103,
        104,
        117,
        88,
        83,
        120,
        106,
        75,
        87,
        50,
        112,
        122,
        121,
        51,
        80,
        65,
        107,
        47
    ]
}
