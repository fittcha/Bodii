//
//  SleepStatusTests.swift
//  BodiiTests
//
//  Created by Auto-Claude on 2026-01-12.
//

import XCTest
@testable import Bodii

/// Unit tests for SleepStatus factory method
///
/// SleepStatus 팩토리 메서드에 대한 단위 테스트
final class SleepStatusTests: XCTestCase {

    // MARK: - Bad Status Tests (<330 minutes)

    /// Test: 0 minutes should return bad status
    ///
    /// 테스트: 0분은 나쁨 상태를 반환해야 함
    func testFrom_ZeroMinutes_ReturnsBad() {
        // Given: 0 minutes of sleep (no sleep)
        let duration: Int32 = 0

        // When: Creating sleep status
        let status = SleepStatus.from(durationMinutes: duration)

        // Then: Should return bad status
        XCTAssertEqual(status, .bad, "0 minutes should return bad status")
        XCTAssertEqual(status.displayName, "나쁨", "Display name should be '나쁨'")
    }

    /// Test: 1 minute should return bad status
    ///
    /// 테스트: 1분은 나쁨 상태를 반환해야 함
    func testFrom_OneMinute_ReturnsBad() {
        // Given: 1 minute of sleep
        let duration: Int32 = 1

        // When: Creating sleep status
        let status = SleepStatus.from(durationMinutes: duration)

        // Then: Should return bad status
        XCTAssertEqual(status, .bad, "1 minute should return bad status")
    }

    /// Test: 329 minutes (just below boundary) should return bad status
    ///
    /// 테스트: 329분(경계 바로 아래)은 나쁨 상태를 반환해야 함
    func testFrom_329Minutes_ReturnsBad() {
        // Given: 329 minutes of sleep (5h 29m, just below soso threshold)
        let duration: Int32 = 329

        // When: Creating sleep status
        let status = SleepStatus.from(durationMinutes: duration)

        // Then: Should return bad status
        XCTAssertEqual(status, .bad, "329 minutes should return bad status (just below 330)")
    }

    /// Test: Normal bad sleep duration (4 hours = 240 minutes)
    ///
    /// 테스트: 일반적인 나쁨 수면 시간 (4시간 = 240분)
    func testFrom_240Minutes_ReturnsBad() {
        // Given: 240 minutes of sleep (4 hours)
        let duration: Int32 = 240

        // When: Creating sleep status
        let status = SleepStatus.from(durationMinutes: duration)

        // Then: Should return bad status
        XCTAssertEqual(status, .bad, "240 minutes (4 hours) should return bad status")
    }

    // MARK: - Soso Status Tests (330-389 minutes)

    /// Test: 330 minutes (minimum boundary) should return soso status
    ///
    /// 테스트: 330분(최소 경계)은 보통 상태를 반환해야 함
    func testFrom_330Minutes_ReturnsSoso() {
        // Given: 330 minutes of sleep (5h 30m, minimum soso threshold)
        let duration: Int32 = 330

        // When: Creating sleep status
        let status = SleepStatus.from(durationMinutes: duration)

        // Then: Should return soso status
        XCTAssertEqual(status, .soso, "330 minutes should return soso status (minimum boundary)")
        XCTAssertEqual(status.displayName, "보통", "Display name should be '보통'")
    }

    /// Test: 331 minutes (just above minimum) should return soso status
    ///
    /// 테스트: 331분(최소 경계 바로 위)은 보통 상태를 반환해야 함
    func testFrom_331Minutes_ReturnsSoso() {
        // Given: 331 minutes of sleep (5h 31m)
        let duration: Int32 = 331

        // When: Creating sleep status
        let status = SleepStatus.from(durationMinutes: duration)

        // Then: Should return soso status
        XCTAssertEqual(status, .soso, "331 minutes should return soso status")
    }

    /// Test: 360 minutes (middle of range) should return soso status
    ///
    /// 테스트: 360분(범위 중간)은 보통 상태를 반환해야 함
    func testFrom_360Minutes_ReturnsSoso() {
        // Given: 360 minutes of sleep (6 hours, middle of soso range)
        let duration: Int32 = 360

        // When: Creating sleep status
        let status = SleepStatus.from(durationMinutes: duration)

        // Then: Should return soso status
        XCTAssertEqual(status, .soso, "360 minutes (6 hours) should return soso status")
    }

    /// Test: 389 minutes (just below maximum) should return soso status
    ///
    /// 테스트: 389분(최대 경계 바로 아래)은 보통 상태를 반환해야 함
    func testFrom_389Minutes_ReturnsSoso() {
        // Given: 389 minutes of sleep (6h 29m, just below good threshold)
        let duration: Int32 = 389

        // When: Creating sleep status
        let status = SleepStatus.from(durationMinutes: duration)

        // Then: Should return soso status
        XCTAssertEqual(status, .soso, "389 minutes should return soso status (just below 390)")
    }

    // MARK: - Good Status Tests (390-449 minutes)

    /// Test: 390 minutes (minimum boundary) should return good status
    ///
    /// 테스트: 390분(최소 경계)은 좋음 상태를 반환해야 함
    func testFrom_390Minutes_ReturnsGood() {
        // Given: 390 minutes of sleep (6h 30m, minimum good threshold)
        let duration: Int32 = 390

        // When: Creating sleep status
        let status = SleepStatus.from(durationMinutes: duration)

        // Then: Should return good status
        XCTAssertEqual(status, .good, "390 minutes should return good status (minimum boundary)")
        XCTAssertEqual(status.displayName, "좋음", "Display name should be '좋음'")
    }

    /// Test: 391 minutes (just above minimum) should return good status
    ///
    /// 테스트: 391분(최소 경계 바로 위)은 좋음 상태를 반환해야 함
    func testFrom_391Minutes_ReturnsGood() {
        // Given: 391 minutes of sleep (6h 31m)
        let duration: Int32 = 391

        // When: Creating sleep status
        let status = SleepStatus.from(durationMinutes: duration)

        // Then: Should return good status
        XCTAssertEqual(status, .good, "391 minutes should return good status")
    }

    /// Test: 420 minutes (middle of range) should return good status
    ///
    /// 테스트: 420분(범위 중간)은 좋음 상태를 반환해야 함
    func testFrom_420Minutes_ReturnsGood() {
        // Given: 420 minutes of sleep (7 hours, middle of good range)
        let duration: Int32 = 420

        // When: Creating sleep status
        let status = SleepStatus.from(durationMinutes: duration)

        // Then: Should return good status
        XCTAssertEqual(status, .good, "420 minutes (7 hours) should return good status")
    }

    /// Test: 449 minutes (just below maximum) should return good status
    ///
    /// 테스트: 449분(최대 경계 바로 아래)은 좋음 상태를 반환해야 함
    func testFrom_449Minutes_ReturnsGood() {
        // Given: 449 minutes of sleep (7h 29m, just below excellent threshold)
        let duration: Int32 = 449

        // When: Creating sleep status
        let status = SleepStatus.from(durationMinutes: duration)

        // Then: Should return good status
        XCTAssertEqual(status, .good, "449 minutes should return good status (just below 450)")
    }

    // MARK: - Excellent Status Tests (450-540 minutes)

    /// Test: 450 minutes (minimum boundary) should return excellent status
    ///
    /// 테스트: 450분(최소 경계)은 매우 좋음 상태를 반환해야 함
    func testFrom_450Minutes_ReturnsExcellent() {
        // Given: 450 minutes of sleep (7h 30m, minimum excellent threshold)
        let duration: Int32 = 450

        // When: Creating sleep status
        let status = SleepStatus.from(durationMinutes: duration)

        // Then: Should return excellent status
        XCTAssertEqual(status, .excellent, "450 minutes should return excellent status (minimum boundary)")
        XCTAssertEqual(status.displayName, "매우 좋음", "Display name should be '매우 좋음'")
    }

    /// Test: 451 minutes (just above minimum) should return excellent status
    ///
    /// 테스트: 451분(최소 경계 바로 위)은 매우 좋음 상태를 반환해야 함
    func testFrom_451Minutes_ReturnsExcellent() {
        // Given: 451 minutes of sleep (7h 31m)
        let duration: Int32 = 451

        // When: Creating sleep status
        let status = SleepStatus.from(durationMinutes: duration)

        // Then: Should return excellent status
        XCTAssertEqual(status, .excellent, "451 minutes should return excellent status")
    }

    /// Test: 480 minutes (middle of range) should return excellent status
    ///
    /// 테스트: 480분(범위 중간)은 매우 좋음 상태를 반환해야 함
    func testFrom_480Minutes_ReturnsExcellent() {
        // Given: 480 minutes of sleep (8 hours, middle of excellent range)
        let duration: Int32 = 480

        // When: Creating sleep status
        let status = SleepStatus.from(durationMinutes: duration)

        // Then: Should return excellent status
        XCTAssertEqual(status, .excellent, "480 minutes (8 hours) should return excellent status")
    }

    /// Test: 540 minutes (maximum boundary) should return excellent status
    ///
    /// 테스트: 540분(최대 경계)은 매우 좋음 상태를 반환해야 함
    func testFrom_540Minutes_ReturnsExcellent() {
        // Given: 540 minutes of sleep (9 hours, maximum excellent threshold)
        let duration: Int32 = 540

        // When: Creating sleep status
        let status = SleepStatus.from(durationMinutes: duration)

        // Then: Should return excellent status
        XCTAssertEqual(status, .excellent, "540 minutes should return excellent status (maximum boundary)")
    }

    // MARK: - Oversleep Status Tests (>540 minutes)

    /// Test: 541 minutes (just above maximum) should return oversleep status
    ///
    /// 테스트: 541분(최대 경계 바로 위)은 과다 수면 상태를 반환해야 함
    func testFrom_541Minutes_ReturnsOversleep() {
        // Given: 541 minutes of sleep (9h 1m, just above excellent threshold)
        let duration: Int32 = 541

        // When: Creating sleep status
        let status = SleepStatus.from(durationMinutes: duration)

        // Then: Should return oversleep status
        XCTAssertEqual(status, .oversleep, "541 minutes should return oversleep status (just above 540)")
        XCTAssertEqual(status.displayName, "과다 수면", "Display name should be '과다 수면'")
    }

    /// Test: 600 minutes (10 hours) should return oversleep status
    ///
    /// 테스트: 600분(10시간)은 과다 수면 상태를 반환해야 함
    func testFrom_600Minutes_ReturnsOversleep() {
        // Given: 600 minutes of sleep (10 hours)
        let duration: Int32 = 600

        // When: Creating sleep status
        let status = SleepStatus.from(durationMinutes: duration)

        // Then: Should return oversleep status
        XCTAssertEqual(status, .oversleep, "600 minutes (10 hours) should return oversleep status")
    }

    /// Test: 720 minutes (12 hours) should return oversleep status
    ///
    /// 테스트: 720분(12시간)은 과다 수면 상태를 반환해야 함
    func testFrom_720Minutes_ReturnsOversleep() {
        // Given: 720 minutes of sleep (12 hours)
        let duration: Int32 = 720

        // When: Creating sleep status
        let status = SleepStatus.from(durationMinutes: duration)

        // Then: Should return oversleep status
        XCTAssertEqual(status, .oversleep, "720 minutes (12 hours) should return oversleep status")
    }

    /// Test: Very large duration should return oversleep status
    ///
    /// 테스트: 매우 큰 시간은 과다 수면 상태를 반환해야 함
    func testFrom_VeryLargeDuration_ReturnsOversleep() {
        // Given: 1440 minutes of sleep (24 hours, extreme case)
        let duration: Int32 = 1440

        // When: Creating sleep status
        let status = SleepStatus.from(durationMinutes: duration)

        // Then: Should return oversleep status
        XCTAssertEqual(status, .oversleep, "1440 minutes (24 hours) should return oversleep status")
    }

    // MARK: - Boundary Verification Tests

    /// Test: All boundary values are correctly handled
    ///
    /// 테스트: 모든 경계값이 올바르게 처리되는지 확인
    func testFrom_AllBoundaries_CorrectStatuses() {
        // Given: Array of (duration, expected status) tuples
        let testCases: [(duration: Int32, expected: SleepStatus, description: String)] = [
            (0, .bad, "0분 (밤샘)"),
            (329, .bad, "329분 (bad 최대)"),
            (330, .soso, "330분 (soso 최소)"),
            (389, .soso, "389분 (soso 최대)"),
            (390, .good, "390분 (good 최소)"),
            (449, .good, "449분 (good 최대)"),
            (450, .excellent, "450분 (excellent 최소)"),
            (540, .excellent, "540분 (excellent 최대)"),
            (541, .oversleep, "541분 (oversleep 최소)")
        ]

        // When/Then: Each boundary should return correct status
        for testCase in testCases {
            let status = SleepStatus.from(durationMinutes: testCase.duration)
            XCTAssertEqual(
                status,
                testCase.expected,
                "\(testCase.description) should return \(testCase.expected.displayName)"
            )
        }
    }

    // MARK: - Real-world Scenario Tests

    /// Test: Common real-world sleep durations return expected statuses
    ///
    /// 테스트: 일반적인 실제 수면 시간이 예상된 상태를 반환하는지 확인
    func testFrom_RealWorldScenarios_CorrectStatuses() {
        // Given: Common sleep durations
        let testCases: [(hours: Int, minutes: Int, expected: SleepStatus)] = [
            (3, 0, .bad),          // 3시간 (극단적 부족)
            (5, 0, .bad),          // 5시간 (부족)
            (5, 30, .soso),        // 5시간 30분 (경계)
            (6, 0, .soso),         // 6시간 (보통)
            (6, 30, .good),        // 6시간 30분 (경계)
            (7, 0, .good),         // 7시간 (좋음)
            (7, 30, .excellent),   // 7시간 30분 (경계)
            (8, 0, .excellent),    // 8시간 (매우 좋음)
            (9, 0, .excellent),    // 9시간 (매우 좋음)
            (10, 0, .oversleep),   // 10시간 (과다)
            (12, 0, .oversleep)    // 12시간 (과다)
        ]

        // When/Then: Each duration should return correct status
        for testCase in testCases {
            let totalMinutes: Int32 = Int32(testCase.hours * 60 + testCase.minutes)
            let status = SleepStatus.from(durationMinutes: totalMinutes)
            XCTAssertEqual(
                status,
                testCase.expected,
                "\(testCase.hours)시간 \(testCase.minutes)분 should return \(testCase.expected.displayName)"
            )
        }
    }

    // MARK: - Edge Case from Documentation

    /// Test: Edge case from docs - 0 hours 0 minutes allowed (all-nighter)
    ///
    /// 테스트: 문서의 엣지 케이스 - 0시간 0분 허용 (밤샘)
    func testFrom_AllNighter_ReturnsBad() {
        // Given: 0 minutes of sleep (all-nighter scenario from docs)
        let duration: Int32 = 0

        // When: Creating sleep status
        let status = SleepStatus.from(durationMinutes: duration)

        // Then: Should return bad status (documented as allowed)
        XCTAssertEqual(status, .bad, "All-nighter (0분) should return bad status")
    }
}
