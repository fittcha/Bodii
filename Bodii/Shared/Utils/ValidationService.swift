//
//  ValidationService.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-11.
//

// 📚 학습 포인트: Input Validation Service
// Swift의 Result 패턴과 유사하게 ValidationResult 구조체로 성공/실패 반환
// 💡 Java 비교: Bean Validation과 유사하지만 Swift는 타입 안전성이 더 강함

import Foundation

// MARK: - ValidationResult

/// 검증 결과를 담는 구조체
/// - isValid: 검증 통과 여부
/// - errorMessage: 실패 시 사용자에게 표시할 한국어 오류 메시지
///
/// ## 예시
/// ```swift
/// let result = ValidationService.validateHeight(180)
/// if result.isValid {
///     print("유효한 키입니다")
/// } else {
///     print(result.errorMessage ?? "")
/// }
/// ```
struct ValidationResult {
    /// 검증 통과 여부
    let isValid: Bool

    /// 오류 메시지 (실패 시에만 존재)
    let errorMessage: String?

    /// 성공 결과 생성
    static var success: ValidationResult {
        ValidationResult(isValid: true, errorMessage: nil)
    }

    /// 실패 결과 생성
    /// - Parameter message: 한국어 오류 메시지
    /// - Returns: 실패 결과
    static func failure(_ message: String) -> ValidationResult {
        ValidationResult(isValid: false, errorMessage: message)
    }
}

// MARK: - ValidationService

/// 사용자 입력 검증 서비스
/// - 모든 입력값의 유효 범위 검증
/// - Constants.Validation에 정의된 범위 사용
/// - 한국어 오류 메시지 제공
///
/// ## 검증 항목
/// - 신체 정보: 키, 체중, 체지방률, 근육량
/// - 사용자 정보: 이름, 생년
/// - 운동 정보: 운동 시간
/// - 음식 정보: 섭취량 (인분/그램)
///
/// ## 예시
/// ```swift
/// // 키 검증
/// let heightResult = ValidationService.validateHeight(175.5)
/// if !heightResult.isValid {
///     showError(heightResult.errorMessage ?? "")
/// }
///
/// // 체중 검증
/// let weightResult = ValidationService.validateWeight(70.0)
///
/// // 이름 검증
/// let nameResult = ValidationService.validateName("홍길동")
/// ```
enum ValidationService {

    // MARK: - Body Measurements

    /// 키 검증 (100-250cm)
    /// - Parameter height: 검증할 키 값 (cm)
    /// - Returns: 검증 결과
    ///
    /// ## 유효 범위
    /// - 최소: 100cm
    /// - 최대: 250cm
    ///
    /// ## 예시
    /// ```swift
    /// ValidationService.validateHeight(99)   // 실패: "키는 100cm에서 250cm 사이여야 합니다"
    /// ValidationService.validateHeight(175)  // 성공
    /// ValidationService.validateHeight(251)  // 실패
    /// ```
    static func validateHeight(_ height: Double) -> ValidationResult {
        guard height >= Constants.Validation.Height.min,
              height <= Constants.Validation.Height.max else {
            return .failure("키는 \(Int(Constants.Validation.Height.min))cm에서 \(Int(Constants.Validation.Height.max))cm 사이여야 합니다")
        }
        return .success
    }

    /// 체중 검증 (20-300kg)
    /// - Parameter weight: 검증할 체중 값 (kg)
    /// - Returns: 검증 결과
    ///
    /// ## 유효 범위
    /// - 최소: 20kg
    /// - 최대: 300kg
    ///
    /// ## 예시
    /// ```swift
    /// ValidationService.validateWeight(19)   // 실패: "체중은 20kg에서 300kg 사이여야 합니다"
    /// ValidationService.validateWeight(70)   // 성공
    /// ValidationService.validateWeight(301)  // 실패
    /// ```
    static func validateWeight(_ weight: Double) -> ValidationResult {
        guard weight >= Constants.Validation.Weight.min,
              weight <= Constants.Validation.Weight.max else {
            return .failure("체중은 \(Int(Constants.Validation.Weight.min))kg에서 \(Int(Constants.Validation.Weight.max))kg 사이여야 합니다")
        }
        return .success
    }

    /// 체지방률 검증 (3-60%)
    /// - Parameter bodyFatPercent: 검증할 체지방률 값 (%)
    /// - Returns: 검증 결과
    ///
    /// ## 유효 범위
    /// - 최소: 3%
    /// - 최대: 60%
    ///
    /// ## 예시
    /// ```swift
    /// ValidationService.validateBodyFatPercent(2)   // 실패: "체지방률은 3%에서 60% 사이여야 합니다"
    /// ValidationService.validateBodyFatPercent(15)  // 성공
    /// ValidationService.validateBodyFatPercent(61)  // 실패
    /// ```
    static func validateBodyFatPercent(_ bodyFatPercent: Double) -> ValidationResult {
        guard bodyFatPercent >= Constants.Validation.BodyFatPercent.min,
              bodyFatPercent <= Constants.Validation.BodyFatPercent.max else {
            return .failure("체지방률은 \(Int(Constants.Validation.BodyFatPercent.min))%에서 \(Int(Constants.Validation.BodyFatPercent.max))% 사이여야 합니다")
        }
        return .success
    }

    /// 근육량 검증 (10-60kg)
    /// - Parameter muscleMass: 검증할 근육량 값 (kg)
    /// - Returns: 검증 결과
    ///
    /// ## 유효 범위
    /// - 최소: 10kg
    /// - 최대: 60kg
    ///
    /// ## 예시
    /// ```swift
    /// ValidationService.validateMuscleMass(9)   // 실패: "근육량은 10kg에서 60kg 사이여야 합니다"
    /// ValidationService.validateMuscleMass(30)  // 성공
    /// ValidationService.validateMuscleMass(61)  // 실패
    /// ```
    static func validateMuscleMass(_ muscleMass: Double) -> ValidationResult {
        guard muscleMass >= Constants.Validation.MuscleMass.min,
              muscleMass <= Constants.Validation.MuscleMass.max else {
            return .failure("근육량은 \(Int(Constants.Validation.MuscleMass.min))kg에서 \(Int(Constants.Validation.MuscleMass.max))kg 사이여야 합니다")
        }
        return .success
    }

    // MARK: - User Profile

    /// 나이 검증 (생년 기준: 1900년 ~ 현재 연도)
    /// - Parameter birthYear: 검증할 출생 연도
    /// - Returns: 검증 결과
    ///
    /// ## 유효 범위
    /// - 최소: 1900년
    /// - 최대: 현재 연도
    ///
    /// ## 예시
    /// ```swift
    /// ValidationService.validateAge(1899)  // 실패: "출생 연도는 1900년에서 2026년 사이여야 합니다"
    /// ValidationService.validateAge(1990)  // 성공
    /// ValidationService.validateAge(2027)  // 실패
    /// ```
    static func validateAge(_ birthYear: Int) -> ValidationResult {
        let currentYear = Constants.Validation.BirthYear.max
        guard birthYear >= Constants.Validation.BirthYear.min,
              birthYear <= currentYear else {
            return .failure("출생 연도는 \(Constants.Validation.BirthYear.min)년에서 \(currentYear)년 사이여야 합니다")
        }
        return .success
    }

    /// 이름 검증 (1-20자, 공백 불가)
    /// - Parameter name: 검증할 이름
    /// - Returns: 검증 결과
    ///
    /// ## 유효 조건
    /// - 길이: 1-20자
    /// - 공백 제거 후 비어있지 않음
    ///
    /// ## 예시
    /// ```swift
    /// ValidationService.validateName("")            // 실패: "이름을 입력해주세요"
    /// ValidationService.validateName("   ")         // 실패: "이름을 입력해주세요"
    /// ValidationService.validateName("홍길동")      // 성공
    /// ValidationService.validateName("a")           // 성공
    /// ValidationService.validateName("매우긴이름123456789012") // 실패: "이름은 1자에서 20자 사이여야 합니다"
    /// ```
    static func validateName(_ name: String) -> ValidationResult {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        // 빈 문자열 검사
        guard !trimmedName.isEmpty else {
            return .failure("이름을 입력해주세요")
        }

        // 길이 검사
        guard trimmedName.count >= Constants.Validation.Name.minLength,
              trimmedName.count <= Constants.Validation.Name.maxLength else {
            return .failure("이름은 \(Constants.Validation.Name.minLength)자에서 \(Constants.Validation.Name.maxLength)자 사이여야 합니다")
        }

        return .success
    }

    // MARK: - Exercise

    /// 운동 시간 검증 (1-480분)
    /// - Parameter duration: 검증할 운동 시간 (분)
    /// - Returns: 검증 결과
    ///
    /// ## 유효 범위
    /// - 최소: 1분
    /// - 최대: 480분 (8시간)
    ///
    /// ## 예시
    /// ```swift
    /// ValidationService.validateExerciseDuration(0)    // 실패: "운동 시간은 1분에서 480분 사이여야 합니다"
    /// ValidationService.validateExerciseDuration(30)   // 성공
    /// ValidationService.validateExerciseDuration(481)  // 실패
    /// ```
    static func validateExerciseDuration(_ duration: Int) -> ValidationResult {
        guard duration >= Constants.Validation.ExerciseDuration.min,
              duration <= Constants.Validation.ExerciseDuration.max else {
            return .failure("운동 시간은 \(Constants.Validation.ExerciseDuration.min)분에서 \(Constants.Validation.ExerciseDuration.max)분 사이여야 합니다")
        }
        return .success
    }

    // MARK: - Food

    /// 음식 섭취량 검증 (단위에 따라 다른 범위 적용)
    /// - Parameters:
    ///   - quantity: 검증할 섭취량
    ///   - unit: 섭취량 단위 (serving: 0.1-100, gram: 1-10000)
    /// - Returns: 검증 결과
    ///
    /// ## 유효 범위
    /// - 인분(serving): 0.1 ~ 100인분
    /// - 그램(gram): 1 ~ 10,000g
    ///
    /// ## 예시
    /// ```swift
    /// // 인분 단위
    /// ValidationService.validateFoodQuantity(0.05, unit: .serving)  // 실패: "섭취량은 0.1인분에서 100인분 사이여야 합니다"
    /// ValidationService.validateFoodQuantity(1.5, unit: .serving)   // 성공
    /// ValidationService.validateFoodQuantity(101, unit: .serving)   // 실패
    ///
    /// // 그램 단위
    /// ValidationService.validateFoodQuantity(0.5, unit: .gram)      // 실패: "섭취량은 1g에서 10000g 사이여야 합니다"
    /// ValidationService.validateFoodQuantity(200, unit: .gram)      // 성공
    /// ValidationService.validateFoodQuantity(10001, unit: .gram)    // 실패
    /// ```
    static func validateFoodQuantity(_ quantity: Double, unit: QuantityUnit) -> ValidationResult {
        switch unit {
        case .serving:
            guard quantity >= Constants.Validation.ServingQuantity.min,
                  quantity <= Constants.Validation.ServingQuantity.max else {
                // 인분은 소수점이 있으므로 Double로 표시
                return .failure("섭취량은 \(Constants.Validation.ServingQuantity.min)인분에서 \(Int(Constants.Validation.ServingQuantity.max))인분 사이여야 합니다")
            }
            return .success

        case .gram:
            guard quantity >= Constants.Validation.GramQuantity.min,
                  quantity <= Constants.Validation.GramQuantity.max else {
                return .failure("섭취량은 \(Int(Constants.Validation.GramQuantity.min))g에서 \(Int(Constants.Validation.GramQuantity.max))g 사이여야 합니다")
            }
            return .success
        }
    }

    // MARK: - Composite Validations

    /// 체성분 일관성 검증
    /// - Parameters:
    ///   - weight: 체중 (kg)
    ///   - bodyFatPercent: 체지방률 (%)
    ///   - muscleMass: 근육량 (kg)
    /// - Returns: 검증 결과
    ///
    /// ## 검증 로직
    /// 1. 제지방량 = 체중 × (1 - 체지방률/100)
    /// 2. 제지방량 ≥ 근육량 검증
    ///
    /// ## 예시
    /// ```swift
    /// // 체중 70kg, 체지방률 15%, 근육량 50kg
    /// // 제지방량 = 70 × (1 - 0.15) = 59.5kg
    /// // 59.5kg ≥ 50kg → 성공
    /// ValidationService.validateBodyComposition(weight: 70, bodyFatPercent: 15, muscleMass: 50)
    ///
    /// // 체중 70kg, 체지방률 15%, 근육량 65kg
    /// // 제지방량 = 59.5kg
    /// // 59.5kg < 65kg → 실패
    /// ValidationService.validateBodyComposition(weight: 70, bodyFatPercent: 15, muscleMass: 65)
    /// ```
    static func validateBodyComposition(weight: Double, bodyFatPercent: Double, muscleMass: Double) -> ValidationResult {
        // 제지방량 계산
        let leanBodyMass = weight * (1.0 - bodyFatPercent / 100.0)

        // 근육량은 제지방량을 초과할 수 없음
        guard muscleMass <= leanBodyMass else {
            return .failure("근육량은 제지방량(\(String(format: "%.1f", leanBodyMass))kg)을 초과할 수 없습니다")
        }

        return .success
    }
}
