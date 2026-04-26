//
//  IslamicHolidaysView.swift
//  PrayerEase
//
//  Created by Alisultan Abdullah on 12/19/24.
//

import SwiftUI

struct IslamicHolidaysView: View {
    private let hijriYear: Int
    @State private var holidays: [IslamicHoliday]
    @State private var selectedHoliday: IslamicHoliday?

    init(year: Int? = nil) {
        let currentHijriYear = Calendar(identifier: .islamicUmmAlQura).component(
            .year, from: Date())
        let resolvedYear = year ?? currentHijriYear
        self.hijriYear = resolvedYear
        _holidays = State(
            initialValue: DiyanetHolidayProvider.localHolidays(for: resolvedYear)
        )
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack {
                    ForEach(Array(holidays.enumerated()), id: \.element.id) { _, holiday in
                        Button {
                            selectedHoliday = holiday
                        } label: {
                            HolidayRowView(holiday: holiday, isPassed: isPassed(holiday))
                                .id(holiday.id)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .task(id: hijriYear) {
                if let refreshed = await DiyanetHolidayProvider.refreshedHolidays(for: hijriYear) {
                    holidays = refreshed
                }
                scrollToCurrentDay(using: proxy)
            }
            .onAppear {
                scrollToCurrentDay(using: proxy)
            }
            .onChange(of: holidays.map(\.id)) { _, _ in
                scrollToCurrentDay(using: proxy)
            }
            .sheet(item: $selectedHoliday) { holiday in
                HolidayDetailSheet(holiday: holiday)
            }
        }
    }

    private func isPassed(_ holiday: IslamicHoliday) -> Bool {
        let calendar = Calendar.current
        return calendar.startOfDay(for: holiday.date) < calendar.startOfDay(for: Date())
    }

    private func scrollToCurrentDay(using proxy: ScrollViewProxy) {
        guard let target = nearestHolidayToToday() else { return }
        DispatchQueue.main.async {
            withAnimation {
                proxy.scrollTo(target.id, anchor: .center)
            }
        }
    }

    private func nearestHolidayToToday() -> IslamicHoliday? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)

        if let exact = holidays.first(where: { calendar.isDate($0.date, inSameDayAs: today) }) {
            return exact
        }
        if let upcoming = holidays.first(where: { calendar.startOfDay(for: $0.date) > today }) {
            return upcoming
        }
        return holidays.last
    }
}

private struct HolidayRowView: View {
    let holiday: IslamicHoliday
    let isPassed: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(holiday.name)
                    .font(.headline)
                    .fontWeight(.semibold)

                Text(holiday.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            VStack(alignment: .trailing) {
                Text(holiday.date, style: .date)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(isPassed ? Color.secondary : Color.accentColor)
                    .multilineTextAlignment(.trailing)
            }
        }
        .opacity(isPassed ? 0.52 : 1)
        .padding()
        .background(
            Group {
                if #available(iOS 26, *) {
                    Color.clear.glassEffect(.regular, in: .rect(cornerRadius: 16))
                } else {
                    RoundedRectangle(cornerRadius: 16).fill(.ultraThinMaterial)
                }
            }
        )
    }
}

private struct HolidayDetailSheet: View {
    let holiday: IslamicHoliday
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text(holiday.name)
                        .font(.title3)
                        .fontWeight(.bold)

                    Text(holiday.date.formatted(date: .long, time: .omitted))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text(holiday.explanation)
                        .font(.body)
                        .padding(.top, 6)

                    HStack {
                        Text("Source")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(holiday.source.displayName)
                            .font(.caption.weight(.semibold))
                    }
                    .padding(.top, 8)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }
            .navigationTitle("Holiday details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    IslamicHolidaysView()
}
