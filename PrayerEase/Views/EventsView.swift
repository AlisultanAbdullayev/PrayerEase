//
//  EventsView.swift
//  PrayerEase
//
//  Created by Alisultan Abdullah on 10/30/24.
//

import SwiftUI

struct EventsView: View {
    @EnvironmentObject private var prayerTimesManager: PrayerTimeManager
    @EnvironmentObject private var locationManager: LocationManager

    var body: some View {
        NavigationStack {
            VStack {
                prayerTimesHeader
                prayerTimesList
            }
            .task {
                if let location = locationManager.userLocation {
                    prayerTimesManager.updateLocation(location)
                    prayerTimesManager.fetchMonthlyPrayerTimes(for: Date())
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .navigationTitle("Monthly view")
        }
    }
    
    private var prayerTimesHeader: some View {
        HStack {
            ForEach(["Day","Fajr", "Sunrise", "Dhuhr", "Asr", "Maghrib", "Isha"], id: \.self) { prayerName in
                Text(prayerName)
                    .font(.subheadline)
                    .foregroundStyle(prayerName == "Fajr" || prayerName == "Maghrib" ? Color(uiColor: .label) : .secondary)
                if prayerName != "Isha" {
                    Spacer()
                }
            }
        }
        .padding(.horizontal)
    }
    
    private var prayerTimesList: some View {
        List {
            ForEach(prayerTimesManager.prayerTimesArr.indices, id: \.self) { index in
                if index < prayerTimesManager.prayerTimesArr.count - 1 {
                    CalendarRowView(index: index + 1,
                                    prayerTime: prayerTimesManager.prayerTimesArr[index])
//                CalendarRowView(prayerTime: index)
                        .listRowBackground(index == prayerTimesManager.prayerTimeIndex ? Color.accentColor.opacity(0.5) : nil)
                }
            }
        }
        .listStyle(.grouped)
    }
    
    private func changeDateBy(_ months: Int) -> Date {
        if let date = Calendar.current.date(byAdding: .month, value: months, to: Date()) {
            return date
        }
        return Date()
    }
}


#Preview {
    EventsView()
        .environmentObject(LocationManager())
}

