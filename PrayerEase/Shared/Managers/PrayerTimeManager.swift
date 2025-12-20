//
//  PrayerTimeManager.swift
//  PrayerEase
//
//  Created by Alisultan Abdullah on 10/30/24.
//

import Adhan
import CoreLocation
import Foundation

final class PrayerTimeManager: ObservableObject {
    static let shared = PrayerTimeManager()

    @Published var prayerTimes: PrayerTimes?
    @Published var prayerTimesArr = [PrayerTimes]()
    @Published var prayerTimeIndex: Int?
    @Published var madhab: Madhab = .shafi {
        didSet { UserDefaults.standard.set(madhab.rawValue, forKey: "madhab") }
    }
    @Published var method: CalculationMethod = .turkey {
        didSet { UserDefaults.standard.set(method.rawValue, forKey: "method") }
    }

    @Published var isMethodManuallySet: Bool = false {
        didSet { UserDefaults.standard.set(isMethodManuallySet, forKey: "isMethodManuallySet") }
    }
    @Published var dataId = UUID()

    private var coordinates: Coordinates?

    let madhabs: [Madhab] = [.hanafi, .shafi]
    let methods: [CalculationMethod] = CalculationMethod.allCases

    private init() {
        self.madhab = Madhab(rawValue: UserDefaults.standard.integer(forKey: "madhab")) ?? .shafi
        self.method =
            CalculationMethod(rawValue: UserDefaults.standard.string(forKey: "method") ?? "")
            ?? .turkey
        self.isMethodManuallySet = UserDefaults.standard.bool(forKey: "isMethodManuallySet")
    }

    func autoSelectMethod(for timeZoneIdentifier: String) -> Bool {
        print("DEBUG: autoSelectMethod called for \(timeZoneIdentifier)")
        // Map TimeZone identifiers to methods
        let targetMethod: CalculationMethod?

        // Simplified mapping based on region prefixes or known cities
        if timeZoneIdentifier.contains("Riyadh") {
            targetMethod = .ummAlQura
        } else if timeZoneIdentifier.contains("Istanbul") {
            targetMethod = .turkey
        } else if timeZoneIdentifier.contains("Qatar") {
            targetMethod = .qatar
        }  // Asia/Qatar
        else if timeZoneIdentifier.contains("Kuwait") {
            targetMethod = .kuwait
        } else if timeZoneIdentifier.contains("Dubai") {
            targetMethod = .dubai
        } else if timeZoneIdentifier.contains("Cairo") {
            targetMethod = .egyptian
        } else if timeZoneIdentifier.contains("Karachi") {
            targetMethod = .karachi
        } else if timeZoneIdentifier.contains("Singapore") {
            targetMethod = .singapore
        } else if timeZoneIdentifier.contains("Tehran") {
            targetMethod = .tehran
        } else if timeZoneIdentifier.contains("America") || timeZoneIdentifier.contains("Canada")
            || timeZoneIdentifier.contains("US")
        {
            targetMethod = .northAmerica
        } else if timeZoneIdentifier.contains("London") {
            targetMethod = .moonsightingCommittee
        }  // Or ISNA/London Unified
        else {
            targetMethod = nil
        }

        if let method = targetMethod {
            self.method = method
            return true
        }
        return false
    }

    func updateLocation(_ location: CLLocation) {
        self.coordinates = Coordinates(
            latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
    }

    func getPrayerTimes(for date: Date) -> PrayerTimes? {
        guard let coordinates = self.coordinates else { return nil }

        var params = method.params
        params.madhab = madhab

        let components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return PrayerTimes(
            coordinates: coordinates, date: components, calculationParameters: params)
    }

    func fetchPrayerTimes(for date: Date) {
        guard let prayerTimes = getPrayerTimes(for: date) else { return }

        self.prayerTimes = prayerTimes
        updateCurrentPrayerTime(for: date)
    }

    // TODO: Nado reshit calendar
    func fetchMonthlyPrayerTimes(for date: Date = Date()) {
        guard let coordinates = self.coordinates else { return }

        let calendar = Calendar.current

        // Get the start of the month
        guard
            let startOfMonth = calendar.date(
                from: calendar.dateComponents([.year, .month], from: date))
        else { return }

        // Get the range of days in the month
        guard let range = calendar.range(of: .day, in: .month, for: startOfMonth) else { return }

        prayerTimesArr.removeAll()

        for day in range {
            let currentDate = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth)!
            let dateComponents = calendar.dateComponents([.year, .month, .day], from: currentDate)

            if let prayers = PrayerTimes(
                coordinates: coordinates, date: dateComponents, calculationParameters: method.params
            ) {
                prayerTimesArr.append(prayers)
            }
        }

        // Update the prayerTimeIndex to point to today's prayer times
        updateCurrentPrayerTime(for: date)

        dataId = UUID()
        objectWillChange.send()
    }

    private func updateCurrentPrayerTime(for date: Date) {
        prayerTimeIndex = getPrayerTimeIndex(for: date)
    }

    private func getPrayerTimeIndex(for date: Date) -> Int? {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return prayerTimesArr.firstIndex { $0.date == components }
    }

    func formattedPrayerTime(_ prayerTime: Date?) -> String {
        guard let prayerTime = prayerTime else { return "N/A" }
        let formatter = DateFormatter()
        formatter.timeZone = .current
        formatter.timeStyle = .short
        return formatter.string(from: prayerTime)
    }
}
