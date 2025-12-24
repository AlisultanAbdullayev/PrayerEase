//
//  WatchPrayerTimesViewModel.swift
//  PrayerEaseWatch Watch App
//
//  Created by Antigravity on 12/23/25.
//

import Combine
import Foundation

/// View model for Prayer Times screen on watchOS
@MainActor
final class WatchPrayerTimesViewModel: ObservableObject {

    // MARK: - Dependencies

    private let watchDataManager: WatchDataManager
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Published Properties

    @Published var standardPrayers: [SharedPrayerTime] = []
    @Published var optionalPrayers: [SharedPrayerTime] = []
    @Published var locationName: String = ""
    @Published var islamicDate: String = ""
    @Published var currentPrayer: SharedPrayerTime?
    @Published var nextPrayer: SharedPrayerTime?

    // MARK: - Initialization

    init(watchDataManager: WatchDataManager) {
        self.watchDataManager = watchDataManager
        setupBindings()
        loadData()
    }

    convenience init() {
        self.init(watchDataManager: WatchDataManager.shared)
    }

    // MARK: - Setup

    private func setupBindings() {
        // Observe prayer data changes
        watchDataManager.$prayerTimes
            .sink { [weak self] times in
                self?.standardPrayers = times
                self?.updateCurrentPrayer()
            }
            .store(in: &cancellables)

        // Observe optional prayers
        watchDataManager.$isDuhaEnabled
            .combineLatest(watchDataManager.$isTahajjudEnabled)
            .sink { [weak self] _ in
                self?.optionalPrayers = self?.watchDataManager.optionalPrayers ?? []
            }
            .store(in: &cancellables)

        // Observe location
        watchDataManager.$locationName
            .assign(to: &$locationName)

        // Observe Islamic date
        watchDataManager.$islamicDate
            .assign(to: &$islamicDate)
    }

    private func loadData() {
        standardPrayers = watchDataManager.prayerTimes
        optionalPrayers = watchDataManager.optionalPrayers
        locationName = watchDataManager.locationName
        islamicDate = watchDataManager.islamicDate
        updateCurrentPrayer()
    }

    // MARK: - Actions

    /// Refreshes prayer data from storage
    func refresh() {
        watchDataManager.refresh()

        // Also request fresh data from iOS app if available
        WatchConnectivityManager.shared.requestPrayerDataUpdate()
    }

    // MARK: - Helpers

    /// Checks if a prayer is the current active prayer
    func isCurrent(prayer: SharedPrayerTime) -> Bool {
        return watchDataManager.isCurrent(prayer: prayer)
    }

    private func updateCurrentPrayer() {
        currentPrayer = watchDataManager.currentPrayer
        nextPrayer = watchDataManager.nextPrayer
    }
}
