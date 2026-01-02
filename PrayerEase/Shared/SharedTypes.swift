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
    static let fiveMinutes: TimeInterval = 300
    static let fifteenMinutes: TimeInterval = 900
    static let oneHour: TimeInterval = 3600
    static let fourHours: TimeInterval = 14400
    static let twelveHours: TimeInterval = 43200
    static let oneDay: TimeInterval = 86400
    static let duhaOffsetFromSunrise: TimeInterval = 45 * 60

    /// One hour minus 5 seconds (for timeline entry before prayer)
    static let oneHourMinus5Seconds: TimeInterval = 3595
}

// MARK: - UI Constants

/// UI-related constants
enum UIConstants {
    /// Default progress value when previous prayer time is unavailable
    static let defaultProgressFallback: Double = 0.5
}

// MARK: - Default Values

/// Default values and placeholders
enum DefaultValues {
    static let loadingPlaceholder = "Loading..."
    static let unknownLocation = "N/A"
    static let defaultBeforeMinutes = 25
    /// Distance in meters before triggering location-based updates
    static let locationChangeThreshold: Double = 2000
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

// MARK: - Prayer Time Calculator

/// Prayer time calculation service for reuse across all targets
/// Includes optional prayer calculations, progress tracking, and countdown formatting
enum PrayerTimeCalculator {

    // MARK: - Optional Prayer Calculations

    /// Calculate Duha time (45 min after sunrise)
    static func duhaTime(from sunrise: Date) -> Date {
        sunrise.addingTimeInterval(TimeIntervals.duhaOffsetFromSunrise)
    }

    /// Calculate Tahajjud time (last third of night between Maghrib and Fajr)
    static func tahajjudTime(maghrib: Date, fajrTomorrow: Date) -> Date {
        let nightDuration = fajrTomorrow.timeIntervalSince(maghrib)
        let lastThird = nightDuration / 3
        return fajrTomorrow.addingTimeInterval(-lastThird)
    }

    // MARK: - Progress Calculations

    /// Calculate progress between two prayer times
    static func progress(
        from previousTime: Date?,
        to nextTime: Date,
        at currentDate: Date = Date()
    ) -> Double {
        guard let prevTime = previousTime else {
            return UIConstants.defaultProgressFallback
        }
        let totalInterval = nextTime.timeIntervalSince(prevTime)
        let elapsed = currentDate.timeIntervalSince(prevTime)
        guard totalInterval > 0 else { return 0 }
        return min(max(elapsed / totalInterval, 0), 1)
    }

    // MARK: - Prayer Lookup

    /// Determine the current active prayer from a list
    static func currentPrayer(
        from prayers: [SharedPrayerTime],
        at date: Date = Date()
    ) -> SharedPrayerTime? {
        for i in 0..<prayers.count {
            let current = prayers[i]
            if i < prayers.count - 1 {
                let next = prayers[i + 1]
                if date >= current.time && date < next.time {
                    return current
                }
            } else {
                if date >= current.time {
                    return current
                }
            }
        }
        return prayers.last
    }

    /// Find next prayer from a list
    static func nextPrayer(
        from prayers: [SharedPrayerTime],
        at date: Date = Date()
    ) -> SharedPrayerTime? {
        prayers.first { $0.time > date }
    }

    /// Find previous prayer time from a list
    static func previousPrayerTime(
        from prayers: [SharedPrayerTime],
        at date: Date = Date()
    ) -> Date? {
        let sorted = prayers.sorted { $0.time < $1.time }
        if let nextIndex = sorted.firstIndex(where: { $0.time > date }) {
            if nextIndex > 0 {
                return sorted[nextIndex - 1].time
            } else {
                if let isha = sorted.last {
                    return Calendar.current.date(byAdding: .day, value: -1, to: isha.time)
                }
            }
        }
        return sorted.last?.time
    }

    // MARK: - Date Projection

    /// Project a past prayer time to future by adding minimum days needed
    static func projectToFuture(_ date: Date, from referenceDate: Date) -> Date {
        guard date <= referenceDate else { return date }

        let calendar = Calendar.current
        let daysDifference = calendar.dateComponents([.day], from: date, to: referenceDate).day ?? 0
        let daysToAdd = daysDifference + 1

        return calendar.date(byAdding: .day, value: daysToAdd, to: date)
            ?? date.addingTimeInterval(Double(daysToAdd) * TimeIntervals.oneDay)
    }

    // MARK: - Countdown Formatting

    /// Format countdown for compact display (watch complications)
    static func formatCompactCountdown(_ remaining: TimeInterval) -> String {
        if remaining >= TimeIntervals.oneHour {
            return "\(Int(remaining / TimeIntervals.oneHour))h+"
        } else if remaining >= TimeIntervals.oneMinute {
            return "\(Int(remaining / TimeIntervals.oneMinute))m+"
        } else {
            return "<1m"
        }
    }
}
