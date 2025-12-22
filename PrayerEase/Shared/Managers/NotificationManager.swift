//
//  NotificationManager.swift
//  PrayerEase
//
//  Created by Alisultan Abdullah on 10/30/24.
//
//  NOTE: This file should ONLY be included in the main app target, NOT in widget extensions.
//  In Xcode, uncheck the widget extension target in this file's Target Membership.
//

import Adhan
import BackgroundTasks
import Combine
import CoreLocation
import Foundation
import MapKit
import UserNotifications

@MainActor
final class NotificationManager: ObservableObject {
    static let shared = NotificationManager()

    private let prayerTimeManager = PrayerTimeManager.shared
    private let notificationCenter = UNUserNotificationCenter.current()
    private let userDefaults = UserDefaults.standard

    let minuteOptions: [Int] = [10, 15, 20, 25, 30, 45, 60]

    @Published var notificationSettings: [String: Bool] {
        didSet {
            userDefaults.set(notificationSettings, forKey: "notifications")
            syncNotifications()
        }
    }
    @Published var notificationSettingsBefore: [String: Bool] {
        didSet {
            userDefaults.set(notificationSettingsBefore, forKey: "notificationsBefore")
            syncNotifications()
        }
    }
    @Published var beforeMinutes: Int = 25 {
        didSet {
            userDefaults.set(beforeMinutes, forKey: "beforeMinutes")
            syncNotifications()
        }
    }

    private var currentLocation: CLLocation?
    private var lastScheduledLocation: CLLocation?

    private init() {
        self.notificationSettings =
            userDefaults.dictionary(forKey: "notifications") as? [String: Bool] ?? [
                "Fajr": true, "Sunrise": false, "Dhuhr": true,
                "Asr": true, "Maghrib": true, "Isha": true,
            ]
        self.notificationSettingsBefore =
            userDefaults.dictionary(forKey: "notificationsBefore") as? [String: Bool] ?? [
                "Fajr": false, "Sunrise": false, "Dhuhr": false,
                "Asr": false, "Maghrib": false, "Isha": false,
            ]
        let savedMinutes = userDefaults.integer(forKey: "beforeMinutes")
        if minuteOptions.contains(savedMinutes) {
            self.beforeMinutes = savedMinutes
        } else {
            self.beforeMinutes = 25
        }

        registerBackgroundTask()
    }

    func updateLocation(_ location: CLLocation) {
        self.currentLocation = location
        prayerTimeManager.updateLocation(location)

        // Only sync if location changed significantly (> 2km) or never scheduled
        if let lastLocation = lastScheduledLocation {
            let distance = location.distance(from: lastLocation)
            if distance > 2000 {
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
            forTaskWithIdentifier: "com.alijaver.SalahTimes.refreshNotifications", using: nil
        ) { [weak self] task in
            guard let appRefreshTask = task as? BGAppRefreshTask else { return }
            Task { @MainActor [weak self] in
                await self?.handleAppRefresh(task: appRefreshTask)
            }
        }
    }

    private func scheduleBackgroundRefresh() {
        let request = BGAppRefreshTaskRequest(
            identifier: "com.alijaver.SalahTimes.refreshNotifications")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 12 * 3600)  // Refresh twice a day roughly

        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Could not schedule app refresh: \(error)")
        }
    }

    private func handleAppRefresh(task: BGAppRefreshTask) async {
        scheduleBackgroundRefresh()  // Schedule next one

        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }

        syncNotifications()
        task.setTaskCompleted(success: true)
    }

    /// The Single Source of Truth for scheduling.
    /// Wipes all pending requests and reschedules everything for the next 3 days.
    func syncNotifications() {
        guard currentLocation != nil else {
            print("Location not available. Cannot schedule notifications.")
            return
        }

        // 1. Cancel ALL pending triggers to strictly enforce our limit and state.
        notificationCenter.removeAllPendingNotificationRequests()

        // 2. Schedule for a rolling 3-day window only.
        //    (Today + Tomorrow + DayAfter) = 3 days max.
        //    Max Local Notifications = 64.
        //    Our Max usage: 3 days * 6 prayers * 2 types (exact+early) = 36 notifications.
        //    (Often less because User rarely enables EVERYTHING).
        //    We are well within the 64 safe zone.

        let calendar = Calendar.current
        let today = Date()

        for dayOffset in 0..<3 {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: today),
                let prayerTimes = prayerTimeManager.getPrayerTimes(for: date)
            else { continue }

            scheduleDailyNotifications(for: prayerTimes)

            // After scheduling for today, update widget shared data
            // Adding helper call here as per instructions
            if dayOffset == 0 {
                updateWidgetSharedData(prayerTimes: prayerTimes)  // <-- New helper call
            }
        }

        scheduleBackgroundRefresh()  // Always ensure BG task is kept alive
        self.lastScheduledLocation = currentLocation
        print("syncNotifications complete: Rolling 3-day schedule updated.")
    }

    private func scheduleDailyNotifications(for prayerTimes: PrayerTimes) {
        var prayerTimesToNotify = [
            ("Fajr", prayerTimes.fajr),
            ("Sunrise", prayerTimes.sunrise),
            ("Dhuhr", prayerTimes.dhuhr),
            ("Asr", prayerTimes.asr),
            ("Maghrib", prayerTimes.maghrib),
            ("Isha", prayerTimes.isha),
        ]

        let storage = PrayerDataStorage.shared

        // Add Duha if enabled
        if storage.isDuhaEnabled() {
            let duhaTime = prayerTimes.sunrise.addingTimeInterval(45 * 60)
            prayerTimesToNotify.append(("Duha", duhaTime))
        }

        // Add Tahajjud if enabled (Next Day Pre-Fajr)
        if storage.isTahajjudEnabled() {
            // Calculate: Fajr (Tomorrow) - (FajrTomorrow - MaghribToday) / 3
            let fajrTomorrow = prayerTimes.fajr.addingTimeInterval(86400)
            let nightDuration = fajrTomorrow.timeIntervalSince(prayerTimes.maghrib)
            let lastThird = nightDuration / 3
            let tahajjudTime = fajrTomorrow.addingTimeInterval(-lastThird)

            prayerTimesToNotify.append(("Tahajjud", tahajjudTime))
        }

        for (prayerName, prayerTime) in prayerTimesToNotify {
            // Determine if we should notify
            // Standard prayers: check dictionary
            // Optional prayers: always notify if they are in this list (since they are only added if enabled)
            var shouldNotify = notificationSettings[prayerName] == true
            if prayerName == "Tahajjud" || prayerName == "Duha" {
                shouldNotify = true
            }

            // 1. Exact time notification
            if shouldNotify {
                scheduleNotification(for: prayerTime, with: prayerName, type: .exact)
            }

            // 2. Early reminder
            // Reuse same logic or check specific before-settings?
            // User didn't specify early reminders for Tahajjud, but safe to default to 'before' settings if present,
            // or just skip early for now unless explicit.
            // 'notificationSettingsBefore' likely misses keys too.
            // Let's assume early reminders are NOT enabled for optional prayers by default to avoid spam.
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
        guard let validDate = prayerTime.addingTimeInterval(0) as Date? else { return }  // Safe check

        // Don't schedule past events for Today.
        if validDate < Date() && isExact(type) { return }

        let content = UNMutableNotificationContent()
        content.sound = .default

        var triggerDate = validDate
        var identifierSuffix = ""

        switch type {
        case .exact:
            content.title = "Salah Time"
            content.body = "It's time for \(prayerName)"
            identifierSuffix = "exact"

        case .early(let minutes):
            // Calculate early time
            triggerDate = validDate.addingTimeInterval(TimeInterval(-minutes * 60))
            if triggerDate < Date() { return }  // Don't schedule if reminder time already passed

            content.title = "Approaching Prayer"
            content.body = "\(minutes) minutes left until \(prayerName)"
            identifierSuffix = "early"
        }

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        // Unique ID per prayer per day per type.
        // e.g. "Fajr-2023-10-25-exact"
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
        // didSet will call syncNotifications() automatically
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

    /// Writes next prayer info, all prayer times, location name, and Islamic date to shared UserDefaults for Widget usage.
    /// Keys:
    /// - widget_nextPrayer: String (name of next prayer)
    /// - widget_nextPrayerTime: String (ISO8601 date string)
    /// - widget_prayerTimes: [String: String] dictionary with prayer names and ISO8601 date strings
    /// - widget_locationName: String (current location name or empty)
    /// - widget_islamicDate: String (formatted Islamic date)
    private func updateWidgetSharedData(prayerTimes: PrayerTimes) {
        // Retrieve location name from shared defaults (best effort)
        let locationName =
            UserDefaults(suiteName: "group.com.alijaver.PrayerEase")?.string(forKey: "locationName")
            ?? ""

        // Calculate Islamic date
        let islamicCalendar = Calendar(identifier: .islamicUmmAlQura)
        let islamicDateFormatter = DateFormatter()
        islamicDateFormatter.calendar = islamicCalendar
        islamicDateFormatter.dateStyle = .medium
        islamicDateFormatter.timeStyle = .none
        let islamicDateString = islamicDateFormatter.string(from: Date())

        // Delegate to WidgetDataManager to ensure consistent format
        WidgetDataManager.shared.updateWidgetData(
            prayerTimes: prayerTimes,
            locationName: locationName,
            islamicDate: islamicDateString
        )
    }
}
