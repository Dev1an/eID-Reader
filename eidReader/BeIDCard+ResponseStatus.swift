import Foundation

extension BeIDCard.ResponseStatus {
    static let ok = Data([0x90,00])
    
    var category: UInt8 {
        data[data.startIndex]
    }
    
    var code: UInt8 {
        data[data.startIndex + 1]
    }
    
    func check() throws {
        if data == Self.ok {
            return
        } else {
            switch (category, code) {
            case (0x6C, let length): throw Fatal.expectedLength(length)
            case (0x6A, 0x86): throw Fatal.incorrectParameters
            default: throw Unknown(data: data)
            }
        }
    }
    
    struct Unknown: Error {
        let data: Data
    }
    
    enum Fatal: Error {
        case incorrectParameters
        case expectedLength(UInt8)
    }
}
