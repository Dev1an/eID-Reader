import CryptoTokenKit

class BeIDCard {
    let card: TKSmartCard
    
    init(card: TKSmartCard) {
        self.card = card
    }
    
    public enum FilePath {
        case id
        case address
        case photo
        
        var data: Data {
            switch self {
            case .id:      Data([0xDF, 0x01, 0x40, 0x31])
            case .address: Data([0xDF, 0x01, 0x40, 0x33])
            case .photo:   Data([0xDF, 0x01, 0x40, 0x35])
            }
        }
    }
    
    func beginSession() async throws {
        try await card.beginSession()
    }
    
    func endSession() {
        card.endSession()
    }
        
    func selectFileCommand(path: FilePath) -> Data {
        selectFileCommandHeader + path.data
    }
    
    public func select(file: FilePath) async throws {
        let responseData = try await card.transmit(selectFileCommand(path: file))
        guard responseData.count == 2 else {
            throw UnexpectedResponseLength(expected: 2, actual: responseData.count)
        }
        let response = ResponseStatus(data: responseData)
        try response.check()
    }
    
    /// Read bytes from current file
    /// as described in section "7.2.3 READ BINARY command" of ISO 7816-4
    ///
    /// - Parameters:
    ///   - length: number of bytes to read (Le)
    ///   - offset: number of bytes to skip (15-bit unsigned integer, ranging from 0 to 32 767)
    public func readBytes(length: UInt8, offset: UInt16 = 0) async throws -> Data {
        var packet = Data([
            0x00, // Commmand header: CLA (Class byte)
            0xB0,                  // INS (Instruction byte: READ BINARY)
               0,                  // P1  (Parameter byte: offset's high byte)
               0,                  // P2  (Parameter byte: offset's  low byte)
            
            length // Number of bytes to read. 0 means entire file
        ])
        packet.withUnsafeMutableBytes { pointer in
            pointer.storeBytes(of: offset.bigEndian, toByteOffset: 2, as: UInt16.self)
        }
        let data = try await card.transmit(packet)
        guard data.count > 1 else {
            throw UnexpectedResponseLength(expected: 2, actual: data.count)
        }
        let responseOffset = data.endIndex - 2
        let response = ResponseStatus(data: data.suffix(from: responseOffset))
        do {
            try response.check()
            return data.prefix(upTo: responseOffset)
        } catch ResponseStatus.Fatal.expectedLength(let correctLength) {
            return try await readBytes(length: correctLength, offset: offset)
        }
    }
    
    func readByteStream() -> AsyncData {
        AsyncData(card: self)
    }
    
    struct AsyncData: AsyncIteratorProtocol {
        private let card: BeIDCard
        private var offset = UInt16(0)
        private var isInProgress = true
        
        init(card: BeIDCard) { self.card = card }
        
        mutating func next() async throws -> Data? {
            if isInProgress {
                let data = try await card.readBytes(length: 0, offset: offset)
                offset += UInt16(data.count)
                if data.count < 256 { isInProgress = false }
                return data
            } else {
                return nil
            }
        }
    }
    
    struct ResponseStatus {
        let data: Data
    }
    
    struct UnexpectedResponseLength: Error {
        let expected: UInt8
        let actual: Int
    }
}

/// Header for file selection with a path of 4 bytes. See ISO 7816-4 secion 7.1.1
fileprivate let selectFileCommandHeader = Data([
    0x00, // CLA
    0xA4, // Select command
    0x08, // P1 (Select by DF name)
    0x0C, // P2 (?)
       4  // File path of 4 bytes
])
