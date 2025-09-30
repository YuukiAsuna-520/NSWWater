//
//  DamListView.swift
//  NSWWater
//
//  Created by 黑白熊 on 28/9/2025.
//

import SwiftUI

struct DamListView: View {
    @EnvironmentObject var vm: DamListViewModel
    // Read the shared view model from the environment.

    var body: some View {
        NavigationStack {
            List(vm.filtered) { dam in
                NavigationLink(destination: DamDetailView(dam: dam)) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(dam.name).font(.headline)                    // Name
                        Text(dam.region ?? "NSW")
                            .font(.subheadline).foregroundStyle(.secondary) // Region
                        if let p = dam.storagePercent {
                            Text(String(format: "Storage: %.1f%%", p))
                                .font(.caption).foregroundStyle(.secondary) // Storage
                        }
                    }
                }
            }
            .navigationTitle("Dams")    // View Title
            .searchable(text: $vm.searchText, prompt: "Search by name or region")
            // Bind search bar to the view model's searchText.
        }
    }
}

#Preview {
    DamListView().environmentObject(DamListViewModel())
}

