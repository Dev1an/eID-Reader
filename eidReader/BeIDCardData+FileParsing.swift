import Foundation

extension BeIDCardData {
    static func utf8(_ data: Data.SubSequence) throws -> String {
        guard let string = String(data: data, encoding: .utf8) else { throw DataNotUtf8(data: data) }
        return string
    }
    static func ascii(_ data: Data.SubSequence) throws -> String {
        guard let string = String(data: data, encoding: .ascii) else { throw DataNotAscii(data: data) }
        return string
    }

    struct DataNotUtf8: Error {
        let data: Data.SubSequence
    }
    struct DataNotAscii: Error {
        let data: Data.SubSequence
    }
}
