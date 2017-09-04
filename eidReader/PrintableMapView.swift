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
				let pitch = 1.5
				let span = MKCoordinateSpan(latitudeDelta: region.span.latitudeDelta/pitch, longitudeDelta: region.span.longitudeDelta/pitch)
				options.region = MKCoordinateRegion(center: region.center, span: span)
				options.size.width  = dirtyRect.width  * 2 * CGFloat(pitch)
				options.size.height = dirtyRect.height * 2 * CGFloat(pitch)
				options.showsBuildings = true
				
				let mapSnapshotter = MKMapSnapshotter(options: options)
				
				let semaphore = DispatchSemaphore(value: 0)
				mapSnapshotter.start(with: DispatchQueue.global(qos: .userInteractive)) { (snapshot, error) -> Void in
					// do error handling
					if let snapshot = snapshot {
						NSGraphicsContext.setCurrent(context)
						let t = NSAffineTransform()
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
