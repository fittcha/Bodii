//
//  BodiiTests.swift
//  BodiiTests
//
//  Created by Bodii Team on 2026-01-24.
//

import XCTest
@testable import Bodii

final class BodiiTests: XCTestCase {

    func testBasicAssertions() throws {
        // 기본 동작 확인을 위한 간단한 테스트
        XCTAssertTrue(true, "기본 테스트가 통과해야 합니다")
        XCTAssertEqual(1 + 1, 2, "기본 산술 연산이 정상 동작해야 합니다")
    }

    func testAppBundleExists() throws {
        // 앱 번들이 존재하는지 확인
        let bundle = Bundle(for: type(of: self))
        XCTAssertNotNil(bundle, "테스트 번들이 존재해야 합니다")
    }
}
