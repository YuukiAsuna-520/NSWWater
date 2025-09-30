//
//  DamListView.swift
//  NSWWater
//
//  Created by 黑白熊 on 28/9/2025.
//

import SwiftUI

struct DamListView: View {
    @EnvironmentObject var vm: DamListViewModel        // shared VM
    @EnvironmentObject var favs: FavoritesStore        // favorites

    @State private var showError = false               // drive alert

    var body: some View {
        NavigationStack {
            List {
                ForEach(vm.filtered) { dam in
                    NavigationLink {
                        DamDetailView(dam: dam)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(dam.name)
                                    .font(.headline)

                                Text(String(format: "Lat %.4f, Lon %.4f",
                                            dam.latitude, dam.longitude))
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if favs.isFav(dam.id) {
                                Image(systemName: "star.fill")
                                    .foregroundStyle(.yellow)
                                    .accessibilityLabel("Favorited")
                            }
                        }
                    }
                    // swipe to (un)favorite
                    .swipeActions(edge: .trailing) {
                        Button {
                            favs.toggle(dam.id)
                        } label: {
                            Label(favs.isFav(dam.id) ? "Unfavorite" : "Favorite",
                                  systemImage: favs.isFav(dam.id) ? "star.slash" : "star")
                        }
                        .tint(.yellow)
                    }
                }
            }
            .navigationTitle("Dams")
            .searchable(text: $vm.searchText, prompt: "Search by name or id")

            // load once on first appear
            .task { await vm.ensureLoadedOnce() }

            // pull to refresh
            .refreshable { await vm.refresh() }

            // loading & empty overlays
            .overlay {
                if vm.isLoading {
                    ProgressView().controlSize(.large)
                } else if vm.filtered.isEmpty {
                    ContentUnavailableView(
                        "No results",
                        systemImage: "magnifyingglass",
                        description: Text("Try a different keyword.")
                    )
                }
            }

            // error alert
            .onChange(of: vm.lastError) { _, newValue in
                showError = (newValue != nil)
            }
            .alert("Network Error", isPresented: $showError, presenting: vm.lastError) { _ in
                Button("OK", role: .cancel) {}
            } message: { err in
                Text(err)
            }
        }
    }
}

#Preview {
    DamListView()
        .environmentObject(DamListViewModel())
        .environmentObject(FavoritesStore())
}
