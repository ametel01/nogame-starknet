use forge_print::PrintTrait;

use nogame::libraries::packable::PackPackable;
use nogame::game::library::CompoundsLevelsPacked;

#[test]
fn pack_test() {
    let comp = CompoundsLevelsPacked {
        steel: 1, quartz: 2, tritium: 23, energy: 32, lab: 12, dockyard: 52
    };
    let packed = PackPackable::pack(comp);
    let unpacked = PackPackable::unpack(packed);
    unpacked.steel.print();
    unpacked.quartz.print();
    unpacked.tritium.print();
    unpacked.energy.print();
    unpacked.lab.print();
    unpacked.dockyard.print();
    assert(unpacked.steel == comp.steel, '');
}

