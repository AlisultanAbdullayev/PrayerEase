import Contacts
import MapKit
import SwiftUI

struct ManualLocationSearchView: View {
    @Environment(LocationManager.self) private var locationManager
    @Environment(\.dismiss) private var dismiss

    @State private var query = ""
    @State private var results: [MKMapItem] = []
    @State private var isSearching = false

    var body: some View {
        List {
            if isSearching {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else if results.isEmpty && !query.isEmpty {
                Text("No results found")
                    .foregroundStyle(.secondary)
            }

            ForEach(results, id: \.self) { item in
                Button {
                    selectLocation(item)
                } label: {
                    VStack(alignment: .leading) {
                        Text(item.name ?? "Unknown Place")
                            .font(.headline)
                        if let context = item.addressRepresentations?.cityWithContext,
                            !context.isEmpty
                        {
                            Text(context)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .foregroundStyle(.primary)
            }
        }
        .searchable(text: $query, prompt: "Search city, address...")
        .onChange(of: query) { _, newValue in
            Task {
                await performSearch(query: newValue)
            }
        }
        .navigationTitle("Search Location")
    }

    private func performSearch(query: String) async {
        guard !query.isEmpty else {
            results = []
            return
        }
        isSearching = true
        let items = await locationManager.searchLocation(startingWith: query)
        await MainActor.run {
            self.results = items
            self.isSearching = false
        }
    }

    private func selectLocation(_ item: MKMapItem) {
        let location = item.location

        let name = item.name ?? "Manual Location"
        let context = item.addressRepresentations?.cityWithContext ?? ""
        let fullAddress = context.isEmpty ? name : context

        locationManager.setManualLocation(
            location,
            name: fullAddress,
            timeZone: item.timeZone
        )
        dismiss()
    }
}
