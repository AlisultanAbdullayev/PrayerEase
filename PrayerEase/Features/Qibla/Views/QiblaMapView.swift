//
//  QiblaMapView.swift
//  PrayerEase
//
//  Created by Alisultan Abdullah on 12/22/25.
//

import MapKit
import SwiftUI

struct QiblaMapView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var locationManager: LocationManager

    @State private var position: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var mapStyle: MapStyle = .standard
    @State private var selectedMapStyle = 0  // 0: Standard, 1: Satellite (Hybrid)

    // Kaaba Coordinates
    private let kaabaCoordinate = CLLocationCoordinate2D(latitude: 21.422487, longitude: 39.826206)

    var body: some View {
        NavigationStack {
            Map(position: $position) {
                // User Location
                UserAnnotation()

                // Kaaba Marker
                Marker("Kaaba", coordinate: kaabaCoordinate)
                    .tint(.black)

                // Line connecting User to Kaaba
                if let userLocation = locationManager.userLocation?.coordinate {
                    MapPolyline(
                        coordinates: geodesicCoordinates(from: userLocation, to: kaabaCoordinate)
                    )
                    .stroke(.accent, style: StrokeStyle(lineWidth: 3, dash: [10, 5]))
                }
            }
            .mapStyle(selectedMapStyle == 0 ? .standard : .hybrid(elevation: .realistic))
            .mapControls {
                MapUserLocationButton()
                MapCompass()
                MapScaleView()
            }
            .navigationTitle("Qibla Map")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("Map Style", selection: $selectedMapStyle) {
                            Label("Standard", systemImage: "map").tag(0)
                            Label("Satellite", systemImage: "globe.americas.fill").tag(1)
                        }
                    } label: {
                        Image(systemName: selectedMapStyle == 0 ? "map" : "globe.americas.fill")
                            .font(.headline)
                            .foregroundStyle(.accent)
                    }
                }
            }
        }
        .onAppear(perform: locationManager.startUpdatingHeading)
        .onDisappear(perform: locationManager.stopUpdatingHeading)
    }

    private func geodesicCoordinates(
        from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D
    ) -> [CLLocationCoordinate2D] {
        let polyline = MKGeodesicPolyline(coordinates: [start, end], count: 2)
        var coords = [CLLocationCoordinate2D](
            repeating: kCLLocationCoordinate2DInvalid, count: polyline.pointCount)
        polyline.getCoordinates(&coords, range: NSRange(location: 0, length: polyline.pointCount))
        return coords
    }
}

#Preview {
    QiblaMapView()
        .environmentObject(LocationManager())
}
