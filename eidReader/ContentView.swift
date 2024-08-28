//
//  ContentView.swift
//  eidReader
//
//  Created by Damiaan Dufaux on 24/08/2024.
//

import SwiftUI

struct ContentView: View {
    @State var readerManager = SlotManagerObserver()
    
    var body: some View {
        if let reader = readerManager.slotCollection.slotObservers.first {
            CardReaderView(card: reader.card).navigationTitle(reader.slot.name)
        } else {
            Text("No reader found")
        }
    }
}

#Preview {
    ContentView()
}
