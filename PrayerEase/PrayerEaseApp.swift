//
//  PrayerEaseApp.swift
//  PrayerEase
//
//  Created by Alisultan Abdullah on 10/30/24.
//

import SwiftUI

@main
struct PrayerEaseApp: App {

    @Environment(\.scenePhase) private var scenePhase

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
            // Sync app state and check for pending location change
            .onChange(of: scenePhase) { _, newPhase in
                locationManager.isAppActive = (newPhase == .active)
                if newPhase == .active && locationManager.hasPendingLocationChange {
                    locationManager.isShowingLocationPrompt = true
                }
            }
            // Location consent alert
            .alert(
                "Update Location?",
                isPresented: $locationManager.isShowingLocationPrompt
            ) {
                Button("Update") {
                    Task {
                        await locationManager.confirmPendingLocation()
                        prayerTimeManager.fetchPrayerTimes(for: Date())
                    }
                }
                Button("Keep Current", role: .cancel) {
                    locationManager.declinePendingLocation()
                }
            } message: {
                Text(
                    "Your location has changed to \(locationManager.pendingLocationName). Update prayer times?"
                )
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
