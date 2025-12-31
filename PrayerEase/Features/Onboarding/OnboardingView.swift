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

    @Environment(LocationManager.self) private var locationManager
    @Environment(PrayerTimeManager.self) private var prayerTimeManager
    @Environment(NotificationManager.self) private var notificationManager

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
                            if let tz = locationManager.userTimeZone {
                                _ = prayerTimeManager.autoSelectMethod(for: tz)
                            }
                            path.append(OnboardingStep.method)
                        }
                    )
                    .onChange(of: locationManager.userTimeZone) { _, timeZone in
                        if let tz = timeZone {
                            print("DEBUG: OnboardingView observed timezone change: \(tz)")
                            let found = prayerTimeManager.autoSelectMethod(for: tz)
                            print("DEBUG: Auto-selected method found: \(found)")
                        }
                    }
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
        .environment(LocationManager())
        .environment(PrayerTimeManager.shared)
        .environment(NotificationManager.shared)
}
