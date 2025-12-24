//
//  PrayerEaseApp.swift
//  PrayerEase
//
//  Created by Alisultan Abdullah on 10/30/24.
//

import SwiftUI

@main
struct PrayerEaseApp: App {

    @StateObject private var locationManager = LocationManager()
    @StateObject private var prayerTimeManager = PrayerTimeManager.shared
    @StateObject private var notificationManager = NotificationManager.shared
    @StateObject private var connectivityManager = IOSConnectivityManager.shared

    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false

    var body: some Scene {
        WindowGroup {
            Group {
                if hasCompletedOnboarding {
                    TabPageView()
                } else {
                    OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
                }
            }
            .environmentObject(locationManager)
            .environmentObject(notificationManager)
            .environmentObject(prayerTimeManager)
            .task(id: hasCompletedOnboarding) {
                setupApp()
            }
        }
    }
    private func setupApp() {
        // App setup moved to respective flows (Onboarding/ContentView)
    }
}

#if DEBUG
    struct SalahTimeApp_Previews: PreviewProvider {
        static var previews: some View {
            TabPageView()
                .environmentObject(LocationManager())
                .environmentObject(NotificationManager.shared)
                .environmentObject(PrayerTimeManager.shared)
        }
    }
#endif
