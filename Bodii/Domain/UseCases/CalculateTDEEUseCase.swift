//
//  CalculateTDEEUseCase.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-12.
//

// 📚 학습 포인트: Use Case Pattern
// 단일 비즈니스 로직을 캡슐화하는 Use Case 패턴
// 💡 Java 비교: Service layer의 단일 메서드와 유사하지만 더 세분화됨

import Foundation

// MARK: - CalculateTDEEUseCase

/// TDEE(Total Daily Energy Expenditure) 계산 Use Case
/// BMR에 활동 수준 계수를 곱하여 하루 총 에너지 소비량을 계산합니다.
/// 📚 학습 포인트: Clean Architecture - Use Case Layer
/// - 특정 비즈니스 로직(TDEE 계산)을 독립적인 유닛으로 캡슐화
/// - UI나 데이터베이스에 의존하지 않는 순수한 비즈니스 로직
/// - 재사용 가능하고 테스트하기 쉬운 구조
/// 💡 Java 비교: Interactor 또는 Service 클래스의 단일 책임 메서드
struct CalculateTDEEUseCase {

    // MARK: - Types

    /// TDEE 계산에 필요한 입력 데이터
    /// 📚 학습 포인트: Nested Type
    /// - Use Case 내부에 관련된 타입을 중첩하여 네임스페이스 정리
    /// - 외부에서는 CalculateTDEEUseCase.Input으로 접근
    /// 💡 Java 비교: static nested class와 유사
    struct Input {
        /// 기초대사량 (kcal/day)
        /// 📚 학습 포인트: Decimal for Precision
        /// 부동소수점 오차를 방지하기 위해 Decimal 사용
        let bmr: Decimal

        /// 활동 수준
        /// TDEE 계산을 위한 활동 계수를 가진 enum
        let activityLevel: ActivityLevel

        /// Input 유효성 검증
        /// 📚 학습 포인트: Validation in Domain Layer
        /// 비즈니스 규칙 검증을 도메인 레이어에서 처리
        /// - Returns: 유효하면 true, 그렇지 않으면 false
        var isValid: Bool {
            bmr > 0
        }
    }

    /// TDEE 계산 결과
    /// 📚 학습 포인트: Result Type
    /// 성공/실패를 명시적으로 표현하는 타입
    /// 💡 Java 비교: Optional이나 Result<T, E>와 유사
    struct Output {
        /// 계산된 TDEE 값 (kcal/day)
        /// 📚 학습 포인트: Decimal Type
        /// 칼로리 계산은 정밀도가 중요하므로 Decimal 사용
        let tdee: Decimal

        /// TDEE를 반올림하여 표시용 정수로 변환
        /// 📚 학습 포인트: Computed Property
        /// UI에서 표시할 때는 소수점이 필요없으므로 반올림
        /// 💡 Java 비교: getter 메서드와 유사
        var roundedTDEE: Int {
            return NSDecimalNumber(decimal: tdee).rounding(accordingToBehavior: nil).intValue
        }

        /// 포맷된 TDEE 문자열 (예: "2,165 kcal/day")
        /// 📚 학습 포인트: String Formatting
        /// UI 표시를 위한 편의 메서드
        /// - Returns: 쉼표로 구분된 TDEE 문자열
        func formatted() -> String {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = 0

            let tdeeString = formatter.string(from: NSDecimalNumber(decimal: tdee)) ?? "\(roundedTDEE)"
            return "\(tdeeString) kcal/day"
        }
    }

    // MARK: - Error

    /// TDEE 계산 중 발생할 수 있는 에러
    /// 📚 학습 포인트: Custom Error Type
    /// Swift의 Error 프로토콜을 conform하여 throw 가능한 타입 정의
    /// 💡 Java 비교: Custom Exception과 유사
    enum TDEEError: Error, LocalizedError {
        /// 유효하지 않은 입력 값
        case invalidInput

        /// 계산 중 발생한 에러
        case calculationError

        /// 에러 설명 (사용자에게 표시할 메시지)
        /// 📚 학습 포인트: LocalizedError Protocol
        /// errorDescription을 구현하여 사용자 친화적인 에러 메시지 제공
        var errorDescription: String? {
            switch self {
            case .invalidInput:
                return "Invalid input values. BMR must be greater than 0."
            case .calculationError:
                return "An error occurred during TDEE calculation."
            }
        }
    }

    // MARK: - Initialization

    /// Use Case 초기화
    /// 📚 학습 포인트: Stateless Use Case
    /// 이 Use Case는 상태를 갖지 않으므로 별도 초기화 불필요
    /// 그러나 명시적으로 init을 제공하여 향후 의존성 주입 가능
    init() {}

    // MARK: - Execute

    /// TDEE 계산 실행
    /// 📚 학습 포인트: TDEE Calculation Formula
    /// TDEE = BMR × Activity Level Multiplier
    ///
    /// 활동 수준별 계수:
    /// - Sedentary (거의 운동하지 않음): 1.2
    /// - Lightly Active (주 1-3일 가벼운 운동): 1.375
    /// - Moderately Active (주 3-5일 중간 강도 운동): 1.55
    /// - Very Active (주 6-7일 강한 운동): 1.725
    /// - Extra Active (하루 2회 이상 매우 강한 운동): 1.9
    ///
    /// 단위:
    /// - BMR: kcal/day
    /// - TDEE: kcal/day
    ///
    /// 📚 학습 포인트: Throws
    /// Swift의 에러 처리 메커니즘 - 에러를 throw할 수 있는 함수
    /// 💡 Java 비교: throws Exception과 유사하지만 더 타입 안전
    ///
    /// - Parameter input: TDEE 계산에 필요한 입력 데이터
    /// - Returns: 계산된 TDEE 결과
    /// - Throws: TDEEError - 입력값이 유효하지 않거나 계산 중 에러 발생 시
    func execute(input: Input) throws -> Output {
        // 📚 학습 포인트: Guard Statement
        // 조건이 false일 때 early return
        // 💡 Java 비교: if (!condition) throw와 유사하지만 더 명시적
        guard input.isValid else {
            throw TDEEError.invalidInput
        }

        // 📚 학습 포인트: TDEE Formula Implementation
        // TDEE = BMR × Activity Level Multiplier

        // 활동 계수를 Decimal로 변환
        // 📚 학습 포인트: Type Conversion
        // Double을 Decimal로 변환
        let multiplier = Decimal(input.activityLevel.multiplier)

        // TDEE 계산
        let tdee = input.bmr * multiplier

        // 📚 학습 포인트: Sanity Check
        // 계산된 TDEE가 합리적인 범위인지 확인 (400-10000 kcal/day)
        // 극단적인 값은 입력 오류이거나 계산 오류일 가능성 높음
        guard tdee >= 400 && tdee <= 10000 else {
            throw TDEEError.calculationError
        }

        return Output(tdee: tdee)
    }

    // MARK: - Convenience Methods

    /// BMR과 ActivityLevel을 직접 받는 편의 메서드
    /// 📚 학습 포인트: Convenience Method
    /// 개별 파라미터를 받아서 Input으로 변환하는 헬퍼 메서드
    /// 💡 사용처: ViewModel이나 다른 Use Case에서 쉽게 호출 가능
    ///
    /// - Parameters:
    ///   - bmr: 기초대사량 (kcal/day)
    ///   - activityLevel: 활동 수준
    /// - Returns: 계산된 TDEE 결과
    /// - Throws: TDEEError
    func execute(bmr: Decimal, activityLevel: ActivityLevel) throws -> Output {
        let input = Input(bmr: bmr, activityLevel: activityLevel)
        return try execute(input: input)
    }

    /// BMR Output과 ActivityLevel을 받는 편의 메서드
    /// 📚 학습 포인트: Use Case Composition
    /// CalculateBMRUseCase의 결과를 직접 받아서 TDEE 계산
    /// 💡 사용처: BMR 계산 후 바로 TDEE 계산할 때 유용
    ///
    /// - Parameters:
    ///   - bmrOutput: CalculateBMRUseCase의 계산 결과
    ///   - activityLevel: 활동 수준
    /// - Returns: 계산된 TDEE 결과
    /// - Throws: TDEEError
    func execute(bmrOutput: CalculateBMRUseCase.Output, activityLevel: ActivityLevel) throws -> Output {
        let input = Input(bmr: bmrOutput.bmr, activityLevel: activityLevel)
        return try execute(input: input)
    }
}

// MARK: - Sample Usage

extension CalculateTDEEUseCase {
    /// 📚 학습 포인트: Sample Data for Testing
    /// Use Case의 사용 예시와 테스트를 위한 샘플 데이터
    /// 💡 Java 비교: JUnit의 @Test fixture와 유사

    /// 샘플 입력 - BMR 1648 kcal/day, 보통 활동 (Moderately Active)
    /// 예상 TDEE: 1648 × 1.55 = 2554.4 kcal/day
    static let sampleInputModerate = Input(
        bmr: Decimal(1648),
        activityLevel: .moderatelyActive
    )

    /// 샘플 입력 - BMR 1276 kcal/day, 가벼운 활동 (Lightly Active)
    /// 예상 TDEE: 1276 × 1.375 = 1754.5 kcal/day
    static let sampleInputLight = Input(
        bmr: Decimal(1276),
        activityLevel: .lightlyActive
    )

    /// 샘플 입력 - BMR 1500 kcal/day, 거의 운동하지 않음 (Sedentary)
    /// 예상 TDEE: 1500 × 1.2 = 1800 kcal/day
    static let sampleInputSedentary = Input(
        bmr: Decimal(1500),
        activityLevel: .sedentary
    )

    /// 샘플 입력 - BMR 2000 kcal/day, 매우 활동적 (Very Active)
    /// 예상 TDEE: 2000 × 1.725 = 3450 kcal/day
    static let sampleInputVeryActive = Input(
        bmr: Decimal(2000),
        activityLevel: .veryActive
    )
}

// MARK: - Documentation

/// 📚 학습 포인트: TDEE (Total Daily Energy Expenditure) 이해
///
/// TDEE란?
/// - 총 일일 에너지 소비량: 하루 동안 소비하는 전체 칼로리
/// - BMR(기초대사량) + 활동을 통한 칼로리 소비
/// - 체중 조절의 기준이 되는 중요한 지표
///
/// TDEE 계산 공식:
/// - TDEE = BMR × Activity Level Multiplier
/// - BMR은 기본 생명 유지에 필요한 칼로리
/// - Activity Multiplier는 일상 활동과 운동으로 인한 추가 소비를 반영
///
/// 활동 수준별 계수의 의미:
/// - 1.2 (Sedentary): BMR의 20% 추가 소비 (거의 운동 없음)
/// - 1.375 (Lightly Active): BMR의 37.5% 추가 소비 (주 1-3일 운동)
/// - 1.55 (Moderately Active): BMR의 55% 추가 소비 (주 3-5일 운동)
/// - 1.725 (Very Active): BMR의 72.5% 추가 소비 (주 6-7일 운동)
/// - 1.9 (Extra Active): BMR의 90% 추가 소비 (하루 2회 이상 강한 운동)
///
/// TDEE의 활용:
/// - 다이어트: TDEE - 500 kcal/day = 주당 약 0.5kg 감량
/// - 증량: TDEE + 500 kcal/day = 주당 약 0.5kg 증량
/// - 유지: TDEE만큼 섭취 = 체중 유지
/// - 💡 너무 급격한 칼로리 제한은 건강에 해로울 수 있음
///
/// BMR과의 차이:
/// - BMR: 완전히 쉬고 있을 때의 최소 칼로리 소비
/// - TDEE: 일상 활동을 포함한 실제 칼로리 소비
/// - 일반적으로 TDEE는 BMR보다 20-90% 높음
///
/// 정확도 향상 팁:
/// - 활동 수준을 과대평가하지 않기 (대부분의 사람은 Sedentary~Lightly Active)
/// - 2주 정도 기록하며 체중 변화로 실제 TDEE 확인
/// - 나이가 들면서 BMR과 TDEE 모두 감소하므로 주기적 재계산 필요
///
