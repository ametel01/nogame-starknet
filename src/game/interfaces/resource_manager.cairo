use nogame::libraries::types::ERC20s;
use starknet::ContractAddress;

/// Resource management interface - handles ERC20 resource minting and burning
#[starknet::interface]
trait IResourceManager<TState> {
    /// Pay resources by burning ERC20 tokens from an account
    fn pay_resources_erc20(self: @TState, account: ContractAddress, amounts: ERC20s);

    /// Receive resources by minting ERC20 tokens to an account
    fn receive_resources_erc20(self: @TState, account: ContractAddress, amounts: ERC20s);

    /// Check if an account has enough resources
    fn check_enough_resources(self: @TState, caller: ContractAddress, amounts: ERC20s);
}
