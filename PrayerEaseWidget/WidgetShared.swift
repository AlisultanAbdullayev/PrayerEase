//
//  WidgetShared.swift
//  PrayerEaseWidget
//
//  Created by Alisultan Abdullah on 12/21/25.
//

import SwiftUI
import WidgetKit

// MARK: - Constants

let accentGreen = Color(red: 0.2, green: 0.8, blue: 0.4)

// MARK: - Shared Models

struct SharedPrayerTime: Identifiable, Equatable, Codable, Hashable {
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

    var shortName: String {
        String(name.prefix(3)).uppercased()
    }

    var timeString: String {
        time.formatted(.dateTime.hour().minute())
    }

    var amPmString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "a"
        return formatter.string(from: time)
    }

    var hourMinuteString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm"
        return formatter.string(from: time)
    }
}

// MARK: - Shared View Components

/// A unified header showing Prayer Name, Time, Countdown, and Location
struct UnifiedHeaderView: View {
    let prayerName: String
    let prayerTime: Date
    let locationName: String
    let hijriDate: String
    let countdownDate: Date

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 8) {
                // Prayer Name and Countdown
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(prayerName)
                        .foregroundStyle(accentGreen)
                    Text("at")
                        .foregroundStyle(.secondary)
                    Text(prayerTime, format: .dateTime.hour().minute())
                        .foregroundStyle(.secondary)
                }

                //Countdown
                Text(countdownDate, style: .timer)
                    .monospacedDigit()
                    .font(.title2)
                    .bold()
                    .contentTransition(.numericText())
            }

            Spacer()

            // Location
            VStack(alignment: .trailing, spacing: 8) {
                Text(hijriDate)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                HStack(spacing: 4) {
                    Image(systemName: "location.fill")

                    ViewThatFits(in: .horizontal) {
                        Text(locationName)

                        Text(locationName.components(separatedBy: ",").first ?? locationName)

                        Text(locationName.components(separatedBy: ",").first ?? locationName)
                            .minimumScaleFactor(0.8)
                    }
                }
                .font(.footnote)

            }
            .foregroundStyle(.secondary)
        }
    }
}

/// A unified schedule row showing all prayers
struct PrayerScheduleView: View {
    let prayers: [SharedPrayerTime]
    let currentPrayerName: String

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(prayers.enumerated()), id: \.element.id) { index, prayer in
                PrayerGridCell(
                    prayer: prayer,
                    isActive: prayer.name == currentPrayerName
                )

                if index < prayers.count - 1 {
                    Divider()
                        .frame(width: 1, height: 30)
                        .overlay(Color.secondary.opacity(0.2))
                }
            }
        }
        .background(Color.secondary.opacity(0.05), in: .rect)
    }
}

/// Individual cell for the prayer schedule
struct PrayerGridCell: View {
    let prayer: SharedPrayerTime
    let isActive: Bool

    var body: some View {
        VStack {
            Text(prayer.shortName)

            Text(prayer.hourMinuteString)

            Text(prayer.amPmString)
                .textCase(.uppercase)
        }
        .foregroundStyle(isActive ? .white : .secondary)
        .fontWeight(isActive ? .bold : .regular)
        .font(.caption)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
        .background(isActive ? accentGreen : .gray.opacity(0.1), in: .rect)
    }
}
