//
//  PrayerEaseWatchApp.swift
//  PrayerEaseWatch Watch App
//
//  Created by Alisultan Abdullah on 12/23/25.
//

import SwiftUI

@main
struct PrayerEaseWatchApp: App {
    @State private var watchDataManager = WatchDataManager.shared
    @State private var connectivityManager = WatchConnectivityManager.shared

    var body: some Scene {
        WindowGroup {
            WatchRootView()
                .environment(watchDataManager)
                .onAppear {
                    watchDataManager.loadPrayerData()
                    connectivityManager.requestPrayerDataUpdate()
                }
        }
    }
}
