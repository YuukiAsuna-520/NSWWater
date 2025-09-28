//
//  ContentView.swift
//  NSWWater
//
//  Created by 黑白熊 on 28/9/2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var damListVM = DamListViewModel()
    // Create a single shared instance and inject it into the environment.

    var body: some View {
        TabView {
            MapView()
                .tabItem { Label("Map", systemImage: "map") }
            DamListView()
                .tabItem { Label("Dams", systemImage: "list.bullet") }
            FavoritesView()
                .tabItem { Label("Favorites", systemImage: "star") }
        }
        .environmentObject(damListVM)
        // Make damListVM available to all tabs via the environment.
    }
}

#Preview {
    ContentView()
}
