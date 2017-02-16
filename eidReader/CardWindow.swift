//
//  ViewController.swift
//  cardreader
//
//  Created by Damiaan on 28-12-16.
//  Copyright © 2016 Damiaan. All rights reserved.
//

import Cocoa
import MapKit

func createCardWindow() -> NSWindowController {
	return storyboard.instantiateController(withIdentifier: "Card window controller") as! NSWindowController
}

class ViewController: NSViewController {
	@IBOutlet weak var profileImage: NSImageView!
	@IBOutlet weak var imageProgressIndicator: NSProgressIndicator!
	@IBOutlet weak var nameField: NSTextField!
	@IBOutlet weak var nationalityField: NSTextField!
	@IBOutlet weak var birthPlaceField: NSTextField!
	@IBOutlet weak var birthdayField: NSTextField!
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
		
		map.delegate = self
	}
	
	var address: Address? {
		willSet {
			if let address = address {
				map.removeAnnotation(address)
			}
		}
		didSet {
			if let address = address {
				map.addAnnotation(address)
				map.setCenter(address.coordinate, animated: true)
				map.selectAnnotation(address, animated: true)
			}
		}
	}
	
	var basicInfo: BasicInfo? {
		didSet {
			if let basicInfo = basicInfo {
				nameField.stringValue = "\(basicInfo.firstName) \(basicInfo.otherName) \(basicInfo.lastName)"
				nationalityField.stringValue = basicInfo.nationality
				birthPlaceField.stringValue = basicInfo.birthPlace
				birthdayField.objectValue = basicInfo.birthday
				nationalIDField.stringValue = basicInfo.nationalIDNumber
				
				cardNumberField.stringValue = basicInfo.cardNumber
				validStartField.objectValue = basicInfo.validityStart
				validEndField.objectValue = basicInfo.validityEnd
				releasePlaceField.stringValue = basicInfo.releasePlace
			} else {
				self.profileImage.image = nil
				self.imageProgressIndicator.doubleValue = 0
				self.imageProgressIndicator.isHidden = true
				self.nameField.stringValue = ""
				self.nationalityField.stringValue = ""
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

extension ViewController: MKMapViewDelegate {
	public func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
		var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "pin")
		if annotationView == nil {
			annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "pin")
		} else {
			annotationView!.annotation = annotation
		}
		annotationView!.canShowCallout = true
		if #available(OSX 10.12, *) {
			let label = NSTextField(labelWithString: annotation.subtitle!!)
			label.isSelectable = true
			label.font = NSFont.systemFont(ofSize: 12)
			label.textColor = NSColor.secondaryLabelColor
			annotationView!.detailCalloutAccessoryView = label
		}
		return annotationView
	}
}

class CardView: NSView {
	override var acceptsFirstResponder: Bool { return true }
	
	@IBAction override func print(_ sender: Any?) {
		Swift.print("printing view")
		NSPrintOperation(view: self).run()
	}
}
