use starknet::ContractAddress;

#[starknet::interface]
trait IERC20NoGame<TState> {
    fn upgrade(ref self: TState, impl_hash: starknet::ClassHash);
    // IERC20NG
    fn mint(ref self: TState, recipient: ContractAddress, amount: u256);
    fn burn(ref self: TState, account: ContractAddress, amount: u256);
}
