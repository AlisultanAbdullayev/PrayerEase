//
//  PrayerCountdownView.swift
//  PrayerEaseWatch Watch App
//
//  Shows countdown timer to next prayer
//

import SwiftUI

/// Countdown timer component showing time until next prayer
struct PrayerCountdownView: View {
    let nextPrayer: SharedPrayerTime?

    @State private var timeRemaining: TimeInterval = 0
    @State private var timer: Timer?

    var body: some View {
        VStack(spacing: 4) {
            // Next prayer label
            if let prayer = nextPrayer {
                HStack(spacing: 4) {
                    Text("\(prayer.name) at:")
                        .font(.caption)
                        .foregroundStyle(.green)

                    Text(prayer.timeString)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                }

                // Countdown timer
                Text(formattedCountdown)
                    .font(.title)
                    .bold()
                    .fontDesign(.rounded)
                    .monospacedDigit()
                    .contentTransition(.numericText())
            } else {
                Text("--:--:--")
                    .font(.title)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.accentColor.opacity(0.25), in: .rect(cornerRadius: 12))
        .glassCard()
        .onAppear {
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
        .onChange(of: nextPrayer?.time) { _, _ in
            updateTimeRemaining()
        }
    }

    private var formattedCountdown: String {
        guard timeRemaining > 0 else { return "00:00:00" }

        let hours = Int(timeRemaining) / 3600
        let minutes = (Int(timeRemaining) % 3600) / 60
        let seconds = Int(timeRemaining) % 60

        return String(format: "%d:%02d:%02d", hours, minutes, seconds)
    }

    private func startTimer() {
        updateTimeRemaining()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            updateTimeRemaining()
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func updateTimeRemaining() {
        guard let prayer = nextPrayer else {
            timeRemaining = 0
            return
        }

        let remaining = prayer.time.timeIntervalSince(Date())
        timeRemaining = max(0, remaining)
    }
}

#Preview {
    PrayerCountdownView(
        nextPrayer: SharedPrayerTime(
            name: "Fajr",
            time: Date().addingTimeInterval(3600 * 6 + 60 * 22 + 40)
        )
    )
}
