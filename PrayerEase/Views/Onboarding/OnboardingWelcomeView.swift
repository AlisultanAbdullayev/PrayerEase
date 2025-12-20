//
//  OnboardingWelcomeView.swift
//  PrayerEase
//
//  Created by Alisultan Abdullah on 12/19/24.
//

import SwiftUI

struct OnboardingWelcomeView: View {
    var onContinue: () -> Void

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            // App Icon or Logo Placeholder
            Image("AppIcon")  // Assuming AppIcon is available in assets, or use a system placeholder
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .cornerRadius(24)
                .shadow(radius: 10)
                // Fallback if AppIcon asset is not directly loadable by name in SwiftUI Image yet
                .overlay {
                    if UIImage(named: "AppIcon") == nil {
                        Image(systemName: "sun.haze.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.accentColor)
                    }
                }

            VStack(spacing: 10) {
                Text("Welcome to PrayerEase")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text("Your modern companion for accurate prayer times.")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(alignment: .leading, spacing: 20) {
                FeatureRow(
                    icon: "swift",
                    text: "Built with latest Swift & SwiftUI for a native experience.")
                FeatureRow(
                    icon: "bolt.fill", text: "Lightweight app size with blazing fast performance.")
                FeatureRow(icon: "gift.fill", text: "Completely free forever. No ads, just peace.")
            }
            .padding(.horizontal)
            .padding(.top, 20)

            Spacer()

            Button(action: onContinue) {
                Text("Get Started")
                    .fontWeight(.semibold)

            }
            .buttonStyle(.glassProminent)
            .controlSize(.large)
            .buttonSizing(.flexible)
            Spacer()
        }
        .padding()
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .frame(width: 30)
                .foregroundColor(.accentColor)

            Text(text)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    OnboardingWelcomeView(onContinue: {})
}
