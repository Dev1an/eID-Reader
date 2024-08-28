import Foundation

extension BeIDCardData.Identification {
    private static let validityDateFormatter = DateFormatter(format: "dd.MM.yyyy")
    
    init(idFile: Data) throws {
        let fields = Self.loadDictionary(from: idFile.dropLast(2))
        
        func data(_ offset: Self.ByteOffset) throws -> Data.SubSequence {
            guard let data = fields[offset] else { throw NoSuchField(field: offset) }
            return data
        }        
        
        func date(_ string: String, using formatter: DateFormatter) throws -> Date {
            guard let date = formatter.date(from: string) else { throw CouldNotParseDate(string: string, formatter: formatter) }
            return date
        }
        
        cardNumber = try BeIDCardData.utf8(data(.cardNumber))
        validityStart = try date(BeIDCardData.utf8(data(.validityStart)), using: Self.validityDateFormatter)
        validityEnd = try date(BeIDCardData.utf8(data(.validityEnd)), using: Self.validityDateFormatter)
        birthPlace = try BeIDCardData.utf8(data(.birthPlace))
        let nationalIdNumber = try data(.nationalIdNumber)
        let birthMonthAndDay = try BeIDCardData.utf8(nationalIdNumber.dropLast(5).dropFirst(2))
        let fullBirthYear = try BeIDCardData.utf8( data(.birthday).suffix(4) )
        birthday = try date(fullBirthYear + birthMonthAndDay, using: Self.fullYmdFormatter)
        let birthNumberDigits = nationalIdNumber.suffix(5).dropLast(2).map {UInt16($0 & 0b1111)}
        birthNumber = 100 * birthNumberDigits[0] + 10*birthNumberDigits[1] + birthNumberDigits[2]
        lastName = try BeIDCardData.utf8(data(.lastName))
        firstName = try BeIDCardData.utf8(data(.firstName))
        otherName = try BeIDCardData.utf8(data(.otherName))
        nationality = try BeIDCardData.utf8(data(.nationality))
        releasePlace = try BeIDCardData.utf8(data(.releasePlace))
    }

    enum ByteOffset: UInt8 {
        case fileStructureVersion = 0, cardNumber, chipNumber, validityStart, validityEnd, releasePlace, nationalIdNumber, lastName, firstName, otherName, nationality, birthPlace, birthday, sex, nobleCondition, documentType, specialStatus, pictureHash, duplicate, specialOrganisation, memberOfFamily, protection
    }
    
    struct NoSuchField: Error {
        let field: BeIDCardData.Identification.ByteOffset
    }
    struct CouldNotParseDate: LocalizedError {
        let string: String
        let formatter: DateFormatter
    }
    
    static func loadDictionary(from data: Data) -> [Self.ByteOffset: Data.SubSequence] {
        var dictionary = [Self.ByteOffset: Data.SubSequence]()
        var cursor = data.startIndex + 2
        while cursor<data.endIndex {
            let length = Int( data[cursor-1] )
            if let offset = Self.ByteOffset(rawValue: data[cursor-2]) {
                dictionary[offset] = data[cursor ..< min(cursor+length, data.endIndex)]
            }
            cursor += length + 2
        }
        return dictionary
    }
}
