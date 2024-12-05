//
//  Extensions.swift
//  PrayerEase
//
//  Created by Alisultan Abdullah on 10/30/24.
//

import Foundation
import CoreLocation

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
