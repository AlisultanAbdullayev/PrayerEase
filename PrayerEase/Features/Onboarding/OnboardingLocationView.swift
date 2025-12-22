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
    @State private var isShowingManualSearch = false

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
                ? "Continue"
                : (locationManager.authorizationStatus == .denied
                    || locationManager.authorizationStatus == .restricted
                    ? "Open Settings" : "Find Current Location"),
            action: {
                if locationManager.userLocation != nil {
                    onContinue()
                } else if locationManager.authorizationStatus == .denied
                    || locationManager.authorizationStatus == .restricted
                {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } else {
                    locationManager.isAutoLocationEnabled = true
                    locationManager.requestLocation()
                }
            },
            secondaryActionTitle: locationManager.userLocation == nil ? "Enter Manually" : nil,
            secondaryAction: locationManager.userLocation == nil
                ? { isShowingManualSearch = true } : nil,
            customContent: {
                if locationManager.userLocation != nil {
                    Toggle(
                        "Enable Auto Location Detection",
                        isOn: $locationManager.isAutoLocationEnabled
                    )
                    .padding()
                    .glassEffect(.regular)
                    .sensoryFeedback(.selection, trigger: locationManager.isAutoLocationEnabled)
                }
            }
        )
        .onAppear {
            locationManager.updateStatus()
        }
        .sheet(isPresented: $isShowingManualSearch) {
            NavigationStack {
                ManualLocationSearchView()
            }
        }
    }
}

#Preview {
    OnboardingLocationView(locationManager: LocationManager(), onContinue: {})
}
