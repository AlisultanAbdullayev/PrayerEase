//
//  SettingsView.swift
//  PrayerEase
//
//  Created by Alisultan Abdullah on 10/30/24.
//

import ActivityKit
import Adhan
import SwiftUI

struct SettingsView: View {

    @EnvironmentObject private var prayerTimeManager: PrayerTimeManager
    @EnvironmentObject private var notificationManager: NotificationManager
    @EnvironmentObject private var locationManager: LocationManager
    @StateObject private var widgetDataManager = WidgetDataManager.shared
    @State private var isNotifyBeforeExpanded = false

    var body: some View {
        Form {
            locationSection
            liveActivitySection
            notificationSection
            calculationSection
            debugSection
            footerSection
        }

        .onDisappear {
            isNotifyBeforeExpanded = false
        }
        .navigationTitle("Settings")
    }

    private var locationSection: some View {
        Section(header: Text("Location")) {
            Toggle(isOn: $locationManager.isAutoLocationEnabled) {
                Text("Auto Location Detection")
            }
        }
    }
    
    private var liveActivitySection: some View {
        Section {
            Toggle(isOn: $widgetDataManager.isLiveActivityEnabled) {
                HStack {
                    Image(systemName: "clock.badge.fill")
                        .foregroundStyle(.blue)
                    Text("Live Activity")
                }
            }
            .onChange(of: widgetDataManager.isLiveActivityEnabled) { _, isEnabled in
                Task {
                    if isEnabled {
                        await startLiveActivityIfPossible()
                    } else {
                        await widgetDataManager.endLiveActivity()
                    }
                }
            }
            
            if !ActivityAuthorizationInfo().areActivitiesEnabled {
                Text("Live Activities are disabled. Enable them in Settings > PrayerEase.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("Live Activity")
        } footer: {
            Text("Shows prayer countdown on your Lock Screen and Dynamic Island.")
        }
    }
    
    private func startLiveActivityIfPossible() async {
        guard let prayerTimes = prayerTimeManager.prayerTimes else { return }
        
        let islamicDate = getFormattedHijriDate()
        
        await widgetDataManager.startLiveActivity(
            prayerTimes: prayerTimes,
            locationName: locationManager.locationName,
            islamicDate: islamicDate
        )
    }
    
    private func getFormattedHijriDate() -> String {
        let hijriCalendar = Calendar(identifier: .islamicUmmAlQura)
        let formatter = DateFormatter()
        formatter.calendar = hijriCalendar
        formatter.dateFormat = "d MMMM yyyy"
        return formatter.string(from: Date())
    }

    private var notificationSection: some View {
        Section(header: Text("Notification:")) {
            notifyBeforeGroup
            minutesBeforePicker
        }
    }

    private var notifyBeforeGroup: some View {
        DisclosureGroup(isExpanded: $isNotifyBeforeExpanded) {
            ForEach(notificationManager.notificationSettingsBefore.keys.sorted(), id: \.self) {
                key in
                Toggle(isOn: bindingForNotification(key: key)) {
                    Text(key).tag(key)
                }
            }
        } label: {
            SettingsRowWithSelection(text: Text("Notify before salahs"), systemImage: "clock") {}
        }
    }

    private var minutesBeforePicker: some View {
        SettingsRowWithSelection(text: Text("Minutes before"), systemImage: "hourglass") {
            Picker("", selection: $notificationManager.beforeMinutes) {
                ForEach(notificationManager.minuteOptions, id: \.self) { minute in
                    Text(minute == 60 ? "1 hour" : "\(minute) minutes").tag(minute)
                }
            }
        }
        .onAppear {
            if !notificationManager.minuteOptions.contains(notificationManager.beforeMinutes) {
                notificationManager.beforeMinutes = notificationManager.minuteOptions[3]
            }
        }
    }

    private var calculationSection: some View {
        Section(header: Text("Calculation:")) {
            madhabPicker
            institutionPicker
        }
    }

    private var madhabPicker: some View {
        SettingsRowWithSelection(text: Text("Madhab"), systemImage: "doc.plaintext") {
            Picker("", selection: $prayerTimeManager.madhab) {
                ForEach(prayerTimeManager.madhabs, id: \.self) { madhab in
                    Text(madhab == .hanafi ? "Hanafi" : "Default (Shafi, Maliki, Hanbali)")
                        .tag(madhab)
                }
            }
        }
    }

    private var institutionPicker: some View {
        SettingsRowWithSelection(text: Text("Institution"), systemImage: "book") {
            Picker("", selection: $prayerTimeManager.method) {
                ForEach(prayerTimeManager.methods, id: \.self) { method in
                    Text(methodName(for: method)).tag(method)
                }
            }
            .pickerStyle(NavigationLinkPickerStyle())
        }
    }

    private var debugSection: some View {
        Section(header: Text("Debug")) {
            Button(role: .destructive) {
                resetOnboarding()
            } label: {
                Text("Reset Onboarding")
            }
        }
    }

    private func resetOnboarding() {
        // Clear all UserDefaults
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
        }

        // Explicitly clear specific keys if suite sharing is involved,
        // but removing persistent domain usually handles standard suite.
        // For shared groups, we might need to clear that suite too if used,
        // but request asked for "reset onboarding" primarily.

        // Trigger App restart logic by modifying the AppStorage binding indirectly
        // or just letting the app state refresh naturally on next launch?
        // Actually, since hasCompletedOnboarding is AppStorage, writing to UserDefaults
        // might not update the binding immediately in PrayerEaseApp without a sync.

        // Force update the specific key to False to trigger UI change immediately if possible,
        // OR just exit/crash app (brisk solution for debug) or let user restart.
        // Better:
        UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")

        // Notify user
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    private var footerSection: some View {
        VStack {
            Text("Make 🤲 for us")
            Text("Made with ❤️")
            Text("by Alisultan Abdullah")
        }
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private func bindingForNotification(key: String) -> Binding<Bool> {
        Binding(
            get: { self.notificationManager.notificationSettingsBefore[key] ?? false },
            set: { newValue in
                self.notificationManager.updateNotificationSettings(
                    for: key, sendNotification: newValue, isBefore: true)
                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
            }
        )
    }

    private func methodName(for method: CalculationMethod) -> String {
        switch method {
        case .dubai:
            return "Dubai"
        case .muslimWorldLeague:
            return "Muslim World League"
        case .egyptian:
            return "Egyptian General Authority of Survey"
        case .karachi:
            return "University of Islamic Sciences, Karachi"
        case .ummAlQura:
            return "Umm Al-Qura University, Makkah"
        case .moonsightingCommittee:
            return "Moonsighting Committee Worldwide"
        case .northAmerica:
            return "Islamic Society of North America"
        case .kuwait:
            return "Kuwait"
        case .qatar:
            return "Qatar"
        case .singapore:
            return "Majlis Ugama Islam Singapura, Singapore"
        case .tehran:
            return "Institute of Geophysics, University of Tehran"
        case .turkey:
            return "Diyanet İşleri Başkanlığı, Turkey"
        case .other:
            return "Other"
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(PrayerTimeManager.shared)
        .environmentObject(NotificationManager.shared)
        .environmentObject(LocationManager())
}
