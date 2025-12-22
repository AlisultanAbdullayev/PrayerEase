//
//  QiblaView.swift
//  PrayerEase
//
//  Created by Alisultan Abdullah on 10/30/24.
//

import CoreLocation
import SwiftUI

struct QiblaView: View {
    @EnvironmentObject var locationManager: LocationManager

    var qiblaDirection: Double {
        QiblaService.calculateQiblaDirection(
            from: locationManager.userLocation ?? CLLocation(latitude: 0, longitude: 0))
    }

    var body: some View {
        NavigationStack {
            if locationManager.isLocationActive {
                GeometryReader { geometry in
                    VStack(spacing: 12) {
                        compassView(size: geometry.size.width * 0.8)

                        if accuracyPercentage < 75 {
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
                    .animation(
                        .spring(response: 0.6, dampingFraction: 0.7),
                        value: accuracyPercentage < 75
                    )
                    .sensoryFeedback(.success, trigger: isPointingToQibla)
                    .sensoryFeedback(.warning, trigger: accuracyPercentage < 75)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .navigationTitle("Qibla Direction")
                .onAppear(perform: locationManager.startUpdatingHeading)
                .onDisappear(perform: locationManager.stopUpdatingHeading)
            } else {
                Text("Please, enable location services")
                    .foregroundStyle(.secondary)
                    .font(.title2)
            }
        }
    }

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

            //            Image(systemName: "arrow.up")
            //                .resizable()
            //                .aspectRatio(contentMode: .fit)
            //                .frame(width: size * 0.2, height: size * 0.2)
            //                .foregroundColor(.red)
            ////                .rotationEffect(.degrees(Double(-locationManager.heading)))

            Image(systemName: "arrow.up")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: size * 0.3, height: size * 0.3)
                .foregroundStyle(isPointingToQibla ? .green : .secondary)
            //                .rotationEffect(.degrees(Double(locationManager.heading)))
            //                .rotationEffect(.degrees(Double(qiblaDirection - locationManager.heading)))

            Text("QIBLA")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(isPointingToQibla ? .green : .secondary)
                .offset(y: -size / 2 - 15)

        }
        .rotationEffect(.degrees(Double(qiblaDirection - locationManager.heading)))
        //        .animation(.interactiveSpring, value: locationManager.heading)
    }

    private var accuracyPercentage: Int {
        let accuracy = locationManager.headingAccuracy
        if accuracy < 0 { return 0 }
        // accuracy is in degrees of error. 0 degrees = 100%. 50 degrees = 50%.
        return Int(max(0, 100 - accuracy))
    }

    private var accuracyColor: Color {
        if accuracyPercentage >= 75 { return .green }  // Good
        if accuracyPercentage >= 50 { return .yellow }  // Fair
        return .red  // Poor
    }

    private var isPointingToQibla: Bool {
        abs(locationManager.heading - qiblaDirection) <= 5
    }

    //    private func startUpdating() {
    //        locationManager.startUpdatingLocation()
    //        locationManager.startUpdatingHeading()
    //    }
    //
    //    private func stopUpdating() {
    //        locationManager.stopUpdatingLocation()
    //        locationManager.stopUpdatingHeading()
    //    }
}

struct QiblaView_Previews: PreviewProvider {
    static var previews: some View {
        QiblaView()
            .environmentObject(LocationManager())
    }
}
