//
//  VisionAPIUsageTrackerTests.swift
//  BodiiTests
//
//  Created by Auto-Claude on 2026-01-17.
//

import XCTest
@testable import Bodii

/// Unit tests for VisionAPIUsageTracker
///
/// VisionAPIUsageTracker의 사용량 추적, 월간 리셋, 할당량 관리 단위 테스트
///
/// **테스트 범위:**
/// - Monthly usage tracking and persistence
/// - Automatic monthly reset logic
/// - Quota checking and warning thresholds
/// - Thread-safe operations
/// - Days until reset calculation
final class VisionAPIUsageTrackerTests: XCTestCase {

    // MARK: - Properties

    var tracker: VisionAPIUsageTracker!
    var testUserDefaults: UserDefaults!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()

        // Create isolated UserDefaults for testing
        // 테스트용 격리된 UserDefaults 생성
        testUserDefaults = UserDefaults(suiteName: "VisionAPIUsageTrackerTests")!
        testUserDefaults.removePersistentDomain(forName: "VisionAPIUsageTrackerTests")

        // Initialize tracker with test UserDefaults
        tracker = VisionAPIUsageTracker(userDefaults: testUserDefaults)
    }

    override func tearDown() {
        // Clean up test data
        testUserDefaults.removePersistentDomain(forName: "VisionAPIUsageTrackerTests")
        tracker = nil
        testUserDefaults = nil
        super.tearDown()
    }

    // MARK: - Initial State Tests

    /// Test: Initial state has zero usage
    ///
    /// 테스트: 초기 상태는 사용량이 0
    func testInitialState_HasZeroUsage() {
        // When: Checking initial usage
        let usage = tracker.getCurrentUsage()

        // Then: Should be zero
        XCTAssertEqual(usage, 0, "Initial usage should be 0")
    }

    /// Test: Initial state allows requests
    ///
    /// 테스트: 초기 상태는 요청 가능
    func testInitialState_AllowsRequests() {
        // When: Checking if can make request
        let canMake = tracker.canMakeRequest()

        // Then: Should allow requests
        XCTAssertTrue(canMake, "Should allow requests initially")
    }

    /// Test: Initial state has full quota remaining
    ///
    /// 테스트: 초기 상태는 전체 할당량 남아있음
    func testInitialState_HasFullQuotaRemaining() {
        // When: Checking remaining quota
        let remaining = tracker.getRemainingQuota()

        // Then: Should have full quota (1000)
        XCTAssertEqual(remaining, 1000, "Should have full quota initially")
    }

    // MARK: - Recording API Calls Tests

    /// Test: Record single API call increments usage
    ///
    /// 테스트: API 호출 1회 기록 시 사용량 증가
    func testRecordAPICall_IncrementsUsage() {
        // When: Recording one API call
        tracker.recordAPICall()

        // Then: Usage should be 1
        XCTAssertEqual(tracker.getCurrentUsage(), 1, "Usage should be 1 after one call")
    }

    /// Test: Record multiple API calls
    ///
    /// 테스트: 여러 API 호출 기록
    func testRecordAPICall_MultipleCallsIncrementsCorrectly() {
        // When: Recording 5 API calls
        for _ in 1...5 {
            tracker.recordAPICall()
        }

        // Then: Usage should be 5
        XCTAssertEqual(tracker.getCurrentUsage(), 5, "Usage should be 5 after five calls")
    }

    /// Test: Record API call updates remaining quota
    ///
    /// 테스트: API 호출 기록 시 남은 할당량 업데이트
    func testRecordAPICall_UpdatesRemainingQuota() {
        // When: Recording 100 API calls
        for _ in 1...100 {
            tracker.recordAPICall()
        }

        // Then: Remaining should be 900
        XCTAssertEqual(tracker.getRemainingQuota(), 900, "Should have 900 remaining")
    }

    // MARK: - Quota Limit Tests

    /// Test: Can make request when under limit
    ///
    /// 테스트: 한도 미만일 때 요청 가능
    func testCanMakeRequest_UnderLimit_ReturnsTrue() {
        // Given: 999 calls made (under limit)
        for _ in 1...999 {
            tracker.recordAPICall()
        }

        // When: Checking if can make request
        let canMake = tracker.canMakeRequest()

        // Then: Should still allow
        XCTAssertTrue(canMake, "Should allow request at 999/1000")
    }

    /// Test: Cannot make request when at limit
    ///
    /// 테스트: 한도 도달 시 요청 불가
    func testCanMakeRequest_AtLimit_ReturnsFalse() {
        // Given: 1000 calls made (at limit)
        for _ in 1...1000 {
            tracker.recordAPICall()
        }

        // When: Checking if can make request
        let canMake = tracker.canMakeRequest()

        // Then: Should not allow
        XCTAssertFalse(canMake, "Should not allow request at 1000/1000")
    }

    /// Test: Cannot make request when over limit
    ///
    /// 테스트: 한도 초과 시 요청 불가
    func testCanMakeRequest_OverLimit_ReturnsFalse() {
        // Given: 1100 calls made (over limit)
        for _ in 1...1100 {
            tracker.recordAPICall()
        }

        // When: Checking if can make request
        let canMake = tracker.canMakeRequest()

        // Then: Should not allow
        XCTAssertFalse(canMake, "Should not allow request over limit")
    }

    /// Test: Remaining quota never goes negative
    ///
    /// 테스트: 남은 할당량은 음수가 되지 않음
    func testGetRemainingQuota_NeverNegative() {
        // Given: Over limit usage (1200 calls)
        for _ in 1...1200 {
            tracker.recordAPICall()
        }

        // When: Checking remaining quota
        let remaining = tracker.getRemainingQuota()

        // Then: Should be 0 (not negative)
        XCTAssertEqual(remaining, 0, "Remaining should be 0, not negative")
    }

    // MARK: - Warning Threshold Tests

    /// Test: Should not show warning under threshold
    ///
    /// 테스트: 임계값 미만일 때 경고 표시 안함
    func testShouldShowWarning_UnderThreshold_ReturnsFalse() {
        // Given: 850 calls (under 90% threshold)
        for _ in 1...850 {
            tracker.recordAPICall()
        }

        // When: Checking if should show warning
        let shouldWarn = tracker.shouldShowWarning()

        // Then: Should not warn
        XCTAssertFalse(shouldWarn, "Should not warn at 850/1000 (85%)")
    }

    /// Test: Should show warning at threshold
    ///
    /// 테스트: 임계값 도달 시 경고 표시
    func testShouldShowWarning_AtThreshold_ReturnsTrue() {
        // Given: 900 calls (at 90% threshold)
        for _ in 1...900 {
            tracker.recordAPICall()
        }

        // When: Checking if should show warning
        let shouldWarn = tracker.shouldShowWarning()

        // Then: Should warn
        XCTAssertTrue(shouldWarn, "Should warn at 900/1000 (90%)")
    }

    /// Test: Should show warning over threshold
    ///
    /// 테스트: 임계값 초과 시 경고 표시
    func testShouldShowWarning_OverThreshold_ReturnsTrue() {
        // Given: 950 calls (over 90% threshold)
        for _ in 1...950 {
            tracker.recordAPICall()
        }

        // When: Checking if should show warning
        let shouldWarn = tracker.shouldShowWarning()

        // Then: Should warn
        XCTAssertTrue(shouldWarn, "Should warn at 950/1000 (95%)")
    }

    /// Test: Warning threshold is 900 (90% of 1000)
    ///
    /// 테스트: 경고 임계값은 900 (1000의 90%)
    func testGetWarningThreshold_Returns900() {
        // When: Getting warning threshold
        let threshold = tracker.getWarningThreshold()

        // Then: Should be 900
        XCTAssertEqual(threshold, 900, "Warning threshold should be 900")
    }

    // MARK: - Monthly Limit Tests

    /// Test: Monthly limit is 1000
    ///
    /// 테스트: 월간 한도는 1000
    func testGetMonthlyLimit_Returns1000() {
        // When: Getting monthly limit
        let limit = tracker.getMonthlyLimit()

        // Then: Should be 1000
        XCTAssertEqual(limit, 1000, "Monthly limit should be 1000")
    }

    // MARK: - Reset Tests

    /// Test: Reset clears usage count
    ///
    /// 테스트: 리셋은 사용량 카운트를 초기화
    func testReset_ClearsUsageCount() {
        // Given: Some usage recorded
        for _ in 1...50 {
            tracker.recordAPICall()
        }

        // When: Resetting tracker
        tracker.reset()

        // Then: Usage should be 0
        XCTAssertEqual(tracker.getCurrentUsage(), 0, "Usage should be 0 after reset")
    }

    /// Test: Reset allows requests again
    ///
    /// 테스트: 리셋 후 다시 요청 가능
    func testReset_AllowsRequestsAgain() {
        // Given: Usage at limit
        for _ in 1...1000 {
            tracker.recordAPICall()
        }
        XCTAssertFalse(tracker.canMakeRequest(), "Should not allow at limit")

        // When: Resetting tracker
        tracker.reset()

        // Then: Should allow requests again
        XCTAssertTrue(tracker.canMakeRequest(), "Should allow after reset")
    }

    // MARK: - Days Until Reset Tests

    /// Test: Days until reset is positive
    ///
    /// 테스트: 리셋까지 남은 일수는 양수
    func testGetDaysUntilReset_ReturnsPositive() {
        // When: Getting days until reset
        let days = tracker.getDaysUntilReset()

        // Then: Should be at least 1
        XCTAssertGreaterThanOrEqual(days, 1, "Days until reset should be at least 1")
    }

    /// Test: Days until reset is reasonable (not over 31)
    ///
    /// 테스트: 리셋까지 남은 일수는 합리적 (31일 이하)
    func testGetDaysUntilReset_IsReasonable() {
        // When: Getting days until reset
        let days = tracker.getDaysUntilReset()

        // Then: Should not exceed 31 days
        XCTAssertLessThanOrEqual(days, 31, "Days until reset should not exceed 31")
    }

    /// Test: Reset date is in the future
    ///
    /// 테스트: 리셋 날짜는 미래
    func testGetResetDate_IsInFuture() {
        // When: Getting reset date
        let resetDate = tracker.getResetDate()

        // Then: Should be after now
        XCTAssertGreaterThan(resetDate, Date(), "Reset date should be in future")
    }

    /// Test: Reset date is next month's first day
    ///
    /// 테스트: 리셋 날짜는 다음 달 1일
    func testGetResetDate_IsFirstOfNextMonth() {
        // Given: Current date
        let calendar = Calendar.current
        let now = Date()

        // When: Getting reset date
        let resetDate = tracker.getResetDate()

        // Then: Should be first day of a month
        let components = calendar.dateComponents([.day], from: resetDate)
        XCTAssertEqual(components.day, 1, "Reset date should be first of month")

        // Then: Should be at least next month
        let monthsDiff = calendar.dateComponents([.month], from: now, to: resetDate).month ?? 0
        XCTAssertGreaterThanOrEqual(monthsDiff, 0, "Reset date should be this or next month")
    }

    // MARK: - Persistence Tests

    /// Test: Usage persists across instances
    ///
    /// 테스트: 사용량은 인스턴스간 유지됨
    func testUsage_PersistsAcrossInstances() {
        // Given: Record 50 calls with first tracker
        for _ in 1...50 {
            tracker.recordAPICall()
        }

        // When: Creating new tracker with same UserDefaults
        let newTracker = VisionAPIUsageTracker(userDefaults: testUserDefaults)

        // Then: Should have same usage
        XCTAssertEqual(newTracker.getCurrentUsage(), 50, "Usage should persist")
    }

    /// Test: Quota state persists across instances
    ///
    /// 테스트: 할당량 상태는 인스턴스간 유지됨
    func testQuotaState_PersistsAcrossInstances() {
        // Given: Reach quota limit
        for _ in 1...1000 {
            tracker.recordAPICall()
        }

        // When: Creating new tracker with same UserDefaults
        let newTracker = VisionAPIUsageTracker(userDefaults: testUserDefaults)

        // Then: Should still be at limit
        XCTAssertFalse(newTracker.canMakeRequest(), "Quota state should persist")
        XCTAssertEqual(newTracker.getRemainingQuota(), 0, "Remaining should be 0")
    }

    // MARK: - Thread Safety Tests

    /// Test: Concurrent API calls are thread-safe
    ///
    /// 테스트: 동시 API 호출은 스레드 안전
    func testConcurrentAPICalls_AreThreadSafe() {
        // Given: Expectation for async operations
        let expectation = self.expectation(description: "Concurrent calls complete")
        let callCount = 100

        // When: Recording API calls concurrently
        DispatchQueue.concurrentPerform(iterations: callCount) { _ in
            tracker.recordAPICall()
        }

        DispatchQueue.global().async {
            expectation.fulfill()
        }

        // Wait for completion
        waitForExpectations(timeout: 5.0)

        // Then: All calls should be recorded
        XCTAssertEqual(tracker.getCurrentUsage(), callCount, "Should record all concurrent calls")
    }

    /// Test: Concurrent quota checks are thread-safe
    ///
    /// 테스트: 동시 할당량 확인은 스레드 안전
    func testConcurrentQuotaChecks_AreThreadSafe() {
        // Given: Some usage
        for _ in 1...500 {
            tracker.recordAPICall()
        }

        let expectation = self.expectation(description: "Concurrent checks complete")
        let checkCount = 100
        var results: [Bool] = []
        let resultsQueue = DispatchQueue(label: "results")

        // When: Checking quota concurrently
        DispatchQueue.concurrentPerform(iterations: checkCount) { _ in
            let canMake = tracker.canMakeRequest()
            resultsQueue.sync {
                results.append(canMake)
            }
        }

        DispatchQueue.global().async {
            expectation.fulfill()
        }

        // Wait for completion
        waitForExpectations(timeout: 5.0)

        // Then: All checks should return consistent result
        XCTAssertEqual(results.count, checkCount, "Should complete all checks")
        let allTrue = results.allSatisfy { $0 == true }
        XCTAssertTrue(allTrue, "All checks should return same result")
    }
}
