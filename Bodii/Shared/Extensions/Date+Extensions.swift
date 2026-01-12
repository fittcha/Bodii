//
//  Date+Extensions.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-12.
//

import Foundation

/// Date extension providing age calculation and date manipulation helpers
extension Date {

    // MARK: - Age Calculation

    /// Calculates age in years from a birth date to the current date
    ///
    /// 생년월일로부터 현재 나이를 계산합니다.
    ///
    /// - Parameter birthDate: 생년월일
    /// - Returns: 만 나이 (years)
    ///
    /// Example:
    /// ```swift
    /// let birthDate = Calendar.current.date(from: DateComponents(year: 1994, month: 3, day: 15))!
    /// let age = Date.age(from: birthDate)
    /// // Returns: 31 (as of 2026)
    /// ```
    static func age(from birthDate: Date) -> Int {
        let calendar = Calendar.current
        let now = Date()
        let ageComponents = calendar.dateComponents([.year], from: birthDate, to: now)
        return ageComponents.year ?? 0
    }

    /// Calculates age in years from this date to another date
    ///
    /// 이 날짜로부터 다른 날짜까지의 나이를 계산합니다.
    ///
    /// - Parameter date: 기준 날짜 (기본값: 현재)
    /// - Returns: 만 나이 (years)
    ///
    /// Example:
    /// ```swift
    /// let birthDate = Date()
    /// let age = birthDate.age(to: Date())
    /// ```
    func age(to date: Date = Date()) -> Int {
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: self, to: date)
        return ageComponents.year ?? 0
    }

    // MARK: - Date Manipulation

    /// Returns the start of day for this date
    ///
    /// 이 날짜의 시작 시각(00:00:00)을 반환합니다.
    ///
    /// Example:
    /// ```swift
    /// let date = Date() // 2026-01-12 15:30:45
    /// let startOfDay = date.startOfDay // 2026-01-12 00:00:00
    /// ```
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    /// Returns the end of day for this date
    ///
    /// 이 날짜의 마지막 시각(23:59:59)을 반환합니다.
    ///
    /// Example:
    /// ```swift
    /// let date = Date() // 2026-01-12 15:30:45
    /// let endOfDay = date.endOfDay // 2026-01-12 23:59:59
    /// ```
    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay) ?? self
    }

    /// Adds a specified number of days to this date
    ///
    /// 이 날짜에 지정된 일수를 더합니다.
    ///
    /// - Parameter days: 더할 일수 (음수 가능)
    /// - Returns: 계산된 날짜, 실패 시 원본 날짜
    ///
    /// Example:
    /// ```swift
    /// let today = Date()
    /// let tomorrow = today.adding(days: 1)
    /// let yesterday = today.adding(days: -1)
    /// ```
    func adding(days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }

    /// Adds a specified number of months to this date
    ///
    /// 이 날짜에 지정된 개월수를 더합니다.
    ///
    /// - Parameter months: 더할 개월수 (음수 가능)
    /// - Returns: 계산된 날짜, 실패 시 원본 날짜
    ///
    /// Example:
    /// ```swift
    /// let today = Date()
    /// let nextMonth = today.adding(months: 1)
    /// let lastMonth = today.adding(months: -1)
    /// ```
    func adding(months: Int) -> Date {
        Calendar.current.date(byAdding: .month, value: months, to: self) ?? self
    }

    /// Adds a specified number of years to this date
    ///
    /// 이 날짜에 지정된 년수를 더합니다.
    ///
    /// - Parameter years: 더할 년수 (음수 가능)
    /// - Returns: 계산된 날짜, 실패 시 원본 날짜
    ///
    /// Example:
    /// ```swift
    /// let today = Date()
    /// let nextYear = today.adding(years: 1)
    /// let lastYear = today.adding(years: -1)
    /// ```
    func adding(years: Int) -> Date {
        Calendar.current.date(byAdding: .year, value: years, to: self) ?? self
    }

    // MARK: - Date Components

    /// Returns the year component of this date
    ///
    /// 이 날짜의 년도를 반환합니다.
    ///
    /// Example:
    /// ```swift
    /// let date = Date() // 2026-01-12
    /// let year = date.year // 2026
    /// ```
    var year: Int {
        Calendar.current.component(.year, from: self)
    }

    /// Returns the month component of this date (1-12)
    ///
    /// 이 날짜의 월을 반환합니다 (1-12).
    ///
    /// Example:
    /// ```swift
    /// let date = Date() // 2026-01-12
    /// let month = date.month // 1
    /// ```
    var month: Int {
        Calendar.current.component(.month, from: self)
    }

    /// Returns the day component of this date
    ///
    /// 이 날짜의 일을 반환합니다.
    ///
    /// Example:
    /// ```swift
    /// let date = Date() // 2026-01-12
    /// let day = date.day // 12
    /// ```
    var day: Int {
        Calendar.current.component(.day, from: self)
    }

    /// Returns the hour component of this date (0-23)
    ///
    /// 이 날짜의 시간을 반환합니다 (0-23).
    ///
    /// Example:
    /// ```swift
    /// let date = Date() // 2026-01-12 15:30:45
    /// let hour = date.hour // 15
    /// ```
    var hour: Int {
        Calendar.current.component(.hour, from: self)
    }

    /// Returns the minute component of this date (0-59)
    ///
    /// 이 날짜의 분을 반환합니다 (0-59).
    ///
    /// Example:
    /// ```swift
    /// let date = Date() // 2026-01-12 15:30:45
    /// let minute = date.minute // 30
    /// ```
    var minute: Int {
        Calendar.current.component(.minute, from: self)
    }

    // MARK: - Date Comparison

    /// Checks if this date is the same day as another date
    ///
    /// 이 날짜가 다른 날짜와 같은 날인지 확인합니다.
    ///
    /// - Parameter date: 비교할 날짜
    /// - Returns: 같은 날이면 true
    ///
    /// Example:
    /// ```swift
    /// let date1 = Date() // 2026-01-12 10:00:00
    /// let date2 = Date() // 2026-01-12 15:30:00
    /// let isSameDay = date1.isSameDay(as: date2) // true
    /// ```
    func isSameDay(as date: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: date)
    }

    /// Checks if this date is today
    ///
    /// 이 날짜가 오늘인지 확인합니다.
    ///
    /// Example:
    /// ```swift
    /// let date = Date()
    /// let isToday = date.isToday // true
    /// ```
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    /// Checks if this date is yesterday
    ///
    /// 이 날짜가 어제인지 확인합니다.
    ///
    /// Example:
    /// ```swift
    /// let yesterday = Date().adding(days: -1)
    /// let isYesterday = yesterday.isYesterday // true
    /// ```
    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }

    /// Checks if this date is tomorrow
    ///
    /// 이 날짜가 내일인지 확인합니다.
    ///
    /// Example:
    /// ```swift
    /// let tomorrow = Date().adding(days: 1)
    /// let isTomorrow = tomorrow.isTomorrow // true
    /// ```
    var isTomorrow: Bool {
        Calendar.current.isDateInTomorrow(self)
    }

    // MARK: - Formatting Helpers

    /// Returns a string representation in "yyyy-MM-dd" format
    ///
    /// "yyyy-MM-dd" 형식의 문자열을 반환합니다.
    ///
    /// Example:
    /// ```swift
    /// let date = Date() // 2026-01-12 15:30:45
    /// let formatted = date.yyyyMMdd // "2026-01-12"
    /// ```
    var yyyyMMdd: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: self)
    }

    /// Returns a string representation in "yyyy-MM-dd HH:mm:ss" format
    ///
    /// "yyyy-MM-dd HH:mm:ss" 형식의 문자열을 반환합니다.
    ///
    /// Example:
    /// ```swift
    /// let date = Date() // 2026-01-12 15:30:45
    /// let formatted = date.yyyyMMddHHmmss // "2026-01-12 15:30:45"
    /// ```
    var yyyyMMddHHmmss: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: self)
    }
}
