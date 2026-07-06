use nogame::game::interfaces::{IResourceManagerDispatcher, IResourceManagerDispatcherTrait};
use nogame::libraries::types::{Contracts, ERC20s};
use nogame::planet::contract::IPlanetDispatcherTrait;
use starknet::ContractAddress;

#[derive(Copy, Drop)]
struct PlanetSpendWorkflow {
    caller: ContractAddress,
    planet_id: u32,
}

fn begin_planet_workflow(contracts: Contracts, caller: ContractAddress) -> PlanetSpendWorkflow {
    contracts.planet.collect_resources(caller);
    PlanetSpendWorkflow { caller, planet_id: contracts.planet.get_owned_planet(caller) }
}

fn spend_and_record(contracts: Contracts, workflow: PlanetSpendWorkflow, cost: ERC20s) {
    let resource_manager = IResourceManagerDispatcher {
        contract_address: contracts.game.contract_address,
    };
    resource_manager.spend_resources(workflow.caller, cost);
    contracts.planet.update_planet_points(workflow.planet_id, cost, false);
}
