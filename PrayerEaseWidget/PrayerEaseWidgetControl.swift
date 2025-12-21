//
//  PrayerEaseWidgetControl.swift
//  PrayerEaseWidget
//
//  Created by Alisultan Abdullah on 12/21/25.
//

import AppIntents
import SwiftUI
import WidgetKit

// MARK: - Control Center Widget

struct PrayerEaseControlWidget: ControlWidget {
    static let kind = "com.alijaver.PrayerEase.ControlWidget"
    
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(
            kind: Self.kind,
            provider: PrayerControlProvider()
        ) { value in
            ControlWidgetButton(action: OpenPrayerTimesIntent()) {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(value.nextPrayerName)
                            .font(.headline)
                        Text(value.formattedTime)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: value.iconName)
                }
            }
        }
        .displayName("Next Prayer")
        .description("Shows the next prayer time. Tap to open PrayerEase.")
    }
}

// MARK: - Control Widget Value

struct PrayerControlValue {
    let nextPrayerName: String
    let nextPrayerTime: Date
    
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: nextPrayerTime)
    }
    
    var iconName: String {
        switch nextPrayerName.lowercased() {
        case "fajr": return "circle.lefthalf.filled"
        case "sunrise": return "sunrise.fill"
        case "dhuhr": return "sun.max.fill"
        case "asr": return "sun.haze.fill"
        case "maghrib": return "sunset.fill"
        case "isha": return "moon.stars.fill"
        default: return "clock.fill"
        }
    }
    
    static var placeholder: PrayerControlValue {
        PrayerControlValue(
            nextPrayerName: "Fajr",
            nextPrayerTime: Date().addingTimeInterval(3600)
        )
    }
}

// MARK: - Control Widget Provider

struct PrayerControlProvider: ControlValueProvider {
    private static let appGroupId = "group.com.alijaver.PrayerEase"
    
    var previewValue: PrayerControlValue {
        .placeholder
    }
    
    func currentValue() async throws -> PrayerControlValue {
        guard let defaults = UserDefaults(suiteName: Self.appGroupId) else {
            return .placeholder
        }
        
        let nextPrayerName = defaults.string(forKey: "nextPrayerName") ?? "Fajr"
        let nextPrayerTime = defaults.object(forKey: "nextPrayerTime") as? Date ?? Date().addingTimeInterval(3600)
        
        return PrayerControlValue(
            nextPrayerName: nextPrayerName,
            nextPrayerTime: nextPrayerTime
        )
    }
}

// MARK: - App Intent for Control Widget

struct OpenPrayerTimesIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Prayer Times"
    static var description = IntentDescription("Opens the PrayerEase app to view prayer times.")
    static var openAppWhenRun: Bool = true
    
    func perform() async throws -> some IntentResult {
        return .result()
    }
}
