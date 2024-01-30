use integer::BoundedInt;
use starknet::{
    storage_access::{Store, StorageBaseAddress},
    {SyscallResult, syscalls::{storage_read_syscall, storage_write_syscall}}
};

mod game {
    mod interface;
    mod main;
}

mod colony {
    mod colony;
    mod positions;
}

mod compounds {
    mod compounds;
}

mod libraries {
    mod auction;
    mod compounds;
    mod defences;
    mod dockyard;
    mod fleet;
    mod math;
    mod positions;
    mod research;
    mod types;
}

mod token {
    mod erc20 {
        mod erc20;
        mod erc20_ng;
        mod interface;
    }
    mod erc721 {
        mod erc721;
        mod erc721_ng;
        mod interface;
    }
}

mod storage {
    mod storage;
}

