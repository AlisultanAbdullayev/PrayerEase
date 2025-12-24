//
//  WatchQiblaViewModel.swift
//  PrayerEaseWatch Watch App
//
//  Created by Antigravity on 12/23/25.
//

import CoreLocation
import Foundation
import SwiftUI
import Combine

/// View model for Qibla direction screen on watchOS
@MainActor
final class WatchQiblaViewModel: NSObject, ObservableObject {

    // MARK: - Published Properties

    @Published var heading: Double = 0
    @Published var qiblaDirection: Double = 0
    @Published var userLocation: CLLocation?
    @Published var headingAccuracy: Double = -1
    @Published var isLocationActive: Bool = false

    // MARK: - Private Properties

    private let locationManager = CLLocationManager()

    // MARK: - Initialization

    override init() {
        super.init()
        setupLocationManager()
    }

    // MARK: - Setup

    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }

    // MARK: - Actions

    func startUpdating() {
        requestLocationPermission()
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
    }

    func stopUpdating() {
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
    }

    private func requestLocationPermission() {
        let status = locationManager.authorizationStatus

        if status == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
    }

    // MARK: - Computed Properties

    /// Accuracy percentage (0-100)
    var accuracyPercentage: Int {
        let accuracy = headingAccuracy
        if accuracy < 0 { return 0 }
        // accuracy is in degrees of error. 0 degrees = 100%. 50 degrees = 50%.
        return Int(max(0, 100 - accuracy))
    }

    /// Whether user is pointing toward Qibla (within 5 degrees)
    var isPointingToQibla: Bool {
        abs(heading - qiblaDirection) <= 5
    }
}

// MARK: - CLLocationManagerDelegate

extension WatchQiblaViewModel: CLLocationManagerDelegate {

    nonisolated func locationManager(
        _ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]
    ) {
        guard let location = locations.last else { return }

        Task { @MainActor in
            self.userLocation = location
            self.isLocationActive = true

            // Calculate Qibla direction
            self.qiblaDirection = QiblaService.calculateQiblaDirection(from: location)
        }
    }

    nonisolated func locationManager(
        _ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading
    ) {
        Task { @MainActor in
            self.heading =
                newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading
            self.headingAccuracy = newHeading.headingAccuracy
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \\(error.localizedDescription)")
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus

        Task { @MainActor in
            self.isLocationActive = (status == .authorizedWhenInUse || status == .authorizedAlways)

            if self.isLocationActive {
                manager.startUpdatingLocation()
                manager.startUpdatingHeading()
            }
        }
    }
}
