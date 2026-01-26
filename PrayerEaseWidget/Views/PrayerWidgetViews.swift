//
//  PrayerWidgetViews.swift
//  PrayerEaseWidget
//
//  Created by Alisultan Abdullah on 12/21/25.
//

import SwiftUI
import WidgetKit

// MARK: - Widget Entry Views

struct PrayerEaseWidgetEntryView: View {
    var entry: PrayerWidgetEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                SmallWidgetView(entry: entry)
            case .systemMedium:
                MediumWidgetView(entry: entry)
            case .systemLarge:
                LargeWidgetView(entry: entry)
            case .systemExtraLarge:
                ExtraLargeWidgetView(entry: entry)
            case .accessoryCircular:
                AccessoryCircularView(entry: entry)
            case .accessoryRectangular:
                AccessoryRectangularView(entry: entry)
            case .accessoryInline:
                AccessoryInlineView(entry: entry)
            #if os(watchOS)
                case .accessoryCorner:
                    AccessoryCornerView(entry: entry)
            #endif
            @unknown default:
                SmallWidgetView(entry: entry)
            }
        }
    }
}

// MARK: - Small Widget

struct SmallWidgetView: View {
    let entry: PrayerWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(entry.nextPrayerName)
                    .foregroundStyle(.accent)
                    .fontWeight(.semibold)
                Spacer()
                Image("PrayerEase")  // Lightweight fallback for safety
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
            }

            Text("at \(entry.nextPrayerTime, format: .dateTime.hour().minute())")
                .foregroundStyle(.secondary)
                .fontWeight(.semibold)

            Spacer(minLength: 8)

            Text(entry.nextPrayerTime, style: .timer)
                .font(.title)
                .bold()
                .fontDesign(.rounded)
                .monospacedDigit()
                .foregroundStyle(.primary)
                .contentTransition(.numericText())

            Spacer(minLength: 6)

            Text(entry.islamicDate)
                .font(.caption2)
                .foregroundStyle(.secondary)
            LocationLabel(name: entry.locationName)

        }
        .padding()
    }
}

// MARK: - Medium Widget

struct MediumWidgetView: View {
    let entry: PrayerWidgetEntry

    var body: some View {
        VStack {
            // Header
            UnifiedHeaderView(
                prayerName: entry.nextPrayerName,
                prayerTime: entry.nextPrayerTime,
                locationName: entry.locationName,
                hijriDate: entry.islamicDate,
                countdownDate: entry.nextPrayerTime
            )
            .padding()

            Spacer()

            // Schedule
            PrayerScheduleView(
                prayers: entry.prayerTimes,
                currentPrayerName: entry.currentPrayerName
            )
            .padding(.bottom, 8)
        }
    }
}

// MARK: - Large Widget

struct LargeWidgetView: View {
    let entry: PrayerWidgetEntry

    var body: some View {
        VStack {
            // Header
            UnifiedHeaderView(
                prayerName: entry.nextPrayerName,
                prayerTime: entry.nextPrayerTime,
                locationName: entry.locationName,
                hijriDate: entry.islamicDate,
                countdownDate: entry.nextPrayerTime
            )

            Spacer()

            // List view for large widget
            LargePrayerListView(
                prayers: entry.prayerTimes,
                currentPrayerName: entry.currentPrayerName
            )
        }
        .padding()
    }
}

private struct LargePrayerListView: View {
    let prayers: [SharedPrayerTime]
    let currentPrayerName: String

    var body: some View {
        VStack {
            ForEach(prayers) { prayer in
                LargePrayerRow(
                    prayer: prayer,
                    isActive: prayer.name == currentPrayerName,
                    isLast: prayer.id == prayers.last?.id
                )
            }
        }
    }
}

/// Extracted row for Large Widget (resolves type-checker complexity)
private struct LargePrayerRow: View {
    let prayer: SharedPrayerTime
    let isActive: Bool
    let isLast: Bool

    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text(prayer.name)
                Spacer()
                Text(prayer.time, format: .dateTime.hour().minute())
            }
            .foregroundStyle(isActive ? Color.accent : .secondary)
            .font(isActive ? .callout.bold() : .callout)

            if !isLast {
                Divider()
            }
        }
    }
}

// MARK: - Extra Large Widget

struct ExtraLargeWidgetView: View {
    let entry: PrayerWidgetEntry

    var body: some View {
        LargeWidgetView(entry: entry)
    }
}

// MARK: - Accessory Widgets

struct AccessoryCircularView: View {
    let entry: PrayerWidgetEntry

    var progress: Double {
        guard let prev = entry.previousPrayerTime else { return 0.5 }
        let total = entry.nextPrayerTime.timeIntervalSince(prev)
        let elapsed = entry.date.timeIntervalSince(prev)
        guard total > 0 else { return 0 }
        return min(max(elapsed / total, 0), 1)
    }

    var body: some View {
        Gauge(value: 1.0 - progress) {
            Text(prayerShortName)
                .font(.caption2)
                .bold()
        } currentValueLabel: {
            AccessoryCircularTimeLabelView(
                nextPrayerTime: entry.nextPrayerTime,
                entryDate: entry.date
            )
                .multilineTextAlignment(.center)
                .font(.caption2)
        }
        .gaugeStyle(.accessoryCircular)
    }

    private var prayerShortName: String {
        if let prayer = entry.prayerTimes.first(where: { $0.name == entry.nextPrayerName }) {
            return prayer.shortName
        }
        return String(entry.nextPrayerName.prefix(3)).uppercased()
    }

}

private struct AccessoryCircularTimeLabelView: View {
    let nextPrayerTime: Date
    let entryDate: Date

    var body: some View {
        let timeInterval = nextPrayerTime.timeIntervalSince(entryDate)
        if timeInterval >= 3600 {  // >= 1 hour
            let hours = Int(timeInterval / 3600)
            Text("\(hours)h+")
        } else if timeInterval <= 60 {
            Text(nextPrayerTime, style: .timer)
        } else {
            Text(nextPrayerTime, style: .relative)
        }
    }
}

struct AccessoryRectangularView: View {
    let entry: PrayerWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(
                "\(entry.nextPrayerName): \(entry.nextPrayerTime, format: .dateTime.hour().minute())"
            )

            Text(entry.nextPrayerTime, style: .timer)
                .bold()
                .monospacedDigit()

            ViewThatFits(in: .horizontal) {
                Text(entry.locationName)

                Text(entry.locationName.components(separatedBy: ",").first ?? entry.locationName)

                Text(entry.locationName.components(separatedBy: ",").first ?? entry.locationName)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(.secondary)
        }
    }
}

struct AccessoryInlineView: View {
    let entry: PrayerWidgetEntry

    var body: some View {
        Text(
            "\(entry.nextPrayerName) at \(entry.nextPrayerTime, format: .dateTime.hour().minute())")
    }
}

// MARK: - Corner Complication (watchOS)

struct AccessoryCornerView: View {
    let entry: PrayerWidgetEntry

    var body: some View {
        Text(entry.nextPrayerTime, style: .timer)
            .fontWeight(.semibold)
            .fontDesign(.rounded)
            .monospacedDigit()
            .widgetLabel {
                Text(entry.nextPrayerName)
            }
    }
}

// MARK: - Shared Components

struct LocationLabel: View {
    let name: String

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "location.fill")
                .font(.footnote)

            ViewThatFits(in: .horizontal) {
                Text(name)
                    .font(.caption)

                Text(name.components(separatedBy: ",").first ?? name)
                    .font(.caption)

                Text(name.components(separatedBy: ",").first ?? name)
                    .font(.caption)
                    .minimumScaleFactor(0.8)
            }
        }
        .fontWeight(.semibold)
        .foregroundStyle(.secondary)
    }
}
