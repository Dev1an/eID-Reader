//
//  ViewController.swift
//  cardreader
//
//  Created by Damiaan on 28-12-16.
//  Copyright © 2016 Damiaan. All rights reserved.
//

import Cocoa
import CryptoTokenKit
import MapKit

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
	
	
	let slotManager = TKSmartCardSlotManager.default
	var currentSlot: TKSmartCardSlot?
	var currentAddress: TKSmartCard.Address?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		addObserver(self, forKeyPath: #keyPath(slotManager.slotNames), options: [.new, .initial], context: nil)
		// Do any additional setup after loading the view.
		profileImage.layer?.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.1010948504).cgColor
	}
	
	override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
		if keyPath == #keyPath(slotManager.slotNames) {
			if let firstSlot = (change?[.newKey] as! [String]).first {
				observe(slot: firstSlot)
			} else {
				clearCard()
				print("slot disappeared")
			}
		} else if keyPath == #keyPath(currentSlot.state) {
			if let state = currentSlot?.state {
				print("slot state:", state)
				switch state {
				case .missing :
					removeObserver(self, forKeyPath: #keyPath(currentSlot.state), context: nil)
				case .empty:
					clearCard()
				case .validCard:
					showSlot()
				default: break
				}
			}
		}
	}
	
	func clearSlot() {
		DispatchQueue.main.async { self.view.window?.title = "" }
		clearCard()
	}
	
	func clearCard() {
		DispatchQueue.main.async {
			self.profileImage.image = nil
			// TODO: bind map
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
			if let address = self.currentAddress {self.map.removeAnnotation(address)}
		}
	}
	
	func observe(slot: String) {
		print("observing slot")
		DispatchQueue.main.async { self.view.window?.title = slot }
		slotManager?.getSlot(withName: slot) {
			self.currentSlot = $0
			self.addObserver(self, forKeyPath: #keyPath(currentSlot.state), options: [.new, .initial], context: nil)
		}
	}
	
	func updateImageProgress(progress: Double) {
		DispatchQueue.main.async {
			self.imageProgressIndicator.doubleValue = progress
		}
	}
	
	func showSlot() {
		if let card = currentSlot?.makeSmartCard() {
			card.beginSession{ (success, error) in
				if success {
					card.getAddress(geocodeCompletionHandler: self.displayHome) { (address, error) in
						card.getBasicInfo { (basicInfo, error) in
							card.getProfileImage(updateProgress: self.updateImageProgress) { (imageData, error) in
								if let imageData = imageData, let image = NSImage(data: imageData) {
									DispatchQueue.main.async {
										self.profileImage.image = image
									}
								}
								card.endSession()
							}
							DispatchQueue.main.async { self.imageProgressIndicator.isHidden = false }
							if let basicInfo = basicInfo {
								DispatchQueue.main.async {
									self.nameField.stringValue = "\(basicInfo.firstName) \(basicInfo.otherName) \(basicInfo.lastName)"
									self.nationalityField.stringValue = basicInfo.nationality
									self.birthPlaceField.stringValue = basicInfo.birthPlace
									self.birthdayField.objectValue = basicInfo.birthday
									self.nationalIDField.stringValue = basicInfo.nationalIDNumber
									
									self.cardNumberField.stringValue = basicInfo.cardNumber
									self.validStartField.objectValue = basicInfo.validityStart
									self.validEndField.objectValue = basicInfo.validityEnd
									self.releasePlaceField.stringValue = basicInfo.releasePlace
								}
							}
						}
						if let address = address {
							self.currentAddress = address
						}
					}
				}
			}
		}
	}
	
	func displayHome(places: [CLPlacemark]?, error: Error?) {
		if let coordinate = places?.first?.location?.coordinate {
			currentAddress!.coordinate = coordinate
			map.addAnnotation(currentAddress!)
			map.setCenter(currentAddress!.coordinate, animated: true)
			map.selectAnnotation(currentAddress!, animated: true)
		}
	}

	override var representedObject: Any? {
		didSet {
		// Update the view, if already loaded.
		}
	}


}
