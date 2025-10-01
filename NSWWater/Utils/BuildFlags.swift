//
//  BuildFlags.swift
//  NSWWater
//
//  Created by 黑白熊 on 28/9/2025.
//

import Foundation

enum BuildFlags {
    // Toggle to use live API; keep `false` for stub/offline.
    // If you have API, it will try to use network at first.
    // It's 'OR' not 'AND', if you want to trun off network change '||' to '&&' in vm
    static let useNetwork = false
}
