//
//  OnboardingMethodView.swift
//  PrayerEase
//
//  Created by Alisultan Abdullah on 12/19/24.
//

import Adhan
import SwiftUI

struct OnboardingMethodView: View {
    let prayerTimeManager: PrayerTimeManager
    let onContinue: () -> Void

    var body: some View {
        @Bindable var manager = prayerTimeManager

        OnboardingStepView(
            systemImage: "globe.europe.africa.fill",
            title: "Calculation Method",
            description:
                "We've selected a potentially suitable method for your location. You can adjust it now or later in Settings.",
            actionButtonTitle: "Continue",
            action: onContinue,
            secondaryAction: nil,
            customContent: {
                VStack {
                    VStack(alignment: .leading) {
                        Text("Calculation Method")
                            .font(.headline)
                            .foregroundStyle(.primary)

                        Menu {
                            Picker("Method", selection: $manager.method) {
                                ForEach(prayerTimeManager.methods, id: \.self) { method in
                                    Text(method.displayName)
                                        .tag(method)
                                }
                            }
                        } label: {
                            HStack {
                                Text(prayerTimeManager.method.displayName)
                                    .foregroundStyle(.primary)
                                Spacer()
                                Image(systemName: "chevron.up.chevron.down")
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                            }
                            .customGlassContainer()
                        }
                    }

                    VStack(alignment: .leading) {
                        Text("Madhab")
                            .font(.headline)
                            .foregroundStyle(.primary)

                        Menu {
                            Picker("Madhab", selection: $manager.madhab) {
                                ForEach(prayerTimeManager.madhabs, id: \.self) { madhab in
                                    Text(madhab == .hanafi ? "Hanafi" : "Shafi, Maliki, Hanbali")
                                        .tag(madhab)
                                }
                            }
                        } label: {
                            HStack {
                                Text(
                                    prayerTimeManager.madhab == .hanafi
                                        ? "Hanafi" : "Shafi, Maliki, Hanbali"
                                )
                                .foregroundStyle(.primary)
                                Spacer()
                                Image(systemName: "chevron.up.chevron.down")
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                            }
                            .customGlassContainer()
                        }
                    }
                }
            }
        )
        .padding(.horizontal)
    }

}

#Preview {
    OnboardingMethodView(prayerTimeManager: PrayerTimeManager.shared, onContinue: {})
}
