use nogame::colony::colony::{Colony, IColonyDispatcher, IColonyDispatcherTrait};
use nogame::compound::compound::{Compound, ICompoundDispatcher, ICompoundDispatcherTrait};
use nogame::defence::defence::{Defence, IDefenceDispatcher, IDefenceDispatcherTrait};
use nogame::dockyard::dockyard::{Dockyard, IDockyardDispatcher, IDockyardDispatcherTrait};
use nogame::fleet_movements::fleet_movements::{
    FleetMovements, IFleetMovementsDispatcher, IFleetMovementsDispatcherTrait
};
use nogame::libraries::types::{PRICE, TechUpgradeType, CompoundUpgradeType, Names, ERC20s};
use nogame::planet::planet::{IPlanetDispatcher, IPlanetDispatcherTrait};
use nogame::storage::storage::{Storage, IStorageDispatcher, IStorageDispatcherTrait};
use nogame::tech::tech::{Tech, ITechDispatcher, ITechDispatcherTrait};
use nogame::token::erc20::erc20::ERC20;
use nogame::token::erc20::erc20_ng::ERC20NoGame;
use nogame::token::erc20::interface::{IERC20NoGameDispatcher, IERC20NoGameDispatcherTrait};
use nogame::token::erc721::interface::{IERC721NoGameDispatcher, IERC721NoGameDispatcherTrait};
use nogame_fixed::f128::types::{Fixed, FixedTrait, ONE_u128 as ONE};
use openzeppelin::token::erc20::interface::{IERC20CamelDispatcher, IERC20CamelDispatcherTrait};

use snforge_std::{
    declare, ContractClassTrait, start_warp, start_prank, stop_prank, PrintTrait, CheatTarget,
    store, map_entry_address
};
use starknet::{
    ContractAddress, contract_address_const, get_block_timestamp, get_contract_address,
    get_caller_address, class_hash::ClassHash
};

const E18: u128 = 1_000_000_000_000_000_000;
const ETH_SUPPLY: felt252 = 1_000_000_000_000_000_000_000;
const HOUR: u64 = 3_600;
const DAY: u64 = 86_400;
const WEEK: u64 = 604_800;
const YEAR: u64 = 31_557_600;
const UNI_SPEED: u128 = 1;
const TOKEN_PRICE: u128 = 1;

#[derive(Copy, Drop, Serde)]
struct Dispatchers {
    erc721: IERC721NoGameDispatcher,
    steel: IERC20NoGameDispatcher,
    quartz: IERC20NoGameDispatcher,
    tritium: IERC20NoGameDispatcher,
    eth: IERC20CamelDispatcher,
    planet: IPlanetDispatcher,
    storage: IStorageDispatcher,
    colony: IColonyDispatcher,
    compound: ICompoundDispatcher,
    defence: IDefenceDispatcher,
    dockyard: IDockyardDispatcher,
    fleet: IFleetMovementsDispatcher,
    tech: ITechDispatcher,
}

fn DEPLOYER() -> ContractAddress {
    contract_address_const::<'DEPLOYER'>()
}
fn ACCOUNT1() -> ContractAddress {
    contract_address_const::<1>()
}
fn ACCOUNT2() -> ContractAddress {
    contract_address_const::<2>()
}
fn ACCOUNT3() -> ContractAddress {
    contract_address_const::<3>()
}
fn ACCOUNT4() -> ContractAddress {
    contract_address_const::<4>()
}
fn ACCOUNT5() -> ContractAddress {
    contract_address_const::<5>()
}

fn set_up() -> Dispatchers {
    let contract = declare('Storage');
    let calldata: Array<felt252> = array![];
    let storage = contract.deploy(@calldata).expect('failed storage');

    let contract = declare('Colony');
    let calldata: Array<felt252> = array![DEPLOYER().into(), storage.into()];
    let colony = contract.deploy(@calldata).expect('failed colony');

    let contract = declare('Compound');
    let calldata: Array<felt252> = array![DEPLOYER().into(), storage.into(), colony.into()];
    let compound = contract.deploy(@calldata).expect('failed compound');

    let contract = declare('Defence');
    let calldata: Array<felt252> = array![DEPLOYER().into(), storage.into(), colony.into()];
    let defence = contract.deploy(@calldata).expect('failed defence');

    let contract = declare('Dockyard');
    let calldata: Array<felt252> = array![DEPLOYER().into(), storage.into(), colony.into()];
    let dockyard = contract.deploy(@calldata).expect('failed dockyard');

    let contract = declare('FleetMovements');
    let calldata: Array<felt252> = array![DEPLOYER().into(), storage.into(), colony.into()];
    let fleet = contract.deploy(@calldata).expect('failed fleet');

    let contract = declare('Planet');
    let calldata: Array<felt252> = array![DEPLOYER().into(), storage.into(), colony.into()];
    let planet = contract.deploy(@calldata).expect('failed nogame');

    let contract = declare('Tech');
    let calldata: Array<felt252> = array![DEPLOYER().into(), storage.into(), colony.into()];
    let tech = contract.deploy(@calldata).expect('failed tech');

    let contract = declare('ERC721NoGame');
    let calldata: Array<felt252> = array![
        'nogame-planet', 'NGPL', planet.into(), DEPLOYER().into()
    ];
    let erc721 = contract.deploy(@calldata).expect('failed erc721');

    let contract = declare('ERC20NoGame');
    let calldata: Array<felt252> = array!['Nogame Steel', 'NGST', planet.into()];
    let steel = contract.deploy(@calldata).expect('failed steel');

    let calldata: Array<felt252> = array!['Nogame Quartz', 'NGQZ', planet.into()];
    let quartz = contract.deploy(@calldata).expect('failed quartz');

    let calldata: Array<felt252> = array!['Nogame Tritium', 'NGTR', planet.into()];
    let tritium = contract.deploy(@calldata).expect('failed tritium');

    let contract = declare('ERC20');
    let calldata: Array<felt252> = array!['ETHER', 'ETH', ETH_SUPPLY, 0, DEPLOYER().into()];
    let eth = contract.deploy(@calldata).expect('failed to deploy eth');

    Dispatchers {
        erc721: IERC721NoGameDispatcher { contract_address: erc721 },
        steel: IERC20NoGameDispatcher { contract_address: steel },
        quartz: IERC20NoGameDispatcher { contract_address: quartz },
        tritium: IERC20NoGameDispatcher { contract_address: tritium },
        eth: IERC20CamelDispatcher { contract_address: eth },
        colony: IColonyDispatcher { contract_address: colony },
        compound: ICompoundDispatcher { contract_address: compound },
        defence: IDefenceDispatcher { contract_address: defence },
        dockyard: IDockyardDispatcher { contract_address: dockyard },
        fleet: IFleetMovementsDispatcher { contract_address: fleet },
        planet: IPlanetDispatcher { contract_address: planet },
        tech: ITechDispatcher { contract_address: tech },
        storage: IStorageDispatcher { contract_address: storage },
    }
}

fn init_game(dsp: Dispatchers) {
    start_prank(CheatTarget::All, DEPLOYER());
    dsp
        .storage
        .initializer(
            dsp.colony.contract_address,
            dsp.compound.contract_address,
            dsp.defence.contract_address,
            dsp.dockyard.contract_address,
            dsp.fleet.contract_address,
            dsp.planet.contract_address,
            dsp.tech.contract_address,
            dsp.erc721.contract_address,
            dsp.steel.contract_address,
            dsp.quartz.contract_address,
            dsp.tritium.contract_address,
            dsp.eth.contract_address,
            DEPLOYER(),
            UNI_SPEED,
            TOKEN_PRICE,
            false,
        );
    start_prank(CheatTarget::One(dsp.eth.contract_address), DEPLOYER());
    dsp.eth.transfer(ACCOUNT1(), (10 * E18).into());
    dsp.eth.transfer(ACCOUNT2(), (10 * E18).into());
    dsp.eth.transfer(ACCOUNT3(), (10 * E18).into());
    dsp.eth.transfer(ACCOUNT4(), (10 * E18).into());
    dsp.eth.transfer(ACCOUNT5(), (10 * E18).into());
    stop_prank(CheatTarget::One(dsp.eth.contract_address));

    start_prank(CheatTarget::One(dsp.eth.contract_address), ACCOUNT1());
    dsp.eth.approve(dsp.planet.contract_address, (2 * E18).into());
    stop_prank(CheatTarget::One(dsp.eth.contract_address));

    start_prank(CheatTarget::One(dsp.eth.contract_address), ACCOUNT2());
    dsp.eth.approve(dsp.planet.contract_address, (2 * E18).into());
    stop_prank(CheatTarget::One(dsp.eth.contract_address));

    start_prank(CheatTarget::One(dsp.eth.contract_address), ACCOUNT3());
    dsp.eth.approve(dsp.planet.contract_address, (2 * E18).into());
    stop_prank(CheatTarget::One(dsp.eth.contract_address));

    start_prank(CheatTarget::One(dsp.eth.contract_address), ACCOUNT4());
    dsp.eth.approve(dsp.planet.contract_address, (2 * E18).into());
    stop_prank(CheatTarget::One(dsp.eth.contract_address));

    start_prank(CheatTarget::One(dsp.eth.contract_address), ACCOUNT5());
    dsp.eth.approve(dsp.planet.contract_address, (2 * E18).into());
    stop_prank(CheatTarget::One(dsp.eth.contract_address));
    start_prank(CheatTarget::One(dsp.erc721.contract_address), dsp.planet.contract_address);
    start_prank(CheatTarget::One(dsp.steel.contract_address), dsp.planet.contract_address);
    start_prank(CheatTarget::One(dsp.quartz.contract_address), dsp.planet.contract_address);
    start_prank(CheatTarget::One(dsp.tritium.contract_address), dsp.planet.contract_address);
}

#[test]
fn test_deploy_and_init() {
    let dsp: Dispatchers = set_up();
    init_game(dsp);
    start_prank(CheatTarget::All, dsp.planet.contract_address);
    dsp.eth.transferFrom(ACCOUNT1(), DEPLOYER(), 1.into());
}

fn init_storage(dsp: Dispatchers, planet_id: u32) {
    store(
        dsp.storage.contract_address,
        map_entry_address(
            selector!("compounds_level"), // Providing variable name
            array![planet_id.into(), Names::STEEL].span(), // Providing mapping key 
        ),
        array![20].span()
    );
    store(
        dsp.storage.contract_address,
        map_entry_address(
            selector!("compounds_level"), // Providing variable name
            array![planet_id.into(), Names::QUARTZ].span(), // Providing mapping key 
        ),
        array![20].span()
    );
    store(
        dsp.storage.contract_address,
        map_entry_address(
            selector!("compounds_level"), // Providing variable name
            array![planet_id.into(), Names::TRITIUM].span(), // Providing mapping key 
        ),
        array![20].span()
    );
    store(
        dsp.storage.contract_address,
        map_entry_address(
            selector!("compounds_level"), // Providing variable name
            array![planet_id.into(), Names::ENERGY_PLANT].span(), // Providing mapping key 
        ),
        array![30].span()
    );
    store(
        dsp.storage.contract_address,
        map_entry_address(
            selector!("compounds_level"), // Providing variable name
            array![planet_id.into(), Names::LAB].span(), // Providing mapping key 
        ),
        array![10].span()
    );
    store(
        dsp.storage.contract_address,
        map_entry_address(
            selector!("compounds_level"), // Providing variable name
            array![planet_id.into(), Names::DOCKYARD].span(), // Providing mapping key 
        ),
        array![8].span()
    );
    store(
        dsp.storage.contract_address,
        map_entry_address(
            selector!("techs_level"), // Providing variable name
            array![planet_id.into(), Names::ENERGY_TECH].span(), // Providing mapping key 
        ),
        array![8].span()
    );
    store(
        dsp.storage.contract_address,
        map_entry_address(
            selector!("techs_level"), // Providing variable name
            array![planet_id.into(), Names::COMBUSTION].span(), // Providing mapping key 
        ),
        array![6].span()
    );
    store(
        dsp.storage.contract_address,
        map_entry_address(
            selector!("techs_level"), // Providing variable name
            array![planet_id.into(), Names::BEAM_TECH].span(), // Providing mapping key 
        ),
        array![10].span()
    );
    store(
        dsp.storage.contract_address,
        map_entry_address(
            selector!("techs_level"), // Providing variable name
            array![planet_id.into(), Names::SHIELD].span(), // Providing mapping key 
        ),
        array![6].span()
    );
    store(
        dsp.storage.contract_address,
        map_entry_address(
            selector!("techs_level"), // Providing variable name
            array![planet_id.into(), Names::SPACETIME].span(), // Providing mapping key 
        ),
        array![3].span()
    );
    store(
        dsp.storage.contract_address,
        map_entry_address(
            selector!("techs_level"), // Providing variable name
            array![planet_id.into(), Names::WARP].span(), // Providing mapping key 
        ),
        array![4].span()
    );
    store(
        dsp.storage.contract_address,
        map_entry_address(
            selector!("techs_level"), // Providing variable name
            array![planet_id.into(), Names::ION].span(), // Providing mapping key 
        ),
        array![5].span()
    );
    store(
        dsp.storage.contract_address,
        map_entry_address(
            selector!("techs_level"), // Providing variable name
            array![planet_id.into(), Names::THRUST].span(), // Providing mapping key 
        ),
        array![4].span()
    );
    store(
        dsp.storage.contract_address,
        map_entry_address(
            selector!("techs_level"), // Providing variable name
            array![planet_id.into(), Names::PLASMA_TECH].span(), // Providing mapping key 
        ),
        array![7].span()
    );
    store(
        dsp.storage.contract_address,
        map_entry_address(
            selector!("techs_level"), // Providing variable name
            array![planet_id.into(), Names::WEAPONS].span(), // Providing mapping key 
        ),
        array![4].span()
    );
    store(
        dsp.storage.contract_address,
        map_entry_address(
            selector!("techs_level"), // Providing variable name
            array![planet_id.into(), Names::EXOCRAFT].span(), // Providing mapping key 
        ),
        array![5].span()
    );
    store(
        dsp.storage.contract_address,
        map_entry_address(
            selector!("resources_spent"), // Providing variable name
            array![planet_id.into()].span(), // Providing mapping key 
        ),
        array![1_000_000_000].span()
    );
    warp_multiple(
        dsp.planet.contract_address, get_contract_address(), get_block_timestamp() + WEEK
    );
    dsp.planet.collect_resources();
}


fn warp_multiple(a: ContractAddress, b: ContractAddress, time: u64) {
    start_warp(CheatTarget::All, time);
}

fn declare_upgradable() -> ClassHash {
    declare('NoGameUpgraded').class_hash
}

fn prank_contracts(dsp: Dispatchers, account: ContractAddress) {
    start_prank(
        CheatTarget::Multiple(
            array![
                dsp.colony.contract_address,
                dsp.compound.contract_address,
                dsp.defence.contract_address,
                dsp.dockyard.contract_address,
                dsp.fleet.contract_address,
                dsp.planet.contract_address,
                dsp.tech.contract_address,
            ]
        ),
        account
    );
}

#[test]
fn test_deploy() {
    let dsp = set_up();
    init_game(dsp);
}
