//
//  BEIDCard.swift
//  cardreader
//
//  Created by Damiaan on 28-12-16.
//  Copyright © 2016 Damiaan. All rights reserved.
//

import Foundation
import CryptoTokenKit
import MapKit

let idFile:        [UInt8] = [0xDF, 0x01, 0x40, 0x38]
let photoFile:     [UInt8] = [0xDF, 0x01, 0x40, 0x35]
let addressFile:   [UInt8] = [0xDF, 0x01, 0x40, 0x33]
let basicInfoFile: [UInt8] = [0xDF, 0x01, 0x40, 0x31]
let selectFile:    [UInt8] = [0,    0xA4, 0x08, 0x0C]
let readBinary:    [UInt8] = [0,    0xB0]

let geocoder = CLGeocoder()

class Address: NSObject, MKAnnotation, NSCoding {
	let street: String
	let city: String
	let postalCode: String
	var coordinate = CLLocationCoordinate2D(latitude: 0, longitude: 0)
	var title: String?
	var subtitle: String? {
		return "\(street)\n\(postalCode) \(city)"
	}
	
	enum ArchiveKey: String {
		case street, city, postalColde, title, latitude, longitude
	}
	
	func encode(with aCoder: NSCoder) {
		aCoder.encode(street, forKey: ArchiveKey.street.rawValue)
		aCoder.encode(city, forKey: ArchiveKey.city.rawValue)
		aCoder.encode(postalCode, forKey: ArchiveKey.postalColde.rawValue)
		aCoder.encode(title, forKey: ArchiveKey.title.rawValue)
		aCoder.encode(coordinate.latitude, forKey: ArchiveKey.latitude.rawValue)
		aCoder.encode(coordinate.longitude, forKey: ArchiveKey.longitude.rawValue)
	}
	
	required init?(coder aDecoder: NSCoder) {
		street = aDecoder.decodeObject(forKey: ArchiveKey.street.rawValue) as! String
		postalCode = aDecoder.decodeObject(forKey: ArchiveKey.postalColde.rawValue) as! String
		city = aDecoder.decodeObject(forKey: ArchiveKey.city.rawValue) as! String
		title = aDecoder.decodeObject(forKey: ArchiveKey.title.rawValue) as? String
		
		let latitude = aDecoder.decodeDouble(forKey: ArchiveKey.latitude.rawValue)
		let longitude = aDecoder.decodeDouble(forKey: ArchiveKey.longitude.rawValue)
		coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
	}
	
	init (address: (street: String, postalCode: String, city: String), title: String? = nil, geocodeCompletionHandler: @escaping CLGeocodeCompletionHandler) {
		(street, postalCode, city) = address
		self.title = title
		geocoder.geocodeAddressString("\(street), \(postalCode) \(city)", completionHandler: geocodeCompletionHandler)
	}
	
	override var debugDescription: String {
		return "\(street)\n\(postalCode) \(city)"
	}
}

class BasicInfo: NSObject, NSCoding {
	enum Index: UInt8 {
		case fileStructureVersion = 0, cardNumber, chipNumber, validityStart, validityEnd, releasePlace, nationalIdNumber, lastName, firstName, otherName, nationality, birthPlace, birthDate, sex, nobleCondition, documentType, specialStatus, pictureHash, duplicate, specialOrganisation, memberOfFamily, protection
	}
	
	enum Sex: UInt8, CustomStringConvertible {
		case female, male
		
		var description: String {
			switch self {
			case .female:
				return NSLocalizedString("female", comment: "Sex")
			case .male:
				return NSLocalizedString("male", comment: "Sex")
			}
		}
	}
	
	enum ArchiveKey: String {
		case cardNumber, releasePlace, firstName, lastName, otherName, nationality, birthPlace, validityStart, validityEnd, birthday, birthNumber
	}
	
	static let validityDateFormatter = DateFormatter(format: "dd.MM.yyyy")
	static let nationalIDNumberFormatter = DateFormatter(format: "YYMMdd")
	static let nationalIDNumberDottedFormatter = DateFormatter(format: "YY.MM.dd")
	
	let cardNumber, releasePlace, firstName, lastName, otherName, nationality, birthPlace: String
	let validityStart, validityEnd, birthday: Date
	let birthNumber: UInt16
	
	init(from file: Data) {
		let ranges = loadDictionary(from: file.dropLast(2))
		func field(_ index: Index) -> Data.SubSequence {
			return file[ranges[index.rawValue]!]
		}
		func string(with index: Index) -> String {
			return String(bytes: field(index), encoding: .utf8)!
		}
		func range(of index: Index) -> CountableRange<Int> {
			return ranges[index.rawValue]!
		}
		
		cardNumber = string(with: .cardNumber)
		validityStart = BasicInfo.validityDateFormatter.date(from: string(with: .validityStart))!
		validityEnd = BasicInfo.validityDateFormatter.date(from: string(with: .validityEnd))!
		birthPlace = string(with: .birthPlace)
		birthday = BasicInfo.nationalIDNumberFormatter.date(from: String(bytes: file[range(of: .nationalIdNumber).dropLast(5)], encoding: .utf8)!)!
		let birthNumberDigits = file[range(of: .nationalIdNumber).suffix(5).dropLast(2)].map {UInt16($0 & 0b1111)}
		birthNumber = 100 * birthNumberDigits[0] + 10*birthNumberDigits[1] + birthNumberDigits[2]
		lastName = string(with: .lastName)
		firstName = string(with: .firstName)
		otherName = string(with: .otherName)
		nationality = string(with: .nationality)
		releasePlace = string(with: .releasePlace)
	}
	
	required init?(coder aDecoder: NSCoder) {
		func string(with key: ArchiveKey) -> String {
			return aDecoder.decodeObject(forKey: key.rawValue) as! String
		}
		
		cardNumber = string(with: .cardNumber)
		releasePlace = string(with: .releasePlace)
		firstName = string(with: .firstName)
		lastName = string(with: .lastName)
		otherName = string(with: .otherName)
		nationality = string(with: .nationality)
		birthPlace = string(with: .birthPlace)
		
		validityStart = aDecoder.decodeObject(forKey: ArchiveKey.validityStart.rawValue) as! Date
		validityEnd = aDecoder.decodeObject(forKey: ArchiveKey.validityEnd.rawValue) as! Date
		birthday = aDecoder.decodeObject(forKey: ArchiveKey.birthday.rawValue) as! Date
		
		birthNumber = aDecoder.decodeObject(forKey: ArchiveKey.birthNumber.rawValue) as! UInt16
	}
	
	func encode(with aCoder: NSCoder) {
		func encode(_ object: Any?, for key: ArchiveKey) {
			aCoder.encode(object, forKey: key.rawValue)
		}
		
		encode(cardNumber, for: .cardNumber)
		encode(releasePlace, for: .releasePlace)
		encode(firstName, for: .firstName)
		encode(lastName, for: .lastName)
		encode(otherName, for: .otherName)
		encode(nationality, for: .nationality)
		encode(birthPlace, for: .birthPlace)
		encode(validityStart, for: .validityStart)
		encode(validityEnd, for: .validityEnd)
		encode(birthday, for: .birthday)
		encode(birthNumber, for: .birthNumber)
	}
	
	var sex: Sex {
		return Sex(rawValue: UInt8(UInt16(birthNumber) % UInt16(2)))!
	}
	
	override var debugDescription: String {
		return "ID card of \(firstName) \(otherName) \(lastName)"
	}
	
	var nationalIDNumber : String {
		let checksum = 97 - (1000 * Int(BasicInfo.nationalIDNumberFormatter.string(from: birthday))! + Int(birthNumber)) % 97
		let paddedBirthNumber = String(format: "%03d", birthNumber)
		let paddedChecksum    = String(format: "%02d", checksum)
		return BasicInfo.nationalIDNumberDottedFormatter.string(from: birthday) + "-\(paddedBirthNumber).\(paddedChecksum)"
	}
}

extension TKSmartCard {
	enum CardError: Error {
		case NoPreciseDiagnostic, EepromCorrupted, WrongParameterP1P2, CommandNotAvailableWithinCurrentLifeCycle
		
		var localizedDescription: String {
			return "\(self)"
		}
	}
	
	enum SelectFileError: Error {
		case SelectedFileNotActivated, FileNotFound, LcInconsistentWithP1P2, AttemptToSelectForbiddenLogicalChannel, ClaNotSupported
	}
	
	enum ReadBinaryError: Error {
		case SecurityStatusNotSatisfied, IncorrectLength(expected: UInt8)
	}
	
	enum ReadResponse {
		case data(Data)
		case error(Error)
	}
	
	struct UnknownError: Error {}
	
	/// Select a file on the card by path as described in ISO 7816-4
	///
	/// - Parameter dedicatedFile: Absolute path to dedicated file without the MF Identifier
	func select(dedicatedFile file: [UInt8], handler reply: @escaping (Error?)->Void) {
		self.transmit(Data(bytes: selectFile + [UInt8(file.count)] + file)) { (selectFileReply, error) in
			if let error = error {
				reply(error)
			} else if let selectFileReply = selectFileReply {
				switch (selectFileReply[0], selectFileReply[1]) {
				case (0x62, 0x83):
					reply(SelectFileError.SelectedFileNotActivated)
				case (0x64, 0):
					reply(CardError.NoPreciseDiagnostic)
				case (0x65, 0x81):
					reply(CardError.EepromCorrupted)
				case (0x6A, 0x82):
					reply(SelectFileError.FileNotFound)
				case (0x6A, 0x86):
					reply(CardError.WrongParameterP1P2)
				case (0x6A, 0x87):
					reply(SelectFileError.LcInconsistentWithP1P2)
				case (0x69, 0x99), (0x69, 0x85):
					reply(SelectFileError.AttemptToSelectForbiddenLogicalChannel)
				case (0x6D, 0):
					reply(CardError.CommandNotAvailableWithinCurrentLifeCycle)
				case (0x6E, 0):
					reply(SelectFileError.ClaNotSupported)
				case (0x90, 0):
					reply(nil)
				default:
					reply(UnknownError())
				}
			} else {
				fatalError("transmit must either have a response or an error")
			}
		}
	}
	
	
	/// Read bytes from current file
	/// as described in section "7.2.3 READ BINARY command" of ISO 7816-4
	///
	/// - Parameters:
	///   - length: number of bytes to read (Le)
	///   - offset: number of bytes to skip (15-bit unsigned integer, ranging from 0 to 32 767)
	///   - handler: function to execute after completion
	func readBytes(length: UInt8, offset: UInt16 = 0, handler: @escaping (ReadResponse) -> Void) {
		self.transmit(Data(bytes: readBinary + [UInt8(offset >> 8), UInt8(offset & 0xff), length])) { (binaryReply, error) in
			if let error = error {
				print(error)
			} else if let binaryReply = binaryReply {
				let statusBytes = (binaryReply[binaryReply.endIndex-2], binaryReply.last!)
				switch statusBytes {
				case (0x64, 0):
					handler(.error(CardError.NoPreciseDiagnostic) )
				case (0x65, 0x81):
					handler(.error(CardError.EepromCorrupted) )
				case (0x6B, 0):
					handler(.error(CardError.WrongParameterP1P2) )
				case (0x6D, 0):
					handler(.error(CardError.CommandNotAvailableWithinCurrentLifeCycle) )
				case (0x69, 0x82):
					handler(.error(ReadBinaryError.SecurityStatusNotSatisfied) )
				case (0x6C, _):
					handler(.error(ReadBinaryError.IncorrectLength(expected: binaryReply.last!)) )
				case (0x90, 0):
					handler(.data(
						Data(binaryReply.dropLast(2))
						))
				default:
					handler(
						.error( UnknownError() )
					)
				}
			}
		}
	}
	
	func readBytesUntilError(data: Data = Data(bytes:[]), updateProgress: ((UInt8)->Void)? = nil, handler reply: @escaping (ReadResponse)->Void) {
		let offset = UInt16(data.count)
		updateProgress?(UInt8(offset/256))
		readBytes(length: 0, offset: offset) {
			switch $0 {
			case .error(let error):
				switch error {
				case ReadBinaryError.IncorrectLength(let expectedLength):
					self.readBytes(length: expectedLength, offset: offset) { response in
						updateProgress?(UInt8(offset/256))
						switch response {
						case .error(let error):
							reply(.error(error))
						case .data(let newData):
							var concat = Data()
							concat.reserveCapacity(data.count+newData.count)
							concat.append(data)
							concat.append(newData)
							reply(.data(concat))
						}
					}
				case CardError.WrongParameterP1P2:
					if data.count > 0 {
						reply(.data(data))
					} else {
						reply(.error(error))
					}
				default:
					reply(.error(error))
				}
			case .data(let newData):
				var concat = Data()
				concat.reserveCapacity(data.count+newData.count)
				concat.append(data)
				concat.append(newData)
				if newData.count < 256 {
					reply(.data(concat))
				} else {
					self.readBytesUntilError(data: concat, updateProgress: updateProgress, handler: reply)
				}
			}
		}
	}
	
	/// Select dedicated file and read all its bytes. This is a helper function that combines the SELECT (section 7.1.1) & READ BINARY (section 7.2.3) commands from ISO 7816-4.
	///
	/// - Parameters:
	///   - file: Absolute path to dedicated file without the MF Identifier
	///   - updateProgress: function that gets called while reading the large files and informs the progress of the read command
	///   - reply: function that gets called when the file is read
	func read(file: [UInt8], updateProgress: ((UInt8)->Void)? = nil, reply: @escaping (ReadResponse)->Void) {
		select(dedicatedFile: file) {
			if let error = $0 {
				reply(.error(error) )
			} else {
				self.readBytesUntilError(updateProgress: updateProgress, handler: reply)
			}
		}
	}
	
	func getAddress(geocodeCompletionHandler: @escaping CLGeocodeCompletionHandler = {(_,_) in}, reply: @escaping (_ address: Address?, _ error: Error?) -> Void) {
		read(file: addressFile) { response in
			switch response {
			case .data(let data):
				let street = 2 ..< Int(data[1]) + 2
				let postalCode = street.upperBound + 2  ..<  street.upperBound + Int(data[street.upperBound+1]) + 2
				let city = postalCode.upperBound + 2  ..<  postalCode.upperBound + Int(data[postalCode.upperBound+1]) + 2
				
				reply(Address( address: (
					String(bytes: data[street], encoding: .utf8)!,
					String(bytes: data[postalCode], encoding: .utf8)!,
					String(bytes: data[city], encoding: .utf8)!
					), title: NSLocalizedString("Domicile", comment: "Domicile"), geocodeCompletionHandler: geocodeCompletionHandler), nil)
			case .error(let error):
				reply(nil, error)
			}
		}
	}
	
	
	func getBasicInfo(reply: @escaping (BasicInfo?, Error?)->Void) {
		read(file: basicInfoFile) { response in
			switch response {
			case .error(let error):
				reply(nil, error)
			case .data(let data):
				reply(BasicInfo(from: data), nil)
			}
		}
	}
	
	func getProfileImage(updateProgress: ((UInt8)->Void)? = nil, reply: @escaping (ReadResponse)->Void) {
		read(file: photoFile, updateProgress: updateProgress, reply: reply)
	}
}

func loadDictionary(from data: Data) -> [UInt8: CountableRange<Int>] {
	var dictionary = [UInt8: CountableRange<Int>]()
	var cursor = 2
	while cursor<data.endIndex && data[cursor-2] != 0 {
		let length = Int( data[cursor-1] )
		dictionary[data[cursor-2]] = cursor ..< cursor+length
		cursor += length + 2
	}
	return dictionary
}

extension DateFormatter {
	convenience init(format: String) {
		self.init()
		self.dateFormat = format
	}
	
	convenience init(style: DateFormatter.Style) {
		self.init()
		self.dateStyle = style
	}
}

