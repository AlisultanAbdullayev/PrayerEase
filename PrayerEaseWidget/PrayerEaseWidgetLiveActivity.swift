//
//  PrayerEaseWidgetLiveActivity.swift
//  PrayerEaseWidget
//
//  Created by Alisultan Abdullah on 12/21/25.
//

import ActivityKit
import SwiftUI
import WidgetKit

// MARK: - Live Activity Attributes

// App accent color - green theme
private let accentGreen = Color(red: 0.2, green: 0.8, blue: 0.4)

// Note: This type must match PrayerEaseWidgetAttributes in the main app's WidgetDataManager
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

// Note: This type must match LiveActivityPrayerTimeData in the main app's WidgetDataManager
struct LiveActivityPrayerTime: Codable, Hashable, Identifiable {
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

// Type alias to match main app naming
typealias LiveActivityPrayerTimeData = LiveActivityPrayerTime

// MARK: - Live Activity Widget

struct PrayerEaseWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PrayerEaseWidgetAttributes.self) { context in
            // Lock Screen / Banner View
            LockScreenLiveActivityView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded Regions
                DynamicIslandExpandedRegion(.leading) {
                    ExpandedLeadingView(state: context.state)
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    ExpandedTrailingView(state: context.state)
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    ExpandedBottomView(state: context.state)
                }
                
                DynamicIslandExpandedRegion(.center) {
                    ExpandedCenterView(state: context.state)
                }
            } compactLeading: {
                CompactLeadingView(state: context.state)
            } compactTrailing: {
                CompactTrailingView(state: context.state)
            } minimal: {
                MinimalView(state: context.state)
            }
            .widgetURL(URL(string: "prayerease://prayer/\(context.state.nextPrayerName.lowercased())"))
            .keylineTint(accentGreen)
        }
    }
}

// MARK: - Lock Screen Live Activity View

struct LockScreenLiveActivityView: View {
    let context: ActivityViewContext<PrayerEaseWidgetAttributes>
    
    var body: some View {
        VStack(spacing: 12) {
            // Header Row
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    // Prayer name and time on same line
                    HStack(spacing: 8) {
                        Text(context.state.nextPrayerName)
                            .font(.title2)
                            .foregroundStyle(.primary)
                        Text(":")
                        Text(context.state.nextPrayerTime, format: .dateTime.hour().minute())
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                    
                    // Countdown Timer
                    Text(context.state.nextPrayerTime, style: .timer)
                        .font(.title)
                        .bold()
                        .monospacedDigit()
                        .foregroundStyle(.primary)
                        .contentTransition(.numericText())
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(context.state.locationName)
                        .foregroundStyle(.primary)
                    
                    Text(context.state.islamicDate)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Prayer Times Row
            if !context.state.allPrayerTimes.isEmpty {
                HStack(spacing: 4) {
                    ForEach(context.state.allPrayerTimes) { prayer in
                        LiveActivityPrayerCell(
                            prayer: prayer,
                            isActive: prayer.name == context.state.nextPrayerName
                        )
                    }
                }
            }
        }
        .padding()
//        .liveActivityBackground()
    }
}

struct LiveActivityPrayerCell: View {
    let prayer: LiveActivityPrayerTime
    let isActive: Bool
    
    var body: some View {
        VStack(spacing: 3) {
            Text(prayer.name)
                .font(.system(size: 10, weight: .medium))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            Image(systemName: prayer.iconName)
                .font(.system(size: 12))
                .symbolRenderingMode(.hierarchical)
            
            Text(prayer.time, format: .dateTime.hour().minute())
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .lineLimit(1)
        }
        .foregroundStyle(isActive ? .white : .secondary)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(isActive ? accentGreen : .white.opacity(0.08))
        }
    }
}

// MARK: - Dynamic Island Expanded Views

struct ExpandedLeadingView: View {
    let state: PrayerEaseWidgetAttributes.ContentState
    
    var body: some View {
        HStack {
            Text(state.nextPrayerName)
                .font(.headline.weight(.bold))
                .foregroundStyle(.primary)
            Text(state.nextPrayerTime, format: .dateTime.hour().minute())
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.leading, 4)
    }
}

struct ExpandedTrailingView: View {
    let state: PrayerEaseWidgetAttributes.ContentState
    
    var body: some View {
        VStack(alignment: .trailing) {
            Text(state.nextPrayerTime, style: .timer)
                .font(.title3.weight(.bold).monospacedDigit())
                .foregroundStyle(.primary)
                .contentTransition(.numericText())
            
            Text("at \(state.nextPrayerTime, format: .dateTime.hour().minute())")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
//        .padding(.trailing, 4)
    }
}

struct ExpandedCenterView: View {
    let state: PrayerEaseWidgetAttributes.ContentState
    
    var body: some View {
        EmptyView()
    }
}

struct ExpandedBottomView: View {
    let state: PrayerEaseWidgetAttributes.ContentState
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .font(.caption2)
                    Text(state.locationName)
                        .font(.caption)
                }
                
                Spacer()
                
                Text(state.islamicDate)
                    .font(.caption)
            }
            .foregroundStyle(.secondary)
            
            if !state.allPrayerTimes.isEmpty {
                HStack(spacing: 0) {
                    ForEach(state.allPrayerTimes) { prayer in
                        DynamicIslandPrayerCell(
                            prayer: prayer,
                            isActive: prayer.name == state.nextPrayerName
                        )
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }
}

struct DynamicIslandPrayerCell: View {
    let prayer: LiveActivityPrayerTime
    let isActive: Bool
    
    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: prayer.iconName)
                .font(.footnote)
                .symbolRenderingMode(.hierarchical)
            
            Text(prayer.time, format: .dateTime.hour().minute())
                .font(.footnote)
        }
        .foregroundStyle(isActive ? accentGreen : .secondary)
        .padding(.vertical, 4)
    }
}

// MARK: - Dynamic Island Compact Views

struct CompactLeadingView: View {
    let state: PrayerEaseWidgetAttributes.ContentState
    
    var body: some View {
        HStack(spacing: 4) {
            Text(state.nextPrayerName)
                .foregroundStyle(.primary)
        }

    }
}

struct CompactTrailingView: View {
    let state: PrayerEaseWidgetAttributes.ContentState
    
    var body: some View {
        HStack(spacing: 6) {
            // Timer
            Text(state.nextPrayerTime, style: .timer)
                .foregroundStyle(.primary)
                .contentTransition(.numericText())
        }
    }
}

struct CompactProgressBar: View {
    let progress: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                Capsule()
                    .fill(Color.white.opacity(0.2))
                
                // Progress fill with green accent
                Capsule()
                    .fill(accentGreen)
                    .frame(width: geometry.size.width * min(max(progress, 0.05), 1.0))
            }
        }
    }
}

struct MinimalView: View {
    let state: PrayerEaseWidgetAttributes.ContentState
    
    var body: some View {
        ZStack {
            // Circular progress
            Circle()
                .stroke(Color.white.opacity(0.2), lineWidth: 2)
            
            Circle()
                .trim(from: 0, to: state.progress)
                .stroke(accentGreen, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .rotationEffect(.degrees(-90))
            
            Text(state.nextPrayerName.prefix(1))
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.primary)
        }
    }
}

// MARK: - Live Activity Background Modifier

extension View {
    @ViewBuilder
    func liveActivityBackground() -> some View {
        if #available(iOS 26.0, *) {
            self.background { Color.clear.glassEffect() }
        } else {
            self.background(.ultraThinMaterial)
        }
    }
}

// MARK: - Preview Data

extension PrayerEaseWidgetAttributes {
    static var preview: PrayerEaseWidgetAttributes {
        PrayerEaseWidgetAttributes(activityName: "Prayer Tracker")
    }
}

extension PrayerEaseWidgetAttributes.ContentState {
    static var previewFajr: PrayerEaseWidgetAttributes.ContentState {
        let now = Date()
        let calendar = Calendar.current
        
        return PrayerEaseWidgetAttributes.ContentState(
            nextPrayerName: "Fajr",
            nextPrayerTime: calendar.date(bySettingHour: 6, minute: 3, second: 0, of: now)!,
            locationName: "Richmond",
            islamicDate: "29 Jumada-Al-Thani, 1447",
            allPrayerTimes: [
                LiveActivityPrayerTimeData(name: "Fajr", time: calendar.date(bySettingHour: 6, minute: 3, second: 0, of: now)!),
                LiveActivityPrayerTimeData(name: "Sunrise", time: calendar.date(bySettingHour: 7, minute: 13, second: 0, of: now)!),
                LiveActivityPrayerTimeData(name: "Dhuhr", time: calendar.date(bySettingHour: 12, minute: 21, second: 0, of: now)!),
                LiveActivityPrayerTimeData(name: "Asr", time: calendar.date(bySettingHour: 15, minute: 10, second: 0, of: now)!),
                LiveActivityPrayerTimeData(name: "Maghrib", time: calendar.date(bySettingHour: 17, minute: 28, second: 0, of: now)!),
                LiveActivityPrayerTimeData(name: "Isha", time: calendar.date(bySettingHour: 18, minute: 39, second: 0, of: now)!)
            ],
            previousPrayerTime: calendar.date(byAdding: .hour, value: -2, to: now)
        )
    }
    
    static var previewIsha: PrayerEaseWidgetAttributes.ContentState {
        let now = Date()
        let calendar = Calendar.current
        
        return PrayerEaseWidgetAttributes.ContentState(
            nextPrayerName: "Isha",
            nextPrayerTime: calendar.date(bySettingHour: 18, minute: 39, second: 0, of: now)!,
            locationName: "Dubai",
            islamicDate: "15 Ramadan, 1447",
            allPrayerTimes: [
                LiveActivityPrayerTimeData(name: "Fajr", time: calendar.date(bySettingHour: 5, minute: 15, second: 0, of: now)!),
                LiveActivityPrayerTimeData(name: "Sunrise", time: calendar.date(bySettingHour: 6, minute: 30, second: 0, of: now)!),
                LiveActivityPrayerTimeData(name: "Dhuhr", time: calendar.date(bySettingHour: 12, minute: 15, second: 0, of: now)!),
                LiveActivityPrayerTimeData(name: "Asr", time: calendar.date(bySettingHour: 15, minute: 45, second: 0, of: now)!),
                LiveActivityPrayerTimeData(name: "Maghrib", time: calendar.date(bySettingHour: 18, minute: 5, second: 0, of: now)!),
                LiveActivityPrayerTimeData(name: "Isha", time: calendar.date(bySettingHour: 19, minute: 30, second: 0, of: now)!)
            ],
            previousPrayerTime: calendar.date(bySettingHour: 18, minute: 5, second: 0, of: now)
        )
    }
}

// MARK: - Previews

#Preview("Live Activity - Lock Screen", as: .content, using: PrayerEaseWidgetAttributes.preview) {
    PrayerEaseWidgetLiveActivity()
} contentStates: {
    PrayerEaseWidgetAttributes.ContentState.previewFajr
    PrayerEaseWidgetAttributes.ContentState.previewIsha
}

#Preview("Dynamic Island - Expanded", as: .dynamicIsland(.expanded), using: PrayerEaseWidgetAttributes.preview) {
    PrayerEaseWidgetLiveActivity()
} contentStates: {
    PrayerEaseWidgetAttributes.ContentState.previewFajr
}

#Preview("Dynamic Island - Compact", as: .dynamicIsland(.compact), using: PrayerEaseWidgetAttributes.preview) {
    PrayerEaseWidgetLiveActivity()
} contentStates: {
    PrayerEaseWidgetAttributes.ContentState.previewFajr
}

#Preview("Dynamic Island - Minimal", as: .dynamicIsland(.minimal), using: PrayerEaseWidgetAttributes.preview) {
    PrayerEaseWidgetLiveActivity()
} contentStates: {
    PrayerEaseWidgetAttributes.ContentState.previewFajr
}
