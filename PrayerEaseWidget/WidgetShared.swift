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

// NOTE: SharedPrayerTime is now defined in SharedTypes.swift (shared across all targets)

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
                    .font(.title)
                    .bold()
                    .fontDesign(.rounded)
                    .contentTransition(.numericText())
            }

            Spacer()

            // Location
            VStack(alignment: .trailing, spacing: 8) {
                Image("PrayerEase")
                    .resizable()
                    .frame(width: 24, height: 24)

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
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
    }
}

/// A unified schedule row showing all prayers
struct PrayerScheduleView: View {
    @Environment(\.widgetRenderingMode) private var widgetRenderingMode

    let prayers: [SharedPrayerTime]
    let currentPrayerName: String

    /// Container background adapted for rendering mode
    private var containerBackground: Color {
        switch widgetRenderingMode {
        case .accented, .vibrant:
            return .clear
        default:
            return Color.secondary.opacity(0.05)
        }
    }

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
        .background(containerBackground, in: .rect)
    }
}

/// Individual cell for the prayer schedule
struct PrayerGridCell: View {

    @Environment(\.widgetRenderingMode) private var widgetRenderingMode

    let prayer: SharedPrayerTime
    let isActive: Bool

    // MARK: - Computed Background Colors

    /// Base background for active/inactive states
    private var baseBackground: Color {
        isActive ? accentGreen : .gray.opacity(0.15)
    }

    /// Final background adjusted for widget rendering mode
    private var adaptiveBackground: Color {
        switch widgetRenderingMode {
        case .accented:
            // Soften background when tinted/accented
            return baseBackground.opacity(isActive ? 0.3 : 0.1)
        case .vibrant:
            // Let system handle it (Lock Screen blur)
            return .clear
        default:
            // Full color mode (Home Screen, StandBy)
            return baseBackground
        }
    }

    var body: some View {
        VStack {
            Text(prayer.name)

            Text(prayer.hourMinuteString)

            Text(prayer.amPmString)
                .textCase(.uppercase)
        }
        .widgetAccentable()
        .foregroundStyle(isActive ? .white : .secondary)
        .fontWeight(isActive ? .bold : .regular)
        .font(.caption)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
        .background(adaptiveBackground, in: .rect)
    }
}
