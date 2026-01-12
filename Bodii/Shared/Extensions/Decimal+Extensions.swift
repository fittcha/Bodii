//
//  Decimal+Extensions.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-12.
//

import Foundation

/// Decimal extension providing formatting and arithmetic helpers for body measurements
extension Decimal {

    // MARK: - Formatting Helpers

    /// Formats decimal as string with 1 decimal place for body measurements
    ///
    /// 신체 측정값을 소수점 1자리까지 문자열로 포맷팅합니다.
    ///
    /// Example:
    /// ```swift
    /// let weight = Decimal(72.456)
    /// let formatted = weight.formatted1 // "72.5"
    /// ```
    var formatted1: String {
        formatted(decimalPlaces: 1)
    }

    /// Formats decimal as string with 2 decimal places
    ///
    /// 소수점 2자리까지 문자열로 포맷팅합니다.
    ///
    /// Example:
    /// ```swift
    /// let value = Decimal(18.756)
    /// let formatted = value.formatted2 // "18.76"
    /// ```
    var formatted2: String {
        formatted(decimalPlaces: 2)
    }

    /// Formats decimal as string with no decimal places (for calorie counts)
    ///
    /// 정수 형식으로 문자열을 포맷팅합니다 (칼로리 표시용).
    ///
    /// Example:
    /// ```swift
    /// let calories = Decimal(1845.7)
    /// let formatted = calories.formatted0 // "1846"
    /// ```
    var formatted0: String {
        formatted(decimalPlaces: 0)
    }

    /// Formats decimal as percentage string with 1 decimal place
    ///
    /// 퍼센트 형식으로 문자열을 포맷팅합니다 (소수점 1자리).
    ///
    /// Example:
    /// ```swift
    /// let bodyFat = Decimal(18.5)
    /// let formatted = bodyFat.formattedPercent // "18.5%"
    /// ```
    var formattedPercent: String {
        "\(formatted1)%"
    }

    /// Formats decimal with specified number of decimal places
    ///
    /// 지정된 소수점 자리수로 문자열을 포맷팅합니다.
    ///
    /// - Parameter decimalPlaces: 소수점 자리수 (기본값: 1)
    /// - Returns: 포맷팅된 문자열
    ///
    /// Example:
    /// ```swift
    /// let value = Decimal(123.456789)
    /// let formatted = value.formatted(decimalPlaces: 3) // "123.457"
    /// ```
    func formatted(decimalPlaces: Int = 1) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = decimalPlaces
        formatter.maximumFractionDigits = decimalPlaces
        formatter.roundingMode = .halfUp
        formatter.locale = Locale.current
        return formatter.string(from: self as NSDecimalNumber) ?? "\(self)"
    }

    // MARK: - Arithmetic Helpers

    /// Rounds decimal to specified number of decimal places
    ///
    /// 지정된 소수점 자리수로 반올림합니다.
    ///
    /// - Parameter places: 소수점 자리수
    /// - Returns: 반올림된 Decimal 값
    ///
    /// Example:
    /// ```swift
    /// let value = Decimal(72.456)
    /// let rounded = value.rounded(to: 1) // 72.5
    /// ```
    func rounded(to places: Int) -> Decimal {
        var result = self
        var roundedValue = Decimal()
        NSDecimalRound(&roundedValue, &result, places, .plain)
        return roundedValue
    }

    /// Rounds decimal to 1 decimal place (for body measurements)
    ///
    /// 신체 측정값을 소수점 1자리로 반올림합니다.
    ///
    /// Example:
    /// ```swift
    /// let weight = Decimal(72.456)
    /// let rounded = weight.rounded1 // 72.5
    /// ```
    var rounded1: Decimal {
        rounded(to: 1)
    }

    /// Rounds decimal to 2 decimal places
    ///
    /// 소수점 2자리로 반올림합니다.
    ///
    /// Example:
    /// ```swift
    /// let value = Decimal(18.756)
    /// let rounded = value.rounded2 // 18.76
    /// ```
    var rounded2: Decimal {
        rounded(to: 2)
    }

    /// Rounds decimal to nearest integer
    ///
    /// 가장 가까운 정수로 반올림합니다.
    ///
    /// Example:
    /// ```swift
    /// let calories = Decimal(1845.7)
    /// let rounded = calories.rounded0 // 1846
    /// ```
    var rounded0: Decimal {
        rounded(to: 0)
    }

    // MARK: - Conversion Helpers

    /// Converts Decimal to Double
    ///
    /// Decimal을 Double로 변환합니다.
    ///
    /// Example:
    /// ```swift
    /// let weight = Decimal(72.5)
    /// let doubleValue = weight.toDouble() // 72.5 (Double)
    /// ```
    func toDouble() -> Double {
        NSDecimalNumber(decimal: self).doubleValue
    }

    /// Converts Decimal to Int (rounded)
    ///
    /// Decimal을 반올림하여 Int로 변환합니다.
    ///
    /// Example:
    /// ```swift
    /// let calories = Decimal(1845.7)
    /// let intValue = calories.toInt() // 1846
    /// ```
    func toInt() -> Int {
        Int(truncating: NSDecimalNumber(decimal: rounded0))
    }

    /// Converts Decimal to Int32 (rounded, for Core Data)
    ///
    /// Decimal을 반올림하여 Int32로 변환합니다 (Core Data용).
    ///
    /// Example:
    /// ```swift
    /// let calories = Decimal(1845.7)
    /// let int32Value = calories.toInt32() // 1846
    /// ```
    func toInt32() -> Int32 {
        Int32(truncating: NSDecimalNumber(decimal: rounded0))
    }

    /// Creates Decimal from Double
    ///
    /// Double로부터 Decimal을 생성합니다.
    ///
    /// - Parameter value: Double 값
    /// - Returns: Decimal 값
    ///
    /// Example:
    /// ```swift
    /// let decimal = Decimal.from(72.5)
    /// ```
    static func from(_ value: Double) -> Decimal {
        Decimal(value)
    }

    /// Creates Decimal from Int
    ///
    /// Int로부터 Decimal을 생성합니다.
    ///
    /// - Parameter value: Int 값
    /// - Returns: Decimal 값
    ///
    /// Example:
    /// ```swift
    /// let decimal = Decimal.from(1846)
    /// ```
    static func from(_ value: Int) -> Decimal {
        Decimal(value)
    }

    // MARK: - Validation Helpers

    /// Checks if decimal is within specified range
    ///
    /// Decimal 값이 지정된 범위 내에 있는지 확인합니다.
    ///
    /// - Parameters:
    ///   - min: 최소값
    ///   - max: 최대값
    /// - Returns: 범위 내에 있으면 true
    ///
    /// Example:
    /// ```swift
    /// let weight = Decimal(72.5)
    /// let isValid = weight.isInRange(min: 20, max: 300) // true
    /// ```
    func isInRange(min: Decimal, max: Decimal) -> Bool {
        self >= min && self <= max
    }

    /// Checks if decimal is positive (> 0)
    ///
    /// Decimal 값이 양수인지 확인합니다 (0보다 큼).
    ///
    /// Example:
    /// ```swift
    /// let weight = Decimal(72.5)
    /// let isPositive = weight.isPositive // true
    /// ```
    var isPositive: Bool {
        self > 0
    }

    /// Checks if decimal is zero
    ///
    /// Decimal 값이 0인지 확인합니다.
    ///
    /// Example:
    /// ```swift
    /// let value = Decimal(0)
    /// let isZero = value.isZero // true
    /// ```
    var isZero: Bool {
        self == 0
    }

    // MARK: - Calculation Helpers

    /// Calculates percentage of a total
    ///
    /// 전체 중 이 값의 비율을 백분율로 계산합니다.
    ///
    /// - Parameter total: 전체 값
    /// - Returns: 백분율 (0-100), 전체가 0이면 0 반환
    ///
    /// Example:
    /// ```swift
    /// let carbs = Decimal(50)
    /// let totalCalories = Decimal(200)
    /// let percentage = carbs.percentage(of: totalCalories) // 25.0
    /// ```
    func percentage(of total: Decimal) -> Decimal {
        guard total > 0 else { return 0 }
        return (self / total) * 100
    }

    /// Calculates value from percentage
    ///
    /// 전체 값의 특정 퍼센트에 해당하는 값을 계산합니다.
    ///
    /// - Parameter total: 전체 값
    /// - Returns: 계산된 값
    ///
    /// Example:
    /// ```swift
    /// let bodyFatPct = Decimal(18.5)
    /// let weight = Decimal(72)
    /// let bodyFatMass = bodyFatPct.valueFrom(total: weight) // 13.32
    /// ```
    func valueFrom(total: Decimal) -> Decimal {
        (self / 100) * total
    }

    /// Clamps decimal to specified range
    ///
    /// Decimal 값을 지정된 범위로 제한합니다.
    ///
    /// - Parameters:
    ///   - min: 최소값
    ///   - max: 최대값
    /// - Returns: 범위 내로 제한된 값
    ///
    /// Example:
    /// ```swift
    /// let value = Decimal(350)
    /// let clamped = value.clamped(to: 20, max: 300) // 300
    /// ```
    func clamped(to min: Decimal, max: Decimal) -> Decimal {
        if self < min { return min }
        if self > max { return max }
        return self
    }
}
