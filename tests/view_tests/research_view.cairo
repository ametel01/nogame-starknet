// use starknet::testing::cheatcode;
// use starknet::info::get_contract_address;
// use starknet::{ContractAddress, contract_address_const};
// use snforge_std::PrintTrait;

// use snforge_std::{start_prank, start_warp, CheatTarget};

// use nogame::game::interface::{INoGameDispatcher, INoGameDispatcherTrait};
// use nogame::game::main::NoGame;
// use nogame::libraries::types::{
//     ERC20s, EnergyCost, TechLevels, TechsCost, ShipsLevels, ShipsCost, DefencesLevels, DefencesCost
// };
// use nogame::tests::utils::{E18, HOUR, Dispatchers, ACCOUNT1, ACCOUNT2, init_game, set_up};

// use nogame::game::main::energy_innovation_levelContractMemberStateTrait;
// use nogame::game::main::digital_systems_levelContractMemberStateTrait;
// use nogame::game::main::beam_technology_levelContractMemberStateTrait;
// use nogame::game::main::armour_innovation_levelContractMemberStateTrait;
// use nogame::game::main::ion_systems_levelContractMemberStateTrait;
// use nogame::game::main::plasma_engineering_levelContractMemberStateTrait;
// use nogame::game::main::weapons_development_levelContractMemberStateTrait;
// use nogame::game::main::shield_tech_levelContractMemberStateTrait;
// use nogame::game::main::spacetime_warp_levelContractMemberStateTrait;
// use nogame::game::main::combustive_engine_levelContractMemberStateTrait;
// use nogame::game::main::thrust_propulsion_levelContractMemberStateTrait;
// use nogame::game::main::warp_drive_levelContractMemberStateTrait;

// #[test]
// fn test_get_tech_levels() {
//     let mut state = NoGame::contract_state_for_testing();        // <--- Ad. 3
//     // state.balance.write(10);

//     let techs = NoGame::InternalImpl::tech_levels(1);
//     assert(techs.energy == 0, 'wrong level');
//     assert(techs.digital == 0, 'wrong level');
//     assert(techs.beam == 0, 'wrong level');
//     assert(techs.armour == 0, 'wrong level');
//     assert(techs.ion == 0, 'wrong level');
//     assert(techs.plasma == 0, 'wrong level');
//     assert(techs.weapons == 0, 'wrong level');
//     assert(techs.shield == 0, 'wrong level');
//     assert(techs.spacetime == 0, 'wrong level');
//     assert(techs.combustion == 0, 'wrong level');
//     assert(techs.thrust == 0, 'wrong level');
//     assert(techs.warp == 0, 'wrong level');
// }

