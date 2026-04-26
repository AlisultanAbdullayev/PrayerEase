//
//  LeftTimeSection.swift
//  PrayerEase
//
//  Created by Alisultan Abdullah on 10/30/24.
//

import SwiftUI
import Adhan

struct LeftTimeSection: View {
    let prayers: PrayerTimes

    private var timeUntilNextPrayer: Date {
        if let nextPrayer = prayers.nextPrayer() {
            return prayers.time(for: nextPrayer)
        } else {
            return Calendar.current.date(byAdding: .day, value: 1, to: prayers.fajr)!
        }
    }

    private var timeRemainingText: Text {
        Text(timeUntilNextPrayer, style: .timer)
    }

    var body: some View {
        VStack(alignment: .leading) {
            Text("Time until next prayer")
                .foregroundStyle(.accent)
                .font(.subheadline)
                .padding(.horizontal)

                timeRemainingText
                    .frame(maxWidth: .infinity, alignment: .center)
                    .font(.largeTitle)
                    .bold()
                    .id(prayers.fajr)
                    .customGlassContainer(glassType: .clear)

        }
    }
}

#Preview {
    let coordinates = Coordinates(latitude: 21.422487, longitude: 39.826206)
    let date = Date()
    let dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: date)
    let params = CalculationMethod.muslimWorldLeague.params
    if let prayers = PrayerTimes(
        coordinates: coordinates, date: dateComponents, calculationParameters: params
    ) {
        List {
            LeftTimeSection(prayers: prayers)
        }
    }
}
