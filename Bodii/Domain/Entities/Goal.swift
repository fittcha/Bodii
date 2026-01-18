//
//  Goal.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-11.
//

// 📚 학습 포인트: Goal Target Validation
// 목표 체성분의 물리적 일관성 검증 - 목표 제지방량 ≥ 목표 근육량
// 💡 Java 비교: Bean Validation의 커스텀 검증 로직과 유사하지만 Swift는 메서드로 구현

import Foundation

// MARK: - Goal

/// 사용자 목표 도메인 엔티티
/// - 사용자의 체중/체지방/근육량 목표와 목표 달성을 위한 계획 관리
/// - 목표 설정 시 물리적 일관성 검증 (목표 제지방량 ≥ 목표 근육량)
/// - 목표 기반 일일 칼로리 목표 계산
///
/// ## 주요 기능
/// - 목표 유형 관리 (감량/유지/증량)
/// - 목표 체성분 설정 (체중, 체지방률, 근육량)
/// - 주간 변화율 설정 (체중, 체지방률, 근육량)
/// - 시작 시점 체성분 및 대사 정보 스냅샷
/// - 일일 칼로리 목표 계산
/// - 목표 물리적 일관성 검증
///
/// ## 검증 규칙
/// ```
/// 목표 제지방량 = 목표 체중 - 목표 체지방량
/// 목표 체지방량 = 목표 체중 × (목표 체지방률 / 100)
/// 검증: 목표 제지방량 ≥ 목표 근육량 (근육은 제지방의 일부)
/// ```
///
/// ## 사용 예시
/// ```swift
/// // 1. 체중 감량 목표 생성
/// let goal = Goal.create(
///     userId: userId,
///     goalType: .lose,
///     targetWeight: 65.0,
///     targetBodyFatPct: 15.0,
///     targetMuscleMass: 30.0,
///     weeklyWeightRate: -0.5,
///     weeklyFatPctRate: -0.5,
///     weeklyMuscleRate: 0.0,
///     startWeight: 70.0,
///     startBodyFatPct: 20.0,
///     startMuscleMass: 30.0,
///     startBMR: 1650,
///     startTDEE: 2550,
///     dailyCalorieTarget: 2000,
///     targetDate: Date().addingTimeInterval(60 * 60 * 24 * 70) // 10주 후
/// )
///
/// // 2. 목표 검증
/// let validation = goal.validatePhysicalConsistency()
/// if !validation.isValid {
///     print("목표가 물리적으로 불가능합니다: \(validation.errorMessage ?? "")")
/// }
/// ```
struct Goal: Identifiable, Codable, Equatable {

    // MARK: - Properties

    // MARK: Identifier

    /// 목표 고유 식별자
    /// - UUID 타입으로 전역 고유성 보장
    let id: UUID

    /// 사용자 고유 식별자
    /// - User 엔티티와의 외래 키 관계
    let userId: UUID

    // MARK: Goal Type

    /// 목표 유형
    /// - lose: 체중 감량
    /// - maintain: 체중 유지
    /// - gain: 체중 증량
    var goalType: GoalType

    // MARK: Target Values

    /// 목표 체중 (kg)
    /// - 허용 범위: 20-300kg (ValidationService.validateWeight로 검증)
    /// - 목표 달성 시점의 체중
    var targetWeight: Decimal

    /// 목표 체지방률 (%)
    /// - 허용 범위: 3-60% (ValidationService.validateBodyFatPercent로 검증)
    /// - 목표 달성 시점의 체지방률
    var targetBodyFatPct: Decimal

    /// 목표 근육량 (kg)
    /// - 허용 범위: 10-60kg (ValidationService.validateMuscleMass로 검증)
    /// - 목표 달성 시점의 근육량
    /// - 검증: 목표 근육량 ≤ 목표 제지방량
    var targetMuscleMass: Decimal

    // MARK: Weekly Change Rates

    /// 주간 체중 변화율 (kg/week)
    /// - 양수: 체중 증가, 음수: 체중 감소
    /// - 예: -0.5 = 주당 0.5kg 감량
    /// - 권장 범위: -1.0 ~ +1.0kg/week (건강한 변화율)
    var weeklyWeightRate: Decimal

    /// 주간 체지방률 변화율 (%/week)
    /// - 양수: 체지방률 증가, 음수: 체지방률 감소
    /// - 예: -0.5 = 주당 0.5% 감소
    /// - 권장 범위: -1.0 ~ +1.0%/week
    var weeklyFatPctRate: Decimal

    /// 주간 근육량 변화율 (kg/week)
    /// - 양수: 근육량 증가, 음수: 근육량 감소
    /// - 예: +0.2 = 주당 0.2kg 증가
    /// - 권장 범위: -0.5 ~ +0.5kg/week
    var weeklyMuscleRate: Decimal

    // MARK: Start Values

    /// 시작 시점 체중 (kg)
    /// - 목표 설정 시점의 체중 스냅샷
    /// - 목표 진행률 계산에 사용
    let startWeight: Decimal

    /// 시작 시점 체지방률 (%)
    /// - 목표 설정 시점의 체지방률 스냅샷
    let startBodyFatPct: Decimal

    /// 시작 시점 근육량 (kg)
    /// - 목표 설정 시점의 근육량 스냅샷
    let startMuscleMass: Decimal

    /// 시작 시점 기초대사량 (kcal/day)
    /// - 목표 설정 시점의 BMR 스냅샷
    let startBMR: Int

    /// 시작 시점 일일 총 에너지 소비량 (kcal/day)
    /// - 목표 설정 시점의 TDEE 스냅샷
    let startTDEE: Int

    // MARK: Calorie Target

    /// 일일 칼로리 목표 (kcal/day)
    /// - 목표 달성을 위한 하루 섭취 칼로리 목표
    /// - 계산식: TDEE + (목표 체중 변화 × 7700kcal/kg) / 7일
    /// - 예: 주당 0.5kg 감량 → dailyCalorieTarget = TDEE - 550kcal
    var dailyCalorieTarget: Int

    // MARK: Status

    /// 목표 활성화 여부
    /// - true: 현재 진행 중인 목표
    /// - false: 완료되었거나 중단된 목표
    /// - 사용자당 하나의 활성 목표만 존재 가능
    var isActive: Bool

    // MARK: Dates

    /// 목표 시작일
    /// - 목표 설정 시점의 날짜
    let startDate: Date

    /// 목표 달성 예정일
    /// - 주간 변화율 기반 계산된 목표 달성일
    /// - 사용자가 직접 수정 가능
    var targetDate: Date

    // MARK: Timestamps

    /// 생성 시각
    let createdAt: Date

    /// 마지막 수정 시각
    var updatedAt: Date

    // MARK: - Computed Properties

    /// 목표 제지방량 (kg)
    /// - 계산 공식: 목표 체중 - 목표 체지방량
    /// - 목표 체지방량 = 목표 체중 × (목표 체지방률 / 100)
    /// - 근육량 검증에 사용: 목표 근육량 ≤ 목표 제지방량
    ///
    /// ## 참고
    /// 제지방량(Lean Body Mass, LBM)은 체중에서 체지방량을 제외한 모든 조직의 무게
    /// - 포함: 근육, 뼈, 장기, 수분 등
    /// - 근육량은 제지방량의 일부이므로 반드시 제지방량보다 작거나 같아야 함
    var targetLeanBodyMass: Decimal {
        let targetBodyFatMass = targetWeight * (targetBodyFatPct / 100)
        return targetWeight - targetBodyFatMass
    }

    /// 시작 시점 제지방량 (kg)
    /// - 계산 공식: 시작 체중 - 시작 체지방량
    var startLeanBodyMass: Decimal {
        let startBodyFatMass = startWeight * (startBodyFatPct / 100)
        return startWeight - startBodyFatMass
    }

    /// 목표까지 남은 체중 변화량 (kg)
    /// - 양수: 증량 필요, 음수: 감량 필요, 0: 목표 달성
    /// - 현재 체중과 비교하려면 외부에서 currentWeight 제공 필요
    var targetWeightChange: Decimal {
        targetWeight - startWeight
    }

    /// 목표 기간 (일)
    /// - 시작일부터 목표일까지의 일수
    var durationInDays: Int {
        Calendar.current.dateComponents([.day], from: startDate, to: targetDate).day ?? 0
    }

    /// 목표 기간 (주)
    /// - 시작일부터 목표일까지의 주수 (소수점 포함)
    var durationInWeeks: Double {
        Double(durationInDays) / 7.0
    }

    // MARK: - Factory Methods

    /// Goal 생성 (모든 필드 명시)
    /// - Parameters:
    ///   - userId: 사용자 고유 식별자
    ///   - goalType: 목표 유형 (감량/유지/증량)
    ///   - targetWeight: 목표 체중 (kg)
    ///   - targetBodyFatPct: 목표 체지방률 (%)
    ///   - targetMuscleMass: 목표 근육량 (kg)
    ///   - weeklyWeightRate: 주간 체중 변화율 (kg/week)
    ///   - weeklyFatPctRate: 주간 체지방률 변화율 (%/week)
    ///   - weeklyMuscleRate: 주간 근육량 변화율 (kg/week)
    ///   - startWeight: 시작 체중 (kg)
    ///   - startBodyFatPct: 시작 체지방률 (%)
    ///   - startMuscleMass: 시작 근육량 (kg)
    ///   - startBMR: 시작 BMR (kcal/day)
    ///   - startTDEE: 시작 TDEE (kcal/day)
    ///   - dailyCalorieTarget: 일일 칼로리 목표 (kcal/day)
    ///   - targetDate: 목표 달성 예정일
    /// - Returns: 생성된 Goal 엔티티
    ///
    /// ## 사용 예시
    /// ```swift
    /// let goal = Goal.create(
    ///     userId: userId,
    ///     goalType: .lose,
    ///     targetWeight: 65.0,
    ///     targetBodyFatPct: 15.0,
    ///     targetMuscleMass: 30.0,
    ///     weeklyWeightRate: -0.5,
    ///     weeklyFatPctRate: -0.5,
    ///     weeklyMuscleRate: 0.0,
    ///     startWeight: 70.0,
    ///     startBodyFatPct: 20.0,
    ///     startMuscleMass: 30.0,
    ///     startBMR: 1650,
    ///     startTDEE: 2550,
    ///     dailyCalorieTarget: 2000,
    ///     targetDate: Date().addingTimeInterval(60 * 60 * 24 * 70)
    /// )
    /// ```
    static func create(
        userId: UUID,
        goalType: GoalType,
        targetWeight: Decimal,
        targetBodyFatPct: Decimal,
        targetMuscleMass: Decimal,
        weeklyWeightRate: Decimal,
        weeklyFatPctRate: Decimal,
        weeklyMuscleRate: Decimal,
        startWeight: Decimal,
        startBodyFatPct: Decimal,
        startMuscleMass: Decimal,
        startBMR: Int,
        startTDEE: Int,
        dailyCalorieTarget: Int,
        targetDate: Date
    ) -> Goal {
        let now = Date()
        return Goal(
            id: UUID(),
            userId: userId,
            goalType: goalType,
            targetWeight: targetWeight,
            targetBodyFatPct: targetBodyFatPct,
            targetMuscleMass: targetMuscleMass,
            weeklyWeightRate: weeklyWeightRate,
            weeklyFatPctRate: weeklyFatPctRate,
            weeklyMuscleRate: weeklyMuscleRate,
            startWeight: startWeight,
            startBodyFatPct: startBodyFatPct,
            startMuscleMass: startMuscleMass,
            startBMR: startBMR,
            startTDEE: startTDEE,
            dailyCalorieTarget: dailyCalorieTarget,
            isActive: true,
            startDate: now,
            targetDate: targetDate,
            createdAt: now,
            updatedAt: now
        )
    }

    // MARK: - Validation Methods

    /// 목표의 물리적 일관성 검증
    /// - Returns: 검증 결과
    ///
    /// ## 검증 규칙
    /// ```
    /// 목표 제지방량 = 목표 체중 - (목표 체중 × 목표 체지방률 / 100)
    /// 검증: 목표 제지방량 ≥ 목표 근육량
    /// ```
    ///
    /// ## 검증이 필요한 이유
    /// 근육은 제지방량의 일부입니다. 따라서 근육량이 제지방량보다 클 수 없습니다.
    /// 예를 들어, 목표 체중 70kg, 목표 체지방률 10%일 때:
    /// - 목표 체지방량 = 70 × 0.1 = 7kg
    /// - 목표 제지방량 = 70 - 7 = 63kg
    /// - 목표 근육량은 최대 63kg까지만 가능
    ///
    /// ## 사용 예시
    /// ```swift
    /// let goal = Goal.create(...)
    /// let validation = goal.validatePhysicalConsistency()
    /// if !validation.isValid {
    ///     print("오류: \(validation.errorMessage ?? "")")
    /// }
    /// ```
    func validatePhysicalConsistency() -> ValidationResult {
        // 목표 제지방량 계산
        let targetBodyFatMass = targetWeight * (targetBodyFatPct / 100)
        let targetLBM = targetWeight - targetBodyFatMass

        // 근육량 ≤ 제지방량 검증
        guard targetMuscleMass <= targetLBM else {
            let lbmDouble = NSDecimalNumber(decimal: targetLBM).doubleValue
            let muscleDouble = NSDecimalNumber(decimal: targetMuscleMass).doubleValue
            return .failure(
                "목표 근육량(\(String(format: "%.1f", muscleDouble))kg)이 목표 제지방량(\(String(format: "%.1f", lbmDouble))kg)보다 클 수 없습니다. " +
                "제지방량은 체중에서 체지방을 제외한 모든 조직(근육, 뼈, 장기 등)의 무게이며, 근육량은 제지방량의 일부입니다."
            )
        }

        return .success
    }

    // MARK: - Update Methods

    /// 목표 체성분 업데이트 (물리적 일관성 검증 포함)
    /// - Parameters:
    ///   - targetWeight: 새로운 목표 체중
    ///   - targetBodyFatPct: 새로운 목표 체지방률
    ///   - targetMuscleMass: 새로운 목표 근육량
    /// - Returns: 업데이트된 Goal (검증 실패 시 nil)
    ///
    /// ## 사용 예시
    /// ```swift
    /// if let updatedGoal = goal.updatingTargets(
    ///     targetWeight: 68.0,
    ///     targetBodyFatPct: 16.0,
    ///     targetMuscleMass: 31.0
    /// ) {
    ///     // 검증 통과 - 업데이트된 목표 사용
    /// } else {
    ///     // 검증 실패 - 물리적으로 불가능한 목표
    /// }
    /// ```
    func updatingTargets(
        targetWeight: Decimal,
        targetBodyFatPct: Decimal,
        targetMuscleMass: Decimal
    ) -> Goal? {
        // 임시 Goal 생성하여 검증
        let tempGoal = Goal(
            id: id,
            userId: userId,
            goalType: goalType,
            targetWeight: targetWeight,
            targetBodyFatPct: targetBodyFatPct,
            targetMuscleMass: targetMuscleMass,
            weeklyWeightRate: weeklyWeightRate,
            weeklyFatPctRate: weeklyFatPctRate,
            weeklyMuscleRate: weeklyMuscleRate,
            startWeight: startWeight,
            startBodyFatPct: startBodyFatPct,
            startMuscleMass: startMuscleMass,
            startBMR: startBMR,
            startTDEE: startTDEE,
            dailyCalorieTarget: dailyCalorieTarget,
            isActive: isActive,
            startDate: startDate,
            targetDate: targetDate,
            createdAt: createdAt,
            updatedAt: Date()
        )

        // 물리적 일관성 검증
        guard tempGoal.validatePhysicalConsistency().isValid else {
            return nil
        }

        return tempGoal
    }

    /// 주간 변화율 업데이트
    /// - Parameters:
    ///   - weeklyWeightRate: 새로운 주간 체중 변화율
    ///   - weeklyFatPctRate: 새로운 주간 체지방률 변화율
    ///   - weeklyMuscleRate: 새로운 주간 근육량 변화율
    /// - Returns: 업데이트된 Goal
    func updatingWeeklyRates(
        weeklyWeightRate: Decimal,
        weeklyFatPctRate: Decimal,
        weeklyMuscleRate: Decimal
    ) -> Goal {
        Goal(
            id: id,
            userId: userId,
            goalType: goalType,
            targetWeight: targetWeight,
            targetBodyFatPct: targetBodyFatPct,
            targetMuscleMass: targetMuscleMass,
            weeklyWeightRate: weeklyWeightRate,
            weeklyFatPctRate: weeklyFatPctRate,
            weeklyMuscleRate: weeklyMuscleRate,
            startWeight: startWeight,
            startBodyFatPct: startBodyFatPct,
            startMuscleMass: startMuscleMass,
            startBMR: startBMR,
            startTDEE: startTDEE,
            dailyCalorieTarget: dailyCalorieTarget,
            isActive: isActive,
            startDate: startDate,
            targetDate: targetDate,
            createdAt: createdAt,
            updatedAt: Date()
        )
    }

    /// 일일 칼로리 목표 업데이트
    /// - Parameter dailyCalorieTarget: 새로운 일일 칼로리 목표
    /// - Returns: 업데이트된 Goal
    func updatingDailyCalorieTarget(_ dailyCalorieTarget: Int) -> Goal {
        Goal(
            id: id,
            userId: userId,
            goalType: goalType,
            targetWeight: targetWeight,
            targetBodyFatPct: targetBodyFatPct,
            targetMuscleMass: targetMuscleMass,
            weeklyWeightRate: weeklyWeightRate,
            weeklyFatPctRate: weeklyFatPctRate,
            weeklyMuscleRate: weeklyMuscleRate,
            startWeight: startWeight,
            startBodyFatPct: startBodyFatPct,
            startMuscleMass: startMuscleMass,
            startBMR: startBMR,
            startTDEE: startTDEE,
            dailyCalorieTarget: dailyCalorieTarget,
            isActive: isActive,
            startDate: startDate,
            targetDate: targetDate,
            createdAt: createdAt,
            updatedAt: Date()
        )
    }

    /// 목표 활성화 상태 변경
    /// - Parameter isActive: 활성화 여부
    /// - Returns: 업데이트된 Goal
    func updatingActiveStatus(_ isActive: Bool) -> Goal {
        Goal(
            id: id,
            userId: userId,
            goalType: goalType,
            targetWeight: targetWeight,
            targetBodyFatPct: targetBodyFatPct,
            targetMuscleMass: targetMuscleMass,
            weeklyWeightRate: weeklyWeightRate,
            weeklyFatPctRate: weeklyFatPctRate,
            weeklyMuscleRate: weeklyMuscleRate,
            startWeight: startWeight,
            startBodyFatPct: startBodyFatPct,
            startMuscleMass: startMuscleMass,
            startBMR: startBMR,
            startTDEE: startTDEE,
            dailyCalorieTarget: dailyCalorieTarget,
            isActive: isActive,
            startDate: startDate,
            targetDate: targetDate,
            createdAt: createdAt,
            updatedAt: Date()
        )
    }

    /// 목표 달성일 변경
    /// - Parameter targetDate: 새로운 목표 달성 예정일
    /// - Returns: 업데이트된 Goal
    func updatingTargetDate(_ targetDate: Date) -> Goal {
        Goal(
            id: id,
            userId: userId,
            goalType: goalType,
            targetWeight: targetWeight,
            targetBodyFatPct: targetBodyFatPct,
            targetMuscleMass: targetMuscleMass,
            weeklyWeightRate: weeklyWeightRate,
            weeklyFatPctRate: weeklyFatPctRate,
            weeklyMuscleRate: weeklyMuscleRate,
            startWeight: startWeight,
            startBodyFatPct: startBodyFatPct,
            startMuscleMass: startMuscleMass,
            startBMR: startBMR,
            startTDEE: startTDEE,
            dailyCalorieTarget: dailyCalorieTarget,
            isActive: isActive,
            startDate: startDate,
            targetDate: targetDate,
            createdAt: createdAt,
            updatedAt: Date()
        )
    }
}

// MARK: - Goal + CustomStringConvertible

extension Goal: CustomStringConvertible {
    /// 디버깅용 문자열 표현
    var description: String {
        let activeStatus = isActive ? "활성" : "비활성"
        let weightChange = targetWeightChange
        let weightChangeSign = weightChange >= 0 ? "+" : ""

        return """
        Goal(
          id: \(id.uuidString.prefix(8))...,
          userId: \(userId.uuidString.prefix(8))...,
          goalType: \(goalType.displayName),
          목표: 체중 \(targetWeight)kg, 체지방률 \(targetBodyFatPct)%, 근육량 \(targetMuscleMass)kg,
          시작: 체중 \(startWeight)kg, 체지방률 \(startBodyFatPct)%, 근육량 \(startMuscleMass)kg,
          변화량: \(weightChangeSign)\(weightChange)kg,
          주간 변화율: 체중 \(weeklyWeightRate)kg/week, 체지방률 \(weeklyFatPctRate)%/week, 근육량 \(weeklyMuscleRate)kg/week,
          칼로리 목표: \(dailyCalorieTarget)kcal/day,
          기간: \(durationInDays)일 (\(String(format: "%.1f", durationInWeeks))주),
          상태: \(activeStatus),
          목표 제지방량: \(targetLeanBodyMass)kg (computed)
        )
        """
    }
}
