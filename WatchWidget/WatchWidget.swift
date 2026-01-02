//
//  WatchWidget.swift
//  WatchWidget
//
//  Created by Alisultan Abdullah on 12/24/25.
//

import Foundation
import SwiftUI
import WidgetKit

// NOTE: SharedPrayerTime is now defined in SharedTypes.swift (shared across all targets)

// MARK: - Countdown Formatting Helper

/// Uses PrayerTimeCalculator for consistent formatting across targets
private func formatCountdown(_ remaining: TimeInterval) -> String {
    PrayerTimeCalculator.formatCompactCountdown(remaining)
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
            nextPrayerName: PrayerNames.fajr,
            nextPrayerTime: Date().addingTimeInterval(TimeIntervals.oneHour),
            currentPrayerName: PrayerNames.isha,
            locationName: DefaultValues.loadingPlaceholder,
            previousPrayerTime: Date().addingTimeInterval(-TimeIntervals.oneHour)
        )
    }
}

// MARK: - Timeline Provider

struct WatchTimelineProvider: TimelineProvider {
    // Shared App Group container
    private let appGroupID = AppConfig.appGroupId

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

        // Load prayer times once for efficiency
        let prayerTimes = loadPrayerTimes()

        // Find next prayer to determine update frequency
//        let nextPrayer = prayerTimes.first { $0.time > now }
//        let timeUntilNextPrayer = nextPrayer?.time.timeIntervalSince(now) ?? TimeIntervals.oneHour

        // Standard 15-minute entries for battery efficiency
        // SwiftUI .timer style handles real-time countdown automatically
        for minuteOffset in stride(from: 0, to: 240, by: 15) {
            guard let entryDate = calendar.date(byAdding: .minute, value: minuteOffset, to: now)
            else { continue }
            entries.append(loadEntry(for: entryDate, cachedPrayers: prayerTimes))
        }

        // 3. Critical prayer-time entries (ensure update at exact prayer times)
        let protectionWindow = now.addingTimeInterval(TimeIntervals.fourHours)
        for prayer in prayerTimes where prayer.time > now && prayer.time < protectionWindow {
            // Entry AT prayer time
            entries.append(loadEntry(for: prayer.time, cachedPrayers: prayerTimes))

            // Entry 1 second after (to show next prayer immediately)
            if let afterPrayer = calendar.date(byAdding: .second, value: 1, to: prayer.time) {
                entries.append(loadEntry(for: afterPrayer, cachedPrayers: prayerTimes))
            }
        }

        // 4. Sort and deduplicate by date
        entries.sort { $0.date < $1.date }

        // Request refresh in 5 minutes (watch OS will batch updates)
        let refreshDate = calendar.date(byAdding: .minute, value: 5, to: now) ?? now
        completion(Timeline(entries: entries, policy: .after(refreshDate)))
    }
    /// Loads prayer times from App Group storage
    private func loadPrayerTimes() -> [SharedPrayerTime] {
        guard let defaults = UserDefaults(suiteName: appGroupID),
            let data = defaults.data(forKey: StorageKeys.widgetPrayerTimes),
            let decoded = try? JSONDecoder().decode([SharedPrayerTime].self, from: data)
        else {
            return []
        }
        return decoded
    }

    /// Loads entry for a specific date, optionally using cached prayer times for efficiency
    private func loadEntry(for date: Date, cachedPrayers: [SharedPrayerTime]? = nil)
        -> WatchWidgetEntry
    {
        let prayerTimes = cachedPrayers ?? loadPrayerTimes()

        guard let defaults = UserDefaults(suiteName: appGroupID) else {
            return .placeholder
        }

        let locationName = defaults.string(forKey: StorageKeys.locationName) ?? "PrayerEase"

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

        guard let first = prayerTimes.first else {
            return (PrayerNames.fajr, date.addingTimeInterval(TimeIntervals.oneHour))
        }

        // Use shared calculator for date projection
        let nextTime = PrayerTimeCalculator.projectToFuture(first.time, from: date)
        return (first.name, nextTime)
    }

    // NOTE: projectToFuture moved to PrayerTimeCalculator for reuse across targets

    private func findCurrentPrayer(from date: Date, prayerTimes: [SharedPrayerTime]) -> (
        String, Date
    ) {
        if let current = prayerTimes.last(where: { $0.time <= date }) {
            return (current.name, current.time)
        }
        return (PrayerNames.isha, date)
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
    @Environment(\.isLuminanceReduced) private var isLuminanceReduced

    var progress: Double {
        PrayerTimeCalculator.progress(
            from: entry.previousPrayerTime,
            to: entry.nextPrayerTime,
            at: entry.date
        )
    }

    var body: some View {
        Gauge(value: 1.0 - progress) {
            // Always show NEXT prayer name
            Text(String(entry.nextPrayerName.prefix(3)).uppercased())
                .fontWeight(.bold)
        } currentValueLabel: {
            // Use timer for normal mode, compact format when luminance is reduced
            if isLuminanceReduced {
                Text(formatCountdown(entry.nextPrayerTime.timeIntervalSince(entry.date)))
            } else {
                Text(entry.nextPrayerTime, style: .timer)
                    .monospacedDigit()
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
    @Environment(\.isLuminanceReduced) private var isLuminanceReduced

    var body: some View {
        Group {
            // Use timer for normal mode, compact format when luminance is reduced
            if isLuminanceReduced {
                Text(formatCountdown(entry.nextPrayerTime.timeIntervalSince(entry.date)))
            } else {
                Text(entry.nextPrayerTime, style: .timer)
                    .monospacedDigit()
            }
        }
        .widgetCurvesContent()
        .widgetLabel { Text(entry.nextPrayerName) }
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
