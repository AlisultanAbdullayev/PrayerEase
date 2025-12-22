//
//  WidgetDataManager.swift
//  PrayerEase
//
//  Created by Alisultan Abdullah on 12/21/25.
//

import ActivityKit
import Adhan
import Foundation
import WidgetKit

/// Manages data synchronization between the main app and widgets
@MainActor
final class WidgetDataManager: ObservableObject, Sendable {
    static let shared = WidgetDataManager()

    private let storage = PrayerDataStorage.shared

    @Published var isLiveActivityEnabled: Bool {
        didSet {
            storage.setLiveActivityEnabled(isLiveActivityEnabled)
        }
    }

    @Published var isTahajjudEnabled: Bool {
        didSet {
            storage.setTahajjudEnabled(isTahajjudEnabled)
        }
    }

    @Published var isDuhaEnabled: Bool {
        didSet {
            storage.setDuhaEnabled(isDuhaEnabled)
        }
    }

    var isLiveActivityRunning: Bool {
        currentActivity != nil
    }

    private init() {
        self.isLiveActivityEnabled = PrayerDataStorage.shared.isLiveActivityEnabled()
        self.isTahajjudEnabled = PrayerDataStorage.shared.isTahajjudEnabled()
        self.isDuhaEnabled = PrayerDataStorage.shared.isDuhaEnabled()

        // Resume monitoring existing activity if present
        if let existingActivity = Activity<PrayerEaseWidgetAttributes>.activities.first {
            self.currentActivity = existingActivity
            monitorActivityState(for: existingActivity)
        }
    }

    private func monitorActivityState(for activity: Activity<PrayerEaseWidgetAttributes>) {
        Task {
            for await state in activity.activityStateUpdates {
                if state == .dismissed || state == .ended {
                    await MainActor.run {
                        self.isLiveActivityEnabled = false
                        if self.currentActivity?.id == activity.id {
                            self.currentActivity = nil
                        }
                    }
                }
            }
        }
    }

    // MARK: - Widget Data Sync

    private var lastUpdateParams: (prayerTimes: [SharedPrayerTime], location: String, date: String)?

    /// Updates widget data with current prayer times
    func updateWidgetData(
        prayerTimes: PrayerTimes,
        locationName: String,
        islamicDate: String
    ) {
        // Convert prayer times to shared format
        let sharedPrayerTimes = createSharedPrayerTimes(from: prayerTimes)

        // Deduplication check
        if let last = lastUpdateParams,
            last.prayerTimes == sharedPrayerTimes,
            last.location == locationName,
            last.date == islamicDate
        {
            print("DEBUG Widget: Skipping redundant data update")
            return
        }

        // Update cache
        lastUpdateParams = (sharedPrayerTimes, locationName, islamicDate)

        // Find next prayer
        let now = Date()
        let nextPrayerInfo = findNextPrayer(prayerTimes: prayerTimes, from: now)
        let nextPrayer = SharedPrayerTime(name: nextPrayerInfo.name, time: nextPrayerInfo.time)

        // Save using storage service
        storage.saveWidgetData(
            prayerTimes: sharedPrayerTimes,
            locationName: locationName,
            islamicDate: islamicDate,
            nextPrayer: nextPrayer
        )

        print("DEBUG Widget: Data stored - Location: '\(locationName)', Next: \(nextPrayer.name)")

        // Reload all widget timelines
        WidgetCenter.shared.reloadAllTimelines()
        print("DEBUG Widget: Requested timeline reload")
    }

    /// Creates widget-compatible prayer time data
    private func createSharedPrayerTimes(from prayerTimes: PrayerTimes) -> [SharedPrayerTime] {
        [
            SharedPrayerTime(name: "Fajr", time: prayerTimes.fajr),
            SharedPrayerTime(name: "Sunrise", time: prayerTimes.sunrise),
            SharedPrayerTime(name: "Dhuhr", time: prayerTimes.dhuhr),
            SharedPrayerTime(name: "Asr", time: prayerTimes.asr),
            SharedPrayerTime(name: "Maghrib", time: prayerTimes.maghrib),
            SharedPrayerTime(name: "Isha", time: prayerTimes.isha),
        ]
    }

    private func findNextPrayer(prayerTimes: PrayerTimes, from date: Date) -> (
        name: String, time: Date, iconName: String
    ) {
        if let next = prayerTimes.nextPrayer(at: date) {
            let time = prayerTimes.time(for: next)
            return (next.name, time, iconName(for: next))
        }

        // Return tomorrow's Fajr if no prayer remaining today
        let tomorrow =
            Calendar.current.date(byAdding: .day, value: 1, to: prayerTimes.fajr)
            ?? prayerTimes.fajr
        return ("Fajr", tomorrow, "circle.lefthalf.filled")
    }

    private func iconName(for prayer: Prayer) -> String {
        switch prayer {
        case .fajr: return "circle.lefthalf.filled"
        case .sunrise: return "sunrise.fill"
        case .dhuhr: return "sun.max.fill"
        case .asr: return "sun.haze.fill"
        case .maghrib: return "sunset.fill"
        case .isha: return "moon.stars.fill"
        }
    }

    // MARK: - Live Activity Management

    private var currentActivity: Activity<PrayerEaseWidgetAttributes>? = nil

    /// Starts a Live Activity for prayer countdown
    func startLiveActivity(
        prayerTimes: PrayerTimes,
        locationName: String,
        islamicDate: String
    ) async {
        let authInfo = ActivityAuthorizationInfo()

        guard authInfo.areActivitiesEnabled else {
            print("Live Activities are not enabled by the user")
            return
        }

        // End any existing activity first
        await endLiveActivity()

        let now = Date()

        // Get next prayer and previous prayer
        let nextPrayerName: String
        let nextPrayerTime: Date
        let previousPrayerTime: Date?

        if let next = prayerTimes.nextPrayer(at: now) {
            nextPrayerName = next.name
            nextPrayerTime = prayerTimes.time(for: next)
            previousPrayerTime = findPreviousPrayerTime(prayerTimes: prayerTimes, before: next)
        } else {
            // All prayers passed, use tomorrow's Fajr
            nextPrayerName = "Fajr"
            nextPrayerTime =
                Calendar.current.date(byAdding: .day, value: 1, to: prayerTimes.fajr)
                ?? prayerTimes.fajr
            previousPrayerTime = prayerTimes.isha
        }

        let attributes = PrayerEaseWidgetAttributes(activityName: "Prayer Countdown")

        let contentState = PrayerEaseWidgetAttributes.ContentState(
            nextPrayerName: nextPrayerName,
            nextPrayerTime: nextPrayerTime,
            locationName: locationName,
            islamicDate: islamicDate,
            allPrayerTimes: createLiveActivityPrayerTimes(from: prayerTimes),
            previousPrayerTime: previousPrayerTime
        )

        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: contentState, staleDate: nil),
                pushType: nil
            )
            currentActivity = activity
            monitorActivityState(for: activity)
            print("Live Activity started successfully for \(nextPrayerName)")
        } catch {
            print("Failed to start Live Activity: \(error)")
        }
    }

    /// Updates the current Live Activity with new prayer data
    func updateLiveActivity(
        prayerTimes: PrayerTimes,
        locationName: String,
        islamicDate: String
    ) async {
        guard let activity = currentActivity else {
            await startLiveActivity(
                prayerTimes: prayerTimes, locationName: locationName, islamicDate: islamicDate)
            return
        }

        let now = Date()

        // Get next prayer and previous prayer
        let nextPrayerName: String
        let nextPrayerTime: Date
        let previousPrayerTime: Date?

        if let next = prayerTimes.nextPrayer(at: now) {
            nextPrayerName = next.name
            nextPrayerTime = prayerTimes.time(for: next)
            previousPrayerTime = findPreviousPrayerTime(prayerTimes: prayerTimes, before: next)
        } else {
            // All prayers passed, use tomorrow's Fajr
            nextPrayerName = "Fajr"
            nextPrayerTime =
                Calendar.current.date(byAdding: .day, value: 1, to: prayerTimes.fajr)
                ?? prayerTimes.fajr
            previousPrayerTime = prayerTimes.isha
        }

        let contentState = PrayerEaseWidgetAttributes.ContentState(
            nextPrayerName: nextPrayerName,
            nextPrayerTime: nextPrayerTime,
            locationName: locationName,
            islamicDate: islamicDate,
            allPrayerTimes: createLiveActivityPrayerTimes(from: prayerTimes),
            previousPrayerTime: previousPrayerTime
        )

        await activity.update(.init(state: contentState, staleDate: nil))
    }

    /// Finds the time of the prayer before the given prayer
    private func findPreviousPrayerTime(prayerTimes: PrayerTimes, before prayer: Prayer) -> Date? {
        switch prayer {
        case .fajr:
            // Use yesterday's Isha to ensure continuity
            // Approximating as Today's Isha - 24 hours is robust
            return Calendar.current.date(byAdding: .day, value: -1, to: prayerTimes.isha)
        case .sunrise:
            return prayerTimes.fajr
        case .dhuhr:
            return prayerTimes.sunrise
        case .asr:
            return prayerTimes.dhuhr
        case .maghrib:
            return prayerTimes.asr
        case .isha:
            return prayerTimes.maghrib
        }
    }

    /// Ends the current Live Activity
    func endLiveActivity() async {
        guard let activity = currentActivity else { return }
        await activity.end(nil, dismissalPolicy: .immediate)
        currentActivity = nil
    }

    private func createLiveActivityPrayerTimes(from prayerTimes: PrayerTimes)
        -> [LiveActivityPrayerTimeData]
    {
        [
            LiveActivityPrayerTimeData(name: "Fajr", time: prayerTimes.fajr),
            LiveActivityPrayerTimeData(name: "Sunrise", time: prayerTimes.sunrise),
            LiveActivityPrayerTimeData(name: "Dhuhr", time: prayerTimes.dhuhr),
            LiveActivityPrayerTimeData(name: "Asr", time: prayerTimes.asr),
            LiveActivityPrayerTimeData(name: "Maghrib", time: prayerTimes.maghrib),
            LiveActivityPrayerTimeData(name: "Isha", time: prayerTimes.isha),
        ]
    }
}
