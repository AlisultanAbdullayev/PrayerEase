//
//  WatchQiblaView.swift
//  PrayerEaseWatch Watch App
//
//  Created by Antigravity on 12/23/25.
//

import SwiftUI

/// Qibla direction screen for watchOS
struct WatchQiblaView: View {
    @State private var viewModel = WatchQiblaViewModel()
    @State private var isMapPresented = false
    @State private var showWarning = false
    @State private var hasShownWarning = false

    var body: some View {
        if viewModel.isLocationActive {
            VStack(spacing: 8) {
                Spacer()

                WatchCompassView(
                    rotationDegrees: viewModel.cumulativeRotation,
                    isPointingToQibla: viewModel.isPointingToQibla
                )
                .containerRelativeFrame(.horizontal, count: 10, span: 7, spacing: 0)
                .aspectRatio(1, contentMode: .fit)

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                viewModel.startUpdating()
            }
            .task {
                try? await Task.sleep(for: .seconds(2))
                if viewModel.accuracyPercentage > 0 && viewModel.accuracyPercentage < 75
                    && !hasShownWarning
                {
                    showWarning = true
                    hasShownWarning = true
                }
            }
            .onDisappear {
                viewModel.stopUpdating()
            }
            .toolbar {
                ToolbarItem(placement: .bottomBar) {
                    Button {
                        isMapPresented = true
                    } label: {
                        Image(systemName: "map")
                            .foregroundStyle(.green)
                            .buttonStyle(.glassCircle)
                    }
                }
                ToolbarItem(placement: .bottomBar) {
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
            VStack(spacing: 12) {
                Image(systemName: "location.slash")
                    .font(.title)
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

    private struct WatchCompassView: View {
        let rotationDegrees: Double
        let isPointingToQibla: Bool

        var body: some View {
            ZStack {
                WatchCompassDialView()
                WatchCompassArrowView(isPointingToQibla: isPointingToQibla)
                WatchCompassLabelView(isPointingToQibla: isPointingToQibla)
            }
            .rotationEffect(.degrees(rotationDegrees))
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: rotationDegrees)
            .sensoryFeedback(.success, trigger: isPointingToQibla)
        }
    }

    private struct WatchCompassDialView: View {
        var body: some View {
            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.3), lineWidth: 3)

                Canvas { context, size in
                    let radius = min(size.width, size.height) / 2
                    let center = CGPoint(x: size.width / 2, y: size.height / 2)
                    let tickCount = 72
                    let tickInset = radius * 0.07
                    let majorTickLength = radius * 0.1
                    let minorTickLength = radius * 0.05

                    for tick in 0..<tickCount {
                        let angle = CGFloat(tick) * (2 * .pi / CGFloat(tickCount))
                        let isMajor = tick % 9 == 0
                        let tickLength = isMajor ? majorTickLength : minorTickLength
                        let tickWidth: CGFloat = isMajor ? max(2, radius * 0.01) : max(1, radius * 0.006)

                        let start = CGPoint(
                            x: center.x + cos(angle) * (radius - tickInset - tickLength),
                            y: center.y + sin(angle) * (radius - tickInset - tickLength)
                        )
                        let end = CGPoint(
                            x: center.x + cos(angle) * (radius - tickInset),
                            y: center.y + sin(angle) * (radius - tickInset)
                        )

                        var path = Path()
                        path.move(to: start)
                        path.addLine(to: end)
                        context.stroke(path, with: .color(.secondary.opacity(0.6)), lineWidth: tickWidth)
                    }
                }
            }
        }
    }

    private struct WatchCompassArrowView: View {
        let isPointingToQibla: Bool

        var body: some View {
            Image(systemName: "arrow.up")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .containerRelativeFrame(.horizontal, count: 4, span: 1, spacing: 0)
                .foregroundStyle(isPointingToQibla ? .green : .primary)
                .shadow(color: isPointingToQibla ? .green.opacity(0.5) : .clear, radius: 8)
        }
    }

    private struct WatchCompassLabelView: View {
        let isPointingToQibla: Bool
        @ScaledMetric(relativeTo: .caption2) private var labelOffset: CGFloat = 12

        var body: some View {
            Text("QIBLA")
                .font(.caption2)
                .bold()
                .foregroundStyle(isPointingToQibla ? .green : .secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .offset(y: -labelOffset)
        }
    }
}

#Preview {
    WatchQiblaView()
}
