//
//  FavoritesView.swift
//  NSWWater
//
//  Created by 黑白熊 on 28/9/2025.
//

import SwiftUI

struct FavoritesView: View {
    @EnvironmentObject var vm: DamListViewModel
    @EnvironmentObject var favs: FavoritesStore

    var body: some View {
        NavigationStack {
            if favs.ids.isEmpty {
                ContentUnavailableView(
                    "No favorites",
                    systemImage: "star",
                    description: Text("Swipe a dam in the list to add it here.")
                )
                .navigationTitle("Favorites")
            } else {
                List(favs.all(in: vm.dams)) { dam in
                    NavigationLink(destination: DamDetailView(dam: dam)) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(dam.name).font(.headline)
                            Text(String(format: "Lat %.4f, Lon %.4f", dam.latitude, dam.longitude))
                                .font(.footnote).foregroundStyle(.secondary)
                        }
                    }
                }
                .navigationTitle("Favorites")
                .toolbar {
                    Button("Clear") { favs.clear() }
                }
            }
        }
    }
}

#Preview {
    FavoritesView()
        .environmentObject(DamListViewModel())
        .environmentObject(FavoritesStore())
}
