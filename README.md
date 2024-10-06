# Project Title
Auction Starknet Smart Contract

## Deployment Details

```
class_hash: 0x2fd82ed922855defe0fd54e07048ff0bf95fa50ea6660761c44029dba17e568

```

## Interact with the Smart Contract

Interact with the Smart Contract on [Starkscan!](https://sepolia.starkscan.co/contract/0x0034d2b3bd8ff85077c14883b1322e5b6706f7ee8aa92e8cf9b2fa06554fa102#read-write-contract-sub-read)
```
0x0034d2b3bd8ff85077c14883b1322e5b6706f7ee8aa92e8cf9b2fa06554fa102
```

## Contract Interface
These are the list of functions to interact with
```cairo
    fn register_item(ref self: TContractState, item_name: ByteArray);
    fn unregister_item(ref self: TContractState, item_name: ByteArray);
    fn bid(ref self: TContractState, item_name: ByteArray, amount: u32);
    fn get_highest_bidder(self: @TContractState, item_name: ByteArray) -> u32;
    fn is_registered(self: @TContractState, item_name: ByteArray) -> bool;
    fn get_registered_items(self: @TContractState) -> Array<(ByteArray, u32)>;
    fn get_registered_item(self: @TContractState, item_name: ByteArray) -> (ByteArray, u32);
    fn get_item_count(self: @TContractState) -> u64;
```


