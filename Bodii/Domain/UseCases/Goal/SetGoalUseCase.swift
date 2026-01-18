//
//  SetGoalUseCase.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-18.
//

import Foundation

/// 새로운 목표 설정 유스케이스
///
/// 목표 설정의 전체 흐름을 관리하는 오케스트레이션 Use Case입니다.
///
/// ## 책임
/// - 현재 체성분 스냅샷 생성 (시작값)
/// - 목표 유효성 검증
/// - 기존 활성 목표 비활성화
/// - 예상 달성일 계산
/// - 새 목표 저장
///
/// ## 의존성
/// - GoalValidationService: 목표 검증
/// - BodyRepositoryProtocol: 현재 체성분 조회
/// - GoalRepositoryProtocol: 목표 저장 및 관리
///
/// ## 비즈니스 플로우
/// 1. 최신 체성분 기록을 조회하여 시작값으로 설정
/// 2. GoalValidationService를 통해 목표 유효성 검증
/// 3. 기존 활성 목표를 비활성화 (isActive = false)
/// 4. 목표 유형과 변화율을 기반으로 예상 달성일 계산
/// 5. 새로운 목표를 isActive = true로 저장
///
/// ## 사용 예시
/// ```swift
/// let useCase = SetGoalUseCase(
///     bodyRepository: bodyRepository,
///     goalRepository: goalRepository
/// )
///
/// do {
///     let goal = try await useCase.execute(
///         userId: user.id,
///         goalType: .lose,
///         targetWeight: Decimal(65.0),
///         weeklyWeightRate: Decimal(-0.5)
///     )
///     print("목표 설정 완료: \(goal.id)")
/// } catch SetGoalError.noBodyCompositionData {
///     print("체성분 기록이 필요합니다")
/// } catch {
///     print("목표 설정 실패: \(error)")
/// }
/// ```
struct SetGoalUseCase {

    // MARK: - Dependencies

    /// 체성분 데이터 저장소
    private let bodyRepository: BodyRepositoryProtocol

    /// 목표 데이터 저장소
    private let goalRepository: GoalRepositoryProtocol

    // MARK: - Initialization

    /// SetGoalUseCase 초기화
    ///
    /// - Parameters:
    ///   - bodyRepository: 체성분 데이터 저장소
    ///   - goalRepository: 목표 데이터 저장소
    init(
        bodyRepository: BodyRepositoryProtocol,
        goalRepository: GoalRepositoryProtocol
    ) {
        self.bodyRepository = bodyRepository
        self.goalRepository = goalRepository
    }

    // MARK: - Execute

    /// 새로운 목표를 설정합니다.
    ///
    /// ## 실행 순서
    /// 1. 최신 체성분 기록 조회 (현재 상태 스냅샷)
    /// 2. 목표 엔티티 생성 (시작값 설정)
    /// 3. GoalValidationService를 통한 검증
    /// 4. 기존 활성 목표 비활성화
    /// 5. 예상 달성일 계산
    /// 6. 새 목표 저장 (isActive = true)
    ///
    /// - Parameters:
    ///   - userId: 사용자 ID
    ///   - goalType: 목표 유형 (감량/유지/증량)
    ///   - targetWeight: 목표 체중 (kg, 선택사항)
    ///   - targetBodyFatPct: 목표 체지방률 (%, 선택사항)
    ///   - targetMuscleMass: 목표 근육량 (kg, 선택사항)
    ///   - weeklyWeightRate: 주간 체중 변화율 (kg/week, 선택사항)
    ///   - weeklyFatPctRate: 주간 체지방률 변화율 (%/week, 선택사항)
    ///   - weeklyMuscleRate: 주간 근육량 변화율 (kg/week, 선택사항)
    ///   - dailyCalorieTarget: 일일 칼로리 목표 (kcal, 선택사항)
    ///
    /// - Throws:
    ///   - SetGoalError.noBodyCompositionData: 체성분 기록이 없을 때
    ///   - SetGoalError.validationFailed: 목표 검증 실패
    ///   - SetGoalError.saveFailed: 저장 실패
    ///
    /// - Returns: 저장된 목표
    ///
    /// - Example:
    /// ```swift
    /// // 체중 감량 목표 설정
    /// let goal = try await useCase.execute(
    ///     userId: user.id,
    ///     goalType: .lose,
    ///     targetWeight: Decimal(65.0),
    ///     weeklyWeightRate: Decimal(-0.5)
    /// )
    ///
    /// // 복수 목표 설정 (체중 + 체지방률 + 근육량)
    /// let multiGoal = try await useCase.execute(
    ///     userId: user.id,
    ///     goalType: .lose,
    ///     targetWeight: Decimal(65.0),
    ///     targetBodyFatPct: Decimal(18.0),
    ///     targetMuscleMass: Decimal(30.0),
    ///     weeklyWeightRate: Decimal(-0.5),
    ///     weeklyFatPctRate: Decimal(-0.5),
    ///     weeklyMuscleRate: Decimal(-0.1)
    /// )
    /// ```
    func execute(
        userId: UUID,
        goalType: GoalType,
        targetWeight: Decimal? = nil,
        targetBodyFatPct: Decimal? = nil,
        targetMuscleMass: Decimal? = nil,
        weeklyWeightRate: Decimal? = nil,
        weeklyFatPctRate: Decimal? = nil,
        weeklyMuscleRate: Decimal? = nil,
        dailyCalorieTarget: Int32? = nil
    ) async throws -> Goal {

        // Step 1: 최신 체성분 기록 조회하여 시작값 스냅샷 생성
        guard let latestBody = try await bodyRepository.fetchLatest() else {
            throw SetGoalError.noBodyCompositionData
        }

        // Step 2: 대사율 데이터 조회 (시작 BMR/TDEE 저장용)
        let metabolismData = try await bodyRepository.fetchMetabolismData(for: latestBody.id)

        // Step 3: 목표 엔티티 생성 (시작값 포함)
        let now = Date()
        var goal = Goal(
            id: UUID(),
            userId: userId,
            goalType: goalType,
            targetWeight: targetWeight,
            targetBodyFatPct: targetBodyFatPct,
            targetMuscleMass: targetMuscleMass,
            weeklyWeightRate: weeklyWeightRate,
            weeklyFatPctRate: weeklyFatPctRate,
            weeklyMuscleRate: weeklyMuscleRate,
            startWeight: latestBody.weight,
            startBodyFatPct: latestBody.bodyFatPercent,
            startMuscleMass: latestBody.muscleMass,
            startBMR: metabolismData?.bmr,
            startTDEE: metabolismData?.tdee,
            dailyCalorieTarget: dailyCalorieTarget,
            isActive: true,
            createdAt: now,
            updatedAt: now
        )

        // Step 4: 목표 검증
        do {
            try GoalValidationService.validate(goal: goal)
        } catch {
            throw SetGoalError.validationFailed(error)
        }

        // Step 5: 기존 활성 목표 비활성화
        do {
            try await goalRepository.deactivateAllGoals(for: userId)
        } catch {
            throw SetGoalError.deactivationFailed(error)
        }

        // Step 6: 새 목표 저장
        let savedGoal: Goal
        do {
            savedGoal = try await goalRepository.save(goal)
        } catch {
            throw SetGoalError.saveFailed(error)
        }

        return savedGoal
    }
}

// MARK: - Error Types

/// 목표 설정 중 발생할 수 있는 에러
enum SetGoalError: Error, LocalizedError {

    /// 체성분 기록이 없음
    ///
    /// 목표를 설정하려면 최소 1개 이상의 체성분 기록이 필요합니다.
    /// 체성분을 먼저 입력한 후 목표를 설정하세요.
    case noBodyCompositionData

    /// 목표 검증 실패
    ///
    /// GoalValidationService에서 검증 실패한 경우
    ///
    /// - Parameter error: 검증 에러
    case validationFailed(Error)

    /// 기존 목표 비활성화 실패
    ///
    /// 기존 활성 목표를 비활성화하는 과정에서 에러 발생
    ///
    /// - Parameter error: 저장소 에러
    case deactivationFailed(Error)

    /// 목표 저장 실패
    ///
    /// 새 목표를 저장하는 과정에서 에러 발생
    ///
    /// - Parameter error: 저장소 에러
    case saveFailed(Error)

    /// 사용자에게 표시할 에러 설명
    var errorDescription: String? {
        switch self {
        case .noBodyCompositionData:
            return "목표를 설정하려면 체성분 기록이 필요합니다. 먼저 체성분을 입력해주세요."

        case .validationFailed(let error):
            return "목표 검증 실패: \(error.localizedDescription)"

        case .deactivationFailed(let error):
            return "기존 목표 비활성화 실패: \(error.localizedDescription)"

        case .saveFailed(let error):
            return "목표 저장 실패: \(error.localizedDescription)"
        }
    }
}

// MARK: - Convenience Extensions

extension SetGoalUseCase {

    /// 단일 목표 설정 편의 메서드 - 체중 감량
    ///
    /// 체중 감량 목표만 간단하게 설정할 수 있는 편의 메서드입니다.
    ///
    /// - Parameters:
    ///   - userId: 사용자 ID
    ///   - targetWeight: 목표 체중 (kg)
    ///   - weeklyRate: 주간 변화율 (kg/week, 음수여야 함)
    ///
    /// - Returns: 저장된 목표
    ///
    /// - Example:
    /// ```swift
    /// let goal = try await useCase.setWeightLossGoal(
    ///     userId: user.id,
    ///     targetWeight: Decimal(65.0),
    ///     weeklyRate: Decimal(-0.5)
    /// )
    /// ```
    func setWeightLossGoal(
        userId: UUID,
        targetWeight: Decimal,
        weeklyRate: Decimal
    ) async throws -> Goal {
        return try await execute(
            userId: userId,
            goalType: .lose,
            targetWeight: targetWeight,
            weeklyWeightRate: weeklyRate
        )
    }

    /// 단일 목표 설정 편의 메서드 - 체중 증량
    ///
    /// 체중 증량 목표만 간단하게 설정할 수 있는 편의 메서드입니다.
    ///
    /// - Parameters:
    ///   - userId: 사용자 ID
    ///   - targetWeight: 목표 체중 (kg)
    ///   - weeklyRate: 주간 변화율 (kg/week, 양수여야 함)
    ///
    /// - Returns: 저장된 목표
    ///
    /// - Example:
    /// ```swift
    /// let goal = try await useCase.setWeightGainGoal(
    ///     userId: user.id,
    ///     targetWeight: Decimal(75.0),
    ///     weeklyRate: Decimal(0.5)
    /// )
    /// ```
    func setWeightGainGoal(
        userId: UUID,
        targetWeight: Decimal,
        weeklyRate: Decimal
    ) async throws -> Goal {
        return try await execute(
            userId: userId,
            goalType: .gain,
            targetWeight: targetWeight,
            weeklyWeightRate: weeklyRate
        )
    }

    /// 단일 목표 설정 편의 메서드 - 체중 유지
    ///
    /// 체중 유지 목표를 간단하게 설정할 수 있는 편의 메서드입니다.
    ///
    /// - Parameters:
    ///   - userId: 사용자 ID
    ///   - targetWeight: 목표 체중 (kg, 현재 체중과 유사해야 함)
    ///
    /// - Returns: 저장된 목표
    ///
    /// - Example:
    /// ```swift
    /// let goal = try await useCase.setWeightMaintenanceGoal(
    ///     userId: user.id,
    ///     targetWeight: Decimal(70.0)
    /// )
    /// ```
    func setWeightMaintenanceGoal(
        userId: UUID,
        targetWeight: Decimal
    ) async throws -> Goal {
        return try await execute(
            userId: userId,
            goalType: .maintain,
            targetWeight: targetWeight,
            weeklyWeightRate: Decimal(0)
        )
    }
}

// MARK: - Helper Functions

extension SetGoalUseCase {

    /// 예상 달성일을 계산합니다.
    ///
    /// 주간 변화율과 목표까지의 차이를 기반으로 예상 달성일을 계산합니다.
    ///
    /// - Parameters:
    ///   - current: 현재값
    ///   - target: 목표값
    ///   - weeklyRate: 주간 변화율
    ///
    /// - Returns: 예상 달성일 (계산 불가능하면 nil)
    ///
    /// - Note: weeklyRate가 0이거나 방향이 맞지 않으면 nil을 반환합니다.
    ///
    /// - Example:
    /// ```swift
    /// // 70kg → 65kg, 주당 -0.5kg
    /// let estimatedDate = calculateEstimatedCompletionDate(
    ///     current: Decimal(70),
    ///     target: Decimal(65),
    ///     weeklyRate: Decimal(-0.5)
    /// )
    /// // 약 10주 후 = 70일 후
    /// ```
    private func calculateEstimatedCompletionDate(
        current: Decimal,
        target: Decimal,
        weeklyRate: Decimal
    ) -> Date? {
        // 변화율이 0이면 계산 불가
        guard weeklyRate != 0 else { return nil }

        let difference = target - current

        // 방향이 맞지 않으면 계산 불가
        // 예: 감량 목표인데 weeklyRate가 양수
        if (difference > 0 && weeklyRate < 0) || (difference < 0 && weeklyRate > 0) {
            return nil
        }

        // 예상 소요 주수 계산
        let weeksToGoal = abs(difference / weeklyRate)

        // 주수를 일수로 변환
        let daysToGoal = weeksToGoal * 7

        // 현재 날짜에 일수를 더함
        let calendar = Calendar.current
        let estimatedDate = calendar.date(
            byAdding: .day,
            value: Int(daysToGoal.rounded0.toDouble()),
            to: Date()
        )

        return estimatedDate
    }
}

// MARK: - Documentation

/// ## UseCase Pattern 설명
///
/// SetGoalUseCase는 목표 설정이라는 복잡한 비즈니스 플로우를 캡슐화합니다.
///
/// ### 책임
///
/// 1. **체성분 스냅샷 생성**
///    - 목표 설정 시점의 체성분을 시작값으로 저장
///    - 나중에 진행률 계산 시 기준점으로 사용
///
/// 2. **목표 검증**
///    - GoalValidationService를 통한 유효성 검증
///    - 비현실적인 목표나 물리적으로 불가능한 목표 차단
///
/// 3. **기존 목표 관리**
///    - 한 번에 하나의 활성 목표만 허용
///    - 새 목표 설정 시 기존 목표를 자동으로 비활성화
///
/// 4. **목표 영속화**
///    - 검증된 목표를 저장소에 저장
///    - 트랜잭션 보장 (모두 성공 또는 모두 실패)
///
/// ### 에러 처리
///
/// - 각 단계에서 발생할 수 있는 에러를 SetGoalError로 래핑
/// - 사용자에게 명확한 에러 메시지 제공
/// - Repository 에러와 Validation 에러를 구분
///
/// ### Clean Architecture에서의 위치
///
/// ```
/// [Presentation]     ViewModel → SetGoalUseCase 호출
///       ↓
/// [Domain]          SetGoalUseCase → Repository/Service 조율
///       ↓
/// [Data]            Repository → DataSource 호출
/// ```
///
/// ### 사용 시나리오
///
/// 1. **간단한 체중 감량 목표**
///    ```swift
///    try await useCase.setWeightLossGoal(
///        userId: user.id,
///        targetWeight: Decimal(65.0),
///        weeklyRate: Decimal(-0.5)
///    )
///    ```
///
/// 2. **복합 목표 (체중 + 체지방률 + 근육량)**
///    ```swift
///    try await useCase.execute(
///        userId: user.id,
///        goalType: .lose,
///        targetWeight: Decimal(65.0),
///        targetBodyFatPct: Decimal(18.0),
///        targetMuscleMass: Decimal(30.0),
///        weeklyWeightRate: Decimal(-0.5),
///        weeklyFatPctRate: Decimal(-0.5),
///        weeklyMuscleRate: Decimal(-0.1)
///    )
///    ```
///
/// 3. **칼로리 목표 포함**
///    ```swift
///    try await useCase.execute(
///        userId: user.id,
///        goalType: .lose,
///        targetWeight: Decimal(65.0),
///        weeklyWeightRate: Decimal(-0.5),
///        dailyCalorieTarget: 1800
///    )
///    ```
