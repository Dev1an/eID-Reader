import Observation
import CryptoTokenKit

struct SlotManagerObserver {
    let slotManager: TKSmartCardSlotManager
    let slotNamesObserver: NSKeyValueObservation
    let slotCollection: SlotCollection

    init() {
        let slotCollection = SlotCollection()
        let slotManager = TKSmartCardSlotManager()
        var slotMapping = Task<Void, Error> {}
        slotNamesObserver = slotManager.observe(\.slotNames, options: .initial) { manager, change in
            slotMapping.cancel()
            slotMapping = Task {
                let newSlots = try await slotManager.slots.map(SlotObserver.init)
                try await MainActor.run {
                    try Task.checkCancellation()
                    slotCollection.slotObservers = newSlots
                }
            }
        }
        self.slotCollection = slotCollection
        self.slotManager = slotManager
    }
    
    @Observable
    class SlotCollection {
        var slotObservers = [SlotObserver]()
    }
    
    struct SlotObserver {
        let slot: TKSmartCardSlot
        let observer: NSKeyValueObservation
        let card: Card
        
        init(slot: TKSmartCardSlot) {
            var stateChange = Task<Void, Error> {}
            func override(_ closure: @escaping ()->Void) {
                stateChange.cancel()
                stateChange = Task {
                    try await MainActor.run {
                        try Task.checkCancellation()
                        closure()
                    }
                }
            }
            let card = Card(state: .notConnected)
            observer = slot.observe(\.state, options: .initial) { slot, change in
                switch slot.state {
                case .validCard:
                    if let smartcard = slot.makeSmartCard() {
                        stateChange.cancel()
                        stateChange = Task {
                            do {
                                let eidCard = BeIDCard(card: smartcard)
                                try await eidCard.beginSession()
                                defer { eidCard.endSession() }
                                try await eidCard.select(file: .id)
                                try await MainActor.run {
                                    try Task.checkCancellation()
                                    card.state = .idCard(eidCard)
                                }
                            } catch is CancellationError {}
                            catch {
                                await MainActor.run {
                                    card.state = .otherCard(smartcard)
                                }
                            }
                        }
                    } else {
                        override { card.state = .unreadableCard }
                    }
                case .empty, .missing:
                    override { card.state = .notConnected }
                case .muteCard:
                    override { card.state = .unreadableCard }
                case .probing:
                    override { card.state = .probing }
                @unknown default:
                    override { card.state = .unreadableCard }
                }
            }
            self.slot = slot
            self.card = card
        }
    }
    
    @Observable
    class Card {
        var state: State
        
        init(state: State) {
            self.state = state
        }
        
        enum State {
            case probing
            case idCard(BeIDCard)
            case otherCard(TKSmartCard)
            case unreadableCard
            case notConnected
        }
    }
}

extension TKSmartCardSlotManager {
    var slots: [TKSmartCardSlot] {
        get async throws {
            try await withThrowingTaskGroup(of: TKSmartCardSlot?.self, returning: [TKSmartCardSlot].self) { group in
                for name in slotNames {
                    guard group.addTaskUnlessCancelled(operation: {
                        await self.getSlot(withName: name)
                    }) else { throw CancellationError() }
                }
                var slots = [TKSmartCardSlot]()
                slots.reserveCapacity(slotNames.count)
                while let slot = try await group.next() {
                    if let slot { slots.append(slot) }
                }
                return slots
            }
        }
    }
}

extension TKSmartCardSlot.State: @retroactive CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .missing:
            "missing"
        case .empty:
            "empty"
        case .probing:
            "probing"
        case .muteCard:
            "muteCard"
        case .validCard:
            "validCard"
        @unknown default:
            "unknown"
        }
    }
}
