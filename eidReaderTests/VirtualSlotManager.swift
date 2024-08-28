import CryptoTokenKit

class VirtualSlotManager: TKSmartCardSlotManager {
    private var store = Store()
    
    override var slotNames: [String] { store.slots.map(\.name) }
    
    override func getSlot(withName name: String) async -> TKSmartCardSlot? {
        for slot in store.slots {
            if slot.name == name { return slot }
        }
        return nil
    }
    
    struct Store {
        var slots = [Slot]()
    }
    
    class Slot: TKSmartCardSlot {
        private var store: Store
        
        init(store: Store) {
            self.store = store
        }
        
        override var name: String { store.name }
        override var state: TKSmartCardSlot.State { store.state }
        override func makeSmartCard() -> TKSmartCard? {
            if state == .validCard { store.card }
            else { nil }
        }
    }
    
    struct Mutator {
        let manager: VirtualSlotManager
        
        func addSlot(name: String, card: TKSmartCard) -> Slot {
            let slot = Slot(store: .init(name: name, card: card))
            manager.willChangeValue(for: \.slotNames)
            manager.store.slots.append(slot)
            manager.didChangeValue(for: \.slotNames)
            return slot
        }
        
        func remove(slot: Slot) {
            var snapshot = manager.store.slots
            let oldCount = snapshot.count
            snapshot.removeAll { $0 === slot }
            if snapshot.count != oldCount {
                manager.willChangeValue(for: \.slotNames)
                manager.store.slots = snapshot
                manager.didChangeValue(for: \.slotNames)
            }
        }
    }
    
    class Card: TKSmartCard {
        private let store: Store
        var ready = true
        
        init(store: Store) {
            self.store = store
        }
        
        override func beginSession() async throws -> Bool {
            guard ready else { return false }
            ready = false
            return true
        }
        override func endSession() {
            ready = true
        }
    }
}

extension VirtualSlotManager.Slot {
    struct Store {
        let name: String
        var state: TKSmartCardSlot.State = .empty
        let card: TKSmartCard
    }
    
    struct Mutator {
        let slot: VirtualSlotManager.Slot
        
        func make(state: TKSmartCardSlot.State) {
            slot.willChangeValue(for: \.state)
            slot.store.state = state
            slot.didChangeValue(for: \.state)
        }
    }
}

import eidReader

extension VirtualSlotManager.Card {
    struct Store {
        let id: BeIDCardData.Identification
    }
}
