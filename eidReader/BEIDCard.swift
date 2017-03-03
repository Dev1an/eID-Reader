//
//  BEIDCard.swift
//  cardreader
//
//  Created by Damiaan on 28-12-16.
//  Copyright © 2016 Damiaan. All rights reserved.
//

import Foundation
import CryptoTokenKit
import AppKit
import MapKit

let idFile:        [UInt8] = [0x3F, 0x00, 0xDF, 0x01, 0x40, 0x38]
let photoFile:     [UInt8] = [0x3F, 0x00, 0xDF, 0x01, 0x40, 0x35]
let addressFile:   [UInt8] = [0x3F, 0x00, 0xDF, 0x01, 0x40, 0x33]
let basicInfoFile: [UInt8] = [0x3F, 0x00, 0xDF, 0x01, 0x40, 0x31]
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
	
	enum Sex: UInt8 {
		case female, male
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
	}
	
	enum SelectFileError: Error {
		case SelectedFileNotActivated, FileNotFound, LcInconsistentWithP1P2, AttemptToSelectForbiddenLogicalChannel, ClaNotSupported
	}
	
	enum ReadBinaryError: Error {
		case SecurityStatusNotSatisfied, IncorrectLength(expected: UInt8)
	}
	
	func read(file: [UInt8], length: UInt8, offset: UInt16 = 0, reply: @escaping (Data?, Error?)->Void) {
		self.transmit(Data(bytes: selectFile + [UInt8(file.count)] + file)) { (selectFileReply, error) in
			if let error = error {
				reply(nil, error)
			} else if let selectFileReply = selectFileReply {
				switch (selectFileReply[0], selectFileReply[1]) {
				case (0x62, 0x83):
					reply(nil, SelectFileError.SelectedFileNotActivated)
				case (0x64, 0):
					reply(nil, CardError.NoPreciseDiagnostic)
				case (0x65, 0x81):
					reply(nil, CardError.EepromCorrupted)
				case (0x6A, 0x82):
					reply(nil, SelectFileError.FileNotFound)
				case (0x6A, 0x86):
					reply(nil, CardError.WrongParameterP1P2)
				case (0x6A, 0x87):
					reply(nil, SelectFileError.LcInconsistentWithP1P2)
				case (0x69, 0x99), (0x69, 0x85):
					reply(nil, SelectFileError.AttemptToSelectForbiddenLogicalChannel)
				case (0x6D, 0):
					reply(nil, CardError.CommandNotAvailableWithinCurrentLifeCycle)
				case (0x6E, 0):
					reply(nil, SelectFileError.ClaNotSupported)
				case (0x90, 0):
					self.transmit(Data(bytes: readBinary + [UInt8(offset >> 8), UInt8(offset & 0xff), length])) { (binaryReply, error) in
						if let error = error {
							print(error)
						} else if let binaryReply = binaryReply {
							let statusBytes = (binaryReply[binaryReply.endIndex-2], binaryReply.last!)
							switch statusBytes {
							case (0x64, 0):
								reply(nil, CardError.NoPreciseDiagnostic)
							case (0x65, 0x81):
								reply(nil, CardError.EepromCorrupted)
							case (0x6B, 0):
								reply(nil, CardError.WrongParameterP1P2)
							case (0x6D, 0):
								reply(nil, CardError.CommandNotAvailableWithinCurrentLifeCycle)
							case (0x69, 0x82):
								reply(nil, ReadBinaryError.SecurityStatusNotSatisfied)
							case (0x6C, _):
								reply(nil, ReadBinaryError.IncorrectLength(expected: binaryReply.last!))
							case (0x90, 0):
								reply(Data(binaryReply.dropLast(2)), nil)
							default: break
							}
						}
					}
				default: break
				}
			} else {
				// TODO: cleanup
			}
		}
	}
	
	func readUntilError(file: [UInt8], data: Data = Data(bytes:[]), counter: UInt8 = 0, updateProgress: ((Double)->Void)? = nil, reply: @escaping (Data?, Error?)->Void) {
		let offset = UInt16(counter) << 8
		updateProgress?(Double(counter))
		read(file: file, length: 0, offset: offset) { (newData, error) in
			if let error = error {
				switch error {
				case ReadBinaryError.IncorrectLength(let expectedLength):
					self.read(file: file, length: expectedLength, offset: offset) { (newData, error) in
						updateProgress?(Double(counter+1))
						if let error = error {
							reply(data, error)
						} else if let newData = newData {
							var concat = Data()
							concat.reserveCapacity(data.count+newData.count)
							concat.append(data)
							concat.append(newData)
							reply(concat, nil)
						}
					}
				default:
					reply(data, error)
				}
			} else if let newData = newData {
				var concat = Data()
				concat.reserveCapacity(data.count+newData.count)
				concat.append(data)
				concat.append(newData)
				self.readUntilError(file: file, data: concat, counter: counter+1, updateProgress: updateProgress) { (data, error) in
					reply(data, error)
				}
			}
		}
	}
	
	func getAddress(geocodeCompletionHandler: @escaping CLGeocodeCompletionHandler = {(_,_) in}, reply: @escaping (_ address: Address?, _ error: Error?) -> Void) {
		readUntilError(file: addressFile) { (data, error) in
			if let error = error {
				reply(nil, error)
			} else if let data = data {
				let street = 2 ..< Int(data[1]) + 2
				let postalCode = street.upperBound + 2  ..<  street.upperBound + Int(data[street.upperBound+1]) + 2
				let city = postalCode.upperBound + 2  ..<  postalCode.upperBound + Int(data[postalCode.upperBound+1]) + 2
				
				reply(Address( address: (
					String(bytes: data[street], encoding: .utf8)!,
					String(bytes: data[postalCode], encoding: .utf8)!,
					String(bytes: data[city], encoding: .utf8)!
					), title: "Woonplaats", geocodeCompletionHandler: geocodeCompletionHandler), nil)
			}
		}
	}
	
	
	func getBasicInfo(reply: @escaping (BasicInfo?, Error?)->Void) {
		readUntilError(file: basicInfoFile) { (data, error) in
			if let data = data {
				reply(BasicInfo(from: data), nil)
			} else {
				reply(nil, error)
			}
		}
	}
	
	func getProfileImage(updateProgress: ((Double)->Void)? = nil, reply: @escaping (Data?, Error?)->Void) {
		readUntilError(file: photoFile, updateProgress: updateProgress, reply: reply)
	}
}

func loadDictionary(from data: MutableRandomAccessSlice<Data>) -> [UInt8: CountableRange<Int>] {
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
