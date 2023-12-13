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
    }
    mod erc721 {
        mod erc721_ng;
        mod interface;
    }
}

mod tests {
    mod internal_functions {
        #[cfg(test)]
        mod auction_price;
        #[cfg(test)]
        mod compound_cost;
        #[cfg(test)]
        mod fleet;
        #[cfg(test)]
        mod math;
        #[cfg(test)]
        mod mine_production;
        #[cfg(test)]
        mod tech_cost;
    }

    mod view_tests {
        #[cfg(test)]
        mod general_view;
        #[cfg(test)]
        mod compound_view;
        #[cfg(test)]
        mod defence_view;
        #[cfg(test)]
        mod dockyard_view;
        #[cfg(test)]
        mod fleet_view;
        #[cfg(test)]
        mod research_view;
    }

    mod write_tests {
        #[cfg(test)]
        mod compound_write;
        #[cfg(test)]
        mod defence_write;
        #[cfg(test)]
        mod dockyard_write;
        #[cfg(test)]
        mod fleet_write;
        #[cfg(test)]
        mod general_write;
        #[cfg(test)]
        mod research_write;
    }

    mod token {
        #[cfg(test)]
        mod test_erc721;
    }
    #[cfg(test)]
    mod utils;
}
