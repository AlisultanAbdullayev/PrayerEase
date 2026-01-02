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
                headerView(for: prayer)
                countdownText
            } else {
                placeholderText
            }
        }
        .onChange(of: hasReachedPrayerTime) { _, reached in
            if reached {
                onPrayerTimeReached?()
            }
        }
    }

    // MARK: - Computed Properties

    private var timeRemaining: TimeInterval {
        guard let prayer = nextPrayer else { return 0 }
        return max(0, prayer.time.timeIntervalSince(currentDate))
    }

    private var hasReachedPrayerTime: Bool {
        guard let prayer = nextPrayer else { return false }
        return currentDate >= prayer.time
    }

    private var formattedCountdown: String {
        guard timeRemaining > 0 else { return "00:00" }

        let totalSeconds = Int(timeRemaining)
        let hours = Int(totalSeconds / Int(TimeIntervals.oneHour))
        let minutes = (totalSeconds % Int(TimeIntervals.oneHour)) / 60
        let seconds = totalSeconds % 60

        // KISS: Simple conditional formatting
        return hours > 0
            ? String(format: "%d:%02d:%02d", hours, minutes, seconds)
            : String(format: "%02d:%02d", minutes, seconds)
    }

    // MARK: - View Components (DRY - extracted for reuse)

    @ViewBuilder
    private func headerView(for prayer: SharedPrayerTime) -> some View {
        HStack(spacing: 4) {
            Text("\(prayer.name) at:")
                .font(.caption)
                .foregroundStyle(.green)

            Text(prayer.timeString)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
        }
    }

    private var countdownText: some View {
        Text(formattedCountdown)
            .font(.title)
            .bold()
            .fontDesign(.rounded)
            .monospacedDigit()
            .contentTransition(.numericText())
    }

    private var placeholderText: some View {
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
