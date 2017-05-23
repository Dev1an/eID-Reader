//
//  PrintableMapView.swift
//  eidReader
//
//  Created by Damiaan on 23/05/17.
//  Copyright © 2017 Damiaan. All rights reserved.
//

import MapKit
import Dispatch

class PrintableMapView: MKMapView {
	override func draw(_ dirtyRect: NSRect) {
		if NSGraphicsContext.currentContextDrawingToScreen() {
			super.draw(dirtyRect)
		} else {
			if let context = NSGraphicsContext.current() {
				let options = MKMapSnapshotOptions()
				options.region = region;
				options.size.width  = dirtyRect.width  * 1.5
				options.size.height = dirtyRect.height * 1.5
				
				let mapSnapshotter = MKMapSnapshotter(options: options)
				
				let semaphore = DispatchSemaphore(value: 0)
				mapSnapshotter.start(with: DispatchQueue.global(qos: .userInteractive)) { (snapshot, error) -> Void in
					// do error handling
					if let snapshot = snapshot {
						NSGraphicsContext.setCurrent(context)
						var t = NSAffineTransform()
						t.translateX(by: 0, yBy: dirtyRect.size.height)
						t.scaleX(by: 1, yBy: -1)
						t.concat()
						snapshot.image.draw(in: dirtyRect)
						
						Swift.print("map drawn")
						semaphore.signal()
					}
				}
				semaphore.wait()
				Swift.print("end of draw func")
			}
		}
	}
}
