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

    let viewModel: WatchQiblaViewModel

    @State private var position: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var selectedMapStyle: WatchQiblaMapStyle = .defaultStyle
    @State private var showMapStylePicker = false

    private let kaabaCoordinate = CLLocationCoordinate2D(latitude: 21.422487, longitude: 39.826206)

    var body: some View {
        NavigationStack {
            Map(position: $position) {
                UserAnnotation()

                Marker("Kaaba", coordinate: kaabaCoordinate)
                    .tint(.black)

                if let userLocation = viewModel.userLocation?.coordinate {
                    MapPolyline(
                        coordinates: geodesicCoordinates(from: userLocation, to: kaabaCoordinate)
                    )
                    .stroke(.green, style: StrokeStyle(lineWidth: 2, dash: [8, 4]))
                }
            }
            .mapStyle(selectedMapStyle.style)
            .mapControls {
                MapUserLocationButton()
                MapCompass()
            }
            .navigationTitle("Qibla Map")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .tint(.primary)
                }

                ToolbarItem(placement: .bottomBar) {
                    Button(
                        "Map Style",
                        systemImage: selectedMapStyle == .defaultStyle ? "map" : "globe.americas.fill"
                    ) {
                        showMapStylePicker = true
                    }
                    .font(.headline)
                }
            }
            .sheet(isPresented: $showMapStylePicker) {
                NavigationStack {
                    List {
                        Button {
                            selectedMapStyle = .defaultStyle
                            showMapStylePicker = false
                        } label: {
                            HStack {
                                Label("Default", systemImage: "map")
                                    .foregroundStyle(.primary)
                                Spacer()
                                if selectedMapStyle == .defaultStyle {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.accent)
                                }
                            }
                        }

                        Button {
                            selectedMapStyle = .satellite
                            showMapStylePicker = false
                        } label: {
                            HStack {
                                Label("Satellite", systemImage: "globe.americas.fill")
                                    .foregroundStyle(.primary)
                                Spacer()
                                if selectedMapStyle == .satellite {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.accent)
                                }
                            }
                        }
                    }
                    .navigationTitle("Map Style")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button {
                                showMapStylePicker = false
                            } label: {
                                Image(systemName: "checkmark")
                            }
                            .tint(.accent)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Helpers

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

private enum WatchQiblaMapStyle {
    case defaultStyle
    case satellite

    var style: MapStyle {
        switch self {
        case .defaultStyle:
            return .standard
        case .satellite:
            return .imagery(elevation: .realistic)
        }
    }
}

#Preview {
    WatchQiblaMapView(viewModel: WatchQiblaViewModel())
}
