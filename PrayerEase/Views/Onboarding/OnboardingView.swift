//
//  OnboardingView.swift
//  PrayerEase
//
//  Created by Alisultan Abdullah on 12/19/24.
//

import SwiftUI

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool

    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var prayerTimeManager: PrayerTimeManager
    @EnvironmentObject var notificationManager: NotificationManager

    @State private var currentStep = 0

    var body: some View {
        ZStack {
            switch currentStep {
            case 0:
                OnboardingWelcomeView(
                    onContinue: {
                        withAnimation {
                            currentStep = 1
                        }
                    }
                )
                .transition(
                    .asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
            case 1:
                OnboardingLocationView(
                    locationManager: locationManager,
                    onContinue: {
                        // Ensure method is selected based on current timezone
                        if let tz = locationManager.userTimeZone {
                            _ = prayerTimeManager.autoSelectMethod(for: tz)
                        }
                        withAnimation {
                            currentStep = 2
                        }
                    }
                )
                .transition(
                    .asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading))
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
            case 2:
                OnboardingMethodView(
                    prayerTimeManager: prayerTimeManager,
                    onContinue: {
                        withAnimation {
                            currentStep = 3
                        }
                    }
                )
                .transition(
                    .asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
            case 3:
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
                .transition(
                    .asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
            default:
                EmptyView()
            }
        }
        .overlay(alignment: .topLeading) {
            if currentStep > 0 {
                Button(action: {
                    withAnimation {
                        currentStep -= 1
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(.primary)
                        .padding()
                        .background(Color.white.opacity(0.001))  // Expand hit area
                }
                .padding(.top, 40)  // Adjust for status bar safely if needed, or rely on safe area
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
