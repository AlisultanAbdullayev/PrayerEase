//
//  IslamicHolidaysView.swift
//  PrayerEase
//
//  Created by Alisultan Abdullah on 12/19/24.
//

import SwiftUI

struct IslamicHolidaysView: View {
    let holidays: [IslamicHoliday]

    // We can default to current Hijri year, or pass it in.
    init(year: Int? = nil) {
        let currentHijriYear = Calendar(identifier: .islamicUmmAlQura).component(
            .year, from: Date())
        self.holidays = IslamicHoliday.getHolidays(for: year ?? currentHijriYear)
    }

    var body: some View {
        List(holidays) { holiday in
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(holiday.name)
                        .font(.headline)
                        .fontWeight(.semibold)

                    Text(holiday.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing) {
                    Text(holiday.date, style: .date)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.accent)
                        .multilineTextAlignment(.trailing)
                }
            }
            .padding(.vertical, 4)
        }
        .listStyle(.grouped)
    }
}

#Preview {
    IslamicHolidaysView()
}
