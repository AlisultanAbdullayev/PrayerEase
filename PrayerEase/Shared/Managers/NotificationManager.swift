//
//  NotificationManager.swift
//  PrayerEase
//
//  Created by Alisultan Abdullah on 10/30/24.
//

import Adhan
import BackgroundTasks
import CoreLocation
import Foundation
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

        // requestNotificationAuthorization() // Removed auto-request for onboarding flow
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
        return await withCheckedContinuation { continuation in
            notificationCenter.requestAuthorization(options: [.alert, .sound]) {
                [weak self] granted, error in
                if let error = error {
                    print(
                        "Error requesting notification authorization: \(error.localizedDescription)"
                    )
                } else {
                    print("Notification authorization \(granted ? "granted" : "denied")")
                    if granted {
                        Task { @MainActor in
                            self?.syncNotifications()
                        }
                    }
                }
                continuation.resume(returning: granted)
            }
        }
    }

    private func registerBackgroundTask() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "com.alijaver.SalahTimes.refreshNotifications", using: nil
        ) { [weak self] task in
            Task { @MainActor in
                self?.handleAppRefresh(task: task as! BGAppRefreshTask)
            }
        }
    }

    private func scheduleBackgroundRefresh() {
        let request = BGAppRefreshTaskRequest(
            identifier: "com.alijaver.SalahTimes.refreshNotifications")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 12 * 3600)  // Refresh twice a day roughly, or at least check frequently.

        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Could not schedule app refresh: \(error)")
        }
    }

    private func handleAppRefresh(task: BGAppRefreshTask) {
        scheduleBackgroundRefresh()  // Schedule next one

        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }

        // Use Task for modern concurrency
        Task {
            self.syncNotifications()
            task.setTaskCompleted(success: true)
        }
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
        }

        scheduleBackgroundRefresh()  // Always ensure BG task is kept alive
        self.lastScheduledLocation = currentLocation
        print("syncNotifications complete: Rolling 3-day schedule updated.")
    }

    private func scheduleDailyNotifications(for prayerTimes: PrayerTimes) {
        let prayerTimesToNotify = [
            ("Fajr", prayerTimes.fajr),
            ("Sunrise", prayerTimes.sunrise),
            ("Dhuhr", prayerTimes.dhuhr),
            ("Asr", prayerTimes.asr),
            ("Maghrib", prayerTimes.maghrib),
            ("Isha", prayerTimes.isha),
        ]

        for (prayerName, prayerTime) in prayerTimesToNotify {
            // 1. Exact time notification
            if notificationSettings[prayerName] == true {
                scheduleNotification(for: prayerTime, with: prayerName, type: .exact)
            }

            // 2. Early reminder
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
}
