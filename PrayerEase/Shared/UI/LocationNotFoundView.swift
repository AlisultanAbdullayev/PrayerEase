//
//  LocationNotFoundView.swift
//  PrayerEase
//
//  Created by Alisultan Abdullah on 10/30/24.
//

import SwiftUI

struct LocationNotFoundView: View {
    @Environment(LocationManager.self) private var locationManager

    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "location.fill")
                .font(.largeTitle)
                .imageScale(.large)
                .foregroundStyle(.accent)

            HStack {
                Text("Correct")
                    .font(.title)
                    .bold()

                Text("Location")
                    .font(.title)
                    .bold()
                    .foregroundStyle(.accent)
            }
            Text(
                "To access the most accurate prayer times instantly through the Salah app, you need to allow location access."
            )
            .font(.callout)
            .fontWeight(.light)
            .multilineTextAlignment(.center)
            .padding()

            Text(
                "We only need your location information while you are using the app. This enables us to provide prayer times specific to your location and is not shared with any other parties."
            )
            .font(.callout)
            .fontWeight(.light)
            .multilineTextAlignment(.center)
            .padding()

            Spacer()

            Text(
                locationManager.authorizationStatus == .notDetermined
                    ? "Enable Location Access" : "Enable Location Access from Settings"
            )
            .font(.callout)
            .foregroundStyle(.secondary)

            Button {
                if locationManager.authorizationStatus == .notDetermined {
                    locationManager.requestLocation()
                } else if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }

            } label: {
                Label(
                    locationManager.authorizationStatus == .notDetermined
                        ? "Allow Access" : "Open Settings", systemImage: "location.fill"
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .buttonSizing(.flexible)
            .controlSize(.large)

        }
        .padding()
        .onAppear {
            locationManager.updateStatus()
        }
    }
}

#Preview {
    LocationNotFoundView()
        .environment(LocationManager())
}
