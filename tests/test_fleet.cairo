use snforge_std::{declare, ContractClassTrait, PrintTrait};
use xoroshiro::xoroshiro::Xoroshiro;

use nogame::{Fleet, Unit, TechLevels};
use nogame::fleet::{Combat, get_fleet_speed};

#[test]
fn test_war_basic() {
    let mut attackers = TEST_FLEET_1();
    let mut defenders = TEST_FLEET_2();
    let (res1, res2) = Combat::war(attackers, Default::default(), defenders, Default::default());
    res1.n_ships.print();
    res2.n_ships.print();
}
#[test]
fn test_fleet_speed() {
    let fleet = Default::default();
    let techs = Default::default();
}
