//
//  CLLocationManager+Simulation.swift
//  LocationSimulator
//
//  Created by Victor Zyabko on 2024-06-10.
//

import Foundation
import CoreLocation

/// Location simulation (for CLLocationManager)
public protocol CLLocationManagerSimulation {

	/**
	 Initialize the location simulation.
	 Should be called when the application is launched, eg: in UIApplicationDelegate.willFinishLaunchingWithOptions.
	 Use only if you plan to simulate a location. Should not be used in a release build.
	 */
	static func initializeSimulation()

	/// Enable / Disable location simulation. Works if initializeSimulation() had been called.
	static var isSimulationEnabled: Bool { get set }

	/// Set simulated location. Works if initializeSimulation() had been called. and if isSimulationEnabled = True.
	static func setSimulatedLocation(_ location: CLLocation?)

}



extension CLLocationManager: CLLocationManagerSimulation {

	/**
	 Initialize the location simulation.
	 Should be called when the application is launched, eg: in UIApplicationDelegate.willFinishLaunchingWithOptions.
	 Use only if you plan to simulate a location. Should not be used in a release build.
	 */
	public static func initializeSimulation() {
		LocationSimulator.shared.initialize()
	}

	/// Enable / Disable location simulation. Works if initializeSimulation() had been called.
	public static var isSimulationEnabled: Bool {
		get {
			return LocationSimulator.shared.isEnabled
		}
		set {
			LocationSimulator.shared.isEnabled = newValue
		}
	}

	/// Set simulated location. Works if initializeSimulation() had been called. and if isSimulationEnabled = True.
	public static func setSimulatedLocation(_ location: CLLocation?) {
		LocationSimulator.shared.setSimulatedLocation(location)
	}

}
