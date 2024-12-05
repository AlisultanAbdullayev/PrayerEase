//
//  CalendarRowView.swift
//  PrayerEase
//
//  Created by Alisultan Abdullah on 10/30/24.
//

import SwiftUI

import SwiftUI
import Adhan

struct CalendarRowView: View {
    
    let index: Int
    let prayerTime: PrayerTimes
    
    var body: some View {
        HStack {
            Text(index.description)
            Spacer()
            Text(prayerTime.fajr.formatted(date: .omitted, time: .shortened))
                .foregroundStyle(Color(uiColor: .label))
            Spacer()
            Text(prayerTime.sunrise.formatted(date: .omitted, time: .shortened))
            Spacer()
            Text(prayerTime.dhuhr.formatted(date: .omitted, time: .shortened))
            Spacer()
            Text(prayerTime.asr.formatted(date: .omitted, time: .shortened))
            Spacer()
            Text(prayerTime.maghrib.formatted(date: .omitted, time: .shortened))
                .foregroundStyle(Color(uiColor: .label))
            Spacer()
            Text(prayerTime.isha.formatted(date: .omitted, time: .shortened))
        }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: prayerTime.date.date ?? Date())
    }
}
