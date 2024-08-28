import Foundation

public struct BeIDCardData {
    public struct Identification {
        static let ymdFormatter = DateFormatter(format: "YYMMdd")
        static let fullYmdFormatter = DateFormatter(format: "yyyyMMdd")
        static let ymdDottedFormatter = DateFormatter(format: "YY.MM.dd")
        
        public let cardNumber, releasePlace, firstName, lastName, otherName, nationality, birthPlace: String
        public let validityStart, validityEnd, birthday: Date
        public let birthNumber: UInt16
                
        public var nationalIDNumber : String {
            let checksum = 97 - (1000 * Int(Self.ymdFormatter.string(from: birthday))! + Int(birthNumber)) % 97
            let paddedBirthNumber = String(format: "%03d", birthNumber)
            let paddedChecksum    = String(format: "%02d", checksum)
            return Self.ymdDottedFormatter.string(from: birthday) + "-\(paddedBirthNumber).\(paddedChecksum)"
        }
        
        public var sex: Sex {
            birthNumber.isMultiple(of: 2) ? .female : .male
        }
        
        public enum Sex {
            case female, male
        }
    }
    
    public struct Address {
        public let street: String
        public let city: String
        public let postalCode: String
        
        var full: String {
            street + ", "  +
            postalCode + " " +
            city
        }
    }
}
