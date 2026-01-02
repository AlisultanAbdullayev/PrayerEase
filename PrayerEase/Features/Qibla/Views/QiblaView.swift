//
//  QiblaView.swift
//  PrayerEase
//
//  Created by Alisultan Abdullah on 10/30/24.
//

import CoreLocation
import SwiftUI

struct QiblaView: View {
    @Environment(LocationManager.self) private var locationManager

    @State private var isMapPresented = false

    private var qiblaDirection: Double {
        QiblaService.calculateQiblaDirection(
            from: locationManager.userLocation ?? CLLocation(latitude: 0, longitude: 0))
    }

    var body: some View {
        NavigationStack {
            if locationManager.isLocationActive {
                GeometryReader { geometry in
                    VStack(spacing: 12) {
                        compassView(size: geometry.size.width * 0.8)

                        if accuracyPercentage < 85 {
                            accuracyWarning
                        }
                    }
                    .animation(
                        .spring(response: 0.6, dampingFraction: 0.7),
                        value: accuracyPercentage < 85
                    )
                    .sensoryFeedback(.success, trigger: isPointingToQibla)
                    .sensoryFeedback(.warning, trigger: accuracyPercentage < 85)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
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
                            isMapPresented = true
                        } label: {
                            Image(systemName: "map.fill")
                                .font(.headline)
                                .foregroundStyle(Color.green)
                        }
                    }
                }
                .sheet(isPresented: $isMapPresented) {
                    QiblaMapView()
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

    private func compassView(size: CGFloat) -> some View {
        ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.3), lineWidth: 5)
                .frame(width: size, height: size)

            ForEach(0..<72) { tick in
                Rectangle()
                    .fill(Color.secondary)
                    .frame(width: tick % 9 == 0 ? 2 : 1, height: tick % 9 == 0 ? 20 : 10)
                    .offset(y: size / 2 - 15)
                    .rotationEffect(.degrees(Double(tick) * 5))
            }

            Image(systemName: "arrow.up")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: size * 0.3, height: size * 0.3)
                .foregroundStyle(isPointingToQibla ? .green : .secondary)

            Text("QIBLA")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(isPointingToQibla ? .green : .secondary)
                .offset(y: -size / 2 - 15)
        }
        .rotationEffect(.degrees(Double(qiblaDirection - locationManager.heading)))
    }

    private var accuracyWarning: some View {
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

#Preview {
    QiblaView()
        .environment(LocationManager())
}
