//
//  DamResourceTests.swift
//  NSWWaterTests
//
//  Created by 黑白熊 on 1/10/2025.
//

import XCTest
@testable import NSWWater

@MainActor  // 消除 “Main actor-isolated …” 警告
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

        // 如果你在模型里没写 CodingKeys，也可以启用蛇形转驼峰：
        let dec = JSONDecoder()
        // dec.keyDecodingStrategy = .convertFromSnakeCase

        let r = try dec.decode(DamResource.self, from: json)

        // 先解包，再断言（用 XCTUnwrap 能给出更清晰的失败信息）
        let volume  = try XCTUnwrap(r.volume,       "volume should decode")
        let inflow  = try XCTUnwrap(r.inflow,       "inflow should decode")
        let release = try XCTUnwrap(r.release,      "release should decode")
        let pf      = try XCTUnwrap(r.percentFull,  "percent_full should decode")

        XCTAssertEqual(volume,  2297.743, accuracy: 0.001)
        XCTAssertEqual(inflow,  0,         accuracy: 0.001)
        XCTAssertEqual(release, 0,         accuracy: 0.001)
        XCTAssertEqual(pf,      77.968,    accuracy: 0.001)

        // 如果你的模型里把 date 设为可选，缺省时应为 nil：
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
