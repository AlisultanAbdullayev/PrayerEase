//
//  WatchQiblaViewModel.swift
//  PrayerEaseWatch Watch App
//
//  Created by Antigravity on 12/23/25.
//

import Combine
import CoreLocation
import Foundation
import SwiftUI

/// View model for Qibla direction screen on watchOS
@MainActor
final class WatchQiblaViewModel: NSObject, ObservableObject {

    // MARK: - Published Properties

    @Published var heading: Double = 0
    @Published var qiblaDirection: Double = 0
    @Published var userLocation: CLLocation?
    @Published var headingAccuracy: Double = -1
    @Published var isLocationActive: Bool = false

    /// Cumulative rotation for smooth animation (not limited to 0-360)
    @Published var cumulativeRotation: Double = 0

    // MARK: - Private Properties

    private let locationManager = CLLocationManager()
    private var lastHeading: Double = 0
    private var isFirstHeading = true

    // MARK: - Initialization

    override init() {
        super.init()
        setupLocationManager()
    }

    // MARK: - Setup

    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.headingFilter = 1
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

    /// Updates heading with proper wraparound handling
    private func updateHeading(_ newHeading: Double) {
        if isFirstHeading {
            // Initialize on first heading
            heading = newHeading
            lastHeading = newHeading
            cumulativeRotation = qiblaDirection - newHeading
            isFirstHeading = false
            return
        }

        // Calculate the shortest delta (handles 360/0 wraparound)
        var delta = newHeading - lastHeading
        if delta > 180 { delta -= 360 }
        if delta < -180 { delta += 360 }

        // Update heading and cumulative rotation
        heading = newHeading
        lastHeading = newHeading

        // Cumulative rotation goes opposite direction of heading
        cumulativeRotation -= delta
    }

    // MARK: - Computed Properties

    /// Accuracy percentage (0-100)
    var accuracyPercentage: Int {
        let accuracy = headingAccuracy
        if accuracy < 0 { return 0 }
        return Int(max(0, 100 - accuracy))
    }

    /// Whether user is pointing toward Qibla (within 5 degrees)
    var isPointingToQibla: Bool {
        let diff = abs(heading - qiblaDirection)
        return diff <= 5 || diff >= 355
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

            let newQibla = QiblaService.calculateQiblaDirection(from: location)

            // If Qibla direction changes (e.g. initial fix), adjust rotation
            if !self.isFirstHeading {
                let diff = newQibla - self.qiblaDirection
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    self.cumulativeRotation += diff
                }
            }

            self.qiblaDirection = newQibla
        }
    }

    nonisolated func locationManager(
        _ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading
    ) {
        Task { @MainActor in
            let newValue =
                newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading
            self.updateHeading(newValue)
            self.headingAccuracy = newHeading.headingAccuracy
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
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
