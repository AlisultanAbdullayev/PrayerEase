//
//  WatchPrayerTimesView.swift
//  PrayerEaseWatch Watch App
//
//  Created by Antigravity on 12/23/25.
//

import SwiftUI

/// Prayer Times screen for watchOS
struct WatchPrayerTimesView: View {
    @Environment(WatchDataManager.self) private var dataManager
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 4) {
                WatchLocationHeaderView(locationName: dataManager.locationName)
                WatchCountdownSection(nextPrayer: dataManager.nextPrayer) {
                    dataManager.refresh()
                }
                WatchPrayersListSection(
                    prayers: dataManager.prayerTimes,
                    isCurrent: { prayer in
                        dataManager.isCurrent(prayer: prayer)
                    }
                )
                WatchOptionalPrayersSection(optionalPrayers: dataManager.optionalPrayers)
                WatchPrayerTimesEmptyStateView(isEmpty: dataManager.prayerTimes.isEmpty)
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                dataManager.refresh()
            }
        }
    }

}

// MARK: - View Components

private struct WatchLocationHeaderView: View {
    let locationName: String

    var body: some View {
        Text(locationName.isEmpty ? "Prayers" : locationName)
            .foregroundStyle(.secondary)
    }
}

private struct WatchCountdownSection: View {
    let nextPrayer: SharedPrayerTime?
    let onPrayerTimeReached: () -> Void

    var body: some View {
        if let nextPrayer {
            PrayerCountdownView(nextPrayer: nextPrayer) {
                onPrayerTimeReached()
            }
            .padding(.bottom)
        }
    }
}

private struct WatchPrayersListSection: View {
    let prayers: [SharedPrayerTime]
    let isCurrent: (SharedPrayerTime) -> Bool

    var body: some View {
        if !prayers.isEmpty {
            VStack(spacing: 2) {
                ForEach(prayers) { prayer in
                    PrayerRowView(
                        prayer: prayer,
                        isCurrent: isCurrent(prayer)
                    )
                }
            }
        }
    }
}

private struct WatchOptionalPrayersSection: View {
    let optionalPrayers: [SharedPrayerTime]

    var body: some View {
        if !optionalPrayers.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                Text("Optional")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)

                VStack(spacing: 2) {
                    ForEach(optionalPrayers) { prayer in
                        PrayerRowView(
                            prayer: prayer,
                            isCurrent: false
                        )
                    }
                }
            }
        }
    }
}

private struct WatchPrayerTimesEmptyStateView: View {
    let isEmpty: Bool

    var body: some View {
        if isEmpty {
            ContentUnavailableView(
                "No Prayer Data",
                systemImage: "clock.badge.exclamationmark",
                description: Text("Open iOS app first")
            )
        }
    }
}

#Preview {
    WatchPrayerTimesView()
        .environment(WatchDataManager.shared)
}
