//
//  OnboardingNotificationView.swift
//  PrayerEase
//
//  Created by Alisultan Abdullah on 12/19/24.
//

import SwiftUI

struct OnboardingNotificationView: View {
    @ObservedObject var notificationManager: NotificationManager
    var onEnable: () -> Void
    var onSkip: () -> Void

    var body: some View {
        OnboardingStepView(
            systemImage: "bell.badge.fill",
            title: "Notifications",
            description:
                "Stay connected with your prayers. Customize which alerts you want to receive.",
            actionButtonTitle: "Enable Notifications",
            action: onEnable,
            secondaryActionTitle: "Maybe Later",
            secondaryAction: onSkip,
            customContent: {
                // Ensure Prayer is available or use strings if needed. Using Adhan.Prayer for safety.
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(
                            notificationManager.notificationSettingsBefore.keys.sorted(), id: \.self
                        ) { key in
                            Toggle(isOn: bindingForNotification(key: key)) {
                                Text(key.capitalized)
                                    .font(.body)
                            }
                            .padding()
                            .glassEffect(.regular)
                            // .sensoryFeedback(
                            //     .selection, trigger: notificationManager.notificationSettings[key])
                        }
                    }
                }
                .frame(maxHeight: 300)
            }
        )
    }

    private func bindingForNotification(key: String) -> Binding<Bool> {
        Binding(
            get: { self.notificationManager.notificationSettings[key] ?? false },
            set: { newValue in
                self.notificationManager.updateNotificationSettings(
                    for: key, sendNotification: newValue)
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
        )
    }
}

#Preview {
    OnboardingNotificationView(
        notificationManager: NotificationManager.shared,
        onEnable: {},
        onSkip: {}
    )
}
