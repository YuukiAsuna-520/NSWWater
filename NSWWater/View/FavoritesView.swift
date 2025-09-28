//
//  FavoritesView.swift
//  NSWWater
//
//  Created by 黑白熊 on 28/9/2025.
//

import SwiftUI

struct FavoritesView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("Favorites").font(.title2).bold()
            Text("Saved dams will appear here (Core Data).")
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

#Preview {
    FavoritesView()
}
