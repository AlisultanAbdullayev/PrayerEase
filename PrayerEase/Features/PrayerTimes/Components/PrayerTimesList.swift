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
    @Environment(PrayerTimeManager.self) private var prayerTimeManager
    @Environment(WidgetDataManager.self) private var widgetDataManager

    let prayers: PrayerTimes

    // Custom Model for List
    struct PrayerItem: Identifiable, Equatable {
        let id: String
        let name: String
        let time: Date
        let icon: String
        let isNative: Bool
        let nativePrayer: Prayer?
    }

    var body: some View {
        let standard = standardPrayers
        let optional = optionalPrayers
        VStack {
            // Standard Prayers Card
            VStack {
                // Header
                HStack {
                    Label(
                        locationManager.locationName,
                        systemImage: locationManager.isLocationActive
                            ? "location.circle.fill" : "location.slash"
                    )
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.accent)
                    
                    Spacer()
                }
                .padding()
                
                Divider()
                
                ForEach(Array(standard.enumerated()), id: \.element.id) { index, item in
                    SalahTimeRowView(
                        imageName: item.icon,
                        salahTime: item.isNative
                            ? prayerTimeManager.formattedPrayerTime(item.time)
                            : formattedTime(item.time),
                        salahName: item.name
                    )
                    .foregroundStyle(isHighlighted(item, in: standard) ? .accent : .primary)
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                    
                    if index < standard.count - 1 {
                        Divider()
                    }
                }
            }
            .background(
                Group {
                    if #available(iOS 26, *) {
                        Color.clear.glassEffect(.regular, in: .rect(cornerRadius: 24))
                    } else {
                        RoundedRectangle(cornerRadius: 24).fill(.ultraThinMaterial)
                    }
                }
            )
            
            // Optional Prayers Card
            if !optional.isEmpty {
                VStack {
                    HStack {
                        Text("Optional Prayers")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.accent)
                        Spacer()
                    }
                    .padding()
                    
                    Divider()
                    
                    ForEach(Array(optional.enumerated()), id: \.element.id) { index, item in
                        SalahTimeRowView(
                            imageName: item.icon,
                            salahTime: formattedTime(item.time),
                            salahName: item.name
                        )
                        .padding(.horizontal)
                        .padding(.vertical, 10)
                        
                        if index < optional.count - 1 {
                            Divider()
                        }
                    }
                }
                .background(
                    Group {
                        if #available(iOS 26, *) {
                            Color.clear.glassEffect(.regular, in: .rect(cornerRadius: 24))
                        } else {
                            RoundedRectangle(cornerRadius: 24).fill(.ultraThinMaterial)
                        }
                    }
                )
            }
        }
    }

    private var standardPrayers: [PrayerItem] {
        [
            PrayerItem(
                id: PrayerNames.fajr, name: PrayerNames.fajr, time: prayers.fajr, icon: "sunrise",
                isNative: true,
                nativePrayer: .fajr),
            PrayerItem(
                id: PrayerNames.sunrise, name: PrayerNames.sunrise, time: prayers.sunrise,
                icon: "sun.and.horizon", isNative: true,
                nativePrayer: .sunrise),
            PrayerItem(
                id: PrayerNames.dhuhr, name: PrayerNames.dhuhr, time: prayers.dhuhr,
                icon: "sun.max", isNative: true,
                nativePrayer: .dhuhr),
            PrayerItem(
                id: PrayerNames.asr, name: PrayerNames.asr, time: prayers.asr, icon: "sunset",
                isNative: true,
                nativePrayer: .asr),
            PrayerItem(
                id: PrayerNames.maghrib, name: PrayerNames.maghrib, time: prayers.maghrib,
                icon: "moon", isNative: true,
                nativePrayer: .maghrib),
            PrayerItem(
                id: PrayerNames.isha, name: PrayerNames.isha, time: prayers.isha,
                icon: "moon.stars", isNative: true,
                nativePrayer: .isha),
        ]
    }

    private var optionalPrayers: [PrayerItem] {
        var items: [PrayerItem] = []

        if widgetDataManager.isDuhaEnabled {
            let duhaTime = PrayerTimeCalculator.duhaTime(from: prayers.sunrise)
            items.append(
                PrayerItem(
                    id: PrayerNames.duha, name: PrayerNames.duha, time: duhaTime,
                    icon: "sun.max.fill", isNative: false, nativePrayer: nil))
        }

        if widgetDataManager.isTahajjudEnabled {
            let fajrTomorrow = prayers.fajr.addingTimeInterval(TimeIntervals.oneDay)
            let tahajjudTime = PrayerTimeCalculator.tahajjudTime(
                maghrib: prayers.maghrib,
                fajrTomorrow: fajrTomorrow
            )

            items.append(
                PrayerItem(
                    id: PrayerNames.tahajjud, name: PrayerNames.tahajjud, time: tahajjudTime,
                    icon: "moon.stars.fill", isNative: false, nativePrayer: nil))
        }

        return items.sorted { $0.time < $1.time }
    }

    private func isHighlighted(_ item: PrayerItem, in nativeItems: [PrayerItem]) -> Bool {
        guard item.isNative else { return false }

        let now = Date()

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
