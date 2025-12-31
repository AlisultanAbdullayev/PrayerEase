//
//  AppConstants.swift
//  PrayerEase
//
//  Centralized constants to eliminate hardcoded values across the codebase.
//

import Foundation

/// App-wide constants shared across all targets
enum AppConstants {
    /// App Group identifier for shared UserDefaults and data between app and extensions
    static let appGroupId = "group.com.alijaver.PrayerEase"

    /// Widget kind identifier
    static let widgetKind = "com.alijaver.PrayerEase.PrayerEaseWidget"

    /// Background task identifier for notification refresh
    static let backgroundTaskId = "com.alijaver.SalahTimes.refreshNotifications"

    /// UserDefaults keys for shared data
    enum Keys {
        static let widgetPrayerTimes = "widgetPrayerTimes"
        static let locationName = "locationName"
        static let islamicDate = "islamicDate"
        static let userLocation = "userLocation"
        static let userTimeZone = "userTimeZone"
        static let isAutoLocationEnabled = "isAutoLocationEnabled"
        static let isDuhaEnabled = "isDuhaEnabled"
        static let isTahajjudEnabled = "isTahajjudEnabled"
        static let isLiveActivityEnabled = "isLiveActivityEnabled"
        static let madhab = "madhab"
        static let method = "method"
        static let isMethodManuallySet = "isMethodManuallySet"
        static let notifications = "notifications"
        static let notificationsBefore = "notificationsBefore"
        static let beforeMinutes = "beforeMinutes"
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
    }

    /// Prayer names as constants
    enum PrayerNames {
        static let fajr = "Fajr"
        static let sunrise = "Sunrise"
        static let dhuhr = "Dhuhr"
        static let asr = "Asr"
        static let maghrib = "Maghrib"
        static let isha = "Isha"
        static let duha = "Duha"
        static let tahajjud = "Tahajjud"

        static let all: [String] = [fajr, sunrise, dhuhr, asr, maghrib, isha]
    }

    /// Time intervals in seconds
    enum TimeIntervals {
        static let oneMinute: TimeInterval = 60
        static let oneHour: TimeInterval = 3600
        static let oneDay: TimeInterval = 86400
        static let duhaOffsetFromSunrise: TimeInterval = 45 * 60  // 45 minutes
    }
}
