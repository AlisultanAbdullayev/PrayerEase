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
    @Environment(PrayerTimeManager.self) private var prayerTimeManager
    @Environment(NotificationManager.self) private var notificationManager
    @Environment(LocationManager.self) private var locationManager

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
}

// MARK: - Location Settings

struct LocationSettingsView: View {
    @Environment(LocationManager.self) private var locationManager

    var body: some View {
        @Bindable var manager = locationManager

        Form {
            Section(header: Text("Location Services")) {
                Toggle(isOn: $manager.isAutoLocationEnabled) {
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

// MARK: - Notification Settings

struct NotificationSettingsView: View {
    @Environment(NotificationManager.self) private var notificationManager
    @Environment(PrayerTimeManager.self) private var prayerTimeManager
    @Environment(LocationManager.self) private var locationManager

    @State private var widgetDataManager = WidgetDataManager.shared
    @State private var isNotifyBeforeExpanded = false
    @State private var isNotifyExactExpanded = false

    var body: some View {
        Form {
            LiveActivitySection(
                widgetDataManager: widgetDataManager,
                startLiveActivityIfPossible: startLiveActivityIfPossible
            )
            ExactAlertsSection(
                isNotifyExactExpanded: $isNotifyExactExpanded,
                widgetDataManager: widgetDataManager,
                notificationManager: notificationManager,
                bindingForNotification: bindingForNotification,
                bindingForOptionalPrayerNotification: bindingForOptionalPrayerNotification
            )
            QiraaSection(bindingForNotification: bindingForNotification)
            PreAlertsSection(
                isNotifyBeforeExpanded: $isNotifyBeforeExpanded,
                notificationManager: notificationManager,
                bindingForNotification: bindingForNotification
            )
        }
        .navigationTitle("Notifications")
        .onDisappear {
            isNotifyBeforeExpanded = false
        }
    }

    // MARK: - Helpers

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

    private func bindingForOptionalPrayerNotification(key: String, isEnabledBinding: Binding<Bool>)
        -> Binding<Bool>
    {
        Binding(
            get: {
                return self.notificationManager.notificationSettings[key]
                    ?? isEnabledBinding.wrappedValue
            },
            set: { newValue in
                self.notificationManager.updateNotificationSettings(
                    for: key, sendNotification: newValue, isBefore: false)

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

// MARK: - Notification Sections

private struct LiveActivitySection: View {
    @Bindable var widgetDataManager: WidgetDataManager
    let startLiveActivityIfPossible: () async -> Void

    var body: some View {
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
}

private struct ExactAlertsSection: View {
    @Binding var isNotifyExactExpanded: Bool
    @Bindable var widgetDataManager: WidgetDataManager
    let notificationManager: NotificationManager
    let bindingForNotification: (String, Bool) -> Binding<Bool>
    let bindingForOptionalPrayerNotification: (String, Binding<Bool>) -> Binding<Bool>

    var body: some View {
        Section(header: Text("Prayer Alerts")) {
            DisclosureGroup(isExpanded: $isNotifyExactExpanded) {
                ForEach(notificationManager.notificationSettings.keys.sorted(), id: \.self) { key in
                    // Exclude optional prayers and Qiraa (they have their own sections)
                    if key != "Tahajjud" && key != "Duha" && !key.starts(with: "Qiraa") {
                        Toggle(isOn: bindingForNotification(key, false)) {
                            Text(key).tag(key)
                        }
                    }
                }

                Toggle(
                    isOn: bindingForOptionalPrayerNotification(
                        "Duha", $widgetDataManager.isDuhaEnabled)
                ) {
                    Text("Duha")
                }

                Toggle(
                    isOn: bindingForOptionalPrayerNotification(
                        "Tahajjud", $widgetDataManager.isTahajjudEnabled)
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
}

private struct QiraaSection: View {
    let bindingForNotification: (String, Bool) -> Binding<Bool>

    var body: some View {
        Section(header: Text("Qiraa Times")) {
            Toggle(isOn: bindingForNotification("QiraaAfterSunrise", false)) {
                VStack(alignment: .leading) {
                    Text("After Sunrise")
                    Text("45 min after sunrise")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Toggle(isOn: bindingForNotification("QiraaBeforeDhuhr", false)) {
                VStack(alignment: .leading) {
                    Text("Before Dhuhr")
                    Text("45 min before dhuhr")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Toggle(isOn: bindingForNotification("QiraaBeforeMaghrib", false)) {
                VStack(alignment: .leading) {
                    Text("Before Maghrib")
                    Text("45 min before maghrib")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

private struct PreAlertsSection: View {
    @Binding var isNotifyBeforeExpanded: Bool
    @Bindable var notificationManager: NotificationManager
    let bindingForNotification: (String, Bool) -> Binding<Bool>

    var body: some View {
        Section(header: Text("Pre-Prayer Alerts")) {
            DisclosureGroup(isExpanded: $isNotifyBeforeExpanded) {
                ForEach(notificationManager.notificationSettingsBefore.keys.sorted(), id: \.self) {
                    key in
                    Toggle(isOn: bindingForNotification(key, true)) {
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
}

// MARK: - Prayer Settings

struct PrayerSettingsView: View {
    @Environment(PrayerTimeManager.self) private var prayerTimeManager

    @State private var widgetDataManager = WidgetDataManager.shared

    var body: some View {
        Form {
            OptionalPrayersSection(widgetDataManager: widgetDataManager)
            CalculationSection(
                prayerTimeManager: prayerTimeManager,
                methodName: methodName
            )
        }
        .navigationTitle("Prayer Settings")
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

// MARK: - Prayer Settings Sections

private struct OptionalPrayersSection: View {
    @Bindable var widgetDataManager: WidgetDataManager

    var body: some View {
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
}

private struct CalculationSection: View {
    @Bindable var prayerTimeManager: PrayerTimeManager
    let methodName: (CalculationMethod) -> String

    var body: some View {
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
                        Text(methodName(method)).tag(method)
                    }
                }
                .pickerStyle(NavigationLinkPickerStyle())
            }
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environment(PrayerTimeManager.shared)
            .environment(NotificationManager.shared)
            .environment(LocationManager())
    }
}
