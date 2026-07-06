use nogame::token::erc20::interface::{IERC20NoGameDispatcher, IERC20NoGameDispatcherTrait};
use openzeppelin_interfaces::token::erc20::{ERC20ABIDispatcher, ERC20ABIDispatcherTrait};
use openzeppelin_utils::serde::SerializedAppend;
use snforge_std::{ContractClassTrait, DeclareResultTrait, declare, start_cheat_caller_address};
use super::utils::{ACCOUNT1, ACCOUNT2, ACCOUNT3, DEPLOYER, ETH_SUPPLY};

#[test]
fn test_erc20_nogame_mint_burn_and_public_abi() {
    let (token, minter) = deploy_nogame_erc20();

    assert(token.name() == "Nogame Steel", 'name failed');
    assert(token.symbol() == "NGST", 'symbol failed');
    assert(token.decimals() == 18, 'decimals failed');
    assert(token.total_supply() == 0, 'supply failed');

    start_cheat_caller_address(token.contract_address, DEPLOYER());
    minter.mint(ACCOUNT1(), 1_000);
    assert(token.balance_of(ACCOUNT1()) == 1_000, 'mint failed');
    assert(token.balanceOf(ACCOUNT1()) == 1_000, 'balanceOf failed');

    start_cheat_caller_address(token.contract_address, ACCOUNT1());
    assert(token.transfer(ACCOUNT2(), 200), 'transfer failed');
    assert(token.balance_of(ACCOUNT2()) == 200, 'recipient failed');
    assert(token.approve(ACCOUNT3(), 300), 'approve failed');
    assert(token.allowance(ACCOUNT1(), ACCOUNT3()) == 300, 'allowance failed');

    start_cheat_caller_address(token.contract_address, ACCOUNT3());
    assert(token.transfer_from(ACCOUNT1(), ACCOUNT3(), 100), 'transfer_from failed');
    assert(token.transferFrom(ACCOUNT1(), ACCOUNT3(), 50), 'transferFrom failed');
    assert(token.balance_of(ACCOUNT3()) == 150, 'spender failed');

    start_cheat_caller_address(token.contract_address, DEPLOYER());
    minter.burn(ACCOUNT1(), 100);
    assert(token.totalSupply() == 900, 'totalSupply failed');
}

#[test]
fn test_erc20_upgradeable_constructor_and_public_abi() {
    let token = deploy_upgradeable_erc20();

    assert(token.name() == "Ether", 'preset name failed');
    assert(token.symbol() == "ETH", 'preset symbol failed');
    assert(token.decimals() == 18, 'preset decimals failed');
    assert(token.total_supply() == ETH_SUPPLY, 'preset supply failed');
    assert(token.totalSupply() == ETH_SUPPLY, 'preset totalSupply failed');
    assert(token.balance_of(DEPLOYER()) == ETH_SUPPLY, 'preset balance failed');
    assert(token.balanceOf(DEPLOYER()) == ETH_SUPPLY, 'preset balanceOf failed');

    start_cheat_caller_address(token.contract_address, DEPLOYER());
    assert(token.transfer(ACCOUNT1(), 1_000), 'preset transfer failed');
    assert(token.approve(ACCOUNT2(), 500), 'preset approve failed');
    assert(token.allowance(DEPLOYER(), ACCOUNT2()) == 500, 'preset allowance failed');

    start_cheat_caller_address(token.contract_address, ACCOUNT2());
    assert(token.transfer_from(DEPLOYER(), ACCOUNT2(), 200), 'preset from failed');
    assert(token.transferFrom(DEPLOYER(), ACCOUNT3(), 100), 'preset camel failed');
    assert(token.balance_of(ACCOUNT2()) == 200, 'preset spender failed');
    assert(token.balance_of(ACCOUNT3()) == 100, 'preset camel balance failed');
}

fn deploy_nogame_erc20() -> (ERC20ABIDispatcher, IERC20NoGameDispatcher) {
    let contract = declare("ERC20NoGame").unwrap().contract_class();
    let name: ByteArray = "Nogame Steel";
    let symbol: ByteArray = "NGST";
    let mut calldata: Array<felt252> = array![];
    calldata.append_serde(name);
    calldata.append_serde(symbol);
    calldata.append_serde(DEPLOYER());
    calldata.append_serde(DEPLOYER());
    let (contract_address, _) = contract.deploy(@calldata).expect('failed erc20');

    (ERC20ABIDispatcher { contract_address }, IERC20NoGameDispatcher { contract_address })
}

fn deploy_upgradeable_erc20() -> ERC20ABIDispatcher {
    let contract = declare("ERC20Upgradeable").unwrap().contract_class();
    let name: ByteArray = "Ether";
    let symbol: ByteArray = "ETH";
    let mut calldata: Array<felt252> = array![];
    calldata.append_serde(name);
    calldata.append_serde(symbol);
    calldata.append_serde(ETH_SUPPLY);
    calldata.append_serde(DEPLOYER());
    calldata.append_serde(DEPLOYER());
    let (contract_address, _) = contract.deploy(@calldata).expect('failed erc20 preset');

    ERC20ABIDispatcher { contract_address }
}
