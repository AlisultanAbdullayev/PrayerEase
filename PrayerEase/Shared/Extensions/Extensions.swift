//
//  Extensions.swift
//  PrayerEase
//
//  Created by Alisultan Abdullah on 10/30/24.
//

import Adhan
import CoreLocation
import Foundation

extension Double {
    var radiansToDegrees: Double {
        self * .pi / 180
    }
}

extension UserDefaults {
    func set(location:CLLocation, forKey key: String) {
        let locationLat = NSNumber(value:location.coordinate.latitude)
        let locationLon = NSNumber(value:location.coordinate.longitude)
        self.set(["lat": locationLat, "long": locationLon], forKey:key)
    }
    
    func location(forKey key: String) -> CLLocation? {
        if let locationDictionary = self.object(forKey: key) as? Dictionary<String,NSNumber> {
            let locationLat = locationDictionary["lat"]!.doubleValue
            let locationLon = locationDictionary["long"]!.doubleValue
            return CLLocation(latitude: locationLat, longitude: locationLon)
        }
        return nil
    }
}

// MARK: - Prayer Extension

extension Prayer {
    var name: String {
        switch self {
        case .fajr: return "Fajr"
        case .sunrise: return "Sunrise"
        case .dhuhr: return "Dhuhr"
        case .asr: return "Asr"
        case .maghrib: return "Maghrib"
        case .isha: return "Isha"
        }
    }
}
