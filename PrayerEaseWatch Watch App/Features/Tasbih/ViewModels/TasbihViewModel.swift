//
//  TasbihViewModel.swift
//  PrayerEaseWatch Watch App
//
//  Created by Antigravity on 12/23/25.
//

import Foundation
import SwiftUI
import Combine

/// View model for Tasbih counter screen (watch-only feature)
@MainActor
final class TasbihViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var currentCount: Int {
        didSet {
            saveState()
            checkTargetReached()
        }
    }

    @Published var targetCount: Int {
        didSet {
            saveState()
        }
    }

    @Published var totalCount: Int {
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

        // Set default target if not set
        if targetCount == 0 {
            targetCount = 33
        }
    }

    // MARK: - Actions

    /// Increments the current count
    func increment() {
        currentCount += 1
        totalCount += 1

        // Haptic feedback
        WKInterfaceDevice.current().play(.click)
    }

    /// Resets the current session count
    func resetCurrent() {
        currentCount = 0

        // Haptic feedback
        WKInterfaceDevice.current().play(.stop)
    }

    /// Resets the total historical count
    func resetTotal() {
        totalCount = 0
        currentCount = 0

        // Haptic feedback
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
            // Target reached - auto reset current count
            WKInterfaceDevice.current().play(.success)

            // Reset with slight delay for better UX
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.currentCount = 0
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
