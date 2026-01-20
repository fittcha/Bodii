//
//  Formatters.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-12.
//

import Foundation

/// Utility for consistent display formatting throughout the app
///
/// 앱 전체에서 일관된 표시 포맷을 제공하는 유틸리티
enum Formatters {

    // MARK: - Calorie Formatting

    /// Formats calories as integer with thousands separator and kcal unit
    ///
    /// 칼로리를 천 단위 구분자와 kcal 단위로 포맷합니다.
    ///
    /// - Parameter calories: Calorie value (can be Int, Int32, Decimal, or Double)
    /// - Returns: Formatted string (e.g., "1,234 kcal")
    ///
    /// Example:
    /// ```swift
    /// let calories1 = Formatters.calories(1234)
    /// // Returns: "1,234 kcal"
    ///
    /// let calories2 = Formatters.calories(Decimal(1845.7))
    /// // Returns: "1,846 kcal"
    ///
    /// let calories3 = Formatters.calories(0)
    /// // Returns: "0 kcal"
    /// ```
    static func calories(_ value: Int) -> String {
        "\(numberWithCommas(value)) kcal"
    }

    /// Formats calories from Int32 value
    ///
    /// Int32 칼로리 값을 포맷합니다.
    ///
    /// - Parameter value: Calorie value (Int32)
    /// - Returns: Formatted string (e.g., "1,234 kcal")
    ///
    /// Example:
    /// ```swift
    /// let totalCalories: Int32 = 2150
    /// let formatted = Formatters.calories(totalCalories)
    /// // Returns: "2,150 kcal"
    /// ```
    static func calories(_ value: Int32) -> String {
        calories(Int(value))
    }

    /// Formats calories from Decimal value (rounds to nearest integer)
    ///
    /// Decimal 칼로리 값을 포맷합니다 (가장 가까운 정수로 반올림).
    ///
    /// - Parameter value: Calorie value (Decimal)
    /// - Returns: Formatted string (e.g., "1,234 kcal")
    ///
    /// Example:
    /// ```swift
    /// let calculatedCalories = Decimal(1845.7)
    /// let formatted = Formatters.calories(calculatedCalories)
    /// // Returns: "1,846 kcal"
    /// ```
    static func calories(_ value: Decimal) -> String {
        calories(value.toInt())
    }

    /// Formats calories from Double value (rounds to nearest integer)
    ///
    /// Double 칼로리 값을 포맷합니다 (가장 가까운 정수로 반올림).
    ///
    /// - Parameter value: Calorie value (Double)
    /// - Returns: Formatted string (e.g., "1,234 kcal")
    ///
    /// Example:
    /// ```swift
    /// let caloriesBurned = 345.8
    /// let formatted = Formatters.calories(caloriesBurned)
    /// // Returns: "346 kcal"
    /// ```
    static func calories(_ value: Double) -> String {
        calories(Int(value.rounded()))
    }

    // MARK: - Weight Formatting

    /// Formats weight with 1 decimal place and kg unit
    ///
    /// 체중을 소수점 1자리와 kg 단위로 포맷합니다.
    ///
    /// - Parameter weight: Weight in kilograms
    /// - Returns: Formatted string (e.g., "72.5 kg")
    ///
    /// Example:
    /// ```swift
    /// let weight = Decimal(72.456)
    /// let formatted = Formatters.weight(weight)
    /// // Returns: "72.5 kg"
    /// ```
    static func weight(_ value: Decimal) -> String {
        "\(value.formatted1) kg"
    }

    /// Formats weight from Double value
    ///
    /// Double 체중 값을 포맷합니다.
    ///
    /// - Parameter value: Weight in kilograms
    /// - Returns: Formatted string (e.g., "72.5 kg")
    ///
    /// Example:
    /// ```swift
    /// let weight = 72.456
    /// let formatted = Formatters.weight(weight)
    /// // Returns: "72.5 kg"
    /// ```
    static func weight(_ value: Double) -> String {
        weight(Decimal(value))
    }

    // MARK: - Height Formatting

    /// Formats height with 1 decimal place and cm unit
    ///
    /// 키를 소수점 1자리와 cm 단위로 포맷합니다.
    ///
    /// - Parameter height: Height in centimeters
    /// - Returns: Formatted string (e.g., "175.5 cm")
    ///
    /// Example:
    /// ```swift
    /// let height = Decimal(175.456)
    /// let formatted = Formatters.height(height)
    /// // Returns: "175.5 cm"
    /// ```
    static func height(_ value: Decimal) -> String {
        "\(value.formatted1) cm"
    }

    /// Formats height from Double value
    ///
    /// Double 키 값을 포맷합니다.
    ///
    /// - Parameter value: Height in centimeters
    /// - Returns: Formatted string (e.g., "175.5 cm")
    ///
    /// Example:
    /// ```swift
    /// let height = 175.456
    /// let formatted = Formatters.height(height)
    /// // Returns: "175.5 cm"
    /// ```
    static func height(_ value: Double) -> String {
        height(Decimal(value))
    }

    // MARK: - Percentage Formatting

    /// Formats percentage with 1 decimal place and % symbol
    ///
    /// 퍼센트를 소수점 1자리와 % 기호로 포맷합니다.
    ///
    /// - Parameter percentage: Percentage value (0-100)
    /// - Returns: Formatted string (e.g., "18.5%")
    ///
    /// Example:
    /// ```swift
    /// let bodyFat = Decimal(18.456)
    /// let formatted = Formatters.percentage(bodyFat)
    /// // Returns: "18.5%"
    ///
    /// let ratio = Decimal(25.0)
    /// let formatted2 = Formatters.percentage(ratio)
    /// // Returns: "25.0%"
    /// ```
    static func percentage(_ value: Decimal) -> String {
        value.formattedPercent
    }

    /// Formats percentage from Double value
    ///
    /// Double 퍼센트 값을 포맷합니다.
    ///
    /// - Parameter value: Percentage value (0-100)
    /// - Returns: Formatted string (e.g., "18.5%")
    ///
    /// Example:
    /// ```swift
    /// let bodyFat = 18.456
    /// let formatted = Formatters.percentage(bodyFat)
    /// // Returns: "18.5%"
    /// ```
    static func percentage(_ value: Double) -> String {
        percentage(Decimal(value))
    }

    /// Formats optional percentage, returns "-" if nil
    ///
    /// 선택적 퍼센트를 포맷하며, nil이면 "-"를 반환합니다.
    ///
    /// - Parameter value: Optional percentage value
    /// - Returns: Formatted string or "-" if nil
    ///
    /// Example:
    /// ```swift
    /// let carbsRatio: Decimal? = 45.5
    /// let formatted1 = Formatters.percentageOptional(carbsRatio)
    /// // Returns: "45.5%"
    ///
    /// let fatRatio: Decimal? = nil
    /// let formatted2 = Formatters.percentageOptional(fatRatio)
    /// // Returns: "-"
    /// ```
    static func percentageOptional(_ value: Decimal?) -> String {
        guard let value = value else { return "-" }
        return percentage(value)
    }

    // MARK: - Macronutrient Formatting

    /// Formats macronutrient (carbs, protein, fat) with 1 decimal place and g unit
    ///
    /// 다량영양소(탄수화물, 단백질, 지방)를 소수점 1자리와 g 단위로 포맷합니다.
    ///
    /// - Parameter grams: Macronutrient value in grams
    /// - Returns: Formatted string (e.g., "50.5 g")
    ///
    /// Example:
    /// ```swift
    /// let protein = Decimal(45.678)
    /// let formatted = Formatters.macronutrient(protein)
    /// // Returns: "45.7 g"
    /// ```
    static func macronutrient(_ value: Decimal) -> String {
        "\(value.formatted1) g"
    }

    /// Formats macronutrient from Double value
    ///
    /// Double 다량영양소 값을 포맷합니다.
    ///
    /// - Parameter value: Macronutrient value in grams
    /// - Returns: Formatted string (e.g., "50.5 g")
    ///
    /// Example:
    /// ```swift
    /// let carbs = 125.456
    /// let formatted = Formatters.macronutrient(carbs)
    /// // Returns: "125.5 g"
    /// ```
    static func macronutrient(_ value: Double) -> String {
        macronutrient(Decimal(value))
    }

    // MARK: - Sodium Formatting

    /// Formats sodium with 0 decimal places and mg unit (for values < 1000mg)
    ///
    /// 나트륨을 mg 단위로 포맷합니다 (1000mg 미만).
    ///
    /// - Parameter milligrams: Sodium value in milligrams
    /// - Returns: Formatted string (e.g., "234 mg" or "1,234 mg")
    ///
    /// Example:
    /// ```swift
    /// let sodium = Decimal(234.5)
    /// let formatted = Formatters.sodium(sodium)
    /// // Returns: "235 mg"
    ///
    /// let highSodium = Decimal(2345.8)
    /// let formatted2 = Formatters.sodium(highSodium)
    /// // Returns: "2,346 mg"
    /// ```
    static func sodium(_ value: Decimal) -> String {
        let rounded = value.toInt()
        return "\(numberWithCommas(rounded)) mg"
    }

    /// Formats sodium from Double value
    ///
    /// Double 나트륨 값을 포맷합니다.
    ///
    /// - Parameter value: Sodium value in milligrams
    /// - Returns: Formatted string (e.g., "234 mg")
    ///
    /// Example:
    /// ```swift
    /// let sodium = 234.5
    /// let formatted = Formatters.sodium(sodium)
    /// // Returns: "235 mg"
    /// ```
    static func sodium(_ value: Double) -> String {
        sodium(Decimal(value))
    }

    // MARK: - Serving Size Formatting

    /// Formats serving size with appropriate precision
    ///
    /// 제공량을 적절한 정밀도로 포맷합니다.
    ///
    /// - Parameter servings: Serving size value
    /// - Returns: Formatted string (e.g., "1.5", "2", "0.5")
    ///
    /// Example:
    /// ```swift
    /// let serving1 = Decimal(1.5)
    /// let formatted1 = Formatters.servingSize(serving1)
    /// // Returns: "1.5"
    ///
    /// let serving2 = Decimal(2.0)
    /// let formatted2 = Formatters.servingSize(serving2)
    /// // Returns: "2"
    /// ```
    static func servingSize(_ value: Decimal) -> String {
        // If it's a whole number, format with 0 decimals
        // Decimal doesn't have truncatingRemainder, so we check if it's a whole number
        var rounded = Decimal()
        var mutableValue = value
        NSDecimalRound(&rounded, &mutableValue, 0, .plain)
        if value == rounded {
            return value.formatted0
        }
        // Otherwise, format with 1 decimal
        return value.formatted1
    }

    /// Formats serving size with unit (인분 or g)
    ///
    /// 제공량을 단위와 함께 포맷합니다 (인분 또는 g).
    ///
    /// - Parameters:
    ///   - value: Serving size value
    ///   - unit: Quantity unit (serving or grams)
    /// - Returns: Formatted string (e.g., "1.5 인분", "150 g")
    ///
    /// Example:
    /// ```swift
    /// let serving = Decimal(1.5)
    /// let formatted1 = Formatters.servingWithUnit(serving, unit: .serving)
    /// // Returns: "1.5 인분"
    ///
    /// let grams = Decimal(150.0)
    /// let formatted2 = Formatters.servingWithUnit(grams, unit: .grams)
    /// // Returns: "150 g"
    /// ```
    static func servingWithUnit(_ value: Decimal, unit: QuantityUnit) -> String {
        let formatted = servingSize(value)
        return "\(formatted) \(unit.displayName)"
    }

    // MARK: - Number Formatting Helper

    /// Formats integer with thousands separator
    ///
    /// 정수를 천 단위 구분자로 포맷합니다.
    ///
    /// - Parameter value: Integer value
    /// - Returns: Formatted string (e.g., "1,234")
    ///
    /// Example:
    /// ```swift
    /// let number = 1234567
    /// let formatted = Formatters.numberWithCommas(number)
    /// // Returns: "1,234,567"
    /// ```
    static func numberWithCommas(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.groupingSize = 3
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    // MARK: - BMI Formatting

    /// Formats BMI with 1 decimal place
    ///
    /// BMI를 소수점 1자리로 포맷합니다.
    ///
    /// - Parameter bmi: BMI value
    /// - Returns: Formatted string (e.g., "23.5")
    ///
    /// Example:
    /// ```swift
    /// let bmi = Decimal(23.456)
    /// let formatted = Formatters.bmi(bmi)
    /// // Returns: "23.5"
    /// ```
    static func bmi(_ value: Decimal) -> String {
        value.formatted1
    }

    /// Formats BMI from Double value
    ///
    /// Double BMI 값을 포맷합니다.
    ///
    /// - Parameter value: BMI value
    /// - Returns: Formatted string (e.g., "23.5")
    ///
    /// Example:
    /// ```swift
    /// let bmi = 23.456
    /// let formatted = Formatters.bmi(bmi)
    /// // Returns: "23.5"
    /// ```
    static func bmi(_ value: Double) -> String {
        bmi(Decimal(value))
    }
}
