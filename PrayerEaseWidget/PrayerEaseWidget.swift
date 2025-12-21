//
//  PrayerEaseWidget.swift
//  PrayerEaseWidget
//
//  Created by Alisultan Abdullah on 12/21/25.
//

import SwiftUI
import WidgetKit

// MARK: - Data Models

struct WidgetPrayerTime: Identifiable, Equatable, Codable {
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

struct PrayerWidgetEntry: TimelineEntry {
    let date: Date
    let nextPrayerName: String
    let nextPrayerTime: Date
    let locationName: String
    let prayerTimes: [WidgetPrayerTime]
    let islamicDate: String
    
    static var placeholder: PrayerWidgetEntry {
        let now = Date()
        let calendar = Calendar.current
        let prayerTimes = [
            WidgetPrayerTime(name: "Fajr", time: calendar.date(bySettingHour: 6, minute: 3, second: 0, of: now)!),
            WidgetPrayerTime(name: "Sunrise", time: calendar.date(bySettingHour: 7, minute: 13, second: 0, of: now)!),
            WidgetPrayerTime(name: "Dhuhr", time: calendar.date(bySettingHour: 12, minute: 21, second: 0, of: now)!),
            WidgetPrayerTime(name: "Asr", time: calendar.date(bySettingHour: 15, minute: 10, second: 0, of: now)!),
            WidgetPrayerTime(name: "Maghrib", time: calendar.date(bySettingHour: 17, minute: 28, second: 0, of: now)!),
            WidgetPrayerTime(name: "Isha", time: calendar.date(bySettingHour: 18, minute: 39, second: 0, of: now)!)
        ]
        return PrayerWidgetEntry(
            date: now,
            nextPrayerName: "Isha",
            nextPrayerTime: prayerTimes[5].time,
            locationName: "Richmond",
            prayerTimes: prayerTimes,
            islamicDate: "29 Jumada-Al-Thani, 1447"
        )
    }
}

// MARK: - Timeline Provider

struct PrayerTimelineProvider: TimelineProvider {
    private static let appGroupId = "group.com.alijaver.PrayerEase"
    
    private var userDefaults: UserDefaults? {
        UserDefaults(suiteName: Self.appGroupId)
    }
    
    func placeholder(in context: Context) -> PrayerWidgetEntry {
        .placeholder
    }
    
    func getSnapshot(in context: Context, completion: @escaping (PrayerWidgetEntry) -> Void) {
        completion(loadEntry(for: Date()))
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<PrayerWidgetEntry>) -> Void) {
        let now = Date()
        var entries: [PrayerWidgetEntry] = []
        let calendar = Calendar.current
        
        for minuteOffset in stride(from: 0, to: 240, by: 1) {
            guard let entryDate = calendar.date(byAdding: .minute, value: minuteOffset, to: now) else { continue }
            entries.append(loadEntry(for: entryDate))
        }
        
        let refreshDate = calendar.date(byAdding: .hour, value: 4, to: now) ?? now
        let timeline = Timeline(entries: entries, policy: .after(refreshDate))
        completion(timeline)
    }
    
    private func loadEntry(for date: Date) -> PrayerWidgetEntry {
        let prayerTimes = loadPrayerTimes(for: date)
        let locationName = loadLocationName()
        let islamicDate = loadIslamicDate(for: date)
        let nextPrayer = findNextPrayer(from: date, prayerTimes: prayerTimes)
        
        return PrayerWidgetEntry(
            date: date,
            nextPrayerName: nextPrayer.name,
            nextPrayerTime: nextPrayer.time,
            locationName: locationName,
            prayerTimes: prayerTimes,
            islamicDate: islamicDate
        )
    }
    
    private func loadPrayerTimes(for date: Date) -> [WidgetPrayerTime] {
        guard let defaults = userDefaults else {
            print("Widget: No userDefaults available")
            return Self.mockPrayerTimes(for: date)
        }
        
        guard let data = defaults.data(forKey: "widgetPrayerTimes") else {
            print("Widget: No widgetPrayerTimes data found")
            return Self.mockPrayerTimes(for: date)
        }
        
        guard let decoded = try? JSONDecoder().decode([WidgetPrayerTime].self, from: data),
              !decoded.isEmpty else {
            print("Widget: Failed to decode prayer times")
            return Self.mockPrayerTimes(for: date)
        }
        
        print("Widget: Loaded \(decoded.count) prayer times from shared data")
        
        // Check if the stored times are for today
        let calendar = Calendar.current
        if let firstTime = decoded.first?.time,
           calendar.isDate(firstTime, inSameDayAs: date) {
            return decoded
        }
        
        print("Widget: Stored times not for today, using mock")
        // If stored times are for a different day, use mock data adjusted for the requested date
        return Self.mockPrayerTimes(for: date)
    }
    
    private func loadLocationName() -> String {
        let name = userDefaults?.string(forKey: "locationName")
        print("Widget: Loaded location name: '\(name ?? "nil")'")
        return name ?? "Loading..."
    }
    
    private func loadIslamicDate(for date: Date) -> String {
        let hijriCalendar = Calendar(identifier: .islamicUmmAlQura)
        let formatter = DateFormatter()
        formatter.calendar = hijriCalendar
        formatter.dateFormat = "d MMMM, yyyy"
        return formatter.string(from: date)
    }
    
    private func findNextPrayer(from date: Date, prayerTimes: [WidgetPrayerTime]) -> (name: String, time: Date) {
        let upcoming = prayerTimes.filter { $0.time > date }
        if let next = upcoming.first {
            return (next.name, next.time)
        }
        
        if let first = prayerTimes.first {
            let calendar = Calendar.current
            if let tomorrow = calendar.date(byAdding: .day, value: 1, to: first.time) {
                return (first.name, tomorrow)
            }
        }
        
        return ("Fajr", date)
    }
    
    private static func mockPrayerTimes(for date: Date) -> [WidgetPrayerTime] {
        let calendar = Calendar.current
        return [
            WidgetPrayerTime(name: "Fajr", time: calendar.date(bySettingHour: 6, minute: 3, second: 0, of: date)!),
            WidgetPrayerTime(name: "Sunrise", time: calendar.date(bySettingHour: 7, minute: 13, second: 0, of: date)!),
            WidgetPrayerTime(name: "Dhuhr", time: calendar.date(bySettingHour: 12, minute: 21, second: 0, of: date)!),
            WidgetPrayerTime(name: "Asr", time: calendar.date(bySettingHour: 15, minute: 10, second: 0, of: date)!),
            WidgetPrayerTime(name: "Maghrib", time: calendar.date(bySettingHour: 17, minute: 28, second: 0, of: date)!),
            WidgetPrayerTime(name: "Isha", time: calendar.date(bySettingHour: 18, minute: 39, second: 0, of: date)!)
        ]
    }
}

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
            // Header
            Text("NEXT")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Color.accentColor)
                .tracking(0.5)
            
            // Prayer Name
            Text(entry.nextPrayerName)
                .font(.title2)
                .foregroundStyle(.primary)
                .padding(.top, 2)
            
            // Time
            Text("at \(entry.nextPrayerTime, format: .dateTime.hour().minute())")
                .font(.body)
                .foregroundStyle(.secondary)
                .padding(.top, 1)
            
            Spacer(minLength: 8)
            
            // Countdown
            Text(entry.nextPrayerTime, style: .timer)
                .font(.title)
                .foregroundStyle(.primary)
                .contentTransition(.numericText())

            Spacer(minLength: 6)
            
            // Location
            HStack(spacing: 3) {
                Image(systemName: "location.fill")
                    .font(.system(size: 10))
                Text(entry.locationName)
                    .font(.system(size: 12))
                    .lineLimit(1)
            }
            .foregroundStyle(.secondary)
        }
        .padding()
        .widgetBackground()
    }
}

// MARK: - Medium Widget

struct MediumWidgetView: View {
    let entry: PrayerWidgetEntry
    
    var body: some View {
        VStack(spacing: 0) {
            // Top Section
            HStack(alignment: .top, spacing: 0) {
                // Left: Prayer Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.nextPrayerName)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.primary)
                    
                    Text(entry.nextPrayerTime, style: .timer)
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.primary)
                        .minimumScaleFactor(0.7)
                        .contentTransition(.numericText())
                }
                
                Spacer(minLength: 16)
                
                // Right: Location & Date
                VStack(alignment: .trailing, spacing: 4) {
                    Text(entry.locationName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    
                    Text(entry.islamicDate)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer(minLength: 12)
            
            // Prayer Times Row
            PrayerTimesRowView(
                prayerTimes: entry.prayerTimes,
                currentPrayer: entry.nextPrayerName
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 12)
        .widgetBackground()
    }
}

// MARK: - Large Widget

struct LargeWidgetView: View {
    let entry: PrayerWidgetEntry
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 11))
                        Text(entry.locationName)
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundStyle(.secondary)
                    
                    Text(entry.islamicDate)
                        .font(.system(size: 13))
                        .foregroundStyle(.tertiary)
                }
                
                Spacer()
            }
            .padding(.bottom, 12)
            
            Divider()
                .opacity(0.3)
            
            Spacer(minLength: 16)
            
            // Next Prayer Section
            VStack(spacing: 6) {
                Text("NEXT PRAYER")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.orange)
                    .tracking(1.2)
                
                Text(entry.nextPrayerName)
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                
                Text("at \(entry.nextPrayerTime, format: .dateTime.hour().minute())")
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
                
                Text(entry.nextPrayerTime, style: .timer)
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.primary)
                    .minimumScaleFactor(0.7)
                    .contentTransition(.numericText())
                    .padding(.top, 4)
            }
            
            Spacer(minLength: 16)
            
            // Prayer Times List
            VStack(spacing: 6) {
                ForEach(entry.prayerTimes) { prayer in
                    PrayerTimeDetailRow(
                        prayer: prayer,
                        isNext: prayer.name == entry.nextPrayerName
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(18)
        .widgetBackground()
    }
}

// MARK: - Extra Large Widget (iPad)

struct ExtraLargeWidgetView: View {
    let entry: PrayerWidgetEntry
    
    var body: some View {
        HStack(spacing: 0) {
            // Left: Next Prayer
            VStack(spacing: 10) {
                Text("NEXT PRAYER")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.orange)
                    .tracking(1.2)
                
                Text(entry.nextPrayerName)
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                
                Text(entry.nextPrayerTime, style: .timer)
                    .font(.system(size: 58, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.primary)
                    .minimumScaleFactor(0.7)
                    .contentTransition(.numericText())
                
                Spacer()
                
                VStack(spacing: 3) {
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 12))
                        Text(entry.locationName)
                            .font(.system(size: 15, weight: .medium))
                    }
                    
                    Text(entry.islamicDate)
                        .font(.system(size: 13))
                }
                .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.trailing, 20)
            
            Divider()
                .opacity(0.3)
            
            // Right: All Prayers
            VStack(alignment: .leading, spacing: 6) {
                Text("TODAY'S PRAYERS")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .tracking(1)
                    .padding(.bottom, 4)
                
                ForEach(entry.prayerTimes) { prayer in
                    PrayerTimeDetailRow(
                        prayer: prayer,
                        isNext: prayer.name == entry.nextPrayerName
                    )
                }
                
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .padding(.leading, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(22)
        .widgetBackground()
    }
}

// MARK: - Accessory Widgets (Lock Screen)

struct AccessoryCircularView: View {
    let entry: PrayerWidgetEntry
    
    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            
            VStack(spacing: 0) {
                Text(entry.nextPrayerName.prefix(3).uppercased())
                    .font(.system(size: 10, weight: .bold))
                
                Text(entry.nextPrayerTime, format: .dateTime.hour().minute())
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .monospacedDigit()
            }
        }
    }
}

struct AccessoryRectangularView: View {
    let entry: PrayerWidgetEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            // Prayer name and time on same line
            HStack(spacing: 6) {
                Text(entry.nextPrayerName)
                    .font(.system(size: 15, weight: .semibold))
                
                Text(entry.nextPrayerTime, format: .dateTime.hour().minute())
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            
            // Countdown
            Text(entry.nextPrayerTime, style: .timer)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .monospacedDigit()
            
            // Location below
            HStack(spacing: 3) {
                Image(systemName: "location.fill")
                    .font(.system(size: 9))
                Text(entry.locationName)
                    .font(.system(size: 11))
                    .lineLimit(1)
            }
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct AccessoryInlineView: View {
    let entry: PrayerWidgetEntry
    
    var body: some View {
        HStack(spacing: 4) {
            Text(entry.nextPrayerName)
            Text("at")
                .foregroundStyle(.secondary)
            Text(entry.nextPrayerTime, format: .dateTime.hour().minute())
        }
    }
}

// MARK: - Shared Components

struct PrayerTimesRowView: View {
    let prayerTimes: [WidgetPrayerTime]
    let currentPrayer: String
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(prayerTimes) { prayer in
                PrayerTimeCell(
                    prayer: prayer,
                    isActive: prayer.name == currentPrayer
                )
            }
        }
    }
}

struct PrayerTimeCell: View {
    let prayer: WidgetPrayerTime
    let isActive: Bool
    
    var body: some View {
        VStack(spacing: 3) {
            Text(prayer.name)
                .font(.system(size: 10, weight: .medium))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            Image(systemName: prayer.iconName)
                .font(.system(size: 14))
                .symbolRenderingMode(.hierarchical)
            
            Text(prayer.time, format: .dateTime.hour().minute())
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .lineLimit(1)
        }
        .foregroundStyle(isActive ? .white : .secondary)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .padding(.horizontal, 2)
        .background {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(isActive ? .blue : .white.opacity(0.08))
        }
    }
}

struct PrayerTimeDetailRow: View {
    let prayer: WidgetPrayerTime
    let isNext: Bool
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: prayer.iconName)
                .font(.system(size: 14))
                .frame(width: 20)
                .symbolRenderingMode(.hierarchical)
            
            Text(prayer.name)
                .font(.system(size: 15, weight: isNext ? .semibold : .regular))
            
            Spacer()
            
            Text(prayer.time, format: .dateTime.hour().minute())
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .monospacedDigit()
        }
        .foregroundStyle(isNext ? .primary : .secondary)
        .padding(.vertical, 7)
        .padding(.horizontal, 12)
        .background {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(isNext ? .blue.opacity(0.2) : .clear)
        }
    }
}

// MARK: - Background Modifier

extension View {
    @ViewBuilder
    func widgetBackground() -> some View {
        self.containerBackground(.ultraThinMaterial, for: .widget)
    }
}

// MARK: - Widget Configuration

struct PrayerEaseWidget: Widget {
    let kind: String = "PrayerEaseWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayerTimelineProvider()) { entry in
            PrayerEaseWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Prayer Times")
        .description("Shows the next prayer time with countdown, location, and daily prayer schedule.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .systemLarge,
            .systemExtraLarge,
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline
        ])
        .contentMarginsDisabled()
    }
}

// MARK: - Previews

#Preview("Small Widget", as: .systemSmall) {
    PrayerEaseWidget()
} timeline: {
    PrayerWidgetEntry.placeholder
}

#Preview("Medium Widget", as: .systemMedium) {
    PrayerEaseWidget()
} timeline: {
    PrayerWidgetEntry.placeholder
}

#Preview("Large Widget", as: .systemLarge) {
    PrayerEaseWidget()
} timeline: {
    PrayerWidgetEntry.placeholder
}

#Preview("Accessory Circular", as: .accessoryCircular) {
    PrayerEaseWidget()
} timeline: {
    PrayerWidgetEntry.placeholder
}

#Preview("Accessory Rectangular", as: .accessoryRectangular) {
    PrayerEaseWidget()
} timeline: {
    PrayerWidgetEntry.placeholder
}
