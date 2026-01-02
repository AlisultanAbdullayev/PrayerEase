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

    private var userDefaults: UserDefaults? {
        UserDefaults(suiteName: AppConfig.appGroupId)
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

        if let data = defaults.data(forKey: StorageKeys.widgetPrayerTimes),
            let decoded = try? JSONDecoder().decode([SharedPrayerTime].self, from: data)
        {
            self.prayerTimes = decoded
            print("DEBUG Watch: Loaded \(decoded.count) prayer times")
        } else {
            print("DEBUG Watch: No prayer times data found in App Group")
        }

        self.locationName =
            defaults.string(forKey: StorageKeys.locationName) ?? DefaultValues.loadingPlaceholder
        self.islamicDate = defaults.string(forKey: StorageKeys.islamicDate) ?? ""

        self.isDuhaEnabled = defaults.bool(forKey: StorageKeys.isDuhaEnabled)
        self.isTahajjudEnabled = defaults.bool(forKey: StorageKeys.isTahajjudEnabled)

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
        guard let defaults = UserDefaults(suiteName: AppConfig.appGroupId) else {
            print("DEBUG Watch: Failed to access App Group for widget persistence")
            return
        }

        if let encoded = try? JSONEncoder().encode(prayerTimes) {
            defaults.set(encoded, forKey: StorageKeys.widgetPrayerTimes)
        }

        defaults.set(locationName, forKey: StorageKeys.locationName)
        defaults.set(islamicDate, forKey: StorageKeys.islamicDate)
        defaults.set(isDuhaEnabled, forKey: StorageKeys.isDuhaEnabled)
        defaults.set(isTahajjudEnabled, forKey: StorageKeys.isTahajjudEnabled)

        reloadWidgetTimelines()

        print("DEBUG Watch: Persisted data for widget to App Group")
    }

    private func reloadWidgetTimelines() {
        WidgetCenter.shared.reloadAllTimelines()
    }

    var currentPrayer: SharedPrayerTime? {
        PrayerTimeCalculator.currentPrayer(from: prayerTimes)
    }

    var nextPrayer: SharedPrayerTime? {
        let now = Date()

        if let next = prayerTimes.first(where: { $0.time > now }) {
            return next
        }

        guard
            let fajr = prayerTimes.first(where: { $0.name == PrayerNames.fajr })
                ?? prayerTimes.first
        else {
            return nil
        }

        let nextFajrTime = PrayerTimeCalculator.projectToFuture(fajr.time, from: now)
        return SharedPrayerTime(name: fajr.name, time: nextFajrTime)
    }

    // NOTE: projectToFuture moved to PrayerTimeCalculator for reuse across targets

    var optionalPrayers: [SharedPrayerTime] {
        var prayers: [SharedPrayerTime] = []

        guard !prayerTimes.isEmpty else { return [] }

        if isDuhaEnabled, let sunrise = prayerTimes.first(where: { $0.name == PrayerNames.sunrise })
        {
            let duhaTime = PrayerTimeCalculator.duhaTime(from: sunrise.time)
            prayers.append(SharedPrayerTime(name: PrayerNames.duha, time: duhaTime))
        }

        if isTahajjudEnabled,
            let fajr = prayerTimes.first(where: { $0.name == PrayerNames.fajr }),
            let maghrib = prayerTimes.first(where: { $0.name == PrayerNames.maghrib })
        {
            let fajrTomorrow = fajr.time.addingTimeInterval(TimeIntervals.oneDay)
            let tahajjudTime = PrayerTimeCalculator.tahajjudTime(
                maghrib: maghrib.time, fajrTomorrow: fajrTomorrow)

            prayers.append(SharedPrayerTime(name: PrayerNames.tahajjud, time: tahajjudTime))
        }

        return prayers.sorted { $0.time < $1.time }
    }

    func isCurrent(prayer: SharedPrayerTime) -> Bool {
        return currentPrayer?.name == prayer.name
    }
}
