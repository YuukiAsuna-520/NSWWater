//
//  DamResource.swift
//  NSWWater
//
//  Created by 黑白熊 on 1/10/2025.
//

import Foundation

struct DamResource: Decodable, Equatable {
    let percentFull: Double?
    let volume: Double?
    let inflow: Double?
    let release: Double?

    enum CodingKeys: String, CodingKey {
        case percentFull = "percent_full"
        case volume, inflow, release
    }
}
