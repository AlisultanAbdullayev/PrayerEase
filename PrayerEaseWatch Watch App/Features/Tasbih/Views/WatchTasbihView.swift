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

    @State private var targetText: String = ""

    init(viewModel: TasbihViewModel) {
        self.viewModel = viewModel
        _targetText = State(initialValue: String(viewModel.targetCount))
    }

    var body: some View {
        NavigationStack {
            List {
                // Target section with TextField
                Section("Target Count") {
                    TextField("Enter target", text: $targetText)
                        .onChange(of: targetText) { _, newValue in
                            // Update target when text changes
                            if let target = Int(newValue), target > 0 {
                                viewModel.setTarget(target)
                            }
                        }
                }

                // Reset section
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
            .navigationTitle("Tasbih Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    WatchTasbihView()
}
