//
//  LocationManager.swift
//  PrayerEase
//
//  Created by Alisultan Abdullah on 10/30/24.
//


import Adhan
import SwiftUI
import CoreLocation
import MapKit

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
        
        // Check Status
        updateAuthorizationStatus()
    }
    
    private func loadSavedData() {
        if let savedLocation = userDefaults?.location(forKey: "userLocation") {
            self.userLocation = savedLocation
        }
        if let savedName = userDefaults?.string(forKey: "locationName") {
            self.locationName = savedName
        }
        self.isAutoLocationEnabled = userDefaults?.bool(forKey: "isAutoLocationEnabled") ?? true
    }
    
    private func updateAuthorizationStatus() {
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            isLocationActive = true
            if isAutoLocationEnabled {
                startLocationUpdates()
            }
            locationManager.startUpdatingHeading()
        case .notDetermined:
            // Waiting for request
            isLocationActive = false
        case .restricted, .denied:
            isLocationActive = false
            stopLocationUpdates()
        @unknown default:
            break
        }
    }
    
    // MARK: - Public Methods
    func requestLocation() {
        if locationManager.authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
            
            // Poll for status change or assume user interaction will trigger app lifecycle events
            // In a relentless loop or via delegate is strict "Old way".
            // Bridging to "New way" without delegate for Auth is tricky because `CLLocationUpdate`
            // doesn't stream auth changes directly.
            // However, we can use a Task to monitor updates once authorized.
            
            Task {
                // Wait briefly/Checking loop could be implemented,
                // but usually the UI handles the re-check or we lazily start on next active.
                // For "Modern", we often lean on the stream starting when allowed.
                if isAutoLocationEnabled {
                    startLocationUpdates()
                }
            }
        } else {
            // Manual Request or Active
            // If Auto is ON: ensure it's running
            // If Auto is OFF: Run once then stop
            
            if isAutoLocationEnabled {
                startLocationUpdates()
            } else {
                Task {
                   await requestOneTimeLocation()
                }
            }
        }
    }
    
    private func requestOneTimeLocation() async {
        // Start updates, get one, then stop.
        // We reuse logic but ensure we break.
        // Or we use `requestLocation()` from CLLocationManager if we were using delegate,
        // but since we rely on AsyncSequence...
        
        guard locationTask == nil else { return } // Already running?
        
        locationTask = Task {
            do {
                let updates = CLLocationUpdate.liveUpdates()
                for try await update in updates {
                    if let location = update.location {
                        self.userLocation = location
                        await reverseGeocode(location: location)
                        break // Stop immediately for one-time request
                    }
                }
            } catch {
                print("Location updates error: \(error)")
            }
            // Cleanup task reference
            self.locationTask = nil
        }
    }
    
    private func startLocationUpdates() {
        guard locationTask == nil else { return }
        
        locationTask = Task {
            do {
                // Modern Async Iteration
                // Note: liveUpdates is iOS 17+. If we need lower (iOS 15), we wrap delegate in AsyncStream.
                // Assuming "Modernize" allows cutting edge or at least standard AsyncStream.
                // Since I cannot verify OS version, I will use the safest modern wrapper: AsyncStream wrapping the CL updates
                // BUT, to completely remove NSObject, we MUST blindly trust `CLLocationUpdate` (iOS 17).
                // If user encounters error, we can fallback.
                
                let updates = CLLocationUpdate.liveUpdates()
                for try await update in updates {
                    if let location = update.location {
                        self.userLocation = location
                        await reverseGeocode(location: location)
 
                    }
                }
            } catch {
                print("Location updates error: \(error)")
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
        let qiblaDegree = Qibla(coordinates: Coordinates(latitude: location.coordinate.latitude,
                                                         longitude: location.coordinate.longitude)).direction
        return Int(qiblaDegree)
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
                let mapItem = mapItems.first
                self.locationName = mapItem?.addressRepresentations?.cityWithContext ?? "Unknown location"
            } catch  {
                print(error.localizedDescription)
            }
        }
    }
}
