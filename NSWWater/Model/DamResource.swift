//
//  DamResource.swift
//  NSWWater
//
//  Created by 黑白熊 on 1/10/2025.
//

import Foundation

// Latest monthly resource for a dam.
struct DamResource: Decodable, Equatable {
    let date: Date
    let volume: Double
    let inflow: Double
    let release: Double
    let percentFull: Double

    enum CodingKeys: String, CodingKey {
        case date, volume, inflow, release
        case percentFull = "percent_full"
    }

    // Custom date parsing: support "yyyy-MM-dd" and ISO8601.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let dateStr = try c.decode(String.self, forKey: .date)

        if let d = DamResource.parseDate(dateStr) {
            self.date = d
        } else {
            throw DecodingError.dataCorruptedError(forKey: .date,
                                                   in: c,
                                                   debugDescription: "Unsupported date: \(dateStr)")
        }

        volume      = try c.decode(Double.self, forKey: .volume)
        inflow      = try c.decode(Double.self, forKey: .inflow)
        release     = try c.decode(Double.self, forKey: .release)
        percentFull = try c.decode(Double.self, forKey: .percentFull)
    }

    private static func parseDate(_ s: String) -> Date? {
        // Try ISO 8601 first
        let iso = ISO8601DateFormatter()
        if let d = iso.date(from: s) { return d }

        // Then yyyy-MM-dd
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "en_US_POSIX")
        fmt.dateFormat = "yyyy-MM-dd"
        return fmt.date(from: s)
    }
}
