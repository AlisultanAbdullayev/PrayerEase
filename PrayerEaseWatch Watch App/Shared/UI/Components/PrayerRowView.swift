//
//  PrayerRowView.swift
//  PrayerEaseWatch Watch App
//
//  Created by Antigravity on 12/23/25.
//

import SwiftUI

/// Reusable prayer row component for watchOS
struct PrayerRowView: View {
    let prayer: SharedPrayerTime
    let isCurrent: Bool

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: prayer.iconName)
                .foregroundStyle(isCurrent ? Color.accentColor : .secondary)

            Text(prayer.name)
                .foregroundStyle(isCurrent ? Color.accentColor : .primary)

            Spacer()

            Text(prayer.timeString)
                .foregroundStyle(isCurrent ? Color.accentColor : .primary)
        }
        .padding()
        .background {
            if isCurrent {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.accentColor.opacity(0.15))
            }
        }
        .glassCard()
    }
}

#Preview {
    VStack(spacing: 4) {
        PrayerRowView(
            prayer: SharedPrayerTime(name: "Fajr", time: Date()),
            isCurrent: false
        )

        PrayerRowView(
            prayer: SharedPrayerTime(name: "Dhuhr", time: Date()),
            isCurrent: true
        )

        PrayerRowView(
            prayer: SharedPrayerTime(name: "Maghrib", time: Date()),
            isCurrent: false
        )
    }
}
