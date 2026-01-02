//
//  PrayerTimesList.swift
//  PrayerEase
//
//  Created by Alisultan Abdullah on 10/30/24.
//

import Adhan
import SwiftUI

struct PrayerTimesList: View {
    @Environment(LocationManager.self) private var locationManager

    @State private var prayerTimeManager = PrayerTimeManager.shared
    @State private var widgetDataManager = WidgetDataManager.shared

    let prayers: PrayerTimes

    // Custom Model for List
    struct PrayerItem: Identifiable, Equatable {
        let id = UUID()
        let name: String
        let time: Date
        let icon: String
        let isNative: Bool
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
                name: PrayerNames.fajr, time: prayers.fajr, icon: "sunrise", isNative: true,
                nativePrayer: .fajr),
            PrayerItem(
                name: PrayerNames.sunrise, time: prayers.sunrise, icon: "sun.and.horizon",
                isNative: true,
                nativePrayer: .sunrise),
            PrayerItem(
                name: PrayerNames.dhuhr, time: prayers.dhuhr, icon: "sun.max", isNative: true,
                nativePrayer: .dhuhr),
            PrayerItem(
                name: PrayerNames.asr, time: prayers.asr, icon: "sunset", isNative: true,
                nativePrayer: .asr),
            PrayerItem(
                name: PrayerNames.maghrib, time: prayers.maghrib, icon: "moon", isNative: true,
                nativePrayer: .maghrib),
            PrayerItem(
                name: PrayerNames.isha, time: prayers.isha, icon: "moon.stars", isNative: true,
                nativePrayer: .isha),
        ]
    }

    private var optionalPrayers: [PrayerItem] {
        var items: [PrayerItem] = []

        if widgetDataManager.isDuhaEnabled {
            let duhaTime = PrayerTimeCalculator.duhaTime(from: prayers.sunrise)
            items.append(
                PrayerItem(
                    name: PrayerNames.duha, time: duhaTime, icon: "sun.max.fill", isNative: false,
                    nativePrayer: nil))
        }

        if widgetDataManager.isTahajjudEnabled {
            let fajrTomorrow = prayers.fajr.addingTimeInterval(TimeIntervals.oneDay)
            let tahajjudTime = PrayerTimeCalculator.tahajjudTime(
                maghrib: prayers.maghrib,
                fajrTomorrow: fajrTomorrow
            )

            items.append(
                PrayerItem(
                    name: PrayerNames.tahajjud, time: tahajjudTime, icon: "moon.stars.fill",
                    isNative: false,
                    nativePrayer: nil))
        }

        return items.sorted { $0.time < $1.time }
    }

    private func isHighlighted(_ item: PrayerItem) -> Bool {
        guard item.isNative else { return false }

        let now = Date()
        let nativeItems = standardPrayers

        if let first = nativeItems.first, now < first.time {
            if let last = nativeItems.last {
                return item.name == last.name
            }
        }

        for i in 0..<nativeItems.count {
            let current = nativeItems[i]
            let nextIndex = i + 1

            if nextIndex < nativeItems.count {
                let next = nativeItems[nextIndex]
                if now >= current.time && now < next.time {
                    return item.name == current.name
                }
            } else {
                if now >= current.time {
                    return item.name == current.name
                }
            }
        }

        return false
    }

    private func formattedTime(_ date: Date) -> String {
        SharedFormatters.time.string(from: date)
    }
}

#Preview {
    let date = Date()
    let calendar = Calendar.current
    let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
    let coordinates = Coordinates(latitude: 21.422487, longitude: 39.826206)
    let params = CalculationMethod.moonsightingCommittee.params

    if let prayerTimes = PrayerTimes(
        coordinates: coordinates, date: dateComponents, calculationParameters: params)
    {
        PrayerTimesList(prayers: prayerTimes)
            .environment(LocationManager())
    } else {
        Text("Unable to calculate prayer times")
    }
}
