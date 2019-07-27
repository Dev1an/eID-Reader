//
//  ViewController.swift
//  cardreader
//
//  Created by Damiaan on 28-12-16.
//  Copyright © 2016 Damiaan. All rights reserved.
//

import Cocoa
import MapKit

let belgium = MKCoordinateRegion.init(center: CLLocationCoordinate2D.init(latitude: 50.473342, longitude: 4.464229), span: MKCoordinateSpan.init(latitudeDelta: 2.5, longitudeDelta: 4))

func createCardWindow() -> NSWindowController {
	return storyboard.instantiateController(withIdentifier: "Card window controller") as! NSWindowController
}

class CardWindow: NSWindow {
	@IBAction func printDocument2(_ sender: Any?) {
		let printInfo: NSPrintInfo
		if let document = windowController?.document as? Document {
			printInfo = document.printInfo
		} else {
			printInfo = NSPrintInfo()
			fitToTop(info: printInfo)
		}
		
		guard let view = contentView else {
			let alert = NSAlert(error: PrintError.noContentView)
			alert.informativeText = alert.messageText
			alert.messageText = "Unable to print this card."
			alert.runModal()
			return
		}
		
		NSPrintOperation(view: view, printInfo: printInfo).run()
	}
}

class ViewController: NSViewController {
	@IBOutlet weak var profileImage: NSImageView!
	@IBOutlet weak var imageProgressIndicator: NSProgressIndicator!
	@IBOutlet weak var nameField: NSTextField!
	@IBOutlet weak var nationalityField: NSTextField!
	@IBOutlet weak var sexField: NSTextField!
	@IBOutlet weak var birthPlaceField: NSTextField!
	@IBOutlet weak var birthdayField: NSTextField!
	@IBOutlet weak var addressField: NSTextField!
	@IBOutlet weak var nationalIDField: NSTextField!
	@IBOutlet weak var cardNumberField: NSTextField!
	@IBOutlet weak var validStartField: NSTextField!
	@IBOutlet weak var validEndField: NSTextField!
	@IBOutlet weak var releasePlaceField: NSTextField!
	@IBOutlet weak var map: MKMapView!
	
	var profileImageLayer: CALayer?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		profileImageLayer = profileImage.layer
		profileImage.layer?.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.1010948504).cgColor
		profileImageLayer?.cornerRadius = 3
	}
	
	var address: Address? {
		willSet {
			if let address = address {
				map.removeAnnotation(address)
			}
		}
		didSet {
			if let address = address {
				addressField.stringValue = "\(address.street), \(address.city) \(address.postalCode)"
				map.addAnnotation(address)
				let region = MKCoordinateRegion.init(center: address.coordinate, latitudinalMeters: 1500, longitudinalMeters: 1500)
				map.setRegion(region, animated: true)
				map.selectAnnotation(address, animated: true)
			} else {
				addressField.stringValue = ""
				map.setRegion(belgium, animated: true)
			}
		}
	}
	
	var basicInfo: BasicInfo? {
		didSet {
			if let basicInfo = basicInfo {
				nameField.stringValue = "\(basicInfo.firstName) \(basicInfo.otherName) \(basicInfo.lastName)"
				nationalityField.stringValue = basicInfo.nationality
				sexField.stringValue = basicInfo.sex.description
				birthPlaceField.stringValue = basicInfo.birthPlace
				birthdayField.objectValue = basicInfo.birthday
				nationalIDField.stringValue = basicInfo.nationalIDNumber
				
				cardNumberField.stringValue = basicInfo.cardNumber
				validStartField.objectValue = basicInfo.validityStart
				validEndField.objectValue = basicInfo.validityEnd
				if basicInfo.validityEnd < Date() {
					validStartField.textColor = NSColor.red
					validEndField.textColor = NSColor.red
				} else {
					validStartField.textColor = NSColor.textColor
					validEndField.textColor = NSColor.textColor
				}
				releasePlaceField.stringValue = basicInfo.releasePlace
			} else {
				self.profileImage.image = nil
				self.imageProgressIndicator.doubleValue = 0
				self.imageProgressIndicator.isHidden = true
				self.nameField.stringValue = ""
				self.nationalityField.stringValue = ""
				self.sexField.stringValue = ""
				self.birthPlaceField.stringValue = ""
				self.birthdayField.stringValue = ""
				self.nationalIDField.stringValue = ""
				self.cardNumberField.stringValue = ""
				self.validStartField.stringValue = ""
				self.validEndField.stringValue = ""
				self.releasePlaceField.stringValue = ""
			}
		}
	}	
}

class NoInsetsTextField: NSTextField {
	override var alignmentRectInsets: NSEdgeInsets {
		return NSEdgeInsets(top: 10, left: 0, bottom: 0, right: 0)
	}
}
