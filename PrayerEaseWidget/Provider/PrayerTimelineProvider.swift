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
                name: "Fajr", time: calendar.date(bySettingHour: 6, minute: 3, second: 0, of: now)!),
            WidgetPrayerTime(
                name: "Sunrise",
                time: calendar.date(bySettingHour: 7, minute: 13, second: 0, of: now)!),
            WidgetPrayerTime(
                name: "Dhuhr",
                time: calendar.date(bySettingHour: 12, minute: 21, second: 0, of: now)!),
            WidgetPrayerTime(
                name: "Asr", time: calendar.date(bySettingHour: 15, minute: 10, second: 0, of: now)!
            ),
            WidgetPrayerTime(
                name: "Maghrib",
                time: calendar.date(bySettingHour: 17, minute: 28, second: 0, of: now)!),
            WidgetPrayerTime(
                name: "Isha",
                time: calendar.date(bySettingHour: 18, minute: 39, second: 0, of: now)!),
        ]
        return PrayerWidgetEntry(
            date: now,
            nextPrayerName: "Isha",
            nextPrayerTime: prayerTimes[5].time,
            currentPrayerName: "Maghrib",
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
    private let storage = PrayerDataStorage.shared

    func placeholder(in context: Context) -> PrayerWidgetEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (PrayerWidgetEntry) -> Void) {
        completion(loadEntry(for: Date()))
    }

    func getTimeline(
        in context: Context, completion: @escaping (Timeline<PrayerWidgetEntry>) -> Void
    ) {
        let now = Date()
        var entries: [PrayerWidgetEntry] = []

        // Load initial data
        let loadedPrayers = loadPrayerTimes(for: now)
        let (_, nextTime) = findNextPrayer(from: now, prayerTimes: loadedPrayers)

        // Determine refresh policy
        // If next prayer is within 60 minutes, update every minute to show accurate countdown
        let timeToNext = nextTime.timeIntervalSince(now)
        let isClose = timeToNext > 0 && timeToNext <= 3600

        // Generate entries
        // If close: generate every minute for the next hour
        // If not close: generate every 15 minutes

        let interval: TimeInterval = isClose ? 60 : 15 * 60
        let entryCount = isClose ? 60 : 16  // 1 hour worth or 4 hours worth

        for i in 0..<entryCount {
            let entryDate = now.addingTimeInterval(TimeInterval(i) * interval)
            entries.append(loadEntry(for: entryDate))
        }

        // Add specific trigger for exact prayer time
        if nextTime > now {
            entries.append(loadEntry(for: nextTime))
            // And 1 minute after to switch to "Now" or next state
            entries.append(loadEntry(for: nextTime.addingTimeInterval(60)))
        }

        // Sort and deduplicate
        entries.sort { $0.date < $1.date }

        // Refresh policy:
        // If close, refresh after the last minute entry (~1 hour)
        // If far, refresh after 15 mins (standard) or when next prayer gets close (1h mark)
        var refreshDate = now.addingTimeInterval(isClose ? 3600 : 15 * 60)

        // If we are far, but the 1 hour mark comes before the standard refresh, strictly refresh then
        if !isClose {
            let oneHourMark = nextTime.addingTimeInterval(-3600)
            if oneHourMark > now && oneHourMark < refreshDate {
                refreshDate = oneHourMark
            }
        }

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
        return sorted.first?.time.addingTimeInterval(-3600)
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

        return ("Fajr", date)
    }

    private func findCurrentPrayer(from date: Date, prayerTimes: [WidgetPrayerTime]) -> (
        name: String, time: Date
    ) {
        if let current = prayerTimes.last(where: { $0.time <= date }) {
            return (current.name, current.time)
        }

        if let isha = prayerTimes.last(where: { $0.name == "Isha" }),
            let prevIsha = Calendar.current.date(byAdding: .day, value: -1, to: isha.time)
        {
            return ("Isha", prevIsha)
        }

        return ("Isha", date)
    }

    private static func mockPrayerTimes(for date: Date) -> [WidgetPrayerTime] {
        let calendar = Calendar.current
        return [
            WidgetPrayerTime(
                name: "Fajr", time: calendar.date(bySettingHour: 6, minute: 3, second: 0, of: date)!
            ),
            WidgetPrayerTime(
                name: "Sunrise",
                time: calendar.date(bySettingHour: 7, minute: 13, second: 0, of: date)!),
            WidgetPrayerTime(
                name: "Dhuhr",
                time: calendar.date(bySettingHour: 12, minute: 21, second: 0, of: date)!),
            WidgetPrayerTime(
                name: "Asr",
                time: calendar.date(bySettingHour: 15, minute: 10, second: 0, of: date)!),
            WidgetPrayerTime(
                name: "Maghrib",
                time: calendar.date(bySettingHour: 17, minute: 28, second: 0, of: date)!),
            WidgetPrayerTime(
                name: "Isha",
                time: calendar.date(bySettingHour: 18, minute: 39, second: 0, of: date)!),
        ]
    }
}
