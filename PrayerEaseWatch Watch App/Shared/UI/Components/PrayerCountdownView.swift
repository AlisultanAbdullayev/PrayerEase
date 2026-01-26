//
//  PrayerCountdownView.swift
//  PrayerEaseWatch Watch App
//
//  Shows countdown timer to next prayer
//

import SwiftUI

/// Countdown timer component showing time until next prayer
/// Uses TimelineView for efficient, automatic updates (modern SwiftUI pattern)
struct PrayerCountdownView: View {
    let nextPrayer: SharedPrayerTime?
    var onPrayerTimeReached: (() -> Void)?

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            CountdownContent(
                nextPrayer: nextPrayer,
                currentDate: context.date,
                onPrayerTimeReached: onPrayerTimeReached
            )
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.accentColor.opacity(0.25), in: .rect(cornerRadius: 12))
        .glassCard()
    }
}

// MARK: - Private Subview (SRP - Single Responsibility)

/// Extracted content view for countdown display
private struct CountdownContent: View {
    let nextPrayer: SharedPrayerTime?
    let currentDate: Date
    var onPrayerTimeReached: (() -> Void)?

    var body: some View {
        VStack(spacing: 4) {
            if let prayer = nextPrayer {
                CountdownHeaderView(prayer: prayer)
                CountdownTimerView(prayerTime: prayer.time, currentDate: currentDate)
            } else {
                CountdownPlaceholderView()
            }
        }
        .onChange(of: hasReachedPrayerTime) { _, reached in
            if reached {
                onPrayerTimeReached?()
            }
        }
    }

    // MARK: - Computed Properties

    private var hasReachedPrayerTime: Bool {
        guard let prayer = nextPrayer else { return false }
        return currentDate >= prayer.time
    }
}

// MARK: - View Components

private struct CountdownHeaderView: View {
    let prayer: SharedPrayerTime

    var body: some View {
        HStack(spacing: 4) {
            Text("\(prayer.name) at:")
                .font(.caption)
                .foregroundStyle(.green)

            Text(prayer.timeString)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
        }
    }
}

private struct CountdownTimerView: View {
    let prayerTime: Date
    let currentDate: Date

    var body: some View {
        Group {
            if currentDate >= prayerTime {
                Text("00:00")
            } else {
                Text(prayerTime, style: .timer)
            }
        }
        .font(.title)
        .bold()
        .fontDesign(.rounded)
        .monospacedDigit()
        .contentTransition(.numericText())
    }
}

private struct CountdownPlaceholderView: View {
    var body: some View {
        Text("--:--:--")
            .font(.title)
            .foregroundStyle(.secondary)
    }
}

#Preview {
    PrayerCountdownView(
        nextPrayer: SharedPrayerTime(
            name: PrayerNames.fajr,
            time: Date().addingTimeInterval(
                TimeIntervals.oneHour * 6 + TimeIntervals.oneMinute * 22 + 40)
        )
    )
}
