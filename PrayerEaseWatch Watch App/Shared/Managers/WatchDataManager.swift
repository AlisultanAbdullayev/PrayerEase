//
//  WatchDataManager.swift
//  PrayerEaseWatch Watch App
//
//  Created by Antigravity on 12/23/25.
//

import Combine
import Foundation

/// Manages prayer data synchronization between iOS app and watchOS app via App Group
@MainActor
final class WatchDataManager: ObservableObject {
    static let shared = WatchDataManager()

    private let appGroupId = "group.com.alijaver.PrayerEase"

    private var userDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupId)
    }

    // MARK: - Published Properties

    @Published var prayerTimes: [SharedPrayerTime] = []
    @Published var locationName: String = ""
    @Published var islamicDate: String = ""
    @Published var isDuhaEnabled: Bool = false
    @Published var isTahajjudEnabled: Bool = false

    // MARK: - Initialization

    private init() {
        loadPrayerData()
    }

    // MARK: - Data Loading

    /// Loads prayer data from App Group storage
    func loadPrayerData() {
        guard let defaults = userDefaults else {
            print("DEBUG Watch: Failed to access App Group UserDefaults")
            return
        }

        // Load prayer times
        if let data = defaults.data(forKey: "widgetPrayerTimes"),
            let decoded = try? JSONDecoder().decode([SharedPrayerTime].self, from: data)
        {
            self.prayerTimes = decoded
            print("DEBUG Watch: Loaded \(decoded.count) prayer times")
        } else {
            print("DEBUG Watch: No prayer times data found in App Group")
        }

        // Load location and date
        self.locationName = defaults.string(forKey: "locationName") ?? "Loading..."
        self.islamicDate = defaults.string(forKey: "islamicDate") ?? ""

        // Load optional prayer settings
        self.isDuhaEnabled = defaults.bool(forKey: "isDuhaEnabled")
        self.isTahajjudEnabled = defaults.bool(forKey: "isTahajjudEnabled")

        print("DEBUG Watch: Location: \(locationName), Islamic Date: \(islamicDate)")
        print("DEBUG Watch: Duha: \(isDuhaEnabled), Tahajjud: \(isTahajjudEnabled)")
    }

    /// Refreshes prayer data (call when returning from background or on manual refresh)
    func refresh() {
        loadPrayerData()
    }

    /// Updates data from WatchConnectivity application context
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

        print(
            "DEBUG Watch: Updated from context - \(prayerTimes.count) prayers for \(locationName)")
    }

    /// Returns the current prayer based on current time
    var currentPrayer: SharedPrayerTime? {
        let now = Date()

        // Find which prayer slot we're in
        for i in 0..<prayerTimes.count {
            let current = prayerTimes[i]

            // Check if we're in this prayer's time slot
            if i < prayerTimes.count - 1 {
                let next = prayerTimes[i + 1]
                if now >= current.time && now < next.time {
                    return current
                }
            } else {
                // Last prayer (Isha) - active until next Fajr
                if now >= current.time {
                    return current
                }
            }
        }

        // Before Fajr - return last prayer (Isha from previous day)
        return prayerTimes.last
    }

    /// Returns the next upcoming prayer
    var nextPrayer: SharedPrayerTime? {
        let now = Date()

        // Find first prayer after current time
        for prayer in prayerTimes {
            if prayer.time > now {
                return prayer
            }
        }

        // All prayers passed - return first prayer (Fajr for tomorrow)
        return prayerTimes.first
    }

    /// Returns optional prayers based on enabled flags
    var optionalPrayers: [SharedPrayerTime] {
        var prayers: [SharedPrayerTime] = []

        // Only show if standard prayers are loaded
        guard !prayerTimes.isEmpty else { return [] }

        // Duha: 45 minutes after Sunrise
        if isDuhaEnabled, let sunrise = prayerTimes.first(where: { $0.name == "Sunrise" }) {
            let duhaTime = sunrise.time.addingTimeInterval(45 * 60)
            prayers.append(SharedPrayerTime(name: "Duha", time: duhaTime))
        }

        // Tahajjud: Last third of the night (before Fajr)
        if isTahajjudEnabled,
            let fajr = prayerTimes.first(where: { $0.name == "Fajr" }),
            let maghrib = prayerTimes.first(where: { $0.name == "Maghrib" })
        {

            // Calculate tomorrow's Fajr for night duration
            let fajrTomorrow = fajr.time.addingTimeInterval(86400)
            let nightDuration = fajrTomorrow.timeIntervalSince(maghrib.time)
            let lastThird = nightDuration / 3
            let tahajjudTime = fajrTomorrow.addingTimeInterval(-lastThird)

            prayers.append(SharedPrayerTime(name: "Tahajjud", time: tahajjudTime))
        }

        return prayers.sorted { $0.time < $1.time }
    }

    /// Checks if a given prayer is the current prayer
    func isCurrent(prayer: SharedPrayerTime) -> Bool {
        return currentPrayer?.name == prayer.name
    }
}
