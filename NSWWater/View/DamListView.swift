//
//  DamListView.swift
//  NSWWater
//
//  Created by 黑白熊 on 28/9/2025.
//

import SwiftUI

struct DamListView: View {
    @EnvironmentObject var vm: DamListViewModel        // Read shared VM from environment

    @State private var showError = false               // Drive alert presentation

    var body: some View {
        NavigationStack {
            List {
                ForEach(vm.filtered) { dam in
                    NavigationLink {
                        DamDetailView(dam: dam)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(dam.name)
                                .font(.headline)      // Dam name

                            Text(String(format: "Lat %.4f, Lon %.4f",
                                         dam.latitude, dam.longitude))
                                .font(.footnote)
                                .foregroundStyle(.secondary)  // Coordinates
                        }
                    }
                }
            }
            .navigationTitle("Dams")
            .searchable(text: $vm.searchText, prompt: "Search by name or id")
            // Load once when view first appears (avoids duplicate loads when switching tabs)
            .task { await vm.ensureLoadedOnce() }

            // Pull to refresh
            .refreshable { await vm.refresh() }

            // Loading spinner & empty state overlay
            .overlay {
                if vm.isLoading {
                    ProgressView()
                        .controlSize(.large)
                } else if vm.filtered.isEmpty {
                    ContentUnavailableView(
                        "No results",
                        systemImage: "magnifyingglass",
                        description: Text("Try a different keyword.")
                    )
                }
            }

            // Show alert when lastError changes to non-nil
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
    DamListView().environmentObject(DamListViewModel())
}
