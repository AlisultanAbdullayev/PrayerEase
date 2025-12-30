//
//  WatchPrayerTimesView.swift
//  PrayerEaseWatch Watch App
//
//  Created by Antigravity on 12/23/25.
//

import SwiftUI

/// Prayer Times screen for watchOS
struct WatchPrayerTimesView: View {
    @StateObject private var viewModel = WatchPrayerTimesViewModel()
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
                viewModel.refresh()
            }
        }
    }

    // MARK: - View Components (SRP - Single Responsibility)

    private var locationHeader: some View {
        Text(viewModel.locationName.isEmpty ? "Prayers" : viewModel.locationName)
            .foregroundStyle(.secondary)
    }

    @ViewBuilder
    private var countdownSection: some View {
        if let nextPrayer = viewModel.nextPrayer {
            PrayerCountdownView(nextPrayer: nextPrayer) {
                viewModel.refresh()
            }
            .padding(.bottom)
        }
    }

    @ViewBuilder
    private var prayersList: some View {
        if !viewModel.standardPrayers.isEmpty {
            VStack(spacing: 2) {
                ForEach(viewModel.standardPrayers) { prayer in
                    PrayerRowView(
                        prayer: prayer,
                        isCurrent: viewModel.isCurrent(prayer: prayer)
                    )
                }
            }
        }
    }

    @ViewBuilder
    private var optionalPrayersSection: some View {
        if !viewModel.optionalPrayers.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                Text("Optional")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)

                VStack(spacing: 2) {
                    ForEach(viewModel.optionalPrayers) { prayer in
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
        if viewModel.standardPrayers.isEmpty {
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
}
