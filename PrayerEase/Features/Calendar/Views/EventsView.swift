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

    @State private var selectedView: CalendarTab = .prayers
    @State private var currentDate = Date()

    private enum CalendarTab: String, CaseIterable {
        case prayers = "Prayer Times"
        case holidays = "Holidays"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("View", selection: $selectedView) {
                    ForEach(CalendarTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                if selectedView == .prayers {
                    monthNavigationHeader
                    prayerTimesHeader
                    prayerTimesList
                } else {
                    IslamicHolidaysView()
                }
            }
            .task {
                updateMonthlyPrayerTimes()
            }
            .onChange(of: locationManager.userLocation) { _, _ in
                updateMonthlyPrayerTimes()
            }
            .onChange(of: prayerTimesManager.madhab) { _, _ in
                updateMonthlyPrayerTimes()
            }
            .onChange(of: prayerTimesManager.method) { _, _ in
                updateMonthlyPrayerTimes()
            }
            // Update when month changes
            .onChange(of: currentDate) { _, _ in
                updateMonthlyPrayerTimes()
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .navigationTitle("Calendar")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func updateMonthlyPrayerTimes() {
        if let location = locationManager.userLocation {
            prayerTimesManager.updateLocation(location)
            prayerTimesManager.fetchMonthlyPrayerTimes(for: currentDate)
        }
    }

    private var monthNavigationHeader: some View {
        HStack {
            Button(action: { changeMonth(by: -1) }) {
                Image(systemName: "chevron.left")
                    .padding()
            }

            Spacer()

            Text(currentDate.formatted(.dateTime.month(.wide).year()))
                .font(.headline)
                .foregroundStyle(.primary)

            Spacer()

            Button(action: { changeMonth(by: 1) }) {
                Image(systemName: "chevron.right")
                    .padding()
            }
        }
        .padding(.horizontal)
    }

    private var prayerTimesHeader: some View {
        HStack {
            ForEach(["Day", "Fajr", "Sunrise", "Dhuhr", "Asr", "Maghrib", "Isha"], id: \.self) {
                prayerName in
                Text(prayerName)
                    .font(.subheadline)
                    .foregroundStyle(
                        prayerName == "Fajr" || prayerName == "Maghrib"
                            ? Color(uiColor: .label) : .secondary)
                if prayerName != "Isha" {
                    Spacer()
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    private var prayerTimesList: some View {
        ScrollViewReader { proxy in
            List {
                ForEach(prayerTimesManager.prayerTimesArr.indices, id: \.self) { index in
                    if index < prayerTimesManager.prayerTimesArr.count {
                        CalendarRowView(
                            index: index + 1,
                            prayerTime: prayerTimesManager.prayerTimesArr[index]
                        )
                        .id(index)
                        .listRowBackground(
                            isToday(index: index) ? Color.accentColor.opacity(0.3) : nil)
                    }
                }
            }
            .listStyle(.grouped)
            .onChange(of: prayerTimesManager.dataId) { _, _ in
                scrollToCurrentDay(proxy: proxy)
            }
            .onAppear {
                scrollToCurrentDay(proxy: proxy)
            }
        }
    }

    private func scrollToCurrentDay(proxy: ScrollViewProxy) {
        // Find index of today or displayed month's day
        let calendar = Calendar.current
        let targetComponents = calendar.dateComponents([.year, .month, .day], from: Date())

        if let index = prayerTimesManager.prayerTimesArr.firstIndex(where: {
            $0.date.year == targetComponents.year && $0.date.month == targetComponents.month
                && $0.date.day == targetComponents.day
        }) {
            // Scroll to today if present
            withAnimation {
                proxy.scrollTo(index, anchor: .center)
            }
        }
    }

    private func changeMonth(by value: Int) {
        if let newDate = Calendar.current.date(byAdding: .month, value: value, to: currentDate) {
            currentDate = newDate
        }
    }

    private func isToday(index: Int) -> Bool {
        // Need to check if the day in the list matches real today
        // prayerTimesArr[index].date gives DateComponents
        let todayComponents = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        let itemComponents = prayerTimesManager.prayerTimesArr[index].date
        return todayComponents.year == itemComponents.year
            && todayComponents.month == itemComponents.month
            && todayComponents.day == itemComponents.day
    }
}

#Preview {
    EventsView()
        .environmentObject(LocationManager())
}
