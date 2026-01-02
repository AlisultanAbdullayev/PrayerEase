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
import UserNotifications
import WidgetKit

// MARK: - Location Change Threshold

private let significantDistanceThreshold: CLLocationDistance = 35000  // 35 km

#if DEBUG
    private let disableNotificationThrottle = true  // Set to false to test throttling
#else
    private let disableNotificationThrottle = false
#endif

@MainActor
@Observable
final class LocationManager {
    // MARK: - Confirmed Location (used by widgets/complications)
    private(set) var locationName: String = "N/A" {
        didSet { saveLocationName() }
    }

    private(set) var userLocation: CLLocation? {
        didSet { saveUserLocation() }
    }

    private(set) var error: Error?
    private(set) var isLocationActive: Bool = false

    private(set) var userTimeZone: String? {
        didSet { userDefaults?.set(userTimeZone, forKey: "userTimeZone") }
    }

    // MARK: - Pending Location (awaiting user consent)
    var pendingLocation: CLLocation?
    var pendingLocationName: String = ""
    var hasPendingLocationChange: Bool = false
    var isShowingLocationPrompt: Bool = false
    private var pendingNotificationSent: Bool = false  // Prevent duplicate notifications

    // App state tracking (set from scenePhase in PrayerEaseApp)
    var isAppActive: Bool = true

    // MARK: - Settings
    var isAutoLocationEnabled: Bool = true {
        didSet {
            userDefaults?.set(isAutoLocationEnabled, forKey: "isAutoLocationEnabled")
            if isAutoLocationEnabled {
                startLocationUpdates(authorizeIfNeeded: false)
            } else {
                stopLocationUpdates()
                // Clear any pending location when turning off auto-location
                clearPendingLocation()
            }
        }
    }

    var heading: Double = 0

    var headingAccuracy: Double = 0.0 {
        didSet {
            isInterferenceDetected = headingAccuracy < 0 || headingAccuracy > 45
        }
    }

    var isInterferenceDetected: Bool = false
    var authorizationStatus: CLAuthorizationStatus = .notDetermined

    // MARK: - Private Properties
    private let locationManager = CLLocationManager()
    private let userDefaults = UserDefaults(suiteName: AppConfig.appGroupId)
    private var locationTask: Task<Void, Never>?
    private var locationDelegate: LocationDelegate?
    private var lastNotificationSentAt: Date?

    // MARK: - Lifecycle
    init() {
        setupLocationManager()
        loadSavedData()
        setupNotificationCategory()
    }

    private func setupLocationManager() {
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 100

        let adapter = LocationDelegate(manager: self)
        self.locationDelegate = adapter
        locationManager.delegate = adapter

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

    // MARK: - Notification Setup
    private func setupNotificationCategory() {
        let updateAction = UNNotificationAction(
            identifier: "UPDATE_LOCATION",
            title: "Update",
            options: .foreground
        )
        let keepAction = UNNotificationAction(
            identifier: "KEEP_LOCATION",
            title: "Keep Current",
            options: .destructive
        )

        let category = UNNotificationCategory(
            identifier: "LOCATION_CHANGE",
            actions: [updateAction, keepAction],
            intentIdentifiers: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([category])
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
        locationManager.requestWhenInUseAuthorization()

        if isAutoLocationEnabled {
            print("DEBUG: Auto enabled, checking if updates running")
            startLocationUpdates(authorizeIfNeeded: true)
        }
    }

    private func startLocationUpdates(authorizeIfNeeded: Bool = false) {
        print("DEBUG: startLocationUpdates called. Existing task: \(locationTask != nil)")
        guard locationTask == nil else { return }

        if locationManager.authorizationStatus == .notDetermined {
            if !authorizeIfNeeded {
                print(
                    "DEBUG: Skipping startLocationUpdates because auth is undetermined and authorizeIfNeeded is false."
                )
                return
            } else {
                locationManager.requestWhenInUseAuthorization()
            }
        }

        locationTask = Task { [weak self] in
            guard let self = self else { return }
            do {
                print("DEBUG: Waiting for liveUpdates...")
                let updates = CLLocationUpdate.liveUpdates()
                for try await update in updates {
                    // Skip nil locations (normal during startup)
                    guard let location = update.location else { continue }
                    await self.handleLocationUpdate(location)
                }
            } catch {
                print("DEBUG: Location updates error: \(error)")
            }
        }
    }

    /// Handles new location - stores as pending if significant change detected
    private func handleLocationUpdate(_ newLocation: CLLocation) async {
        // First time: set location directly (no pending state)
        guard let currentLocation = self.userLocation else {
            self.userLocation = newLocation
            self.isLocationActive = true
            await reverseGeocode(location: newLocation)
            return
        }

        // Check if location changed significantly (5km threshold)
        let distance = newLocation.distance(from: currentLocation)
        guard distance >= significantDistanceThreshold else {
            print("DEBUG: Location change insignificant (\(Int(distance))m < 5km). Skipping.")
            return
        }

        print("DEBUG: Significant location change detected: \(Int(distance))m")

        // Store as PENDING location (do NOT update confirmed location)
        self.pendingLocation = newLocation
        self.hasPendingLocationChange = true

        // Reverse geocode the pending location
        if let request = MKReverseGeocodingRequest(location: newLocation) {
            do {
                let mapItems = try await request.mapItems
                if let mapItem = mapItems.first {
                    self.pendingLocationName =
                        mapItem.addressRepresentations?.cityWithContext ?? "New Location"
                }
            } catch {
                self.pendingLocationName = "New Location"
            }
        }

        // Only prompt once per location change (alert or notification)
        guard !pendingNotificationSent else {
            print("DEBUG: User already prompted for this location change")
            return
        }
        pendingNotificationSent = true

        // If app is in foreground, show alert directly; otherwise send notification
        if isAppActive {
            isShowingLocationPrompt = true
        } else {
            await sendLocationChangeNotification()
        }
    }

    /// Sends local notification asking user to confirm location change
    private func sendLocationChangeNotification() async {
        // Throttle: max 1 notification per hour (disabled in DEBUG)
        if !disableNotificationThrottle,
            let lastSent = lastNotificationSentAt,
            Date().timeIntervalSince(lastSent) < 3600
        {
            print("DEBUG: Notification throttled (sent within last hour)")
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "Location Changed"
        content.body =
            "Your location has changed to \(pendingLocationName). Would you like to update your prayer times?"
        content.sound = .default
        content.categoryIdentifier = "LOCATION_CHANGE"

        let request = UNNotificationRequest(
            identifier: "location-change-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
            lastNotificationSentAt = Date()
            print("DEBUG: Location change notification sent")
        } catch {
            print("DEBUG: Failed to send notification: \(error)")
        }
    }

    // MARK: - User Consent Actions

    /// Called when user accepts the location update
    func confirmPendingLocation() async {
        guard let pending = pendingLocation else { return }

        // Save as confirmed location
        self.userLocation = pending
        self.locationName = pendingLocationName
        self.isLocationActive = true

        // Geocode for timezone
        await reverseGeocode(location: pending)

        // Clear pending state
        clearPendingLocation()

        // Refresh widgets
        WidgetCenter.shared.reloadAllTimelines()

        // Notify watch
        IOSConnectivityManager.shared.sendCurrentPrayerData()

        print("DEBUG: Location confirmed and widgets refreshed")
    }

    /// Called when user declines the location update
    func declinePendingLocation() {
        print("DEBUG: User declined location update, keeping: \(locationName)")
        // Clear pending but KEEP pendingNotificationSent=true so we don't re-notify
        pendingLocation = nil
        pendingLocationName = ""
        hasPendingLocationChange = false
        isShowingLocationPrompt = false
        // NOTE: pendingNotificationSent stays TRUE until a genuinely new location change
    }

    private func clearPendingLocation() {
        pendingLocation = nil
        pendingLocationName = ""
        hasPendingLocationChange = false
        isShowingLocationPrompt = false
        pendingNotificationSent = false  // Reset so next location change can trigger notification
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
        if isAutoLocationEnabled {
            if locationTask == nil {
                startLocationUpdates(authorizeIfNeeded: true)
            }
        } else {
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
                    break
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

    func setManualLocation(_ location: CLLocation, name: String, timeZone: TimeZone?) {
        self.isAutoLocationEnabled = false
        self.userLocation = location
        self.locationName = name
        self.userTimeZone = timeZone?.identifier ?? TimeZone.current.identifier
        self.isLocationActive = true

        // Refresh widgets when manual location is set
        WidgetCenter.shared.reloadAllTimelines()
        IOSConnectivityManager.shared.sendCurrentPrayerData()
    }

    func searchLocation(startingWith query: String) async -> [MKMapItem] {
        guard !query.isEmpty else { return [] }
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.resultTypes = .address

        do {
            let search = MKLocalSearch(request: request)
            let response = try await search.start()
            return response.mapItems
        } catch {
            print("Search failed: \(error.localizedDescription)")
            return []
        }
    }

    private func reverseGeocode(location: CLLocation) async {
        if let request = MKReverseGeocodingRequest(location: location) {
            do {
                let mapItems = try await request.mapItems
                if let mapItem = mapItems.first {
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
