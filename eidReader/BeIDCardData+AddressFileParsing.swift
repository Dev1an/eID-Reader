//
//  Address+FileParsing.swift
//  eidReader
//
//  Created by Damiaan Dufaux on 24/08/2024.
//

import Foundation

extension BeIDCardData.Address {
    init(addressFile: Data) throws {
        let streetRange = 2 ..< Int(addressFile[1]) + 2
        let postalCodeRange = streetRange.upperBound + 2  ..<  streetRange.upperBound + Int(addressFile[streetRange.upperBound+1]) + 2
        let cityRange = postalCodeRange.upperBound + 2  ..<  postalCodeRange.upperBound + Int(addressFile[postalCodeRange.upperBound+1]) + 2
        
        street = try BeIDCardData.utf8(addressFile[streetRange])
        postalCode = try BeIDCardData.ascii(addressFile[postalCodeRange])
        city = try BeIDCardData.utf8(addressFile[cityRange])
    }
}
