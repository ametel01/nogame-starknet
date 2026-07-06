use nogame::dockyard::contract::{IDockyardDispatcher, IDockyardDispatcherTrait};
use nogame::libraries::names::Names;
use nogame::libraries::types::ShipBuildType;
use snforge_std::{map_entry_address, start_cheat_caller_address, stop_cheat_caller_address, store};
use super::utils::{ACCOUNT1, Dispatchers, generate_planet_for, init_storage, set_up_game};

fn set_up_shipyard_planet() -> Dispatchers {
    let dsp = set_up_game();
    generate_planet_for(dsp, ACCOUNT1());
    init_storage(dsp, 1);
    dsp
}

fn set_dockyard_level(dsp: Dispatchers, level: u8) {
    store(
        dsp.compound.contract_address,
        map_entry_address(
            selector!("compound_level"), array![1, Names::Compound::DOCKYARD.into()].span(),
        ),
        array![level.into()].span(),
    );
}

fn set_tech_level(dsp: Dispatchers, name: u8, level: u8) {
    store(
        dsp.tech.contract_address,
        map_entry_address(selector!("tech_level"), array![1, name.into()].span()),
        array![level.into()].span(),
    );
}

fn build_ship(dsp: Dispatchers, component: ShipBuildType) {
    start_cheat_caller_address(dsp.dockyard.contract_address, ACCOUNT1());
    dsp.dockyard.process_ship_build(component, 1);
    stop_cheat_caller_address(dsp.dockyard.contract_address);
}

#[test]
fn test_carrier_build() {
    let dsp = set_up_shipyard_planet();

    build_ship(dsp, ShipBuildType::Carrier);

    let ships = dsp.dockyard.get_ships_levels(1);
    assert(ships.carrier == 1, 'wrong carrier level');
}

#[test]
#[should_panic]
fn test_carrier_build_fails_dockyard_level() {
    let dsp = set_up_shipyard_planet();
    set_dockyard_level(dsp, 1);

    build_ship(dsp, ShipBuildType::Carrier);
}

#[test]
#[should_panic]
fn test_carrier_build_fails_combustion_level() {
    let dsp = set_up_shipyard_planet();
    set_tech_level(dsp, Names::Tech::COMBUSTION, 1);

    build_ship(dsp, ShipBuildType::Carrier);
}

#[test]
#[should_panic]
fn test_sparrow_build_fails_dockyard_level() {
    let dsp = set_up_shipyard_planet();
    set_dockyard_level(dsp, 0);

    build_ship(dsp, ShipBuildType::Sparrow);
}

#[test]
#[should_panic]
fn test_scraper_build_fails_shield_level() {
    let dsp = set_up_shipyard_planet();
    set_tech_level(dsp, Names::Tech::SHIELD, 1);

    build_ship(dsp, ShipBuildType::Scraper);
}

#[test]
#[should_panic]
fn test_frigate_build_fails_ion_level() {
    let dsp = set_up_shipyard_planet();
    set_tech_level(dsp, Names::Tech::ION, 1);

    build_ship(dsp, ShipBuildType::Frigate);
}

#[test]
#[should_panic]
fn test_frigate_build_fails_thrust_level() {
    let dsp = set_up_shipyard_planet();
    set_tech_level(dsp, Names::Tech::THRUST, 3);

    build_ship(dsp, ShipBuildType::Frigate);
}

#[test]
#[should_panic]
fn test_armade_build_fails_warp_level() {
    let dsp = set_up_shipyard_planet();
    set_tech_level(dsp, Names::Tech::WARP, 3);

    build_ship(dsp, ShipBuildType::Armade);
}
