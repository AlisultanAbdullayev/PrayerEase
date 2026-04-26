//
//  CalendarRowView.swift
//  PrayerEase
//
//  Created by Alisultan Abdullah on 10/30/24.
//

import SwiftUI
import Adhan

struct CalendarRowView: View {
    
    let index: Int
    let prayerTime: PrayerTimes
    var isToday: Bool = false
    
    var body: some View {
        GridRow {
            Text(index.description)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(isToday ? .accent : .secondary)
            
            Text(prayerTime.fajr.formatted(date: .omitted, time: .shortened))
                .font(.caption2)
                .monospacedDigit()
                .foregroundStyle(isToday ? .accent : .primary)
            
            Text(prayerTime.sunrise.formatted(date: .omitted, time: .shortened))
                .font(.caption2)
                .monospacedDigit()
                .foregroundStyle(isToday ? .accent : .secondary)
            
            Text(prayerTime.dhuhr.formatted(date: .omitted, time: .shortened))
                .font(.caption2)
                .monospacedDigit()
                .foregroundStyle(isToday ? .accent : .secondary)
            
            Text(prayerTime.asr.formatted(date: .omitted, time: .shortened))
                .font(.caption2)
                .monospacedDigit()
                .foregroundStyle(isToday ? .accent : .secondary)
            
            Text(prayerTime.maghrib.formatted(date: .omitted, time: .shortened))
                .font(.caption2)
                .monospacedDigit()
                .foregroundStyle(isToday ? .accent : .primary)
            
            Text(prayerTime.isha.formatted(date: .omitted, time: .shortened))
                .font(.caption2)
                .monospacedDigit()
                .foregroundStyle(isToday ? .accent : .secondary)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.8)
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: prayerTime.date.date ?? Date())
    }
}
