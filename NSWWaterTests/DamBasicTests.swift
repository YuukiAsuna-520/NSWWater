//
//  DamBasicTests.swift
//  NSWWaterTests
//
//  Created by 黑白熊 on 1/10/2025.
//

import XCTest
@testable import NSWWater

final class DamBasicTests: XCTestCase {
    func testStubDecoding() {
        let dams = StubLoader.loadDams()
        XCTAssertFalse(dams.isEmpty)
        XCTAssertFalse(dams[0].id.isEmpty)
        XCTAssertFalse(dams[0].name.isEmpty)
    }

    func testFiltering() {
        let vm = DamListViewModel()
        vm.dams = [
            Dam(id: "A", name: "Alpha", latitude: 0, longitude: 0, fullVolume: nil),
            Dam(id: "B", name: "Beta",  latitude: 0, longitude: 0, fullVolume: nil)
        ]
        vm.searchText = "alp"
        XCTAssertEqual(vm.filtered.map { $0.id }, ["A"])
    }
}
