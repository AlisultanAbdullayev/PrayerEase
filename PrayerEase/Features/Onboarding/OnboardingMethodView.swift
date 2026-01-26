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
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Calculation Method")
                            .font(.headline)
                            .foregroundStyle(.primary)

                        Menu {
                            Picker("Method", selection: $manager.method) {
                                ForEach(prayerTimeManager.methods, id: \.self) { method in
                                    Text(methodName(for: method))
                                        .tag(method)
                                }
                            }
                        } label: {
                            HStack {
                                Text(methodName(for: prayerTimeManager.method))
                                    .foregroundStyle(.primary)
                                Spacer()
                                Image(systemName: "chevron.up.chevron.down")
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                            }
                            .padding()
                            .glassEffect(.regular)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
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
                            .padding()
                            .glassEffect(.regular)
                        }
                    }
                }
            }
        )
        .padding(.horizontal)
    }

    private func methodName(for method: CalculationMethod) -> String {
        switch method {
        case .dubai: return "Dubai"
        case .muslimWorldLeague: return "Muslim World League"
        case .egyptian: return "Egyptian General Authority of Survey"
        case .karachi: return "University of Islamic Sciences, Karachi"
        case .ummAlQura: return "Umm Al-Qura University, Makkah"
        case .moonsightingCommittee: return "Moonsighting Committee Worldwide"
        case .northAmerica: return "Islamic Society of North America"
        case .kuwait: return "Kuwait"
        case .qatar: return "Qatar"
        case .singapore: return "Singapore"
        case .tehran: return "Tehran"
        case .turkey: return "Turkey"
        case .other: return "Other"
        }
    }
}

#Preview {
    OnboardingMethodView(prayerTimeManager: PrayerTimeManager.shared, onContinue: {})
}
