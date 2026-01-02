//
//  PrayerTimesFormView.swift
//  PrayerEase
//
//  Created by Alisultan Abdullah on 12/20/24.
//

import Adhan
import SwiftUI

struct PrayerTimesFormView: View {
    @Environment(PrayerTimeManager.self) private var prayerTimeManager
    @Environment(LocationManager.self) private var locationManager

    let currentDate: Date
    let hijriCalendar: Calendar

    var body: some View {
        Form {
            if let prayerTimes = prayerTimeManager.prayerTimes {
                LeftTimeSection(prayers: prayerTimes)
                PrayerTimesList(prayers: prayerTimes)
            } else {
                progressView
            }
        }
        .refreshable {
            // Force location check - shows keep/update prompt if location differs
            await locationManager.refreshLocation(force: true, silent: false)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(formattedHijriDate)
                        .font(.footnote)
                        .fontWeight(.bold)
                        .foregroundStyle(.accent)

                    Text(currentDate, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
        }
    }

    private var formattedHijriDate: String {
        let formatter = DateFormatter()
        formatter.calendar = hijriCalendar
        formatter.dateFormat = "d MMMM yyyy"
        return formatter.string(from: currentDate)
    }

    private var progressView: some View {
        ProgressView("Loading prayer times...")
            .frame(maxWidth: .infinity)
    }
}
