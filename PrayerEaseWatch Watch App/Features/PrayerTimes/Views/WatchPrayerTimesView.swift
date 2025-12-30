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

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.locationName.isEmpty ? "Prayers" : viewModel.locationName)
                    .foregroundStyle(.secondary)
                // Countdown timer section
                if let nextPrayer = viewModel.nextPrayer {
                    PrayerCountdownView(nextPrayer: nextPrayer) {
                        // When countdown reaches 0, refresh to get next prayer
                        viewModel.refresh()
                    }
                    .padding(.bottom)
                }

                // Prayer times list
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

                // Optional prayers section
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

                // Empty state
                if viewModel.standardPrayers.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "clock.badge.exclamationmark")
                            .font(.system(size: 32))
                            .foregroundStyle(.secondary)

                        Text("No Prayer Data")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text("Open iOS app first")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        }
        //        .navigationTitle()
        //        .navigationBarTitleDisplayMode(.inline)
        //        .toolbar {
        //            ToolbarItem(placement: .topBarTrailing) {
        //                Button {
        //                    viewModel.refresh()
        //                    WKInterfaceDevice.current().play(.click)
        //                } label: {
        //                    Image(systemName: "arrow.clockwise")
        //                        .font(.caption)
        //                }
        //            }
        //        }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
            // Refresh when day changes
            viewModel.refresh()
        }
        .onAppear {
            viewModel.refresh()
        }
    }
}

#Preview {
    WatchPrayerTimesView()
}
