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
    mod i128;
}


mod game {
    mod main;
    mod interface;
}

mod token {
    mod erc20;
    mod erc721;
}

mod mocks {
    mod mock_upgradable;
}
