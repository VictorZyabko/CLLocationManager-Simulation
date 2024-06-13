//
//  LocationSimulator.swift
//  LocationSimulator
//
//  Created by Victor Zyabko on 2024-06-10.
//

import Foundation
import CoreLocation

/// Simulates device location
class LocationSimulator: NSObject {

	// MARK: - Public

	/// Shared instance
	static var shared: LocationSimulator = {
		return LocationSimulator()
	}()

	/// Should be called in UIApplicationDelegate.willFinishLaunchingWithOptions.
	func initialize() {
		if _isInitialized {
			return
		}
		_isInitialized = true

		_swizzlingStartUpdatingLocation = SwizzlingMethodInfo(forClass: CLLocationManager.self,
															  originalSelector: #selector(CLLocationManager.startUpdatingLocation),
															  swizzledSelector: #selector(CLLocationManager.swizzledStartUpdatingLocation))

		_swizzlingStopUpdatingLocation = SwizzlingMethodInfo(forClass: CLLocationManager.self,
															 originalSelector: #selector(CLLocationManager.stopUpdatingLocation),
															 swizzledSelector: #selector(CLLocationManager.swizzledStopUpdatingLocation))

		_swizzlingDelegateGetter = SwizzlingMethodInfo(forClass: CLLocationManager.self,
													   originalSelector: #selector(getter: CLLocationManager.delegate),
													   swizzledSelector: #selector(getter: CLLocationManager.swizzledDelegate))

		_swizzlingDelegateSetter = SwizzlingMethodInfo(forClass: CLLocationManager.self,
													   originalSelector: #selector(setter: CLLocationManager.delegate),
													   swizzledSelector: #selector(setter: CLLocationManager.swizzledDelegate))

		_swizzlingLocationGetter = SwizzlingMethodInfo(forClass: CLLocationManager.self,
													   originalSelector: #selector(getter: CLLocationManager.location),
													   swizzledSelector: #selector(getter: CLLocationManager.swizzledLocation))

		// Should be always swizzled
		_swizzlingStartUpdatingLocation?.swizzle()
		_swizzlingStopUpdatingLocation?.swizzle()
	}

	/// Enable / Disable simulating
	var isEnabled: Bool {
		get {
			return _isEnabled
		}
		set {
			if !_isInitialized {
				return
			}
			_isEnabled = newValue
			// Remove info about deleted managers
			_arrLocationManagerInfo.removeAll(where: {$0.locationManager == nil})
			if _isEnabled {
				// Set dummy delegates
				for info in _arrLocationManagerInfo {
					info.originalDelegate = info.locationManager?.delegate
					info.locationManager?.delegate = info.dummyDelegate
				}
				// Then swizzle
				_swizzlingDelegateGetter?.swizzle()
				_swizzlingDelegateSetter?.swizzle()
			} else {
				_simulatedLocation = nil
				// First unswizzle
				_swizzlingDelegateGetter?.unswizzle()
				_swizzlingDelegateSetter?.unswizzle()
				// Then set original delegates
				for info in _arrLocationManagerInfo {
					info.locationManager?.delegate = info.originalDelegate
					info.originalDelegate = nil
				}
			}
			self.callDidUpdateLocations()
		}
	}

	/// Set simulated location
	func setSimulatedLocation(_ location: CLLocation?) {
		if !_isEnabled {
			return
		}
		if _simulatedLocation !== location {
			_simulatedLocation = location
			self.callDidUpdateLocations()
		}
	}

	// MARK: - Private. Public

	/// Private for Signleton
	private override init() {
		super.init()
	}

	// MARK: - Private. Data

	private var _isInitialized = false
	private var _isEnabled = false
	private var _simulatedLocation: CLLocation? = nil

	private var _swizzlingStartUpdatingLocation: SwizzlingMethodInfo? = nil
	private var _swizzlingStopUpdatingLocation: SwizzlingMethodInfo? = nil
	private var _swizzlingDelegateGetter: SwizzlingMethodInfo? = nil
	private var _swizzlingDelegateSetter: SwizzlingMethodInfo? = nil
	private var _swizzlingLocationGetter: SwizzlingMethodInfo? = nil

	private var _arrLocationManagerInfo = [LocationManagerInfo]()

	// MARK: - Private

	private func getLocationManagerInfo(locationManager: CLLocationManager) -> LocationManagerInfo {
		var info = _arrLocationManagerInfo.first(where: {$0.locationManager === locationManager})
		if info == nil {
			info = LocationManagerInfo()
			info?.locationManager = locationManager
			_arrLocationManagerInfo.append(info!)
		}
		return info!
	}

	private func callDidUpdateLocations() {
		if _isEnabled {
			let location = _simulatedLocation
			if let location {
				for info in _arrLocationManagerInfo {
					if let locationManager = info.locationManager {
						if let delegate = info.originalDelegate {
							delegate.locationManager?(locationManager, didUpdateLocations: [location])
						}
					}
				}
			}
		} else {
			//-
		}
	}

	// MARK: - Private. Swizzled methods

	fileprivate func startUpdatingLocation(locationManager: CLLocationManager) {
		let info = self.getLocationManagerInfo(locationManager: locationManager)
		info.isUpdatingLocation = true
		// if !_isEnabled {
		_swizzlingStartUpdatingLocation?.usingOriginalMethod {
			locationManager.startUpdatingLocation()
		}
		//}
	}

	fileprivate func stopUpdatingLocation(locationManager: CLLocationManager) {
		let info = self.getLocationManagerInfo(locationManager: locationManager)
		info.isUpdatingLocation = false
		//if !_isEnabled {
		_swizzlingStopUpdatingLocation?.usingOriginalMethod {
			locationManager.stopUpdatingLocation()
		}
		//}
	}

	fileprivate func delegateGetter(locationManager: CLLocationManager) -> CLLocationManagerDelegate? {
		let info = self.getLocationManagerInfo(locationManager: locationManager)
		if _isEnabled {
			return info.dummyDelegate
		} else {
			return info.originalDelegate
		}
	}

	fileprivate func delegateSetter(locationManager: CLLocationManager, delegate: CLLocationManagerDelegate?) {
		let info = self.getLocationManagerInfo(locationManager: locationManager)
		info.originalDelegate = delegate
	}

	fileprivate func locationGetter(locationManager: CLLocationManager) -> CLLocation? {
		var result: CLLocation? = nil
		if _isEnabled {
			result = _simulatedLocation
		} else {
			_swizzlingLocationGetter?.usingOriginalMethod {
				result = locationManager.location
			}
		}
		return result
	}

	// MARK: -

}

fileprivate extension CLLocationManager {

	@objc
	func swizzledStartUpdatingLocation() {
		print("swizzled startUpdatingLocation")
		LocationSimulator.shared.startUpdatingLocation(locationManager: self)
	}

	@objc
	func swizzledStopUpdatingLocation() {
		print("swizzled stopUpdatingLocation")
		LocationSimulator.shared.stopUpdatingLocation(locationManager: self)
	}

	@objc
	var swizzledDelegate: CLLocationManagerDelegate? {
		get {
			print("swizzled delegate getter")
			return LocationSimulator.shared.delegateGetter(locationManager: self)
		}
		set {
			print("swizzled delegate setter")
			LocationSimulator.shared.delegateSetter(locationManager: self, delegate: newValue)
		}
	}

	@objc
	var swizzledLocation: CLLocation? {
		get {
			print("swizzled location getter")
			return LocationSimulator.shared.locationGetter(locationManager: self)
		}
	}

}
