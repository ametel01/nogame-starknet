use starknet::storage_access::StorePacking;
use integer::{
    U8IntoFelt252, Felt252TryIntoU16, U16DivRem, U32DivRem, U64DivRem, u8_as_non_zero,
    u16_as_non_zero, U16IntoFelt252, u32_as_non_zero, u64_as_non_zero, U32IntoFelt252,
    Felt252TryIntoU8
};
use traits::{Into, TryInto, DivRem};
use option::OptionTrait;

use nogame::game::game_library::{CompoundsLevelsPacked};

const B6_felt: felt252 = 64;
const B6: u64 = 64;
const B12_felt: felt252 = 4096;
const B12: u64 = 4096;
const B18_felt: felt252 = 262144;
const B18: u64 = 262144;
const B24_felt: felt252 = 16777216;
const B24: u64 = 16777216;
const B30_felt: felt252 = 1073741824;
const B30: u64 = 1073741824;
const B36_felt: felt252 = 68719476736;
const B36: u64 = 68719476736;

impl PackPackable of StorePacking<CompoundsLevelsPacked, felt252> {
    fn pack(value: CompoundsLevelsPacked) -> felt252 {
        let steel: felt252 = B30_felt * value.steel.into();
        let quartz: felt252 = B24_felt * value.quartz.into();
        let tritium: felt252 = B18_felt * value.tritium.into();
        let energy: felt252 = B12_felt * value.energy.into();
        let lab: felt252 = B6_felt * value.lab.into();
        let dockyard: felt252 = value.dockyard.into();
        return steel + quartz + tritium + energy + lab + dockyard;
    }
    fn unpack(value: felt252) -> CompoundsLevelsPacked {
        let value: u64 = value.try_into().unwrap();
        let (steel, quartz) = U64DivRem::div_rem(value, u64_as_non_zero(B30));
        let (quartz, tritium) = U64DivRem::div_rem(quartz, u64_as_non_zero(B24));
        let (tritium, energy) = U64DivRem::div_rem(tritium, u64_as_non_zero(B18));
        let (energy, lab) = U64DivRem::div_rem(energy, u64_as_non_zero(B12));
        let (lab, dockyard) = U64DivRem::div_rem(lab, u64_as_non_zero(B6));
        let _steel: u8 = Into::<u64, felt252>::into(steel).try_into().unwrap();
        let _quartz: u8 = Into::<u64, felt252>::into(quartz).try_into().unwrap();
        let _tritium: u8 = Into::<u64, felt252>::into(tritium).try_into().unwrap();
        let _energy: u8 = Into::<u64, felt252>::into(energy).try_into().unwrap();
        let _lab: u8 = Into::<u64, felt252>::into(lab).try_into().unwrap();
        let _dockyard: u8 = Into::<u64, felt252>::into(dockyard).try_into().unwrap();
        return CompoundsLevelsPacked {
            steel: _steel,
            quartz: _quartz,
            tritium: _tritium,
            energy: _energy,
            lab: _lab,
            dockyard: _dockyard
        };
    }
}
