use nogame::libraries::types::ERC20s;
use starknet::ContractAddress;

/// Resource management interface - handles ERC20 resource minting and burning
#[starknet::interface]
trait IResourceManager<TState> {
    /// Validate and pay resources by burning ERC20 tokens from an account
    fn spend_resources(self: @TState, account: ContractAddress, amounts: ERC20s);

    /// Receive resources by minting ERC20 tokens to an account
    fn grant_resources(self: @TState, account: ContractAddress, amounts: ERC20s);

    /// Get account resource balances in game units
    fn get_account_resources(self: @TState, account: ContractAddress) -> ERC20s;

    /// Get spendable resources for the owner of a planet
    fn get_planet_spendable_resources(self: @TState, planet_id: u32) -> ERC20s;

    /// Pay resources from the owner of a planet
    fn spend_planet_resources(self: @TState, planet_id: u32, amounts: ERC20s);

    /// Pay resources by burning ERC20 tokens from an account
    fn pay_resources_erc20(self: @TState, account: ContractAddress, amounts: ERC20s);

    /// Receive resources by minting ERC20 tokens to an account
    fn receive_resources_erc20(self: @TState, account: ContractAddress, amounts: ERC20s);

    /// Check if an account has enough resources
    fn check_enough_resources(self: @TState, caller: ContractAddress, amounts: ERC20s);
}
