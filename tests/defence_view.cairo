// use nogame::game::game::{INoGameDispatcher, INoGameDispatcherTrait};
// use nogame::libraries::types::{
//     ERC20s, EnergyCost, TechLevels, TechsCost, ShipsLevels, ShipsCost, Defences, DefencesCost
// };
// use nogame::storage::storage::{IStorageDispatcher, IStorageDispatcherTrait};
// use snforge_std::PrintTrait;

// use snforge_std::{start_prank, start_warp, CheatTarget};
// use starknet::info::get_contract_address;
// use starknet::testing::cheatcode;
// use starknet::{ContractAddress, contract_address_const};
// use tests::utils::{E18, HOUR, Dispatchers, ACCOUNT1, ACCOUNT2, init_game, set_up};

// #[test]
// fn test_get_defences_levels() {
//     let dsp = set_up();
//     init_game(dsp);
//     start_prank(CheatTarget::One(dsp.nogame.contract_address), ACCOUNT1());
//     dsp.nogame.generate_planet();

//     let def = dsp.storage.get_defences_levels(1);
//     assert(def.blaster == 0, 'wrong blaster');
//     assert(def.beam == 0, 'wrong beam');
//     assert(def.astral == 0, 'wrong astral');
//     assert(def.plasma == 0, 'wrong plasma');
// }


