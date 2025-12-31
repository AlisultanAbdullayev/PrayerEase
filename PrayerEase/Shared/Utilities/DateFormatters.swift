//
//  DateFormatters.swift
//  PrayerEase
//
//  Cached DateFormatters to avoid repeated allocation (DateFormatter is expensive to create).
//

import Foundation

/// Cached formatters for prayer time display (DRY principle - avoid recreating formatters)
enum DateFormatters {
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

    /// Formatter for date identifiers (e.g., "2024-12-31")
    static let dateIdentifier: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
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
