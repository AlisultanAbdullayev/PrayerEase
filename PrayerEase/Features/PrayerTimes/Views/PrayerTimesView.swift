//
//  ContentView.swift
//  PrayerEase
//
//  Created by Alisultan Abdullah on 10/30/24.
//

import Adhan
import CoreLocation
import SwiftUI
import WidgetKit

struct PrayerTimesView: View {
    @EnvironmentObject private var locationManager: LocationManager
    @EnvironmentObject private var notificationManager: NotificationManager
    @EnvironmentObject private var prayerTimeManager: PrayerTimeManager

    @StateObject private var viewModel = PrayerTimesViewModel()

    @Environment(\.scenePhase) var scenePhase

    var body: some View {
        baseView
            .onChange(of: scenePhase) { _, newPhase in
                handleScenePhaseChange(newPhase)
            }
    }
    
    private var baseView: some View {
        coreContent
            .onReceive(locationManager.$locationName) { _ in
                syncWidgetData()
            }
            .onReceive(prayerTimeManager.$prayerTimes) { _ in
                syncWidgetData()
            }
    }
    
    private var coreContent: some View {
        settingsObservingContent
            .onReceive(locationManager.$userLocation) { newLocation in
                handleLocationChange(newLocation)
            }
            .onReceive(locationManager.$userTimeZone) { timeZone in
                handleTimeZoneChange(timeZone)
            }
    }
    
    private var settingsObservingContent: some View {
        sheetContent
            .onReceive(prayerTimeManager.$madhab) { _ in
                updatePrayerTimesAndNotifications()
            }
            .onReceive(prayerTimeManager.$method) { _ in
                updatePrayerTimesAndNotifications()
            }
            .onReceive(viewModel.$currentDate) { _ in
                updatePrayerTimes()
            }
    }
    
    private var sheetContent: some View {
        navigationContent
            .sheet(isPresented: $viewModel.isSheetShowing) {
                LocationNotFoundView()
                    .interactiveDismissDisabled()
            }
            .sheet(isPresented: $viewModel.isSetupSheetPresented) {
                SetupSheetView(prayerTimeManager: prayerTimeManager)
                    .interactiveDismissDisabled()
            }
    }
    
    private var navigationContent: some View {
        contentGroup
            .navigationTitle("Salah time")
            .task { updatePrayerTimes() }
    }

    @ViewBuilder
    private var contentGroup: some View {
        if locationManager.userLocation == nil {
            locationNotFoundView
        } else {
            PrayerTimesFormView(viewModel: viewModel)
        }
    }

    private var locationNotFoundView: some View {
        VStack {}
            .onAppear { viewModel.isSheetShowing = true }
            .onDisappear { viewModel.isSheetShowing = false }
    }
    
    // MARK: - Event Handlers
    
    private func handleLocationChange(_ newLocation: CLLocation?) {
        guard let location = newLocation else { return }
        prayerTimeManager.updateLocation(location)
        notificationManager.updateLocation(location)
        prayerTimeManager.fetchPrayerTimes(for: viewModel.currentDate)
    }
    
    private func handleTimeZoneChange(_ timeZone: String?) {
        guard let tz = timeZone, !prayerTimeManager.isMethodManuallySet else { return }
        let found = prayerTimeManager.autoSelectMethod(for: tz)
        if !found {
            viewModel.isSetupSheetPresented = true
        }
    }
    
    private func handleScenePhaseChange(_ newPhase: ScenePhase) {
        if newPhase == .active {
            viewModel.onSceneActive()
            syncWidgetData()
        }
    }

    private func updatePrayerTimes() {
        guard let location = locationManager.userLocation else { return }
        prayerTimeManager.updateLocation(location)
        prayerTimeManager.fetchPrayerTimes(for: viewModel.currentDate)
        syncWidgetData()
    }

    private func updatePrayerTimesAndNotifications() {
        updatePrayerTimes()
        notificationManager.syncNotifications()
    }
    
    private func syncWidgetData() {
        guard let prayerTimes = prayerTimeManager.prayerTimes else { return }
        
        let islamicDate = viewModel.getFormattedHijriDate()
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
        .environmentObject(LocationManager())
}
