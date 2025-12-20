//
//  OnboardingStepView.swift
//  PrayerEase
//
//  Created by Alisultan Abdullah on 12/19/24.
//

import SwiftUI

struct OnboardingStepView<Content: View>: View {
    let systemImage: String
    let title: String
    let subtitle: String?
    let description: String

    // Optional custom content to inject between description and button (e.g. pickers, toggles)
    @ViewBuilder let customContent: () -> Content

    let actionButtonTitle: String
    let action: () -> Void
    let secondaryActionTitle: String?
    let secondaryAction: (() -> Void)?

    init(
        systemImage: String,
        title: String,
        subtitle: String? = nil,
        description: String,
        actionButtonTitle: String,
        action: @escaping () -> Void,
        secondaryActionTitle: String? = nil,
        secondaryAction: (() -> Void)? = nil,
        @ViewBuilder customContent: @escaping () -> Content = { EmptyView() }
    ) {
        self.systemImage = systemImage
        self.title = title
        self.subtitle = subtitle
        self.description = description
        self.actionButtonTitle = actionButtonTitle
        self.action = action
        self.secondaryActionTitle = secondaryActionTitle
        self.secondaryAction = secondaryAction
        self.customContent = customContent
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: systemImage)
                .font(.system(size: 80))
                .foregroundColor(.accentColor)
                .padding(.bottom, 10)

            VStack(spacing: 8) {
                Text(title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                if let subtitle = subtitle {
                    Text(subtitle)
                        /*    .font(.title3)
                            .fontWeight(.semibold)*/
                    .font(.headline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }

            Text(description)
                .font(.body)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)  // Allow growing
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            // Custom content injection
            customContent()
                .padding(.vertical, 4)

            Spacer()

            VStack(spacing: 16) {
                if !actionButtonTitle.isEmpty {
                    Button(action: action) {
                        Text(actionButtonTitle)
                            .fontWeight(.semibold)
                    }
                    .buttonStyle(.glassProminent)
                    .controlSize(.large)
                    .buttonSizing(.flexible)
                }

                if let secondaryTitle = secondaryActionTitle, let secondaryAction = secondaryAction
                {
                    Button(action: secondaryAction) {
                        Text(secondaryTitle)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.bottom, 30)
        }
        .padding()
    }
}

#Preview {
    OnboardingStepView(
        systemImage: "location.fill",
        title: "Location Access",
        subtitle: "Accurate Prayer Times",
        description:
            "We use your location to calculate exact prayer times for your area. This ensures you never miss a prayer.",
        actionButtonTitle: "Allow Location",
        action: {},
        secondaryActionTitle: "Skip",
        secondaryAction: {}
    )
}
