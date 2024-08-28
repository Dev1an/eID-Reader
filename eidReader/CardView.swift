//
//  IdCardView.swift
//  eidReader
//
//  Created by Damiaan Dufaux on 28/08/2024.
//

import SwiftUI
import MapKit

struct IdCardView: View {
    let idData: BeIDCardData.Identification
    let addressData: BeIDCardData.Address
    let photoProgress: PhotoLoadProgress
    let location: CLLocationCoordinate2D?
    
    @State var position = MapCameraPosition.automatic
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 20) {
                photo
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .frame(minWidth: 105, minHeight: 150)
                text.fixedSize(horizontal: true, vertical: false)
                Spacer(minLength: 0)
            }.padding()
            Divider()
            Map(position: $position) {
                if let location {
                    Marker(coordinate: location) {
                        Label("Domicile", systemImage: "house")
                    }
                }
            }.onChange(of: location) { _, newValue in
                if let location {
                    move(to: location)
                }
            }

            .frame(minHeight: 150).id("map")
        }
    }
    
    func move(to location: CLLocationCoordinate2D) {
        position = .region(MKCoordinateRegion(center: location, latitudinalMeters: 2000, longitudinalMeters: 2000))
    }
    
    var photo: some View {
        Group {
            switch photoProgress {
            case .loaded(let photo):
                Image(xImage: photo)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            case .loading(let progress):
                RadialGradient(
                    colors: [.init(white: 0.95), .black],
                    center: .center,
                    startRadius: 0,
                    endRadius: 1000
                )
                .aspectRatio(
                    7/10,
                    contentMode: .fit
                )
                .overlay {
                    VStack {
                        Spacer()
                        Image(systemName: "person.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .padding(.horizontal, 30)
                            .foregroundStyle(.tertiary)
                        ProgressView(value: min(1, Double(progress)/256/11))
                            .progressViewStyle(.linear)
                            .padding()
                    }
                }
            }
        }
    }
    
    var text: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(join(\.firstName, \.otherName, \.lastName)).textSelection(.enabled)
                Text(idData.nationality).foregroundStyle(.secondary)
                switch idData.sex {
                case .female:
                    Text("female").foregroundStyle(.tertiary)
                case .male:
                    Text("male").foregroundStyle(.tertiary)
                }
            }
            HStack {
                Text("Born in").foregroundStyle(.secondary)
                Text(idData.birthPlace).textSelection(.enabled)
                Text("on").foregroundStyle(.secondary)
                Text(idData.birthday.formatted(
                    date: .complete,
                    time: .omitted
                )).textSelection(.enabled)
            }
            HStack {
                Text("Domicile").foregroundStyle(.secondary)
                Text(addressData.full).textSelection(.enabled)
            }
            HStack {
                Text("ID of the national register").foregroundStyle(.secondary)
                Text(idData.nationalIDNumber).textSelection(.enabled)
            }.padding(.bottom, 8)
            
            HStack {
                Text("Card").foregroundStyle(.secondary)
                Text(idData.cardNumber).textSelection(.enabled)
            }
            HStack {
                Text("Valid from").foregroundStyle(.secondary)
                Text(idData.validityStart.formatted(date: .long, time: .omitted))
                Text("until").foregroundStyle(.secondary)
                Text(idData.validityEnd.formatted(date: .long, time: .omitted))
            }
        }
    }
    
    func join(_ paths: KeyPath<BeIDCardData.Identification, String>...) -> String {
        paths.map{idData[keyPath:$0]}.joined(separator: " ")
    }
    
    enum PhotoLoadProgress {
        case loading(Int)
        case loaded(XImage)
    }
}

#Preview {
    IdCardView(
        idData: BeIDCardData.Identification(cardNumber: "590032092878", releasePlace: "Antwerpen", firstName: "Dieter", lastName: "Bosmans", otherName: "Dinges", nationality: "Belg", birthPlace: "Gent", validityStart: .now, validityEnd: .now, birthday: .init(timeIntervalSince1970: 0), birthNumber: 21),
        addressData: .init(street: "Kronkelweg 9", city: "Scheveninge", postalCode: "1234"),
        photoProgress: .loading(300),
        location: CLLocationCoordinate2D(latitude: 50.879499, longitude: 4.701302)
    )
}

extension CLLocationCoordinate2D: @retroactive Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}
