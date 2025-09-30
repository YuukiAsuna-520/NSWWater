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
    @EnvironmentObject var vm: DamListViewModel

    @State private var isFetching = false

    private var latest: DamResource? { vm.latestByDam[dam.id] }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                // Title
                Text(dam.name)
                    .font(.title).bold()

                // Coordinates
                Label {
                    Text(String(format: "Lat %.4f, Lon %.4f", dam.latitude, dam.longitude))
                } icon: {
                    Image(systemName: "location")
                }

                // Design capacity (from Dam)
                if let volume = dam.fullVolume {
                    Label {
                        Text("Full volume: \(volume) ML")
                    } icon: {
                        Image(systemName: "drop.triangle")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }

                // Latest metrics (NO date)
                if let r = latest {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Latest").font(.headline)

                        if let p = r.percentFull {
                            Label {
                                Text(String(format: "Storage: %.1f%%", p))
                            } icon: {
                                Image(systemName: "gauge.with.dots.needle.bottom.50percent")
                            }
                            .foregroundStyle(.secondary)
                        }

                        if let v = r.volume {
                            Label {
                                Text(String(format: "Current volume: %.0f ML", v))
                            } icon: {
                                Image(systemName: "drop.fill")
                            }
                            .foregroundStyle(.secondary)
                        }

                        if let i = r.inflow {
                            Label {
                                Text(String(format: "Inflow: %.0f ML", i))
                            } icon: {
                                Image(systemName: "arrow.down")
                            }
                            .foregroundStyle(.secondary)
                        }

                        if let o = r.release {
                            Label {
                                Text(String(format: "Release: %.0f ML", o))
                            } icon: {
                                Image(systemName: "arrow.up")
                            }
                            .foregroundStyle(.secondary)
                        }
                    }
                    .padding()
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                } else {
                    Text(isFetching ? "Loading latest…" : "Latest data unavailable.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

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
        .task { await fetchLatest() }
        .refreshable { await fetchLatest() }
    }

    // MARK: - Helpers

    private func fetchLatest() async {
        isFetching = true
        await vm.loadLatest(for: dam)
        isFetching = false
    }
}
