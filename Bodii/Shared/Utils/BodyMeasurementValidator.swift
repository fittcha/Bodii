//
//  BodyMeasurementValidator.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-12.
//

// 📚 학습 포인트: Validation Utility Pattern
// 입력 검증 로직을 중앙화하여 코드 중복을 제거하고 일관성 확보
// 💡 Java 비교: Validator 클래스 또는 Bean Validation과 유사

import Foundation

// MARK: - BodyMeasurementValidator

/// 신체 측정값 검증 유틸리티
/// 체중, 체지방률, 근육량, 신장 등의 유효성을 검증합니다.
/// 📚 학습 포인트: Domain Validation
/// - 도메인 규칙을 한 곳에서 관리하여 일관성 유지
/// - 각 측정값의 허용 범위를 명확히 정의
/// - 사용자 친화적인 에러 메시지 제공
/// 💡 Java 비교: javax.validation 또는 custom Validator와 유사
struct BodyMeasurementValidator {

    // MARK: - Validation Ranges

    /// 체중 유효 범위 (kg)
    /// 📚 학습 포인트: Domain Constants
    /// 비즈니스 규칙을 상수로 명시하여 가독성 향상
    static let weightRange: ClosedRange<Decimal> = 20...200

    /// 체지방률 유효 범위 (%)
    /// 📚 학습 포인트: Percentage Range
    /// 1-60%는 극단적인 케이스를 포함한 넓은 범위
    /// - 1-3%: 필수 지방 (Essential fat)
    /// - 60%: 극도 비만 상태
    static let bodyFatPercentRange: ClosedRange<Decimal> = 1...60

    /// 근육량 유효 범위 (kg)
    /// 📚 학습 포인트: Muscle Mass Range
    /// 10-100kg는 성인의 일반적인 근육량 범위
    /// - 10kg: 최소 근육량 (심각한 근감소증 상태)
    /// - 100kg: 엘리트 보디빌더 수준
    static let muscleMassRange: ClosedRange<Decimal> = 10...100

    /// 신장 유효 범위 (cm)
    /// 📚 학습 포인트: Height Range
    /// 50-300cm는 성인과 아동을 모두 포함하는 범위
    /// - 50cm: 유아 신장
    /// - 300cm: 기록된 최장신 인간보다 높은 값
    static let heightRange: ClosedRange<Decimal> = 50...300

    // MARK: - Error Types

    /// 측정값 검증 에러
    /// 📚 학습 포인트: Custom Error Type
    /// Swift의 Error 프로토콜을 conform하여 throw 가능한 타입 정의
    /// 💡 Java 비교: Custom Exception과 유사
    enum ValidationError: Error, LocalizedError {
        /// 체중이 유효 범위를 벗어남
        case invalidWeight(Decimal)

        /// 체지방률이 유효 범위를 벗어남
        case invalidBodyFatPercent(Decimal)

        /// 근육량이 유효 범위를 벗어남
        case invalidMuscleMass(Decimal)

        /// 신장이 유효 범위를 벗어남
        case invalidHeight(Decimal)

        /// 근육량이 체중보다 크거나 같음 (논리적 오류)
        case muscleMassExceedsWeight(muscleMass: Decimal, weight: Decimal)

        /// 나이가 유효하지 않음
        case invalidAge(Int)

        /// 에러 설명 (사용자에게 표시할 메시지)
        /// 📚 학습 포인트: LocalizedError Protocol
        /// errorDescription을 구현하여 사용자 친화적인 에러 메시지 제공 (한국어)
        var errorDescription: String? {
            switch self {
            case .invalidWeight(let value):
                return "체중은 \(Self.formatRange(weightRange)) kg 범위여야 합니다. (입력값: \(Self.formatDecimal(value)) kg)"

            case .invalidBodyFatPercent(let value):
                return "체지방률은 \(Self.formatRange(bodyFatPercentRange))% 범위여야 합니다. (입력값: \(Self.formatDecimal(value))%)"

            case .invalidMuscleMass(let value):
                return "근육량은 \(Self.formatRange(muscleMassRange)) kg 범위여야 합니다. (입력값: \(Self.formatDecimal(value)) kg)"

            case .invalidHeight(let value):
                return "신장은 \(Self.formatRange(heightRange)) cm 범위여야 합니다. (입력값: \(Self.formatDecimal(value)) cm)"

            case .muscleMassExceedsWeight(let muscleMass, let weight):
                return "근육량(\(Self.formatDecimal(muscleMass)) kg)은 체중(\(Self.formatDecimal(weight)) kg)보다 작아야 합니다."

            case .invalidAge(let value):
                return "나이는 1세 이상이어야 합니다. (입력값: \(value)세)"
            }
        }

        // MARK: - Helper Methods

        /// 범위를 포맷된 문자열로 변환
        /// 📚 학습 포인트: Private Helper
        /// 에러 메시지 생성을 위한 내부 헬퍼 메서드
        private static func formatRange(_ range: ClosedRange<Decimal>) -> String {
            return "\(formatDecimal(range.lowerBound))-\(formatDecimal(range.upperBound))"
        }

        /// Decimal을 포맷된 문자열로 변환
        /// 📚 학습 포인트: Number Formatting
        /// 소수점 1자리까지 표시
        private static func formatDecimal(_ value: Decimal) -> String {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.minimumFractionDigits = 0
            formatter.maximumFractionDigits = 1
            return formatter.string(from: NSDecimalNumber(decimal: value)) ?? "\(value)"
        }
    }

    // MARK: - Validation Result

    /// 검증 결과를 나타내는 타입
    /// 📚 학습 포인트: Result Type
    /// 성공/실패를 명시적으로 표현하고 상세한 정보 제공
    /// 💡 Java 비교: Optional<ValidationResult> 또는 Either<Error, Success>와 유사
    struct ValidationResult {
        /// 검증 성공 여부
        let isValid: Bool

        /// 검증 실패 시 에러 메시지 목록
        /// 📚 학습 포인트: Multiple Error Messages
        /// 모든 검증 오류를 한 번에 수집하여 사용자에게 표시
        let errorMessages: [String]

        /// 검증 성공 시 사용하는 생성자
        /// 📚 학습 포인트: Factory Method Pattern
        static var valid: ValidationResult {
            return ValidationResult(isValid: true, errorMessages: [])
        }

        /// 검증 실패 시 사용하는 생성자
        /// 📚 학습 포인트: Factory Method with Parameters
        static func invalid(errors: [String]) -> ValidationResult {
            return ValidationResult(isValid: false, errorMessages: errors)
        }
    }

    // MARK: - Individual Validation Methods

    /// 체중 검증
    /// 📚 학습 포인트: Single Responsibility
    /// 각 측정값마다 독립적인 검증 메서드 제공
    /// - Parameter weight: 체중 (kg)
    /// - Returns: 유효하면 true, 그렇지 않으면 false
    /// - Throws: ValidationError.invalidWeight
    static func validateWeight(_ weight: Decimal) throws {
        guard weightRange.contains(weight) else {
            throw ValidationError.invalidWeight(weight)
        }
    }

    /// 체지방률 검증
    /// - Parameter bodyFatPercent: 체지방률 (%)
    /// - Returns: 유효하면 true, 그렇지 않으면 false
    /// - Throws: ValidationError.invalidBodyFatPercent
    static func validateBodyFatPercent(_ bodyFatPercent: Decimal) throws {
        guard bodyFatPercentRange.contains(bodyFatPercent) else {
            throw ValidationError.invalidBodyFatPercent(bodyFatPercent)
        }
    }

    /// 근육량 검증
    /// - Parameter muscleMass: 근육량 (kg)
    /// - Returns: 유효하면 true, 그렇지 않으면 false
    /// - Throws: ValidationError.invalidMuscleMass
    static func validateMuscleMass(_ muscleMass: Decimal) throws {
        guard muscleMassRange.contains(muscleMass) else {
            throw ValidationError.invalidMuscleMass(muscleMass)
        }
    }

    /// 신장 검증
    /// - Parameter height: 신장 (cm)
    /// - Returns: 유효하면 true, 그렇지 않으면 false
    /// - Throws: ValidationError.invalidHeight
    static func validateHeight(_ height: Decimal) throws {
        guard heightRange.contains(height) else {
            throw ValidationError.invalidHeight(height)
        }
    }

    /// 나이 검증
    /// - Parameter age: 나이 (years)
    /// - Returns: 유효하면 true, 그렇지 않으면 false
    /// - Throws: ValidationError.invalidAge
    static func validateAge(_ age: Int) throws {
        guard age > 0 else {
            throw ValidationError.invalidAge(age)
        }
    }

    /// 근육량과 체중의 논리적 관계 검증
    /// 📚 학습 포인트: Cross-Field Validation
    /// 여러 필드 간의 논리적 관계를 검증
    /// 💡 Java 비교: @AssertTrue 커스텀 검증 메서드와 유사
    /// - Parameters:
    ///   - muscleMass: 근육량 (kg)
    ///   - weight: 체중 (kg)
    /// - Throws: ValidationError.muscleMassExceedsWeight
    static func validateMuscleMassRelativeToWeight(muscleMass: Decimal, weight: Decimal) throws {
        guard muscleMass < weight else {
            throw ValidationError.muscleMassExceedsWeight(muscleMass: muscleMass, weight: weight)
        }
    }

    // MARK: - Combined Validation Methods

    /// 신체 구성 데이터 전체 검증
    /// 📚 학습 포인트: Composite Validation
    /// 모든 개별 검증을 조합하여 전체 데이터 검증
    /// 💡 Java 비교: @Valid annotation과 유사한 역할
    ///
    /// - Parameters:
    ///   - weight: 체중 (kg)
    ///   - bodyFatPercent: 체지방률 (%)
    ///   - muscleMass: 근육량 (kg)
    /// - Throws: ValidationError - 검증 실패 시 첫 번째 에러 throw
    static func validateBodyComposition(
        weight: Decimal,
        bodyFatPercent: Decimal,
        muscleMass: Decimal
    ) throws {
        // 📚 학습 포인트: Sequential Validation
        // 각 검증을 순차적으로 수행하고 첫 번째 에러에서 중단
        try validateWeight(weight)
        try validateBodyFatPercent(bodyFatPercent)
        try validateMuscleMass(muscleMass)
        try validateMuscleMassRelativeToWeight(muscleMass: muscleMass, weight: weight)
    }

    /// 신체 구성 데이터 전체 검증 (모든 에러 수집)
    /// 📚 학습 포인트: Collecting All Errors
    /// 첫 번째 에러에서 중단하지 않고 모든 검증 오류를 수집
    /// 사용자에게 한 번에 모든 문제점을 알려줄 수 있음
    /// 💡 사용처: UI에서 모든 에러 메시지를 한 번에 표시할 때
    ///
    /// - Parameters:
    ///   - weight: 체중 (kg)
    ///   - bodyFatPercent: 체지방률 (%)
    ///   - muscleMass: 근육량 (kg)
    /// - Returns: ValidationResult - 모든 검증 결과와 에러 메시지 목록
    static func validateBodyCompositionCollectingErrors(
        weight: Decimal,
        bodyFatPercent: Decimal,
        muscleMass: Decimal
    ) -> ValidationResult {
        var errors: [String] = []

        // 📚 학습 포인트: Error Collection Pattern
        // 각 검증을 시도하고 실패 시 에러 메시지 수집

        // 체중 검증
        do {
            try validateWeight(weight)
        } catch {
            errors.append(error.localizedDescription)
        }

        // 체지방률 검증
        do {
            try validateBodyFatPercent(bodyFatPercent)
        } catch {
            errors.append(error.localizedDescription)
        }

        // 근육량 검증
        do {
            try validateMuscleMass(muscleMass)
        } catch {
            errors.append(error.localizedDescription)
        }

        // 근육량-체중 관계 검증
        do {
            try validateMuscleMassRelativeToWeight(muscleMass: muscleMass, weight: weight)
        } catch {
            errors.append(error.localizedDescription)
        }

        // 결과 반환
        if errors.isEmpty {
            return .valid
        } else {
            return .invalid(errors: errors)
        }
    }

    /// 사용자 프로필 데이터 검증
    /// 📚 학습 포인트: Profile Validation
    /// BMR 계산에 필요한 사용자 정보 검증
    ///
    /// - Parameters:
    ///   - height: 신장 (cm)
    ///   - age: 나이 (years)
    /// - Throws: ValidationError - 검증 실패 시
    static func validateUserProfile(height: Decimal, age: Int) throws {
        try validateHeight(height)
        try validateAge(age)
    }

    // MARK: - Convenience Methods

    /// String 입력값을 검증
    /// 📚 학습 포인트: String to Decimal Validation
    /// UI에서 입력받은 문자열을 Decimal로 변환하면서 검증
    /// 💡 사용처: TextField에서 입력받은 값을 검증할 때
    ///
    /// - Parameters:
    ///   - weightString: 체중 문자열
    ///   - bodyFatPercentString: 체지방률 문자열
    ///   - muscleMassString: 근육량 문자열
    /// - Returns: ValidationResult - 검증 결과
    static func validateBodyCompositionStrings(
        weightString: String,
        bodyFatPercentString: String,
        muscleMassString: String
    ) -> ValidationResult {
        var errors: [String] = []

        // 📚 학습 포인트: String to Decimal Conversion
        // Decimal(string:) 이니셜라이저는 실패할 수 있으므로 옵셔널 반환

        // 체중 변환 및 검증
        guard let weight = Decimal(string: weightString) else {
            errors.append("체중은 유효한 숫자여야 합니다.")
            return .invalid(errors: errors)
        }

        // 체지방률 변환 및 검증
        guard let bodyFatPercent = Decimal(string: bodyFatPercentString) else {
            errors.append("체지방률은 유효한 숫자여야 합니다.")
            return .invalid(errors: errors)
        }

        // 근육량 변환 및 검증
        guard let muscleMass = Decimal(string: muscleMassString) else {
            errors.append("근육량은 유효한 숫자여야 합니다.")
            return .invalid(errors: errors)
        }

        // 변환된 값으로 검증 수행
        return validateBodyCompositionCollectingErrors(
            weight: weight,
            bodyFatPercent: bodyFatPercent,
            muscleMass: muscleMass
        )
    }

    /// 체중과 체지방률로부터 체지방량 검증
    /// 📚 학습 포인트: Derived Value Validation
    /// 계산된 값이 합리적인 범위인지 검증
    ///
    /// - Parameters:
    ///   - weight: 체중 (kg)
    ///   - bodyFatPercent: 체지방률 (%)
    /// - Returns: 체지방량 (kg)
    /// - Throws: ValidationError - 입력값이 유효하지 않을 때
    static func calculateAndValidateBodyFatMass(
        weight: Decimal,
        bodyFatPercent: Decimal
    ) throws -> Decimal {
        try validateWeight(weight)
        try validateBodyFatPercent(bodyFatPercent)

        // 📚 학습 포인트: Body Fat Mass Calculation
        // 체지방량 = 체중 × (체지방률 / 100)
        let bodyFatMass = weight * (bodyFatPercent / 100)

        return bodyFatMass
    }
}

// MARK: - Sample Usage

extension BodyMeasurementValidator {
    /// 📚 학습 포인트: Sample Data for Testing
    /// Validator의 사용 예시와 테스트를 위한 샘플 데이터
    /// 💡 Java 비교: JUnit의 @Test fixture와 유사

    /// 유효한 신체 구성 데이터 샘플
    struct SampleValidData {
        static let weight = Decimal(70.5)
        static let bodyFatPercent = Decimal(18.5)
        static let muscleMass = Decimal(32.0)
        static let height = Decimal(175.5)
        static let age = 30
    }

    /// 유효하지 않은 신체 구성 데이터 샘플
    struct SampleInvalidData {
        static let weightTooLow = Decimal(15.0)      // < 20
        static let weightTooHigh = Decimal(600.0)    // > 500
        static let bodyFatTooLow = Decimal(0.5)      // < 1
        static let bodyFatTooHigh = Decimal(70.0)    // > 60
        static let muscleMassTooLow = Decimal(5.0)   // < 10
        static let muscleMassTooHigh = Decimal(150.0) // > 100
        static let heightTooLow = Decimal(30.0)      // < 50
        static let heightTooHigh = Decimal(350.0)    // > 300
        static let ageInvalid = 0                     // <= 0
    }
}

// MARK: - Documentation

/// 📚 학습 포인트: Body Measurement Validation 이해
///
/// 신체 측정값 검증의 중요성:
/// 1. 데이터 무결성: 잘못된 데이터가 시스템에 저장되는 것을 방지
/// 2. 사용자 경험: 입력 오류를 즉시 피드백하여 수정 기회 제공
/// 3. 계산 정확도: BMR/TDEE 계산의 신뢰성 확보
/// 4. 안전성: 극단적인 값으로 인한 계산 오류 방지
///
/// 검증 범위 설정 근거:
///
/// 체중 (20-500 kg):
/// - 하한: 20kg - 소아청소년 최소 체중
/// - 상한: 500kg - 의학적으로 기록된 최대 체중
///
/// 체지방률 (1-60%):
/// - 하한: 1% - 필수 지방 (Essential fat) 이하는 생존 불가능
/// - 상한: 60% - 극도 비만 상태
/// - 건강 범위: 남성 6-24%, 여성 14-31%
///
/// 근육량 (10-100 kg):
/// - 하한: 10kg - 심각한 근감소증 상태
/// - 상한: 100kg - 엘리트 보디빌더 수준
/// - 일반 성인: 남성 35-40kg, 여성 25-30kg
///
/// 신장 (50-300 cm):
/// - 하한: 50cm - 유아 신장
/// - 상한: 300cm - 역사상 최장신 인간(272cm)보다 여유있게 설정
///
/// 논리적 제약:
/// - 근육량 < 체중: 근육은 신체의 일부이므로 전체 체중보다 클 수 없음
///
/// 사용 패턴:
/// 1. Throwing validation: 첫 번째 에러에서 중단, 빠른 검증
/// 2. Collecting validation: 모든 에러 수집, 사용자 친화적
/// 3. String validation: UI 입력값 직접 검증
///
