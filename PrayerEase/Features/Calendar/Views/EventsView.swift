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
            VStack {
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
                    PrayerTimesGridView()
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
            Button("Previous", systemImage: "chevron.left") {
                onChangeMonth(-1)
            }
            .padding()

            Spacer()

            Text(currentDate.formatted(.dateTime.month(.wide).year()))
                .font(.headline)
                .foregroundStyle(.primary)

            Spacer()

            Button("Next", systemImage: "chevron.right") {
                onChangeMonth(1)
            }
            .padding()
        }
        .padding(.horizontal)
    }
}

private struct PrayerTimesGridView: View {
    @Environment(PrayerTimeManager.self) private var prayerTimesManager
    private let prayerNames = ["Day", "Fajr", "Sunrise", "Dhuhr", "Asr", "Maghrib", "Isha"]

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                ScrollView(.horizontal, showsIndicators: false) {
                    Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 8) {
                        GridRow {
                            ForEach(prayerNames, id: \.self) { prayerName in
                                Text(prayerName)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundStyle(
                                        prayerName == "Fajr" || prayerName == "Maghrib"
                                            ? .primary : .secondary)
                            }
                        }
                        .padding(.bottom)

                        ForEach(
                            prayerTimesManager.prayerTimesArr.enumerated(),
                            id: \.element.date
                        ) { index, prayerTime in
                            CalendarRowView(
                                index: index + 1,
                                prayerTime: prayerTime,
                                isToday: isToday(components: prayerTime.date)
                            )
                            .id(prayerTime.date)
                            
                            if index < prayerTimesManager.prayerTimesArr.count - 1 {
                                Divider()
                            }
                        }
                    }
                    .padding()
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
                .padding(.horizontal)
            }
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

        if let target = prayerTimesManager.prayerTimesArr.first(where: {
            $0.date.year == targetComponents.year
                && $0.date.month == targetComponents.month
                && $0.date.day == targetComponents.day
        }) {
            withAnimation {
                proxy.scrollTo(target.date, anchor: .center)
            }
        }
    }

    private func isToday(components: DateComponents) -> Bool {
        let todayComponents = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        return todayComponents.year == components.year
            && todayComponents.month == components.month
            && todayComponents.day == components.day
    }
}

#Preview {
    EventsView()
        .environment(LocationManager())
}
