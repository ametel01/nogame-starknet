use starknet::{
    storage_access::{Store, StorageBaseAddress},
    {SyscallResult, syscalls::{storage_read_syscall, storage_write_syscall}}
};
use integer::BoundedInt;
use snforge_std::PrintTrait;

mod libraries {
    mod auction;
    mod compounds;
    mod defences;
    mod dockyard;
    mod fleet;
    mod math;
    mod research;
    mod types;
    mod positions;
}


mod game {
    mod main;
    mod interface;
}

mod token {
    mod erc20 {
        mod erc20_ng;
        mod interface;
        mod erc20;
    }
    mod erc721 {
        mod erc721;
        mod erc721_ng;
        mod interface;
    }
}

