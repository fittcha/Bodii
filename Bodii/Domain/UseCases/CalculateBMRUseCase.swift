//
//  CalculateBMRUseCase.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-12.
//

// 📚 학습 포인트: Use Case Pattern
// 단일 비즈니스 로직을 캡슐화하는 Use Case 패턴
// 💡 Java 비교: Service layer의 단일 메서드와 유사하지만 더 세분화됨

import Foundation

// MARK: - CalculateBMRUseCase

/// BMR(Basal Metabolic Rate) 계산 Use Case
/// Mifflin-St Jeor 공식을 사용하여 기초대사량을 계산합니다.
/// 📚 학습 포인트: Clean Architecture - Use Case Layer
/// - 특정 비즈니스 로직(BMR 계산)을 독립적인 유닛으로 캡슐화
/// - UI나 데이터베이스에 의존하지 않는 순수한 비즈니스 로직
/// - 재사용 가능하고 테스트하기 쉬운 구조
/// 💡 Java 비교: Interactor 또는 Service 클래스의 단일 책임 메서드
struct CalculateBMRUseCase {

    // MARK: - Types

    /// BMR 계산에 필요한 입력 데이터
    /// 📚 학습 포인트: Nested Type
    /// - Use Case 내부에 관련된 타입을 중첩하여 네임스페이스 정리
    /// - 외부에서는 CalculateBMRUseCase.Input으로 접근
    /// 💡 Java 비교: static nested class와 유사
    struct Input {
        /// 체중 (kg)
        /// 📚 학습 포인트: Decimal for Precision
        /// 부동소수점 오차를 방지하기 위해 Decimal 사용
        let weight: Decimal

        /// 신장 (cm)
        /// BMR 공식에서 cm 단위로 직접 사용
        let height: Decimal

        /// 나이 (years)
        /// 만 나이를 정수로 사용
        let age: Int

        /// 성별
        /// 남성과 여성의 BMR 계산 공식이 다름
        let gender: Gender

        /// 체지방률 (%) - Optional
        /// 📚 학습 포인트: Optional for Hybrid Formula
        /// 체지방률이 있으면 Katch-McArdle 공식 사용 (더 정확)
        /// 없으면 Mifflin-St Jeor 공식 사용 (표준)
        let bodyFatPercent: Decimal?

        /// Input 초기화
        /// - Parameters:
        ///   - weight: 체중 (kg)
        ///   - height: 신장 (cm)
        ///   - age: 나이
        ///   - gender: 성별
        ///   - bodyFatPercent: 체지방률 (%, 선택사항)
        init(
            weight: Decimal,
            height: Decimal,
            age: Int,
            gender: Gender,
            bodyFatPercent: Decimal? = nil
        ) {
            self.weight = weight
            self.height = height
            self.age = age
            self.gender = gender
            self.bodyFatPercent = bodyFatPercent
        }

        /// Input 유효성 검증
        /// 📚 학습 포인트: Validation in Domain Layer
        /// 비즈니스 규칙 검증을 도메인 레이어에서 처리
        /// - Returns: 유효하면 true, 그렇지 않으면 false
        var isValid: Bool {
            guard weight > 0 && height > 0 && age > 0 else { return false }
            // 체지방률이 있으면 유효 범위 확인 (1-60%)
            if let bf = bodyFatPercent {
                guard bf >= 1 && bf <= 60 else { return false }
            }
            return true
        }
    }

    /// 사용된 BMR 계산 공식
    /// 📚 학습 포인트: Enum for Formula Type
    /// 어떤 공식이 사용되었는지 추적하여 투명성 제공
    enum Formula: String {
        /// Mifflin-St Jeor 공식 (체지방률 없을 때)
        case mifflinStJeor = "Mifflin-St Jeor"
        /// Katch-McArdle 공식 (체지방률 있을 때, 더 정확)
        case katchMcArdle = "Katch-McArdle"

        var description: String {
            switch self {
            case .mifflinStJeor:
                return "Mifflin-St Jeor 공식 (표준)"
            case .katchMcArdle:
                return "Katch-McArdle 공식 (체지방률 기반, 더 정확)"
            }
        }
    }

    /// BMR 계산 결과
    /// 📚 학습 포인트: Result Type
    /// 성공/실패를 명시적으로 표현하는 타입
    /// 💡 Java 비교: Optional이나 Result<T, E>와 유사
    struct Output {
        /// 계산된 BMR 값 (kcal/day)
        /// 📚 학습 포인트: Decimal Type
        /// 칼로리 계산은 정밀도가 중요하므로 Decimal 사용
        let bmr: Decimal

        /// 사용된 계산 공식
        /// 📚 학습 포인트: Transparency
        /// 어떤 공식이 사용되었는지 사용자에게 알려줄 수 있음
        let formulaUsed: Formula

        /// BMR을 반올림하여 표시용 정수로 변환
        /// 📚 학습 포인트: Computed Property
        /// UI에서 표시할 때는 소수점이 필요없으므로 반올림
        /// 💡 Java 비교: getter 메서드와 유사
        var roundedBMR: Int {
            return NSDecimalNumber(decimal: bmr).rounding(accordingToBehavior: nil).intValue
        }

        /// 포맷된 BMR 문자열 (예: "1,567 kcal/day")
        /// 📚 학습 포인트: String Formatting
        /// UI 표시를 위한 편의 메서드
        /// - Returns: 쉼표로 구분된 BMR 문자열
        func formatted() -> String {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = 0

            let bmrString = formatter.string(from: NSDecimalNumber(decimal: bmr)) ?? "\(roundedBMR)"
            return "\(bmrString) kcal/day"
        }
    }

    // MARK: - Error

    /// BMR 계산 중 발생할 수 있는 에러
    /// 📚 학습 포인트: Custom Error Type
    /// Swift의 Error 프로토콜을 conform하여 throw 가능한 타입 정의
    /// 💡 Java 비교: Custom Exception과 유사
    enum BMRError: Error, LocalizedError {
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
                return "Invalid input values. Weight, height, and age must be greater than 0."
            case .calculationError:
                return "An error occurred during BMR calculation."
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

    /// BMR 계산 실행
    /// 📚 학습 포인트: Hybrid Formula (하이브리드 공식)
    ///
    /// 체지방률 유무에 따라 적절한 공식을 선택합니다:
    ///
    /// ## 1. Katch-McArdle 공식 (체지방률이 있을 때 - 더 정확)
    /// ```
    /// LBM = weight × (1 - bodyFatPercent / 100)
    /// BMR = 370 + (21.6 × LBM)
    /// ```
    /// - LBM: 제지방량 (Lean Body Mass)
    /// - 체지방률을 고려하므로 더 정확한 결과 제공
    ///
    /// ## 2. Mifflin-St Jeor 공식 (체지방률이 없을 때 - 표준)
    /// ```
    /// 남성: BMR = (10 × weight) + (6.25 × height) - (5 × age) + 5
    /// 여성: BMR = (10 × weight) + (6.25 × height) - (5 × age) - 161
    /// ```
    ///
    /// 단위:
    /// - weight: kg
    /// - height: cm
    /// - age: years
    /// - BMR: kcal/day
    ///
    /// - Parameter input: BMR 계산에 필요한 입력 데이터
    /// - Returns: 계산된 BMR 결과 (사용된 공식 정보 포함)
    /// - Throws: BMRError - 입력값이 유효하지 않거나 계산 중 에러 발생 시
    func execute(input: Input) throws -> Output {
        // 📚 학습 포인트: Guard Statement
        guard input.isValid else {
            throw BMRError.invalidInput
        }

        let bmr: Decimal
        let formulaUsed: Formula

        // 📚 학습 포인트: Hybrid Formula Selection
        // 체지방률이 있으면 Katch-McArdle (더 정확), 없으면 Mifflin-St Jeor (표준)
        if let bodyFatPercent = input.bodyFatPercent {
            // Katch-McArdle 공식 사용
            // LBM = weight × (1 - bodyFatPercent / 100)
            // BMR = 370 + (21.6 × LBM)
            let bodyFatRatio = bodyFatPercent / Decimal(100)
            let lbm = input.weight * (Decimal(1) - bodyFatRatio)
            bmr = Decimal(370) + (Decimal(21.6) * lbm)
            formulaUsed = .katchMcArdle
        } else {
            // Mifflin-St Jeor 공식 사용
            // BMR = (10 × weight) + (6.25 × height) - (5 × age) ± genderAdjustment
            let weightComponent = Decimal(10) * input.weight
            let heightComponent = Decimal(6.25) * input.height
            let ageComponent = Decimal(5) * Decimal(input.age)
            let genderAdjustment = Decimal(input.gender.bmrAdjustment)
            bmr = weightComponent + heightComponent - ageComponent + genderAdjustment
            formulaUsed = .mifflinStJeor
        }

        // 📚 학습 포인트: Sanity Check
        // 계산된 BMR이 합리적인 범위인지 확인 (300-5000 kcal/day)
        guard bmr >= 300 && bmr <= 5000 else {
            throw BMRError.calculationError
        }

        return Output(bmr: bmr, formulaUsed: formulaUsed)
    }

    // MARK: - Convenience Methods

    /// UserProfile과 BodyCompositionEntry를 사용한 BMR 계산 편의 메서드
    /// 📚 학습 포인트: Convenience Method
    /// 도메인 엔티티를 직접 받아서 Input으로 변환하는 헬퍼 메서드
    /// 💡 사용처: ViewModel이나 다른 Use Case에서 쉽게 호출 가능
    ///
    /// **하이브리드 공식**: BodyCompositionEntry의 체지방률이 있으므로
    /// 자동으로 Katch-McArdle 공식이 사용됩니다.
    ///
    /// - Parameters:
    ///   - profile: 사용자 프로필 (신장, 나이, 성별 포함)
    ///   - bodyEntry: 신체 구성 데이터 (체중, 체지방률 포함)
    /// - Returns: 계산된 BMR 결과
    /// - Throws: BMRError
    func execute(profile: UserProfile, bodyEntry: BodyCompositionEntry) throws -> Output {
        let input = Input(
            weight: bodyEntry.weight,
            height: profile.height,
            age: profile.age,
            gender: profile.gender,
            bodyFatPercent: bodyEntry.bodyFatPercent
        )
        return try execute(input: input)
    }

    /// 개별 파라미터를 사용한 BMR 계산 편의 메서드 (체지방률 없음)
    /// 📚 학습 포인트: Method Overloading
    /// Swift에서는 다른 시그니처를 가진 같은 이름의 메서드 정의 가능
    /// 💡 Java 비교: Method overloading과 동일
    ///
    /// **공식**: 체지방률이 없으므로 Mifflin-St Jeor 공식 사용
    ///
    /// - Parameters:
    ///   - weight: 체중 (kg)
    ///   - height: 신장 (cm)
    ///   - age: 나이 (years)
    ///   - gender: 성별
    /// - Returns: 계산된 BMR 결과
    /// - Throws: BMRError
    func execute(
        weight: Decimal,
        height: Decimal,
        age: Int,
        gender: Gender
    ) throws -> Output {
        let input = Input(
            weight: weight,
            height: height,
            age: age,
            gender: gender
        )
        return try execute(input: input)
    }

    /// 개별 파라미터를 사용한 BMR 계산 편의 메서드 (체지방률 포함)
    /// 📚 학습 포인트: Method Overloading with Optional Parameter
    ///
    /// **하이브리드 공식**:
    /// - 체지방률이 있으면 Katch-McArdle 공식 사용 (더 정확)
    /// - 체지방률이 없으면 Mifflin-St Jeor 공식 사용 (표준)
    ///
    /// - Parameters:
    ///   - weight: 체중 (kg)
    ///   - height: 신장 (cm)
    ///   - age: 나이 (years)
    ///   - gender: 성별
    ///   - bodyFatPercent: 체지방률 (%, 선택사항)
    /// - Returns: 계산된 BMR 결과
    /// - Throws: BMRError
    func execute(
        weight: Decimal,
        height: Decimal,
        age: Int,
        gender: Gender,
        bodyFatPercent: Decimal?
    ) throws -> Output {
        let input = Input(
            weight: weight,
            height: height,
            age: age,
            gender: gender,
            bodyFatPercent: bodyFatPercent
        )
        return try execute(input: input)
    }
}

// MARK: - Sample Usage

extension CalculateBMRUseCase {
    /// 📚 학습 포인트: Sample Data for Testing
    /// Use Case의 사용 예시와 테스트를 위한 샘플 데이터
    /// 💡 Java 비교: JUnit의 @Test fixture와 유사

    /// 샘플 입력 - 30세 남성, 70kg, 175cm (체지방률 없음 → Mifflin-St Jeor)
    static let sampleInputMale = Input(
        weight: Decimal(70),
        height: Decimal(175),
        age: 30,
        gender: .male
    )

    /// 샘플 입력 - 25세 여성, 55kg, 162cm (체지방률 없음 → Mifflin-St Jeor)
    static let sampleInputFemale = Input(
        weight: Decimal(55),
        height: Decimal(162),
        age: 25,
        gender: .female
    )

    /// 샘플 입력 - 30세 남성, 70kg, 체지방률 18% (체지방률 있음 → Katch-McArdle)
    static let sampleInputMaleWithBodyFat = Input(
        weight: Decimal(70),
        height: Decimal(175),
        age: 30,
        gender: .male,
        bodyFatPercent: Decimal(18)
    )

    /// 샘플 입력 - 25세 여성, 55kg, 체지방률 25% (체지방률 있음 → Katch-McArdle)
    static let sampleInputFemaleWithBodyFat = Input(
        weight: Decimal(55),
        height: Decimal(162),
        age: 25,
        gender: .female,
        bodyFatPercent: Decimal(25)
    )

    /// 예상 결과 계산
    ///
    /// **Mifflin-St Jeor 공식 (체지방률 없음)**:
    /// 남성: (10 × 70) + (6.25 × 175) - (5 × 30) + 5 = 700 + 1093.75 - 150 + 5 = 1648.75 kcal/day
    /// 여성: (10 × 55) + (6.25 × 162) - (5 × 25) - 161 = 550 + 1012.5 - 125 - 161 = 1276.5 kcal/day
    ///
    /// **Katch-McArdle 공식 (체지방률 있음)**:
    /// 남성 (체지방률 18%): LBM = 70 × (1 - 0.18) = 57.4kg, BMR = 370 + (21.6 × 57.4) = 1609.84 kcal/day
    /// 여성 (체지방률 25%): LBM = 55 × (1 - 0.25) = 41.25kg, BMR = 370 + (21.6 × 41.25) = 1261 kcal/day
}

// MARK: - Documentation

/// 📚 학습 포인트: BMR (Basal Metabolic Rate) 이해
///
/// BMR이란?
/// - 기초대사량: 생명 유지를 위해 필요한 최소 에너지량
/// - 아무 활동도 하지 않고 누워만 있어도 소모되는 칼로리
/// - 전체 하루 에너지 소비의 약 60-75%를 차지
///
/// ## 하이브리드 공식 (Hybrid Formula)
///
/// 이 앱에서는 체지방률 유무에 따라 적절한 공식을 자동 선택합니다:
///
/// ### 1. Katch-McArdle 공식 (체지방률이 있을 때)
/// ```
/// LBM = weight × (1 - bodyFatPercent / 100)
/// BMR = 370 + (21.6 × LBM)
/// ```
/// - LBM: 제지방량 (Lean Body Mass)
/// - 체지방률을 고려하므로 더 정확한 결과 제공
/// - 인바디 측정을 한 사용자에게 적합
///
/// ### 2. Mifflin-St Jeor 공식 (체지방률이 없을 때)
/// ```
/// 남성: BMR = (10 × weight) + (6.25 × height) - (5 × age) + 5
/// 여성: BMR = (10 × weight) + (6.25 × height) - (5 × age) - 161
/// ```
/// - 1990년 발표된 비교적 최신 공식
/// - Harris-Benedict 공식보다 약 5% 더 정확
/// - 미국 영양학회(ADA)에서 권장하는 공식
/// - 체지방률을 모르는 사용자에게 적합
///
/// ## 왜 하이브리드 방식인가?
///
/// 1. **사용자 편의성**: 체지방률을 모르는 사용자도 앱 사용 가능
/// 2. **정확성 향상**: 체지방률이 있으면 더 정확한 계산 제공
/// 3. **점진적 개선**: 처음에는 몸무게만, 나중에 인바디 측정 시 자동으로 더 정확한 계산
///
/// ## 다른 BMR 공식들 참고
///
/// 1. Harris-Benedict (1919): 가장 오래된 공식, 현대인에게는 과대평가 경향
/// 2. Cunningham: 운동선수에게 적합
///
/// ## TDEE와의 관계
///
/// - TDEE (Total Daily Energy Expenditure) = BMR × Activity Level Multiplier
/// - BMR은 기본값이고, 여기에 활동량을 곱하여 하루 총 소비 칼로리 산출
///
/// ## 활용
///
/// - 다이어트: TDEE보다 적게 먹으면 체중 감소
/// - 증량: TDEE보다 많이 먹으면 체중 증가
/// - 유지: TDEE만큼 먹으면 체중 유지
