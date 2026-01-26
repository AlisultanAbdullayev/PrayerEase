//
//  PrayerTimesView.swift
//  PrayerEase
//
//  Created by Alisultan Abdullah on 10/30/24.
//

import Adhan
import CoreLocation
import SwiftUI
import WidgetKit

struct PrayerTimesView: View {
    // MARK: - Environment
    @Environment(LocationManager.self) private var locationManager
    @Environment(NotificationManager.self) private var notificationManager
    @Environment(PrayerTimeManager.self) private var prayerTimeManager
    @Environment(\.scenePhase) private var scenePhase

    // MARK: - State
    @State private var presentedSheet: PresentedSheet?
    @State private var currentDate = Date()

    // MARK: - Constants
    private let hijriCalendar = Calendar(identifier: .islamicUmmAlQura)

    // MARK: - Body
    var body: some View {
        Group {
            if locationManager.userLocation == nil {
                LocationNotFoundTriggerView(presentedSheet: $presentedSheet)
            } else {
                PrayerTimesFormView(currentDate: currentDate, hijriCalendar: hijriCalendar)
            }
        }
            .navigationTitle("Salah time")
            .task { updatePrayerTimes() }
            .task {
                await setupDayChangeTimer()
            }
            .sheet(item: $presentedSheet) { sheet in
                PrayerTimesSheetView(sheet: sheet, prayerTimeManager: prayerTimeManager)
            }
            .onChange(of: scenePhase) { _, newPhase in
                handleScenePhaseChange(newPhase)
            }
            .onChange(of: locationManager.userLocation) { _, newLocation in
                handleLocationChange(newLocation)
            }
            .onChange(of: locationManager.userTimeZone) { _, timeZone in
                handleTimeZoneChange(timeZone)
            }
            .onChange(of: locationManager.locationName) { _, _ in
                syncWidgetData()
            }
            .onChange(of: prayerTimeManager.dataId) { _, _ in
                syncWidgetData()
            }
            .onChange(of: prayerTimeManager.madhab) { _, _ in
                updatePrayerTimesAndNotifications()
            }
            .onChange(of: prayerTimeManager.method) { _, _ in
                updatePrayerTimesAndNotifications()
            }
            .onChange(of: currentDate) { _, _ in
                updatePrayerTimes()
            }
    }

    // MARK: - Helpers
    private func getFormattedHijriDate() -> String {
        let formatter = DateFormatter()
        formatter.calendar = hijriCalendar
        formatter.dateFormat = "d MMMM yyyy"
        return formatter.string(from: currentDate)
    }

    // MARK: - Event Handlers

    private func handleLocationChange(_ newLocation: CLLocation?) {
        guard let location = newLocation else { return }
        prayerTimeManager.updateLocation(location)
        notificationManager.updateLocation(location)
        prayerTimeManager.fetchPrayerTimes(for: currentDate)
    }

    private func handleTimeZoneChange(_ timeZone: String?) {
        guard let tz = timeZone, !prayerTimeManager.isMethodManuallySet else { return }
        let found = prayerTimeManager.autoSelectMethod(for: tz)
        if !found {
            presentedSheet = .setup
        }
    }

    private func handleScenePhaseChange(_ newPhase: ScenePhase) {
        if newPhase == .active {
            checkForDayChange()
            syncWidgetData()
        }
    }

    private func checkForDayChange() {
        let now = Date()
        if !Calendar.current.isDate(now, inSameDayAs: currentDate) {
            currentDate = now
        }
    }

    private func setupDayChangeTimer() async {
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(60))
            checkForDayChange()
        }
    }

    private func updatePrayerTimes() {
        guard let location = locationManager.userLocation else { return }
        prayerTimeManager.updateLocation(location)
        prayerTimeManager.fetchPrayerTimes(for: currentDate)
        syncWidgetData()
    }

    private func updatePrayerTimesAndNotifications() {
        updatePrayerTimes()
        notificationManager.syncNotifications()
    }

    private func syncWidgetData() {
        guard let prayerTimes = prayerTimeManager.prayerTimes else { return }

        let islamicDate = getFormattedHijriDate()
        let locationName = locationManager.locationName

        WidgetDataManager.shared.updateWidgetData(
            prayerTimes: prayerTimes,
            locationName: locationName,
            islamicDate: islamicDate
        )

        if WidgetDataManager.shared.isLiveActivityEnabled {
            Task {
                await WidgetDataManager.shared.updateLiveActivity(
                    prayerTimes: prayerTimes,
                    locationName: locationName,
                    islamicDate: islamicDate
                )
            }
        }
    }
}

// MARK: - Subviews
private struct LocationNotFoundTriggerView: View {
    @Binding var presentedSheet: PresentedSheet?

    var body: some View {
        Color.clear
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear { presentedSheet = .locationNotFound }
            .onDisappear { presentedSheet = nil }
    }
}

private struct PrayerTimesSheetView: View {
    let sheet: PresentedSheet
    let prayerTimeManager: PrayerTimeManager

    var body: some View {
        switch sheet {
        case .locationNotFound:
            LocationNotFoundView()
                .interactiveDismissDisabled()
        case .setup:
            SetupSheetView(prayerTimeManager: prayerTimeManager)
                .interactiveDismissDisabled()
        }
    }
}

// MARK: - Supporting Types
private enum PresentedSheet: Identifiable {
    case locationNotFound
    case setup

    var id: Self { self }
}

// MARK: - Preview
#Preview {
    PrayerTimesView()
        .environment(LocationManager())
}
