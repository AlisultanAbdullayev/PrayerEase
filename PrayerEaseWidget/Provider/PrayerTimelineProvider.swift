//
//  PrayerTimelineProvider.swift
//  PrayerEaseWidget
//
//  Created by Alisultan Abdullah on 12/21/25.
//

import SwiftUI
import WidgetKit

// MARK: - Data Models

typealias WidgetPrayerTime = SharedPrayerTime

struct PrayerWidgetEntry: TimelineEntry {
    let date: Date
    let nextPrayerName: String
    let nextPrayerTime: Date
    let currentPrayerName: String
    let currentPrayerTime: Date
    let locationName: String
    let prayerTimes: [WidgetPrayerTime]
    let islamicDate: String
    var previousPrayerTime: Date?  // Added for progress calculation

    static var placeholder: PrayerWidgetEntry {
        let now = Date()
        let calendar = Calendar.current
        let prayerTimes = [
            WidgetPrayerTime(
                name: PrayerNames.fajr,
                time: calendar.date(bySettingHour: 6, minute: 3, second: 0, of: now)!),
            WidgetPrayerTime(
                name: PrayerNames.sunrise,
                time: calendar.date(bySettingHour: 7, minute: 13, second: 0, of: now)!),
            WidgetPrayerTime(
                name: PrayerNames.dhuhr,
                time: calendar.date(bySettingHour: 12, minute: 21, second: 0, of: now)!),
            WidgetPrayerTime(
                name: PrayerNames.asr,
                time: calendar.date(bySettingHour: 15, minute: 10, second: 0, of: now)!
            ),
            WidgetPrayerTime(
                name: PrayerNames.maghrib,
                time: calendar.date(bySettingHour: 17, minute: 28, second: 0, of: now)!),
            WidgetPrayerTime(
                name: PrayerNames.isha,
                time: calendar.date(bySettingHour: 18, minute: 39, second: 0, of: now)!),
        ]
        return PrayerWidgetEntry(
            date: now,
            nextPrayerName: PrayerNames.isha,
            nextPrayerTime: prayerTimes[5].time,
            currentPrayerName: PrayerNames.maghrib,
            currentPrayerTime: prayerTimes[4].time,
            locationName: "Richmond",
            prayerTimes: prayerTimes,
            islamicDate: "29 Jumada-Al-Thani, 1447",
            previousPrayerTime: prayerTimes[4].time
        )
    }
}

// MARK: - Timeline Provider

struct PrayerTimelineProvider: TimelineProvider {

    // Use Shared Data Storage
    private let storage = SharedPrayerDataStorage.shared

    func placeholder(in context: Context) -> PrayerWidgetEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (PrayerWidgetEntry) -> Void) {
        // Return placeholder immediately for widget gallery (faster preview)
        if context.isPreview {
            completion(.placeholder)
        } else {
            completion(loadEntry(for: Date()))
        }
    }

    func getTimeline(
        in context: Context, completion: @escaping (Timeline<PrayerWidgetEntry>) -> Void
    ) {
        let now = Date()
        var entries: [PrayerWidgetEntry] = []
        let calendar = Calendar.current

        // Load prayers once for efficiency
        let loadedPrayers = loadPrayerTimes(for: now)

        // Find next prayer to optimize entry generation
        let nextPrayerTime = loadedPrayers.first(where: { $0.time > now })?.time
        let timeToNextPrayer = nextPrayerTime.map { $0.timeIntervalSince(now) } ?? Double.infinity

        // 1. Generate entries based on proximity to next prayer
        if timeToNextPrayer <= TimeIntervals.oneHour {
            // Less than 1 hour: minute-by-minute for accurate countdown
            for minuteOffset in 0..<60 {
                guard let entryDate = calendar.date(byAdding: .minute, value: minuteOffset, to: now)
                else { continue }
                entries.append(loadEntry(for: entryDate))
            }
            // Then every 5 minutes for the remaining 3 hours
            for minuteOffset in stride(from: 60, to: 240, by: 5) {
                guard let entryDate = calendar.date(byAdding: .minute, value: minuteOffset, to: now)
                else { continue }
                entries.append(loadEntry(for: entryDate))
            }
        } else {
            // More than 1 hour: standard 15-min entries (battery efficient)
            for minuteOffset in stride(from: 0, to: 240, by: 15) {
                guard let entryDate = calendar.date(byAdding: .minute, value: minuteOffset, to: now)
                else { continue }
                entries.append(loadEntry(for: entryDate))
            }
        }

        // 2. Critical prayer-time entries (ensure immediate update at prayer times)
        let protectionWindow = now.addingTimeInterval(TimeIntervals.fourHours)

        // Add tomorrow's Fajr candidate
        var candidates = loadedPrayers.filter { $0.time > now }
        if let first = loadedPrayers.first,
            let tomorrowFajr = calendar.date(byAdding: .day, value: 1, to: first.time)
        {
            candidates.append(WidgetPrayerTime(name: first.name, time: tomorrowFajr))
        }

        for prayer in candidates where prayer.time < protectionWindow {
            // T-1h: Switch from "Xh+" to "59 min"
            let tMinus1h = prayer.time.addingTimeInterval(-TimeIntervals.oneHourMinus5Seconds)

            // T-1m: Switch from "X min" to Timer
            let tMinus1m = prayer.time.addingTimeInterval(-TimeIntervals.oneMinute)

            // Exact prayer time: Show next prayer immediately
            let atPrayer = prayer.time

            // 1 second after: Ensure transition
            let afterPrayer = prayer.time.addingTimeInterval(1)

            for trigger in [tMinus1h, tMinus1m, atPrayer, afterPrayer] {
                if trigger > now && trigger < protectionWindow {
                    entries.append(loadEntry(for: trigger))
                }
            }
        }

        // 3. Sort and deduplicate
        entries.sort { $0.date < $1.date }

        // Request refresh sooner when close to prayer time
        let refreshInterval = timeToNextPrayer <= TimeIntervals.oneHour ? 5 : 15
        let refreshDate = calendar.date(byAdding: .minute, value: refreshInterval, to: now) ?? now
        let timeline = Timeline(entries: entries, policy: .after(refreshDate))
        completion(timeline)
    }

    private func loadEntry(for date: Date) -> PrayerWidgetEntry {
        let prayerTimes = loadPrayerTimes(for: date)
        let locationName = storage.loadLocationName()
        let islamicDate = storage.loadIslamicDate()
        let (nextName, nextTime) = findNextPrayer(from: date, prayerTimes: prayerTimes)
        let (currentName, currentTime) = findCurrentPrayer(from: date, prayerTimes: prayerTimes)
        let previousTime = findPreviousPrayerTime(from: date, prayerTimes: prayerTimes)

        return PrayerWidgetEntry(
            date: date,
            nextPrayerName: nextName,
            nextPrayerTime: nextTime,
            currentPrayerName: currentName,
            currentPrayerTime: currentTime,
            locationName: locationName,
            prayerTimes: prayerTimes,
            islamicDate: islamicDateIfAvailable(islamicDate, for: date),
            previousPrayerTime: previousTime
        )
    }

    private func islamicDateIfAvailable(_ storedDate: String, for date: Date) -> String {
        // Simple logic: if stored date is "Loading...", maybe return empty or keep it.
        // For now, trust the stored value which should be fresh from the app.
        if storedDate.isEmpty { return "PrayerEase" }
        return storedDate
    }

    private func loadPrayerTimes(for date: Date) -> [WidgetPrayerTime] {
        guard let decoded = storage.loadPrayerTimes(), !decoded.isEmpty else {
            return Self.mockPrayerTimes(for: date)
        }

        let calendar = Calendar.current
        if let firstTime = decoded.first?.time,
            calendar.isDate(firstTime, inSameDayAs: date)
        {
            return decoded
        }

        return Self.mockPrayerTimes(for: date)
    }

    // Helper to find previous prayer time for progress calculation
    private func findPreviousPrayerTime(from date: Date, prayerTimes: [WidgetPrayerTime]) -> Date? {
        let sorted = prayerTimes.sorted { $0.time < $1.time }
        if let nextIndex = sorted.firstIndex(where: { $0.time > date }) {
            if nextIndex > 0 {
                return sorted[nextIndex - 1].time
            } else {
                // Next is Fajr (index 0), so previous was Isha yesterday.
                // Approx: Tonight's Isha minus 1 day
                if let isha = sorted.last {
                    return Calendar.current.date(byAdding: .day, value: -1, to: isha.time)
                }
            }
        }
        // Fallback for edge cases
        return sorted.first?.time.addingTimeInterval(-TimeIntervals.oneHour)
    }

    private func findNextPrayer(from date: Date, prayerTimes: [WidgetPrayerTime]) -> (
        name: String, time: Date
    ) {
        if let next = prayerTimes.first(where: { $0.time > date }) {
            return (next.name, next.time)
        }

        if let first = prayerTimes.first,
            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: first.time)
        {
            return (first.name, tomorrow)
        }

        return (PrayerNames.fajr, date)
    }

    private func findCurrentPrayer(from date: Date, prayerTimes: [WidgetPrayerTime]) -> (
        name: String, time: Date
    ) {
        if let current = prayerTimes.last(where: { $0.time <= date }) {
            return (current.name, current.time)
        }

        if let isha = prayerTimes.last(where: { $0.name == PrayerNames.isha }),
            let prevIsha = Calendar.current.date(byAdding: .day, value: -1, to: isha.time)
        {
            return (PrayerNames.isha, prevIsha)
        }

        return (PrayerNames.isha, date)
    }

    private static func mockPrayerTimes(for date: Date) -> [WidgetPrayerTime] {
        let calendar = Calendar.current
        return [
            WidgetPrayerTime(
                name: PrayerNames.fajr,
                time: calendar.date(bySettingHour: 6, minute: 3, second: 0, of: date)!
            ),
            WidgetPrayerTime(
                name: PrayerNames.sunrise,
                time: calendar.date(bySettingHour: 7, minute: 13, second: 0, of: date)!),
            WidgetPrayerTime(
                name: PrayerNames.dhuhr,
                time: calendar.date(bySettingHour: 12, minute: 21, second: 0, of: date)!),
            WidgetPrayerTime(
                name: PrayerNames.asr,
                time: calendar.date(bySettingHour: 15, minute: 10, second: 0, of: date)!),
            WidgetPrayerTime(
                name: PrayerNames.maghrib,
                time: calendar.date(bySettingHour: 17, minute: 28, second: 0, of: date)!),
            WidgetPrayerTime(
                name: PrayerNames.isha,
                time: calendar.date(bySettingHour: 18, minute: 39, second: 0, of: date)!),
        ]
    }
}
