use nogame::game::interfaces::{IResourceManagerDispatcher, IResourceManagerDispatcherTrait};
use nogame::libraries::types::ERC20s;
use nogame::planet::contract::{IPlanetDispatcher, IPlanetDispatcherTrait};
use starknet::ContractAddress;

#[derive(Copy, Drop)]
struct PlanetSpendWorkflow {
    caller: ContractAddress,
    planet_id: u32,
}

fn begin_planet_workflow(
    planet: IPlanetDispatcher, caller: ContractAddress,
) -> PlanetSpendWorkflow {
    planet.collect_resources(caller);
    PlanetSpendWorkflow { caller, planet_id: planet.get_owned_planet(caller) }
}

fn spend_and_record(
    planet: IPlanetDispatcher,
    resource_manager: IResourceManagerDispatcher,
    workflow: PlanetSpendWorkflow,
    cost: ERC20s,
) {
    resource_manager.spend_resources(workflow.caller, cost);
    planet.update_planet_points(workflow.planet_id, cost, false);
}
