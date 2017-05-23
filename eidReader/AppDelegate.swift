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

let storyboard = NSStoryboard(name: "Main", bundle: nil)
let appDelegate = NSApplication.shared().delegate as! AppDelegate

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
	let slotManager = TKSmartCardSlotManager.default
	var currentSlot: TKSmartCardSlot?
	var currentAddress: Address?
	var basicInfo: BasicInfo?
	var profileImage: NSImage?
	
	var readerWindow: NSWindow?
	var viewController: ViewController?
	
	func applicationDidFinishLaunching(_ aNotification: Notification) {
		let windowController = createCardWindow()
		windowController.showWindow(self)
		readerWindow = windowController.window
		viewController = (readerWindow?.contentViewController as! ViewController)
		
		addObserver(self, forKeyPath: #keyPath(slotManager.slotNames), options: [.new, .initial], context: nil)
	}
	
	@IBAction open func saveDocument(_ sender: Any?) {
		createDocumentFromCurrentCard().runModalSavePanel(for: .saveOperation, delegate: self, didSave: #selector(discardDocumentUnless), contextInfo: nil)
	}
	
	func discardDocumentUnless(document: Document, didSave: Bool, with context: Any?) {
		if !didSave {
			document.close()
		}
	}
	
	@IBAction open func duplicateDocument(_ sender: Any?) {
		createDocumentFromCurrentCard()
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
		NSDocumentController.shared().addDocument(document)
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
	
	func updateImageProgress(progress: Double) {
		DispatchQueue.main.async { self.viewController?.imageProgressIndicator.doubleValue = progress }
	}
	
	func clearCard() {
		DispatchQueue.main.async {
			self.viewController?.address = nil
			self.viewController?.basicInfo = nil
		}
	}
	
	override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
		if keyPath == #keyPath(slotManager.slotNames) {
			if let firstSlot = (change?[.newKey] as! [String]).first {
				observe(slot: firstSlot)
			} else {
				clearCard()
				DispatchQueue.main.async {
					self.readerWindow?.title = "No card reader detected"
				}
			}
		} else if keyPath == #keyPath(currentSlot.state) {
			if let state = currentSlot?.state {
				switch state {
				case .missing :
					removeObserver(self, forKeyPath: #keyPath(currentSlot.state), context: nil)
				case .empty:
					clearCard()
				case .validCard:
					readSlot()
				default: break
				}
			}
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
								alert.runModal()
							}
						} else {
							card.getBasicInfo { (basicInfo, error) in
								card.getProfileImage(updateProgress: self.updateImageProgress) { (imageData, error) in
									if let imageData = imageData, let image = NSImage(data: imageData) {
										DispatchQueue.main.async {
											self.profileImage = image
											self.viewController?.profileImage.image = image
										}
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
	
	func observe(slot: String) {
		DispatchQueue.main.async {
			self.readerWindow?.title = slot
			self.showMainWindow()
		}
		slotManager?.getSlot(withName: slot) {
			self.currentSlot = $0
			self.addObserver(self, forKeyPath: #keyPath(currentSlot.state), options: [.new, .initial], context: nil)
		}
	}

	func applicationWillTerminate(_ aNotification: Notification) {
		removeObserver(self, forKeyPath: #keyPath(slotManager.slotNames), context: nil)
	}

	func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
		return true
	}
}

extension Data {
	func hexEncodedString() -> String {
		return map { String(format: "%02hhx", $0) }.joined()
	}
}
