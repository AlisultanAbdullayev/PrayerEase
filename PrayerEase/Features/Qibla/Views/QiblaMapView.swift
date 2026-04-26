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
    @Environment(LocationManager.self) private var locationManager

    @State private var position: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var selectedMapStyle: QiblaMapStyle = .defaultStyle

    private let kaabaCoordinate = CLLocationCoordinate2D(latitude: 21.422487, longitude: 39.826206)

    var body: some View {
        NavigationStack {
            Map(position: $position) {
                UserAnnotation()

                Marker("Kaaba", coordinate: kaabaCoordinate)
                    .tint(.black)

                if let userLocation = locationManager.userLocation?.coordinate {
                    MapPolyline(
                        coordinates: geodesicCoordinates(from: userLocation, to: kaabaCoordinate)
                    )
                    .stroke(.accent, style: StrokeStyle(lineWidth: 3, dash: [10, 5]))
                }
            }
            .mapStyle(selectedMapStyle.style)
            .mapControls {
                MapUserLocationButton()
                MapCompass()
                MapScaleView()
            }
            .navigationTitle("Qibla Map")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .tint(.primary)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            selectedMapStyle = .defaultStyle
                        } label: {
                            Label("Default", systemImage: "map")
                        }

                        Button {
                            selectedMapStyle = .satellite
                        } label: {
                            Label("Satellite", systemImage: "globe.americas.fill")
                        }
                    } label: {
                        Label(
                            "Map Style",
                            systemImage: selectedMapStyle == .defaultStyle
                                ? "map" : "globe.americas.fill"
                        )
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

private enum QiblaMapStyle {
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
    QiblaMapView()
        .environment(LocationManager())
}
