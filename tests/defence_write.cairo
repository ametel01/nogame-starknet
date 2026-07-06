use nogame::defence::contract::{IDefenceDispatcher, IDefenceDispatcherTrait};
use nogame::libraries::names::Names;
use nogame::libraries::types::DefenceBuildType;
use snforge_std::{map_entry_address, start_cheat_caller_address, stop_cheat_caller_address, store};
use super::utils::{ACCOUNT1, Dispatchers, generate_planet_for, init_storage, set_up_game};

fn set_up_defence_planet() -> Dispatchers {
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

fn build_defence(dsp: Dispatchers, component: DefenceBuildType) {
    start_cheat_caller_address(dsp.defence.contract_address, ACCOUNT1());
    dsp.defence.process_defence_build(component, 1);
    stop_cheat_caller_address(dsp.defence.contract_address);
}

#[test]
fn test_blaster_build() {
    let dsp = set_up_defence_planet();

    build_defence(dsp, DefenceBuildType::Blaster);

    let defences = dsp.defence.get_defences_levels(1);
    assert(defences.blaster == 1, 'wrong blaster level');
}

#[test]
#[should_panic]
fn test_blaster_build_fails_dockyard_level() {
    let dsp = set_up_defence_planet();
    set_dockyard_level(dsp, 0);

    build_defence(dsp, DefenceBuildType::Blaster);
}

#[test]
#[should_panic]
fn test_celestia_build_fails_combustion_level() {
    let dsp = set_up_defence_planet();
    set_tech_level(dsp, Names::Tech::COMBUSTION, 0);

    build_defence(dsp, DefenceBuildType::Celestia);
}

#[test]
fn test_beam_build() {
    let dsp = set_up_defence_planet();

    build_defence(dsp, DefenceBuildType::Beam);

    let defences = dsp.defence.get_defences_levels(1);
    assert(defences.beam == 1, 'wrong beam level');
}

#[test]
#[should_panic]
fn test_beam_build_fails_dockyard_level() {
    let dsp = set_up_defence_planet();
    set_dockyard_level(dsp, 3);

    build_defence(dsp, DefenceBuildType::Beam);
}

#[test]
#[should_panic]
fn test_beam_build_fails_energy_tech_level() {
    let dsp = set_up_defence_planet();
    set_tech_level(dsp, Names::Tech::ENERGY, 2);

    build_defence(dsp, DefenceBuildType::Beam);
}

#[test]
#[should_panic]
fn test_beam_build_fails_beam_tech_level() {
    let dsp = set_up_defence_planet();
    set_tech_level(dsp, Names::Tech::BEAM, 5);

    build_defence(dsp, DefenceBuildType::Beam);
}

#[test]
fn test_astral_build() {
    let dsp = set_up_defence_planet();

    build_defence(dsp, DefenceBuildType::Astral);

    let defences = dsp.defence.get_defences_levels(1);
    assert(defences.astral == 1, 'wrong astral level');
}

#[test]
#[should_panic]
fn test_astral_build_fails_dockyard_level() {
    let dsp = set_up_defence_planet();
    set_dockyard_level(dsp, 5);

    build_defence(dsp, DefenceBuildType::Astral);
}

#[test]
#[should_panic]
fn test_astral_build_fails_energy_tech_level() {
    let dsp = set_up_defence_planet();
    set_tech_level(dsp, Names::Tech::ENERGY, 5);

    build_defence(dsp, DefenceBuildType::Astral);
}

#[test]
#[should_panic]
fn test_astral_build_fails_weapons_tech_level() {
    let dsp = set_up_defence_planet();
    set_tech_level(dsp, Names::Tech::WEAPONS, 2);

    build_defence(dsp, DefenceBuildType::Astral);
}

#[test]
#[should_panic]
fn test_astral_build_fails_shield_tech_level() {
    let dsp = set_up_defence_planet();
    set_tech_level(dsp, Names::Tech::SHIELD, 0);

    build_defence(dsp, DefenceBuildType::Astral);
}

#[test]
fn test_plasma_build() {
    let dsp = set_up_defence_planet();

    build_defence(dsp, DefenceBuildType::Plasma);

    let defences = dsp.defence.get_defences_levels(1);
    assert(defences.plasma == 1, 'wrong plasma level');
}

#[test]
#[should_panic]
fn test_plasma_build_fails_dockyard_level() {
    let dsp = set_up_defence_planet();
    set_dockyard_level(dsp, 7);

    build_defence(dsp, DefenceBuildType::Plasma);
}

#[test]
#[should_panic]
fn test_plasma_build_fails_plasma_tech_level() {
    let dsp = set_up_defence_planet();
    set_tech_level(dsp, Names::Tech::PLASMA, 6);

    build_defence(dsp, DefenceBuildType::Plasma);
}
