//
//  LiveActivityViews.swift
//  PrayerEaseWidget
//
//  Created by Alisultan Abdullah on 12/21/25.
//

import ActivityKit
import SwiftUI
import WidgetKit

// MARK: - Lock Screen Live Activity View

struct LockScreenLiveActivityView: View {
    let context: ActivityViewContext<PrayerEaseWidgetAttributes>

    var currentPrayerName: String {
        let prayers = context.state.allPrayerTimes
        guard let index = prayers.firstIndex(where: { $0.name == context.state.nextPrayerName })
        else { return "Fajr" }
        if index > 0 {
            return prayers[index - 1].name
        } else {
            return "Isha"
        }
    }

    var body: some View {
        VStack(spacing: 8) {
            // Replicating Expanded Island Layout
            HStack(alignment: .top) {
                ExpandedLeadingView(state: context.state)
                Spacer(minLength: 150)
                ExpandedTrailingView(state: context.state)
            }

            ExpandedBottomView(state: context.state)

        }
        .padding()
    }
}

// MARK: - Dynamic Island Expanded Views

struct ExpandedLeadingView: View {
    let state: PrayerEaseWidgetAttributes.ContentState

    var body: some View {
        HStack(alignment: .lastTextBaseline, spacing: 4) {
            Text(state.nextPrayerName + ":")
                .font(.subheadline)
                .foregroundStyle(accentGreen)

            Text("\(state.nextPrayerTime, format: .dateTime.hour().minute())")
                .font(.subheadline)
                .foregroundStyle(.primary)

        }
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .padding(.leading, 4)
    }
}

struct ExpandedTrailingView: View {
    let state: PrayerEaseWidgetAttributes.ContentState

    var body: some View {
        VStack(alignment: .trailing, spacing: 0) {
            Text(state.nextPrayerTime, style: .timer)
                .font(.title3.weight(.bold))
                .monospacedDigit()
                .foregroundStyle(.primary)
                .contentTransition(.numericText())
        }
    }
}

struct ExpandedBottomView: View {
    let state: PrayerEaseWidgetAttributes.ContentState

    var body: some View {
        VStack(spacing: 6) {
            // Location and Date Row
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .font(.caption2)

                    ViewThatFits(in: .horizontal) {
                        Text(state.locationName)
                            .font(.caption)

                        Text(
                            state.locationName.components(separatedBy: ",").first
                                ?? state.locationName
                        )
                        .font(.caption)

                        Text(
                            state.locationName.components(separatedBy: ",").first
                                ?? state.locationName
                        )
                        .font(.caption)
                        .minimumScaleFactor(0.8)
                    }
                }
                Spacer()
                Text(state.islamicDate)
                    .font(.caption)
            }
            .foregroundStyle(.secondary)
            .padding(.top, 4)

            // Progress Bar (Reducing)
            Gauge(value: 1.0 - state.progress) {
                EmptyView()
            } currentValueLabel: {
                EmptyView()
            } minimumValueLabel: {
                Text(state.previousPrayerTime ?? Date(), format: .dateTime.hour().minute())
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } maximumValueLabel: {
                Text(state.nextPrayerTime, format: .dateTime.hour().minute())
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .gaugeStyle(.linearCapacity)
            .tint(accentGreen)
            .padding(.bottom, 6)
        }
    }
}

// MARK: - Dynamic Island Compact Views

struct CompactLeadingView: View {
    let state: PrayerEaseWidgetAttributes.ContentState

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: "pray.circle.fill")
                .foregroundStyle(accentGreen)
            Text(state.nextPrayerName)
                .font(.caption)
                .bold()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct CompactTrailingView: View {
    let state: PrayerEaseWidgetAttributes.ContentState

    var body: some View {
        let now = Date()
        let interval = state.nextPrayerTime.timeIntervalSince(now)

        Group {
            if interval >= 3600 {
                let hours = Int(interval / 3600)
                Text("\(hours)h")
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(accentGreen)
            } else if interval >= 60 {
                let minutes = Int(interval / 60)
                Text("\(minutes)m")
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(accentGreen)
            } else {
                Text(state.nextPrayerTime, style: .timer)
                    .monospacedDigit()
                    .font(.footnote)
                    .bold()
                    .foregroundStyle(accentGreen)
                    .frame(maxWidth: 40)
            }
        }
        .gridColumnAlignment(.trailing)
    }
}

struct MinimalView: View {
    let state: PrayerEaseWidgetAttributes.ContentState

    var body: some View {
        let now = Date()
        let interval = state.nextPrayerTime.timeIntervalSince(now)

        ZStack {
            if interval >= 3600 {
                let hours = Int(interval / 3600)
                Text("\(hours)h")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(accentGreen)
            } else if interval >= 60 {
                let minutes = Int(interval / 60)
                Text("\(minutes)m")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(accentGreen)
            } else {
                Text(state.nextPrayerTime, style: .timer)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(accentGreen)
                    .monospacedDigit()
            }
        }
    }
}
