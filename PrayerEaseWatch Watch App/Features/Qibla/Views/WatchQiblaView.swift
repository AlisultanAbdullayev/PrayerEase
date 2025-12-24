//
//  WatchQiblaView.swift
//  PrayerEaseWatch Watch App
//
//  Created by Antigravity on 12/23/25.
//

import SwiftUI

/// Qibla direction screen for watchOS
struct WatchQiblaView: View {
    @StateObject private var viewModel = WatchQiblaViewModel()
    @State private var isMapPresented = false
    @State private var showWarning = false
    @State private var hasShownWarning = false

    var body: some View {
        if viewModel.isLocationActive {
            GeometryReader { geometry in
                VStack(spacing: 8) {
                    Spacer()

                    // Compass view
                    compassView(size: min(geometry.size.width, geometry.size.height) * 0.7)

                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                viewModel.startUpdating()
                // Show warning once if accuracy is low when view appears
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    if viewModel.accuracyPercentage > 0 && viewModel.accuracyPercentage < 75
                        && !hasShownWarning
                    {
                        showWarning = true
                        hasShownWarning = true
                    }
                }
            }
            .onDisappear {
                viewModel.stopUpdating()
            }
            .toolbar {
                ToolbarItem(placement: .bottomBar) {
                    // Map button
                    Button {
                        isMapPresented = true
                    } label: {
                        Image(systemName: "map")
                            .foregroundStyle(.green)
                            .buttonStyle(.glassCircle)
                    }
                }
                ToolbarItem(placement: .bottomBar) {
                    // Warning button
                    Button {
                        showWarning = true
                    } label: {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.yellow)
                            .buttonStyle(.glassCircle)
                    }
                }
            }
            .sheet(isPresented: $isMapPresented) {
                WatchQiblaMapView(viewModel: viewModel)
            }
            .alert("Compass Accuracy", isPresented: $showWarning) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(
                    "Qibla direction can be incorrect because of compass inaccuracy (\(viewModel.accuracyPercentage)%). Try an alternative method."
                )
            }
        } else {
            // Location disabled state
            VStack(spacing: 12) {
                Image(systemName: "location.slash")
                    .font(.system(size: 40))
                    .foregroundStyle(.secondary)

                Text("Location Required")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text("Please enable location services for Qibla direction")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .navigationTitle("Qibla")
        }
    }

    // MARK: - Subviews

    private func compassView(size: CGFloat) -> some View {
        ZStack {
            // Outer ring
            Circle()
                .stroke(Color.secondary.opacity(0.3), lineWidth: 3)
                .frame(width: size, height: size)

            // Tick marks
            ForEach(0..<72) { tick in
                Rectangle()
                    .fill(Color.secondary.opacity(0.6))
                    .frame(width: tick % 9 == 0 ? 2 : 1, height: tick % 9 == 0 ? 12 : 6)
                    .offset(y: -size / 2 + 8)
                    .rotationEffect(.degrees(Double(tick) * 5))
            }

            // Qibla arrow
            Image(systemName: "arrow.up")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size * 0.25, height: size * 0.4)
                .foregroundStyle(viewModel.isPointingToQibla ? .green : .primary)
                .shadow(
                    color: viewModel.isPointingToQibla ? .green.opacity(0.5) : .clear, radius: 8)

            // Qibla label
            Text("QIBLA")
                .font(.caption2.weight(.bold))
                .foregroundStyle(viewModel.isPointingToQibla ? .green : .secondary)
                .offset(y: -size / 2 - 18)
        }
        .rotationEffect(.degrees(viewModel.cumulativeRotation))
        .animation(
            .spring(response: 0.4, dampingFraction: 0.8), value: viewModel.cumulativeRotation
        )
        .sensoryFeedback(.success, trigger: viewModel.isPointingToQibla)
    }
}

#Preview {
    WatchQiblaView()
}
