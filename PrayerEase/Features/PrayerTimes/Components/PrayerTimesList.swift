//
//  PrayerTimesList.swift
//  PrayerEase
//
//  Created by Alisultan Abdullah on 10/30/24.
//

import Adhan
import SwiftUI

struct PrayerTimesList: View {
    let prayers: PrayerTimes
    @StateObject private var prayerTimeManager = PrayerTimeManager.shared
    @EnvironmentObject private var locationManager: LocationManager

    @StateObject private var widgetDataManager = WidgetDataManager.shared

    // Custom Model for List
    struct PrayerItem: Identifiable, Equatable {
        let id = UUID()
        let name: String
        let time: Date
        let icon: String
        let isNative: Bool  // true if part of Adhan.Prayer
        let nativePrayer: Prayer?
    }

    var body: some View {
        Group {
            Section {
                ForEach(standardPrayers) { item in
                    SalahTimeRowView(
                        imageName: item.icon,
                        salahTime: item.isNative
                            ? prayerTimeManager.formattedPrayerTime(item.time)
                            : formattedTime(item.time),
                        salahName: item.name
                    )
                    .foregroundColor(isHighlighted(item) ? .accentColor : .none)
                }
            } header: {
                Label(
                    locationManager.locationName,
                    systemImage: locationManager.isLocationActive
                        ? "location.circle.fill" : "location.slash"
                )
                .foregroundColor(.accentColor)
            }

            if !optionalPrayers.isEmpty {
                Section(header: Text("Optional Prayers")) {
                    ForEach(optionalPrayers) { item in
                        SalahTimeRowView(
                            imageName: item.icon,
                            salahTime: formattedTime(item.time),
                            salahName: item.name
                        )
                    }
                }
            }
        }
    }

    private var standardPrayers: [PrayerItem] {
        [
            PrayerItem(
                name: "Fajr", time: prayers.fajr, icon: "sunrise", isNative: true,
                nativePrayer: .fajr),
            PrayerItem(
                name: "Sunrise", time: prayers.sunrise, icon: "sun.and.horizon", isNative: true,
                nativePrayer: .sunrise),
            PrayerItem(
                name: "Dhuhr", time: prayers.dhuhr, icon: "sun.max", isNative: true,
                nativePrayer: .dhuhr),
            PrayerItem(
                name: "Asr", time: prayers.asr, icon: "sunset", isNative: true, nativePrayer: .asr),
            PrayerItem(
                name: "Maghrib", time: prayers.maghrib, icon: "moon", isNative: true,
                nativePrayer: .maghrib),
            PrayerItem(
                name: "Isha", time: prayers.isha, icon: "moon.stars", isNative: true,
                nativePrayer: .isha),
        ]
    }

    private var optionalPrayers: [PrayerItem] {
        var items: [PrayerItem] = []

        if widgetDataManager.isDuhaEnabled {
            let duhaTime = prayers.sunrise.addingTimeInterval(45 * 60)
            items.append(
                PrayerItem(
                    name: "Duha", time: duhaTime, icon: "sun.max.fill", isNative: false,
                    nativePrayer: nil))
        }

        if widgetDataManager.isTahajjudEnabled {
            let fajrTomorrow = prayers.fajr.addingTimeInterval(86400)
            let maghribToday = prayers.maghrib
            let nightDuration = fajrTomorrow.timeIntervalSince(maghribToday)
            let lastThird = nightDuration / 3
            let tahajjudTime = fajrTomorrow.addingTimeInterval(-lastThird)

            items.append(
                PrayerItem(
                    name: "Tahajjud", time: tahajjudTime, icon: "moon.stars.fill", isNative: false,
                    nativePrayer: nil))
        }

        return items.sorted { $0.time < $1.time }
    }

    private func isHighlighted(_ item: PrayerItem) -> Bool {
        // Only mark native (standard) prayers
        guard item.isNative else { return false }

        let now = Date()
        // Use standardPrayers directly (since standardPrayers are all native)
        let nativeItems = standardPrayers

        // Find the currently active prayer
        // 1. Before Fajr (Early Morning) -> Highlight Isha (Last native)
        if let first = nativeItems.first, now < first.time {
            // Highlight the Last Native Item (Isha)
            if let last = nativeItems.last {
                return item.name == last.name
            }
        }

        // 2. Iterate to find which slot we are in
        for i in 0..<nativeItems.count {
            let current = nativeItems[i]
            let nextIndex = i + 1

            // Check if we are in this item's slot
            if nextIndex < nativeItems.count {
                let next = nativeItems[nextIndex]
                if now >= current.time && now < next.time {
                    return item.name == current.name
                }
            } else {
                // Last item (Isha). Since we handled "Before Fajr" above,
                // if we are here and now >= current.time, it must be the last item active.
                if now >= current.time {
                    return item.name == current.name
                }
            }
        }

        return false
    }

    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    let date = Date()
    let calendar = Calendar.current
    let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
    let coordinates = Coordinates(latitude: 21.422487, longitude: 39.826206)  // Mecca
    let params = CalculationMethod.moonsightingCommittee.params

    guard
        let prayerTimes = PrayerTimes(
            coordinates: coordinates, date: dateComponents, calculationParameters: params)
    else {
        return Text("Unable to calculate prayer times")
    }

    return PrayerTimesList(prayers: prayerTimes)
        .environmentObject(LocationManager())
}
