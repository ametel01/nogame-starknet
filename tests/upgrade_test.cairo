// use nogame::planet::contract::{IPlanetDispatcher, IPlanetDispatcherTrait};
// use nogame::libraries::types::{PlanetPosition, Fleet};
// use snforge_std::{BlockId, start_cheat_caller_address, CheatTarget};

// fn ADMIN() -> starknet::ContractAddress {
//     starknet::::<
//         0x00d5b7d5883c00d106c9df28f24a7c46472ef3006f1460d0649a4256f188b906
//     >()
// }

// fn ACCOUNT2() -> starknet::ContractAddress {
//     starknet::::<
//         0x02e492bffa91eb61dbebb7b70c4520f9a1ec2a66ec8559a943a87d299b2782c7
//     >()
// }

// #[test]
// #[fork(url: "https://free-rpc.nethermind.io/sepolia-juno", block_id: BlockId::Number(25993))]
// fn test_upgrade_breking_changes() {
//     let nogame = IPlanetDispatcher {
//         contract_address: starknet::::<
//             0x0519afeefd86845375134c0e3c0331ad578960e1d020041155385d54b721dd04
//         >()
//     };
//     let missions = nogame.get_active_missions(1);
//     let mission = *missions.at(0);
//     mission.print();

//     start_cheat_caller_address(CheatTarget::One(nogame.contract_address), ADMIN());
//     nogame
//         .upgrade(
//             0x045dbf4d6e6fb89e4bc2b665fd0ac1dae9e9fc9fc336d9d1aef8e1e9c8429e2f.try_into().unwrap()
//         );

//     let missions = nogame.get_active_missions(1);
//     let mission = *missions.at(0);

//     start_cheat_caller_address(CheatTarget::One(nogame.contract_address), ACCOUNT2());
//     let mut position: PlanetPosition = Default::default();
//     let mut fleet: Fleet = Default::default();
//     position.system = 81;
//     position.orbit = 9;
//     fleet.carrier = 1;
//     nogame.send_fleet(fleet, position, 1, 100, 0);

//     let missions = nogame.get_active_missions(1);
//     let mission = *missions.at(1);
//     mission.print();
// }


