//
//  DateUtils.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-12.
//

import Foundation

/// Date utility service for handling date logic including sleep boundary calculations
///
/// 날짜 관련 유틸리티 서비스 (수면 경계 계산 포함)
enum DateUtils {

    // MARK: - Sleep Boundary Logic

    /// Returns the logical date for sleep tracking purposes, applying the 02:00 boundary rule
    ///
    /// 수면 기록을 위한 논리적 날짜를 반환합니다 (02:00 경계 규칙 적용).
    ///
    /// **Rule**: Hours 00:00-01:59 belong to the previous day for sleep tracking.
    /// - 02:00 ~ 23:59 → Current day
    /// - 00:00 ~ 01:59 → Previous day
    ///
    /// - Parameter date: The actual date/time to convert
    /// - Returns: The logical date for sleep tracking
    ///
    /// Example:
    /// ```swift
    /// // January 12, 2026 at 01:30 AM
    /// let date1 = Calendar.current.date(from: DateComponents(year: 2026, month: 1, day: 12, hour: 1, minute: 30))!
    /// let logicalDate1 = DateUtils.getLogicalDate(for: date1)
    /// // Returns: January 11, 2026 (previous day)
    ///
    /// // January 12, 2026 at 02:00 AM
    /// let date2 = Calendar.current.date(from: DateComponents(year: 2026, month: 1, day: 12, hour: 2, minute: 0))!
    /// let logicalDate2 = DateUtils.getLogicalDate(for: date2)
    /// // Returns: January 12, 2026 (current day)
    ///
    /// // January 12, 2026 at 02:01 AM
    /// let date3 = Calendar.current.date(from: DateComponents(year: 2026, month: 1, day: 12, hour: 2, minute: 1))!
    /// let logicalDate3 = DateUtils.getLogicalDate(for: date3)
    /// // Returns: January 12, 2026 (current day)
    /// ```
    static func getLogicalDate(for date: Date) -> Date {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)

        if hour < Constants.Sleep.boundaryHour {
            // 00:00 ~ 01:59 belongs to previous day
            return calendar.date(byAdding: .day, value: -1, to: date.startOfDay) ?? date.startOfDay
        }

        // 02:00 ~ 23:59 is current day
        return date.startOfDay
    }

    /// Checks if the current time is within the sleep recording window
    ///
    /// 현재 시간이 수면 기록 시간대인지 확인합니다 (06:00 이후).
    ///
    /// - Returns: True if current time is >= 06:00 (sleep recording window)
    ///
    /// Example:
    /// ```swift
    /// // At 05:59 AM
    /// let shouldShow1 = DateUtils.shouldShowSleepPopup() // false
    ///
    /// // At 06:00 AM or later
    /// let shouldShow2 = DateUtils.shouldShowSleepPopup() // true
    /// ```
    static func shouldShowSleepPopup() -> Bool {
        let hour = Calendar.current.component(.hour, from: Date())
        return hour >= Constants.Sleep.promptHour
    }

    /// Returns the sleep date for a given date/time
    ///
    /// 주어진 날짜/시간에 대한 수면 날짜를 반환합니다.
    ///
    /// This is an alias for `getLogicalDate(for:)` with clearer naming for sleep context.
    ///
    /// - Parameter date: The actual date/time
    /// - Returns: The sleep date (logical date)
    ///
    /// Example:
    /// ```swift
    /// // At 03:00 AM on Jan 12, entering sleep data
    /// let now = Date() // 2026-01-12 03:00:00
    /// let sleepDate = DateUtils.getSleepDate(for: now)
    /// // Returns: 2026-01-11 (yesterday's sleep)
    /// ```
    static func getSleepDate(for date: Date) -> Date {
        getLogicalDate(for: date)
    }

    // MARK: - Date Formatting Utilities

    /// Formats a date for display in Korean locale (년 월 일)
    ///
    /// 날짜를 한국어 형식으로 포맷합니다 (년 월 일).
    ///
    /// - Parameters:
    ///   - date: The date to format
    ///   - style: The date format style (default: .medium)
    /// - Returns: Formatted date string
    ///
    /// Example:
    /// ```swift
    /// let date = Date() // 2026-01-12
    /// let formatted = DateUtils.formatKorean(date)
    /// // Returns: "2026년 1월 12일"
    /// ```
    static func formatKorean(_ date: Date, style: DateFormatter.Style = .medium) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: date)
    }

    /// Formats a date for display with time in Korean locale
    ///
    /// 날짜와 시간을 한국어 형식으로 포맷합니다.
    ///
    /// - Parameters:
    ///   - date: The date to format
    ///   - dateStyle: The date format style (default: .medium)
    ///   - timeStyle: The time format style (default: .short)
    /// - Returns: Formatted date and time string
    ///
    /// Example:
    /// ```swift
    /// let date = Date() // 2026-01-12 15:30:45
    /// let formatted = DateUtils.formatKoreanWithTime(date)
    /// // Returns: "2026년 1월 12일 오후 3:30"
    /// ```
    static func formatKoreanWithTime(
        _ date: Date,
        dateStyle: DateFormatter.Style = .medium,
        timeStyle: DateFormatter.Style = .short
    ) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = dateStyle
        formatter.timeStyle = timeStyle
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: date)
    }

    /// Returns a relative date string (오늘, 어제, 내일, or formatted date)
    ///
    /// 상대적 날짜 문자열을 반환합니다 (오늘, 어제, 내일, 또는 포맷된 날짜).
    ///
    /// - Parameter date: The date to format
    /// - Returns: Relative date string in Korean
    ///
    /// Example:
    /// ```swift
    /// let today = Date()
    /// let todayStr = DateUtils.relativeDate(today)
    /// // Returns: "오늘"
    ///
    /// let yesterday = Date().adding(days: -1)
    /// let yesterdayStr = DateUtils.relativeDate(yesterday)
    /// // Returns: "어제"
    ///
    /// let lastWeek = Date().adding(days: -7)
    /// let lastWeekStr = DateUtils.relativeDate(lastWeek)
    /// // Returns: "2026년 1월 5일" (formatted)
    /// ```
    static func relativeDate(_ date: Date) -> String {
        if date.isToday {
            return "오늘"
        } else if date.isYesterday {
            return "어제"
        } else if date.isTomorrow {
            return "내일"
        } else {
            return formatKorean(date)
        }
    }

    /// Formats a duration in minutes to a readable Korean string
    ///
    /// 분 단위 시간을 읽기 쉬운 한국어 문자열로 포맷합니다.
    ///
    /// - Parameter minutes: Duration in minutes
    /// - Returns: Formatted duration string (e.g., "7시간 30분")
    ///
    /// Example:
    /// ```swift
    /// let duration1 = DateUtils.formatDuration(minutes: 450)
    /// // Returns: "7시간 30분"
    ///
    /// let duration2 = DateUtils.formatDuration(minutes: 60)
    /// // Returns: "1시간"
    ///
    /// let duration3 = DateUtils.formatDuration(minutes: 45)
    /// // Returns: "45분"
    ///
    /// let duration4 = DateUtils.formatDuration(minutes: 0)
    /// // Returns: "0분"
    /// ```
    static func formatDuration(minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60

        if hours > 0 && mins > 0 {
            return "\(hours)시간 \(mins)분"
        } else if hours > 0 {
            return "\(hours)시간"
        } else {
            return "\(mins)분"
        }
    }

    /// Creates a date from year, month, and day components
    ///
    /// 년, 월, 일 컴포넌트로부터 날짜를 생성합니다.
    ///
    /// - Parameters:
    ///   - year: Year component
    ///   - month: Month component (1-12)
    ///   - day: Day component
    /// - Returns: Date if valid, nil otherwise
    ///
    /// Example:
    /// ```swift
    /// let date = DateUtils.date(year: 2026, month: 1, day: 12)
    /// // Returns: 2026-01-12 00:00:00
    /// ```
    static func date(year: Int, month: Int, day: Int) -> Date? {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        return Calendar.current.date(from: components)
    }

    /// Returns the number of days between two dates
    ///
    /// 두 날짜 사이의 일수를 반환합니다.
    ///
    /// - Parameters:
    ///   - from: Start date
    ///   - to: End date
    /// - Returns: Number of days between the dates
    ///
    /// Example:
    /// ```swift
    /// let date1 = Date() // 2026-01-12
    /// let date2 = date1.adding(days: 7) // 2026-01-19
    /// let days = DateUtils.daysBetween(from: date1, to: date2)
    /// // Returns: 7
    /// ```
    static func daysBetween(from startDate: Date, to endDate: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: startDate.startOfDay, to: endDate.startOfDay)
        return abs(components.day ?? 0)
    }
}
