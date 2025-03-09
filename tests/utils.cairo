use nogame::colony::contract::{IColonyDispatcher, IColonyDispatcherTrait};
use nogame::compound::contract::{ICompoundDispatcher, ICompoundDispatcherTrait};
use nogame::defence::contract::{IDefenceDispatcher, IDefenceDispatcherTrait};
use nogame::dockyard::contract::{IDockyardDispatcher, IDockyardDispatcherTrait};
use nogame::fleet_movements::contract::{IFleetMovementsDispatcher, IFleetMovementsDispatcherTrait};
use nogame::game::contract::{IGameDispatcher, IGameDispatcherTrait};
use nogame::libraries::types::{CompoundUpgradeType, ERC20s, Names, PRICE, TechUpgradeType};
use nogame::planet::contract::{IPlanetDispatcher, IPlanetDispatcherTrait};
use nogame::tech::contract::{ITechDispatcher, ITechDispatcherTrait};
use nogame::token::erc20::interface::{IERC20NoGameDispatcher, IERC20NoGameDispatcherTrait};
use nogame::token::erc721::interface::{IERC721NoGameDispatcher, IERC721NoGameDispatcherTrait};
use nogame_fixed::f128::types::{Fixed, FixedTrait, ONE_u128 as ONE};
use openzeppelin_token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
use snforge_std::{
    ContractClassTrait, DeclareResultTrait, declare, map_entry_address, start_cheat_block_timestamp,
    start_cheat_caller_address, start_cheat_caller_address_global, stop_cheat_caller_address, store,
};
use starknet::class_hash::ClassHash;
use starknet::{ContractAddress, get_block_timestamp, get_caller_address, get_contract_address};

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
    game: IGameDispatcher,
    erc721: IERC721NoGameDispatcher,
    steel: IERC20Dispatcher,
    quartz: IERC20Dispatcher,
    tritium: IERC20Dispatcher,
    eth: IERC20Dispatcher,
    planet: IPlanetDispatcher,
    colony: IColonyDispatcher,
    compound: ICompoundDispatcher,
    defence: IDefenceDispatcher,
    dockyard: IDockyardDispatcher,
    fleet: IFleetMovementsDispatcher,
    tech: ITechDispatcher,
}

fn DEPLOYER() -> ContractAddress {
    'DEPLOYER'.try_into().unwrap()
}
fn ACCOUNT1() -> ContractAddress {
    'ACCOUNT1'.try_into().unwrap()
}
fn ACCOUNT2() -> ContractAddress {
    'ACCOUNT2'.try_into().unwrap()
}
fn ACCOUNT3() -> ContractAddress {
    'ACCOUNT3'.try_into().unwrap()
}
fn ACCOUNT4() -> ContractAddress {
    'ACCOUNT4'.try_into().unwrap()
}
fn ACCOUNT5() -> ContractAddress {
    'ACCOUNT5'.try_into().unwrap()
}

fn set_up() -> Dispatchers {
    let contract = declare("Game").unwrap().contract_class();
    let calldata: Array<felt252> = array![DEPLOYER().into()];
    let (game, _) = contract.deploy(@calldata).expect('failed game');

    let contract = declare("Colony").unwrap().contract_class();
    let calldata: Array<felt252> = array![DEPLOYER().into(), game.into()];
    let (colony, _) = contract.deploy(@calldata).expect('failed colony');

    let contract = declare("Compound").unwrap().contract_class();
    let calldata: Array<felt252> = array![DEPLOYER().into(), game.into(), colony.into()];
    let (compound, _) = contract.deploy(@calldata).expect('failed compound');

    let contract = declare("Defence").unwrap().contract_class();
    let calldata: Array<felt252> = array![DEPLOYER().into(), game.into(), colony.into()];
    let (defence, _) = contract.deploy(@calldata).expect('failed defence');

    let contract = declare("Dockyard").unwrap().contract_class();
    let calldata: Array<felt252> = array![DEPLOYER().into(), game.into(), colony.into()];
    let (dockyard, _) = contract.deploy(@calldata).expect('failed dockyard');

    let contract = declare("FleetMovements").unwrap().contract_class();
    let calldata: Array<felt252> = array![DEPLOYER().into(), game.into(), colony.into()];
    let (fleet, _) = contract.deploy(@calldata).expect('failed fleet');

    let contract = declare("Planet").unwrap().contract_class();
    let calldata: Array<felt252> = array![DEPLOYER().into(), game.into(), colony.into()];
    let (planet, _) = contract.deploy(@calldata).expect('failed nogame');

    let contract = declare("Tech").unwrap().contract_class();
    let calldata: Array<felt252> = array![DEPLOYER().into(), game.into(), colony.into()];
    let (tech, _) = contract.deploy(@calldata).expect('failed tech');

    let contract = declare("ERC721NoGame").unwrap().contract_class();
    let calldata: Array<felt252> = array![
        'nogame-planet', 'NGPL', planet.into(), DEPLOYER().into(),
    ];
    let (erc721, _) = contract.deploy(@calldata).expect('failed erc721');

    let contract = declare("ERC20NoGame").unwrap().contract_class();
    let calldata: Array<felt252> = array!['Nogame Steel', 'NGST', planet.into()];
    let (steel, _) = contract.deploy(@calldata).expect('failed steel');

    let calldata: Array<felt252> = array!['Nogame Quartz', 'NGQZ', planet.into()];
    let (quartz, _) = contract.deploy(@calldata).expect('failed quartz');

    let calldata: Array<felt252> = array!['Nogame Tritium', 'NGTR', planet.into()];
    let (tritium, _) = contract.deploy(@calldata).expect('failed tritium');

    let contract = declare("ERC20Upgradeable").unwrap().contract_class();
    let calldata: Array<felt252> = array!['ETHER', 'ETH', ETH_SUPPLY, 0, DEPLOYER().into()];
    let (eth, _) = contract.deploy(@calldata).expect('failed to deploy eth');

    Dispatchers {
        game: IGameDispatcher { contract_address: game },
        erc721: IERC721NoGameDispatcher { contract_address: erc721 },
        steel: IERC20Dispatcher { contract_address: steel },
        quartz: IERC20Dispatcher { contract_address: quartz },
        tritium: IERC20Dispatcher { contract_address: tritium },
        eth: IERC20Dispatcher { contract_address: eth },
        colony: IColonyDispatcher { contract_address: colony },
        compound: ICompoundDispatcher { contract_address: compound },
        defence: IDefenceDispatcher { contract_address: defence },
        dockyard: IDockyardDispatcher { contract_address: dockyard },
        fleet: IFleetMovementsDispatcher { contract_address: fleet },
        planet: IPlanetDispatcher { contract_address: planet },
        tech: ITechDispatcher { contract_address: tech },
    }
}

fn init_game(dsp: Dispatchers) {
    start_cheat_caller_address_global(DEPLOYER());
    dsp
        .game
        .initialize(
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
            UNI_SPEED,
            TOKEN_PRICE,
        );
    start_cheat_caller_address(dsp.eth.contract_address, DEPLOYER());
    dsp.eth.transfer(ACCOUNT1(), (10 * E18).into());
    dsp.eth.transfer(ACCOUNT2(), (10 * E18).into());
    dsp.eth.transfer(ACCOUNT3(), (10 * E18).into());
    dsp.eth.transfer(ACCOUNT4(), (10 * E18).into());
    dsp.eth.transfer(ACCOUNT5(), (10 * E18).into());
    stop_cheat_caller_address(dsp.eth.contract_address);

    start_cheat_caller_address(dsp.eth.contract_address, ACCOUNT1());
    dsp.eth.approve(dsp.planet.contract_address, (2 * E18).into());
    stop_cheat_caller_address(dsp.eth.contract_address);

    start_cheat_caller_address(dsp.eth.contract_address, ACCOUNT2());
    dsp.eth.approve(dsp.planet.contract_address, (2 * E18).into());
    stop_cheat_caller_address(dsp.eth.contract_address);

    start_cheat_caller_address(dsp.eth.contract_address, ACCOUNT3());
    dsp.eth.approve(dsp.planet.contract_address, (2 * E18).into());
    stop_cheat_caller_address(dsp.eth.contract_address);

    start_cheat_caller_address(dsp.eth.contract_address, ACCOUNT4());
    dsp.eth.approve(dsp.planet.contract_address, (2 * E18).into());
    stop_cheat_caller_address(dsp.eth.contract_address);

    start_cheat_caller_address(dsp.eth.contract_address, ACCOUNT5());
    dsp.eth.approve(dsp.planet.contract_address, (2 * E18).into());
    stop_cheat_caller_address(dsp.eth.contract_address);
    start_cheat_caller_address(dsp.erc721.contract_address, dsp.planet.contract_address);
    start_cheat_caller_address(dsp.steel.contract_address, dsp.planet.contract_address);
    start_cheat_caller_address(dsp.quartz.contract_address, dsp.planet.contract_address);
    start_cheat_caller_address(dsp.tritium.contract_address, dsp.planet.contract_address);
}

#[test]
fn test_deploy_and_init() {
    let dsp: Dispatchers = set_up();
    init_game(dsp);
    start_cheat_caller_address_global(dsp.planet.contract_address);
    dsp.eth.transfer_from(ACCOUNT1(), DEPLOYER(), 1.into());
}

fn init_storage(dsp: Dispatchers, planet_id: u32) {
    store(
        dsp.compound.contract_address,
        map_entry_address(
            selector!("compounds_level"), // Providing variable name
            array![planet_id.into(), Names::STEEL].span() // Providing mapping key 
        ),
        array![20].span(),
    );
    store(
        dsp.compound.contract_address,
        map_entry_address(
            selector!("compounds_level"), // Providing variable name
            array![planet_id.into(), Names::QUARTZ].span() // Providing mapping key 
        ),
        array![20].span(),
    );
    store(
        dsp.compound.contract_address,
        map_entry_address(
            selector!("compounds_level"), // Providing variable name
            array![planet_id.into(), Names::TRITIUM].span() // Providing mapping key 
        ),
        array![20].span(),
    );
    store(
        dsp.compound.contract_address,
        map_entry_address(
            selector!("compounds_level"), // Providing variable name
            array![planet_id.into(), Names::ENERGY_PLANT].span() // Providing mapping key 
        ),
        array![30].span(),
    );
    store(
        dsp.compound.contract_address,
        map_entry_address(
            selector!("compounds_level"), // Providing variable name
            array![planet_id.into(), Names::LAB].span() // Providing mapping key 
        ),
        array![10].span(),
    );
    store(
        dsp.compound.contract_address,
        map_entry_address(
            selector!("compounds_level"), // Providing variable name
            array![planet_id.into(), Names::DOCKYARD].span() // Providing mapping key 
        ),
        array![8].span(),
    );
    store(
        dsp.compound.contract_address,
        map_entry_address(
            selector!("techs_level"), // Providing variable name
            array![planet_id.into(), Names::ENERGY_TECH].span() // Providing mapping key 
        ),
        array![8].span(),
    );
    store(
        dsp.compound.contract_address,
        map_entry_address(
            selector!("techs_level"), // Providing variable name
            array![planet_id.into(), Names::COMBUSTION].span() // Providing mapping key 
        ),
        array![6].span(),
    );
    store(
        dsp.compound.contract_address,
        map_entry_address(
            selector!("techs_level"), // Providing variable name
            array![planet_id.into(), Names::BEAM_TECH].span() // Providing mapping key 
        ),
        array![10].span(),
    );
    store(
        dsp.compound.contract_address,
        map_entry_address(
            selector!("techs_level"), // Providing variable name
            array![planet_id.into(), Names::SHIELD].span() // Providing mapping key 
        ),
        array![6].span(),
    );
    store(
        dsp.compound.contract_address,
        map_entry_address(
            selector!("techs_level"), // Providing variable name
            array![planet_id.into(), Names::SPACETIME].span() // Providing mapping key 
        ),
        array![3].span(),
    );
    store(
        dsp.compound.contract_address,
        map_entry_address(
            selector!("techs_level"), // Providing variable name
            array![planet_id.into(), Names::WARP].span() // Providing mapping key 
        ),
        array![4].span(),
    );
    store(
        dsp.compound.contract_address,
        map_entry_address(
            selector!("techs_level"), // Providing variable name
            array![planet_id.into(), Names::ION].span() // Providing mapping key 
        ),
        array![5].span(),
    );
    store(
        dsp.compound.contract_address,
        map_entry_address(
            selector!("techs_level"), // Providing variable name
            array![planet_id.into(), Names::THRUST].span() // Providing mapping key 
        ),
        array![4].span(),
    );
    store(
        dsp.compound.contract_address,
        map_entry_address(
            selector!("techs_level"), // Providing variable name
            array![planet_id.into(), Names::PLASMA_TECH].span() // Providing mapping key 
        ),
        array![7].span(),
    );
    store(
        dsp.compound.contract_address,
        map_entry_address(
            selector!("techs_level"), // Providing variable name
            array![planet_id.into(), Names::WEAPONS].span() // Providing mapping key 
        ),
        array![4].span(),
    );
    store(
        dsp.compound.contract_address,
        map_entry_address(
            selector!("techs_level"), // Providing variable name
            array![planet_id.into(), Names::EXOCRAFT].span() // Providing mapping key 
        ),
        array![5].span(),
    );
    store(
        dsp.compound.contract_address,
        map_entry_address(
            selector!("resources_spent"), // Providing variable name
            array![planet_id.into()].span() // Providing mapping key 
        ),
        array![1_000_000_000].span(),
    );
    start_cheat_block_timestamp(dsp.planet.contract_address, get_block_timestamp() + WEEK);
    dsp.planet.collect_resources(get_caller_address());
}

#[test]
fn test_deploy() {
    let dsp = set_up();
    init_game(dsp);
}
