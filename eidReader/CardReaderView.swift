import SwiftUI

struct CardReaderView: View {
    let card: SlotManagerObserver.Card
    
    var body: some View {
        switch card.state {
        case .probing:
            Text("Connecting to card").padding()
        case .idCard(let card):
            CardReadingView(card: card)
        case .notConnected:
            Text("It looks like there is no card in the card reader").padding()
        case .otherCard:
            Text("This card does not look like a Belgian ID card").padding()
        case .unreadableCard:
            Text("The card in the reader is unreadable").padding()
        }
    }        
}

extension Image {
    #if os(macOS)
    init(xImage: XImage) { self.init(nsImage: xImage) }
    #else
    init(xImage: XImage) { self.init(uiImage: xImage) }
    #endif
}

#if os(macOS)
typealias XImage = NSImage
#else
typealias XImage = UIImage
#endif

#Preview {
    CardReaderView(card: .init(state: .probing))
}
