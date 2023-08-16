#[cfg(test)]
use traits::TryInto;
use option::OptionTrait;
use starknet::ContractAddress;
use starknet::SyscallResultTrait;
use array::ArrayTrait;
use starknet::syscalls::{deploy_syscall, get_block_hash_syscall};

use openzeppelin::token::erc20::erc20::ERC20;
use nogame::token::erc20::NGERC20;

fn deploy_test() -> ContractAddress {
    let mut calldata = ArrayTrait::<felt252>::new();
    calldata.append('ether');
    calldata.append('ETH');
    calldata.append(0);
    calldata.append(0x123);

    let (address, _) = starknet::deploy_syscall(
        ERC20::TEST_CLASS_HASH.try_into().unwrap(), 0, calldata.span(), false
    )
        .unwrap_syscall();
    address
}
// #[test]
// #[available_gas(200000000)]
// fn test() {
//     let address = deploy_test();
// }


