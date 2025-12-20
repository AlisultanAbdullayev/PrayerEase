//
//  OnboardingView.swift
//  PrayerEase
//
//  Created by Alisultan Abdullah on 12/19/24.
//

import SwiftUI

enum OnboardingStep: Hashable {
    case location
    case method
    case notification
}

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool

    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var prayerTimeManager: PrayerTimeManager
    @EnvironmentObject var notificationManager: NotificationManager

    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            OnboardingWelcomeView(
                onContinue: {
                    path.append(OnboardingStep.location)
                }
            )
            .navigationDestination(for: OnboardingStep.self) { step in
                switch step {
                case .location:
                    OnboardingLocationView(
                        locationManager: locationManager,
                        onContinue: {
                            // Ensure method is selected based on current timezone
                            if let tz = locationManager.userTimeZone {
                                _ = prayerTimeManager.autoSelectMethod(for: tz)
                            }
                            path.append(OnboardingStep.method)
                        }
                    )
                    // Auto-select method when location (timezone) is found
                    .onChange(of: locationManager.userTimeZone) { _, timeZone in
                        if let tz = timeZone {
                            print("DEBUG: OnboardingView observed timezone change: \(tz)")
                            let found = prayerTimeManager.autoSelectMethod(for: tz)
                            print("DEBUG: Auto-selected method found: \(found)")
                        }
                    }
                    // Sync location to managers so they are ready for next steps
                    .onChange(of: locationManager.userLocation) { _, location in
                        if let location = location {
                            print("DEBUG: OnboardingView syncing location to managers: \(location)")
                            prayerTimeManager.updateLocation(location)
                            notificationManager.updateLocation(location)
                        }
                    }

                case .method:
                    OnboardingMethodView(
                        prayerTimeManager: prayerTimeManager,
                        onContinue: {
                            path.append(OnboardingStep.notification)
                        }
                    )

                case .notification:
                    OnboardingNotificationView(
                        notificationManager: notificationManager,
                        onEnable: {
                            Task {
                                let granted = await notificationManager.requestAuthorization()
                                await MainActor.run {
                                    if !granted {
                                        notificationManager.disableAllNotifications()
                                    }
                                    completeOnboarding()
                                }
                            }
                        },
                        onSkip: {
                            completeOnboarding()
                        }
                    )
                }
            }
        }
    }

    private func completeOnboarding() {
        withAnimation {
            hasCompletedOnboarding = true
        }
    }
}

#Preview {
    OnboardingView(hasCompletedOnboarding: .constant(false))
        .environmentObject(LocationManager())
        .environmentObject(PrayerTimeManager.shared)
        .environmentObject(NotificationManager.shared)
}
