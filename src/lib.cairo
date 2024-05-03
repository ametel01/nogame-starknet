use integer::BoundedInt;
use starknet::{
    storage_access::{Store, StorageBaseAddress},
    {SyscallResult, syscalls::{storage_read_syscall, storage_write_syscall}}
};

mod planet {
    mod contract;
}

mod colony {
    mod contract;
    mod positions;
}

mod compound {
    mod contract;
    mod library;
}

mod defence {
    mod contract;
    mod library;
}

mod dockyard {
    mod contract;
    mod library;
}

mod fleet_movements {
    mod contract;
    mod library;
}

mod game {
    mod contract;
}

mod libraries {
    mod auction;
    mod math;
    mod names;
    mod positions;
    mod types;
}

mod tech {
    mod contract;
    mod library;
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

