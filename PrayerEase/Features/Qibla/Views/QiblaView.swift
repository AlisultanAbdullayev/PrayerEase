//
//  QiblaView.swift
//  PrayerEase
//
//  Created by Alisultan Abdullah on 10/30/24.
//

import CoreLocation
import SwiftUI

struct QiblaView: View {
    // MARK: - Environment
    @Environment(LocationManager.self) private var locationManager

    // MARK: - State
    @State private var presentedSheet: PresentedSheet?

    private var qiblaDirection: Double {
        QiblaService.calculateQiblaDirection(
            from: locationManager.userLocation ?? CLLocation(latitude: 0, longitude: 0))
    }

    var body: some View {
        NavigationStack {
            if locationManager.isLocationActive {
                VStack(spacing: 12) {
                    CompassView(
                        rotationDegrees: qiblaDirection - locationManager.heading,
                        isPointingToQibla: isPointingToQibla
                    )
                    .containerRelativeFrame(.horizontal, count: 5, span: 4, spacing: 0)
                    .aspectRatio(1, contentMode: .fit)

                    if accuracyPercentage < 85 {
                        AccuracyWarningView(accuracyPercentage: accuracyPercentage)
                    }
                }
                .animation(
                    .spring(response: 0.6, dampingFraction: 0.7),
                    value: accuracyPercentage < 85
                )
                .sensoryFeedback(.success, trigger: isPointingToQibla)
                .sensoryFeedback(.warning, trigger: accuracyPercentage < 85)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .navigationTitle("Qibla Direction")
                .onAppear {
                    locationManager.startUpdatingHeading()
                    locationManager.boostAccuracyForQibla()
                }
                .onDisappear {
                    locationManager.stopUpdatingHeading()
                    locationManager.restoreNormalAccuracy()
                }
                .task {
                    // Force-refresh location and show prompt if location differs
                    await locationManager.refreshLocation(force: true, silent: false)
                }
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            presentedSheet = .map
                        } label: {
                            Image(systemName: "map.fill")
                                .font(.headline)
                                .foregroundStyle(Color.green)
                        }
                    }
                }
                .sheet(item: $presentedSheet) { sheet in
                    switch sheet {
                    case .map:
                        QiblaMapView()
                    }
                }
            } else {
                ContentUnavailableView(
                    "Location Required",
                    systemImage: "location.slash",
                    description: Text("Please enable location services to find Qibla direction.")
                )
            }
        }
    }

    // MARK: - Subviews

    private struct CompassView: View {
        let rotationDegrees: Double
        let isPointingToQibla: Bool

        var body: some View {
            ZStack {
                CompassDialView()
                CompassArrowView(isPointingToQibla: isPointingToQibla)
                CompassLabelView(isPointingToQibla: isPointingToQibla)
            }
            .rotationEffect(.degrees(rotationDegrees))
        }
    }

    private struct CompassDialView: View {
        var body: some View {
            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.3), lineWidth: 5)

                Canvas { context, size in
                    let radius = min(size.width, size.height) / 2
                    let center = CGPoint(x: size.width / 2, y: size.height / 2)
                    let tickCount = 72
                    let tickInset = radius * 0.08
                    let majorTickLength = radius * 0.12
                    let minorTickLength = radius * 0.06

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
                        context.stroke(path, with: .color(.secondary), lineWidth: tickWidth)
                    }
                }
            }
        }
    }

    private struct CompassArrowView: View {
        let isPointingToQibla: Bool

        var body: some View {
            Image(systemName: "arrow.up")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .containerRelativeFrame(.horizontal, count: 10, span: 3, spacing: 0)
                .foregroundStyle(isPointingToQibla ? .green : .secondary)
        }
    }

    private struct CompassLabelView: View {
        let isPointingToQibla: Bool
        @ScaledMetric(relativeTo: .title2) private var labelOffset: CGFloat = 12

        var body: some View {
            Text("QIBLA")
                .font(.title2)
                .bold()
                .foregroundStyle(isPointingToQibla ? .green : .secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .offset(y: -labelOffset)
        }
    }

    private struct AccuracyWarningView: View {
        let accuracyPercentage: Int

        var body: some View {
            VStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title)
                    .foregroundStyle(.yellow)

                Text(
                    "Compass accuracy is low: \(Text("\(accuracyPercentage)%").foregroundStyle(.red))"
                )
                .font(.headline)

                Text(
                    "Metal or magnetic interference detected.\nMove away from electronic devices or recalibrate."
                )
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            }
            .padding()
            .glassEffect(.clear, in: .rect(cornerRadius: 12))
            .padding(.top, 10)
            .transition(.scale.combined(with: .opacity))
        }
    }

    // MARK: - Computed Properties

    private var accuracyPercentage: Int {
        let accuracy = locationManager.headingAccuracy
        if accuracy < 0 { return 0 }
        return Int(max(0, 100 - accuracy))
    }

    private var isPointingToQibla: Bool {
        abs(locationManager.heading - qiblaDirection) <= 5
    }
}

// MARK: - Supporting Types
private enum PresentedSheet: Identifiable {
    case map

    var id: Self { self }
}

// MARK: - Preview
#Preview {
    QiblaView()
        .environment(LocationManager())
}
