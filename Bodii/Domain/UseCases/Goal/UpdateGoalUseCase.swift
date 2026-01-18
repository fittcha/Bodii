//
//  UpdateGoalUseCase.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-18.
//

import Foundation

/// 목표 수정 유스케이스
///
/// 기존 목표를 수정하면서 히스토리를 보존하는 Use Case입니다.
///
/// ## 책임
/// - 목표값 및 주간 변화율 수정 허용
/// - 시작값 및 생성일 보존 (히스토리 유지)
/// - 수정된 목표 재검증
/// - 저장소 업데이트
///
/// ## 의존성
/// - GoalValidationService: 수정된 목표 검증
/// - GoalRepositoryProtocol: 목표 조회 및 업데이트
///
/// ## 비즈니스 플로우
/// 1. 기존 목표 조회 (존재 여부 확인)
/// 2. 목표값 및 변화율 업데이트 (시작값/생성일은 보존)
/// 3. GoalValidationService를 통해 수정된 목표 검증
/// 4. updatedAt 타임스탬프 갱신
/// 5. 저장소에 업데이트된 목표 저장
///
/// ## 사용 예시
/// ```swift
/// let useCase = UpdateGoalUseCase(
///     goalRepository: goalRepository
/// )
///
/// do {
///     let updatedGoal = try await useCase.execute(
///         goalId: existingGoal.id,
///         targetWeight: Decimal(63.0),        // 수정: 65kg → 63kg
///         weeklyWeightRate: Decimal(-0.3)     // 수정: -0.5kg → -0.3kg
///     )
///     print("목표 수정 완료: \(updatedGoal.id)")
/// } catch UpdateGoalError.goalNotFound {
///     print("목표를 찾을 수 없습니다")
/// } catch UpdateGoalError.validationFailed {
///     print("수정된 목표가 유효하지 않습니다")
/// } catch {
///     print("목표 수정 실패: \(error)")
/// }
/// ```
struct UpdateGoalUseCase {

    // MARK: - Dependencies

    /// 목표 데이터 저장소
    private let goalRepository: GoalRepositoryProtocol

    // MARK: - Initialization

    /// UpdateGoalUseCase 초기화
    ///
    /// - Parameter goalRepository: 목표 데이터 저장소
    init(goalRepository: GoalRepositoryProtocol) {
        self.goalRepository = goalRepository
    }

    // MARK: - Execute

    /// 기존 목표를 수정합니다.
    ///
    /// ## 실행 순서
    /// 1. 기존 목표 조회 (goalNotFound 에러 처리)
    /// 2. 수정 가능한 필드만 업데이트 (시작값/생성일 보존)
    /// 3. GoalValidationService를 통한 재검증
    /// 4. updatedAt 타임스탬프 갱신
    /// 5. 저장소에 업데이트
    ///
    /// ## 보존되는 필드
    /// - id: 고유 식별자
    /// - userId: 사용자 ID
    /// - startWeight: 시작 체중
    /// - startBodyFatPct: 시작 체지방률
    /// - startMuscleMass: 시작 근육량
    /// - startBMR: 시작 BMR
    /// - startTDEE: 시작 TDEE
    /// - createdAt: 생성일시
    ///
    /// ## 수정 가능한 필드
    /// - goalType: 목표 유형
    /// - targetWeight: 목표 체중
    /// - targetBodyFatPct: 목표 체지방률
    /// - targetMuscleMass: 목표 근육량
    /// - weeklyWeightRate: 주간 체중 변화율
    /// - weeklyFatPctRate: 주간 체지방률 변화율
    /// - weeklyMuscleRate: 주간 근육량 변화율
    /// - dailyCalorieTarget: 일일 칼로리 목표
    /// - isActive: 활성 상태
    ///
    /// - Parameters:
    ///   - goalId: 수정할 목표의 ID
    ///   - goalType: 목표 유형 (nil이면 기존값 유지)
    ///   - targetWeight: 목표 체중 (nil이면 기존값 유지)
    ///   - targetBodyFatPct: 목표 체지방률 (nil이면 기존값 유지)
    ///   - targetMuscleMass: 목표 근육량 (nil이면 기존값 유지)
    ///   - weeklyWeightRate: 주간 체중 변화율 (nil이면 기존값 유지)
    ///   - weeklyFatPctRate: 주간 체지방률 변화율 (nil이면 기존값 유지)
    ///   - weeklyMuscleRate: 주간 근육량 변화율 (nil이면 기존값 유지)
    ///   - dailyCalorieTarget: 일일 칼로리 목표 (nil이면 기존값 유지)
    ///   - isActive: 활성 상태 (nil이면 기존값 유지)
    ///
    /// - Throws:
    ///   - UpdateGoalError.goalNotFound: 목표를 찾을 수 없음
    ///   - UpdateGoalError.validationFailed: 수정된 목표 검증 실패
    ///   - UpdateGoalError.updateFailed: 저장소 업데이트 실패
    ///
    /// - Returns: 수정된 목표
    ///
    /// - Example:
    /// ```swift
    /// // 목표 체중만 수정
    /// let updated = try await useCase.execute(
    ///     goalId: goal.id,
    ///     targetWeight: Decimal(63.0)
    /// )
    ///
    /// // 목표 유형과 변화율 수정
    /// let updated = try await useCase.execute(
    ///     goalId: goal.id,
    ///     goalType: .maintain,
    ///     weeklyWeightRate: Decimal(0)
    /// )
    ///
    /// // 복수 목표 수정
    /// let updated = try await useCase.execute(
    ///     goalId: goal.id,
    ///     targetWeight: Decimal(65.0),
    ///     targetBodyFatPct: Decimal(17.0),
    ///     targetMuscleMass: Decimal(31.0),
    ///     weeklyWeightRate: Decimal(-0.4),
    ///     weeklyFatPctRate: Decimal(-0.4),
    ///     weeklyMuscleRate: Decimal(0.1)
    /// )
    /// ```
    func execute(
        goalId: UUID,
        goalType: GoalType? = nil,
        targetWeight: Decimal? = nil,
        targetBodyFatPct: Decimal? = nil,
        targetMuscleMass: Decimal? = nil,
        weeklyWeightRate: Decimal? = nil,
        weeklyFatPctRate: Decimal? = nil,
        weeklyMuscleRate: Decimal? = nil,
        dailyCalorieTarget: Int32? = nil,
        isActive: Bool? = nil
    ) async throws -> Goal {

        // Step 1: 기존 목표 조회
        guard let existingGoal = try await goalRepository.fetch(by: goalId) else {
            throw UpdateGoalError.goalNotFound(goalId)
        }

        // Step 2: 수정 가능한 필드만 업데이트 (시작값과 생성일은 보존)
        var updatedGoal = Goal(
            id: existingGoal.id,
            userId: existingGoal.userId,
            goalType: goalType ?? existingGoal.goalType,
            targetWeight: targetWeight ?? existingGoal.targetWeight,
            targetBodyFatPct: targetBodyFatPct ?? existingGoal.targetBodyFatPct,
            targetMuscleMass: targetMuscleMass ?? existingGoal.targetMuscleMass,
            weeklyWeightRate: weeklyWeightRate ?? existingGoal.weeklyWeightRate,
            weeklyFatPctRate: weeklyFatPctRate ?? existingGoal.weeklyFatPctRate,
            weeklyMuscleRate: weeklyMuscleRate ?? existingGoal.weeklyMuscleRate,
            // 시작값 보존 (히스토리 유지)
            startWeight: existingGoal.startWeight,
            startBodyFatPct: existingGoal.startBodyFatPct,
            startMuscleMass: existingGoal.startMuscleMass,
            startBMR: existingGoal.startBMR,
            startTDEE: existingGoal.startTDEE,
            dailyCalorieTarget: dailyCalorieTarget ?? existingGoal.dailyCalorieTarget,
            isActive: isActive ?? existingGoal.isActive,
            // 생성일 보존, 수정일 갱신
            createdAt: existingGoal.createdAt,
            updatedAt: Date()
        )

        // Step 3: 수정된 목표 검증
        do {
            try GoalValidationService.validate(goal: updatedGoal)
        } catch {
            throw UpdateGoalError.validationFailed(error)
        }

        // Step 4: 저장소에 업데이트
        let savedGoal: Goal
        do {
            savedGoal = try await goalRepository.update(updatedGoal)
        } catch {
            throw UpdateGoalError.updateFailed(error)
        }

        return savedGoal
    }
}

// MARK: - Error Types

/// 목표 수정 중 발생할 수 있는 에러
enum UpdateGoalError: Error, LocalizedError {

    /// 목표를 찾을 수 없음
    ///
    /// 제공된 ID에 해당하는 목표가 존재하지 않습니다.
    ///
    /// - Parameter id: 찾을 수 없는 목표 ID
    case goalNotFound(UUID)

    /// 수정된 목표 검증 실패
    ///
    /// GoalValidationService에서 수정된 목표가 유효하지 않다고 판정
    ///
    /// - Parameter error: 검증 에러
    case validationFailed(Error)

    /// 목표 업데이트 실패
    ///
    /// 저장소에 업데이트하는 과정에서 에러 발생
    ///
    /// - Parameter error: 저장소 에러
    case updateFailed(Error)

    /// 사용자에게 표시할 에러 설명
    var errorDescription: String? {
        switch self {
        case .goalNotFound(let id):
            return "목표를 찾을 수 없습니다 (ID: \(id)). 목표가 삭제되었거나 존재하지 않습니다."

        case .validationFailed(let error):
            return "수정된 목표 검증 실패: \(error.localizedDescription)"

        case .updateFailed(let error):
            return "목표 업데이트 실패: \(error.localizedDescription)"
        }
    }
}

// MARK: - Convenience Extensions

extension UpdateGoalUseCase {

    /// 목표값만 수정하는 편의 메서드
    ///
    /// 변화율은 유지하고 목표값만 변경할 때 사용합니다.
    ///
    /// - Parameters:
    ///   - goalId: 수정할 목표 ID
    ///   - targetWeight: 새로운 목표 체중 (선택사항)
    ///   - targetBodyFatPct: 새로운 목표 체지방률 (선택사항)
    ///   - targetMuscleMass: 새로운 목표 근육량 (선택사항)
    ///
    /// - Returns: 수정된 목표
    ///
    /// - Example:
    /// ```swift
    /// // 목표 체중만 65kg → 63kg로 수정
    /// let updated = try await useCase.updateTargets(
    ///     goalId: goal.id,
    ///     targetWeight: Decimal(63.0)
    /// )
    /// ```
    func updateTargets(
        goalId: UUID,
        targetWeight: Decimal? = nil,
        targetBodyFatPct: Decimal? = nil,
        targetMuscleMass: Decimal? = nil
    ) async throws -> Goal {
        return try await execute(
            goalId: goalId,
            targetWeight: targetWeight,
            targetBodyFatPct: targetBodyFatPct,
            targetMuscleMass: targetMuscleMass
        )
    }

    /// 변화율만 수정하는 편의 메서드
    ///
    /// 목표값은 유지하고 변화율만 변경할 때 사용합니다.
    /// 예: 진행이 느려서 변화율을 높이거나, 너무 빨라서 낮출 때
    ///
    /// - Parameters:
    ///   - goalId: 수정할 목표 ID
    ///   - weeklyWeightRate: 새로운 주간 체중 변화율 (선택사항)
    ///   - weeklyFatPctRate: 새로운 주간 체지방률 변화율 (선택사항)
    ///   - weeklyMuscleRate: 새로운 주간 근육량 변화율 (선택사항)
    ///
    /// - Returns: 수정된 목표
    ///
    /// - Example:
    /// ```swift
    /// // 체중 변화율을 주당 -0.5kg → -0.3kg로 완화
    /// let updated = try await useCase.updateRates(
    ///     goalId: goal.id,
    ///     weeklyWeightRate: Decimal(-0.3)
    /// )
    /// ```
    func updateRates(
        goalId: UUID,
        weeklyWeightRate: Decimal? = nil,
        weeklyFatPctRate: Decimal? = nil,
        weeklyMuscleRate: Decimal? = nil
    ) async throws -> Goal {
        return try await execute(
            goalId: goalId,
            weeklyWeightRate: weeklyWeightRate,
            weeklyFatPctRate: weeklyFatPctRate,
            weeklyMuscleRate: weeklyMuscleRate
        )
    }

    /// 목표 유형만 변경하는 편의 메서드
    ///
    /// 감량 → 유지, 증량 → 감량 등 목표 유형을 전환할 때 사용합니다.
    ///
    /// - Parameters:
    ///   - goalId: 수정할 목표 ID
    ///   - goalType: 새로운 목표 유형
    ///
    /// - Returns: 수정된 목표
    ///
    /// - Example:
    /// ```swift
    /// // 목표 체중 달성 후 유지 모드로 전환
    /// let updated = try await useCase.updateGoalType(
    ///     goalId: goal.id,
    ///     goalType: .maintain
    /// )
    /// ```
    func updateGoalType(
        goalId: UUID,
        goalType: GoalType
    ) async throws -> Goal {
        return try await execute(
            goalId: goalId,
            goalType: goalType
        )
    }

    /// 활성 상태만 변경하는 편의 메서드
    ///
    /// 목표를 일시 중지하거나 재활성화할 때 사용합니다.
    ///
    /// - Parameters:
    ///   - goalId: 수정할 목표 ID
    ///   - isActive: 활성 상태
    ///
    /// - Returns: 수정된 목표
    ///
    /// - Example:
    /// ```swift
    /// // 목표 일시 중지
    /// let paused = try await useCase.updateActiveStatus(
    ///     goalId: goal.id,
    ///     isActive: false
    /// )
    ///
    /// // 목표 재활성화
    /// let resumed = try await useCase.updateActiveStatus(
    ///     goalId: goal.id,
    ///     isActive: true
    /// )
    /// ```
    func updateActiveStatus(
        goalId: UUID,
        isActive: Bool
    ) async throws -> Goal {
        return try await execute(
            goalId: goalId,
            isActive: isActive
        )
    }
}

// MARK: - Documentation

/// ## UseCase Pattern 설명
///
/// UpdateGoalUseCase는 기존 목표 수정이라는 비즈니스 플로우를 캡슐화합니다.
///
/// ### 책임
///
/// 1. **목표 조회 및 존재 확인**
///    - 수정하려는 목표가 실제로 존재하는지 확인
///    - 존재하지 않으면 명확한 에러 반환
///
/// 2. **히스토리 보존**
///    - 시작값(startWeight, startBodyFatPct 등)은 절대 변경하지 않음
///    - 생성일(createdAt)도 보존
///    - 진행률 계산의 기준점을 유지하여 정확한 추적 가능
///
/// 3. **수정된 목표 재검증**
///    - GoalValidationService를 통해 수정된 목표도 유효한지 확인
///    - 비현실적인 목표나 물리적으로 불가능한 목표 차단
///
/// 4. **타임스탬프 관리**
///    - updatedAt을 현재 시각으로 자동 갱신
///    - 마지막 수정 시각 추적
///
/// ### 에러 처리
///
/// - 목표를 찾을 수 없으면 goalNotFound 에러
/// - 검증 실패 시 validationFailed 에러
/// - Repository 에러는 updateFailed로 래핑
///
/// ### Clean Architecture에서의 위치
///
/// ```
/// [Presentation]     ViewModel → UpdateGoalUseCase 호출
///       ↓
/// [Domain]          UpdateGoalUseCase → Repository/Service 조율
///       ↓
/// [Data]            Repository → DataSource 호출
/// ```
///
/// ### 사용 시나리오
///
/// 1. **목표 체중 조정**
///    ```swift
///    // 예: 진행이 잘되어 목표를 더 낮춤
///    try await useCase.updateTargets(
///        goalId: goal.id,
///        targetWeight: Decimal(63.0)
///    )
///    ```
///
/// 2. **변화율 완화**
///    ```swift
///    // 예: 너무 힘들어서 변화율을 낮춤
///    try await useCase.updateRates(
///        goalId: goal.id,
///        weeklyWeightRate: Decimal(-0.3)
///    )
///    ```
///
/// 3. **목표 달성 후 유지 모드 전환**
///    ```swift
///    // 예: 목표 체중 달성 후 유지로 전환
///    try await useCase.updateGoalType(
///        goalId: goal.id,
///        goalType: .maintain
///    )
///    ```
///
/// 4. **복합 수정**
///    ```swift
///    // 예: 목표값과 변화율 동시 수정
///    try await useCase.execute(
///        goalId: goal.id,
///        targetWeight: Decimal(64.0),
///        weeklyWeightRate: Decimal(-0.4)
///    )
///    ```
///
/// ### SetGoalUseCase와의 차이
///
/// - **SetGoalUseCase**: 새 목표 생성 (시작값 스냅샷, 기존 목표 비활성화)
/// - **UpdateGoalUseCase**: 기존 목표 수정 (시작값 보존, 히스토리 유지)
///
/// ### 왜 히스토리를 보존해야 하는가?
///
/// 시작값을 보존하지 않으면:
/// - 진행률 계산이 부정확해짐
/// - 사용자의 성취감이 왜곡됨
/// - 트렌드 분석이 무의미해짐
///
/// 예시:
/// ```
/// 시작: 70kg → 목표: 65kg (5kg 감량)
/// 현재: 67kg (3kg 감량, 60% 달성)
///
/// [잘못된 방법] 목표를 63kg로 수정하면서 시작값도 67kg로 변경
/// → 진행률이 0%로 리셋됨 (3kg 감량 성과가 사라짐)
///
/// [올바른 방법] 시작값 70kg 유지, 목표만 63kg로 변경
/// → 진행률 = (70-67)/(70-63) = 43% (기존 성과 유지)
/// ```
///
