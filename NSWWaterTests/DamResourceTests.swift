//
//  DamResourceTests.swift
//  NSWWaterTests
//
//  Created by 黑白熊 on 1/10/2025.
//

import XCTest
@testable import NSWWater

@MainActor
final class DamResourceTests: XCTestCase {

    func testDecodeDamResource_withoutDate() throws {
        let json = """
        {
          "volume": 2297.743,
          "inflow": 0,
          "release": 0,
          "percent_full": 77.968
        }
        """.data(using: .utf8)!

        let dec = JSONDecoder()
        // dec.keyDecodingStrategy = .convertFromSnakeCase

        let r = try dec.decode(DamResource.self, from: json)

        let volume  = try XCTUnwrap(r.volume,       "volume should decode")
        let inflow  = try XCTUnwrap(r.inflow,       "inflow should decode")
        let release = try XCTUnwrap(r.release,      "release should decode")
        let pf      = try XCTUnwrap(r.percentFull,  "percent_full should decode")

        XCTAssertEqual(volume,  2297.743, accuracy: 0.001)
        XCTAssertEqual(inflow,  0,         accuracy: 0.001)
        XCTAssertEqual(release, 0,         accuracy: 0.001)
        XCTAssertEqual(pf,      77.968,    accuracy: 0.001)

        // XCTAssertNil(r.date)
    }

    func testDecodeDamResource_missingKeysBecomeNil() throws {
        let json = #"{ "percent_full": 12.34 }"#.data(using: .utf8)!
        let r = try JSONDecoder().decode(DamResource.self, from: json)

        XCTAssertEqual(try XCTUnwrap(r.percentFull), 12.34, accuracy: 0.001)
        XCTAssertNil(r.volume)
        XCTAssertNil(r.inflow)
        XCTAssertNil(r.release)
        // XCTAssertNil(r.date)
    }
}
