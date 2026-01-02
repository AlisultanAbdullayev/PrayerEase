//
//  SharedPrayerDataStorage.swift
//  PrayerEase
//
//  Shared between: iOS App, iOS Widget, Watch App, Watch Widget
//  Add this file to ALL 4 targets in Xcode for code reusability.
//

import Foundation

/// Handles data persistence for the App Group to share data between all targets
struct SharedPrayerDataStorage {
    static let shared = SharedPrayerDataStorage()

    private var userDefaults: UserDefaults? {
        UserDefaults(suiteName: AppConfig.appGroupId)
    }

    // MARK: - Reading (All Targets)

    func loadPrayerTimes() -> [SharedPrayerTime]? {
        guard let data = userDefaults?.data(forKey: StorageKeys.widgetPrayerTimes),
            let decoded = try? JSONDecoder().decode([SharedPrayerTime].self, from: data)
        else { return nil }
        return decoded
    }

    func loadLocationName() -> String {
        userDefaults?.string(forKey: StorageKeys.locationName) ?? "Loading..."
    }

    func loadIslamicDate() -> String {
        userDefaults?.string(forKey: StorageKeys.islamicDate) ?? ""
    }

    func isDuhaEnabled() -> Bool {
        userDefaults?.bool(forKey: StorageKeys.isDuhaEnabled) ?? false
    }

    func isTahajjudEnabled() -> Bool {
        userDefaults?.bool(forKey: StorageKeys.isTahajjudEnabled) ?? false
    }

    func isLiveActivityEnabled() -> Bool {
        userDefaults?.bool(forKey: StorageKeys.isLiveActivityEnabled) ?? true
    }

    // MARK: - Writing (iOS App Primary, but available to all)

    func savePrayerTimes(_ prayerTimes: [SharedPrayerTime]) {
        guard let defaults = userDefaults,
            let encoded = try? JSONEncoder().encode(prayerTimes)
        else { return }
        defaults.set(encoded, forKey: StorageKeys.widgetPrayerTimes)
    }

    func saveLocationName(_ name: String) {
        userDefaults?.set(name, forKey: StorageKeys.locationName)
    }

    func saveIslamicDate(_ date: String) {
        userDefaults?.set(date, forKey: StorageKeys.islamicDate)
    }

    func saveWidgetData(
        prayerTimes: [SharedPrayerTime],
        locationName: String,
        islamicDate: String
    ) {
        savePrayerTimes(prayerTimes)
        saveLocationName(locationName)
        saveIslamicDate(islamicDate)
    }

    /// Overload for WidgetDataManager compatibility
    func saveWidgetData(
        prayerTimes: [SharedPrayerTime],
        locationName: String,
        islamicDate: String,
        nextPrayer: SharedPrayerTime
    ) {
        savePrayerTimes(prayerTimes)
        saveLocationName(locationName)
        saveIslamicDate(islamicDate)
        // nextPrayer info is derived from prayerTimes, no need to store separately
    }

    func setDuhaEnabled(_ enabled: Bool) {
        userDefaults?.set(enabled, forKey: StorageKeys.isDuhaEnabled)
    }

    func setTahajjudEnabled(_ enabled: Bool) {
        userDefaults?.set(enabled, forKey: StorageKeys.isTahajjudEnabled)
    }

    func setLiveActivityEnabled(_ enabled: Bool) {
        userDefaults?.set(enabled, forKey: StorageKeys.isLiveActivityEnabled)
    }

    // MARK: - Helper Methods

    /// Gets the next prayer from loaded prayer times
    func getNextPrayer(from date: Date = Date()) -> SharedPrayerTime? {
        guard let prayerTimes = loadPrayerTimes() else { return nil }
        return prayerTimes.first { $0.time > date }
    }

    /// Gets the current active prayer
    func getCurrentPrayer(from date: Date = Date()) -> SharedPrayerTime? {
        guard let prayerTimes = loadPrayerTimes() else { return nil }

        for i in 0..<prayerTimes.count {
            let current = prayerTimes[i]
            if i < prayerTimes.count - 1 {
                let next = prayerTimes[i + 1]
                if date >= current.time && date < next.time {
                    return current
                }
            } else {
                if date >= current.time {
                    return current
                }
            }
        }
        return prayerTimes.last
    }
}
