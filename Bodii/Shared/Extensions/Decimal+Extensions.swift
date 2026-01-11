//
//  Decimal+Extensions.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-11.
//

// 📚 학습 포인트: Decimal Extensions for Core Data
// Core Data의 Decimal 타입을 Swift의 기본 숫자 타입과 쉽게 변환하기 위한 확장
// 💡 Java 비교: BigDecimal과 유사하나, Swift의 Decimal은 값 타입(value type)

import Foundation

// MARK: - Decimal Extensions

/// Decimal 타입 확장
/// - Core Data에서 사용하는 Decimal과 Swift의 Double/Int 간 변환 제공
/// - 소수점 반올림 및 포매팅 기능 포함
///
/// ## Core Data에서 Decimal을 사용하는 이유
/// - 금융/건강 데이터에서 정확한 소수점 계산 필요 (부동소수점 오차 방지)
/// - 예: 체중 67.5kg, 체지방률 18.3% 등
///
/// ## 예시
/// ```swift
/// // Core Data에서 읽은 Decimal을 Double로 변환
/// let weightDecimal: Decimal = bodyRecord.weight // 67.5
/// let weightDouble = weightDecimal.doubleValue // 67.5
///
/// // Double을 Decimal로 변환하여 Core Data에 저장
/// let newWeight = Decimal(double: 68.2)
/// bodyRecord.weight = newWeight
///
/// // 소수점 반올림
/// let rounded = weightDecimal.rounded(scale: 1) // 67.5
///
/// // UI 표시용 문자열 포매팅
/// let display = weightDecimal.formatted(decimalPlaces: 1) // "67.5"
/// ```
extension Decimal {

    // MARK: - Type Conversions

    /// Decimal을 Double로 변환
    ///
    /// ## 사용 시나리오
    /// - Core Data에서 읽은 Decimal 값을 계산에 사용
    /// - UI 차트 라이브러리에 Double 값 전달
    ///
    /// ## 예시
    /// ```swift
    /// let weight: Decimal = 67.5
    /// let weightDouble = weight.doubleValue // 67.5
    /// let bmi = weightDouble / pow(height, 2)
    /// ```
    var doubleValue: Double {
        NSDecimalNumber(decimal: self).doubleValue
    }

    /// Decimal을 Int로 변환 (소수점 버림)
    ///
    /// ## 사용 시나리오
    /// - 칼로리 등 정수로 표시할 값
    /// - UI에서 소수점이 필요 없는 경우
    ///
    /// ## 예시
    /// ```swift
    /// let calories: Decimal = 2156.8
    /// let caloriesInt = calories.intValue // 2156 (소수점 버림)
    ///
    /// let bodyFat: Decimal = 18.3
    /// let bodyFatInt = bodyFat.intValue // 18
    /// ```
    var intValue: Int {
        NSDecimalNumber(decimal: self).intValue
    }

    // MARK: - Initializers

    /// Double 값으로부터 Decimal 생성
    /// - Parameter double: 변환할 Double 값
    ///
    /// ## 사용 시나리오
    /// - UI 입력값(Double)을 Core Data에 저장
    /// - 계산 결과를 Core Data 엔티티에 저장
    ///
    /// ## 예시
    /// ```swift
    /// // UI TextField에서 입력받은 체중
    /// let inputWeight: Double = 67.5
    /// bodyRecord.weight = Decimal(double: inputWeight)
    ///
    /// // 계산된 체지방량을 저장
    /// let bodyFatMass = weight * (bodyFatPercent / 100)
    /// bodyRecord.bodyFatMass = Decimal(double: bodyFatMass)
    /// ```
    init(double: Double) {
        self = NSDecimalNumber(value: double).decimalValue
    }

    // MARK: - Rounding

    /// 지정된 소수점 자리수로 반올림
    /// - Parameter scale: 소수점 이하 자리수 (기본값: 2)
    /// - Returns: 반올림된 Decimal
    ///
    /// ## 반올림 규칙
    /// - NSDecimalNumberHandler의 기본 동작: plain (사사오입)
    /// - 예: 67.45 → 67.5 (scale: 1)
    /// - 예: 67.44 → 67.4 (scale: 1)
    ///
    /// ## 예시
    /// ```swift
    /// let weight = Decimal(double: 67.456)
    /// let rounded1 = weight.rounded(scale: 1) // 67.5
    /// let rounded2 = weight.rounded(scale: 2) // 67.46
    ///
    /// let bodyFat = Decimal(double: 18.347)
    /// let displayed = bodyFat.rounded(scale: 1) // 18.3
    /// ```
    func rounded(scale: Int16 = 2) -> Decimal {
        var result = self
        var rounded = Decimal()
        NSDecimalRound(&rounded, &result, Int(scale), .plain)
        return rounded
    }

    // MARK: - Formatting

    /// UI 표시용 문자열로 포맷 (소수점 자리수 지정)
    /// - Parameter decimalPlaces: 소수점 이하 자리수 (기본값: 1)
    /// - Returns: 포맷된 문자열
    ///
    /// ## 동작 방식
    /// - 지정된 자리수로 반올림 후 문자열 변환
    /// - 천 단위 구분 기호 없음 (순수 숫자만)
    /// - 음수는 "-" 기호 포함
    ///
    /// ## 예시
    /// ```swift
    /// let weight = Decimal(double: 67.5)
    /// let weightStr = weight.formatted(decimalPlaces: 1) // "67.5"
    ///
    /// let bodyFat = Decimal(double: 18.347)
    /// let bodyFatStr = bodyFat.formatted(decimalPlaces: 1) // "18.3"
    ///
    /// let calories = Decimal(double: 2156.8)
    /// let caloriesStr = calories.formatted(decimalPlaces: 0) // "2157"
    ///
    /// // UI 레이블에 사용
    /// weightLabel.text = "\(weight.formatted(decimalPlaces: 1))kg"
    /// bodyFatLabel.text = "\(bodyFat.formatted(decimalPlaces: 1))%"
    /// ```
    func formatted(decimalPlaces: Int = 1) -> String {
        let rounded = self.rounded(scale: Int16(decimalPlaces))
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = decimalPlaces
        formatter.maximumFractionDigits = decimalPlaces
        formatter.groupingSeparator = "" // 천 단위 구분 기호 없음

        return formatter.string(from: NSDecimalNumber(decimal: rounded)) ?? "0"
    }
}
