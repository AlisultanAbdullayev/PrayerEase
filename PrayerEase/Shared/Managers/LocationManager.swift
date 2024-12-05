//
//  LocationManager.swift
//  PrayerEase
//
//  Created by Alisultan Abdullah on 10/30/24.
//


import Adhan
import SwiftUI
import CoreLocation

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
    private let geocoder = CLGeocoder()
    private let userDefaults = UserDefaults(suiteName: "group.com.alijaver.SalahTime")
    private let notificationManager = NotificationManager.shared
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
        geocoder.reverseGeocodeLocation(tempLocation) { [weak self] placemarks, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.error = error
                } else if let placemark = placemarks?.first {
                    self?.locationName = placemark.locality ?? placemark.administrativeArea ?? placemark.country ?? "Unknown location"
                }
            }
        }
    }
    
    private func updateDependentManagers() {
        guard let location = userLocation else { return }
        prayerTimeManager.updateLocation(location)
        notificationManager.updateLocation(location)
        notificationManager.scheduleLongTermNotifications()
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
