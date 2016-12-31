//
//  Document.swift
//  eidReader
//
//  Created by Damiaan on 30-12-16.
//  Copyright © 2016 Damiaan. All rights reserved.
//

import Cocoa

class Document: NSDocument {

	var address: Address?
	var basicInfo: BasicInfo?
	
	var mainWindow: NSWindow?
	
	override func makeWindowControllers() {
		Swift.print("made a doc")
		let windowController = storyboard.instantiateController(withIdentifier: "Document window controller") as! NSWindowController
		self.addWindowController(windowController)
		mainWindow = windowController.window
	}

    override func windowControllerDidLoadNib(_ aController: NSWindowController) {
        super.windowControllerDidLoadNib(aController)
        // Add any code here that needs to be executed once the windowController has loaded the document's window.
    }

    override func data(ofType typeName: String) throws -> Data {
        // Insert code here to write your document to data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning nil.
        // You can also choose to override -fileWrapperOfType:error:, -writeToURL:ofType:error:, or -writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.
		
//		return Data()
        throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
    }
    
    override func read(from data: Data, ofType typeName: String) throws {
        // Insert code here to read your document from the given data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning false.
        // You can also choose to override -readFromFileWrapper:ofType:error: or -readFromURL:ofType:error: instead.
        // If you override either of these, you should also override -isEntireFileLoaded to return false if the contents are lazily loaded.
		
        throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
    }

    override class func autosavesInPlace() -> Bool {
        return true
    }

}
