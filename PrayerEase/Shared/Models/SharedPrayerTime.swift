//
//  SharedPrayerTime.swift
//  PrayerEase
//
//  Created by Alisultan Abdullah on 12/21/25.
//

import Foundation

struct SharedPrayerTime: Identifiable, Equatable, Codable, Hashable, Sendable {
    var id: String { name }
    let name: String
    let time: Date

    var iconName: String {
        switch name.lowercased() {
        case "fajr": return "circle.lefthalf.filled"
        case "sunrise": return "sunrise.fill"
        case "dhuhr": return "sun.max.fill"
        case "asr": return "sun.haze.fill"
        case "maghrib": return "sunset.fill"
        case "isha": return "moon.stars.fill"
        case "duha": return "sun.max.fill"
        case "tahajjud": return "moon.stars.fill"
        default: return "circle.fill"
        }
    }

    var shortName: String {
        String(name.prefix(3)).uppercased()
    }

    var timeString: String {
        time.formatted(.dateTime.hour().minute())
    }

    var amPmString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "a"
        return formatter.string(from: time)
    }

    var hourMinuteString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm"
        return formatter.string(from: time)
    }
}
