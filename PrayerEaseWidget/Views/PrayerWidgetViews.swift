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
            Text(entry.nextPrayerName)
                .foregroundStyle(accentGreen)
                .font(.headline)

            Text("at \(entry.nextPrayerTime, format: .dateTime.hour().minute())")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.top, 1)

            Spacer(minLength: 8)

            Text(entry.nextPrayerTime, style: .timer)
                .font(.title.weight(.bold))
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
        VStack(spacing: 0) {
            // Header
            UnifiedHeaderView(
                prayerName: entry.nextPrayerName,
                prayerTime: entry.nextPrayerTime,
                locationName: entry.locationName,
                hijriDate: entry.islamicDate,
                countdownDate: entry.nextPrayerTime
            )
            .padding([.top, .horizontal])

            Spacer()

            // Schedule
            PrayerScheduleView(
                prayers: entry.prayerTimes,
                currentPrayerName: entry.currentPrayerName
            )
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

            Divider()
            Spacer()

            // List view for large widget
            VStack {
                ForEach(entry.prayerTimes) { prayer in
                    HStack {
                        Text(prayer.name)
                        Spacer()
                        Text(prayer.time, format: .dateTime.hour().minute())
                    }
                    .foregroundStyle(prayer.name == entry.currentPrayerName ? .primary : .secondary)
                    .fontWeight(prayer.name == entry.currentPrayerName ? .bold : .regular)
                    .foregroundStyle(
                        prayer.name == entry.currentPrayerName ? accentGreen : .primary)
                    if prayer.id != entry.prayerTimes.last?.id {
                        Divider()
                    }
                }
            }
            .font(.subheadline)
        }
        .padding()
        .padding(.vertical, 16)
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
            Text(entry.nextPrayerName.prefix(1))
                .font(.caption2.bold())
        } currentValueLabel: {
            Text(entry.nextPrayerTime, style: .timer)
                .multilineTextAlignment(.center)
                .font(.caption2)
        }
        .gaugeStyle(.accessoryCircular)
    }
}

struct AccessoryRectangularView: View {
    let entry: PrayerWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(
                "\(entry.nextPrayerName): \(entry.nextPrayerTime, format: .dateTime.hour().minute())"
            )
            .font(.footnote)

            Text(entry.nextPrayerTime, style: .timer)
                .font(.headline)
                .monospacedDigit()

            Text(entry.locationName)
                .font(.footnote)
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

// MARK: - Shared Components

struct LocationLabel: View {
    let name: String

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "location.fill")
                .font(.caption2)
            Text(name)
                .font(.caption)
                .lineLimit(1)
        }
        .foregroundStyle(.secondary)
    }
}
