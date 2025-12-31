//
//  SetupSheetView.swift
//  PrayerEase
//
//  Created by Alisultan Abdullah on 12/10/24.
//

import Adhan
import SwiftUI

struct SetupSheetView: View {
    @Environment(\.dismiss) private var dismiss

    let prayerTimeManager: PrayerTimeManager

    @State private var selectedMadhab: Madhab = .shafi
    @State private var selectedMethod: CalculationMethod = .turkey

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(
                        "We couldn't automatically detect the best calculation method for your location. Please select one manually."
                    )
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                }

                Section(header: Text("Calculation Method")) {
                    Picker("Method", selection: $selectedMethod) {
                        ForEach(prayerTimeManager.methods, id: \.self) { method in
                            Text(methodName(for: method)).tag(method)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }

                Section(header: Text("Madhab")) {
                    Picker("Madhab", selection: $selectedMadhab) {
                        ForEach(prayerTimeManager.madhabs, id: \.self) { madhab in
                            Text(madhab == .hanafi ? "Hanafi" : "Default (Shafi, Maliki, Hanbali)")
                                .tag(madhab)
                        }
                    }
                }
            }
            .navigationTitle("Setup Prayer Method")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveAndDismiss()
                    }
                }
            }
            .onAppear {
                selectedMadhab = prayerTimeManager.madhab
                selectedMethod = prayerTimeManager.method
            }
        }
    }

    private func saveAndDismiss() {
        prayerTimeManager.madhab = selectedMadhab
        prayerTimeManager.method = selectedMethod
        prayerTimeManager.isMethodManuallySet = true
        dismiss()
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
        case .singapore: return "Majlis Ugama Islam Singapura, Singapore"
        case .tehran: return "Institute of Geophysics, University of Tehran"
        case .turkey: return "Diyanet İşleri Başkanlığı, Turkey"
        case .other: return "Other"
        }
    }
}

#Preview {
    SetupSheetView(prayerTimeManager: PrayerTimeManager.shared)
}
