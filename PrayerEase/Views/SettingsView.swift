//
//  SettingsView.swift
//  PrayerEase
//
//  Created by Alisultan Abdullah on 10/30/24.
//

import SwiftUI
import Adhan

struct SettingsView: View {
    
    @EnvironmentObject private var prayerTimeManager: PrayerTimeManager
    @EnvironmentObject private var notificationManager: NotificationManager
    @State private var isNotifyBeforeExpanded = false
    
    var body: some View {
        Form {
            notificationSection
            calculationSection
            footerSection
        }
        .onChange(of: notificationManager.beforeMinutes) { _,_ in
            notificationManager.scheduleLongTermNotifications()
        }
        .onDisappear {
            isNotifyBeforeExpanded = false
        }
        .navigationTitle("Settings")
    }
    
    private var notificationSection: some View {
        Section(header: Text("Notification:")) {
            notifyBeforeGroup
            minutesBeforePicker
        }
    }
    
    private var notifyBeforeGroup: some View {
        DisclosureGroup(isExpanded: $isNotifyBeforeExpanded) {
            ForEach(notificationManager.notificationSettingsBefore.keys.sorted(), id: \.self) { key in
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
            Picker("Minute", selection: $notificationManager.beforeMinutes) {
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
            Picker("Madhab", selection: $prayerTimeManager.madhab) {
                ForEach(prayerTimeManager.madhabs, id: \.self) { madhab in
                    Text(madhab == .hanafi ? "Hanafi" : "Default (Shafi, Maliki, Hanbali)")
                        .tag(madhab)
                }
            }
        }
    }
    
    private var institutionPicker: some View {
        SettingsRowWithSelection(text: Text("Institution"), systemImage: "book") {
            Picker("Institute", selection: $prayerTimeManager.method) {
                ForEach(prayerTimeManager.methods, id: \.self) { method in
                    Text(methodName(for: method)).tag(method)
                }
            }
            .pickerStyle(NavigationLinkPickerStyle())
        }
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
                self.notificationManager.updateNotificationSettings(for: key, sendNotification: newValue, isBefore: true)
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
}

