//
//  MapView.swift
//  NSWWater
//
//  Created by 黑白熊 on 28/9/2025.
//

import SwiftUI
import MapKit

struct MapView: View {
    @EnvironmentObject var vm: DamListViewModel
    
    // Static region centered on Sydney.
    @State private var camera: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: -33.8688, longitude: 151.2093),
            span: MKCoordinateSpan(latitudeDelta: 0.3, longitudeDelta: 0.3)
        )
    )

    var body: some View {
        Map(position: $camera) {
            // Optional pins for dams (from stub data or API later).
            ForEach(vm.dams) { dam in
                Marker(dam.name, coordinate: dam.coordinate)
            }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    MapView().environmentObject(DamListViewModel())
}
