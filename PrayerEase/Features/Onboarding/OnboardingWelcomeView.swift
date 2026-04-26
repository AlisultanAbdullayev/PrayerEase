//
//  OnboardingWelcomeView.swift
//  PrayerEase
//
//  Created by Alisultan Abdullah on 12/19/24.
//

import SwiftUI

struct OnboardingWelcomeView: View {
    var onContinue: () -> Void
    @State private var isPressed = false

    var body: some View {
        VStack {
            Spacer()

            // App Icon or Logo Placeholder
            Image("PrayerEase")  // Assuming AppIcon is available in assets, or use a system placeholder
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 120)
                .aspectRatio(1, contentMode: .fit)
                .clipShape(.rect(cornerRadius: 24))
                .shadow(radius: 10)
                // Fallback if AppIcon asset is not directly loadable by name in SwiftUI Image yet

            VStack {
                Text("Welcome to PrayerEase")
                    .font(.largeTitle)
                    .bold()
                    .multilineTextAlignment(.center)

                Text("Your modern companion for accurate prayer times.")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(alignment: .leading) {
                FeatureRow(
                    icon: "swift",
                    text: "Built with latest Swift & SwiftUI for a native experience.")
                FeatureRow(
                    icon: "bolt.fill", text: "Lightweight app size with blazing fast performance.")
                FeatureRow(icon: "gift.fill", text: "Completely free forever. No ads, just peace.")
            }
            .padding()

            Spacer()

            Button(action: {
                isPressed.toggle()
                onContinue()
            }) {
                Text("Get Started")
            }
            .buttonStyle(.glassProminent)
            .controlSize(.large)
            .buttonSizing(.flexible)
            .sensoryFeedback(.impact(weight: .medium), trigger: isPressed)
            Spacer()
        }
        .padding()
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.accent)

            Text(text)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    OnboardingWelcomeView(onContinue: {})
}
