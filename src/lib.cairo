use integer::BoundedInt;
use starknet::{
    storage_access::{Store, StorageBaseAddress},
    {SyscallResult, syscalls::{storage_read_syscall, storage_write_syscall}}
};

mod game {
    mod game;
}

mod colony {
    mod colony;
    mod positions;
}

mod component {
    mod shared;
}

mod compound {
    mod compound;
    mod library;
}

mod defence {
    mod defence;
    mod library;
}

mod dockyard {
    mod dockyard;
    mod library;
}

mod fleet_movements {
    mod fleet_movements;
    mod library;
}

mod libraries {
    mod auction;
    mod math;
    mod positions;
    mod types;
}

mod storage {
    mod storage;
}

mod tech {
    mod library;
    mod tech;
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

