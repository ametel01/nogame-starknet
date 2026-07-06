use nogame::game::interfaces::{
    IContractRegistryDispatcher, IContractRegistryDispatcherTrait, IResourceManagerDispatcher,
    IResourceManagerDispatcherTrait,
};
use nogame::libraries::types::ERC20s;
use nogame::planet::contract::{IPlanetDispatcher, IPlanetDispatcherTrait};
use starknet::ContractAddress;

#[derive(Copy, Drop)]
struct PlanetSpendWorkflow {
    caller: ContractAddress,
    planet_id: u32,
    planet: IPlanetDispatcher,
    resource_manager: IResourceManagerDispatcher,
}

fn begin_planet_workflow(
    game_address: ContractAddress, caller: ContractAddress,
) -> PlanetSpendWorkflow {
    let contract_registry = IContractRegistryDispatcher { contract_address: game_address };
    let planet = contract_registry.get_planet();
    planet.collect_resources(caller);
    PlanetSpendWorkflow {
        caller,
        planet_id: planet.get_owned_planet(caller),
        planet,
        resource_manager: IResourceManagerDispatcher { contract_address: game_address },
    }
}

fn spend_and_record(workflow: PlanetSpendWorkflow, cost: ERC20s) {
    workflow.resource_manager.spend_resources(workflow.caller, cost);
    workflow.planet.update_planet_points(workflow.planet_id, cost, false);
}
