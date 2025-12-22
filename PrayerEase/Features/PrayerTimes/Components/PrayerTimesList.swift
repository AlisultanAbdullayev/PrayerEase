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
        Section {
            ForEach(currentPrayers) { item in
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
    }

    private var currentPrayers: [PrayerItem] {
        var items: [PrayerItem] = []

        // 0. Fajr
        items.append(
            PrayerItem(
                name: "Fajr", time: prayers.fajr, icon: "sunrise", isNative: true,
                nativePrayer: .fajr))

        // 1. Sunrise
        items.append(
            PrayerItem(
                name: "Sunrise", time: prayers.sunrise, icon: "sun.and.horizon", isNative: true,
                nativePrayer: .sunrise))

        // 2. Duha (Optional)
        if widgetDataManager.isDuhaEnabled {
            let duhaTime = prayers.sunrise.addingTimeInterval(45 * 60)  // +45 mins
            items.append(
                PrayerItem(
                    name: "Duha", time: duhaTime, icon: "sun.max.fill", isNative: false,
                    nativePrayer: nil))
        }

        // 3. Dhuhr
        items.append(
            PrayerItem(
                name: "Dhuhr", time: prayers.dhuhr, icon: "sun.max", isNative: true,
                nativePrayer: .dhuhr))

        // 4. Asr
        items.append(
            PrayerItem(
                name: "Asr", time: prayers.asr, icon: "sunset", isNative: true, nativePrayer: .asr))

        // 5. Maghrib
        items.append(
            PrayerItem(
                name: "Maghrib", time: prayers.maghrib, icon: "moon", isNative: true,
                nativePrayer: .maghrib))

        // 6. Isha
        items.append(
            PrayerItem(
                name: "Isha", time: prayers.isha, icon: "moon.stars", isNative: true,
                nativePrayer: .isha))

        // 7. Tahajjud (Next Day Pre-Fajr) -> Appears after Isha
        if widgetDataManager.isTahajjudEnabled {
            // Calculate: Fajr (Tomorrow) - (FajrTomorrow - MaghribToday) / 3
            // Fajr Tomorrow = Fajr Today + 24h
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
        // If native, use Adhan logic primarily, but handle overlaps with custom prayers
        let now = Date()
        let all = currentPrayers

        guard let index = all.firstIndex(of: item) else { return false }
        let nextIndex = index + 1

        let startTime = item.time
        let endTime: Date

        if nextIndex < all.count {
            endTime = all[nextIndex].time
        } else {
            // Last item (Isha or something else). Active until Fajr tomorrow.
            // But visually we just check if now >= start.
            // Better logic: Highlighting usually means "Current Active Prayer Period".
            // If now is 11 PM, Isha is active.
            // If now is 4:05 AM and Tahajjud is 4:00 AM, Tahajjud is active (until Fajr).
            // Default to 24h wrap for last item?
            return now >= startTime || (index == all.count - 1 && now < all[0].time)  // Rough logic for Isha wrap
        }

        return now >= startTime && now < endTime
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
