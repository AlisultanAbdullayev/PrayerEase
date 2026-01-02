//
//  NotificationManager.swift
//  PrayerEase
//
//  Created by Alisultan Abdullah on 10/30/24.
//
//  NOTE: This file should ONLY be included in the main app target, NOT in widget extensions.
//

import Adhan
import BackgroundTasks
import CoreLocation
import Foundation
import MapKit
import UserNotifications

@MainActor
@Observable
final class NotificationManager {
    static let shared = NotificationManager()

    private let prayerTimeManager = PrayerTimeManager.shared
    private let notificationCenter = UNUserNotificationCenter.current()
    private let userDefaults = UserDefaults.standard

    let minuteOptions: [Int] = [10, 15, 20, 25, 30, 45, 60]

    var notificationSettings: [String: Bool] {
        didSet {
            userDefaults.set(notificationSettings, forKey: StorageKeys.notifications)
            syncNotifications()
        }
    }

    var notificationSettingsBefore: [String: Bool] {
        didSet {
            userDefaults.set(notificationSettingsBefore, forKey: StorageKeys.notificationsBefore)
            syncNotifications()
        }
    }

    var beforeMinutes: Int = DefaultValues.defaultBeforeMinutes {
        didSet {
            userDefaults.set(beforeMinutes, forKey: StorageKeys.beforeMinutes)
            syncNotifications()
        }
    }

    private var currentLocation: CLLocation?
    private var lastScheduledLocation: CLLocation?

    private init() {
        self.notificationSettings =
            userDefaults.dictionary(forKey: StorageKeys.notifications) as? [String: Bool] ?? [
                PrayerNames.fajr: true, PrayerNames.sunrise: false, PrayerNames.dhuhr: true,
                PrayerNames.asr: true, PrayerNames.maghrib: true, PrayerNames.isha: true,
            ]
        self.notificationSettingsBefore =
            userDefaults.dictionary(forKey: StorageKeys.notificationsBefore) as? [String: Bool] ?? [
                PrayerNames.fajr: false, PrayerNames.sunrise: false, PrayerNames.dhuhr: false,
                PrayerNames.asr: false, PrayerNames.maghrib: false, PrayerNames.isha: false,
            ]
        let savedMinutes = userDefaults.integer(forKey: StorageKeys.beforeMinutes)
        if minuteOptions.contains(savedMinutes) {
            self.beforeMinutes = savedMinutes
        } else {
            self.beforeMinutes = DefaultValues.defaultBeforeMinutes
        }

        registerBackgroundTask()
    }

    func updateLocation(_ location: CLLocation) {
        self.currentLocation = location
        prayerTimeManager.updateLocation(location)

        if let lastLocation = lastScheduledLocation {
            let distance = location.distance(from: lastLocation)
            if distance > DefaultValues.locationChangeThreshold {
                syncNotifications()
            }
        } else {
            syncNotifications()
        }
    }

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [
                .alert, .sound,
            ])
            print("Notification authorization \(granted ? "granted" : "denied")")
            if granted {
                syncNotifications()
            }
            return granted
        } catch {
            print("Error requesting notification authorization: \(error.localizedDescription)")
            return false
        }
    }

    private func registerBackgroundTask() {
        _ = BGTaskScheduler.shared.register(
            forTaskWithIdentifier: AppConfig.backgroundTaskId, using: nil
        ) { [weak self] task in
            guard let appRefreshTask = task as? BGAppRefreshTask else { return }
            Task { @MainActor [weak self] in
                await self?.handleAppRefresh(task: appRefreshTask)
            }
        }
    }

    private func scheduleBackgroundRefresh() {
        let request = BGAppRefreshTaskRequest(
            identifier: AppConfig.backgroundTaskId)
        request.earliestBeginDate = Date(timeIntervalSinceNow: TimeIntervals.twelveHours)

        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Could not schedule app refresh: \(error)")
        }
    }

    private func handleAppRefresh(task: BGAppRefreshTask) async {
        scheduleBackgroundRefresh()

        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }

        syncNotifications()
        task.setTaskCompleted(success: true)
    }

    func syncNotifications() {
        guard currentLocation != nil else {
            // Location not yet available (normal on first launch)
            return
        }

        notificationCenter.removeAllPendingNotificationRequests()

        let calendar = Calendar.current
        let today = Date()

        for dayOffset in 0..<3 {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: today),
                let prayerTimes = prayerTimeManager.getPrayerTimes(for: date)
            else { continue }

            scheduleDailyNotifications(for: prayerTimes)

            if dayOffset == 0 {
                updateWidgetSharedData(prayerTimes: prayerTimes)
            }
        }

        scheduleBackgroundRefresh()
        self.lastScheduledLocation = currentLocation
        print("syncNotifications complete: Rolling 3-day schedule updated.")
    }

    private func scheduleDailyNotifications(for prayerTimes: PrayerTimes) {
        var prayerTimesToNotify = [
            (PrayerNames.fajr, prayerTimes.fajr),
            (PrayerNames.sunrise, prayerTimes.sunrise),
            (PrayerNames.dhuhr, prayerTimes.dhuhr),
            (PrayerNames.asr, prayerTimes.asr),
            (PrayerNames.maghrib, prayerTimes.maghrib),
            (PrayerNames.isha, prayerTimes.isha),
        ]

        let storage = SharedPrayerDataStorage.shared

        if storage.isDuhaEnabled() {
            let duhaTime = PrayerTimeCalculator.duhaTime(from: prayerTimes.sunrise)
            prayerTimesToNotify.append((PrayerNames.duha, duhaTime))
        }

        if storage.isTahajjudEnabled() {
            let fajrTomorrow = prayerTimes.fajr.addingTimeInterval(TimeIntervals.oneDay)
            let tahajjudTime = PrayerTimeCalculator.tahajjudTime(
                maghrib: prayerTimes.maghrib,
                fajrTomorrow: fajrTomorrow
            )
            prayerTimesToNotify.append((PrayerNames.tahajjud, tahajjudTime))
        }

        if notificationSettings["QiraaAfterSunrise"] == true {
            prayerTimesToNotify.append(
                (
                    "Qiraa Ends (Sunrise)",
                    prayerTimes.sunrise.addingTimeInterval(TimeIntervals.duhaOffsetFromSunrise)
                ))
        }

        if notificationSettings["QiraaBeforeDhuhr"] == true {
            prayerTimesToNotify.append(
                (
                    "Qiraa Starts (Dhuhr)",
                    prayerTimes.dhuhr.addingTimeInterval(-TimeIntervals.duhaOffsetFromSunrise)
                ))
        }

        if notificationSettings["QiraaBeforeMaghrib"] == true {
            prayerTimesToNotify.append(
                (
                    "Qiraa Starts (Maghrib)",
                    prayerTimes.maghrib.addingTimeInterval(-TimeIntervals.duhaOffsetFromSunrise)
                ))
        }

        for (prayerName, prayerTime) in prayerTimesToNotify {
            var shouldNotify = notificationSettings[prayerName] == true

            if prayerName == PrayerNames.tahajjud || prayerName == PrayerNames.duha
                || prayerName.starts(with: "Qiraa")
            {
                shouldNotify = true
            }

            if shouldNotify {
                scheduleNotification(for: prayerTime, with: prayerName, type: .exact)
            }

            if notificationSettingsBefore[prayerName] == true {
                scheduleNotification(
                    for: prayerTime, with: prayerName, type: .early(minutes: beforeMinutes))
            }
        }
    }

    private enum NotificationType {
        case exact
        case early(minutes: Int)
    }

    private func scheduleNotification(
        for prayerTime: Date, with prayerName: String, type: NotificationType
    ) {
        guard let validDate = prayerTime.addingTimeInterval(0) as Date? else { return }

        if validDate < Date() && isExact(type) { return }

        let content = UNMutableNotificationContent()
        content.sound = .default

        var triggerDate = validDate
        var identifierSuffix = ""

        switch type {
        case .exact:
            if prayerName.starts(with: "Qiraa") {
                content.title = "Qiraat Time"
                if prayerName.contains("Ends") {
                    content.body = "Forbidden prayer time has ended."
                } else {
                    content.body = "Forbidden prayer time has started."
                }
            } else {
                content.title = "Salah Time"
                content.body = "It's time for \(prayerName)"
            }
            identifierSuffix = "exact"

        case .early(let minutes):
            triggerDate = validDate.addingTimeInterval(TimeInterval(-minutes * 60))
            if triggerDate < Date() { return }

            content.title = "Approaching Prayer"
            content.body = "\(minutes) minutes left until \(prayerName)"
            identifierSuffix = "early"
        }

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: validDate)

        let identifier = "\(prayerName)-\(dateString)-\(identifierSuffix)"

        let request = UNNotificationRequest(
            identifier: identifier, content: content, trigger: trigger)

        notificationCenter.add(request) { error in
            if let error = error {
                print("Error scheduling \(identifier): \(error.localizedDescription)")
            }
        }
    }

    private func isExact(_ type: NotificationType) -> Bool {
        if case .exact = type { return true }
        return false
    }

    func updateNotificationSettings(
        for prayerName: String, sendNotification: Bool, isBefore: Bool = false
    ) {
        if isBefore {
            notificationSettingsBefore[prayerName] = sendNotification
        } else {
            notificationSettings[prayerName] = sendNotification
        }
    }

    func disableAllNotifications() {
        for key in notificationSettings.keys {
            notificationSettings[key] = false
        }
        for key in notificationSettingsBefore.keys {
            notificationSettingsBefore[key] = false
        }
    }

    // MARK: - Widget Shared Data Helper

    private func updateWidgetSharedData(prayerTimes: PrayerTimes) {
        let locationName =
            UserDefaults(suiteName: AppConfig.appGroupId)?.string(
                forKey: StorageKeys.locationName)
            ?? ""

        let islamicCalendar = Calendar(identifier: .islamicUmmAlQura)
        let islamicDateFormatter = DateFormatter()
        islamicDateFormatter.calendar = islamicCalendar
        islamicDateFormatter.dateStyle = .medium
        islamicDateFormatter.timeStyle = .none
        let islamicDateString = islamicDateFormatter.string(from: Date())

        WidgetDataManager.shared.updateWidgetData(
            prayerTimes: prayerTimes,
            locationName: locationName,
            islamicDate: islamicDateString
        )
    }
}
