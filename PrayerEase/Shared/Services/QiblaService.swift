//
//  QiblaService.swift
//  PrayerEase
//
//  Created by Alisultan Abdullah on 12/20/24.
//

import Adhan
import CoreLocation
import Foundation

struct QiblaService {
    static func calculateQiblaDirection(from location: CLLocation) -> Double {
        let qiblaDegree = Qibla(
            coordinates: Coordinates(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude)
        ).direction
        return qiblaDegree
    }
}
