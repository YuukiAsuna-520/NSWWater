//
//  NSWWaterApp.swift
//  NSWWater
//
//  Created by 黑白熊 on 28/9/2025.
//

import SwiftUI

@main
struct NSWWaterApp: App {
    @StateObject private var vm = DamListViewModel()
    @StateObject private var favs = FavoritesStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(vm)
                .environmentObject(favs)
        }
    }
}
