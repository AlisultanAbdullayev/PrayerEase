//
//  LocationManager.swift
//  PrayerEase
//
//  Created by Alisultan Abdullah on 10/30/24.
//

import Adhan
import Combine
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
    @Published var heading: Double = 0
    @Published var headingAccuracy: Double = 0.0 {
        didSet {
            // Negative start = uncalibrated. > 45 = low accuracy/interference
            isInterferenceDetected = headingAccuracy < 0 || headingAccuracy > 45
        }
    }
    @Published var isInterferenceDetected: Bool = false
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined

    // MARK: - Private Properties
    private let locationManager = CLLocationManager()
    private let userDefaults = UserDefaults(suiteName: "group.com.alijaver.PrayerEase")
    private var locationTask: Task<Void, Never>?
    private var locationDelegate: LocationDelegate?

    // MARK: - Lifecycle
    init() {
        setupLocationManager()
        loadSavedData()
    }

    private func setupLocationManager() {
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 100

        let adapter = LocationDelegate(manager: self)
        self.locationDelegate = adapter
        locationManager.delegate = adapter

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

    // MARK: - Public Methods
    func updateStatus() {
        authorizationStatus = locationManager.authorizationStatus
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

    private var headingRequests = 0

    func startUpdatingHeading() {
        headingRequests += 1
        if headingRequests == 1 {
            locationManager.startUpdatingHeading()
        }
    }

    func stopUpdatingHeading() {
        headingRequests = max(0, headingRequests - 1)
        if headingRequests == 0 {
            locationManager.stopUpdatingHeading()
        }
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

// MARK: - Private Delegate Adapter
private class LocationDelegate: NSObject, CLLocationManagerDelegate {
    weak var manager: LocationManager?

    init(manager: LocationManager) {
        self.manager = manager
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        Task { @MainActor [weak self] in
            guard let self = self?.manager else { return }
            self.heading = newHeading.trueHeading
            self.headingAccuracy = newHeading.headingAccuracy
        }
    }
}
