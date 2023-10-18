use serde::Serde;
use core::integer::i128;
use starknet::{
    storage_access::{Store, StorageBaseAddress},
    {SyscallResult, syscalls::{storage_read_syscall, storage_write_syscall}}
};
use integer::BoundedInt;

mod libraries {
    mod auction;
    mod compounds;
    mod defences;
    mod dockyard;
    mod fleet;
    mod math;
    mod research;
    mod types;
}


mod game {
    mod main;
    mod interface;
}

mod token {
    mod erc20;
    mod erc721;
}

impl I128Serde of Serde<i128> {
    fn serialize(self: @i128, ref output: Array<felt252>) {
        output.append((*self).into());
    }
    fn deserialize(ref serialized: Span<felt252>) -> Option<i128> {
        let felt_val = *(serialized.pop_front().expect('i128 deserialize'));
        let i128_val = felt_val.try_into().expect('i128 Overflow');
        Option::Some(i128_val)
    }
}

