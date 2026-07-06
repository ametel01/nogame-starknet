use nogame::token::erc721::interface::{IERC721NoGameDispatcher, IERC721NoGameDispatcherTrait};
use openzeppelin_interfaces::token::erc721::{
    ERC721ABIDispatcher, ERC721ABIDispatcherTrait, IERC721MetadataDispatcher,
    IERC721MetadataDispatcherTrait,
};
use openzeppelin_utils::serde::SerializedAppend;
use snforge_std::{ContractClassTrait, DeclareResultTrait, declare, start_cheat_caller_address};
use starknet::{ContractAddress, SyscallResultTrait};
use super::utils::{ACCOUNT1, ACCOUNT2, ACCOUNT3, DEPLOYER};

#[test]
fn test_erc721_nogame_transfers_and_approvals() {
    let (erc721, metadata) = deploy_nogame_erc721();

    start_cheat_caller_address(erc721.contract_address, DEPLOYER());
    erc721.mint(ACCOUNT1(), 1);
    erc721.mint(ACCOUNT1(), 2);

    assert(erc721.balance_of(ACCOUNT1()) == 2, 'balance_of failed');
    assert(erc721.balanceOf(ACCOUNT1()) == 2, 'balanceOf failed');
    assert(erc721.owner_of(1) == ACCOUNT1(), 'owner_of failed');
    assert(erc721.ownerOf(2) == ACCOUNT1(), 'ownerOf failed');
    assert(erc721.token_of(ACCOUNT1()) == 2, 'token_of mint failed');
    assert(metadata.name() == "Nogame Planet", 'name failed');
    assert(metadata.symbol() == "NGPL", 'symbol failed');
    assert(metadata.token_uri(1) == "https://nogame.com/planet/1", 'token_uri failed');

    start_cheat_caller_address(erc721.contract_address, ACCOUNT1());
    erc721.approve(ACCOUNT2(), 1);
    assert(erc721.get_approved(1) == ACCOUNT2(), 'get_approved failed');
    assert(erc721.getApproved(1) == ACCOUNT2(), 'getApproved failed');
    erc721.set_approval_for_all(ACCOUNT3(), true);
    assert(erc721.is_approved_for_all(ACCOUNT1(), ACCOUNT3()), 'is_approved_for_all failed');
    erc721.setApprovalForAll(ACCOUNT3(), false);
    assert(!erc721.isApprovedForAll(ACCOUNT1(), ACCOUNT3()), 'isApprovedForAll failed');

    start_cheat_caller_address(erc721.contract_address, ACCOUNT2());
    erc721.transfer_from(ACCOUNT1(), ACCOUNT2(), 1);
    assert(erc721.owner_of(1) == ACCOUNT2(), 'transfer_from failed');
    assert(erc721.token_of(ACCOUNT2()) == 1, 'token_of transfer failed');
    assert(erc721.token_of(ACCOUNT1()) == 2, 'sender index changed early');

    start_cheat_caller_address(erc721.contract_address, ACCOUNT1());
    erc721.transferFrom(ACCOUNT1(), ACCOUNT3(), 2);
    assert(erc721.ownerOf(2) == ACCOUNT3(), 'transferFrom failed');
    assert(erc721.token_of(ACCOUNT3()) == 2, 'token_of camel failed');
    assert(erc721.token_of(ACCOUNT1()) == 0, 'sender stale token_of');
}

#[test]
fn test_erc721_nogame_safe_transfers_update_token_of() {
    let (erc721, _) = deploy_nogame_erc721();
    let receiver1 = deploy_erc721_receiver_mock();
    let receiver2 = deploy_erc721_receiver_mock();

    start_cheat_caller_address(erc721.contract_address, DEPLOYER());
    erc721.mint(ACCOUNT1(), 10);
    erc721.mint(ACCOUNT1(), 11);

    let data = array![];
    start_cheat_caller_address(erc721.contract_address, ACCOUNT1());
    erc721.safe_transfer_from(ACCOUNT1(), receiver1, 10, data.span());
    assert(erc721.owner_of(10) == receiver1, 'safe_transfer failed');
    assert(erc721.token_of(receiver1) == 10, 'safe token_of to failed');
    assert(erc721.token_of(ACCOUNT1()) == 11, 'safe sender index failed');

    let data = array![];
    erc721.safeTransferFrom(ACCOUNT1(), receiver2, 11, data.span());
    assert(erc721.ownerOf(11) == receiver2, 'safeTransfer failed');
    assert(erc721.token_of(receiver2) == 11, 'safe camel token_of failed');
    assert(erc721.token_of(ACCOUNT1()) == 0, 'safe sender stale index');
}

#[test]
fn test_erc721_upgradeable_constructor_and_public_abi() {
    let erc721 = deploy_upgradeable_erc721();

    assert(erc721.name() == "Upgradeable Planet", 'upgradeable name failed');
    assert(erc721.symbol() == "UPL", 'upgradeable symbol failed');
    assert(erc721.balance_of(ACCOUNT1()) == 2, 'upgradeable balance failed');
    assert(erc721.balanceOf(ACCOUNT1()) == 2, 'upgradeable balanceOf failed');
    assert(erc721.owner_of(100) == ACCOUNT1(), 'upgradeable owner_of failed');
    assert(erc721.ownerOf(101) == ACCOUNT1(), 'upgradeable ownerOf failed');
    assert(erc721.token_uri(100) == "https://nogame.com/upgradeable/100", 'upgradeable uri failed');
    assert(
        erc721.tokenURI(101) == "https://nogame.com/upgradeable/101", 'upgradeable tokenURI failed',
    );

    start_cheat_caller_address(erc721.contract_address, ACCOUNT1());
    erc721.approve(ACCOUNT2(), 100);
    assert(erc721.get_approved(100) == ACCOUNT2(), 'upgradeable get_approved failed');
    assert(erc721.getApproved(100) == ACCOUNT2(), 'upgradeable getApproved failed');
    erc721.set_approval_for_all(ACCOUNT3(), true);
    assert(erc721.is_approved_for_all(ACCOUNT1(), ACCOUNT3()), 'upgradeable approval failed');
    assert(erc721.isApprovedForAll(ACCOUNT1(), ACCOUNT3()), 'approval camel failed');

    start_cheat_caller_address(erc721.contract_address, ACCOUNT2());
    erc721.transfer_from(ACCOUNT1(), ACCOUNT2(), 100);
    assert(erc721.owner_of(100) == ACCOUNT2(), 'transfer_from failed');

    start_cheat_caller_address(erc721.contract_address, ACCOUNT3());
    erc721.transferFrom(ACCOUNT1(), ACCOUNT3(), 101);
    assert(erc721.ownerOf(101) == ACCOUNT3(), 'upgradeable transferFrom failed');
}

fn deploy_nogame_erc721() -> (IERC721NoGameDispatcher, IERC721MetadataDispatcher) {
    let contract = declare("ERC721NoGame").unwrap_syscall().contract_class();
    let name: ByteArray = "Nogame Planet";
    let symbol: ByteArray = "NGPL";
    let base_uri: ByteArray = "https://nogame.com/planet/";
    let mut calldata: Array<felt252> = array![];
    calldata.append_serde(name);
    calldata.append_serde(symbol);
    calldata.append_serde(base_uri);
    calldata.append_serde(DEPLOYER());
    calldata.append_serde(DEPLOYER());
    let (contract_address, _) = contract.deploy(@calldata).expect('failed erc721');

    (IERC721NoGameDispatcher { contract_address }, IERC721MetadataDispatcher { contract_address })
}

fn deploy_upgradeable_erc721() -> ERC721ABIDispatcher {
    let contract = declare("ERC721Upgradeable").unwrap_syscall().contract_class();
    let name: ByteArray = "Upgradeable Planet";
    let symbol: ByteArray = "UPL";
    let base_uri: ByteArray = "https://nogame.com/upgradeable/";
    let token_ids: Array<u256> = array![100, 101];
    let mut calldata: Array<felt252> = array![];
    calldata.append_serde(name);
    calldata.append_serde(symbol);
    calldata.append_serde(base_uri);
    calldata.append_serde(ACCOUNT1());
    calldata.append_serde(token_ids.span());
    calldata.append_serde(DEPLOYER());
    let (contract_address, _) = contract.deploy(@calldata).expect('failed erc721 preset');

    ERC721ABIDispatcher { contract_address }
}

fn deploy_erc721_receiver_mock() -> ContractAddress {
    let contract = declare("ERC721ReceiverMock").unwrap_syscall().contract_class();
    let calldata: Array<felt252> = array![];
    let (contract_address, _) = contract.deploy(@calldata).expect('failed erc721 receiver');
    contract_address
}

#[starknet::contract]
mod ERC721ReceiverMock {
    use openzeppelin_introspection::src5::SRC5Component;
    use openzeppelin_token::erc721::ERC721ReceiverComponent;
    use starknet::ContractAddress;

    component!(path: ERC721ReceiverComponent, storage: erc721_receiver, event: ERC721ReceiverEvent);
    component!(path: SRC5Component, storage: src5, event: SRC5Event);

    #[abi(embed_v0)]
    impl ERC721ReceiverMixinImpl =
        ERC721ReceiverComponent::ERC721ReceiverMixinImpl<ContractState>;
    impl ERC721ReceiverInternalImpl = ERC721ReceiverComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        erc721_receiver: ERC721ReceiverComponent::Storage,
        #[substorage(v0)]
        src5: SRC5Component::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        ERC721ReceiverEvent: ERC721ReceiverComponent::Event,
        #[flat]
        SRC5Event: SRC5Component::Event,
    }

    #[constructor]
    fn constructor(ref self: ContractState) {
        self.erc721_receiver.initializer();
    }
}
