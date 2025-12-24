//
//  WatchRootView.swift
//  PrayerEaseWatch Watch App
//
//  Created by Antigravity on 12/23/25.
//

import SwiftUI

/// Tab identifiers for the watch app
enum WatchTab: Int, CaseIterable {
    case tasbih = 0
    case prayerTimes = 1
    case qibla = 2
}

/// Root navigation view with three tabs: Tasbih, Prayer Times, Qibla
struct WatchRootView: View {
    @State private var selectedTab: WatchTab = .prayerTimes

    var body: some View {
        NavigationStack {
            TabView(selection: $selectedTab) {
                // Tasbih tab (left)
                WatchTasbihView()
                    .tag(WatchTab.tasbih)
                    .containerBackground(.black.gradient, for: .tabView)

                // Prayer Times tab (center - default)
                WatchPrayerTimesView()
                    .tag(WatchTab.prayerTimes)
                    .containerBackground(.black.gradient, for: .tabView)

                // Qibla tab (right)
                WatchQiblaView()
                    .tag(WatchTab.qibla)
                    .containerBackground(.black.gradient, for: .tabView)
            }
            .tabViewStyle(.page)
        }
    }
}

#Preview {
    WatchRootView()
}
