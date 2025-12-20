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
    @State private var currentTime = Date()
    @State private var timer: Timer?

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
        Section {
            timeRemainingText
                .frame(maxWidth: .infinity, alignment: .center)
                .font(.largeTitle)
                .fontWeight(.bold)
                .fontDesign(.rounded)
                .id(prayers.fajr) // Force refresh when prayers change
        } header: {
            Text("Time until next prayer")
                .foregroundColor(.accentColor)
                .font(.body)
                .fontWeight(.regular)
        }
        .onAppear(perform: startTimer)
        .onDisappear(perform: stopTimer)
    }

    private func startTimer() {
        // Invalidate existing timer if any
        timer?.invalidate()

        // Create and store new timer
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            currentTime = Date()
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

struct LeftTimeSection_Previews: PreviewProvider {
    static var previews: some View {
        let coordinates = Coordinates(latitude: 21.422487, longitude: 39.826206) // Mecca coordinates
        let date = Date()
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let params = CalculationMethod.muslimWorldLeague.params
        let prayers = PrayerTimes(coordinates: coordinates, date: dateComponents, calculationParameters: params)!
        
        return List {
            LeftTimeSection(prayers: prayers)
        }
    }
}

