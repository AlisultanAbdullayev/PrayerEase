//
//  IslamicHoliday.swift
//  PrayerEase
//
//  Created by Alisultan Abdullah on 12/19/24.
//

import Foundation

struct IslamicHoliday: Identifiable {
    let id: String
    let key: String
    let name: String
    let date: Date
    let description: String
    let explanation: String
    let source: HolidaySource
}

enum HolidaySource: String, Sendable {
    case baseline
    case diyanetBundled
    case diyanetRemote

    var displayName: String {
        switch self {
        case .baseline:
            return "Calendar baseline"
        case .diyanetBundled, .diyanetRemote:
            return "Diyanet"
        }
    }
}

extension IslamicHoliday {
    static func getHolidays(for hijriYear: Int) -> [IslamicHoliday] {
        getBaselineHolidays(for: hijriYear)
    }

    static func getBaselineHolidays(for hijriYear: Int) -> [IslamicHoliday] {
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

        let holidayData: [(key: String, month: Int, day: Int, name: String, desc: String, explanation: String)] = [
            (
                "islamic-new-year", 1, 1, "Islamic New Year", "The beginning of the new Hijri year.",
                "The first day of Muharram marks the start of a new Hijri year and commemorates the Hijrah era."
            ),
            (
                "ashura", 1, 10, "Ashura", "Commemoration of Musa's deliverance.",
                "Ashura is observed on 10 Muharram. In Sunni tradition it is linked to the rescue of Prophet Musa and is recommended for voluntary fasting."
            ),
            (
                "ramadan-start", 9, 1, "Ramadan Start", "The first day of the holy month of fasting.",
                "The beginning of Ramadan marks the start of daily fasting from dawn to sunset and increased devotion."
            ),
            (
                "eid-al-fitr", 10, 1, "Eid al-Fitr",
                "Festival of breaking the Ramadan fast.",
                "Eid al-Fitr starts on 1 Shawwal after Ramadan and is celebrated with congregational prayer, charity, and family visits."
            ),
            (
                "day-of-arafah", 12, 9, "Day of Arafah", "The holiest day in the Islamic calendar.",
                "The Day of Arafah is observed on 9 Dhu al-Hijjah and holds central importance during Hajj."
            ),
            (
                "eid-al-adha", 12, 10, "Eid al-Adha",
                "Festival of Sacrifice honoring Prophet Ibrahim's devotion.",
                "Eid al-Adha begins on 10 Dhu al-Hijjah and commemorates Prophet Ibrahim's obedience to Allah."
            ),
        ]

        for data in holidayData {
            if let date = createDate(month: data.month, day: data.day) {
                holidays.append(
                    IslamicHoliday(
                        id: "\(hijriYear)-\(data.key)",
                        key: data.key,
                        name: data.name,
                        date: date,
                        description: data.desc,
                        explanation: data.explanation,
                        source: .baseline
                    )
                )
            }
        }

        return holidays.sorted { $0.date < $1.date }
    }
}
