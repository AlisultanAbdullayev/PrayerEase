//
//  DiyanetHolidayProvider.swift
//  PrayerEase
//

import Foundation

enum DiyanetHolidayProvider {
    static func localHolidays(for hijriYear: Int) -> [IslamicHoliday] {
        let baseline = IslamicHoliday.getBaselineHolidays(for: hijriYear)
        let bundled = loadBundledHolidays(for: hijriYear)
        return mergeDeduplicating(
            baseline: baseline,
            bundled: bundled,
            remote: []
        )
    }

    static func refreshedHolidays(for hijriYear: Int) async -> [IslamicHoliday]? {
        guard let remote = await fetchRemoteHolidays(for: hijriYear) else {
            return nil
        }
        let baseline = IslamicHoliday.getBaselineHolidays(for: hijriYear)
        let bundled = loadBundledHolidays(for: hijriYear)
        return mergeDeduplicating(
            baseline: baseline,
            bundled: bundled,
            remote: remote
        )
    }
}

private extension DiyanetHolidayProvider {
    struct HolidayPayload: Decodable {
        let holidays: [HolidayEntry]
    }

    struct HolidayEntry: Decodable {
        let key: String
        let name: String
        let month: Int
        let day: Int
        let summary: String
        let explanation: String
    }

    static func loadBundledHolidays(for hijriYear: Int) -> [IslamicHoliday] {
        guard
            let url = bundledFileURL(),
            let data = try? Data(contentsOf: url),
            let payload = try? JSONDecoder().decode(HolidayPayload.self, from: data)
        else {
            return []
        }

        return mapEntries(payload.holidays, hijriYear: hijriYear, source: .diyanetBundled)
    }

    static func fetchRemoteHolidays(for hijriYear: Int) async -> [IslamicHoliday]? {
        guard
            let endpoint = liveFeedEndpoint(),
            let url = URL(string: endpoint)
        else {
            return nil
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard
                let http = response as? HTTPURLResponse,
                (200...299).contains(http.statusCode)
            else {
                return nil
            }
            let payload = try JSONDecoder().decode(HolidayPayload.self, from: data)
            return mapEntries(payload.holidays, hijriYear: hijriYear, source: .diyanetRemote)
        } catch {
            return nil
        }
    }

    static func mapEntries(
        _ entries: [HolidayEntry],
        hijriYear: Int,
        source: HolidaySource
    ) -> [IslamicHoliday] {
        let calendar = Calendar(identifier: .islamicUmmAlQura)

        return entries.compactMap { entry in
            var components = DateComponents()
            components.calendar = calendar
            components.year = hijriYear
            components.month = entry.month
            components.day = entry.day

            guard let date = calendar.date(from: components) else {
                return nil
            }

            return IslamicHoliday(
                id: "\(hijriYear)-\(entry.key)",
                key: entry.key,
                name: entry.name,
                date: date,
                description: entry.summary,
                explanation: entry.explanation,
                source: source
            )
        }
    }

    static func mergeDeduplicating(
        baseline: [IslamicHoliday],
        bundled: [IslamicHoliday],
        remote: [IslamicHoliday]
    ) -> [IslamicHoliday] {
        var byKey: [String: IslamicHoliday] = [:]

        for holiday in baseline {
            byKey[holiday.key] = holiday
        }
        for holiday in bundled {
            byKey[holiday.key] = holiday
        }
        for holiday in remote {
            byKey[holiday.key] = holiday
        }

        return byKey.values.sorted { $0.date < $1.date }
    }

    static func liveFeedEndpoint() -> String? {
        if let explicit = ProcessInfo.processInfo.environment["DIYANET_HOLIDAY_FEED_URL"], !explicit.isEmpty {
            return explicit
        }
        if
            let value = Bundle.main.object(
                forInfoDictionaryKey: "DIYANET_HOLIDAY_FEED_URL"
            ) as? String,
            !value.isEmpty
        {
            return value
        }
        return nil
    }

    static func bundledFileURL() -> URL? {
        if let flat = Bundle.main.url(
            forResource: "diyanet_holidays_en",
            withExtension: "json"
        ) {
            return flat
        }
        if let inHolidaysFolder = Bundle.main.url(
            forResource: "diyanet_holidays_en",
            withExtension: "json",
            subdirectory: "Holidays"
        ) {
            return inHolidaysFolder
        }
        return Bundle.main.url(
            forResource: "diyanet_holidays_en",
            withExtension: "json",
            subdirectory: "Resources/Holidays"
        )
    }
}
