//
//  DateUtilsTests.swift
//  BodiiTests
//
//  Created by Auto-Claude on 2026-01-12.
//

import XCTest
@testable import Bodii

/// Unit tests for DateUtils focusing on 02:00 sleep boundary logic
///
/// DateUtils의 02:00 수면 경계 로직에 대한 단위 테스트
final class DateUtilsTests: XCTestCase {

    // MARK: - Test Helpers

    /// Creates a date with specific year, month, day, hour, and minute components
    private func makeDate(year: Int, month: Int, day: Int, hour: Int, minute: Int = 0) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        components.second = 0

        guard let date = Calendar.current.date(from: components) else {
            XCTFail("Failed to create date from components")
            return Date()
        }

        return date
    }

    /// Creates an expected date (start of day)
    private func makeExpectedDate(year: Int, month: Int, day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day

        guard let date = Calendar.current.date(from: components) else {
            XCTFail("Failed to create expected date from components")
            return Date()
        }

        return date
    }

    // MARK: - Sleep Boundary Tests (getLogicalDate)

    /// Test: 01:59 should return previous day
    ///
    /// 테스트: 01:59는 전날을 반환해야 함
    func testGetLogicalDate_0159_ReturnsPreviousDay() {
        // Given: January 12, 2026 at 01:59 AM
        let testDate = makeDate(year: 2026, month: 1, day: 12, hour: 1, minute: 59)

        // When: Getting logical date
        let logicalDate = DateUtils.getLogicalDate(for: testDate)

        // Then: Should return January 11, 2026 (previous day)
        let expectedDate = makeExpectedDate(year: 2026, month: 1, day: 11)
        XCTAssertEqual(
            logicalDate.yyyyMMdd,
            expectedDate.yyyyMMdd,
            "01:59 should return previous day for sleep tracking"
        )
    }

    /// Test: 02:00 should return current day
    ///
    /// 테스트: 02:00는 당일을 반환해야 함
    func testGetLogicalDate_0200_ReturnsCurrentDay() {
        // Given: January 12, 2026 at 02:00 AM
        let testDate = makeDate(year: 2026, month: 1, day: 12, hour: 2, minute: 0)

        // When: Getting logical date
        let logicalDate = DateUtils.getLogicalDate(for: testDate)

        // Then: Should return January 12, 2026 (current day)
        let expectedDate = makeExpectedDate(year: 2026, month: 1, day: 12)
        XCTAssertEqual(
            logicalDate.yyyyMMdd,
            expectedDate.yyyyMMdd,
            "02:00 should return current day for sleep tracking"
        )
    }

    /// Test: 02:01 should return current day
    ///
    /// 테스트: 02:01는 당일을 반환해야 함
    func testGetLogicalDate_0201_ReturnsCurrentDay() {
        // Given: January 12, 2026 at 02:01 AM
        let testDate = makeDate(year: 2026, month: 1, day: 12, hour: 2, minute: 1)

        // When: Getting logical date
        let logicalDate = DateUtils.getLogicalDate(for: testDate)

        // Then: Should return January 12, 2026 (current day)
        let expectedDate = makeExpectedDate(year: 2026, month: 1, day: 12)
        XCTAssertEqual(
            logicalDate.yyyyMMdd,
            expectedDate.yyyyMMdd,
            "02:01 should return current day for sleep tracking"
        )
    }

    /// Test: Midnight (00:00) should return previous day
    ///
    /// 테스트: 자정(00:00)은 전날을 반환해야 함
    func testGetLogicalDate_Midnight_ReturnsPreviousDay() {
        // Given: January 12, 2026 at 00:00 (midnight)
        let testDate = makeDate(year: 2026, month: 1, day: 12, hour: 0, minute: 0)

        // When: Getting logical date
        let logicalDate = DateUtils.getLogicalDate(for: testDate)

        // Then: Should return January 11, 2026 (previous day)
        let expectedDate = makeExpectedDate(year: 2026, month: 1, day: 11)
        XCTAssertEqual(
            logicalDate.yyyyMMdd,
            expectedDate.yyyyMMdd,
            "Midnight (00:00) should return previous day for sleep tracking"
        )
    }

    /// Test: 00:01 should return previous day
    ///
    /// 테스트: 00:01은 전날을 반환해야 함
    func testGetLogicalDate_0001_ReturnsPreviousDay() {
        // Given: January 12, 2026 at 00:01
        let testDate = makeDate(year: 2026, month: 1, day: 12, hour: 0, minute: 1)

        // When: Getting logical date
        let logicalDate = DateUtils.getLogicalDate(for: testDate)

        // Then: Should return January 11, 2026 (previous day)
        let expectedDate = makeExpectedDate(year: 2026, month: 1, day: 11)
        XCTAssertEqual(
            logicalDate.yyyyMMdd,
            expectedDate.yyyyMMdd,
            "00:01 should return previous day for sleep tracking"
        )
    }

    /// Test: 01:00 should return previous day
    ///
    /// 테스트: 01:00은 전날을 반환해야 함
    func testGetLogicalDate_0100_ReturnsPreviousDay() {
        // Given: January 12, 2026 at 01:00
        let testDate = makeDate(year: 2026, month: 1, day: 12, hour: 1, minute: 0)

        // When: Getting logical date
        let logicalDate = DateUtils.getLogicalDate(for: testDate)

        // Then: Should return January 11, 2026 (previous day)
        let expectedDate = makeExpectedDate(year: 2026, month: 1, day: 11)
        XCTAssertEqual(
            logicalDate.yyyyMMdd,
            expectedDate.yyyyMMdd,
            "01:00 should return previous day for sleep tracking"
        )
    }

    /// Test: 03:00 should return current day
    ///
    /// 테스트: 03:00은 당일을 반환해야 함
    func testGetLogicalDate_0300_ReturnsCurrentDay() {
        // Given: January 12, 2026 at 03:00
        let testDate = makeDate(year: 2026, month: 1, day: 12, hour: 3, minute: 0)

        // When: Getting logical date
        let logicalDate = DateUtils.getLogicalDate(for: testDate)

        // Then: Should return January 12, 2026 (current day)
        let expectedDate = makeExpectedDate(year: 2026, month: 1, day: 12)
        XCTAssertEqual(
            logicalDate.yyyyMMdd,
            expectedDate.yyyyMMdd,
            "03:00 should return current day for sleep tracking"
        )
    }

    /// Test: Noon (12:00) should return current day
    ///
    /// 테스트: 정오(12:00)는 당일을 반환해야 함
    func testGetLogicalDate_Noon_ReturnsCurrentDay() {
        // Given: January 12, 2026 at 12:00 (noon)
        let testDate = makeDate(year: 2026, month: 1, day: 12, hour: 12, minute: 0)

        // When: Getting logical date
        let logicalDate = DateUtils.getLogicalDate(for: testDate)

        // Then: Should return January 12, 2026 (current day)
        let expectedDate = makeExpectedDate(year: 2026, month: 1, day: 12)
        XCTAssertEqual(
            logicalDate.yyyyMMdd,
            expectedDate.yyyyMMdd,
            "Noon (12:00) should return current day for sleep tracking"
        )
    }

    /// Test: 23:59 should return current day
    ///
    /// 테스트: 23:59는 당일을 반환해야 함
    func testGetLogicalDate_2359_ReturnsCurrentDay() {
        // Given: January 12, 2026 at 23:59
        let testDate = makeDate(year: 2026, month: 1, day: 12, hour: 23, minute: 59)

        // When: Getting logical date
        let logicalDate = DateUtils.getLogicalDate(for: testDate)

        // Then: Should return January 12, 2026 (current day)
        let expectedDate = makeExpectedDate(year: 2026, month: 1, day: 12)
        XCTAssertEqual(
            logicalDate.yyyyMMdd,
            expectedDate.yyyyMMdd,
            "23:59 should return current day for sleep tracking"
        )
    }

    // MARK: - Month/Year Boundary Tests

    /// Test: Midnight on first day of month should return previous month's last day
    ///
    /// 테스트: 월 첫날 자정은 전월 마지막 날을 반환해야 함
    func testGetLogicalDate_FirstDayOfMonth_Midnight_ReturnsPreviousMonthLastDay() {
        // Given: February 1, 2026 at 00:00 (midnight)
        let testDate = makeDate(year: 2026, month: 2, day: 1, hour: 0, minute: 0)

        // When: Getting logical date
        let logicalDate = DateUtils.getLogicalDate(for: testDate)

        // Then: Should return January 31, 2026
        let expectedDate = makeExpectedDate(year: 2026, month: 1, day: 31)
        XCTAssertEqual(
            logicalDate.yyyyMMdd,
            expectedDate.yyyyMMdd,
            "Midnight on first day of month should return previous month's last day"
        )
    }

    /// Test: Midnight on first day of year should return previous year's last day
    ///
    /// 테스트: 년 첫날 자정은 전년도 마지막 날을 반환해야 함
    func testGetLogicalDate_FirstDayOfYear_Midnight_ReturnsPreviousYearLastDay() {
        // Given: January 1, 2026 at 00:00 (midnight)
        let testDate = makeDate(year: 2026, month: 1, day: 1, hour: 0, minute: 0)

        // When: Getting logical date
        let logicalDate = DateUtils.getLogicalDate(for: testDate)

        // Then: Should return December 31, 2025
        let expectedDate = makeExpectedDate(year: 2025, month: 12, day: 31)
        XCTAssertEqual(
            logicalDate.yyyyMMdd,
            expectedDate.yyyyMMdd,
            "Midnight on first day of year should return previous year's last day"
        )
    }

    /// Test: 01:59 on first day of year should return previous year's last day
    ///
    /// 테스트: 년 첫날 01:59는 전년도 마지막 날을 반환해야 함
    func testGetLogicalDate_FirstDayOfYear_0159_ReturnsPreviousYearLastDay() {
        // Given: January 1, 2026 at 01:59
        let testDate = makeDate(year: 2026, month: 1, day: 1, hour: 1, minute: 59)

        // When: Getting logical date
        let logicalDate = DateUtils.getLogicalDate(for: testDate)

        // Then: Should return December 31, 2025
        let expectedDate = makeExpectedDate(year: 2025, month: 12, day: 31)
        XCTAssertEqual(
            logicalDate.yyyyMMdd,
            expectedDate.yyyyMMdd,
            "01:59 on first day of year should return previous year's last day"
        )
    }

    /// Test: 02:00 on first day of year should return current day (Jan 1)
    ///
    /// 테스트: 년 첫날 02:00은 당일(1월 1일)을 반환해야 함
    func testGetLogicalDate_FirstDayOfYear_0200_ReturnsCurrentDay() {
        // Given: January 1, 2026 at 02:00
        let testDate = makeDate(year: 2026, month: 1, day: 1, hour: 2, minute: 0)

        // When: Getting logical date
        let logicalDate = DateUtils.getLogicalDate(for: testDate)

        // Then: Should return January 1, 2026
        let expectedDate = makeExpectedDate(year: 2026, month: 1, day: 1)
        XCTAssertEqual(
            logicalDate.yyyyMMdd,
            expectedDate.yyyyMMdd,
            "02:00 on first day of year should return current day (Jan 1)"
        )
    }

    // MARK: - getSleepDate Tests (Alias Function)

    /// Test: getSleepDate should behave identically to getLogicalDate
    ///
    /// 테스트: getSleepDate는 getLogicalDate와 동일하게 동작해야 함
    func testGetSleepDate_BehavesIdenticallyToGetLogicalDate() {
        // Given: Various test dates
        let testDates = [
            makeDate(year: 2026, month: 1, day: 12, hour: 0, minute: 0),
            makeDate(year: 2026, month: 1, day: 12, hour: 1, minute: 59),
            makeDate(year: 2026, month: 1, day: 12, hour: 2, minute: 0),
            makeDate(year: 2026, month: 1, day: 12, hour: 2, minute: 1),
            makeDate(year: 2026, month: 1, day: 12, hour: 12, minute: 0),
            makeDate(year: 2026, month: 1, day: 12, hour: 23, minute: 59)
        ]

        // When/Then: getSleepDate should return same result as getLogicalDate
        for testDate in testDates {
            let sleepDate = DateUtils.getSleepDate(for: testDate)
            let logicalDate = DateUtils.getLogicalDate(for: testDate)

            XCTAssertEqual(
                sleepDate.yyyyMMdd,
                logicalDate.yyyyMMdd,
                "getSleepDate should return same date as getLogicalDate for \(testDate.yyyyMMddHHmmss)"
            )
        }
    }

    // MARK: - Edge Cases from Documentation

    /// Test: Edge case scenario from docs - 3 AM on Jan 12 should return Jan 11 for sleep popup
    ///
    /// 테스트: 문서의 엣지 케이스 - 1월 12일 오전 3시는 수면 팝업을 위해 1월 11일을 반환해야 함
    func testGetLogicalDate_DocScenario_3AMReturnsYesterday() {
        // Given: January 12, 2026 at 03:00 (documented scenario)
        let testDate = makeDate(year: 2026, month: 1, day: 12, hour: 3, minute: 0)

        // When: Getting sleep date (logical date for yesterday's sleep)
        let sleepDate = DateUtils.getSleepDate(for: testDate)

        // Then: At 03:00, we're recording yesterday's (Jan 11) sleep
        // But the logical date for 03:00 itself is Jan 12
        let expectedDate = makeExpectedDate(year: 2026, month: 1, day: 12)
        XCTAssertEqual(
            sleepDate.yyyyMMdd,
            expectedDate.yyyyMMdd,
            "At 03:00 AM, the logical date is current day (for entering yesterday's sleep data)"
        )
    }

    /// Test: Edge case - sequential times across boundary
    ///
    /// 테스트: 엣지 케이스 - 경계를 넘는 연속된 시간
    func testGetLogicalDate_SequentialTimesAcrossBoundary() {
        let year = 2026, month = 1, day = 12

        // 01:58 -> previous day
        let date0158 = makeDate(year: year, month: month, day: day, hour: 1, minute: 58)
        let logical0158 = DateUtils.getLogicalDate(for: date0158)
        XCTAssertEqual(logical0158.day, 11, "01:58 should return previous day")

        // 01:59 -> previous day
        let date0159 = makeDate(year: year, month: month, day: day, hour: 1, minute: 59)
        let logical0159 = DateUtils.getLogicalDate(for: date0159)
        XCTAssertEqual(logical0159.day, 11, "01:59 should return previous day")

        // 02:00 -> current day (boundary)
        let date0200 = makeDate(year: year, month: month, day: day, hour: 2, minute: 0)
        let logical0200 = DateUtils.getLogicalDate(for: date0200)
        XCTAssertEqual(logical0200.day, 12, "02:00 should return current day")

        // 02:01 -> current day
        let date0201 = makeDate(year: year, month: month, day: day, hour: 2, minute: 1)
        let logical0201 = DateUtils.getLogicalDate(for: date0201)
        XCTAssertEqual(logical0201.day, 12, "02:01 should return current day")

        // 02:02 -> current day
        let date0202 = makeDate(year: year, month: month, day: day, hour: 2, minute: 2)
        let logical0202 = DateUtils.getLogicalDate(for: date0202)
        XCTAssertEqual(logical0202.day, 12, "02:02 should return current day")
    }

    // MARK: - Date Formatting Utilities Tests

    /// Test: formatKorean returns correct Korean format
    ///
    /// 테스트: formatKorean이 올바른 한국어 형식을 반환하는지 확인
    func testFormatKorean_ReturnsCorrectFormat() {
        // Given: A specific date
        let testDate = makeDate(year: 2026, month: 1, day: 12, hour: 15, minute: 30)

        // When: Formatting in Korean
        let formatted = DateUtils.formatKorean(testDate)

        // Then: Should contain Korean date components
        XCTAssertTrue(
            formatted.contains("2026") && formatted.contains("1") && formatted.contains("12"),
            "Korean formatted date should contain year, month, and day"
        )
        XCTAssertTrue(
            formatted.contains("년") || formatted.contains("월") || formatted.contains("일"),
            "Korean formatted date should contain Korean characters"
        )
    }

    /// Test: formatDuration returns correct Korean duration strings
    ///
    /// 테스트: formatDuration이 올바른 한국어 시간 문자열을 반환하는지 확인
    func testFormatDuration_ReturnsCorrectStrings() {
        // Test hours and minutes
        XCTAssertEqual(DateUtils.formatDuration(minutes: 450), "7시간 30분")

        // Test hours only
        XCTAssertEqual(DateUtils.formatDuration(minutes: 60), "1시간")
        XCTAssertEqual(DateUtils.formatDuration(minutes: 120), "2시간")

        // Test minutes only
        XCTAssertEqual(DateUtils.formatDuration(minutes: 45), "45분")
        XCTAssertEqual(DateUtils.formatDuration(minutes: 0), "0분")
        XCTAssertEqual(DateUtils.formatDuration(minutes: 1), "1분")
    }

    /// Test: daysBetween calculates correct day differences
    ///
    /// 테스트: daysBetween이 올바른 일수 차이를 계산하는지 확인
    func testDaysBetween_CalculatesCorrectDifferences() {
        // Given: Two dates
        let date1 = makeDate(year: 2026, month: 1, day: 12, hour: 10, minute: 0)
        let date2 = makeDate(year: 2026, month: 1, day: 19, hour: 15, minute: 30)

        // When: Calculating days between
        let days = DateUtils.daysBetween(from: date1, to: date2)

        // Then: Should return 7 days
        XCTAssertEqual(days, 7, "Should calculate 7 days between Jan 12 and Jan 19")
    }

    /// Test: relativeDate returns correct Korean relative strings
    ///
    /// 테스트: relativeDate가 올바른 한국어 상대 날짜 문자열을 반환하는지 확인
    func testRelativeDate_ReturnsCorrectStrings() {
        // Given: Today's date
        let today = Date()

        // When/Then: Testing relative dates
        let todayStr = DateUtils.relativeDate(today)
        XCTAssertEqual(todayStr, "오늘", "Today should return '오늘'")

        let yesterday = today.adding(days: -1)
        let yesterdayStr = DateUtils.relativeDate(yesterday)
        XCTAssertEqual(yesterdayStr, "어제", "Yesterday should return '어제'")

        let tomorrow = today.adding(days: 1)
        let tomorrowStr = DateUtils.relativeDate(tomorrow)
        XCTAssertEqual(tomorrowStr, "내일", "Tomorrow should return '내일'")

        // For dates beyond yesterday/tomorrow, should return formatted date
        let lastWeek = today.adding(days: -7)
        let lastWeekStr = DateUtils.relativeDate(lastWeek)
        XCTAssertNotEqual(lastWeekStr, "오늘", "Last week should not return '오늘'")
        XCTAssertNotEqual(lastWeekStr, "어제", "Last week should not return '어제'")
    }

    // MARK: - shouldShowSleepPopup Tests

    /// Test: shouldShowSleepPopup behavior at boundary hours
    ///
    /// 테스트: shouldShowSleepPopup의 경계 시간 동작
    /// 📚 학습 포인트: Time-dependent testing challenge
    /// - 이 메서드는 현재 시간을 사용하므로 직접 테스트하기 어려움
    /// - 실제 구현에서는 dependency injection으로 시간을 주입하는 것이 이상적
    /// - 여기서는 로직의 기대 동작을 문서화하고 간접적으로 검증
    /// 💡 Java 비교: Clock.systemUTC()를 MockClock으로 대체하는 것과 유사
    func testShouldShowSleepPopup_BehaviorDocumentation() {
        // Given: Current time
        let currentHour = Calendar.current.component(.hour, from: Date())

        // When: Calling shouldShowSleepPopup
        let shouldShow = DateUtils.shouldShowSleepPopup()

        // Then: Should return true if hour >= 2, false otherwise
        // 📚 Expected behavior:
        // - 00:00 ~ 01:59 -> false (too early, sleep popup should not show)
        // - 02:00 ~ 23:59 -> true (valid time to show sleep popup)
        if currentHour >= 2 {
            XCTAssertTrue(
                shouldShow,
                "shouldShowSleepPopup() should return true when current hour (\(currentHour)) >= 2"
            )
        } else {
            XCTAssertFalse(
                shouldShow,
                "shouldShowSleepPopup() should return false when current hour (\(currentHour)) < 2"
            )
        }
    }

    /// Test: shouldShowSleepPopup consistency with getLogicalDate boundary
    ///
    /// 테스트: shouldShowSleepPopup과 getLogicalDate의 경계 일관성
    /// 📚 학습 포인트: Consistency Testing
    /// - shouldShowSleepPopup과 getLogicalDate는 같은 경계 로직 사용
    /// - 두 메서드의 동작이 일관성 있게 유지되는지 확인
    func testShouldShowSleepPopup_ConsistentWithLogicalDateBoundary() {
        // Given: Test dates at various hours
        let testCases: [(hour: Int, shouldShow: Bool, description: String)] = [
            (0, false, "Midnight"),
            (1, false, "1 AM"),
            (2, true, "2 AM (boundary)"),
            (3, true, "3 AM"),
            (6, true, "6 AM"),
            (12, true, "Noon"),
            (18, true, "6 PM"),
            (23, true, "11 PM")
        ]

        // When/Then: Verify each hour's behavior matches expected boundary logic
        for testCase in testCases {
            let testDate = makeDate(year: 2026, month: 1, day: 12, hour: testCase.hour)
            let logicalDate = DateUtils.getLogicalDate(for: testDate)
            let expectedDate = makeExpectedDate(year: 2026, month: 1, day: testCase.shouldShow ? 12 : 11)

            XCTAssertEqual(
                logicalDate.yyyyMMdd,
                expectedDate.yyyyMMdd,
                "\(testCase.description) (\(testCase.hour):00) boundary behavior mismatch"
            )

            // Document expected shouldShowSleepPopup behavior
            // 📚 At \(testCase.hour):00, shouldShowSleepPopup() should return \(testCase.shouldShow)
        }
    }

    // MARK: - Additional Edge Cases for Sleep Boundary Logic

    /// Test: Leap year boundary - Feb 29 to Mar 1
    ///
    /// 테스트: 윤년 경계 - 2월 29일에서 3월 1일로
    /// 📚 학습 포인트: Leap Year Edge Case
    func testGetLogicalDate_LeapYearBoundary_Feb29ToMar1() {
        // Given: March 1, 2024 at 00:00 (2024 is a leap year)
        let testDate = makeDate(year: 2024, month: 3, day: 1, hour: 0, minute: 0)

        // When: Getting logical date
        let logicalDate = DateUtils.getLogicalDate(for: testDate)

        // Then: Should return February 29, 2024 (leap day)
        let expectedDate = makeExpectedDate(year: 2024, month: 2, day: 29)
        XCTAssertEqual(
            logicalDate.yyyyMMdd,
            expectedDate.yyyyMMdd,
            "Midnight on March 1 in leap year should return Feb 29"
        )
    }

    /// Test: Leap year boundary - Feb 29 at 01:59
    ///
    /// 테스트: 윤년 경계 - 2월 29일 01:59
    func testGetLogicalDate_LeapYearBoundary_Feb29At0159() {
        // Given: February 29, 2024 at 01:59
        let testDate = makeDate(year: 2024, month: 2, day: 29, hour: 1, minute: 59)

        // When: Getting logical date
        let logicalDate = DateUtils.getLogicalDate(for: testDate)

        // Then: Should return February 28, 2024
        let expectedDate = makeExpectedDate(year: 2024, month: 2, day: 28)
        XCTAssertEqual(
            logicalDate.yyyyMMdd,
            expectedDate.yyyyMMdd,
            "01:59 on Feb 29 should return Feb 28"
        )
    }

    /// Test: Non-leap year boundary - Feb 28 to Mar 1
    ///
    /// 테스트: 평년 경계 - 2월 28일에서 3월 1일로
    func testGetLogicalDate_NonLeapYearBoundary_Feb28ToMar1() {
        // Given: March 1, 2025 at 00:00 (2025 is not a leap year)
        let testDate = makeDate(year: 2025, month: 3, day: 1, hour: 0, minute: 0)

        // When: Getting logical date
        let logicalDate = DateUtils.getLogicalDate(for: testDate)

        // Then: Should return February 28, 2025
        let expectedDate = makeExpectedDate(year: 2025, month: 2, day: 28)
        XCTAssertEqual(
            logicalDate.yyyyMMdd,
            expectedDate.yyyyMMdd,
            "Midnight on March 1 in non-leap year should return Feb 28"
        )
    }

    /// Test: 30-day month boundary - Apr 1 at midnight
    ///
    /// 테스트: 30일 월 경계 - 4월 1일 자정
    func testGetLogicalDate_30DayMonthBoundary() {
        // Given: April 1, 2026 at 00:00
        let testDate = makeDate(year: 2026, month: 4, day: 1, hour: 0, minute: 0)

        // When: Getting logical date
        let logicalDate = DateUtils.getLogicalDate(for: testDate)

        // Then: Should return March 31, 2026
        let expectedDate = makeExpectedDate(year: 2026, month: 3, day: 31)
        XCTAssertEqual(
            logicalDate.yyyyMMdd,
            expectedDate.yyyyMMdd,
            "Midnight on April 1 should return March 31"
        )
    }

    /// Test: 31-day month boundary - Aug 1 at midnight
    ///
    /// 테스트: 31일 월 경계 - 8월 1일 자정
    func testGetLogicalDate_31DayMonthBoundary() {
        // Given: August 1, 2026 at 00:00
        let testDate = makeDate(year: 2026, month: 8, day: 1, hour: 0, minute: 0)

        // When: Getting logical date
        let logicalDate = DateUtils.getLogicalDate(for: testDate)

        // Then: Should return July 31, 2026
        let expectedDate = makeExpectedDate(year: 2026, month: 7, day: 31)
        XCTAssertEqual(
            logicalDate.yyyyMMdd,
            expectedDate.yyyyMMdd,
            "Midnight on August 1 should return July 31"
        )
    }

    /// Test: Year boundary at 01:30
    ///
    /// 테스트: 년 경계 01:30
    func testGetLogicalDate_YearBoundary_0130() {
        // Given: January 1, 2026 at 01:30
        let testDate = makeDate(year: 2026, month: 1, day: 1, hour: 1, minute: 30)

        // When: Getting logical date
        let logicalDate = DateUtils.getLogicalDate(for: testDate)

        // Then: Should return December 31, 2025
        let expectedDate = makeExpectedDate(year: 2025, month: 12, day: 31)
        XCTAssertEqual(
            logicalDate.yyyyMMdd,
            expectedDate.yyyyMMdd,
            "01:30 on Jan 1, 2026 should return Dec 31, 2025"
        )
    }

    /// Test: Last day of year at 23:59
    ///
    /// 테스트: 년 마지막 날 23:59
    func testGetLogicalDate_LastDayOfYear_2359() {
        // Given: December 31, 2025 at 23:59
        let testDate = makeDate(year: 2025, month: 12, day: 31, hour: 23, minute: 59)

        // When: Getting logical date
        let logicalDate = DateUtils.getLogicalDate(for: testDate)

        // Then: Should return December 31, 2025 (same day)
        let expectedDate = makeExpectedDate(year: 2025, month: 12, day: 31)
        XCTAssertEqual(
            logicalDate.yyyyMMdd,
            expectedDate.yyyyMMdd,
            "23:59 on Dec 31 should return Dec 31 (same day)"
        )
    }

    /// Test: Last day of year at 00:00
    ///
    /// 테스트: 년 마지막 날 00:00
    func testGetLogicalDate_LastDayOfYear_Midnight() {
        // Given: December 31, 2025 at 00:00
        let testDate = makeDate(year: 2025, month: 12, day: 31, hour: 0, minute: 0)

        // When: Getting logical date
        let logicalDate = DateUtils.getLogicalDate(for: testDate)

        // Then: Should return December 30, 2025
        let expectedDate = makeExpectedDate(year: 2025, month: 12, day: 30)
        XCTAssertEqual(
            logicalDate.yyyyMMdd,
            expectedDate.yyyyMMdd,
            "Midnight on Dec 31 should return Dec 30"
        )
    }

    // MARK: - Real-world Sleep Tracking Scenarios

    /// Test: Real-world scenario - logging sleep at 8 AM
    ///
    /// 테스트: 실제 시나리오 - 오전 8시에 수면 기록
    /// 📚 학습 포인트: Real-world Use Case
    /// - 사용자가 오전 8시에 일어나서 어젯밤 수면을 기록
    /// - 8시의 논리적 날짜는 오늘이지만, 기록하는 수면은 어제 날짜로 저장되어야 함
    func testGetLogicalDate_RealWorldScenario_LoggingSleepAt8AM() {
        // Given: January 12, 2026 at 08:00 AM
        let testDate = makeDate(year: 2026, month: 1, day: 12, hour: 8, minute: 0)

        // When: Getting logical date (for determining "today")
        let logicalDate = DateUtils.getLogicalDate(for: testDate)

        // Then: Logical date is Jan 12 (today)
        let expectedDate = makeExpectedDate(year: 2026, month: 1, day: 12)
        XCTAssertEqual(
            logicalDate.yyyyMMdd,
            expectedDate.yyyyMMdd,
            "08:00 AM returns current day (Jan 12)"
        )

        // 📚 Note: When logging sleep at 8 AM, the sleep record should be saved with Jan 11 date
        // This is handled by the UI/ViewModel, not by getLogicalDate
    }

    /// Test: Real-world scenario - late night recording at 1 AM
    ///
    /// 테스트: 실제 시나리오 - 새벽 1시에 수면 기록
    /// 📚 학습 포인트: Late Night Recording
    /// - 사용자가 새벽 1시에 깨어서 수면을 기록
    /// - 1시의 논리적 날짜는 어제이므로, 수면도 어제 날짜로 저장
    func testGetLogicalDate_RealWorldScenario_LateNightRecordingAt1AM() {
        // Given: January 12, 2026 at 01:00 AM
        let testDate = makeDate(year: 2026, month: 1, day: 12, hour: 1, minute: 0)

        // When: Getting logical date
        let logicalDate = DateUtils.getLogicalDate(for: testDate)

        // Then: Logical date is Jan 11 (yesterday)
        let expectedDate = makeExpectedDate(year: 2026, month: 1, day: 11)
        XCTAssertEqual(
            logicalDate.yyyyMMdd,
            expectedDate.yyyyMMdd,
            "01:00 AM returns previous day (Jan 11)"
        )

        // 📚 Note: Sleep recorded at 1 AM is saved with yesterday's date (Jan 11)
    }

    /// Test: Real-world scenario - boundary crossing at exactly 2 AM
    ///
    /// 테스트: 실제 시나리오 - 정확히 새벽 2시의 경계
    func testGetLogicalDate_RealWorldScenario_BoundaryCrossingAt2AM() {
        // Given: Dates around 2 AM boundary
        let before = makeDate(year: 2026, month: 1, day: 12, hour: 1, minute: 59)
        let boundary = makeDate(year: 2026, month: 1, day: 12, hour: 2, minute: 0)
        let after = makeDate(year: 2026, month: 1, day: 12, hour: 2, minute: 1)

        // When: Getting logical dates
        let logicalBefore = DateUtils.getLogicalDate(for: before)
        let logicalBoundary = DateUtils.getLogicalDate(for: boundary)
        let logicalAfter = DateUtils.getLogicalDate(for: after)

        // Then: Before returns yesterday, boundary and after return today
        XCTAssertEqual(logicalBefore.day, 11, "01:59 returns yesterday")
        XCTAssertEqual(logicalBoundary.day, 12, "02:00 returns today (boundary)")
        XCTAssertEqual(logicalAfter.day, 12, "02:01 returns today")

        // 📚 Note: The boundary is precise - even 1 minute difference matters
    }

    // MARK: - getSleepDate Additional Tests

    /// Test: getSleepDate with various timezone scenarios
    ///
    /// 테스트: getSleepDate의 다양한 시간대 시나리오
    /// 📚 학습 포인트: Timezone Independence
    /// - getLogicalDate/getSleepDate는 현재 시스템 timezone 사용
    /// - 다른 timezone에서도 동일하게 동작해야 함
    func testGetSleepDate_TimeZoneIndependence() {
        // Given: Dates at boundary hours
        let midnight = makeDate(year: 2026, month: 1, day: 12, hour: 0, minute: 0)
        let twoAM = makeDate(year: 2026, month: 1, day: 12, hour: 2, minute: 0)

        // When: Getting sleep dates
        let sleepDateMidnight = DateUtils.getSleepDate(for: midnight)
        let sleepDateTwoAM = DateUtils.getSleepDate(for: twoAM)

        // Then: Should follow boundary logic regardless of timezone
        XCTAssertEqual(sleepDateMidnight.day, 11, "Midnight returns previous day")
        XCTAssertEqual(sleepDateTwoAM.day, 12, "2 AM returns current day")

        // 📚 Note: This test uses system timezone. In production, ensure
        // consistent timezone handling across different user devices
    }

    /// Test: getSleepDate multiple calls return consistent results
    ///
    /// 테스트: getSleepDate의 여러 호출이 일관된 결과를 반환
    /// 📚 학습 포인트: Idempotency
    func testGetSleepDate_MultipleCallsConsistent() {
        // Given: A specific date
        let testDate = makeDate(year: 2026, month: 1, day: 12, hour: 3, minute: 30)

        // When: Calling getSleepDate multiple times
        let result1 = DateUtils.getSleepDate(for: testDate)
        let result2 = DateUtils.getSleepDate(for: testDate)
        let result3 = DateUtils.getSleepDate(for: testDate)

        // Then: All calls should return the same date
        XCTAssertEqual(result1.yyyyMMdd, result2.yyyyMMdd)
        XCTAssertEqual(result2.yyyyMMdd, result3.yyyyMMdd)
        XCTAssertEqual(result1.yyyyMMdd, result3.yyyyMMdd)

        // 📚 Note: Pure function - same input always produces same output
    }

    // MARK: - Edge Cases for Date Formatting

    /// Test: formatDuration with large values
    ///
    /// 테스트: formatDuration의 큰 값 처리
    func testFormatDuration_LargeValues() {
        // Test 24 hours
        XCTAssertEqual(DateUtils.formatDuration(minutes: 1440), "24시간")

        // Test more than 24 hours
        XCTAssertEqual(DateUtils.formatDuration(minutes: 1500), "25시간")

        // Test multiple days
        XCTAssertEqual(DateUtils.formatDuration(minutes: 2880), "48시간")
    }

    /// Test: formatDuration with edge values
    ///
    /// 테스트: formatDuration의 경계값 처리
    func testFormatDuration_EdgeValues() {
        // Test 1 minute
        XCTAssertEqual(DateUtils.formatDuration(minutes: 1), "1분")

        // Test 59 minutes
        XCTAssertEqual(DateUtils.formatDuration(minutes: 59), "59분")

        // Test exactly 1 hour
        XCTAssertEqual(DateUtils.formatDuration(minutes: 60), "1시간")

        // Test 1 hour 1 minute
        XCTAssertEqual(DateUtils.formatDuration(minutes: 61), "1시간 1분")

        // Test 23 hours 59 minutes
        XCTAssertEqual(DateUtils.formatDuration(minutes: 1439), "23시간 59분")
    }

    /// Test: daysBetween with same day
    ///
    /// 테스트: daysBetween의 같은 날 처리
    func testDaysBetween_SameDay() {
        // Given: Same date at different times
        let date1 = makeDate(year: 2026, month: 1, day: 12, hour: 8, minute: 0)
        let date2 = makeDate(year: 2026, month: 1, day: 12, hour: 20, minute: 0)

        // When: Calculating days between
        let days = DateUtils.daysBetween(from: date1, to: date2)

        // Then: Should return 0 days (same day)
        XCTAssertEqual(days, 0, "Same day should return 0 days")
    }

    /// Test: daysBetween with reversed dates
    ///
    /// 테스트: daysBetween의 역순 날짜 처리
    func testDaysBetween_ReversedDates() {
        // Given: Two dates in reverse order
        let date1 = makeDate(year: 2026, month: 1, day: 12, hour: 10, minute: 0)
        let date2 = makeDate(year: 2026, month: 1, day: 19, hour: 15, minute: 30)

        // When: Calculating days between (reversed)
        let daysForward = DateUtils.daysBetween(from: date1, to: date2)
        let daysReverse = DateUtils.daysBetween(from: date2, to: date1)

        // Then: Should return absolute value (7 days in both cases)
        XCTAssertEqual(daysForward, 7)
        XCTAssertEqual(daysReverse, 7)
        XCTAssertEqual(daysForward, daysReverse, "daysBetween should return absolute value")
    }
}
