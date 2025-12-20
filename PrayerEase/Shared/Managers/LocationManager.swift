//
//  LocationManager.swift
//  PrayerEase
//
//  Created by Alisultan Abdullah on 10/30/24.
//

import Adhan
import CoreLocation
import MapKit
import SwiftUI

@MainActor
final class LocationManager: ObservableObject {
    // MARK: - Published Properties
    @Published private(set) var locationName: String = "N/A" {
        didSet { saveLocationName() }
    }
    @Published private(set) var userLocation: CLLocation? {
        didSet { saveUserLocation() }
    }
    @Published private(set) var error: Error?
    @Published private(set) var isLocationActive: Bool = false
    @Published private(set) var userTimeZone: String? {
        didSet { userDefaults?.set(userTimeZone, forKey: "userTimeZone") }
    }
    @Published var isAutoLocationEnabled: Bool = true {
        didSet {
            userDefaults?.set(isAutoLocationEnabled, forKey: "isAutoLocationEnabled")
            if isAutoLocationEnabled {
                startLocationUpdates()
            } else {
                stopLocationUpdates()
            }
        }
    }
    @Published var heading: Int = 0
    @Published var headingAccuracy: Double = 0.0

    // MARK: - Private Properties
    private let locationManager = CLLocationManager()
    private let userDefaults = UserDefaults(suiteName: "group.com.alijaver.SalahTime")
    private var locationTask: Task<Void, Never>?

    // MARK: - Lifecycle
    init() {
        setupLocationManager()
        loadSavedData()
    }

    private func setupLocationManager() {
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 100

        // Check current status on generic init
        updateStatus()
    }

    private func loadSavedData() {
        if let savedLocation = userDefaults?.location(forKey: "userLocation") {
            self.userLocation = savedLocation
        }
        if let savedName = userDefaults?.string(forKey: "locationName") {
            self.locationName = savedName
        }
        self.userTimeZone = userDefaults?.string(forKey: "userTimeZone")
        if let isEnabled = userDefaults?.object(forKey: "isAutoLocationEnabled") as? Bool {
            self.isAutoLocationEnabled = isEnabled
        } else {
            self.isAutoLocationEnabled = true
        }
    }

    // Check status purely based on manager properties, no delegate
    private func updateStatus() {
        switch locationManager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            isLocationActive = true
            if isAutoLocationEnabled {
                startLocationUpdates()
            }
            locationManager.startUpdatingHeading()
        default:
            isLocationActive = false
        }
    }

    // MARK: - Public Methods
    func requestLocation() {
        print("DEBUG: requestLocation called")
        // Just Request Auth
        locationManager.requestWhenInUseAuthorization()

        // Then start monitoring immediately.
        // liveUpdates() will suspend until authorized.
        if isAutoLocationEnabled {
            print("DEBUG: Auto enabled, checking if updates running")
            startLocationUpdates(authorizeIfNeeded: true)
        }
    }

    private func startLocationUpdates(authorizeIfNeeded: Bool = false) {
        // Prevent duplicate tasks
        print("DEBUG: startLocationUpdates called. Existing task: \(locationTask != nil)")
        guard locationTask == nil else { return }

        // If we are not explicitly asking for authorization (e.g. startup auto-check),
        // and status is undetermined, do NOT start (which would trigger implicit prompt).
        if !authorizeIfNeeded && locationManager.authorizationStatus == .notDetermined {
            print(
                "DEBUG: Skipping startLocationUpdates because auth is undetermined and authorizeIfNeeded is false."
            )
            return
        }

        locationTask = Task { [weak self] in
            guard let self = self else { return }
            do {
                print("DEBUG: Waiting for liveUpdates...")
                // This sequence waits for authorization implicitly
                let updates = CLLocationUpdate.liveUpdates()
                for try await update in updates {
                    print(
                        "DEBUG: Update received. Location: \(String(describing: update.location))")
                    if let location = update.location {
                        // Efficiency optimized: Only process significant changes (> 5km)
                        if let lastLocation = self.userLocation,
                            location.distance(from: lastLocation) < 5000
                        {
                            print("DEBUG: Location change insignificant (< 5km). Skipping update.")
                            continue
                        }

                        self.userLocation = location
                        self.isLocationActive = true
                        print("DEBUG: Location active, reverse geocoding...")
                        await reverseGeocode(location: location)
                    } else {
                        print("DEBUG: Update received but location is nil.")
                    }
                }
            } catch {
                print("DEBUG: Location updates error: \(error)")
            }
        }
    }

    private func stopLocationUpdates() {
        locationTask?.cancel()
        locationTask = nil
    }

    func startUpdatingHeading() {
        locationManager.startUpdatingHeading()
    }

    func stopUpdatingHeading() {
        locationManager.stopUpdatingHeading()
    }

    func calculateQiblaDirection(from location: CLLocation) -> Int {
        let qiblaDegree = Qibla(
            coordinates: Coordinates(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude)
        ).direction
        return Int(qiblaDegree)
    }

    func refreshLocation() async {
        // If auto updates are enabled, ensure the continuous task is running.
        if isAutoLocationEnabled {
            if locationTask == nil {
                startLocationUpdates(authorizeIfNeeded: true)
            }
        } else {
            // If manual, fetch data once and stop.
            await startOneTimeUpdate()
        }
    }

    private func startOneTimeUpdate() async {
        print("DEBUG: Starting one-time location update...")
        do {
            let updates = CLLocationUpdate.liveUpdates()
            for try await update in updates {
                if let location = update.location {
                    print("DEBUG: One-time update received: \(location)")
                    self.userLocation = location
                    self.isLocationActive = true
                    await reverseGeocode(location: location)
                    break  // Stop listening after one valid update
                }
            }
        } catch {
            print("DEBUG: One-time update error: \(error)")
        }
    }

    // MARK: - Private Helpers
    private func saveUserLocation() {
        guard let location = userLocation else { return }
        userDefaults?.set(location: location, forKey: "userLocation")
    }

    private func saveLocationName() {
        userDefaults?.setValue(locationName, forKey: "locationName")
    }

    private func reverseGeocode(location: CLLocation) async {
        if let request = MKReverseGeocodingRequest(location: location) {
            do {
                let mapItems = try await request.mapItems
                if let mapItem = mapItems.first {
                    // Use modern accessors if possible, forcing name for now
                    self.locationName =
                        mapItem.addressRepresentations?.cityWithContext ?? "Unknown location"
                    if let timeZone = mapItem.timeZone {
                        self.userTimeZone = timeZone.identifier
                    } else {
                        self.userTimeZone = TimeZone.current.identifier
                    }
                }
            } catch {
                print("Reverse geocode failed: \(error.localizedDescription)")
            }
        }
    }
}
