//
//  WatchQiblaMapView.swift
//  PrayerEaseWatch Watch App
//
//  Created by Antigravity on 12/23/25.
//

import MapKit
import SwiftUI

/// Map view showing Qibla direction and polyline to Kaaba
struct WatchQiblaMapView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: WatchQiblaViewModel

    @State private var position: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var selectedMapStyle = 0  // 0: Standard, 1: Satellite
    @State private var showMapStylePicker = false

    // Kaaba coordinates
    private let kaabaCoordinate = CLLocationCoordinate2D(latitude: 21.422487, longitude: 39.826206)

    var body: some View {
        NavigationStack {
            Map(position: $position) {
                // User location
                UserAnnotation()

                // Kaaba marker
                Marker("Kaaba", coordinate: kaabaCoordinate)
                    .tint(.black)

                // Line connecting user to Kaaba
                if let userLocation = viewModel.userLocation?.coordinate {
                    MapPolyline(
                        coordinates: geodesicCoordinates(from: userLocation, to: kaabaCoordinate)
                    )
                    .stroke(.green, style: StrokeStyle(lineWidth: 2, dash: [8, 4]))
                }
            }
            .mapStyle(selectedMapStyle == 0 ? .standard : .imagery(elevation: .realistic))
            .mapControls {
                MapUserLocationButton()
                MapCompass()
            }
            .navigationTitle("Qibla Map")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("", systemImage: "xmark") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .bottomBar) {
                    Button {
                        showMapStylePicker = true
                    } label: {
                        Image(systemName: selectedMapStyle == 0 ? "map" : "globe.americas.fill")
                            .font(.headline)
                    }
                }
            }
            .sheet(isPresented: $showMapStylePicker) {
                NavigationStack {
                    List {
                        Button {
                            selectedMapStyle = 0
                            showMapStylePicker = false
                        } label: {
                            HStack {
                                Label("Standard", systemImage: "map")
                                    .foregroundStyle(.primary)
                                Spacer()
                                if selectedMapStyle == 0 {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color.accentColor)
                                }
                            }
                        }

                        Button {
                            selectedMapStyle = 1
                            showMapStylePicker = false
                        } label: {
                            HStack {
                                Label("Satellite", systemImage: "globe.americas.fill")
                                    .foregroundStyle(.primary)
                                Spacer()
                                if selectedMapStyle == 1 {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color.accentColor)
                                }
                            }
                        }
                    }
                    .navigationTitle("Map Style")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("OK") {
                                showMapStylePicker = false
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    /// Generates geodesic coordinates for polyline
    private func geodesicCoordinates(
        from start: CLLocationCoordinate2D,
        to end: CLLocationCoordinate2D
    ) -> [CLLocationCoordinate2D] {
        let polyline = MKGeodesicPolyline(coordinates: [start, end], count: 2)
        var coords = [CLLocationCoordinate2D](
            repeating: kCLLocationCoordinate2DInvalid,
            count: polyline.pointCount
        )
        polyline.getCoordinates(&coords, range: NSRange(location: 0, length: polyline.pointCount))
        return coords
    }
}

#Preview {
    WatchQiblaMapView(viewModel: WatchQiblaViewModel())
}
