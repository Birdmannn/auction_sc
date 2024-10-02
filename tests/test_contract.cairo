use snforge_std::{declare, ContractClassTrait, DeclareResultTrait};
use auction_sc::{
    IAuctionDispatcher, IAuctionDispatcherTrait, IAuctionSafeDispatcher, IAuctionSafeDispatcherTrait
};
use starknet::ContractAddress;


fn deploy_contract(name: ByteArray) -> ContractAddress {
    let contract = declare(name).unwrap().contract_class();
    let (contract_address, _) = contract.deploy(@array![]).unwrap();
    contract_address
}

#[test]
fn test_register_and_get_items() {
    let contract_address = deploy_contract("Auction");
    let dispatcher = IAuctionDispatcher { contract_address };
    let item_1: ByteArray = "dogs";
    let item_2: ByteArray = "a sea horse with the need to be longer than a felt";
    dispatcher.register_item(item_1);
    dispatcher.register_item(item_2);
    
    let item_1: ByteArray = "dogs";
    let item_2: ByteArray = "a sea horse with the need to be longer than a felt";
    let (item_1_ref, _) = dispatcher.get_registered_item(item_1);
    let (item_2_ref, _) = dispatcher.get_registered_item(item_2);
    
    let item_1: ByteArray = "dogs";
    let item_2: ByteArray = "a sea horse with the need to be longer than a felt";
    // assert_eq!(item_1, item_1_ref);
    // assert_eq!(item_2, item_2_ref);
    assert(item_1 == item_1_ref, 'not equal');
    assert(item_2 == item_2_ref, 'second not equal');
    let items_in_store = dispatcher.get_item_count();
    assert(items_in_store == 2_u64, 'item count != 2');
}