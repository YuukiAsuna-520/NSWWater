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

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(dam.name)
                    .font(.title)
                    .bold()

                // Show coordinates
                Label(String(format: "Lat %.4f, Lon %.4f", dam.latitude, dam.longitude),
                      systemImage: "location")

                if let volume = dam.fullVolume {
                    Label("Full volume: \(volume) ML",
                          systemImage: "drop.triangle")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

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
}
