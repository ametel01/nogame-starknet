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

mod tests {
    mod auction_price_test;
    mod test_math;
    mod compounds_cost_test;
    mod mines_cost_test;
    mod mines_production_test;
    mod test_fleet;
    mod view_fn_test;
    mod write_fn_test;
    mod utils;
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

impl I128Store of Store<i128> {
    fn read(address_domain: u32, base: StorageBaseAddress) -> SyscallResult<i128> {
        Result::Ok(
            Store::<felt252>::read(address_domain, base)?.try_into().expect('I128Store - non i128')
        )
    }
    #[inline(always)]
    fn write(address_domain: u32, base: StorageBaseAddress, value: i128) -> SyscallResult<()> {
        Store::<felt252>::write(address_domain, base, value.into())
    }
    #[inline(always)]
    fn read_at_offset(
        address_domain: u32, base: StorageBaseAddress, offset: u8
    ) -> SyscallResult<i128> {
        Result::Ok(
            Store::<felt252>::read_at_offset(address_domain, base, offset)?
                .try_into()
                .expect('I128Store - non i128')
        )
    }
    #[inline(always)]
    fn write_at_offset(
        address_domain: u32, base: StorageBaseAddress, offset: u8, value: i128
    ) -> SyscallResult<()> {
        Store::<felt252>::write_at_offset(address_domain, base, offset, value.into())
    }
    #[inline(always)]
    fn size() -> u8 {
        1_u8
    }
}
