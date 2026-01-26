//
//  EventsView.swift
//  PrayerEase
//
//  Created by Alisultan Abdullah on 10/30/24.
//

import SwiftUI

struct EventsView: View {
    @Environment(PrayerTimeManager.self) private var prayerTimesManager
    @Environment(LocationManager.self) private var locationManager

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
                .colorMultiply(.accentColor)
                .pickerStyle(.segmented)
                .padding()

                if selectedView == .prayers {
                    MonthNavigationHeaderView(
                        currentDate: currentDate,
                        onChangeMonth: changeMonth
                    )
                    PrayerTimesHeaderView()
                    PrayerTimesListView()
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

    private func changeMonth(by value: Int) {
        if let newDate = Calendar.current.date(byAdding: .month, value: value, to: currentDate) {
            currentDate = newDate
        }
    }
}

// MARK: - Subviews
private struct MonthNavigationHeaderView: View {
    let currentDate: Date
    let onChangeMonth: (Int) -> Void

    var body: some View {
        HStack {
            Button(action: { onChangeMonth(-1) }) {
                Image(systemName: "chevron.left")
                    .padding()
            }

            Spacer()

            Text(currentDate.formatted(.dateTime.month(.wide).year()))
                .font(.headline)
                .foregroundStyle(.primary)

            Spacer()

            Button(action: { onChangeMonth(1) }) {
                Image(systemName: "chevron.right")
                    .padding()
            }
        }
        .padding(.horizontal)
    }
}

private struct PrayerTimesHeaderView: View {
    private let prayerNames = ["Day", "Fajr", "Sunrise", "Dhuhr", "Asr", "Maghrib", "Isha"]

    var body: some View {
        HStack {
            ForEach(prayerNames, id: \.self) { prayerName in
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
}

private struct PrayerTimesListView: View {
    @Environment(PrayerTimeManager.self) private var prayerTimesManager

    var body: some View {
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
        let calendar = Calendar.current
        let targetComponents = calendar.dateComponents([.year, .month, .day], from: Date())

        if let index = prayerTimesManager.prayerTimesArr.firstIndex(where: {
            $0.date.year == targetComponents.year && $0.date.month == targetComponents.month
                && $0.date.day == targetComponents.day
        }) {
            withAnimation {
                proxy.scrollTo(index, anchor: .center)
            }
        }
    }

    private func isToday(index: Int) -> Bool {
        let todayComponents = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        let itemComponents = prayerTimesManager.prayerTimesArr[index].date
        return todayComponents.year == itemComponents.year
            && todayComponents.month == itemComponents.month
            && todayComponents.day == itemComponents.day
    }
}

#Preview {
    EventsView()
        .environment(LocationManager())
}
