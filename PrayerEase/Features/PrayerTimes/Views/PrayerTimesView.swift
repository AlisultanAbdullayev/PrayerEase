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
    @Environment(LocationManager.self) private var locationManager
    @Environment(NotificationManager.self) private var notificationManager
    @Environment(PrayerTimeManager.self) private var prayerTimeManager

    @Environment(\.scenePhase) private var scenePhase

    @State private var isSheetShowing = false
    @State private var isSetupSheetPresented = false
    @State private var currentDate = Date()

    private let hijriCalendar = Calendar(identifier: .islamicUmmAlQura)

    var body: some View {
        content
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

    private var content: some View {
        sheetContent
            .navigationTitle("Salah time")
            .task { updatePrayerTimes() }
            .task {
                await setupDayChangeTimer()
            }
    }

    private var sheetContent: some View {
        contentGroup
            .sheet(isPresented: $isSheetShowing) {
                LocationNotFoundView()
                    .interactiveDismissDisabled()
            }
            .sheet(isPresented: $isSetupSheetPresented) {
                SetupSheetView(prayerTimeManager: prayerTimeManager)
                    .interactiveDismissDisabled()
            }
    }

    @ViewBuilder
    private var contentGroup: some View {
        if locationManager.userLocation == nil {
            locationNotFoundView
        } else {
            PrayerTimesFormView(currentDate: currentDate, hijriCalendar: hijriCalendar)
        }
    }

    private var locationNotFoundView: some View {
        VStack {}
            .onAppear { isSheetShowing = true }
            .onDisappear { isSheetShowing = false }
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
            isSetupSheetPresented = true
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

#Preview {
    PrayerTimesView()
        .environment(LocationManager())
}
