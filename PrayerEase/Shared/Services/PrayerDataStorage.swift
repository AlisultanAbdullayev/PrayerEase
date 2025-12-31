//
//  PrayerDataStorage.swift
//  PrayerEase
//
//  Created by Alisultan Abdullah on 12/21/25.
//

import Foundation

/// Handles data persistence for the App Group to share data between App and Widget
struct PrayerDataStorage {
    static let shared = PrayerDataStorage()

    private let appGroupId = AppConstants.appGroupId
    private var userDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupId)
    }

    private enum Keys {
        static let widgetPrayerTimes = "widgetPrayerTimes"
        static let locationName = "locationName"
        static let islamicDate = "islamicDate"
        static let nextPrayerName = "nextPrayerName"
        static let nextPrayerTime = "nextPrayerTime"
        static let nextPrayerIconName = "nextPrayerIconName"
        static let isLiveActivityEnabled = "isLiveActivityEnabled"
    }

    // MARK: - Writing

    func saveWidgetData(
        prayerTimes: [SharedPrayerTime],
        locationName: String,
        islamicDate: String,
        nextPrayer: SharedPrayerTime
    ) {
        guard let defaults = userDefaults else { return }

        if let encoded = try? JSONEncoder().encode(prayerTimes) {
            defaults.set(encoded, forKey: Keys.widgetPrayerTimes)
        }

        defaults.set(locationName, forKey: Keys.locationName)
        defaults.set(islamicDate, forKey: Keys.islamicDate)
        defaults.set(nextPrayer.name, forKey: Keys.nextPrayerName)
        defaults.set(nextPrayer.time, forKey: Keys.nextPrayerTime)
        defaults.set(nextPrayer.iconName, forKey: Keys.nextPrayerIconName)

        defaults.synchronize()
    }

    func isLiveActivityEnabled() -> Bool {
        userDefaults?.bool(forKey: "isLiveActivityEnabled") ?? true
    }

    func setLiveActivityEnabled(_ enabled: Bool) {
        userDefaults?.set(enabled, forKey: "isLiveActivityEnabled")
    }

    // MARK: - Optional Prayers
    func isTahajjudEnabled() -> Bool {
        userDefaults?.bool(forKey: "isTahajjudEnabled") ?? false
    }

    func setTahajjudEnabled(_ enabled: Bool) {
        userDefaults?.set(enabled, forKey: "isTahajjudEnabled")
    }

    func isDuhaEnabled() -> Bool {
        userDefaults?.bool(forKey: "isDuhaEnabled") ?? false
    }

    func setDuhaEnabled(_ enabled: Bool) {
        userDefaults?.set(enabled, forKey: "isDuhaEnabled")
    }

    // MARK: - Reading

    func loadPrayerTimes() -> [SharedPrayerTime]? {
        guard let data = userDefaults?.data(forKey: Keys.widgetPrayerTimes),
            let decoded = try? JSONDecoder().decode([SharedPrayerTime].self, from: data)
        else { return nil }
        return decoded
    }

    func loadLocationName() -> String {
        userDefaults?.string(forKey: Keys.locationName) ?? "Loading..."
    }

    func loadIslamicDate() -> String {
        userDefaults?.string(forKey: Keys.islamicDate) ?? ""
    }

}
