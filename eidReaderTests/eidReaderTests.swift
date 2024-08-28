//
//  eidReaderTests.swift
//  eidReaderTests
//
//  Created by Damiaan Dufaux on 24/08/2024.
//

import Testing
import CryptoTokenKit
@testable import eidReader
import AppKit

struct eidReaderTests {

    @Test func readIdFile() async throws {
        let manager = TKSmartCardSlotManager.default!
        print(manager.slotNames)
        let smartcard = await manager.getSlot(withName: manager.slotNames[0])!.makeSmartCard()!
        
        let card = BeIDCard(card: smartcard)
        
        try await card.beginSession()
        defer { card.endSession() }
        
        try await card.select(file: .id)
        let idData = try await card.readBytes(length: 0)
        print(try BeIDCardData.Identification(idFile: idData))
        
        try await card.select(file: .address)
        let addressData = try await card.readBytes(length: 0)
        print(try BeIDCardData.Address(addressFile: addressData))

        try await card.select(file: .photo)
        var imageData = Data(capacity: 15 * 256)
//        for try await data in card.readByteStream() {
//            imageData.append(data)
//            print("Photo data", data.count, imageData.count)
//        }
        
        let image = NSImage(data: imageData)!
        print(image.size)
    }
    
    @Test func insertAndRemoveVirtualCard() async throws {
        actor Inspector {
            var changed = false
            func change() { changed = true }
        }
        let insertion = Inspector()
        let manager = VirtualSlotManager()
        let managerMutator = VirtualSlotManager.Mutator(manager: manager)
        var observation = manager.observe(\.slotNames) { manager, change in
            Task { await insertion.change() }
        }
        let name = "hello"
        #expect(manager.slotNames.contains(name) == false)
        let slot = managerMutator.addSlot(name: name, card: TKSmartCard())
        #expect(manager.slotNames.contains(name))
        #expect(slot.name == name)
        try await Task.sleep(for: .seconds(0.1))
        #expect(await insertion.changed)
        let returnedSlot = await manager.getSlot(withName: name)
        #expect(slot === returnedSlot)
        
        #expect(slot.state == .empty)
        #expect(slot.makeSmartCard() == nil)
        let slotMutator = VirtualSlotManager.Slot.Mutator(slot: slot)
        slotMutator.make(state: .validCard)
        #expect(slot.state == .validCard)
        let card = slot.makeSmartCard()
        #expect(card != nil)
        
        

        let removal = Inspector()
        observation = manager.observe(\.slotNames) { manager, change in
            Task { await removal.change() }
        }
        managerMutator.remove(slot: slot)
        #expect(manager.slotNames.contains(name) == false)
        try await Task.sleep(for: .seconds(0.1))
        #expect(await removal.changed)

        #expect(observation.observationInfo == nil)
    }

}
