//
//  MapView.swift
//  NSWWater
//
//  Created by 黑白熊 on 28/9/2025.
//

import SwiftUI

struct MapView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("Map View").font(.title2).bold()
            Text("This will be replaced with a real MapKit map.")
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

#Preview {
    MapView()
}
