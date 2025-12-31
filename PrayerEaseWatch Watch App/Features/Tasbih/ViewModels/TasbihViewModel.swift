//
//  TasbihViewModel.swift
//  PrayerEaseWatch Watch App
//
//  Created by Antigravity on 12/23/25.
//

import Foundation
import SwiftUI
import WatchKit

/// View model for Tasbih counter screen (watch-only feature)
@MainActor
@Observable
final class TasbihViewModel {

    // MARK: - Properties

    var currentCount: Int {
        didSet {
            saveState()
            checkTargetReached()
        }
    }

    var targetCount: Int {
        didSet {
            saveState()
        }
    }

    var totalCount: Int {
        didSet {
            saveState()
        }
    }

    // MARK: - Private Properties

    private let userDefaults = UserDefaults.standard
    private let currentCountKey = "tasbih.currentCount"
    private let targetCountKey = "tasbih.targetCount"
    private let totalCountKey = "tasbih.totalCount"

    // MARK: - Initialization

    init() {
        self.currentCount = userDefaults.integer(forKey: currentCountKey)
        self.targetCount = userDefaults.integer(forKey: targetCountKey)
        self.totalCount = userDefaults.integer(forKey: totalCountKey)

        if targetCount == 0 {
            targetCount = 33
        }
    }

    // MARK: - Actions

    /// Increments the current count
    func increment() {
        currentCount += 1
        totalCount += 1
        WKInterfaceDevice.current().play(.click)
    }

    /// Resets the current session count
    func resetCurrent() {
        currentCount = 0
        WKInterfaceDevice.current().play(.stop)
    }

    /// Resets the total historical count
    func resetTotal() {
        totalCount = 0
        currentCount = 0
        WKInterfaceDevice.current().play(.stop)
    }

    /// Sets a new target count
    func setTarget(_ newTarget: Int) {
        targetCount = newTarget
    }

    // MARK: - Private Helpers

    private func saveState() {
        userDefaults.set(currentCount, forKey: currentCountKey)
        userDefaults.set(targetCount, forKey: targetCountKey)
        userDefaults.set(totalCount, forKey: totalCountKey)
    }

    private func checkTargetReached() {
        if currentCount >= targetCount && currentCount > 0 {
            WKInterfaceDevice.current().play(.success)

            Task {
                try? await Task.sleep(for: .milliseconds(500))
                self.currentCount = 0
            }
        }
    }

    // MARK: - Computed Properties

    /// Progress value for gauge (0.0 to 1.0)
    var progress: Double {
        guard targetCount > 0 else { return 0 }
        return min(Double(currentCount) / Double(targetCount), 1.0)
    }
}
