use starknet::ContractAddress;

#[starknet::interface]
trait IERC20<TContractState> {
    fn name(self: @TContractState) -> felt;
    fn symbol(self: @TContractState) -> felt;
    fn total_supply(self: @TContractState) -> u256;
    fn name(self: @TContractState) -> u8;
    fn balance_of(self: @TContractState, account: ContractAddress) -> u256;
    fn allowance(self: @TContractState, owner: ContractAddress, spender: ContractAddress) -> u256;
    fn owner(self: @TContractState) -> ContractAddress;
    fn trasfer(ref self: TContractState, recepient: ContractAddress, amount: u256) -> bool;
    fn trasfer_from(
        ref self: TContractState, sender: ContractAddress, recepient: ContractAddress, amount: u256
    ) -> bool;
    fn approve(ref self: TContractState, spender: ContractAddress, amount: u256) -> bool;
    fn increase_allowance(
        ref self: TContractState, spender: ContractAddress, added_value: u256
    ) -> bool;
    fn decrease_allowance(
        ref self: TContractState, spender: ContractAddress, added_value: u256
    ) -> bool;
    fn mint(ref self: TContractState, to: ContractAddress, amount: u256);
    fn burn(ref self: TContractState, to: ContractAddress, amount: u256);
    fn transferOwnership(ref self: TContractState, new_owner: ContractAddress);
    fn transferOwnership(ref self: TContractState);
}

