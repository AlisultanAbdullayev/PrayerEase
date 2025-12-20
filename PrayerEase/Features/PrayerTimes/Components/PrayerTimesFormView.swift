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
            dateAndHijriSection

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
    }

    private var dateAndHijriSection: some View {
        Section {
            VStack {
                Text(viewModel.getFormattedHijriDate())
                    .font(.title2)
                    .foregroundStyle(.accent)
                Text(viewModel.currentDate, style: .date)
                    .foregroundStyle(.secondary)
                    .font(.title3)
            }
            .fontDesign(.rounded)
            .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity, alignment: .center)
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
