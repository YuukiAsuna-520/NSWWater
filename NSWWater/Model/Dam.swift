//
//  Dam.swift
//  NSWWater
//
//  Created by 黑白熊 on 28/9/2025.
//

struct Dam: Identifiable, Decodable {
    let id: String
    let name: String
    let latitude: Double
    let longitude: Double
    let fullVolume: Int

    enum CodingKeys: String, CodingKey {
        case id         = "dam_id"
        case name       = "dam_name"
        case latitude   = "lat"
        case longitude  = "long"
        case fullVolume = "full_volume"
    }
}

