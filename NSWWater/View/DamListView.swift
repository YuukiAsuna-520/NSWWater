//
//  DamListView.swift
//  NSWWater
//
//  Created by 黑白熊 on 28/9/2025.
//

import SwiftUI

struct DamListView: View {
    @EnvironmentObject var vm: DamListViewModel
    // Read the shared VM from the environment.

    var body: some View {
        NavigationStack {
            List(vm.filtered) { dam in
                NavigationLink(destination: DamDetailView(dam: dam)) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(dam.name)
                            .font(.headline) // Dam name

                        // Show coordinates
                        Text(String(format: "Lat %.4f, Lon %.4f", dam.latitude, dam.longitude))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Dams")
            .searchable(text: $vm.searchText, prompt: "Search by name")
            // Kick off the first network load when the list appears.
            .task {
                await vm.loadFromNetworkReplacingStub()
            }
            // Pull-to-refresh to re-fetch from the API.
            .refreshable {
                await vm.loadFromNetworkReplacingStub()
            }
        }
    }
}

#Preview {
    DamListView().environmentObject(DamListViewModel())
}
