//
//  WatchWidget.swift
//  WatchWidget
//
//  Created by Alisultan Abdullah on 12/24/25.
//

import Foundation
import SwiftUI
import WidgetKit

// MARK: - Shared Model (matches iOS app encoding)

struct SharedPrayerTime: Identifiable, Equatable, Codable, Hashable, Sendable {
    var id: String { name }
    let name: String
    let time: Date

    var shortName: String {
        String(name.prefix(3)).uppercased()
    }
}

// MARK: - Entry

struct WatchWidgetEntry: TimelineEntry {
    let date: Date
    let nextPrayerName: String
    let nextPrayerTime: Date
    let currentPrayerName: String
    let locationName: String
    var previousPrayerTime: Date?

    static var placeholder: WatchWidgetEntry {
        WatchWidgetEntry(
            date: Date(),
            nextPrayerName: "Fajr",
            nextPrayerTime: Date().addingTimeInterval(3600),
            currentPrayerName: "Isha",
            locationName: "Loading...",
            previousPrayerTime: Date().addingTimeInterval(-3600)
        )
    }
}

// MARK: - Timeline Provider

struct WatchTimelineProvider: TimelineProvider {
    // Shared App Group container
    private let appGroupID = "group.com.alijaver.PrayerEase"

    func placeholder(in context: Context) -> WatchWidgetEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (WatchWidgetEntry) -> Void) {
        completion(loadEntry(for: Date()))
    }

    func getTimeline(
        in context: Context, completion: @escaping (Timeline<WatchWidgetEntry>) -> Void
    ) {
        let now = Date()
        var entries: [WatchWidgetEntry] = []
        let calendar = Calendar.current

        // Generate entries for next 4 hours
        for minuteOffset in stride(from: 0, to: 240, by: 15) {
            guard let entryDate = calendar.date(byAdding: .minute, value: minuteOffset, to: now)
            else { continue }
            entries.append(loadEntry(for: entryDate))
        }

        let refreshDate = calendar.date(byAdding: .minute, value: 15, to: now) ?? now
        completion(Timeline(entries: entries, policy: .after(refreshDate)))
    }

    private func loadEntry(for date: Date) -> WatchWidgetEntry {
        // STRICT: Only use App Group. Watch App writes here.
        guard let defaults = UserDefaults(suiteName: appGroupID) else {
            return .placeholder
        }

        var prayerTimes: [SharedPrayerTime] = []
        if let data = defaults.data(forKey: "widgetPrayerTimes"),
            let decoded = try? JSONDecoder().decode([SharedPrayerTime].self, from: data)
        {
            prayerTimes = decoded
        }

        let locationName = defaults.string(forKey: "locationName") ?? "PrayerEase"

        guard !prayerTimes.isEmpty else {
            return .placeholder
        }

        let (nextName, nextTime) = findNextPrayer(from: date, prayerTimes: prayerTimes)
        let (currentName, _) = findCurrentPrayer(from: date, prayerTimes: prayerTimes)
        let previousTime = findPreviousPrayerTime(from: date, prayerTimes: prayerTimes)

        return WatchWidgetEntry(
            date: date,
            nextPrayerName: nextName,
            nextPrayerTime: nextTime,
            currentPrayerName: currentName,
            locationName: locationName,
            previousPrayerTime: previousTime
        )
    }

    private func findNextPrayer(from date: Date, prayerTimes: [SharedPrayerTime]) -> (String, Date)
    {
        if let next = prayerTimes.first(where: { $0.time > date }) {
            return (next.name, next.time)
        }
        if let first = prayerTimes.first {
            // Start with tomorrow
            var nextTime = Calendar.current.date(byAdding: .day, value: 1, to: first.time)!
            // Safety: Ensure it's in the future (handles stale data)
            while nextTime <= date {
                nextTime = Calendar.current.date(byAdding: .day, value: 1, to: nextTime)!
            }
            return (first.name, nextTime)
        }
        return ("Fajr", date.addingTimeInterval(3600))
    }

    private func findCurrentPrayer(from date: Date, prayerTimes: [SharedPrayerTime]) -> (
        String, Date
    ) {
        if let current = prayerTimes.last(where: { $0.time <= date }) {
            return (current.name, current.time)
        }
        return ("Isha", date)
    }

    private func findPreviousPrayerTime(from date: Date, prayerTimes: [SharedPrayerTime]) -> Date? {
        let sorted = prayerTimes.sorted { $0.time < $1.time }
        if let idx = sorted.firstIndex(where: { $0.time > date }) {
            if idx > 0 {
                return sorted[idx - 1].time
            } else {
                // Before first prayer (Fajr) -> Previous was Isha YESTERDAY
                if let isha = sorted.last {
                    return Calendar.current.date(byAdding: .day, value: -1, to: isha.time)
                }
            }
        }
        return sorted.last?.time
    }
}

// MARK: - Views

struct WatchWidgetEntryView: View {
    var entry: WatchWidgetEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .accessoryCircular:
            CircularView(entry: entry)
        case .accessoryRectangular:
            RectangularView(entry: entry)
        case .accessoryInline:
            InlineView(entry: entry)
        case .accessoryCorner:
            CornerView(entry: entry)
        default:
            RectangularView(entry: entry)
        }
    }
}

struct CircularView: View {
    let entry: WatchWidgetEntry

    var progress: Double {
        guard let prev = entry.previousPrayerTime else { return 0.5 }
        let total = entry.nextPrayerTime.timeIntervalSince(prev)
        let elapsed = entry.date.timeIntervalSince(prev)
        guard total > 0 else { return 0 }
        return min(max(elapsed / total, 0), 1)
    }

    var body: some View {
        Gauge(value: 1.0 - progress) {
            // Always show NEXT prayer name
            Text(String(entry.nextPrayerName.prefix(3)).uppercased())
                .fontWeight(.bold)
        } currentValueLabel: {
            let remaining = entry.nextPrayerTime.timeIntervalSince(entry.date)
            if remaining >= 3600 {
                Text("\(Int(remaining / 3600))h+")
            } else {
                Text("\(Int(remaining / 60))m")
            }
        }
        .gaugeStyle(.accessoryCircular)
    }
}

struct RectangularView: View {
    let entry: WatchWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(
                "\(entry.nextPrayerName): \(entry.nextPrayerTime, format: .dateTime.hour().minute())"
            )
            Text(entry.nextPrayerTime, style: .timer)
                .monospacedDigit()
                .bold()
            HStack {
                Image(systemName: "location.fill")
                Text(entry.locationName)
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
    }
}

struct InlineView: View {
    let entry: WatchWidgetEntry
    var body: some View {
        Text(
            "\(entry.nextPrayerName) at \(entry.nextPrayerTime, format: .dateTime.hour().minute())")
    }
}

struct CornerView: View {
    let entry: WatchWidgetEntry

    var body: some View {
        let remaining = entry.nextPrayerTime.timeIntervalSince(entry.date)

        // Short text curves along bezel, like "54°" or "3h"
        if remaining >= 3600 {
            Text("\(Int(remaining / 3600))h+")
                .widgetCurvesContent()
                .widgetLabel { Text(entry.nextPrayerName) }
        } else {
            Text("\(Int(remaining / 60))m")
                .widgetCurvesContent()
                .widgetLabel { Text(entry.nextPrayerName) }
        }
    }
}

// MARK: - Widget

struct WatchWidget: Widget {
    let kind: String = "WatchWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WatchTimelineProvider()) { entry in
            WatchWidgetEntryView(entry: entry)
                .containerBackground(.ultraThinMaterial, for: .widget)
        }
        .configurationDisplayName("Prayer Times")
        .description("Shows countdown to next prayer.")
        .supportedFamilies([
            .accessoryCircular, .accessoryRectangular, .accessoryInline, .accessoryCorner,
        ])
    }
}

#Preview(as: .accessoryRectangular) {
    WatchWidget()
} timeline: {
    WatchWidgetEntry.placeholder
}
