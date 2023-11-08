use starknet::ContractAddress;

#[starknet::interface]
trait IERC20NG<TState> {
    fn ng_balance_of(self: @TState, account: ContractAddress) -> u256;
    fn ng_transfer_from(
        ref self: TState, sender: ContractAddress, recipient: ContractAddress, amount: u256
    ) -> bool;
    fn mint(ref self: TState, recipient: ContractAddress, amount: u256);
    fn burn(ref self: TState, account: ContractAddress, amount: u256);
}
