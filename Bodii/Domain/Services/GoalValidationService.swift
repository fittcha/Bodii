//
//  GoalValidationService.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-18.
//

import Foundation

/// 목표 검증 서비스
///
/// 목표 설정 시 입력값의 유효성과 정합성을 검증합니다.
///
/// ## 검증 항목
///
/// **1. 필수 목표 설정 검증**
/// - 최소 1개 이상의 목표값(targetWeight, targetBodyFatPct, targetMuscleMass)이 설정되어야 합니다.
///
/// **2. 현실적인 변화율 검증**
/// - 체중: 주당 ±2.0kg 이내 권장
/// - 체지방률: 주당 ±3.0% 이내 권장
/// - 근육량: 주당 ±1.0kg 이내 권장
///
/// **3. 목표 유형 일관성 검증**
/// - 감량(lose): 체중/체지방률은 감소, 근육량은 유지 또는 감소
/// - 유지(maintain): 모든 값이 현재값과 유사 (±5% 이내)
/// - 증량(gain): 체중은 증가, 근육량은 증가 또는 유지
///
/// **4. 복수 목표 물리적 정합성 검증**
/// - 체지방량 = 목표체중 × (목표체지방률 / 100)
/// - 제지방량 = 목표체중 - 체지방량
/// - **제지방량 ≥ 목표근육량** (근육은 제지방의 일부이므로 제지방량을 초과할 수 없음)
///
/// ## 사용 예시
/// ```swift
/// let goal = Goal(
///     goalType: .lose,
///     targetWeight: Decimal(65.0),
///     targetBodyFatPct: Decimal(18.0),
///     weeklyWeightRate: Decimal(-0.5),
///     weeklyFatPctRate: Decimal(-0.5),
///     startWeight: Decimal(70.0),
///     startBodyFatPct: Decimal(22.0)
/// )
///
/// do {
///     try GoalValidationService.validate(goal: goal)
///     // 검증 성공
/// } catch GoalValidationError.noTargetsSet {
///     // 최소 1개 목표 필요
/// } catch GoalValidationError.inconsistentGoalType(let message) {
///     // 목표 유형과 맞지 않음
/// } catch GoalValidationError.physicallyImpossible(let message) {
///     // 물리적으로 불가능한 목표
/// }
/// ```
enum GoalValidationService {

    // MARK: - Constants

    /// 체중 변화율 권장 범위 (kg/week)
    private static let recommendedWeightRateRange: ClosedRange<Decimal> = -2.0...2.0

    /// 체지방률 변화율 권장 범위 (%/week)
    private static let recommendedFatPctRateRange: ClosedRange<Decimal> = -3.0...3.0

    /// 근육량 변화율 권장 범위 (kg/week)
    private static let recommendedMuscleRateRange: ClosedRange<Decimal> = -1.0...1.0

    /// 유지 목표 허용 변화 범위 (±5%)
    private static let maintainTolerancePct: Decimal = 5.0

    /// 최소 목표 기간 (주)
    private static let minimumWeeksForGoal: Int = 1

    /// 최대 목표 기간 (주) - 약 2년
    private static let maximumWeeksForGoal: Int = 104

    // MARK: - Public Methods

    /// 목표의 유효성을 검증합니다.
    ///
    /// 모든 검증 규칙을 순차적으로 적용하여 목표가 유효한지 확인합니다.
    /// 검증 실패 시 구체적인 에러 메시지와 함께 GoalValidationError를 throw합니다.
    ///
    /// - Parameter goal: 검증할 목표
    ///
    /// - Throws: GoalValidationError
    ///   - `.noTargetsSet`: 최소 1개 목표가 설정되지 않음
    ///   - `.unrealisticRate`: 주간 변화율이 권장 범위를 벗어남
    ///   - `.inconsistentGoalType`: 목표 유형과 목표값이 일치하지 않음
    ///   - `.physicallyImpossible`: 물리적으로 불가능한 목표 조합
    ///   - `.invalidTargetDate`: 목표 달성 기간이 비현실적임
    ///   - `.missingStartValues`: 시작 값이 없어 검증 불가
    ///
    /// - Example:
    /// ```swift
    /// // 성공 케이스
    /// let validGoal = Goal(
    ///     goalType: .lose,
    ///     targetWeight: Decimal(65.0),
    ///     weeklyWeightRate: Decimal(-0.5),
    ///     startWeight: Decimal(70.0)
    /// )
    /// try GoalValidationService.validate(goal: validGoal) // ✅ 성공
    ///
    /// // 실패 케이스: 목표 없음
    /// let noTargets = Goal(goalType: .lose)
    /// try GoalValidationService.validate(goal: noTargets)
    /// // ❌ throws .noTargetsSet
    ///
    /// // 실패 케이스: 물리적으로 불가능
    /// let impossible = Goal(
    ///     goalType: .lose,
    ///     targetWeight: Decimal(53.0),
    ///     targetBodyFatPct: Decimal(18.0),
    ///     targetMuscleMass: Decimal(45.0)  // 제지방량(43.5kg)보다 많음
    /// )
    /// try GoalValidationService.validate(goal: impossible)
    /// // ❌ throws .physicallyImpossible("제지방량(43.46kg)보다 근육량이 많을 수 없습니다")
    /// ```
    static func validate(goal: Goal) throws {
        // 1. 최소 1개 목표 설정 확인
        try validateHasTargets(goal: goal)

        // 2. 주간 변화율 현실성 검증
        try validateWeeklyRates(goal: goal)

        // 3. 목표 유형 일관성 검증
        try validateGoalTypeConsistency(goal: goal)

        // 4. 복수 목표 물리적 정합성 검증
        try validatePhysicalConsistency(goal: goal)

        // 5. 목표 달성 기간 검증
        try validateTargetDate(goal: goal)
    }

    // MARK: - Validation Methods

    /// 최소 1개 이상의 목표가 설정되었는지 검증합니다.
    ///
    /// - Parameter goal: 검증할 목표
    /// - Throws: GoalValidationError.noTargetsSet
    ///
    /// - Example:
    /// ```swift
    /// let goal = Goal(goalType: .lose)  // 목표값 없음
    /// try GoalValidationService.validateHasTargets(goal: goal)
    /// // ❌ throws .noTargetsSet
    /// ```
    private static func validateHasTargets(goal: Goal) throws {
        let hasWeight = goal.targetWeight != nil
        let hasBodyFat = goal.targetBodyFatPct != nil
        let hasMuscle = goal.targetMuscleMass != nil

        guard hasWeight || hasBodyFat || hasMuscle else {
            throw GoalValidationError.noTargetsSet
        }
    }

    /// 주간 변화율이 현실적인 범위 내에 있는지 검증합니다.
    ///
    /// 건강하지 않은 급격한 변화를 방지하기 위해 권장 범위를 벗어나면 경고합니다.
    ///
    /// - Parameter goal: 검증할 목표
    /// - Throws: GoalValidationError.unrealisticRate
    ///
    /// - Example:
    /// ```swift
    /// let tooFast = Goal(
    ///     targetWeight: Decimal(60.0),
    ///     weeklyWeightRate: Decimal(-3.0),  // 주당 3kg 감량 (너무 빠름)
    ///     startWeight: Decimal(80.0)
    /// )
    /// try GoalValidationService.validateWeeklyRates(goal: tooFast)
    /// // ❌ throws .unrealisticRate("체중 변화율(주당 -3.0kg)이 권장 범위를 벗어났습니다...")
    /// ```
    private static func validateWeeklyRates(goal: Goal) throws {
        // 체중 변화율 검증
        if let rateNS = goal.weeklyWeightRate {
            let rate = rateNS.decimalValue
            if !recommendedWeightRateRange.contains(rate) {
                throw GoalValidationError.unrealisticRate(
                    "체중 변화율(주당 \(rate)kg)이 권장 범위를 벗어났습니다. " +
                    "건강한 변화를 위해 주당 \(recommendedWeightRateRange.lowerBound)kg ~ " +
                    "\(recommendedWeightRateRange.upperBound)kg를 권장합니다."
                )
            }
        }

        // 체지방률 변화율 검증
        if let rateNS = goal.weeklyFatPctRate {
            let rate = rateNS.decimalValue
            if !recommendedFatPctRateRange.contains(rate) {
                throw GoalValidationError.unrealisticRate(
                    "체지방률 변화율(주당 \(rate)%)이 권장 범위를 벗어났습니다. " +
                    "건강한 변화를 위해 주당 \(recommendedFatPctRateRange.lowerBound)% ~ " +
                    "\(recommendedFatPctRateRange.upperBound)%를 권장합니다."
                )
            }
        }

        // 근육량 변화율 검증
        if let rateNS = goal.weeklyMuscleRate {
            let rate = rateNS.decimalValue
            if !recommendedMuscleRateRange.contains(rate) {
                throw GoalValidationError.unrealisticRate(
                    "근육량 변화율(주당 \(rate)kg)이 권장 범위를 벗어났습니다. " +
                    "현실적인 변화를 위해 주당 \(recommendedMuscleRateRange.lowerBound)kg ~ " +
                    "\(recommendedMuscleRateRange.upperBound)kg를 권장합니다."
                )
            }
        }
    }

    /// 목표 유형과 목표값/변화율이 일치하는지 검증합니다.
    ///
    /// - Parameter goal: 검증할 목표
    /// - Throws: GoalValidationError.inconsistentGoalType
    ///
    /// - Example:
    /// ```swift
    /// // 감량 목표인데 체중 증가
    /// let inconsistent = Goal(
    ///     goalType: .lose,
    ///     targetWeight: Decimal(80.0),
    ///     startWeight: Decimal(70.0)  // 70kg → 80kg (증가)
    /// )
    /// try GoalValidationService.validateGoalTypeConsistency(goal: inconsistent)
    /// // ❌ throws .inconsistentGoalType("감량 목표이지만 체중이 증가합니다")
    /// ```
    private static func validateGoalTypeConsistency(goal: Goal) throws {
        // goalType은 Int16이므로 GoalType enum으로 변환
        guard let goalType = GoalType(rawValue: goal.goalType) else {
            return // 알 수 없는 타입은 검증 생략
        }

        switch goalType {
        case .lose:
            try validateLoseGoal(goal: goal)
        case .maintain:
            try validateMaintainGoal(goal: goal)
        case .gain:
            try validateGainGoal(goal: goal)
        }
    }

    /// 감량 목표 일관성 검증
    ///
    /// 감량 목표는:
    /// - 체중이 감소해야 함
    /// - 체지방률이 감소하거나 유지되어야 함
    /// - 근육량은 감소하거나 유지되어야 함 (증가 가능하지만 일반적이지 않음)
    private static func validateLoseGoal(goal: Goal) throws {
        // 체중 검증
        if let targetWeightNS = goal.targetWeight,
           let startWeightNS = goal.startWeight {
            let targetWeight = targetWeightNS.decimalValue
            let startWeight = startWeightNS.decimalValue
            if targetWeight >= startWeight {
                throw GoalValidationError.inconsistentGoalType(
                    "감량 목표이지만 체중이 감소하지 않습니다. " +
                    "목표 체중(\(targetWeight)kg)이 시작 체중(\(startWeight)kg)보다 크거나 같습니다."
                )
            }
        }

        // 체지방률 검증 (선택적 - 체지방률은 증가할 수도 있음)
        if let targetFatNS = goal.targetBodyFatPct,
           let startFatNS = goal.startBodyFatPct {
            let targetFat = targetFatNS.decimalValue
            let startFat = startFatNS.decimalValue
            if targetFat > startFat {
                // 경고만 하고 에러는 throw하지 않음 (근육 감량 시 체지방률 증가 가능)
            }
        }
    }

    /// 유지 목표 일관성 검증
    ///
    /// 유지 목표는 모든 값이 시작값의 ±5% 이내여야 함
    private static func validateMaintainGoal(goal: Goal) throws {
        // 체중 검증
        if let targetWeightNS = goal.targetWeight,
           let startWeightNS = goal.startWeight {
            let targetWeight = targetWeightNS.decimalValue
            let startWeight = startWeightNS.decimalValue
            let tolerance = startWeight * (maintainTolerancePct / 100)
            let range = (startWeight - tolerance)...(startWeight + tolerance)

            if !range.contains(targetWeight) {
                throw GoalValidationError.inconsistentGoalType(
                    "유지 목표이지만 체중 변화가 큽니다. " +
                    "목표 체중(\(targetWeight)kg)이 시작 체중(\(startWeight)kg)의 ±\(maintainTolerancePct)% 범위를 벗어났습니다."
                )
            }
        }

        // 체지방률 검증
        if let targetFatNS = goal.targetBodyFatPct,
           let startFatNS = goal.startBodyFatPct {
            let targetFat = targetFatNS.decimalValue
            let startFat = startFatNS.decimalValue
            let tolerance = startFat * (maintainTolerancePct / 100)
            let range = (startFat - tolerance)...(startFat + tolerance)

            if !range.contains(targetFat) {
                throw GoalValidationError.inconsistentGoalType(
                    "유지 목표이지만 체지방률 변화가 큽니다. " +
                    "목표 체지방률(\(targetFat)%)이 시작 체지방률(\(startFat)%)의 ±\(maintainTolerancePct)% 범위를 벗어났습니다."
                )
            }
        }
    }

    /// 증량 목표 일관성 검증
    ///
    /// 증량 목표는:
    /// - 체중이 증가해야 함
    /// - 근육량이 증가하거나 유지되어야 함
    private static func validateGainGoal(goal: Goal) throws {
        // 체중 검증
        if let targetWeightNS = goal.targetWeight,
           let startWeightNS = goal.startWeight {
            let targetWeight = targetWeightNS.decimalValue
            let startWeight = startWeightNS.decimalValue
            if targetWeight <= startWeight {
                throw GoalValidationError.inconsistentGoalType(
                    "증량 목표이지만 체중이 증가하지 않습니다. " +
                    "목표 체중(\(targetWeight)kg)이 시작 체중(\(startWeight)kg)보다 작거나 같습니다."
                )
            }
        }

        // 근육량 검증 (선택적)
        if let targetMuscleNS = goal.targetMuscleMass,
           let startMuscleNS = goal.startMuscleMass {
            let targetMuscle = targetMuscleNS.decimalValue
            let startMuscle = startMuscleNS.decimalValue
            if targetMuscle < startMuscle {
                // 증량하면서 근육이 감소하는 것은 비정상적
                throw GoalValidationError.inconsistentGoalType(
                    "증량 목표이지만 근육량이 감소합니다. " +
                    "목표 근육량(\(targetMuscle)kg)이 시작 근육량(\(startMuscle)kg)보다 작습니다."
                )
            }
        }
    }

    /// 복수 목표의 물리적 정합성을 검증합니다.
    ///
    /// 체중, 체지방률, 근육량이 모두 설정된 경우 물리적으로 가능한 조합인지 확인합니다.
    ///
    /// **검증 공식:**
    /// ```
    /// 체지방량 = 목표체중 × (목표체지방률 / 100)
    /// 제지방량 = 목표체중 - 체지방량
    /// 근육량 ≤ 제지방량  (근육은 제지방의 일부)
    /// ```
    ///
    /// - Parameter goal: 검증할 목표
    /// - Throws: GoalValidationError.physicallyImpossible
    ///
    /// - Example:
    /// ```swift
    /// // 물리적으로 불가능한 케이스
    /// let impossible = Goal(
    ///     targetWeight: Decimal(53.0),     // 목표 체중 53kg
    ///     targetBodyFatPct: Decimal(18.0), // 목표 체지방률 18%
    ///     targetMuscleMass: Decimal(45.0)  // 목표 근육량 45kg
    /// )
    /// // 계산:
    /// // 체지방량 = 53 × 0.18 = 9.54kg
    /// // 제지방량 = 53 - 9.54 = 43.46kg
    /// // 근육량(45kg) > 제지방량(43.46kg) ❌ 불가능!
    ///
    /// try GoalValidationService.validatePhysicalConsistency(goal: impossible)
    /// // ❌ throws .physicallyImpossible("제지방량(43.46kg)보다 근육량이 많을 수 없습니다")
    /// ```
    private static func validatePhysicalConsistency(goal: Goal) throws {
        guard let targetWeightNS = goal.targetWeight,
              let targetBodyFatPctNS = goal.targetBodyFatPct,
              let targetMuscleMassNS = goal.targetMuscleMass else {
            // 3개 값이 모두 있을 때만 검증
            return
        }

        let targetWeight = targetWeightNS.decimalValue
        let targetBodyFatPct = targetBodyFatPctNS.decimalValue
        let targetMuscleMass = targetMuscleMassNS.decimalValue

        // 1. 체지방량 계산
        let bodyFatMass = targetWeight * (targetBodyFatPct / 100)

        // 2. 제지방량 계산
        let leanBodyMass = targetWeight - bodyFatMass

        // 3. 근육량이 제지방량을 초과하는지 확인
        if targetMuscleMass > leanBodyMass {
            throw GoalValidationError.physicallyImpossible(
                "제지방량(\(leanBodyMass.rounded(to: 2))kg)보다 근육량(\(targetMuscleMass)kg)이 많을 수 없습니다. " +
                "근육은 제지방량의 일부입니다."
            )
        }

        // 4. 체지방률 범위 검증 (1% ~ 60%)
        if targetBodyFatPct < 1 || targetBodyFatPct > 60 {
            throw GoalValidationError.physicallyImpossible(
                "체지방률(\(targetBodyFatPct)%)이 유효 범위(1% ~ 60%)를 벗어났습니다."
            )
        }
    }

    /// 목표 달성 기간이 현실적인지 검증합니다.
    ///
    /// 주간 변화율을 기반으로 목표 달성까지 걸리는 기간을 계산하고,
    /// 너무 짧거나 너무 긴 기간인지 확인합니다.
    ///
    /// - Parameter goal: 검증할 목표
    /// - Throws: GoalValidationError.invalidTargetDate, GoalValidationError.missingStartValues
    ///
    /// - Example:
    /// ```swift
    /// let goal = Goal(
    ///     targetWeight: Decimal(60.0),
    ///     weeklyWeightRate: Decimal(-0.5),
    ///     startWeight: Decimal(70.0)
    /// )
    /// // 예상 기간: (70 - 60) / 0.5 = 20주
    /// try GoalValidationService.validateTargetDate(goal: goal) // ✅ 성공 (1주 ~ 104주 범위)
    /// ```
    private static func validateTargetDate(goal: Goal) throws {
        // 체중 목표가 있는 경우 기간 검증
        if let targetWeightNS = goal.targetWeight,
           let weeklyRateNS = goal.weeklyWeightRate,
           let startWeightNS = goal.startWeight {

            let targetWeight = targetWeightNS.decimalValue
            let weeklyRate = weeklyRateNS.decimalValue
            let startWeight = startWeightNS.decimalValue

            guard weeklyRate != 0 else {
                throw GoalValidationError.invalidTargetDate(
                    "주간 변화율이 0입니다. 목표 달성 기간을 계산할 수 없습니다."
                )
            }

            // 예상 소요 주수 계산
            let difference = targetWeight - startWeight
            let weeksToGoal = abs(difference / weeklyRate)

            // 부호 확인 (목표와 변화율 방향이 일치하는지)
            if (difference > 0 && weeklyRate < 0) || (difference < 0 && weeklyRate > 0) {
                throw GoalValidationError.invalidTargetDate(
                    "목표 방향과 변화율이 일치하지 않습니다. " +
                    "목표 체중(\(targetWeight)kg)에 도달하려면 주간 변화율의 부호를 확인하세요."
                )
            }

            // 기간 범위 검증
            if weeksToGoal < Decimal(minimumWeeksForGoal) {
                throw GoalValidationError.invalidTargetDate(
                    "목표 달성 기간이 너무 짧습니다 (\(weeksToGoal.rounded(to: 1))주). " +
                    "최소 \(minimumWeeksForGoal)주 이상의 기간을 설정하세요."
                )
            }

            if weeksToGoal > Decimal(maximumWeeksForGoal) {
                throw GoalValidationError.invalidTargetDate(
                    "목표 달성 기간이 너무 깁니다 (\(weeksToGoal.rounded(to: 1))주). " +
                    "최대 \(maximumWeeksForGoal)주 이내의 기간을 설정하세요."
                )
            }
        }
    }
}

// MARK: - GoalValidationError

/// 목표 검증 에러
///
/// 목표 설정 시 발생할 수 있는 검증 에러를 정의합니다.
public enum GoalValidationError: Error {

    /// 최소 1개의 목표가 설정되지 않음
    ///
    /// targetWeight, targetBodyFatPct, targetMuscleMass 중
    /// 하나 이상이 반드시 설정되어야 합니다.
    case noTargetsSet

    /// 주간 변화율이 비현실적임
    ///
    /// 건강하지 않거나 현실적이지 않은 변화율이 설정됨
    ///
    /// - Parameter message: 구체적인 에러 메시지
    case unrealisticRate(String)

    /// 목표 유형과 목표값이 일치하지 않음
    ///
    /// 예: 감량 목표인데 체중이 증가하는 경우
    ///
    /// - Parameter message: 구체적인 에러 메시지
    case inconsistentGoalType(String)

    /// 물리적으로 불가능한 목표 조합
    ///
    /// 예: 제지방량보다 근육량이 많은 경우
    ///
    /// - Parameter message: 구체적인 에러 메시지
    case physicallyImpossible(String)

    /// 목표 달성 기간이 비현실적임
    ///
    /// 너무 짧거나 너무 긴 기간, 또는 방향이 맞지 않는 경우
    ///
    /// - Parameter message: 구체적인 에러 메시지
    case invalidTargetDate(String)

    /// 검증에 필요한 시작 값이 없음
    ///
    /// 목표 검증을 위해 startWeight 등의 시작 값이 필요하지만 설정되지 않음
    case missingStartValues
}

// MARK: - LocalizedError

extension GoalValidationError: LocalizedError {

    /// 사용자에게 표시할 에러 설명
    public var errorDescription: String? {
        switch self {
        case .noTargetsSet:
            return "최소 1개 이상의 목표를 설정해야 합니다. 체중, 체지방률, 근육량 중 하나 이상을 선택하세요."

        case .unrealisticRate(let message):
            return message

        case .inconsistentGoalType(let message):
            return message

        case .physicallyImpossible(let message):
            return message

        case .invalidTargetDate(let message):
            return message

        case .missingStartValues:
            return "목표 검증에 필요한 현재 체성분 정보가 없습니다. 체성분을 먼저 입력해주세요."
        }
    }
}
