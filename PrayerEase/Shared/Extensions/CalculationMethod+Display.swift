//
//  CalculationMethod+Display.swift
//  PrayerEase
//

import Adhan

extension CalculationMethod {
    /// Human-readable display name for this calculation method.
    var displayName: String {
        switch self {
        case .dubai: return "Dubai"
        case .muslimWorldLeague: return "Muslim World League"
        case .egyptian: return "Egyptian General Authority of Survey"
        case .karachi: return "University of Islamic Sciences, Karachi"
        case .ummAlQura: return "Umm Al-Qura University, Makkah"
        case .moonsightingCommittee: return "Moonsighting Committee Worldwide"
        case .northAmerica: return "Islamic Society of North America"
        case .kuwait: return "Kuwait"
        case .qatar: return "Qatar"
        case .singapore: return "Majlis Ugama Islam Singapura, Singapore"
        case .tehran: return "Institute of Geophysics, University of Tehran"
        case .turkey: return "Diyanet İşleri Başkanlığı, Turkey"
        case .other: return "Other"
        }
    }
}
