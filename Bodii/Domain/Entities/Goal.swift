//
//  Goal.swift
//  Bodii
//
//  Created by Auto-Claude on 2024-01-12.
//

import Foundation

/// 목표 도메인 엔티티
///
/// 사용자의 체중 관리 목표를 나타냅니다.
///
/// - Note: 최소 1개 이상의 목표 값(targetWeight, targetBodyFatPct, targetMuscleMass)을 설정해야 합니다.
///         목표 설정 시 해당 시작값과 주간 변화율을 함께 저장합니다.
///
/// - Note: 목표 정합성 검증 (앱 레벨):
///         - 체지방량 = 목표체중 × (목표체지방률 / 100)
///         - 제지방량 = 목표체중 - 체지방량
///         - 제지방량 ≥ 목표근육량 (근육은 제지방의 일부)
///
/// - Example:
/// ```swift
/// let goal = Goal(
///     id: UUID(),
///     userId: user.id,
///     goalType: .lose,
///     targetWeight: Decimal(65.0),
///     targetBodyFatPct: Decimal(18.0),
///     weeklyWeightRate: Decimal(-0.5),
///     weeklyFatPctRate: Decimal(-0.5),
///     isActive: true,
///     createdAt: Date(),
///     updatedAt: Date()
/// )
/// ```
struct Goal {
    // MARK: - Primary Key

    /// 고유 식별자
    let id: UUID

    // MARK: - Foreign Key

    /// User 참조
    let userId: UUID

    // MARK: - Goal Configuration

    /// 목표 유형 (0: 감량, 1: 유지, 2: 증량)
    var goalType: GoalType

    // MARK: - Target Values

    /// 목표 체중 (kg)
    var targetWeight: Decimal?

    /// 목표 체지방률 (%)
    var targetBodyFatPct: Decimal?

    /// 목표 근육량 (kg)
    var targetMuscleMass: Decimal?

    // MARK: - Weekly Change Rates

    /// 주간 체중 변화 (kg)
    ///
    /// 감량 시 음수, 증량 시 양수 (예: -0.5kg/week)
    var weeklyWeightRate: Decimal?

    /// 주간 체지방률 변화 (%)
    ///
    /// 감량 시 음수, 증량 시 양수
    var weeklyFatPctRate: Decimal?

    /// 주간 근육량 변화 (kg)
    ///
    /// 감량 시 음수 또는 유지, 증량 시 양수
    var weeklyMuscleRate: Decimal?

    // MARK: - Starting Values

    /// 시작 체중 (kg)
    ///
    /// 목표 설정 시점의 체중
    var startWeight: Decimal?

    /// 시작 체지방률 (%)
    ///
    /// 목표 설정 시점의 체지방률
    var startBodyFatPct: Decimal?

    /// 시작 근육량 (kg)
    ///
    /// 목표 설정 시점의 골격근량
    var startMuscleMass: Decimal?

    /// 시작 BMR (kcal)
    ///
    /// 목표 설정 시점의 기초대사량
    var startBMR: Decimal?

    /// 시작 TDEE (kcal)
    ///
    /// 목표 설정 시점의 활동대사량
    var startTDEE: Decimal?

    // MARK: - Other

    /// 일일 칼로리 목표 (kcal)
    ///
    /// 목표 달성을 위한 하루 권장 칼로리 섭취량
    var dailyCalorieTarget: Int32?

    /// 활성 목표 여부
    ///
    /// 사용자는 여러 목표를 가질 수 있으나, 활성 목표는 하나만 존재합니다.
    var isActive: Bool

    // MARK: - Metadata

    /// 생성일시
    let createdAt: Date

    /// 수정일시
    var updatedAt: Date
}

// MARK: - Identifiable

extension Goal: Identifiable {}

// MARK: - Equatable

extension Goal: Equatable {
    static func == (lhs: Goal, rhs: Goal) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Hashable

extension Goal: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
