//
//  PrayerEaseApp.swift
//  PrayerEase
//
//  Created by Alisultan Abdullah on 10/30/24.
//

import SwiftUI
import UserNotifications

// MARK: - AppDelegate for Notification Actions

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    /// Handle notification actions (Update/Keep buttons)
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        Task { @MainActor in
            let locationManager = await getLocationManager()

            switch response.actionIdentifier {
            case "UPDATE_LOCATION":
                // Directly confirm without showing alert
                await locationManager.confirmPendingLocation()
                PrayerTimeManager.shared.fetchPrayerTimes(for: Date())
                print("DEBUG: Notification action - Update confirmed")

            case "KEEP_LOCATION":
                // Directly decline without showing alert
                locationManager.declinePendingLocation()
                print("DEBUG: Notification action - Keep current")

            case UNNotificationDefaultActionIdentifier:
                // User tapped the notification itself - let default alert flow handle it
                break

            default:
                break
            }

            completionHandler()
        }
    }

    /// Show notifications even when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler:
            @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    @MainActor
    private func getLocationManager() -> LocationManager {
        // Access the shared location manager (we need to ensure it's the same instance)
        // Since LocationManager is @Observable and passed via environment, we access it via a static reference
        return LocationManager.shared
    }
}

@main
struct PrayerEaseApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @Environment(\.scenePhase) private var scenePhase

    @State private var locationManager = LocationManager.shared
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
                // Only show prompt if there's a pending change AND it wasn't already handled by notification action
                if newPhase == .active && locationManager.hasPendingLocationChange
                    && !locationManager.isShowingLocationPrompt
                {
                    locationManager.isShowingLocationPrompt = true
                }
            }
            // Location consent alert
            .alert(
                "Update Location?",
                isPresented: $locationManager.isShowingLocationPrompt
            ) {
                Button("Update", role: .confirm) {
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
                .environment(LocationManager.shared)
                .environment(NotificationManager.shared)
                .environment(PrayerTimeManager.shared)
        }
    }
#endif
