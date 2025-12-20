//
//  CalculationMethodHelper.swift
//  PrayerEase
//
//  Created by Alisultan Abdullah on 12/20/24.
//

import Adhan
import Foundation

struct CalculationMethodHelper {
    static func autoSelectMethod(for timeZoneIdentifier: String) -> CalculationMethod? {
        // Simplified mapping based on region prefixes or known cities
        if timeZoneIdentifier.contains("Riyadh") {
            return .ummAlQura
        } else if timeZoneIdentifier.contains("Istanbul") {
            return .turkey
        } else if timeZoneIdentifier.contains("Qatar") {
            return .qatar
        } else if timeZoneIdentifier.contains("Kuwait") {
            return .kuwait
        } else if timeZoneIdentifier.contains("Dubai") {
            return .dubai
        } else if timeZoneIdentifier.contains("Cairo") {
            return .egyptian
        } else if timeZoneIdentifier.contains("Karachi") {
            return .karachi
        } else if timeZoneIdentifier.contains("Singapore") {
            return .singapore
        } else if timeZoneIdentifier.contains("Tehran") {
            return .tehran
        } else if timeZoneIdentifier.contains("America") || timeZoneIdentifier.contains("Canada")
            || timeZoneIdentifier.contains("US")
        {
            return .northAmerica
        } else if timeZoneIdentifier.contains("London") {
            return .moonsightingCommittee
        } else {
            return .muslimWorldLeague
        }
    }
}
