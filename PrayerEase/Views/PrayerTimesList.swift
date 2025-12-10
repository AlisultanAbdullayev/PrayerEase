//
//  PrayerTimesList.swift
//  PrayerEase
//
//  Created by Alisultan Abdullah on 10/30/24.
//

import SwiftUI
import Adhan

struct PrayerTimesList: View {
    let prayers: PrayerTimes
    @StateObject private var prayerTimeManager = PrayerTimeManager.shared
    @EnvironmentObject private var locationManager: LocationManager
    
    private let prayerInfo: [(Prayer, String, String)] = [
        (.fajr, "sunrise", "Fajr"),
        (.sunrise, "sun.and.horizon", "Sunrise"),
        (.dhuhr, "sun.max", "Dhuhr"),
        (.asr, "sunset", "Asr"),
        (.maghrib, "moon", "Maghrib"),
        (.isha, "moon.stars", "Isha")
    ]
    
    var body: some View {
        Section {
            ForEach(prayerInfo, id: \.2) { prayer, imageName, prayerName in
                SalahTimeRowView(
                    imageName: imageName,
                    salahTime: prayerTimeManager.formattedPrayerTime(prayerTime(for: prayer)),
                    salahName: prayerName
                )
                .foregroundColor(prayers.currentPrayer() == prayer ? .accent : nil)
            }
        } header: {
            Button {
                locationManager.requestLocation()
            } label: {
                Label(locationManager.locationName,
                      systemImage: locationManager.isLocationActive ? "location.circle.fill" : "location.slash")
                    .foregroundColor(.accentColor)
            }
        }
    }
    
    private func prayerTime(for prayer: Prayer) -> Date {
        switch prayer {
        case .fajr: return prayers.fajr
        case .sunrise: return prayers.sunrise
        case .dhuhr: return prayers.dhuhr
        case .asr: return prayers.asr
        case .maghrib: return prayers.maghrib
        case .isha: return prayers.isha
        }
    }
}

#Preview {
    let date = Date()
    let calendar = Calendar.current
    let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
    let coordinates = Coordinates(latitude: 21.422487, longitude: 39.826206) // Mecca
    let params = CalculationMethod.moonsightingCommittee.params
    
    guard let prayerTimes = PrayerTimes(coordinates: coordinates, date: dateComponents, calculationParameters: params) else {
        return Text("Unable to calculate prayer times")
    }
    
    return PrayerTimesList(prayers: prayerTimes)
        .environmentObject(LocationManager())
}
