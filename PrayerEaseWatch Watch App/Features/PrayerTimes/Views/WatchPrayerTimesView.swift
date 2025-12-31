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
                locationHeader
                countdownSection
                prayersList
                optionalPrayersSection
                emptyStateView
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                dataManager.refresh()
            }
        }
    }

    // MARK: - View Components

    private var locationHeader: some View {
        Text(dataManager.locationName.isEmpty ? "Prayers" : dataManager.locationName)
            .foregroundStyle(.secondary)
    }

    @ViewBuilder
    private var countdownSection: some View {
        if let nextPrayer = dataManager.nextPrayer {
            PrayerCountdownView(nextPrayer: nextPrayer) {
                dataManager.refresh()
            }
            .padding(.bottom)
        }
    }

    @ViewBuilder
    private var prayersList: some View {
        if !dataManager.prayerTimes.isEmpty {
            VStack(spacing: 2) {
                ForEach(dataManager.prayerTimes) { prayer in
                    PrayerRowView(
                        prayer: prayer,
                        isCurrent: dataManager.isCurrent(prayer: prayer)
                    )
                }
            }
        }
    }

    @ViewBuilder
    private var optionalPrayersSection: some View {
        if !dataManager.optionalPrayers.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                Text("Optional")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)

                VStack(spacing: 2) {
                    ForEach(dataManager.optionalPrayers) { prayer in
                        PrayerRowView(
                            prayer: prayer,
                            isCurrent: false
                        )
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var emptyStateView: some View {
        if dataManager.prayerTimes.isEmpty {
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
