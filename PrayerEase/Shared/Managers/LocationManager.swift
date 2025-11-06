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

final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published private(set) var locationName: String = "N/A" {
        didSet { saveLocationName() }
    }
    @Published private(set) var userLocation: CLLocation? {
        didSet {
            saveUserLocation()
            updateDependentManagers()
        }
    }
    @Published private(set) var error: Error?
    @Published private(set) var isLocationActive: Bool = false
    @Published var heading: Int = 0
    @Published var headingAccuracy: Double = 0.0
    
    private let cLLocationManager = CLLocationManager()
    private let userDefaults = UserDefaults(suiteName: "group.com.alijaver.SalahTime")
    private let prayerTimeManager = PrayerTimeManager.shared
    
    override init() {
        super.init()
        setupLocationManager()
        loadSavedData()
    }
    
    private func setupLocationManager() {
        cLLocationManager.delegate = self
        cLLocationManager.desiredAccuracy = kCLLocationAccuracyBest
        cLLocationManager.requestWhenInUseAuthorization()
        cLLocationManager.startUpdatingLocation()
        cLLocationManager.startUpdatingHeading()
    }
    
    private func loadSavedData() {
        getUserLocation()
        getLocationName()
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        isLocationActive = status == .authorizedWhenInUse || status == .authorizedAlways
        if isLocationActive {
            manager.startUpdatingLocation()
        } else {
            manager.requestWhenInUseAuthorization()
            updateDependentManagers()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        userLocation = location
        fetchGeocoder(tempLocation: location)
        manager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        heading = Int(newHeading.trueHeading)
        self.headingAccuracy = newHeading.headingAccuracy
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        self.error = error
    }
    
    private func fetchGeocoder(tempLocation: CLLocation) {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            
            // Use MKLocalSearch as the replacement for deprecated CLGeocoder
            let searchRequest = MKLocalSearch.Request()
            searchRequest.naturalLanguageQuery = String(
                format: "%.6f, %.6f", 
                tempLocation.coordinate.latitude, 
                tempLocation.coordinate.longitude
            )
            searchRequest.region = MKCoordinateRegion(
                center: tempLocation.coordinate, 
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
            
            let search = MKLocalSearch(request: searchRequest)
            
            do {
                let response = try await search.start()
                if let mapItem = response.mapItems.first {
                    self.locationName = mapItem.name ?? "Unknown location"
                } else {
                    // Fallback to coordinate display if no results
                    self.locationName = String(format: "%.3f, %.3f", 
                                             tempLocation.coordinate.latitude, 
                                             tempLocation.coordinate.longitude)
                }
            } catch {
                self.error = error
                // Try a different approach - search by coordinate string
                let coordinateSearchRequest = MKLocalSearch.Request()
                coordinateSearchRequest.naturalLanguageQuery = String(
                    format: "%.6f, %.6f", 
                    tempLocation.coordinate.latitude, 
                    tempLocation.coordinate.longitude
                )
                coordinateSearchRequest.region = MKCoordinateRegion(
                    center: tempLocation.coordinate, 
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                )
                
                let coordinateSearch = MKLocalSearch(request: coordinateSearchRequest)
                
                do {
                    let coordinateResponse = try await coordinateSearch.start()
                    if let mapItem = coordinateResponse.mapItems.first {
                        self.locationName = mapItem.name ?? "Unknown location"
                    } else {
                        self.locationName = "Unknown location"
                    }
                } catch {
                    self.locationName = "Unknown location"
                }
            }
        }
    }
    
    private func updateDependentManagers() {
        guard let location = userLocation else { return }
        prayerTimeManager.updateLocation(location)
        Task { @MainActor in
            NotificationManager.shared.updateLocation(location)
            await NotificationManager.shared.scheduleLongTermNotifications()
        }
    }
    
    func calculateQiblaDirection(from location: CLLocation) -> Int {
        let qiblaDegree = Qibla(coordinates: Coordinates(latitude: location.coordinate.latitude,
                                                         longitude: location.coordinate.longitude)).direction
        return Int(qiblaDegree)
    }
    
    func requestLocation() {
        cLLocationManager.requestWhenInUseAuthorization()
    }
    
    func startUpdatingHeading() {
        cLLocationManager.startUpdatingHeading()
    }
    
//    @MainActor
    func stopUpdatingHeading() {
        cLLocationManager.stopUpdatingHeading()
    }
    
//    @MainActor
    func startUpdatingLocation() {
        cLLocationManager.startUpdatingLocation()
    }
    
    
    
    func stopUpdatingLocation() {
        cLLocationManager.stopUpdatingLocation()
    }
    
    private func saveUserLocation() {
        guard let userLocation = userLocation, let userDefaults = userDefaults else { return }
        userDefaults.set(location: userLocation, forKey: "userLocation")
    }
    
    private func getUserLocation() {
        guard let userDefaults = userDefaults else { return }
        userLocation = userDefaults.location(forKey: "userLocation")
    }
    
    private func saveLocationName() {
        guard let userDefaults = userDefaults else { return }
        userDefaults.setValue(locationName, forKey: "locationName")
    }
    
    private func getLocationName() {
        guard let userDefaults = userDefaults, let savedString = userDefaults.string(forKey: "locationName") else { return }
        locationName = savedString
    }
}
