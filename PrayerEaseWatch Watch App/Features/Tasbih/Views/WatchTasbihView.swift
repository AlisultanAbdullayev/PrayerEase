//
//  WatchTasbihView.swift
//  PrayerEaseWatch Watch App
//
//  Created by Antigravity on 12/23/25.
//

import SwiftUI

/// Tasbih counter screen for watchOS (watch-only feature)
struct WatchTasbihView: View {
    @StateObject private var viewModel = TasbihViewModel()
    @State private var showSettings = false
    @State private var customTarget: Int = 33

    var body: some View {
        VStack(spacing: 0) {
            // Main tappable area with gauge
            Button {
                viewModel.increment()
            } label: {
                TasbihGaugeView(
                    currentCount: viewModel.currentCount,
                    targetCount: viewModel.targetCount,
                    totalCount: viewModel.totalCount
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .buttonStyle(.plain)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.headline)
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            TasbihSettingsView(viewModel: viewModel)
        }
    }
}

/// Settings sheet for Tasbih
struct TasbihSettingsView: View {
    @ObservedObject var viewModel: TasbihViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedTarget: Int
    @State private var showCustomTargetInput = false
    @State private var customTargetText = ""

    let presetTargets = [33, 66, 99]

    init(viewModel: TasbihViewModel) {
        self.viewModel = viewModel
        _selectedTarget = State(initialValue: viewModel.targetCount)
    }

    var body: some View {
        NavigationStack {
            settingsList
        }
    }

    private var settingsList: some View {
        List {
            targetSection
            resetSection
        }
        .navigationTitle("Tasbih Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .alert("Custom Target", isPresented: $showCustomTargetInput) {
            customTargetAlert
        } message: {
            Text("Enter your custom target count")
        }
    }

    private var targetSection: some View {
        Section("Target Count") {
            ForEach(presetTargets, id: \.self) { target in
                targetButton(for: target)
            }

            customTargetButton
        }
    }

    private func targetButton(for target: Int) -> some View {
        Button {
            selectedTarget = target
            viewModel.setTarget(target)
            WKInterfaceDevice.current().play(.click)
        } label: {
            HStack {
                Text("\(target)")
                    .foregroundStyle(.primary)
                Spacer()
                if selectedTarget == target {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Color.accentColor)
                }
            }
        }
    }

    private var customTargetButton: some View {
        Button {
            showCustomTargetInput = true
        } label: {
            HStack {
                Text("Custom")
                    .foregroundStyle(.primary)
                Spacer()
                if !presetTargets.contains(selectedTarget) {
                    Text("\(selectedTarget)")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var resetSection: some View {
        Section {
            Button(role: .destructive) {
                viewModel.resetCurrent()
                dismiss()
            } label: {
                Label("Reset Current", systemImage: "arrow.counterclockwise")
            }

            Button(role: .destructive) {
                viewModel.resetTotal()
                dismiss()
            } label: {
                Label("Reset Total", systemImage: "trash")
            }
        }
    }

    @ViewBuilder
    private var customTargetAlert: some View {
        TextField("Target", text: $customTargetText)
//            .keyboardType(.numberPad)

        Button("Cancel", role: .cancel) {
            customTargetText = ""
        }

        Button("Set") {
            if let target = Int(customTargetText), target > 0 {
                selectedTarget = target
                viewModel.setTarget(target)
            }
            customTargetText = ""
        }
    }
}

#Preview {
    WatchTasbihView()
}
