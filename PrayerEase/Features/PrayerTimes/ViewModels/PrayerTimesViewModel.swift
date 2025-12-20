//
//  PrayerTimesViewModel.swift
//  PrayerEase
//
//  Created by Alisultan Abdullah on 12/20/24.
//

import Combine
import Foundation
import SwiftUI

@MainActor
final class PrayerTimesViewModel: ObservableObject {
    @Published var isSheetShowing = false
    @Published var isLoadFailed = false
    @Published var isSetupSheetPresented = false
    @Published var currentDate = Date()

    private var cancellables = Set<AnyCancellable>()
    private var timer: Publishers.Autoconnect<Timer.TimerPublisher>?

    let hijriCalendar = Calendar(identifier: .islamicUmmAlQura)

    init() {
        setupTimer()
    }

    private func setupTimer() {
        timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

        timer?
            .sink { [weak self] _ in
                self?.checkForDayChange()
            }
            .store(in: &cancellables)
    }

    func checkForDayChange() {
        let now = Date()
        if !Calendar.current.isDate(now, inSameDayAs: currentDate) {
            currentDate = now
        }
    }

    func getFormattedHijriDate() -> String {
        let formatter = DateFormatter()
        formatter.calendar = hijriCalendar
        formatter.dateFormat = "d MMMM yyyy"
        return formatter.string(from: currentDate)
    }

    // Logic to handle scene phase changes if needed
    func onSceneActive() {
        checkForDayChange()
    }
}
