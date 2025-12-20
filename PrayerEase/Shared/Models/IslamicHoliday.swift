//
//  IslamicHoliday.swift
//  PrayerEase
//
//  Created by Alisultan Abdullah on 12/19/24.
//

import Foundation

struct IslamicHoliday: Identifiable {
    let id = UUID()
    let name: String
    let date: Date
    let description: String
}

extension IslamicHoliday {
    static func getHolidays(for hijriYear: Int) -> [IslamicHoliday] {
        let calendar = Calendar(identifier: .islamicUmmAlQura)
        var holidays: [IslamicHoliday] = []

        // Helper to create date
        func createDate(month: Int, day: Int) -> Date? {
            var components = DateComponents()
            components.calendar = calendar
            components.year = hijriYear
            components.month = month
            components.day = day
            return calendar.date(from: components)
        }

        let holidayData: [(month: Int, day: Int, name: String, desc: String)] = [
            (1, 1, "Islamic New Year", "The beginning of the new Hijri year."),
            (1, 10, "Ashura", "Commemoration of Moses crossing the Red Sea."),
            (9, 1, "Ramadan Start", "The first day of the holy month of fasting."),
            (
                10, 1, "Eid al-Fitr",
                "Festival of breaking the fast designated by the Prophet Muhammad."
            ),
            (12, 9, "Day of Arafah", "The holiest day in the Islamic calendar."),
            (
                12, 10, "Eid al-Adha",
                "Festival of Sacrifice, honoring the willingness of Ibrahim to sacrifice his son."
            ),
        ]

        for data in holidayData {
            if let date = createDate(month: data.month, day: data.day) {
                holidays.append(IslamicHoliday(name: data.name, date: date, description: data.desc))
            }
        }

        return holidays.sorted { $0.date < $1.date }
    }
}
