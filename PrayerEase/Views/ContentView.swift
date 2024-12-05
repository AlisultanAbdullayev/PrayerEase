//
//  ContentView.swift
//  PrayerEase
//
//  Created by Alisultan Abdullah on 10/30/24.
//

import SwiftUI
import Adhan
import WidgetKit

struct ContentView: View {
    @EnvironmentObject private var locationManager: LocationManager
    @EnvironmentObject private var notificationManager: NotificationManager
    @EnvironmentObject private var prayerTimeManager: PrayerTimeManager
    @State private var isSheetShowing = false
    @State private var isLoadFailed = false
    
    let currentDate = Date()
    let hijriCalendar = Calendar(identifier: .islamicUmmAlQura)
    
    var body: some View {
        Group {
            if locationManager.userLocation == nil {
                locationNotFoundView
            } else {
                mainContentView
            }
        }
        .navigationTitle("Salah time")
        .sheet(isPresented: $isSheetShowing) {
            LocationNotFoundView()
                .interactiveDismissDisabled()
        }
    }
    
    private var locationNotFoundView: some View {
        VStack {}
            .onAppear { self.isSheetShowing = true }
            .onDisappear { self.isSheetShowing = false }
    }
    
    private var mainContentView: some View {
        Form {
            dateAndHijriSection
            if let prayerTimes = prayerTimeManager.prayerTimes {
                LeftTimeSection(prayers: prayerTimes)
                prayerTimesList(prayers: prayerTimes)
            } else {
                progressView
            }
        }
        .task {
            locationManager.startUpdatingLocation()
        }
        .onAppear {
            updatePrayerTimes()
            // Schedule initial background refresh when the app launches
//            (UIApplication.shared.delegate as? SalahTimeApp)?.scheduleNextAppRefresh()
        }
        .onChange(of: prayerTimeManager.madhab) { updatePrayerTimesAndNotifications() }
        .onChange(of: prayerTimeManager.method) { updatePrayerTimesAndNotifications() }
    }
    
    private var dateAndHijriSection: some View {
        Section {
            VStack {
                Text(getFormattedHijriDate(date: currentDate, calendar: hijriCalendar))
                    .font(.title2)
                    .foregroundStyle(.accent)
                Text(currentDate, style: .date)
                    .foregroundStyle(.secondary)
                    .font(.title3)
            }
            .fontDesign(.rounded)
            .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
    
    private var progressView: some View {
        Group {
            if !isLoadFailed {
                ProgressView("Try to load the data...")
                    .frame(maxWidth: .infinity)
                    .task {
                        try? await Task.sleep(nanoseconds: 5_000_000_000)
                        self.isLoadFailed = true
                    }
            } else {
                Text("Data can not be loaded!")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }
    
    @ViewBuilder
    private func prayerTimesList(prayers: PrayerTimes) -> some View {
        Section {
            ForEach(Prayer.allCases, id: \.self) { prayer in
                SalahTimeRowView(
                    imageName: imageName(for: prayer),
                    salahTime: prayerTimeManager.formattedPrayerTime(prayerTime(for: prayer, in: prayers)),
                    salahName: prayer.name
                )
                .foregroundColor(prayers.currentPrayer() == prayer ? .accent : .none)
            }
        } header: {
            Button {
                locationManager.startUpdatingLocation()
            } label: {
                Label(locationManager.locationName,
                      systemImage: locationManager.isLocationActive ? "location.circle.fill" : "location.slash")
                .foregroundColor(.accentColor)
            }
        }
    }
    
    private func updatePrayerTimes() {
        if let location = locationManager.userLocation {
            prayerTimeManager.updateLocation(location)
            prayerTimeManager.fetchPrayerTimes(for: currentDate)
        }
    }
    
    private func updatePrayerTimesAndNotifications() {
        updatePrayerTimes()
        notificationManager.scheduleLongTermNotifications()
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    private func imageName(for prayer: Prayer) -> String {
        switch prayer {
        case .fajr: return "sunrise"
        case .sunrise: return "sun.and.horizon"
        case .dhuhr: return "sun.max"
        case .asr: return "sunset"
        case .maghrib: return "moon"
        case .isha: return "moon.stars"
        }
    }
    
    private func prayerTime(for prayer: Prayer, in prayers: PrayerTimes) -> Date {
        switch prayer {
        case .fajr: return prayers.fajr
        case .sunrise: return prayers.sunrise
        case .dhuhr: return prayers.dhuhr
        case .asr: return prayers.asr
        case .maghrib: return prayers.maghrib
        case .isha: return prayers.isha
        }
    }
    
    private func getFormattedHijriDate(date: Date, calendar: Calendar) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.dateFormat = "d MMMM yyyy"
        return formatter.string(from: date)
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
    ContentView()
        .environmentObject(LocationManager())
}
