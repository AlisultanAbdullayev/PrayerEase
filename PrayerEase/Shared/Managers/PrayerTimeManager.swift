//
//  PrayerTimeManager.swift
//  PrayerEase
//
//  Created by Alisultan Abdullah on 10/30/24.
//

import Adhan
import CoreLocation
import Foundation

@MainActor
@Observable
final class PrayerTimeManager {
    static let shared = PrayerTimeManager()

    // MARK: - App Group Configuration
    static let appGroupId = AppConstants.appGroupId

    private var userDefaults: UserDefaults {
        UserDefaults(suiteName: Self.appGroupId) ?? .standard
    }

    var prayerTimes: PrayerTimes?
    var prayerTimesArr = [PrayerTimes]()
    var prayerTimeIndex: Int?

    var madhab: Madhab = .shafi {
        didSet { userDefaults.set(madhab.rawValue, forKey: "madhab") }
    }

    var method: CalculationMethod = .turkey {
        didSet { userDefaults.set(method.rawValue, forKey: "method") }
    }

    var isMethodManuallySet: Bool = false {
        didSet { userDefaults.set(isMethodManuallySet, forKey: "isMethodManuallySet") }
    }

    var dataId = UUID()

    private var coordinates: Coordinates?

    let madhabs: [Madhab] = [.hanafi, .shafi]
    let methods: [CalculationMethod] = CalculationMethod.allCases

    private init() {
        self.madhab = Madhab(rawValue: userDefaults.integer(forKey: "madhab")) ?? .shafi
        self.method =
            CalculationMethod(rawValue: userDefaults.string(forKey: "method") ?? "")
            ?? .turkey
        self.isMethodManuallySet = userDefaults.bool(forKey: "isMethodManuallySet")
    }

    func autoSelectMethod(for timeZoneIdentifier: String) -> Bool {
        print("DEBUG: autoSelectMethod called for \(timeZoneIdentifier)")

        if let targetMethod = CalculationMethodHelper.autoSelectMethod(for: timeZoneIdentifier) {
            self.method = targetMethod
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

    func fetchMonthlyPrayerTimes(for date: Date = Date()) {
        guard let coordinates = self.coordinates else { return }

        let calendar = Calendar.current

        guard
            let startOfMonth = calendar.date(
                from: calendar.dateComponents([.year, .month], from: date))
        else { return }

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

        updateCurrentPrayerTime(for: date)
        dataId = UUID()
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
        DateFormatters.formatTime(prayerTime)
    }
}
