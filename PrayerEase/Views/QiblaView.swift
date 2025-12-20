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
        locationManager.calculateQiblaDirection(
            from: locationManager.userLocation ?? CLLocation(latitude: 0, longitude: 0))
    }

    var body: some View {
        NavigationStack {
            if locationManager.isLocationActive {
                GeometryReader { geometry in
                    VStack {
                        compassView(size: geometry.size.width * 0.8)
                        //                        infoView
                    }
                    .sensoryFeedback(.success, trigger: isPointingToQibla)
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
                .foregroundStyle(isPointingToQibla ? .accent : .secondary)
            //                .rotationEffect(.degrees(Double(locationManager.heading)))
            //                .rotationEffect(.degrees(Double(qiblaDirection - locationManager.heading)))

            Text("QIBLA")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(isPointingToQibla ? .accent : .secondary)
                .offset(y: -size / 2 - 15)

        }
        .rotationEffect(.degrees(Double(qiblaDirection - locationManager.heading)))
        //        .animation(.interactiveSpring, value: locationManager.heading)
    }

    private var infoView: some View {
        VStack(alignment: .center, spacing: 10) {
            Text("Device Heading: \(Int(locationManager.heading))°")
            Text("Qibla Direction: \(Int(qiblaDirection))°")
            Text(isPointingToQibla ? "Pointing to Qibla" : "Align to the Qibla")
                .fontWeight(.bold)
                .foregroundColor(isPointingToQibla ? .accent : .secondary)
            Text("\(locationManager.headingAccuracy, specifier: "%.2f")")
        }
        .padding(30)
        .glassEffect()
        .padding()
        .sensoryFeedback(.success, trigger: isPointingToQibla)
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
