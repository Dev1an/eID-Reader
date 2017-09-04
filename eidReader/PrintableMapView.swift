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
				let pitch: CGFloat = 3.0
				options.region = region
				options.size.width  = dirtyRect.width  * pitch
				options.size.height = dirtyRect.height * pitch
				
				let mapSnapshotter = MKMapSnapshotter(options: options)
				
				let semaphore = DispatchSemaphore(value: 0)
				mapSnapshotter.start(with: DispatchQueue.global(qos: .userInitiated)) { (snapshot, error) -> Void in
					// do error handling
					if let snapshot = snapshot {
						NSGraphicsContext.setCurrent(context)
						let t = NSAffineTransform()
						t.translateX(by: 0, yBy: dirtyRect.size.height)
						t.scaleX(by: 1, yBy: -1)
						t.concat()
						snapshot.image.draw(in: dirtyRect)

						let pinView = MKPinAnnotationView(annotation: nil, reuseIdentifier: nil)
						let pinImage = pinView.image
						let pinCenter = pinView.centerOffset
						
						let t2 = NSAffineTransform()
						t2.scale(by: 1.0/pitch)
						t2.concat()
						
						for annotation in self.annotations {
							var point = snapshot.point(for: annotation.coordinate)
							point.x -= pinView.bounds.size.width  / 2 / pitch
							point.y -= pinView.bounds.size.height / 2 / pitch
							point.x += pinCenter.x / pitch
							point.y += pinCenter.y / pitch
							pinImage?.draw(at: point, from: dirtyRect, operation: .sourceOver, fraction: 1)
						}
						
						semaphore.signal()
					}
				}
				semaphore.wait()
				
			}
		}
	}
}
