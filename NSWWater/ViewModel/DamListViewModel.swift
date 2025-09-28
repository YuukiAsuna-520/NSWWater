//
//  DamListViewModel.swift
//  NSWWater
//
//  Created by 黑白熊 on 28/9/2025.
//

import Foundation
import Combine

final class DamListViewModel: ObservableObject {

    @Published var dams: [Dam] = StubLoader.loadDams()
    // Source data for the list, loaded from a local JSON stub for now.

    @Published var searchText: String = ""
    // Two-way binding for the search bar.

    var filtered: [Dam] {
        // Filtered list that returns the list after applying the search filter.
        
        // Return all dams if searchText is empty.
        guard !searchText.isEmpty else { return dams }
        
        // Else
        return dams.filter { dam in
            let nameMatch = dam.name.localizedCaseInsensitiveContains(searchText)
            
            let regionText = dam.region ?? ""  // If dam.region is nil，replaced by ""
            let regionMatch = regionText.localizedCaseInsensitiveContains(searchText)
            
            return nameMatch || regionMatch     // Either nameMatch or regionMatch
        }
    }
}
