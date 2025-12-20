//
//  OnboardingLocationView.swift
//  PrayerEase
//
//  Created by Alisultan Abdullah on 12/19/24.
//

import CoreLocation
import SwiftUI

struct OnboardingLocationView: View {
    @ObservedObject var locationManager: LocationManager
    var onContinue: () -> Void

    var body: some View {
        OnboardingStepView(
            systemImage: locationManager.userLocation != nil
                ? "location.fill" : "location.circle.fill",
            title: locationManager.userLocation != nil ? "Location Found" : "Location Access",
            subtitle: locationManager.locationName != "N/A" ? locationManager.locationName : nil,
            description: locationManager.userLocation != nil
                ? "We found your location. You can choose to keep this location updated automatically or manage it manually."
                : "To provide accurate prayer times and Qibla direction, PrayerEase needs access to your location. Your location data stays on your device.",
            actionButtonTitle: locationManager.userLocation != nil
                ? "Continue" : "Find Current Location",
            action: {
                if locationManager.userLocation != nil {
                    onContinue()
                } else {
                    // Initial "Find" action sets auto to true just for the request
                    locationManager.isAutoLocationEnabled = true
                    locationManager.requestLocation()
                }
            },
            secondaryActionTitle: nil,
            secondaryAction: nil,
            customContent: {
                if locationManager.userLocation != nil {
                    Toggle(
                        "Enable Auto Location Detection",
                        isOn: $locationManager.isAutoLocationEnabled
                    )
                    .padding()
                    .glassEffect(.regular)
                }
            }
        )
    }
}

#Preview {
    OnboardingLocationView(locationManager: LocationManager(), onContinue: {})
}
