//
//  DataFetcher.swift
//  eidReader
//
//  Created by Damiaan Dufaux on 28/08/2024.
//

import SwiftUI
import CoreLocation

struct CardReadingView: View {
    let geocoder = CLGeocoder()
    
    enum ReadingState {
        case readingTextData
        case readingPhoto(BeIDCardData.Identification, BeIDCardData.Address, IdCardView.PhotoLoadProgress)
        case error(Error)
    }

    let card: BeIDCard
    
    @State var state = ReadingState.readingTextData
    @State var location: CLLocationCoordinate2D?
    
    var body: some View {
        switch state {
        case .readingTextData:
            Text("Reading ID")
            .padding()
            .task(readCard)
        case .readingPhoto(let identification, let address, let progress):
            IdCardView(idData: identification, addressData: address, photoProgress: progress, location: location)
        case .error(let error):
            Text("Encountered an error while reading the ID card \(error.localizedDescription)")
                .padding()
        }
    }
    
    @Sendable func readCard() async {
        do {
            try await card.beginSession()
            defer { card.endSession() }
            try await card.select(file: .id)
            var idData = Data(capacity: 512)
            var idIterator = card.readByteStream()
            while let chunk = try await idIterator.next() {
                idData.append(chunk)
            }
            let id = try BeIDCardData.Identification(idFile: idData)
            try await card.select(file: .address)
            let addressData = try await card.readBytes(length: 0)
            let address = try BeIDCardData.Address(addressFile: addressData)
            Task {
                let results = try await geocoder.geocodeAddressString(address.full)
                if let location = results.first?.location?.coordinate {
                    await MainActor.run {
                        self.location = location
                    }
                }
            }
            await MainActor.run {
                state = .readingPhoto(id, address, .loading(0))
            }
            try await card.select(file: .photo)
            var photoData = Data(capacity: 256*15)
            var photoIterator = card.readByteStream()
            while let chunk = try await photoIterator.next() {
                photoData.append(chunk)
                await MainActor.run {
                    state = .readingPhoto(id, address, .loading(photoData.count))
                }
            }
            guard let photo = XImage(data: photoData) else {
                throw UnableToLoadPhoto(data: photoData)
            }
            await MainActor.run {
                state = .readingPhoto(id, address, .loaded(photo))
            }
        } catch {
            await MainActor.run {
                state = .error(error)
            }
        }
    }
        
    struct UnableToLoadPhoto: Error {
        let data: Data
    }
}

import CryptoTokenKit
#Preview {
    CardReadingView(card: BeIDCard.init(card: TKSmartCard()))
}
