//
//  LocationManagerInfo.swift
//  LocationSimulator
//
//  Created by Victor Zyabko on 2024-06-11.
//

import Foundation
import CoreLocation

extension LocationSimulator {

	/// Contain information about CLLocationManager instance.
	class LocationManagerInfo: NSObject {
		weak var locationManager: CLLocationManager?
		weak var originalDelegate: CLLocationManagerDelegate?
		let dummyDelegate = DummyDelegate()
		var isUpdatingLocation = false
	}

}
