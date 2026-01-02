//
//  WidgetShared.swift
//  PrayerEaseWidget
//
//  Created by Alisultan Abdullah on 12/21/25.
//

import SwiftUI
import WidgetKit


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
                        .foregroundStyle(.accent)
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
            VStack(alignment: .trailing, spacing: 4) {
                Image("PrayerEase")  // Lightweight fallback
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                Text(hijriDate)
                LocationLabel(name: locationName)
            }
            .font(.footnote)
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
        isActive ? .accent : .gray.opacity(0.15)
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
