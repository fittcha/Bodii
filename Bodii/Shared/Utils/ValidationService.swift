//
//  ValidationService.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-12.
//

import Foundation

/// Validation service for user input validation
///
/// 사용자 입력 검증 서비스
enum ValidationService {

    // MARK: - Validation Result

    /// Result type for validation operations
    ///
    /// 검증 작업의 결과 타입
    enum ValidationResult {
        case success
        case failure(String)

        var isValid: Bool {
            if case .success = self {
                return true
            }
            return false
        }

        var errorMessage: String? {
            if case .failure(let message) = self {
                return message
            }
            return nil
        }
    }

    // MARK: - Name Validation

    /// Validates user name length
    ///
    /// 사용자 이름 길이를 검증합니다.
    ///
    /// **Validation Rule**: 1~20 characters
    ///
    /// - Parameter name: The name to validate
    /// - Returns: ValidationResult indicating success or failure with error message
    ///
    /// Example:
    /// ```swift
    /// let result1 = ValidationService.validateName("홍길동")
    /// // Returns: .success
    ///
    /// let result2 = ValidationService.validateName("")
    /// // Returns: .failure("이름을 입력해주세요")
    ///
    /// let result3 = ValidationService.validateName("매우긴이름입니다스물자가넘어요")
    /// // Returns: .failure("이름을 입력해주세요")
    /// ```
    static func validateName(_ name: String) -> ValidationResult {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let length = trimmedName.count

        guard length >= Constants.Validation.Name.minLength &&
              length <= Constants.Validation.Name.maxLength else {
            return .failure("이름을 입력해주세요")
        }

        return .success
    }

    // MARK: - Birth Date Validation

    /// Validates birth date range
    ///
    /// 생년월일 범위를 검증합니다.
    ///
    /// **Validation Rule**: Year must be between 1900 and current year
    ///
    /// - Parameter birthDate: The birth date to validate
    /// - Returns: ValidationResult indicating success or failure with error message
    ///
    /// Example:
    /// ```swift
    /// let validDate = DateUtils.date(year: 1994, month: 3, day: 15)!
    /// let result1 = ValidationService.validateBirthDate(validDate)
    /// // Returns: .success
    ///
    /// let futureDate = Date().adding(years: 1)
    /// let result2 = ValidationService.validateBirthDate(futureDate)
    /// // Returns: .failure("올바른 생년월일을 선택해주세요")
    ///
    /// let oldDate = DateUtils.date(year: 1899, month: 1, day: 1)!
    /// let result3 = ValidationService.validateBirthDate(oldDate)
    /// // Returns: .failure("올바른 생년월일을 선택해주세요")
    /// ```
    static func validateBirthDate(_ birthDate: Date) -> ValidationResult {
        let birthYear = birthDate.year

        guard birthYear >= Constants.Validation.BirthYear.min &&
              birthYear <= Constants.Validation.BirthYear.max else {
            return .failure("올바른 생년월일을 선택해주세요")
        }

        // Birth date cannot be in the future
        guard birthDate <= Date() else {
            return .failure("올바른 생년월일을 선택해주세요")
        }

        return .success
    }

    // MARK: - Height Validation

    /// Validates height in centimeters
    ///
    /// 키(cm)를 검증합니다.
    ///
    /// **Validation Rule**: 100~250 cm
    ///
    /// - Parameter height: Height in centimeters
    /// - Returns: ValidationResult indicating success or failure with error message
    ///
    /// Example:
    /// ```swift
    /// let result1 = ValidationService.validateHeight(175.5)
    /// // Returns: .success
    ///
    /// let result2 = ValidationService.validateHeight(99.9)
    /// // Returns: .failure("키는 100~250cm 사이로 입력해주세요")
    ///
    /// let result3 = ValidationService.validateHeight(250.1)
    /// // Returns: .failure("키는 100~250cm 사이로 입력해주세요")
    /// ```
    static func validateHeight(_ height: Double) -> ValidationResult {
        guard height >= Constants.Validation.Height.min &&
              height <= Constants.Validation.Height.max else {
            return .failure("키는 100~250cm 사이로 입력해주세요")
        }

        return .success
    }

    // MARK: - Weight Validation

    /// Validates weight in kilograms
    ///
    /// 몸무게(kg)를 검증합니다.
    ///
    /// **Validation Rule**: 20~300 kg
    ///
    /// - Parameter weight: Weight in kilograms
    /// - Returns: ValidationResult indicating success or failure with error message
    ///
    /// Example:
    /// ```swift
    /// let result1 = ValidationService.validateWeight(72.5)
    /// // Returns: .success
    ///
    /// let result2 = ValidationService.validateWeight(19.9)
    /// // Returns: .failure("몸무게는 20~300kg 사이로 입력해주세요")
    ///
    /// let result3 = ValidationService.validateWeight(300.1)
    /// // Returns: .failure("몸무게는 20~300kg 사이로 입력해주세요")
    /// ```
    static func validateWeight(_ weight: Double) -> ValidationResult {
        guard weight >= Constants.Validation.Weight.min &&
              weight <= Constants.Validation.Weight.max else {
            return .failure("몸무게는 20~300kg 사이로 입력해주세요")
        }

        return .success
    }

    // MARK: - Body Fat Percentage Validation

    /// Validates body fat percentage
    ///
    /// 체지방률(%)을 검증합니다.
    ///
    /// **Validation Rule**: 1~60%
    ///
    /// - Parameter bodyFatPercentage: Body fat percentage (1-60)
    /// - Returns: ValidationResult indicating success or failure with error message
    ///
    /// Example:
    /// ```swift
    /// let result1 = ValidationService.validateBodyFatPercentage(18.2)
    /// // Returns: .success
    ///
    /// let result2 = ValidationService.validateBodyFatPercentage(0.9)
    /// // Returns: .failure("체지방률은 1~60% 사이로 입력해주세요")
    ///
    /// let result3 = ValidationService.validateBodyFatPercentage(60.1)
    /// // Returns: .failure("체지방률은 1~60% 사이로 입력해주세요")
    /// ```
    static func validateBodyFatPercentage(_ bodyFatPercentage: Double) -> ValidationResult {
        guard bodyFatPercentage >= Constants.Validation.BodyFatPercentage.min &&
              bodyFatPercentage <= Constants.Validation.BodyFatPercentage.max else {
            return .failure("체지방률은 1~60% 사이로 입력해주세요")
        }

        return .success
    }

    // MARK: - Warning Checks

    /// Checks if body fat percentage is in extreme range (requires user confirmation)
    ///
    /// 체지방률이 극단적 범위인지 확인합니다 (사용자 확인 필요).
    ///
    /// **Warning Range**: < 3% or > 50%
    ///
    /// - Parameter bodyFatPercentage: Body fat percentage to check
    /// - Returns: True if in extreme range, false otherwise
    ///
    /// Example:
    /// ```swift
    /// let needsWarning1 = ValidationService.isExtremeBodyFat(2.5)
    /// // Returns: true
    ///
    /// let needsWarning2 = ValidationService.isExtremeBodyFat(55.0)
    /// // Returns: true
    ///
    /// let needsWarning3 = ValidationService.isExtremeBodyFat(18.0)
    /// // Returns: false
    /// ```
    static func isExtremeBodyFat(_ bodyFatPercentage: Double) -> Bool {
        return bodyFatPercentage < Constants.Threshold.BodyFat.extremeLow ||
               bodyFatPercentage > Constants.Threshold.BodyFat.extremeHigh
    }

    /// Checks if weight change is rapid (requires user confirmation)
    ///
    /// 체중 변화가 급격한지 확인합니다 (사용자 확인 필요).
    ///
    /// **Warning Threshold**: ±3 kg or more
    ///
    /// - Parameters:
    ///   - previousWeight: Previous weight in kg
    ///   - currentWeight: Current weight in kg
    /// - Returns: True if change is ±3kg or more, false otherwise
    ///
    /// Example:
    /// ```swift
    /// let needsWarning1 = ValidationService.isRapidWeightChange(previous: 70.0, current: 73.5)
    /// // Returns: true (3.5 kg gain)
    ///
    /// let needsWarning2 = ValidationService.isRapidWeightChange(previous: 70.0, current: 66.5)
    /// // Returns: true (3.5 kg loss)
    ///
    /// let needsWarning3 = ValidationService.isRapidWeightChange(previous: 70.0, current: 71.5)
    /// // Returns: false (1.5 kg change)
    /// ```
    static func isRapidWeightChange(previous previousWeight: Double, current currentWeight: Double) -> Bool {
        let change = abs(currentWeight - previousWeight)
        return change >= Constants.Threshold.WeightChange.rapid
    }

    // MARK: - Exercise & Food Validation

    /// Validates exercise duration in minutes
    ///
    /// 운동 시간(분)을 검증합니다.
    ///
    /// **Validation Rule**: Minimum 1 minute
    ///
    /// - Parameter minutes: Exercise duration in minutes
    /// - Returns: ValidationResult indicating success or failure with error message
    ///
    /// Example:
    /// ```swift
    /// let result1 = ValidationService.validateExerciseDuration(30)
    /// // Returns: .success
    ///
    /// let result2 = ValidationService.validateExerciseDuration(0)
    /// // Returns: .failure("최소 1분 이상 입력해주세요")
    /// ```
    static func validateExerciseDuration(_ minutes: Int) -> ValidationResult {
        guard minutes >= Constants.Validation.Exercise.minDuration else {
            return .failure("최소 1분 이상 입력해주세요")
        }

        return .success
    }

    /// Checks if exercise duration is excessive (requires user confirmation)
    ///
    /// 운동 시간이 과도한지 확인합니다 (사용자 확인 필요).
    ///
    /// **Warning Threshold**: 480 minutes (8 hours) or more
    ///
    /// - Parameter minutes: Exercise duration in minutes
    /// - Returns: True if duration is excessive, false otherwise
    ///
    /// Example:
    /// ```swift
    /// let needsWarning1 = ValidationService.isExcessiveExerciseDuration(480)
    /// // Returns: true
    ///
    /// let needsWarning2 = ValidationService.isExcessiveExerciseDuration(60)
    /// // Returns: false
    /// ```
    static func isExcessiveExerciseDuration(_ minutes: Int) -> Bool {
        return minutes >= Constants.Threshold.Exercise.excessive
    }

    /// Validates food serving size
    ///
    /// 음식 섭취량을 검증합니다.
    ///
    /// **Validation Rule**: Minimum 0.1 (servings or grams)
    ///
    /// - Parameter servingSize: Serving size
    /// - Returns: ValidationResult indicating success or failure with error message
    ///
    /// Example:
    /// ```swift
    /// let result1 = ValidationService.validateServingSize(1.5)
    /// // Returns: .success
    ///
    /// let result2 = ValidationService.validateServingSize(0.0)
    /// // Returns: .failure("최소 0.1 이상 입력해주세요")
    /// ```
    static func validateServingSize(_ servingSize: Double) -> ValidationResult {
        guard servingSize >= Constants.Validation.Serving.min else {
            return .failure("최소 0.1 이상 입력해주세요")
        }

        return .success
    }

    /// Checks if serving size is excessive (requires user confirmation)
    ///
    /// 섭취량이 과도한지 확인합니다 (사용자 확인 필요).
    ///
    /// **Warning Threshold**: 100 servings or more
    ///
    /// - Parameter servingSize: Serving size
    /// - Returns: True if serving size is excessive, false otherwise
    ///
    /// Example:
    /// ```swift
    /// let needsWarning1 = ValidationService.isExcessiveServingSize(100)
    /// // Returns: true
    ///
    /// let needsWarning2 = ValidationService.isExcessiveServingSize(2.5)
    /// // Returns: false
    /// ```
    static func isExcessiveServingSize(_ servingSize: Double) -> Bool {
        return servingSize >= Constants.Threshold.Serving.excessive
    }
}
