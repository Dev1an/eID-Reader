//
//  AppDelegate.swift
//  cardreader
//
//  Created by Damiaan on 28-12-16.
//  Copyright © 2016 Damiaan. All rights reserved.
//

import Cocoa
import CryptoTokenKit
import MapKit

let storyboard = NSStoryboard(name: NSStoryboard.Name(rawValue: "Main"), bundle: nil)
let appDelegate = NSApplication.shared.delegate as! AppDelegate

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
	@objc let slotManager = TKSmartCardSlotManager.default
	@objc var currentSlot: TKSmartCardSlot?
	var currentAddress: Address?
	var basicInfo: BasicInfo?
	var profileImage: NSImage?
	
	var readerWindow: NSWindow?
	var viewController: ViewController?
	
	var managerObservation: NSKeyValueObservation?
	var slotObservation: NSKeyValueObservation?
	
	func applicationDidFinishLaunching(_ aNotification: Notification) {
		let windowController = createCardWindow()
		windowController.showWindow(self)
		readerWindow = windowController.window
		viewController = (readerWindow?.contentViewController as! ViewController)
		
		managerObservation = slotManager?.observe(\.slotNames, options: .initial, changeHandler: updateCardSlots)
	}

	@IBAction open func saveDocument(_ sender: Any?) {
		createDocumentFromCurrentCard().runModalSavePanel(for: .saveOperation, delegate: self, didSave: #selector(discardDocumentUnless), contextInfo: nil)
	}

	func application(_ sender: NSApplication, openFile filename: String) -> Bool {
		let url = URL(fileURLWithPath: filename)
		Swift.print("is file:", url.isFileURL, url)
		
		NSDocumentController.shared.openDocument(withContentsOf: url, display: true) {
			if let error = $2 {
				let alert = NSAlert(error: error)
				alert.informativeText = alert.messageText
				alert.messageText = "An error occured while reading the card."
				alert.runModal()
			}
		}
		
		return true
	}

	@objc func discardDocumentUnless(document: Document, didSave: Bool, with context: Any?) {
		if !didSave {
			document.close()
		}
	}

	@IBAction open func duplicateDocument(_ sender: Any?) {
		_ = createDocumentFromCurrentCard()
	}

	func applicationShouldOpenUntitledFile(_ sender: NSApplication) -> Bool {
		return false
	}

	override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
		if (menuItem.tag == 2) {
			return true
		} else {
			return currentSlot?.state == .validCard
		}
	}

	func createDocumentFromCurrentCard() -> Document {
		let document = Document()
		document.address = currentAddress
		document.basicInfo = basicInfo
		document.profileImage = profileImage
		NSDocumentController.shared.addDocument(document)
		document.makeWindowControllers()
		if let oldWindow = readerWindow, let newWindow = document.mainWindow {
			newWindow.setFrame(oldWindow.frame, display: true)
			newWindow.animationBehavior = .none
			document.showWindows()
			newWindow.setFrame(oldWindow.frame.offsetBy(dx: 50, dy: -30), display: true, animate: true)
		} else {
			document.showWindows()
		}
		return document
	}

	func updateHomeCoordinate(places: [CLPlacemark]?, error: Error?) {
		if let coordinate = places?.first?.location?.coordinate {
			currentAddress!.coordinate = coordinate
			viewController?.address = currentAddress
		}
	}
	
	@IBAction func showMainWindow(_ sender: Any?) {
		showMainWindow()
	}

	func showMainWindow() {
		if readerWindow?.isVisible == false {
			NSWindowController(window: readerWindow).showWindow(self)
		}
	}
	
	func updateImageProgress(progress: UInt8) {
		DispatchQueue.main.async { self.viewController?.imageProgressIndicator.doubleValue = Double(progress) }
	}
	
	func clearCard() {
		DispatchQueue.main.async {
			self.viewController?.address = nil
			self.viewController?.basicInfo = nil
		}
	}
	
	func readSlot() {
		DispatchQueue.main.async(execute: showMainWindow)
		if let card = currentSlot?.makeSmartCard() {
			card.beginSession{ (success, error) in
				if success {
					card.getAddress(geocodeCompletionHandler: self.updateHomeCoordinate) { (address, error) in
						if let error = error {
							DispatchQueue.main.async {
								let alert = NSAlert(error: error)
								alert.informativeText = alert.messageText
								alert.messageText = "An error occured while reading the card."
								alert.runModal()
							}
						} else {
							card.getBasicInfo { (basicInfo, error) in
								card.getProfileImage(updateProgress: self.updateImageProgress) { response in
									switch response {
									case .data(let imageData):
										if let image = NSImage(data: imageData) {
											DispatchQueue.main.async {
												self.profileImage = image
												self.viewController?.profileImage.image = image
											}
										}
									case .error(_):
										break // TODO: add error handling
									}
									card.endSession()
								}
								DispatchQueue.main.async { self.viewController?.imageProgressIndicator.isHidden = false }
								if let basicInfo = basicInfo {
									DispatchQueue.main.async {
										self.basicInfo = basicInfo
										self.viewController?.basicInfo = basicInfo
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
	}
	
	func updateCardSlots(manager: TKSmartCardSlotManager, change: NSKeyValueObservedChange<[String]>) {
		if let firstSlot = manager.slotNames.first {
			observe(slot: firstSlot)
		} else {
			clearCard()
			DispatchQueue.main.async {
				self.readerWindow?.title = "No card reader detected"
			}
		}
	}
	
	func observe(slot: String) {
		DispatchQueue.main.async {
			self.readerWindow?.title = slot
			self.showMainWindow()
		}
		slotManager?.getSlot(withName: slot) {
			self.currentSlot = $0
			self.slotObservation = self.currentSlot?.observe(\.state, options: .initial) {_,_ in
				if let state = self.currentSlot?.state {
					switch state {
					case .missing :
						self.slotObservation = nil
					case .empty:
						self.clearCard()
					case .validCard:
						self.readSlot()
					default: break
					}
				}
			}
		}
	}

	func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
		return true
	}
}
