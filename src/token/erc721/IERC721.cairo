trait ERC721ABI {
    fn balanceOf(account: ContractAddress) -> u256;
    fn ownerOf(tokenId: u256) -> ContractAddress;
    fn safeTransferFrom(
        from: ContractAddress, to: ContractAddress, tokenId: u256, data: Span<felt252>,
    );
    fn transferFrom(from: ContractAddress, to: ContractAddress, tokenId: u256);
    fn approve(to: ContractAddress, token_id: u256);
    fn setApprovalForAll(operator: ContractAddress, approved: bool);
    fn getApproved(tokenId: u256) -> ContractAddress;
    fn isApprovedForAll(owner: ContractAddress, operator: ContractAddress) -> bool;
}
