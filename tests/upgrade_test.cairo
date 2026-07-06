use nogame::compound::contract::ICompoundDispatcherTrait;
use nogame::game::contract::IGameDispatcherTrait;
use nogame::tech::contract::ITechDispatcherTrait;
use nogame::token::erc20::interface::{IERC20NoGameDispatcher, IERC20NoGameDispatcherTrait};
use openzeppelin_interfaces::upgrades::{IUpgradeableDispatcher, IUpgradeableDispatcherTrait};
use snforge_std::{DeclareResultTrait, declare, start_cheat_caller_address};
use starknet::SyscallResultTrait;
use super::utils::{ACCOUNT1, DEPLOYER, Dispatchers, set_up};

#[test]
fn test_game_upgrade_owner_can_call_upgrade_entrypoints() {
    let dsp: Dispatchers = set_up();

    start_cheat_caller_address(dsp.game.contract_address, DEPLOYER());
    let game_class = declare("Game").unwrap_syscall().contract_class();
    dsp.game.upgrade(*game_class.class_hash);

    start_cheat_caller_address(dsp.compound.contract_address, DEPLOYER());
    let compound_class = declare("Compound").unwrap_syscall().contract_class();
    dsp.compound.upgrade(*compound_class.class_hash);

    start_cheat_caller_address(dsp.tech.contract_address, DEPLOYER());
    let tech_class = declare("Tech").unwrap_syscall().contract_class();
    dsp.tech.upgrade(*tech_class.class_hash);

    start_cheat_caller_address(dsp.steel.contract_address, DEPLOYER());
    let erc20_nogame = IERC20NoGameDispatcher { contract_address: dsp.steel.contract_address };
    let erc20_nogame_class = declare("ERC20NoGame").unwrap_syscall().contract_class();
    erc20_nogame.upgrade(*erc20_nogame_class.class_hash);

    start_cheat_caller_address(dsp.eth.contract_address, DEPLOYER());
    let eth = IUpgradeableDispatcher { contract_address: dsp.eth.contract_address };
    let erc20_class = declare("ERC20Upgradeable").unwrap_syscall().contract_class();
    eth.upgrade(*erc20_class.class_hash);
}

#[test]
#[should_panic(expected: ('Caller is not the owner',))]
fn test_game_upgrade_rejects_non_owner() {
    let dsp: Dispatchers = set_up();

    start_cheat_caller_address(dsp.game.contract_address, ACCOUNT1());
    let game_class = declare("Game").unwrap_syscall().contract_class();
    dsp.game.upgrade(*game_class.class_hash);
}
