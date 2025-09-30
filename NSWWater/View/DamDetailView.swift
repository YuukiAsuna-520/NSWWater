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
    // Minimal details + a small map centered on this dam.

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(dam.name).font(.title).bold()

                if let region = dam.region, !region.isEmpty {
                    Label(region, systemImage: "map")
                }

                Label(String(format: "%.4f, %.4f", dam.latitude, dam.longitude),
                      systemImage: "location")

                if let p = dam.storagePercent {
                    Label(String(format: "Storage: %.1f%%", p),
                          systemImage: "drop.fill")
                }

                Map(initialPosition: .region(
                    MKCoordinateRegion(
                        center: dam.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
                    )
                )) {
                    Marker(dam.name, coordinate: dam.coordinate)
                }
                .frame(height: 220)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding()
        }
        .navigationTitle("Dam Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    DamDetailView(
        dam: Dam(
            id: "WARRAGAMBA",
            name: "Warragamba Dam",
            latitude: -33.875, longitude: 150.602,
            region: "Sydney", storagePercent: 83.2
        )
    )
}

