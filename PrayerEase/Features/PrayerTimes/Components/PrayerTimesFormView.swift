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

    var body: some View {
        ScrollView {
            VStack {
                if let prayerTimes = prayerTimeManager.prayerTimes {
                    LeftTimeSection(prayers: prayerTimes)
                    PrayerTimesList(prayers: prayerTimes)
                } else {
                    PrayerTimesLoadingView()
                }
            }
            .padding()
        }
        .refreshable {
            // Force location check - shows keep/update prompt if location differs
            await locationManager.refreshLocation(force: true, silent: false)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Group {
                    if #available(iOS 26, *) {
                        VStack(alignment: .trailing) {
                            Text(SharedFormatters.formatHijri(currentDate))
                                .font(.footnote)
                                .bold()
                                .foregroundStyle(.accent)

                            Text(currentDate, style: .date)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .glassEffect(.regular, in: .rect(cornerRadius: 10))
                    } else {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(SharedFormatters.formatHijri(currentDate))
                                .font(.footnote)
                                .bold()
                                .foregroundStyle(.accent)

                            Text(currentDate, style: .date)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                    }
                }
            }
        }
    }

}

private struct PrayerTimesLoadingView: View {
    var body: some View {
        ProgressView("Loading prayer times...")
            .frame(maxWidth: .infinity)
    }
}
