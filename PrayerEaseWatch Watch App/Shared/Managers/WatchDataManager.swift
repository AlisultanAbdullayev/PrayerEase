//
//  WatchDataManager.swift
//  PrayerEaseWatch Watch App
//
//  Created by Antigravity on 12/23/25.
//

import Foundation
import WidgetKit

/// Manages prayer data synchronization between iOS app and watchOS app via App Group
@MainActor
@Observable
final class WatchDataManager {
    static let shared = WatchDataManager()

    private let appGroupId = "group.com.alijaver.PrayerEase"

    private var userDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupId)
    }

    // MARK: - Properties

    var prayerTimes: [SharedPrayerTime] = []
    var locationName: String = ""
    var islamicDate: String = ""
    var isDuhaEnabled: Bool = false
    var isTahajjudEnabled: Bool = false

    // MARK: - Initialization

    private init() {
        loadPrayerData()
    }

    // MARK: - Data Loading

    func loadPrayerData() {
        guard let defaults = userDefaults else {
            print("DEBUG Watch: Failed to access App Group UserDefaults")
            return
        }

        if let data = defaults.data(forKey: "widgetPrayerTimes"),
            let decoded = try? JSONDecoder().decode([SharedPrayerTime].self, from: data)
        {
            self.prayerTimes = decoded
            print("DEBUG Watch: Loaded \(decoded.count) prayer times")
        } else {
            print("DEBUG Watch: No prayer times data found in App Group")
        }

        self.locationName = defaults.string(forKey: "locationName") ?? "Loading..."
        self.islamicDate = defaults.string(forKey: "islamicDate") ?? ""

        self.isDuhaEnabled = defaults.bool(forKey: "isDuhaEnabled")
        self.isTahajjudEnabled = defaults.bool(forKey: "isTahajjudEnabled")

        print("DEBUG Watch: Location: \(locationName), Islamic Date: \(islamicDate)")
        print("DEBUG Watch: Duha: \(isDuhaEnabled), Tahajjud: \(isTahajjudEnabled)")
    }

    func refresh() {
        loadPrayerData()
    }

    func updateFromContext(
        prayerTimes: [SharedPrayerTime],
        locationName: String,
        islamicDate: String,
        isDuhaEnabled: Bool,
        isTahajjudEnabled: Bool
    ) {
        self.prayerTimes = prayerTimes
        self.locationName = locationName
        self.islamicDate = islamicDate
        self.isDuhaEnabled = isDuhaEnabled
        self.isTahajjudEnabled = isTahajjudEnabled

        persistDataForWidget()

        print(
            "DEBUG Watch: Updated from context - \(prayerTimes.count) prayers for \(locationName)")
    }

    private func persistDataForWidget() {
        guard let defaults = UserDefaults(suiteName: appGroupId) else {
            print("DEBUG Watch: Failed to access App Group for widget persistence")
            return
        }

        if let encoded = try? JSONEncoder().encode(prayerTimes) {
            defaults.set(encoded, forKey: "widgetPrayerTimes")
        }

        defaults.set(locationName, forKey: "locationName")
        defaults.set(islamicDate, forKey: "islamicDate")
        defaults.set(isDuhaEnabled, forKey: "isDuhaEnabled")
        defaults.set(isTahajjudEnabled, forKey: "isTahajjudEnabled")

        reloadWidgetTimelines()

        print("DEBUG Watch: Persisted data for widget to App Group")
    }

    private func reloadWidgetTimelines() {
        WidgetCenter.shared.reloadAllTimelines()
    }

    var currentPrayer: SharedPrayerTime? {
        let now = Date()

        for i in 0..<prayerTimes.count {
            let current = prayerTimes[i]

            if i < prayerTimes.count - 1 {
                let next = prayerTimes[i + 1]
                if now >= current.time && now < next.time {
                    return current
                }
            } else {
                if now >= current.time {
                    return current
                }
            }
        }

        return prayerTimes.last
    }

    var nextPrayer: SharedPrayerTime? {
        let now = Date()

        if let next = prayerTimes.first(where: { $0.time > now }) {
            return next
        }

        guard let fajr = prayerTimes.first(where: { $0.name == "Fajr" }) ?? prayerTimes.first else {
            return nil
        }

        let nextFajrTime = Self.projectToFuture(fajr.time, from: now)
        return SharedPrayerTime(name: fajr.name, time: nextFajrTime)
    }

    private static func projectToFuture(_ date: Date, from referenceDate: Date) -> Date {
        guard date <= referenceDate else { return date }

        let calendar = Calendar.current
        let daysDifference = calendar.dateComponents([.day], from: date, to: referenceDate).day ?? 0
        let daysToAdd = daysDifference + 1

        return calendar.date(byAdding: .day, value: daysToAdd, to: date)
            ?? date.addingTimeInterval(Double(daysToAdd) * 86400)
    }

    var optionalPrayers: [SharedPrayerTime] {
        var prayers: [SharedPrayerTime] = []

        guard !prayerTimes.isEmpty else { return [] }

        if isDuhaEnabled, let sunrise = prayerTimes.first(where: { $0.name == "Sunrise" }) {
            let duhaTime = sunrise.time.addingTimeInterval(45 * 60)
            prayers.append(SharedPrayerTime(name: "Duha", time: duhaTime))
        }

        if isTahajjudEnabled,
            let fajr = prayerTimes.first(where: { $0.name == "Fajr" }),
            let maghrib = prayerTimes.first(where: { $0.name == "Maghrib" })
        {

            let fajrTomorrow = fajr.time.addingTimeInterval(86400)
            let nightDuration = fajrTomorrow.timeIntervalSince(maghrib.time)
            let lastThird = nightDuration / 3
            let tahajjudTime = fajrTomorrow.addingTimeInterval(-lastThird)

            prayers.append(SharedPrayerTime(name: "Tahajjud", time: tahajjudTime))
        }

        return prayers.sorted { $0.time < $1.time }
    }

    func isCurrent(prayer: SharedPrayerTime) -> Bool {
        return currentPrayer?.name == prayer.name
    }
}
