//
//  ContentView.swift
//  PrayerEase
//
//  Created by Alisultan Abdullah on 10/30/24.
//

import Adhan
import SwiftUI
import WidgetKit

struct PrayerTimesView: View {
    @EnvironmentObject private var locationManager: LocationManager
    @EnvironmentObject private var notificationManager: NotificationManager
    @EnvironmentObject private var prayerTimeManager: PrayerTimeManager

    @StateObject private var viewModel = PrayerTimesViewModel()

    @Environment(\.scenePhase) var scenePhase

    var body: some View {
        Group {
            if locationManager.userLocation == nil {
                locationNotFoundView
            } else {
                PrayerTimesFormView(viewModel: viewModel)
            }
        }
        .navigationTitle("Salah time")
        .sheet(isPresented: $viewModel.isSheetShowing) {
            LocationNotFoundView()
                .interactiveDismissDisabled()
        }
        .sheet(isPresented: $viewModel.isSetupSheetPresented) {
            SetupSheetView(prayerTimeManager: prayerTimeManager)
                .interactiveDismissDisabled()
        }
        .task {
            updatePrayerTimes()
        }
        .onChange(of: locationManager.userLocation) { _, newLocation in
            if let location = newLocation {
                prayerTimeManager.updateLocation(location)
                notificationManager.updateLocation(location)
                prayerTimeManager.fetchPrayerTimes(for: viewModel.currentDate)
            }
        }
        .onChange(of: locationManager.userTimeZone) { _, timeZone in
            if let tz = timeZone, !prayerTimeManager.isMethodManuallySet {
                let found = prayerTimeManager.autoSelectMethod(for: tz)
                if !found {
                    viewModel.isSetupSheetPresented = true
                }
            }
        }
        .onChange(of: prayerTimeManager.madhab) { _, _ in
            updatePrayerTimesAndNotifications()
        }
        .onChange(of: prayerTimeManager.method) { _, _ in
            updatePrayerTimesAndNotifications()
        }
        .onChange(of: viewModel.currentDate) { _, newDate in
            print("DEBUG: Date changed to \(newDate), updating prayer times")
            updatePrayerTimes()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                viewModel.onSceneActive()
            }
        }
    }

    private var locationNotFoundView: some View {
        VStack {}
            .onAppear { viewModel.isSheetShowing = true }
            .onDisappear { viewModel.isSheetShowing = false }
    }

    private func updatePrayerTimes() {
        if let location = locationManager.userLocation {
            prayerTimeManager.updateLocation(location)
            prayerTimeManager.fetchPrayerTimes(for: viewModel.currentDate)
        }
    }

    private func updatePrayerTimesAndNotifications() {
        updatePrayerTimes()
        notificationManager.syncNotifications()
        WidgetCenter.shared.reloadAllTimelines()
    }
}

extension Prayer {
    var name: String {
        switch self {
        case .fajr: return "Fajr"
        case .sunrise: return "Sunrise"
        case .dhuhr: return "Dhuhr"
        case .asr: return "Asr"
        case .maghrib: return "Maghrib"
        case .isha: return "Isha"
        }
    }
}

#Preview {
    PrayerTimesView()
        .environmentObject(LocationManager())
}
