//
//  PrayerTimesFormView.swift
//  PrayerEase
//
//  Created by Alisultan Abdullah on 12/20/24.
//

import Adhan
import SwiftUI

struct PrayerTimesFormView: View {
    @ObservedObject var viewModel: PrayerTimesViewModel
    @EnvironmentObject var prayerTimeManager: PrayerTimeManager
    @EnvironmentObject var locationManager: LocationManager

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
            await locationManager.refreshLocation()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(viewModel.getFormattedHijriDate())
                        .font(.footnote)
                        .fontWeight(.bold)
                        .foregroundStyle(.accent)

                    Text(viewModel.currentDate, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
        }
    }

    private var progressView: some View {
        Group {
            if !viewModel.isLoadFailed {
                ProgressView("Try to load the data...")
                    .frame(maxWidth: .infinity)
                    .task {
                        try? await Task.sleep(nanoseconds: 5_000_000_000)
                        viewModel.isLoadFailed = true
                    }
            } else {
                Text("Data can not be loaded!")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }
}
