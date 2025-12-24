//
//  PrayerEaseWatchApp.swift
//  PrayerEaseWatch Watch App
//
//  Created by Alisultan Abdullah on 12/23/25.
//

import SwiftUI

@main
struct PrayerEaseWatchApp: App {
    @StateObject private var watchDataManager = WatchDataManager.shared
    @StateObject private var connectivityManager = WatchConnectivityManager.shared

    var body: some Scene {
        WindowGroup {
            WatchRootView()
                .environmentObject(watchDataManager)
                .onAppear {
                    // Load cached prayer data
                    watchDataManager.loadPrayerData()

                    // Request fresh data from iOS app
                    connectivityManager.requestPrayerDataUpdate()
                }
        }
    }
}
