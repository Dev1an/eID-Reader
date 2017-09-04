//
//  Document.swift
//  eidReader
//
//  Created by Damiaan on 30-12-16.
//  Copyright © 2016 Damiaan. All rights reserved.
//

import Cocoa

class Document: NSDocument {
	
	var printInfoIsSetUp = false

	var address: Address? {
		didSet { updateViewController { $0.address = address } }
	}
	var basicInfo: BasicInfo? {
		didSet { updateViewController { $0.basicInfo = basicInfo } }
	}
	var profileImage: NSImage? {
		didSet { updateViewController { $0.profileImage.image = profileImage } }
	}
	
	var mainWindow: NSWindow?
	
	override func makeWindowControllers() {
		let windowController = createCardWindow()
		self.addWindowController(windowController)
		mainWindow = windowController.window
		updateViewController {
			$0.basicInfo = basicInfo
			$0.address = address
			$0.profileImage.image = profileImage
		}
	}
	
	func setupPrintInfo() {
		if printInfoIsSetUp == false {
			printInfo.horizontalPagination = .fitPagination
			printInfo.verticalPagination = .fitPagination
			printInfo.isVerticallyCentered = false
			
			printInfoIsSetUp = true
		}
	}
	
	func updateViewController(update: (ViewController)->Void) {
		if let viewController = mainWindow?.contentViewController as? ViewController {
			update(viewController)
		}
	}

    override func data(ofType typeName: String) throws -> Data {
		let data = NSMutableData()
		let archiver = NSKeyedArchiver(forWritingWith: data)
		archiver.encode(address, forKey: "address")
		archiver.encode(basicInfo, forKey: "basic information")
		archiver.encode(profileImage, forKey: "profile image")
		archiver.finishEncoding()
		return data as Data
    }
    
    override func read(from data: Data, ofType typeName: String) throws {
		let unarchiver = NSKeyedUnarchiver(forReadingWith: data)
        basicInfo = unarchiver.decodeObject(forKey: "basic information") as? BasicInfo
		address = unarchiver.decodeObject(forKey: "address") as? Address
		profileImage = unarchiver.decodeObject(forKey: "profile image") as? NSImage
    }

    override class func autosavesInPlace() -> Bool {
        return true
    }
	
	@IBAction func printDocument2(_ sender: Any?) {
		setupPrintInfo()
		
		guard let view = mainWindow?.contentView else {
			let alert = NSAlert(error: PrintError.noContentView)
			alert.informativeText = alert.messageText
			alert.messageText = "Unable to print this card."
			alert.runModal()
			return
		}
		
		Swift.print(printInfo.orientation)
		
		NSPrintOperation(view: view, printInfo: printInfo).run()
	}
}

enum PrintError: Error {
	case noContentView
}
