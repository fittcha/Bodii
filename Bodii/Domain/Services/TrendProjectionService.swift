//
//  TrendProjectionService.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-18.
//

import Foundation

/// 트렌드 분석 및 목표 달성 예측 서비스
///
/// 최근 14일간의 체성분 데이터를 분석하여 변화 추세를 계산하고,
/// 현재 추세가 유지될 경우 목표 달성 예상 일자를 예측합니다.
///
/// ## 트렌드 계산 방식
/// - 최근 14일간의 데이터 포인트를 사용하여 선형 회귀 분석
/// - 최소 2개 이상의 데이터 포인트 필요
/// - 데이터 포인트가 많을수록 신뢰도 향상
///
/// ## 신뢰도 수준
/// - **Low (낮음)**: 2-4개 데이터 포인트 (최소한의 추세 파악 가능)
/// - **Medium (중간)**: 5-9개 데이터 포인트 (적절한 추세 파악)
/// - **High (높음)**: 10개 이상 데이터 포인트 (신뢰도 높은 추세)
///
/// ## 예상 완료일 계산
/// ```
/// 남은 변화량 = 목표값 - 현재값
/// 예상 소요 일수 = 남은 변화량 / 일일 변화율
/// 예상 완료일 = 오늘 + 예상 소요 일수
/// ```
///
/// - Example:
/// ```swift
/// // 14일간 체중 데이터로 트렌드 계산
/// let records = try await bodyRepository.fetchRecent(days: 14)
/// let trend = TrendProjectionService.calculateTrend(
///     records: records,
///     for: .weight
/// )
/// // trend?.weeklyRate = -0.4kg/week (주당 0.4kg 감량 중)
///
/// // 목표 달성 예상일 계산
/// let goal = Goal(targetWeight: 65.0, startWeight: 70.0)
/// let projection = TrendProjectionService.projectCompletionDate(
///     goal: goal,
///     currentValue: 67.0,
///     trend: trend
/// )
/// // projection?.daysToCompletion = 35일 (67kg → 65kg, 하루 -0.057kg)
/// ```
enum TrendProjectionService {

    // MARK: - Constants

    /// 트렌드 분석에 사용할 기간 (일)
    private static let trendAnalysisPeriodDays = 14

    /// 최소 필요한 데이터 포인트 수
    private static let minimumDataPoints = 2

    /// "계획대로" 판단 기준 (±10%)
    private static let onTrackTolerance: Decimal = 10.0

    /// 의미있는 변화로 간주할 최소 변화율 (주당 절댓값)
    private static let minimumMeaningfulWeeklyChange: Decimal = 0.01

    // MARK: - Public Methods

    /// 최근 데이터를 기반으로 트렌드를 계산합니다.
    ///
    /// 선형 회귀 방식으로 일일 변화율을 계산합니다.
    /// 데이터 포인트가 부족하거나 추세를 파악할 수 없는 경우 nil을 반환합니다.
    ///
    /// - Parameters:
    ///   - records: 체성분 기록 목록 (최근 14일 권장)
    ///   - metric: 분석할 지표 (체중/체지방률/근육량)
    ///
    /// - Returns: 트렌드 분석 결과 (데이터 부족 시 nil)
    ///
    /// - Example:
    /// ```swift
    /// let records = try await bodyRepository.fetchRecent(days: 14)
    /// let weightTrend = TrendProjectionService.calculateTrend(
    ///     records: records,
    ///     for: .weight
    /// )
    ///
    /// if let trend = weightTrend {
    ///     print("일일 변화율: \(trend.dailyRate)kg/day")
    ///     print("주간 변화율: \(trend.weeklyRate)kg/week")
    ///     print("신뢰도: \(trend.confidence)")
    /// } else {
    ///     print("데이터 부족: 트렌드 계산 불가")
    /// }
    /// ```
    static func calculateTrend(
        records: [BodyCompositionEntry],
        for metric: GoalMetric
    ) -> TrendResult? {
        // 1. 데이터 포인트 확인
        guard records.count >= minimumDataPoints else {
            return nil
        }

        // 2. 날짜순 정렬 (오래된 것부터)
        let sortedRecords = records.sorted { $0.date < $1.date }

        // 3. 지표별 값 추출
        let values = sortedRecords.compactMap { record -> Decimal? in
            switch metric {
            case .weight:
                return record.weight
            case .bodyFat:
                return record.bodyFatPercent
            case .muscle:
                return record.muscleMass
            }
        }

        guard values.count >= minimumDataPoints else {
            return nil
        }

        // 4. 선형 회귀로 일일 변화율 계산
        let dailyRate = calculateLinearTrend(
            dates: sortedRecords.map { $0.date },
            values: values
        )

        // 5. 주간 변화율 계산
        let weeklyRate = dailyRate * 7

        // 6. 신뢰도 결정
        let confidence = determineConfidence(dataPointsCount: values.count)

        return TrendResult(
            dailyRate: dailyRate,
            weeklyRate: weeklyRate,
            confidence: confidence,
            dataPointsCount: values.count
        )
    }

    /// 현재 트렌드를 기반으로 목표 달성 예상일을 계산합니다.
    ///
    /// 현재 추세가 유지된다고 가정하고 목표값에 도달할 날짜를 예측합니다.
    /// 트렌드가 목표 방향과 반대이거나 변화가 없는 경우 완료일을 예측할 수 없습니다.
    ///
    /// - Parameters:
    ///   - goal: 목표 엔티티
    ///   - currentValue: 현재 값
    ///   - trend: 트렌드 분석 결과
    ///   - metric: 분석 중인 지표
    ///
    /// - Returns: 예측 결과 (예측 불가능 시 nil)
    ///
    /// - Example:
    /// ```swift
    /// let goal = Goal(targetWeight: 65.0, startWeight: 70.0)
    /// let projection = TrendProjectionService.projectCompletionDate(
    ///     goal: goal,
    ///     currentValue: 67.0,
    ///     trend: weightTrend,
    ///     metric: .weight
    /// )
    ///
    /// if let proj = projection {
    ///     if let date = proj.estimatedCompletionDate {
    ///         print("예상 달성일: \(date)")
    ///         print("남은 기간: \(proj.daysToCompletion ?? 0)일")
    ///         print("계획대로: \(proj.isOnTrack)")
    ///     }
    /// }
    /// ```
    static func projectCompletionDate(
        goal: Goal,
        currentValue: Decimal,
        trend: TrendResult,
        metric: GoalMetric
    ) -> ProjectionResult? {
        // 1. 목표값 추출
        guard let targetValue = getTargetValue(from: goal, for: metric) else {
            return nil
        }

        // 2. 계획된 주간 변화율 추출
        guard let plannedWeeklyRate = getPlannedWeeklyRate(from: goal, for: metric) else {
            return nil
        }

        // 3. 남은 변화량 계산
        let remaining = targetValue - currentValue

        // 4. 일일 변화율이 0이면 완료일 예측 불가
        guard trend.dailyRate != 0 else {
            return ProjectionResult(
                estimatedCompletionDate: nil,
                daysToCompletion: nil,
                isOnTrack: false
            )
        }

        // 5. 예상 소요 일수 계산
        let daysToCompletion = remaining / trend.dailyRate

        // 6. 방향 확인 (목표와 트렌드 방향이 일치하는지)
        let isMovingTowardGoal = (remaining > 0 && trend.dailyRate > 0) ||
                                  (remaining < 0 && trend.dailyRate < 0)

        guard isMovingTowardGoal else {
            // 목표 방향과 반대로 움직이는 경우
            return ProjectionResult(
                estimatedCompletionDate: nil,
                daysToCompletion: nil,
                isOnTrack: false
            )
        }

        // 7. 완료 예상일 계산
        let daysInt = Int(NSDecimalNumber(decimal: abs(daysToCompletion)).doubleValue)
        let estimatedDate = Calendar.current.date(byAdding: .day, value: daysInt, to: Date())

        // 8. 계획 대비 진행 상태 확인
        let comparison = compareTrendToPlanned(
            actualRate: trend.weeklyRate,
            plannedRate: plannedWeeklyRate
        )
        let isOnTrack = comparison.status == .onTrack || comparison.status == .ahead

        return ProjectionResult(
            estimatedCompletionDate: estimatedDate,
            daysToCompletion: daysInt,
            isOnTrack: isOnTrack
        )
    }

    /// 실제 트렌드와 계획된 변화율을 비교합니다.
    ///
    /// 현재 진행 속도가 계획보다 빠른지, 느린지, 계획대로인지 판단합니다.
    ///
    /// - Parameters:
    ///   - actualRate: 실제 주간 변화율
    ///   - plannedRate: 계획된 주간 변화율
    ///
    /// - Returns: 트렌드 비교 결과
    ///
    /// - Example:
    /// ```swift
    /// let comparison = TrendProjectionService.compareTrendToPlanned(
    ///     actualRate: -0.4,  // 실제 주당 0.4kg 감량
    ///     plannedRate: -0.5  // 계획 주당 0.5kg 감량
    /// )
    /// // comparison.status = .behind (계획보다 느림)
    /// // comparison.percentageOfPlan = 80% (계획의 80% 달성)
    /// ```
    static func compareTrendToPlanned(
        actualRate: Decimal,
        plannedRate: Decimal
    ) -> TrendComparison {
        // 1. 변화율이 둘 다 0이거나 계획이 0인 경우
        guard plannedRate != 0 else {
            return TrendComparison(
                actualWeeklyRate: actualRate,
                plannedWeeklyRate: plannedRate,
                percentageOfPlan: 0,
                status: .noProgress
            )
        }

        // 2. 계획 대비 비율 계산 (절댓값 기준)
        let percentageOfPlan = (abs(actualRate) / abs(plannedRate)) * 100

        // 3. 진행 상태 판단
        let status: TrendStatus
        if abs(actualRate) < minimumMeaningfulWeeklyChange {
            // 변화가 거의 없음
            status = .noProgress
        } else if abs(percentageOfPlan - 100) <= onTrackTolerance {
            // 계획의 ±10% 이내
            status = .onTrack
        } else if percentageOfPlan > 100 {
            // 계획보다 빠름
            status = .ahead
        } else {
            // 계획보다 느림
            status = .behind
        }

        return TrendComparison(
            actualWeeklyRate: actualRate,
            plannedWeeklyRate: plannedRate,
            percentageOfPlan: percentageOfPlan,
            status: status
        )
    }

    // MARK: - Private Helper Methods

    /// 선형 회귀로 일일 변화율을 계산합니다.
    ///
    /// 최소자승법(Least Squares Method)을 사용하여 기울기를 계산합니다.
    ///
    /// - Parameters:
    ///   - dates: 날짜 배열
    ///   - values: 측정값 배열
    ///
    /// - Returns: 일일 변화율 (기울기)
    private static func calculateLinearTrend(dates: [Date], values: [Decimal]) -> Decimal {
        guard dates.count == values.count, dates.count >= 2 else {
            return 0
        }

        // 1. 첫 번째 날짜를 기준점으로 삼아 x축 값 계산 (일 단위)
        let baseDate = dates[0]
        let xValues = dates.map { date -> Decimal in
            let timeInterval = date.timeIntervalSince(baseDate)
            let days = timeInterval / (24 * 60 * 60)
            return Decimal(days)
        }

        // 2. 평균 계산
        let n = Decimal(xValues.count)
        let xMean = xValues.reduce(0, +) / n
        let yMean = values.reduce(0, +) / n

        // 3. 기울기 계산: slope = Σ((x - xMean) * (y - yMean)) / Σ((x - xMean)²)
        var numerator: Decimal = 0
        var denominator: Decimal = 0

        for i in 0..<xValues.count {
            let xDiff = xValues[i] - xMean
            let yDiff = values[i] - yMean
            numerator += xDiff * yDiff
            denominator += xDiff * xDiff
        }

        guard denominator != 0 else {
            return 0
        }

        let slope = numerator / denominator
        return slope
    }

    /// 데이터 포인트 수에 따라 신뢰도를 결정합니다.
    ///
    /// - Parameter dataPointsCount: 데이터 포인트 개수
    /// - Returns: 트렌드 신뢰도
    private static func determineConfidence(dataPointsCount: Int) -> TrendConfidence {
        switch dataPointsCount {
        case 2...4:
            return .low
        case 5...9:
            return .medium
        default:
            return .high
        }
    }

    /// 목표에서 지표별 목표값을 추출합니다.
    ///
    /// - Parameters:
    ///   - goal: 목표 엔티티
    ///   - metric: 지표
    ///
    /// - Returns: 목표값 (없으면 nil)
    private static func getTargetValue(from goal: Goal, for metric: GoalMetric) -> Decimal? {
        switch metric {
        case .weight:
            return goal.targetWeight?.decimalValue
        case .bodyFat:
            return goal.targetBodyFatPct?.decimalValue
        case .muscle:
            return goal.targetMuscleMass?.decimalValue
        }
    }

    /// 목표에서 지표별 계획된 주간 변화율을 추출합니다.
    ///
    /// - Parameters:
    ///   - goal: 목표 엔티티
    ///   - metric: 지표
    ///
    /// - Returns: 계획된 주간 변화율 (없으면 nil)
    private static func getPlannedWeeklyRate(from goal: Goal, for metric: GoalMetric) -> Decimal? {
        switch metric {
        case .weight:
            return goal.weeklyWeightRate?.decimalValue
        case .bodyFat:
            return goal.weeklyFatPctRate?.decimalValue
        case .muscle:
            return goal.weeklyMuscleRate?.decimalValue
        }
    }
}

// MARK: - Supporting Types

/// 목표 지표 종류
public enum GoalMetric {
    /// 체중 (kg)
    case weight

    /// 체지방률 (%)
    case bodyFat

    /// 근육량 (kg)
    case muscle
}

/// 트렌드 분석 결과
///
/// 최근 데이터를 기반으로 계산된 변화 추세 정보
public struct TrendResult {
    /// 일일 변화율
    ///
    /// 양수: 증가 추세, 음수: 감소 추세
    public let dailyRate: Decimal

    /// 주간 변화율 (dailyRate × 7)
    ///
    /// 계획된 변화율과 비교하기 위해 주간 단위로 환산
    public let weeklyRate: Decimal

    /// 트렌드 신뢰도
    ///
    /// 데이터 포인트 수에 따라 결정됨
    public let confidence: TrendConfidence

    /// 분석에 사용된 데이터 포인트 수
    public let dataPointsCount: Int
}

/// 트렌드 신뢰도 수준
public enum TrendConfidence: String {
    /// 낮음 (2-4개 데이터 포인트)
    case low = "낮음"

    /// 중간 (5-9개 데이터 포인트)
    case medium = "중간"

    /// 높음 (10개 이상 데이터 포인트)
    case high = "높음"
}

/// 목표 달성 예측 결과
public struct ProjectionResult {
    /// 예상 완료일
    ///
    /// 현재 트렌드가 유지될 경우 목표 달성 예상 일자
    /// 예측 불가능한 경우 nil (트렌드가 목표 반대 방향이거나 변화 없음)
    public let estimatedCompletionDate: Date?

    /// 완료까지 남은 일수
    ///
    /// 예상 완료일까지의 일수
    public let daysToCompletion: Int?

    /// 계획대로 진행 중인지 여부
    ///
    /// true: 계획 대비 ±10% 이내 또는 더 빠름
    /// false: 계획보다 10% 이상 느리거나 반대 방향
    public let isOnTrack: Bool
}

/// 트렌드 비교 결과
///
/// 실제 변화율과 계획된 변화율의 비교 정보
public struct TrendComparison {
    /// 실제 주간 변화율
    public let actualWeeklyRate: Decimal

    /// 계획된 주간 변화율
    public let plannedWeeklyRate: Decimal

    /// 계획 대비 달성률 (%)
    ///
    /// (실제 변화율 / 계획 변화율) × 100
    /// 예: 120% = 계획보다 20% 빠름, 80% = 계획보다 20% 느림
    public let percentageOfPlan: Decimal

    /// 진행 상태
    public let status: TrendStatus
}

/// 트렌드 진행 상태
public enum TrendStatus {
    /// 계획보다 빠름 (100% 초과)
    case ahead

    /// 계획대로 (계획의 ±10% 이내)
    case onTrack

    /// 계획보다 느림 (90% 미만)
    case behind

    /// 진행 없음 (변화가 거의 없음)
    case noProgress

    /// 상태 표시 문구
    public var displayName: String {
        switch self {
        case .ahead:
            return "계획보다 빠름"
        case .onTrack:
            return "계획대로"
        case .behind:
            return "계획보다 느림"
        case .noProgress:
            return "진행 없음"
        }
    }
}
