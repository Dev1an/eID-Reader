//
//  Document.swift
//  eidReader
//
//  Created by Damiaan on 30-12-16.
//  Copyright © 2016 Damiaan. All rights reserved.
//

import Cocoa

class Document: NSDocument {

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
		Swift.print("made a doc")
		let windowController = storyboard.instantiateController(withIdentifier: "Document window controller") as! NSWindowController
		self.addWindowController(windowController)
		mainWindow = windowController.window
		updateViewController {
			$0.basicInfo = basicInfo
			$0.address = address
			$0.profileImage.image = profileImage
		}
	}
	
	func updateViewController(update: (ViewController)->Void) {
		if let viewController = mainWindow?.contentViewController as? ViewController {
			update(viewController)
		}
	}

    override func data(ofType typeName: String) throws -> Data {
        // Insert code here to write your document to data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning nil.
        // You can also choose to override -fileWrapperOfType:error:, -writeToURL:ofType:error:, or -writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.
		
		let data = NSMutableData()
		let archiver = NSKeyedArchiver(forWritingWith: data)
		archiver.encode(address, forKey: "address")
		archiver.encode(basicInfo, forKey: "basic information")
		archiver.encode(profileImage, forKey: "profile image")
		archiver.finishEncoding()
		return data as Data
    }
    
    override func read(from data: Data, ofType typeName: String) throws {
        // Insert code here to read your document from the given data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning false.
        // You can also choose to override -readFromFileWrapper:ofType:error: or -readFromURL:ofType:error: instead.
        // If you override either of these, you should also override -isEntireFileLoaded to return false if the contents are lazily loaded.
		let unarchiver = NSKeyedUnarchiver(forReadingWith: data)
        basicInfo = unarchiver.decodeObject(forKey: "basic information") as? BasicInfo
		address = unarchiver.decodeObject(forKey: "address") as? Address
		profileImage = unarchiver.decodeObject(forKey: "profile image") as? NSImage
    }

    override class func autosavesInPlace() -> Bool {
        return true
    }

}
