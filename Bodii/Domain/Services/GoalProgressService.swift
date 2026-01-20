//
//  GoalProgressService.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-18.
//

import Foundation

/// 목표 진행률 계산 서비스
///
/// 현재 진행 상황과 목표 값을 비교하여 진행률을 계산하고, 마일스톤 달성 여부를 확인합니다.
///
/// ## 진행률 계산 공식
/// ```
/// 진행률(%) = (현재값 - 시작값) / (목표값 - 시작값) × 100
/// ```
///
/// ## 마일스톤
/// - 25%: 첫 번째 마일스톤
/// - 50%: 중간 지점
/// - 75%: 3/4 지점
/// - 100%: 목표 달성
///
/// ## 방향 처리
/// - **감량 (Loss)**: 시작값 > 목표값 (감소 방향)
/// - **증량 (Gain)**: 시작값 < 목표값 (증가 방향)
///
/// 감량/증량 모두 동일한 공식을 사용하며, 진행률은 0% ~ 100%로 정규화됩니다.
///
/// - Example:
/// ```swift
/// // 체중 감량 목표: 70kg → 65kg (현재 67kg)
/// let progress = GoalProgressService.calculateProgress(
///     current: Decimal(67.0),
///     start: Decimal(70.0),
///     target: Decimal(65.0)
/// )
/// // 결과: 60% 진행
/// // 계산: (67 - 70) / (65 - 70) × 100 = -3 / -5 × 100 = 60%
///
/// // 근육량 증량 목표: 30kg → 35kg (현재 33kg)
/// let muscleProgress = GoalProgressService.calculateProgress(
///     current: Decimal(33.0),
///     start: Decimal(30.0),
///     target: Decimal(35.0)
/// )
/// // 결과: 60% 진행
/// // 계산: (33 - 30) / (35 - 30) × 100 = 3 / 5 × 100 = 60%
/// ```
enum GoalProgressService {

    // MARK: - Public Methods

    /// 목표 진행률을 계산합니다.
    ///
    /// 시작값, 현재값, 목표값을 기반으로 진행률을 계산합니다.
    /// 감량/증량 방향에 관계없이 동일한 공식을 사용하며, 0% ~ 100%로 정규화됩니다.
    ///
    /// - Parameters:
    ///   - current: 현재 값
    ///   - start: 시작 값 (목표 설정 시점)
    ///   - target: 목표 값
    ///
    /// - Returns: 진행률 결과 (백분율, 남은 값, 방향)
    ///
    /// - Example:
    /// ```swift
    /// // 체중 감량: 70kg → 65kg (현재 67kg)
    /// let progress = GoalProgressService.calculateProgress(
    ///     current: Decimal(67.0),
    ///     start: Decimal(70.0),
    ///     target: Decimal(65.0)
    /// )
    /// // progress.percentage = 60.0
    /// // progress.remaining = 2.0 (67 - 65)
    /// // progress.direction = .loss
    /// ```
    static func calculateProgress(
        current: Decimal,
        start: Decimal,
        target: Decimal
    ) -> ProgressResult {
        // 1. 방향 결정
        let direction = determineDirection(start: start, target: target)

        // 2. 남은 값 계산
        let remaining = abs(target - current)

        // 3. 진행률 계산
        let totalChange = target - start
        let currentChange = current - start

        // 분모가 0인 경우 처리 (시작값과 목표값이 같음)
        guard totalChange != 0 else {
            // 이미 목표 도달 (또는 목표와 시작이 동일)
            return ProgressResult(
                percentage: current == target ? 100.0 : 0.0,
                remaining: remaining,
                direction: direction
            )
        }

        // 진행률 계산: (현재 변화량 / 전체 변화량) × 100
        let progressPct = (currentChange / totalChange) * 100

        // 진행률을 0 ~ 150 범위로 제한 (150%까지 허용 - 목표 초과 달성)
        let clampedProgress = max(0, min(150, progressPct))

        return ProgressResult(
            percentage: clampedProgress,
            remaining: remaining,
            direction: direction
        )
    }

    /// 목표의 전체 진행 상황을 계산합니다.
    ///
    /// 체중, 체지방률, 근육량 목표의 진행률을 각각 계산하고,
    /// 달성된 마일스톤을 확인합니다.
    ///
    /// - Parameters:
    ///   - goal: 목표 엔티티
    ///   - currentWeight: 현재 체중 (kg)
    ///   - currentBodyFatPct: 현재 체지방률 (%)
    ///   - currentMuscleMass: 현재 근육량 (kg)
    ///
    /// - Returns: 전체 목표 진행 상황
    ///
    /// - Example:
    /// ```swift
    /// let goalProgress = GoalProgressService.calculateGoalProgress(
    ///     goal: goal,
    ///     currentWeight: Decimal(67.0),
    ///     currentBodyFatPct: Decimal(20.0),
    ///     currentMuscleMass: nil
    /// )
    /// // goalProgress.weightProgress = ProgressResult(60%, ...)
    /// // goalProgress.bodyFatProgress = ProgressResult(40%, ...)
    /// // goalProgress.muscleProgress = nil
    /// // goalProgress.overallProgress = 50% (평균)
    /// ```
    static func calculateGoalProgress(
        goal: Goal,
        currentWeight: Decimal?,
        currentBodyFatPct: Decimal?,
        currentMuscleMass: Decimal?
    ) -> GoalProgressResult {
        // 1. 각 목표별 진행률 계산
        var weightProgress: ProgressResult?
        var bodyFatProgress: ProgressResult?
        var muscleProgress: ProgressResult?

        if let targetNS = goal.targetWeight,
           let startNS = goal.startWeight,
           let current = currentWeight {
            let target = targetNS.decimalValue
            let start = startNS.decimalValue
            weightProgress = calculateProgress(current: current, start: start, target: target)
        }

        if let targetNS = goal.targetBodyFatPct,
           let startNS = goal.startBodyFatPct,
           let current = currentBodyFatPct {
            let target = targetNS.decimalValue
            let start = startNS.decimalValue
            bodyFatProgress = calculateProgress(current: current, start: start, target: target)
        }

        if let targetNS = goal.targetMuscleMass,
           let startNS = goal.startMuscleMass,
           let current = currentMuscleMass {
            let target = targetNS.decimalValue
            let start = startNS.decimalValue
            muscleProgress = calculateProgress(current: current, start: start, target: target)
        }

        // 2. 전체 진행률 계산 (설정된 목표들의 평균)
        let progressValues = [weightProgress, bodyFatProgress, muscleProgress]
            .compactMap { $0?.percentage }

        let overallProgress = progressValues.isEmpty
            ? 0.0
            : progressValues.reduce(0, +) / Decimal(progressValues.count)

        // 3. 마일스톤 확인
        let achievedMilestones = detectMilestones(progressPercentage: overallProgress)

        return GoalProgressResult(
            weightProgress: weightProgress,
            bodyFatProgress: bodyFatProgress,
            muscleProgress: muscleProgress,
            overallProgress: overallProgress,
            achievedMilestones: achievedMilestones
        )
    }

    /// 달성한 마일스톤을 감지합니다.
    ///
    /// 진행률을 기반으로 어떤 마일스톤을 달성했는지 확인합니다.
    ///
    /// - Parameter progressPercentage: 진행률 (%)
    ///
    /// - Returns: 달성한 마일스톤 목록
    ///
    /// - Example:
    /// ```swift
    /// let milestones = GoalProgressService.detectMilestones(progressPercentage: 60.0)
    /// // 결과: [.quarter, .half]
    ///
    /// let allMilestones = GoalProgressService.detectMilestones(progressPercentage: 100.0)
    /// // 결과: [.quarter, .half, .threeQuarters, .complete]
    /// ```
    static func detectMilestones(progressPercentage: Decimal) -> [Milestone] {
        var milestones: [Milestone] = []

        if progressPercentage >= 25 {
            milestones.append(.quarter)
        }

        if progressPercentage >= 50 {
            milestones.append(.half)
        }

        if progressPercentage >= 75 {
            milestones.append(.threeQuarters)
        }

        if progressPercentage >= 100 {
            milestones.append(.complete)
        }

        return milestones
    }

    /// 새로 달성한 마일스톤을 확인합니다.
    ///
    /// 이전에 달성한 마일스톤과 현재 달성한 마일스톤을 비교하여
    /// 새로 달성한 마일스톤만 반환합니다.
    ///
    /// - Parameters:
    ///   - currentProgress: 현재 진행률 (%)
    ///   - previousProgress: 이전 진행률 (%)
    ///
    /// - Returns: 새로 달성한 마일스톤 목록
    ///
    /// - Example:
    /// ```swift
    /// // 이전: 40%, 현재: 60%
    /// let newMilestones = GoalProgressService.detectNewMilestones(
    ///     currentProgress: 60.0,
    ///     previousProgress: 40.0
    /// )
    /// // 결과: [.half] (50% 마일스톤 새로 달성)
    /// ```
    static func detectNewMilestones(
        currentProgress: Decimal,
        previousProgress: Decimal
    ) -> [Milestone] {
        let currentMilestones = Set(detectMilestones(progressPercentage: currentProgress))
        let previousMilestones = Set(detectMilestones(progressPercentage: previousProgress))

        let newMilestones = currentMilestones.subtracting(previousMilestones)

        // 마일스톤 순서대로 정렬
        return Milestone.allCases.filter { newMilestones.contains($0) }
    }

    // MARK: - Private Helper Methods

    /// 목표 방향을 결정합니다.
    ///
    /// - Parameters:
    ///   - start: 시작 값
    ///   - target: 목표 값
    ///
    /// - Returns: 목표 방향 (감량 또는 증량)
    private static func determineDirection(start: Decimal, target: Decimal) -> ProgressDirection {
        return target < start ? .loss : .gain
    }
}

// MARK: - Supporting Types

/// 진행률 계산 결과
///
/// 개별 목표 항목(체중, 체지방률, 근육량)의 진행률 정보를 담습니다.
public struct ProgressResult {
    /// 진행률 (%)
    ///
    /// 0% ~ 100%: 정상 범위
    /// 100% 초과: 목표 초과 달성
    public let percentage: Decimal

    /// 목표까지 남은 값 (절댓값)
    ///
    /// 예: 목표 65kg, 현재 67kg → 2kg
    public let remaining: Decimal

    /// 목표 방향 (감량 또는 증량)
    public let direction: ProgressDirection
}

/// 목표 방향
public enum ProgressDirection {
    /// 감량 (시작값 > 목표값)
    case loss

    /// 증량 (시작값 < 목표값)
    case gain
}

/// 전체 목표 진행 상황
///
/// 모든 목표 항목의 진행률과 마일스톤 정보를 담습니다.
public struct GoalProgressResult {
    /// 체중 진행률
    public let weightProgress: ProgressResult?

    /// 체지방률 진행률
    public let bodyFatProgress: ProgressResult?

    /// 근육량 진행률
    public let muscleProgress: ProgressResult?

    /// 전체 진행률 (설정된 목표들의 평균) (%)
    public let overallProgress: Decimal

    /// 달성한 마일스톤 목록
    public let achievedMilestones: [Milestone]
}

/// 목표 마일스톤
public enum Milestone: String, CaseIterable, Hashable {
    /// 25% 달성
    case quarter = "25%"

    /// 50% 달성
    case half = "50%"

    /// 75% 달성
    case threeQuarters = "75%"

    /// 100% 달성 (목표 완료)
    case complete = "100%"

    /// 마일스톤 백분율 값
    public var percentage: Decimal {
        switch self {
        case .quarter: return 25
        case .half: return 50
        case .threeQuarters: return 75
        case .complete: return 100
        }
    }

    /// 마일스톤 표시 이름
    public var displayName: String {
        switch self {
        case .quarter: return "1/4 달성"
        case .half: return "절반 달성"
        case .threeQuarters: return "3/4 달성"
        case .complete: return "목표 달성"
        }
    }
}

// 📚 학습 포인트: Decimal 확장 메서드 중복 방지
// Decimal 관련 확장 메서드는 Shared/Extensions/Decimal+Extensions.swift에 정의됨
// 해당 파일의 rounded(to:) 메서드 사용
