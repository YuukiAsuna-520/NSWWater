//
//  DamDetailView.swift
//  NSWWater
//
//  Created by 黑白熊 on 30/9/2025.
//

import SwiftUI
import MapKit

struct DamDetailView: View {
    let dam: Dam
    @EnvironmentObject var vm: DamListViewModel   // read view model

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(dam.name)
                    .font(.title)
                    .bold()

                // Coordinates
                Label(String(format: "Lat %.4f, Lon %.4f", dam.latitude, dam.longitude),
                      systemImage: "location")

                // Full volume (from list model)
                if let volume = dam.fullVolume {
                    Label("Full volume: \(volume) ML", systemImage: "drop.triangle")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // --- Latest monthly resource (from API) ---
                if let r = vm.latestByDam[dam.id] {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Latest (month)").font(.headline)
                        Text("Date: \(format(date: r.date))")
                        Text(String(format: "Percent full: %.1f%%", r.percentFull))
                        Text(String(format: "Inflow: %.0f ML", r.inflow))
                        Text(String(format: "Release: %.0f ML", r.release))
                        Text(String(format: "Volume: %.0f ML", r.volume))
                    }
                    .padding()
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                } else {
                    Text(BuildFlags.useNetwork
                         ? "Fetching latest..."
                         : "Using stub data (latest not fetched).")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                // --- end latest ---

                // Map
                Map(initialPosition: .region(
                    MKCoordinateRegion(
                        center: CLLocationCoordinate2D(latitude: dam.latitude, longitude: dam.longitude),
                        span: MKCoordinateSpan(latitudeDelta: 0.18, longitudeDelta: 0.18)
                    )
                )) {
                    Marker(dam.name, coordinate: CLLocationCoordinate2D(latitude: dam.latitude, longitude: dam.longitude))
                }
                .frame(height: 220)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding()
        }
        .navigationTitle("Dam Details")
        .navigationBarTitleDisplayMode(.inline)
        .task { await vm.loadLatest(for: dam) }  // fetch latest on appear
    }

    private func format(date: Date) -> String {
        let df = DateFormatter()
        df.dateStyle = .medium
        return df.string(from: date)
    }
}

#Preview {
    DamDetailView(
        dam: Dam(
            id: "WARRAGAMBA",
            name: "Warragamba Dam",
            latitude: -33.875,
            longitude: 150.602,
            fullVolume: 35800
        )
    )
    .environmentObject(DamListViewModel())
}
