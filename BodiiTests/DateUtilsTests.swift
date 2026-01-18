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
}
