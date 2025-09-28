//
//  StubLoader.swift
//  NSWWater
//
//  Created by 黑白熊 on 28/9/2025.
//

import Foundation

enum StubLoader {
    static func loadDams() -> [Dam] {
        guard
            let url = Bundle.main.url(forResource: "dams_stub", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let dams = try? JSONDecoder().decode([Dam].self, from: data)
        else { return [] }
        return dams
    }
}
