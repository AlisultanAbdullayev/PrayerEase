//
//  SharedTypes.swift
//  PrayerEase
//
//  Shared between: iOS App, iOS Widget, Watch App, Watch Widget
//  Add this file to ALL 4 targets in Xcode for code reusability.
//

import Foundation

// MARK: - App Configuration

/// Centralized app configuration shared across all targets
enum AppConfig {
    /// App Group identifier for shared UserDefaults
    static let appGroupId = "group.com.alijaver.PrayerEase"

    /// Widget kind identifier
    static let widgetKind = "com.alijaver.PrayerEase.PrayerEaseWidget"

    /// Background task identifier for notification refresh
    static let backgroundTaskId = "com.alijaver.SalahTimes.refreshNotifications"
}

// MARK: - Storage Keys

/// UserDefaults keys for shared data persistence
enum StorageKeys {
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

// MARK: - Prayer Names

/// Standard prayer name constants
enum PrayerNames {
    static let fajr = "Fajr"
    static let sunrise = "Sunrise"
    static let dhuhr = "Dhuhr"
    static let asr = "Asr"
    static let maghrib = "Maghrib"
    static let isha = "Isha"
    static let duha = "Duha"
    static let tahajjud = "Tahajjud"

    static let standard: [String] = [fajr, sunrise, dhuhr, asr, maghrib, isha]
}

// MARK: - Time Intervals

/// Common time intervals in seconds
enum TimeIntervals {
    static let oneMinute: TimeInterval = 60
    static let oneHour: TimeInterval = 3600
    static let oneDay: TimeInterval = 86400
    static let duhaOffsetFromSunrise: TimeInterval = 45 * 60
}

// MARK: - Shared Prayer Time Model

/// Prayer time model shared across all targets
struct SharedPrayerTime: Identifiable, Equatable, Codable, Hashable, Sendable {
    var id: String { name }
    let name: String
    let time: Date

    var iconName: String {
        switch name.lowercased() {
        case "fajr": return "circle.lefthalf.filled"
        case "sunrise": return "sunrise.fill"
        case "dhuhr": return "sun.max.fill"
        case "asr": return "sun.haze.fill"
        case "maghrib": return "sunset.fill"
        case "isha": return "moon.stars.fill"
        case "duha": return "sun.max.fill"
        case "tahajjud": return "moon.stars.fill"
        default: return "circle.fill"
        }
    }

    var shortName: String {
        String(name.prefix(3)).uppercased()
    }

    var timeString: String {
        time.formatted(.dateTime.hour().minute())
    }

    var hourMinuteString: String {
        SharedFormatters.hourMinute.string(from: time)
    }

    var amPmString: String {
        SharedFormatters.amPm.string(from: time)
    }
}

// MARK: - Cached DateFormatters

/// Cached formatters to avoid repeated allocation (DateFormatter is expensive)
enum SharedFormatters {
    /// Formatter for prayer time display (e.g., "5:30 AM")
    static let time: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeZone = .current
        formatter.timeStyle = .short
        return formatter
    }()

    /// Formatter for hour:minute only (e.g., "5:30")
    static let hourMinute: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm"
        return formatter
    }()

    /// Formatter for AM/PM only
    static let amPm: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "a"
        return formatter
    }()

    /// Formatter for Hijri dates
    static let hijri: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .islamicUmmAlQura)
        formatter.dateFormat = "d MMMM yyyy"
        return formatter
    }()

    /// Formatter for Hijri medium style
    static let hijriMedium: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .islamicUmmAlQura)
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    // MARK: - Convenience Methods

    static func formatTime(_ date: Date?) -> String {
        guard let date else { return "N/A" }
        return time.string(from: date)
    }

    static func formatHijri(_ date: Date) -> String {
        hijri.string(from: date)
    }
}
