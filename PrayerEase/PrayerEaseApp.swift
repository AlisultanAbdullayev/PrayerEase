//
//  PrayerEaseApp.swift
//  PrayerEase
//
//  Created by Alisultan Abdullah on 10/30/24.
//

import SwiftUI

@main
struct PrayerEaseApp: App {

    @State private var locationManager = LocationManager()
    @State private var prayerTimeManager = PrayerTimeManager.shared
    @State private var notificationManager = NotificationManager.shared
    @State private var connectivityManager = IOSConnectivityManager.shared

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
            .environment(locationManager)
            .environment(notificationManager)
            .environment(prayerTimeManager)
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
                .environment(LocationManager())
                .environment(NotificationManager.shared)
                .environment(PrayerTimeManager.shared)
        }
    }
#endif
