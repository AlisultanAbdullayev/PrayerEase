//
//  WidgetDataManager.swift
//  PrayerEase
//
//  Created by Alisultan Abdullah on 12/21/25.
//

import Foundation
import WidgetKit
import ActivityKit
import Adhan

/// Manages data synchronization between the main app and widgets
@MainActor
final class WidgetDataManager: ObservableObject, Sendable {
    static let shared = WidgetDataManager()
    
    private static let appGroupId = "group.com.alijaver.PrayerEase"
    
    private var userDefaults: UserDefaults? {
        UserDefaults(suiteName: Self.appGroupId)
    }
    
    @Published var isLiveActivityEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isLiveActivityEnabled, forKey: "isLiveActivityEnabled")
        }
    }
    
    var isLiveActivityRunning: Bool {
        currentActivity != nil
    }
    
    private init() {
        self.isLiveActivityEnabled = UserDefaults.standard.bool(forKey: "isLiveActivityEnabled")
    }
    
    // MARK: - Widget Data Sync
    
    /// Updates widget data with current prayer times
    func updateWidgetData(
        prayerTimes: PrayerTimes,
        locationName: String,
        islamicDate: String
    ) {
        guard let defaults = userDefaults else {
            print("DEBUG Widget: Failed to access App Group UserDefaults")
            return
        }
        
        // Convert prayer times to widget format
        let widgetPrayerTimes = createWidgetPrayerTimes(from: prayerTimes)
        
        // Find next prayer
        let now = Date()
        let nextPrayer = findNextPrayer(prayerTimes: prayerTimes, from: now)
        
        // Store prayer times array
        if let encodedData = try? JSONEncoder().encode(widgetPrayerTimes) {
            defaults.set(encodedData, forKey: "widgetPrayerTimes")
            print("DEBUG Widget: Stored \(widgetPrayerTimes.count) prayer times")
        } else {
            print("DEBUG Widget: Failed to encode prayer times")
        }
        
        // Store individual values for quick access
        defaults.set(locationName, forKey: "locationName")
        defaults.set(islamicDate, forKey: "islamicDate")
        defaults.set(nextPrayer.name, forKey: "nextPrayerName")
        defaults.set(nextPrayer.time, forKey: "nextPrayerTime")
        defaults.set(nextPrayer.iconName, forKey: "nextPrayerIconName")
        
        // Force synchronize
        defaults.synchronize()
        
        print("DEBUG Widget: Data stored - Location: '\(locationName)', Next: \(nextPrayer.name)")
        
        // Reload all widget timelines
        WidgetCenter.shared.reloadAllTimelines()
        print("DEBUG Widget: Requested timeline reload")
    }
    
    /// Creates widget-compatible prayer time data
    private func createWidgetPrayerTimes(from prayerTimes: PrayerTimes) -> [WidgetPrayerTimeData] {
        [
            WidgetPrayerTimeData(name: "Fajr", time: prayerTimes.fajr),
            WidgetPrayerTimeData(name: "Sunrise", time: prayerTimes.sunrise),
            WidgetPrayerTimeData(name: "Dhuhr", time: prayerTimes.dhuhr),
            WidgetPrayerTimeData(name: "Asr", time: prayerTimes.asr),
            WidgetPrayerTimeData(name: "Maghrib", time: prayerTimes.maghrib),
            WidgetPrayerTimeData(name: "Isha", time: prayerTimes.isha)
        ]
    }
    
    private func findNextPrayer(prayerTimes: PrayerTimes, from date: Date) -> (name: String, time: Date, iconName: String) {
        if let next = prayerTimes.nextPrayer(at: date) {
            let time = prayerTimes.time(for: next)
            return (next.name, time, iconName(for: next))
        }
        
        // Return tomorrow's Fajr if no prayer remaining today
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: prayerTimes.fajr) ?? prayerTimes.fajr
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
            nextPrayerTime = Calendar.current.date(byAdding: .day, value: 1, to: prayerTimes.fajr) ?? prayerTimes.fajr
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
            await startLiveActivity(prayerTimes: prayerTimes, locationName: locationName, islamicDate: islamicDate)
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
            nextPrayerTime = Calendar.current.date(byAdding: .day, value: 1, to: prayerTimes.fajr) ?? prayerTimes.fajr
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
            // Previous day's Isha (approximate as 6 hours before Fajr)
            return Calendar.current.date(byAdding: .hour, value: -6, to: prayerTimes.fajr)
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
    
    private func createLiveActivityPrayerTimes(from prayerTimes: PrayerTimes) -> [LiveActivityPrayerTimeData] {
        [
            LiveActivityPrayerTimeData(name: "Fajr", time: prayerTimes.fajr),
            LiveActivityPrayerTimeData(name: "Sunrise", time: prayerTimes.sunrise),
            LiveActivityPrayerTimeData(name: "Dhuhr", time: prayerTimes.dhuhr),
            LiveActivityPrayerTimeData(name: "Asr", time: prayerTimes.asr),
            LiveActivityPrayerTimeData(name: "Maghrib", time: prayerTimes.maghrib),
            LiveActivityPrayerTimeData(name: "Isha", time: prayerTimes.isha)
        ]
    }
}

// MARK: - Widget Data Models (Main App)

struct WidgetPrayerTimeData: Codable {
    let name: String
    let time: Date
}

// MARK: - Live Activity Attributes (Must match widget extension)

import ActivityKit

struct PrayerEaseWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        let nextPrayerName: String
        let nextPrayerTime: Date
        let locationName: String
        let islamicDate: String
        let allPrayerTimes: [LiveActivityPrayerTimeData]
        let previousPrayerTime: Date?
        
        var iconName: String {
            switch nextPrayerName.lowercased() {
            case "fajr": return "circle.lefthalf.filled"
            case "sunrise": return "sunrise.fill"
            case "dhuhr": return "sun.max.fill"
            case "asr": return "sun.haze.fill"
            case "maghrib": return "sunset.fill"
            case "isha": return "moon.stars.fill"
            default: return "circle.fill"
            }
        }
        
        /// Progress from previous prayer to next (0.0 to 1.0)
        var progress: Double {
            guard let prevTime = previousPrayerTime else { return 0.5 }
            let now = Date()
            let totalInterval = nextPrayerTime.timeIntervalSince(prevTime)
            let elapsed = now.timeIntervalSince(prevTime)
            guard totalInterval > 0 else { return 0 }
            return min(max(elapsed / totalInterval, 0), 1)
        }
    }
    
    let activityName: String
}

struct LiveActivityPrayerTimeData: Codable, Hashable, Identifiable {
    var id: String { name }
    let name: String
    let time: Date
    
    var iconName: String {
        switch name.lowercased() {
        case "fajr": return "circle.lefthalf.filled"
        case "sunrise": return "sunrise.fill"
        case "dhuhr": return "sun.max.fill"
        case "asr": return "sun.haze.fill"
        case "maghrib": return "sunset.fill"
        case "isha": return "moon.stars.fill"
        default: return "circle.fill"
        }
    }
}


