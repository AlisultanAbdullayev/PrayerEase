//
//  NotificationManager.swift
//  PrayerEase
//
//  Created by Alisultan Abdullah on 10/30/24.
//

import Foundation
import UserNotifications
import Adhan
import BackgroundTasks
import CoreLocation

final class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    private let prayerTimeManager = PrayerTimeManager.shared
    private let notificationCenter = UNUserNotificationCenter.current()
    private let userDefaults = UserDefaults.standard
    
    let minuteOptions: [Int] = [10, 15, 20, 25, 30, 45, 60]
    
    @Published var notificationSettings: [String: Bool] {
        didSet { userDefaults.set(notificationSettings, forKey: "notifications") }
    }
    @Published var notificationSettingsBefore: [String: Bool] {
        didSet { userDefaults.set(notificationSettingsBefore, forKey: "notificationsBefore") }
    }
    @Published var beforeMinutes: Int = 25 {
        didSet { userDefaults.set(beforeMinutes, forKey: "beforeMinutes") }
    }
    
    private var currentLocation: CLLocation?
    
    private init() {
        self.notificationSettings = userDefaults.dictionary(forKey: "notifications") as? [String: Bool] ?? [
            "Fajr": true, "Sunrise": false, "Dhuhr": true,
            "Asr": true, "Maghrib": true, "Isha": true
        ]
        self.notificationSettingsBefore = userDefaults.dictionary(forKey: "notificationsBefore") as? [String: Bool] ?? [
            "Fajr": false, "Sunrise": false, "Dhuhr": false,
            "Asr": false, "Maghrib": false, "Isha": false
        ]
        self.beforeMinutes = userDefaults.integer(forKey: "beforeMinutes")
        
        requestNotificationAuthorization()

        registerBackgroundTask()
    }
    
    func updateLocation(_ location: CLLocation) {
        self.currentLocation = location
        prayerTimeManager.updateLocation(location)
    }

    private func requestNotificationAuthorization() {
        notificationCenter.requestAuthorization(options: [.alert, .sound]) { [weak self] granted, error in
            if let error = error {
                print("Error requesting notification authorization: \(error.localizedDescription)")
            } else {
                print("Notification authorization \(granted ? "granted" : "denied")")
                if granted {
                        self?.scheduleLongTermNotifications()
                }
            }
        }
    }
    
    private func registerBackgroundTask() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.alijaver.SalahTimes.refreshNotifications", using: nil) { task in
            self.handleAppRefresh(task: task as! BGAppRefreshTask)
        }
    }
    
    private func scheduleBackgroundRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "com.alijaver.SalahTimes.refreshNotifications")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 24 * 3600) // Выполнить через 24 часа
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Could not schedule app refresh: \(error)")
        }
    }
    
    private func handleAppRefresh(task: BGAppRefreshTask) {
        scheduleBackgroundRefresh() // Планируем следующее обновление
        
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }
        
        DispatchQueue.main.async {
            self.scheduleLongTermNotifications()
            task.setTaskCompleted(success: true)
        }
    }
    
    func scheduleLongTermNotifications() {
        guard currentLocation != nil else {
            print("Location not available. Cannot schedule notifications.")
            return
        }
        
        notificationCenter.removeAllPendingNotificationRequests()
        
        let calendar = Calendar.current
        let today = Date()
        
        // Планируем уведомления на следующие 7 дней
        for dayOffset in 0..<1 {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: today),
                  let prayerTimes = prayerTimeManager.getPrayerTimes(for: date) else { continue }
            
            scheduleDailyNotifications(for: prayerTimes)
        }
        
        scheduleBackgroundRefresh()
        print("Long-term notifications scheduled!")
    }
    
    private func scheduleDailyNotifications(for prayerTimes: PrayerTimes) {
        let prayerTimesToNotify = [
            ("Fajr", prayerTimes.fajr),
            ("Sunrise", prayerTimes.sunrise),
            ("Dhuhr", prayerTimes.dhuhr),
            ("Asr", prayerTimes.asr),
            ("Maghrib", prayerTimes.maghrib),
            ("Isha", prayerTimes.isha)
        ]
        
        for (prayerName, prayerTime) in prayerTimesToNotify {
            if notificationSettings[prayerName] == true {
                scheduleNotification(for: prayerTime, with: prayerName)
            }
            if notificationSettingsBefore[prayerName] == true {
                scheduleNotificationBefore(for: prayerTime, with: prayerName, before: beforeMinutes)
            }
        }
    }
    
    private func scheduleNotification(for prayerTime: Date, with prayerName: String) {
        let content = UNMutableNotificationContent()
        content.title = "Salah time"
        content.subtitle = prayerName
        content.body = "Kindly remind you about \(prayerName) time!"
        content.sound = .default
        
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: prayerTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            }
        }
    }
    
    private func scheduleNotificationBefore(for prayerTime: Date, with prayerName: String, before minutes: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Salah time"
        content.body = "Kindly remind you that \(minutes) minutes left until \(prayerName)!"
        content.sound = .default
        
        var components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: prayerTime)
        components.minute = (components.minute ?? 0) - minutes
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        notificationCenter.removeAllPendingNotificationRequests()
        notificationCenter.add(request) { error in
            if let error = error {
                print("Error scheduling notification before: \(error.localizedDescription)")
            }
        }
    }
    
    func updateNotificationSettings(for prayerName: String, sendNotification: Bool, isBefore: Bool = false) {
        if isBefore {
            notificationSettingsBefore[prayerName] = sendNotification
        } else {
            notificationSettings[prayerName] = sendNotification
        }
        scheduleLongTermNotifications()
    }
}
