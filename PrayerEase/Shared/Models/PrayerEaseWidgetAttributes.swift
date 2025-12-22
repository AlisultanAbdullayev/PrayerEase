//
//  PrayerEaseWidgetAttributes.swift
//  PrayerEase
//
//  Created by Alisultan Abdullah on 12/21/25.
//

import ActivityKit
import Foundation

struct PrayerEaseWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        let nextPrayerName: String
        let nextPrayerTime: Date
        let locationName: String
        let islamicDate: String
        let allPrayerTimes: [LiveActivityPrayerTimeData]
        let previousPrayerTime: Date?

        var progress: Double {
            guard let prevTime = previousPrayerTime else { return 0.5 }
            let now = Date()
            let totalInterval = nextPrayerTime.timeIntervalSince(prevTime)
            let elapsed = now.timeIntervalSince(prevTime)
            guard totalInterval > 0 else { return 0 }
            return min(max(elapsed / totalInterval, 0), 1)
        }
    }

    let activityName: String
}

struct LiveActivityPrayerTime: Codable, Hashable, Identifiable {
    var id: String { name }
    let name: String
    let time: Date

    // Helper to convert to SharedPrayerTime
    var asShared: SharedPrayerTime {
        SharedPrayerTime(name: name, time: time)
    }
}

typealias LiveActivityPrayerTimeData = LiveActivityPrayerTime

// MARK: - Preview Data

extension PrayerEaseWidgetAttributes {
    static var preview: PrayerEaseWidgetAttributes {
        PrayerEaseWidgetAttributes(activityName: "Prayer Tracker")
    }
}

extension PrayerEaseWidgetAttributes.ContentState {
    static var previewFajr: PrayerEaseWidgetAttributes.ContentState {
        let now = Date()
        let calendar = Calendar.current

        return PrayerEaseWidgetAttributes.ContentState(
            nextPrayerName: "Fajr",
            nextPrayerTime: calendar.date(bySettingHour: 6, minute: 3, second: 0, of: now)!,
            locationName: "Richmond",
            islamicDate: "29 Jumada-Al-Thani, 1447",
            allPrayerTimes: [
                LiveActivityPrayerTimeData(
                    name: "Fajr",
                    time: calendar.date(bySettingHour: 6, minute: 3, second: 0, of: now)!),
                LiveActivityPrayerTimeData(
                    name: "Sunrise",
                    time: calendar.date(bySettingHour: 7, minute: 13, second: 0, of: now)!),
                LiveActivityPrayerTimeData(
                    name: "Dhuhr",
                    time: calendar.date(bySettingHour: 12, minute: 21, second: 0, of: now)!),
                LiveActivityPrayerTimeData(
                    name: "Asr",
                    time: calendar.date(bySettingHour: 15, minute: 10, second: 0, of: now)!),
                LiveActivityPrayerTimeData(
                    name: "Maghrib",
                    time: calendar.date(bySettingHour: 17, minute: 28, second: 0, of: now)!),
                LiveActivityPrayerTimeData(
                    name: "Isha",
                    time: calendar.date(bySettingHour: 18, minute: 39, second: 0, of: now)!),
            ],
            previousPrayerTime: calendar.date(byAdding: .hour, value: -2, to: now)
        )
    }
}
