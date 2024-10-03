#[starknet::interface]
pub trait IAuction<TContractState> {
    fn register_item(ref self: TContractState, item_name: ByteArray);
    fn unregister_item(ref self: TContractState, item_name: ByteArray);
    fn bid(ref self: TContractState, item_name: ByteArray, amount: u32);
    fn get_highest_bidder(self: @TContractState, item_name: ByteArray) -> u32;
    fn is_registered(self: @TContractState, item_name: ByteArray) -> bool;
    fn get_registered_items(self: @TContractState) -> Array<(ByteArray, u32)>;
    fn get_registered_item(self: @TContractState, item_name: ByteArray) -> (ByteArray, u32);
    fn get_item_count(self: @TContractState) -> u64;
}

#[starknet::contract]
mod Auction {
    use starknet::event::EventEmitter;
    use starknet::storage::StoragePathEntry;
    use core::starknet::storage::{
        Map, StoragePointerReadAccess, StoragePointerWriteAccess, Vec, VecTrait, MutableVecTrait
    };

    #[storage]
    struct Storage {
        bid: Map::<felt252, u32>,
        register: Map::<felt252, (ByteArray, bool)>,
        item_list: Vec::<ByteArray>,
        items_in_store: u64,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        RegisteredItem: RegisteredItem,
        Bid: Bid
    }

    #[derive(Drop, starknet::Event)]
    struct RegisteredItem {
        #[key]
        item_name: ByteArray,
        status: ByteArray
    }

    #[derive(Drop, starknet::Event)]
    struct Bid {
        #[key]
        item_name: ByteArray,
        bid: u32
    }

    #[constructor]
    fn constructor(ref self: ContractState) {
        self.items_in_store.write(0);
    }

    #[abi(embed_v0)]
    impl AuctionImpl of super::IAuction<ContractState> {
        fn register_item(ref self: ContractState, mut item_name: ByteArray) {
            let mut items_in_store: u64 = self.items_in_store.read();
            let mut item_id: felt252 = self.resolve_and_assert_name(ref item_name);
            let item_id_ref = @item_id;
            self.bid.entry(item_id).write(0);
            self.register.entry(*item_id_ref).write((item_name, true));
            self.items_in_store.write(items_in_store + 1);
            self.item_list.append().write(self.get_item_name(item_id_ref));
            
            let item_name: ByteArray = self.get_item_name(item_id_ref);
            self.emit(RegisteredItem { item_name, status: "registered" });
        }

        fn unregister_item(ref self: ContractState, mut item_name: ByteArray) {
            let mut items_in_store: u64 = self.items_in_store.read();
            let item_id: felt252 = InternalFunctions::resolve_name(ref item_name);
            
            let mut found: bool = false;
            for i in 0..self.item_list.len() {
                if item_name == self.item_list.at(i).read() {
                    found = true;
                    self.item_list.at(i).write("");
                    self.emit(RegisteredItem { item_name, status: "Unregistered" });
                    break;
                }
            };
            assert(found, 'Item not found.');
            self.register.entry(item_id).write(("", false));
            self.items_in_store.write(items_in_store - 1);
        }

        fn bid(ref self: ContractState, mut item_name: ByteArray, amount: u32) {
            let item_id: felt252 = InternalFunctions::resolve_name(ref item_name);
            let(_, is_registered) = self.register.entry(item_id).read();
            assert!(is_registered == true, "The item {} you want to bid on is not registered", item_name);
            let item_id_ref = @item_id;
            let bid = @amount;
            let bid_to_match: u32 = self.bid.entry(*item_id_ref).read();
            assert!(bid > @bid_to_match, "Your bid must be greater than the previous bid of {}", bid_to_match);
            self.bid.entry(item_id).write(amount);
            self.emit(Bid { item_name, bid: *bid });
        }

        fn get_highest_bidder(self: @ContractState, mut item_name: ByteArray) -> u32 {
            let item_id: felt252 = InternalFunctions::resolve_name(ref item_name);
            self.bid.entry(item_id).read()
        }

        fn is_registered(self: @ContractState, mut item_name: ByteArray) -> bool {
            let item_id: felt252 = InternalFunctions::resolve_name(ref item_name);
            let (_, is_registered) = self.register.entry(item_id).read();
            is_registered
        }

        fn get_registered_items(self: @ContractState) -> Array<(ByteArray, u32)> {
            let mut registered_items: Array<(ByteArray, u32)> = array![];
            
            for i in 0..self.item_list.len() {
                let mut item_name: ByteArray = self.item_list.at(i).read();
                if item_name != "" {
                    let item_id = InternalFunctions::resolve_name(ref item_name);
                    let item_bid: u32 = self.bid.entry(item_id).read();
                    registered_items.append((item_name, item_bid));
                }
            };
            registered_items
        }

        fn get_registered_item(self: @ContractState, mut item_name: ByteArray) -> (ByteArray, u32) {
            let item_id: felt252 = InternalFunctions::resolve_name(ref item_name);
            (item_name, self.bid.entry(item_id).read())
        }

        fn get_item_count(self: @ContractState) -> u64 {
            self.items_in_store.read()
        }
    }

    #[generate_trait]
    impl InternalFunctions of InternalFunctionTrait {
        fn resolve_name(ref item_name: ByteArray) -> felt252 {
            let mut item_identifier: felt252 = '';
            let mut i: usize = 0;
            while let Option::Some(value) = item_name.at(i) {
                item_identifier += value.into();
                i += 1;
                if i == 31 {
                    break;
                }
            };
            item_identifier
        }

        fn resolve_and_assert_name(self: @ContractState, ref item_name: ByteArray) -> felt252 {
            let item_id: felt252 = Self::resolve_name(ref item_name);
            let (_, is_registered) = self.register.entry(item_id).read();
            assert!(
                is_registered == false,
                "Item already exists or Invalid name. Please try changing the name"
            );
            item_id
        }

        fn get_item_name(self: @ContractState, item_id_ref: @felt252) -> ByteArray {
            let (item_name, _) = self.register.read(*item_id_ref);
            item_name
        }
    }
}
