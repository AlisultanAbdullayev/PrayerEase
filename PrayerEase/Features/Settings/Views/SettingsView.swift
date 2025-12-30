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

    var body: some View {
        Form {
            Section {
                NavigationLink(destination: LocationSettingsView()) {
                    HStack {
                        Image(systemName: "location.fill")
                            .foregroundStyle(.blue)
                        Text("Location")
                            .foregroundStyle(.primary)
                    }
                }

                NavigationLink(destination: NotificationSettingsView()) {
                    HStack {
                        Image(systemName: "bell.badge.fill")
                            .foregroundStyle(.red)
                        Text("Notifications & Display")
                            .foregroundStyle(.primary)
                    }
                }

                NavigationLink(destination: PrayerSettingsView()) {
                    HStack {
                        Image(systemName: "hands.sparkles.fill")
                            .foregroundStyle(.green)
                        Text("Prayer Settings")
                            .foregroundStyle(.primary)
                    }
                }
            }

//            Section(header: Text("Debug")) {
//                Button(role: .destructive) {
//                    resetOnboarding()
//                } label: {
//                    Text("Reset Onboarding")
//                }
//            }

            Section {
                VStack {
                    Text("Make 🤲 for us")
                    Text("Made with ❤️")
                    Text("by Alisultan Abdullah")
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .listRowBackground(Color.clear)
        }
        .navigationTitle("Settings")
    }

    private func resetOnboarding() {
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
        }
        UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}

// MARK: - Subviews

struct LocationSettingsView: View {
    @EnvironmentObject var locationManager: LocationManager

    var body: some View {
        Form {
            Section(header: Text("Location Services")) {
                Toggle(isOn: $locationManager.isAutoLocationEnabled) {
                    VStack(alignment: .leading) {
                        Text("Auto Location Detection")
                        Text(
                            locationManager.isAutoLocationEnabled
                                ? locationManager.locationName : "Using manual location"
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
                .onChange(of: locationManager.isAutoLocationEnabled) { _, isEnabled in
                    if isEnabled {
                        locationManager.requestLocation()
                    }
                }

                if !locationManager.isAutoLocationEnabled {
                    NavigationLink(destination: ManualLocationSearchView()) {
                        HStack {
                            Text("Manually Search Location")
                            Spacer()
                            Text(locationManager.locationName)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
            }
        }
        .navigationTitle("Location")
    }
}

struct NotificationSettingsView: View {
    @EnvironmentObject var notificationManager: NotificationManager
    @EnvironmentObject var prayerTimeManager: PrayerTimeManager
    @EnvironmentObject var locationManager: LocationManager
    @StateObject private var widgetDataManager = WidgetDataManager.shared
    @State private var isNotifyBeforeExpanded = false
    @State private var isNotifyExactExpanded = false  // Collapsed by default

    var body: some View {
        Form {
            liveActivitySection
            exactAlertsSection
            qiraaSection
            preAlertsSection
        }
        .navigationTitle("Notifications")
        .onDisappear {
            isNotifyBeforeExpanded = false
        }
    }

    private var liveActivitySection: some View {
        Section {
            Toggle(isOn: $widgetDataManager.isLiveActivityEnabled) {
                HStack {
                    Image(systemName: "clock.badge")
                        .foregroundStyle(.accent)
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

    private var exactAlertsSection: some View {
        Section(header: Text("Prayer Alerts")) {
            DisclosureGroup(isExpanded: $isNotifyExactExpanded) {
                // Standard Prayers
                ForEach(notificationManager.notificationSettings.keys.sorted(), id: \.self) { key in
                    // Ensure we don't duplicate optional prayers if they somehow get into this dict later
                    if key != "Tahajjud" && key != "Duha" {
                        Toggle(isOn: bindingForNotification(key: key, isBefore: false)) {
                            Text(key).tag(key)
                        }
                    }
                }

                // Optional Prayers
                Toggle(
                    isOn: bindingForOptionalPrayerNotification(
                        key: "Duha", isEnabledBinding: $widgetDataManager.isDuhaEnabled)
                ) {
                    Text("Duha")
                }

                Toggle(
                    isOn: bindingForOptionalPrayerNotification(
                        key: "Tahajjud", isEnabledBinding: $widgetDataManager.isTahajjudEnabled)
                ) {
                    Text("Tahajjud")
                }

            } label: {
                SettingsRowWithSelection(
                    text: Text("Notify at prayer time"), systemImage: "bell.fill"
                ) {}
            }
        }
    }

    private var qiraaSection: some View {
        Section(header: Text("Qiraa Times")) {
            Toggle(isOn: bindingForNotification(key: "QiraaAfterSunrise", isBefore: false)) {
                VStack(alignment: .leading) {
                    Text("After Sunrise")
                    Text("45 min after sunrise")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Toggle(isOn: bindingForNotification(key: "QiraaBeforeDhuhr", isBefore: false)) {
                VStack(alignment: .leading) {
                    Text("Before Dhuhr")
                    Text("45 min before dhuhr")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Toggle(isOn: bindingForNotification(key: "QiraaBeforeMaghrib", isBefore: false)) {
                VStack(alignment: .leading) {
                    Text("Before Maghrib")
                    Text("45 min before maghrib")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var preAlertsSection: some View {
        Section(header: Text("Pre-Prayer Alerts")) {
            DisclosureGroup(isExpanded: $isNotifyBeforeExpanded) {
                ForEach(notificationManager.notificationSettingsBefore.keys.sorted(), id: \.self) {
                    key in
                    Toggle(isOn: bindingForNotification(key: key, isBefore: true)) {
                        Text(key).tag(key)
                    }
                }
            } label: {
                SettingsRowWithSelection(text: Text("Notify before salahs"), systemImage: "clock") {
                }
            }

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
    }

    // Binding for standard prayers
    private func bindingForNotification(key: String, isBefore: Bool) -> Binding<Bool> {
        Binding(
            get: {
                if isBefore {
                    return self.notificationManager.notificationSettingsBefore[key] ?? false
                } else {
                    return self.notificationManager.notificationSettings[key] ?? false
                }
            },
            set: { newValue in
                self.notificationManager.updateNotificationSettings(
                    for: key, sendNotification: newValue, isBefore: isBefore)
                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
            }
        )
    }

    // Binding for optional prayers with auto-enable logic
    private func bindingForOptionalPrayerNotification(key: String, isEnabledBinding: Binding<Bool>)
        -> Binding<Bool>
    {
        Binding(
            get: {
                // If the feature is enabled, we assume notification is enabled (as per earlier simplified logic),
                // OR we check the actual notification dict if I added support there.
                return self.notificationManager.notificationSettings[key]
                    ?? isEnabledBinding.wrappedValue
            },
            set: { newValue in
                // Update notification setting
                self.notificationManager.updateNotificationSettings(
                    for: key, sendNotification: newValue, isBefore: false)

                // Auto-enable feature if notification turned ON
                if newValue {
                    isEnabledBinding.wrappedValue = true
                }

                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
            }
        )
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
}

struct PrayerSettingsView: View {
    @EnvironmentObject var prayerTimeManager: PrayerTimeManager
    @StateObject private var widgetDataManager = WidgetDataManager.shared

    var body: some View {
        Form {
            optionalPrayersSection
            calculationSection
        }
        .navigationTitle("Prayer Settings")
    }

    private var optionalPrayersSection: some View {
        Section(header: Text("Optional Prayers")) {
            Toggle(isOn: $widgetDataManager.isTahajjudEnabled) {
                HStack {
                    Image(systemName: "moon.stars")
                        .foregroundStyle(.purple)
                    VStack(alignment: .leading) {
                        Text("Tahajjud")
                        Text("Last third of the night")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Toggle(isOn: $widgetDataManager.isDuhaEnabled) {
                HStack {
                    Image(systemName: "sun.max")
                        .foregroundStyle(.orange)
                    VStack(alignment: .leading) {
                        Text("Duha")
                        Text("starts 45min after sunrise")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private var calculationSection: some View {
        Section(header: Text("Calculation Method")) {
            SettingsRowWithSelection(text: Text("Madhab"), systemImage: "doc.plaintext") {
                Picker("", selection: $prayerTimeManager.madhab) {
                    ForEach(prayerTimeManager.madhabs, id: \.self) { madhab in
                        Text(madhab == .hanafi ? "Hanafi" : "Default (Shafi, Maliki, Hanbali)")
                            .tag(madhab)
                    }
                }
            }

            SettingsRowWithSelection(text: Text("Institution"), systemImage: "book") {
                Picker("", selection: $prayerTimeManager.method) {
                    ForEach(prayerTimeManager.methods, id: \.self) { method in
                        Text(methodName(for: method)).tag(method)
                    }
                }
                .pickerStyle(NavigationLinkPickerStyle())
            }
        }
    }

    private func methodName(for method: CalculationMethod) -> String {
        switch method {
        case .dubai: return "Dubai"
        case .muslimWorldLeague: return "Muslim World League"
        case .egyptian: return "Egyptian General Authority of Survey"
        case .karachi: return "University of Islamic Sciences, Karachi"
        case .ummAlQura: return "Umm Al-Qura University, Makkah"
        case .moonsightingCommittee: return "Moonsighting Committee Worldwide"
        case .northAmerica: return "Islamic Society of North America"
        case .kuwait: return "Kuwait"
        case .qatar: return "Qatar"
        case .singapore: return "Majlis Ugama Islam Singapura, Singapore"
        case .tehran: return "Institute of Geophysics, University of Tehran"
        case .turkey: return "Diyanet İşleri Başkanlığı, Turkey"
        case .other: return "Other"
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(PrayerTimeManager.shared)
            .environmentObject(NotificationManager.shared)
            .environmentObject(LocationManager())
    }
}
