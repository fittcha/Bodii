//
//  GetGoalProgressUseCase.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-18.
//

import Foundation

/// 목표 진행 상황 조회 유스케이스
///
/// 현재 활성 목표의 진행 상황을 조회하고, 트렌드 분석 및 예상 달성일을 계산합니다.
///
/// ## 책임
/// - 활성 목표 및 현재 체성분 조회
/// - 각 목표별 진행률 계산 (체중, 체지방률, 근육량)
/// - 14일 트렌드 분석 및 예상 달성일 계산
/// - 새로 달성한 마일스톤 감지
///
/// ## 의존성
/// - GoalRepositoryProtocol: 목표 데이터 조회
/// - BodyRepositoryProtocol: 체성분 데이터 조회
/// - GoalProgressService: 진행률 계산
/// - TrendProjectionService: 트렌드 분석 및 예측
///
/// ## 비즈니스 플로우
/// 1. 활성 목표 조회 (없으면 noActiveGoal 에러)
/// 2. 최신 체성분 기록 조회 (없으면 noBodyCompositionData 에러)
/// 3. 최근 14일간 체성분 기록 조회 (트렌드 분석용)
/// 4. 각 목표별 진행률 계산 (GoalProgressService)
/// 5. 각 목표별 트렌드 분석 및 예상 달성일 계산 (TrendProjectionService)
/// 6. 통합 결과 반환
///
/// ## 사용 예시
/// ```swift
/// let useCase = GetGoalProgressUseCase(
///     goalRepository: goalRepository,
///     bodyRepository: bodyRepository
/// )
///
/// do {
///     let progress = try await useCase.execute()
///     print("전체 진행률: \(progress.overallProgress)%")
///
///     if let weightProgress = progress.weightProgress {
///         print("체중 진행률: \(weightProgress.percentage)%")
///         print("남은 체중: \(weightProgress.remaining)kg")
///     }
///
///     if let projection = progress.weightProjection {
///         if let completionDate = projection.estimatedCompletionDate {
///             print("예상 달성일: \(completionDate)")
///         }
///     }
///
///     if !progress.newlyAchievedMilestones.isEmpty {
///         print("축하합니다! 새로운 마일스톤 달성: \(progress.newlyAchievedMilestones)")
///     }
/// } catch GetGoalProgressError.noActiveGoal {
///     print("활성 목표가 없습니다. 먼저 목표를 설정해주세요.")
/// } catch {
///     print("진행 상황 조회 실패: \(error)")
/// }
/// ```
struct GetGoalProgressUseCase {

    // MARK: - Dependencies

    /// 목표 데이터 저장소
    private let goalRepository: GoalRepositoryProtocol

    /// 체성분 데이터 저장소
    private let bodyRepository: BodyRepositoryProtocol

    // MARK: - Initialization

    /// GetGoalProgressUseCase 초기화
    ///
    /// - Parameters:
    ///   - goalRepository: 목표 데이터 저장소
    ///   - bodyRepository: 체성분 데이터 저장소
    init(
        goalRepository: GoalRepositoryProtocol,
        bodyRepository: BodyRepositoryProtocol
    ) {
        self.goalRepository = goalRepository
        self.bodyRepository = bodyRepository
    }

    // MARK: - Execute

    /// 현재 목표의 진행 상황을 조회합니다.
    ///
    /// ## 실행 순서
    /// 1. 활성 목표 조회
    /// 2. 최신 체성분 기록 조회 (현재 상태)
    /// 3. 최근 14일간 체성분 기록 조회 (트렌드 분석용)
    /// 4. 각 목표별 진행률 계산
    /// 5. 각 목표별 트렌드 분석 및 예상 달성일 계산
    /// 6. 새로 달성한 마일스톤 감지 (선택사항)
    /// 7. 통합 결과 반환
    ///
    /// - Parameter previousProgress: 이전 진행률 (새 마일스톤 감지용, 선택사항)
    ///
    /// - Throws:
    ///   - GetGoalProgressError.noActiveGoal: 활성 목표가 없을 때
    ///   - GetGoalProgressError.noBodyCompositionData: 체성분 기록이 없을 때
    ///   - GetGoalProgressError.fetchFailed: 데이터 조회 실패
    ///
    /// - Returns: 목표 진행 상황 정보
    ///
    /// - Example:
    /// ```swift
    /// // 기본 진행 상황 조회
    /// let progress = try await useCase.execute()
    /// print("전체 진행률: \(progress.overallProgress)%")
    ///
    /// // 이전 진행률과 비교하여 새 마일스톤 감지
    /// let previousProgress = Decimal(40.0)
    /// let progress = try await useCase.execute(previousProgress: previousProgress)
    /// if !progress.newlyAchievedMilestones.isEmpty {
    ///     print("새로운 마일스톤: \(progress.newlyAchievedMilestones)")
    /// }
    /// ```
    func execute(previousProgress: Decimal? = nil) async throws -> GoalProgressData {

        // Step 1: 활성 목표 조회
        guard let goal = try await goalRepository.fetchActiveGoal() else {
            throw GetGoalProgressError.noActiveGoal
        }

        // Step 2: 최신 체성분 기록 조회
        guard let latestBody = try await bodyRepository.fetchLatest() else {
            throw GetGoalProgressError.noBodyCompositionData
        }

        // Step 3: 최근 14일간 체성분 기록 조회 (트렌드 분석용)
        let recentRecords: [BodyCompositionEntry]
        do {
            recentRecords = try await bodyRepository.fetchRecent(days: 14)
        } catch {
            throw GetGoalProgressError.fetchFailed(error)
        }

        // Step 4: 각 목표별 진행률 계산
        let progressResult = GoalProgressService.calculateGoalProgress(
            goal: goal,
            currentWeight: latestBody.weight,
            currentBodyFatPct: latestBody.bodyFatPercent,
            currentMuscleMass: latestBody.muscleMass
        )

        // Step 5: 각 목표별 트렌드 분석 및 예상 달성일 계산
        var weightTrend: TrendResult?
        var weightProjection: ProjectionResult?
        if goal.targetWeight != nil {
            weightTrend = TrendProjectionService.calculateTrend(
                records: recentRecords,
                for: .weight
            )
            if let trend = weightTrend {
                weightProjection = TrendProjectionService.projectCompletionDate(
                    goal: goal,
                    currentValue: latestBody.weight,
                    trend: trend,
                    metric: .weight
                )
            }
        }

        var bodyFatTrend: TrendResult?
        var bodyFatProjection: ProjectionResult?
        if goal.targetBodyFatPct != nil {
            bodyFatTrend = TrendProjectionService.calculateTrend(
                records: recentRecords,
                for: .bodyFat
            )
            if let trend = bodyFatTrend {
                bodyFatProjection = TrendProjectionService.projectCompletionDate(
                    goal: goal,
                    currentValue: latestBody.bodyFatPercent,
                    trend: trend,
                    metric: .bodyFat
                )
            }
        }

        var muscleTrend: TrendResult?
        var muscleProjection: ProjectionResult?
        if goal.targetMuscleMass != nil {
            muscleTrend = TrendProjectionService.calculateTrend(
                records: recentRecords,
                for: .muscle
            )
            if let trend = muscleTrend {
                muscleProjection = TrendProjectionService.projectCompletionDate(
                    goal: goal,
                    currentValue: latestBody.muscleMass,
                    trend: trend,
                    metric: .muscle
                )
            }
        }

        // Step 6: 새로 달성한 마일스톤 감지 (선택사항)
        var newlyAchievedMilestones: [Milestone] = []
        if let previous = previousProgress {
            newlyAchievedMilestones = GoalProgressService.detectNewMilestones(
                currentProgress: progressResult.overallProgress,
                previousProgress: previous
            )
        }

        // Step 7: 통합 결과 반환
        return GoalProgressData(
            goal: goal,
            currentBody: latestBody,
            overallProgress: progressResult.overallProgress,
            weightProgress: progressResult.weightProgress,
            bodyFatProgress: progressResult.bodyFatProgress,
            muscleProgress: progressResult.muscleProgress,
            achievedMilestones: progressResult.achievedMilestones,
            newlyAchievedMilestones: newlyAchievedMilestones,
            weightTrend: weightTrend,
            bodyFatTrend: bodyFatTrend,
            muscleTrend: muscleTrend,
            weightProjection: weightProjection,
            bodyFatProjection: bodyFatProjection,
            muscleProjection: muscleProjection,
            dataPointsCount: recentRecords.count
        )
    }
}

// MARK: - Error Types

/// 목표 진행 상황 조회 중 발생할 수 있는 에러
enum GetGoalProgressError: Error, LocalizedError {

    /// 활성 목표가 없음
    ///
    /// 진행 상황을 조회하려면 먼저 목표를 설정해야 합니다.
    case noActiveGoal

    /// 체성분 기록이 없음
    ///
    /// 진행 상황을 계산하려면 최소 1개 이상의 체성분 기록이 필요합니다.
    case noBodyCompositionData

    /// 데이터 조회 실패
    ///
    /// Repository에서 데이터를 가져오는 중 에러 발생
    ///
    /// - Parameter error: 저장소 에러
    case fetchFailed(Error)

    /// 사용자에게 표시할 에러 설명
    var errorDescription: String? {
        switch self {
        case .noActiveGoal:
            return "활성 목표가 없습니다. 먼저 목표를 설정해주세요."

        case .noBodyCompositionData:
            return "체성분 기록이 없습니다. 먼저 체성분을 입력해주세요."

        case .fetchFailed(let error):
            return "데이터 조회 실패: \(error.localizedDescription)"
        }
    }
}

// MARK: - Result Types

/// 목표 진행 상황 데이터
///
/// 목표의 전체 진행 상황, 각 지표별 진행률, 트렌드, 예상 달성일을 포함합니다.
public struct GoalProgressData {
    // MARK: - Basic Info

    /// 현재 활성 목표
    public let goal: Goal

    /// 현재 체성분 상태
    public let currentBody: BodyCompositionEntry

    // MARK: - Progress

    /// 전체 진행률 (%)
    ///
    /// 설정된 모든 목표의 평균 진행률
    public let overallProgress: Decimal

    /// 체중 진행률
    ///
    /// 목표 체중이 설정된 경우에만 값이 있음
    public let weightProgress: ProgressResult?

    /// 체지방률 진행률
    ///
    /// 목표 체지방률이 설정된 경우에만 값이 있음
    public let bodyFatProgress: ProgressResult?

    /// 근육량 진행률
    ///
    /// 목표 근육량이 설정된 경우에만 값이 있음
    public let muscleProgress: ProgressResult?

    // MARK: - Milestones

    /// 달성한 마일스톤 목록
    ///
    /// 25%, 50%, 75%, 100% 중 달성한 마일스톤
    public let achievedMilestones: [Milestone]

    /// 새로 달성한 마일스톤 목록
    ///
    /// 이전 진행률 대비 새로 달성한 마일스톤
    /// previousProgress를 제공하지 않으면 빈 배열
    public let newlyAchievedMilestones: [Milestone]

    // MARK: - Trends

    /// 체중 트렌드
    ///
    /// 최근 14일간 체중 변화 추세
    /// 데이터가 충분하지 않으면 nil
    public let weightTrend: TrendResult?

    /// 체지방률 트렌드
    ///
    /// 최근 14일간 체지방률 변화 추세
    /// 데이터가 충분하지 않으면 nil
    public let bodyFatTrend: TrendResult?

    /// 근육량 트렌드
    ///
    /// 최근 14일간 근육량 변화 추세
    /// 데이터가 충분하지 않으면 nil
    public let muscleTrend: TrendResult?

    // MARK: - Projections

    /// 체중 목표 예상 달성일
    ///
    /// 현재 트렌드가 유지될 경우 체중 목표 달성 예상일
    /// 트렌드가 목표 방향과 반대이거나 데이터가 부족하면 nil
    public let weightProjection: ProjectionResult?

    /// 체지방률 목표 예상 달성일
    ///
    /// 현재 트렌드가 유지될 경우 체지방률 목표 달성 예상일
    /// 트렌드가 목표 방향과 반대이거나 데이터가 부족하면 nil
    public let bodyFatProjection: ProjectionResult?

    /// 근육량 목표 예상 달성일
    ///
    /// 현재 트렌드가 유지될 경우 근육량 목표 달성 예상일
    /// 트렌드가 목표 방향과 반대이거나 데이터가 부족하면 nil
    public let muscleProjection: ProjectionResult?

    // MARK: - Metadata

    /// 트렌드 분석에 사용된 데이터 포인트 수
    ///
    /// 최근 14일간의 체성분 기록 개수
    /// 많을수록 트렌드 신뢰도가 높음
    public let dataPointsCount: Int
}

// MARK: - Convenience Extensions

extension GetGoalProgressUseCase {

    /// 간단한 진행률 조회 편의 메서드
    ///
    /// 새 마일스톤 감지 없이 현재 진행 상황만 조회합니다.
    ///
    /// - Returns: 목표 진행 상황 정보
    ///
    /// - Example:
    /// ```swift
    /// let progress = try await useCase.getSimpleProgress()
    /// print("전체 진행률: \(progress.overallProgress)%")
    /// ```
    func getSimpleProgress() async throws -> GoalProgressData {
        return try await execute(previousProgress: nil)
    }

    /// 새 마일스톤 감지를 포함한 진행률 조회 편의 메서드
    ///
    /// 이전 진행률과 비교하여 새로 달성한 마일스톤을 감지합니다.
    ///
    /// - Parameter previousProgress: 이전 진행률 (%)
    ///
    /// - Returns: 목표 진행 상황 정보 (새 마일스톤 포함)
    ///
    /// - Example:
    /// ```swift
    /// let previousProgress = Decimal(40.0)
    /// let progress = try await useCase.getProgressWithMilestones(
    ///     previousProgress: previousProgress
    /// )
    /// if !progress.newlyAchievedMilestones.isEmpty {
    ///     print("축하합니다! 새로운 마일스톤을 달성했습니다!")
    /// }
    /// ```
    func getProgressWithMilestones(
        previousProgress: Decimal
    ) async throws -> GoalProgressData {
        return try await execute(previousProgress: previousProgress)
    }
}

// MARK: - Helper Extensions

extension GoalProgressData {

    /// 전체적으로 목표가 계획대로 진행 중인지 확인
    ///
    /// 설정된 모든 목표가 계획대로 또는 더 빠르게 진행 중이면 true
    ///
    /// - Note: 하나라도 트렌드가 없거나 계획보다 느리면 false
    public var isOnTrack: Bool {
        var onTrackCount = 0
        var totalCount = 0

        if let projection = weightProjection {
            totalCount += 1
            if projection.isOnTrack {
                onTrackCount += 1
            }
        }

        if let projection = bodyFatProjection {
            totalCount += 1
            if projection.isOnTrack {
                onTrackCount += 1
            }
        }

        if let projection = muscleProjection {
            totalCount += 1
            if projection.isOnTrack {
                onTrackCount += 1
            }
        }

        // 설정된 목표가 없으면 false
        guard totalCount > 0 else { return false }

        // 모든 목표가 계획대로 진행 중이면 true
        return onTrackCount == totalCount
    }

    /// 가장 빠른 예상 달성일
    ///
    /// 여러 목표 중 가장 빨리 달성될 것으로 예상되는 날짜
    ///
    /// - Note: 모든 목표의 예상 달성일이 nil이면 nil
    public var earliestCompletionDate: Date? {
        let dates = [
            weightProjection?.estimatedCompletionDate,
            bodyFatProjection?.estimatedCompletionDate,
            muscleProjection?.estimatedCompletionDate
        ].compactMap { $0 }

        return dates.min()
    }

    /// 가장 늦은 예상 달성일
    ///
    /// 여러 목표 중 가장 늦게 달성될 것으로 예상되는 날짜
    ///
    /// - Note: 모든 목표의 예상 달성일이 nil이면 nil
    public var latestCompletionDate: Date? {
        let dates = [
            weightProjection?.estimatedCompletionDate,
            bodyFatProjection?.estimatedCompletionDate,
            muscleProjection?.estimatedCompletionDate
        ].compactMap { $0 }

        return dates.max()
    }

    /// 트렌드 데이터가 충분한지 확인
    ///
    /// 최소 5개 이상의 데이터 포인트가 있으면 true (Medium 신뢰도 이상)
    public var hasSufficientTrendData: Bool {
        return dataPointsCount >= 5
    }
}

// MARK: - Documentation

/// ## UseCase Pattern 설명
///
/// GetGoalProgressUseCase는 목표 진행 상황 조회라는 복잡한 비즈니스 플로우를 캡슐화합니다.
///
/// ### 책임
///
/// 1. **데이터 수집**
///    - 활성 목표 조회
///    - 현재 체성분 상태 조회
///    - 트렌드 분석을 위한 최근 14일 데이터 조회
///
/// 2. **진행률 계산**
///    - GoalProgressService를 통한 각 목표별 진행률 계산
///    - 전체 진행률 계산 (평균)
///    - 마일스톤 달성 여부 확인
///
/// 3. **트렌드 분석**
///    - TrendProjectionService를 통한 14일 트렌드 계산
///    - 각 목표별 예상 달성일 계산
///    - 계획 대비 진행 상태 확인
///
/// 4. **마일스톤 감지**
///    - 이전 진행률과 비교하여 새로 달성한 마일스톤 감지
///    - 축하 메시지 표시를 위한 정보 제공
///
/// ### 에러 처리
///
/// - 활성 목표가 없으면 noActiveGoal 에러
/// - 체성분 기록이 없으면 noBodyCompositionData 에러
/// - Repository 에러는 fetchFailed로 래핑
///
/// ### Clean Architecture에서의 위치
///
/// ```
/// [Presentation]     ViewModel → GetGoalProgressUseCase 호출
///       ↓
/// [Domain]          GetGoalProgressUseCase → Repository/Service 조율
///       ↓
/// [Data]            Repository → DataSource 호출
/// ```
///
/// ### 사용 시나리오
///
/// 1. **대시보드에서 목표 진행 상황 표시**
///    ```swift
///    let progress = try await useCase.getSimpleProgress()
///    dashboardView.updateProgress(progress.overallProgress)
///    ```
///
/// 2. **새 마일스톤 달성 시 축하 애니메이션**
///    ```swift
///    let progress = try await useCase.getProgressWithMilestones(
///        previousProgress: lastKnownProgress
///    )
///    if !progress.newlyAchievedMilestones.isEmpty {
///        celebrationView.show(milestones: progress.newlyAchievedMilestones)
///    }
///    ```
///
/// 3. **목표 진행 차트 데이터 제공**
///    ```swift
///    let progress = try await useCase.getSimpleProgress()
///    chartView.plotProgress(
///        current: progress.currentBody.weight,
///        target: progress.goal.targetWeight,
///        trend: progress.weightTrend
///    )
///    ```
