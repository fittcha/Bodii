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
/// - 목표 달성일로부터 주간 변화율 역산
/// - 새 목표 저장
///
/// ## 의존성
/// - GoalValidationService: 목표 검증
/// - BodyRepositoryProtocol: 현재 체성분 조회
/// - GoalRepositoryProtocol: 목표 저장 및 관리
///
/// ## 비즈니스 플로우
/// 1. 최신 체성분 기록을 조회하여 시작값으로 설정
/// 2. targetDate로부터 주간 변화율을 역산
/// 3. 기존 활성 목표를 비활성화 (isActive = false)
/// 4. 새로운 목표를 isActive = true로 저장
/// 5. GoalValidationService를 통해 목표 유효성 검증
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
    /// 2. targetDate로부터 주간 변화율 역산
    /// 3. 기존 활성 목표 비활성화
    /// 4. 새 목표 저장 (isActive = true)
    /// 5. GoalValidationService를 통한 검증
    ///
    /// - Parameters:
    ///   - userId: 사용자 ID
    ///   - goalType: 목표 유형 (감량/유지/증량)
    ///   - targetWeight: 목표 체중 (kg, 선택사항)
    ///   - targetBodyFatPct: 목표 체지방률 (%, 선택사항)
    ///   - targetMuscleMass: 목표 근육량 (kg, 선택사항)
    ///   - targetDate: 목표 달성일 (유지 목표 시 nil)
    ///   - dailyCalorieTarget: 일일 칼로리 목표 (kcal, 선택사항)
    ///
    /// - Throws:
    ///   - SetGoalError.noBodyCompositionData: 체성분 기록이 없을 때
    ///   - SetGoalError.saveFailed: 저장 실패
    ///
    /// - Returns: 저장된 목표
    func execute(
        userId: UUID,
        goalType: GoalType,
        targetWeight: Decimal? = nil,
        targetBodyFatPct: Decimal? = nil,
        targetMuscleMass: Decimal? = nil,
        targetDate: Date? = nil,
        dailyCalorieTarget: Int32? = nil,
        goalPeriodStart: Date? = nil,
        goalPeriodEnd: Date? = nil,
        isGoalModeActive: Bool = false
    ) async throws -> Goal {

        // Step 1: 최신 체성분 기록 조회하여 시작값 스냅샷 생성
        guard let latestBody = try await bodyRepository.fetchLatest() else {
            throw SetGoalError.noBodyCompositionData
        }

        // Step 2: 대사율 데이터 조회 (시작 BMR/TDEE 저장용)
        let metabolismData = try await bodyRepository.fetchMetabolismData(for: latestBody.id)

        // Step 3: targetDate로부터 주간 변화율 역산
        let currentWeight: Decimal = latestBody.weight
        let currentBodyFatPct: Decimal = latestBody.bodyFatPercent
        let currentMuscleMass: Decimal = latestBody.muscleMass

        let weeklyWeightRate: Decimal?
        let weeklyFatPctRate: Decimal?
        let weeklyMuscleRate: Decimal?

        if goalType == .maintain {
            // 유지 목표: 변화율 0
            weeklyWeightRate = targetWeight != nil ? Decimal(0) : nil
            weeklyFatPctRate = targetBodyFatPct != nil ? Decimal(0) : nil
            weeklyMuscleRate = targetMuscleMass != nil ? Decimal(0) : nil
        } else {
            // 감량/증량 목표: targetDate로부터 역산
            weeklyWeightRate = calculateWeeklyRate(
                current: currentWeight,
                target: targetWeight,
                targetDate: targetDate
            )
            weeklyFatPctRate = calculateWeeklyRate(
                current: currentBodyFatPct,
                target: targetBodyFatPct,
                targetDate: targetDate
            )
            weeklyMuscleRate = calculateWeeklyRate(
                current: currentMuscleMass,
                target: targetMuscleMass,
                targetDate: targetDate
            )
        }

        // Step 4: 기존 활성 목표 비활성화
        do {
            try await goalRepository.deactivateAllGoals(for: userId)
        } catch {
            throw SetGoalError.deactivationFailed(error)
        }

        // Step 5: 새 목표 생성 (Repository의 create 메서드 사용)
        let savedGoal: Goal
        do {
            savedGoal = try await goalRepository.create(
                userId: userId,
                goalType: goalType,
                targetWeight: targetWeight,
                targetBodyFatPct: targetBodyFatPct,
                targetMuscleMass: targetMuscleMass,
                weeklyWeightRate: weeklyWeightRate,
                weeklyFatPctRate: weeklyFatPctRate,
                weeklyMuscleRate: weeklyMuscleRate,
                dailyCalorieTarget: dailyCalorieTarget,
                targetDate: targetDate,
                startWeight: currentWeight,
                startBodyFatPct: currentBodyFatPct,
                startMuscleMass: currentMuscleMass,
                startBMR: metabolismData?.bmr,
                startTDEE: metabolismData?.tdee,
                goalPeriodStart: goalPeriodStart,
                goalPeriodEnd: goalPeriodEnd,
                isGoalModeActive: isGoalModeActive
            )
        } catch {
            throw SetGoalError.saveFailed(error)
        }

        // Step 6: 목표 검증 (생성 후 검증 - 경고만, 저장 차단 안 함)
        do {
            try GoalValidationService.validate(goal: savedGoal)
        } catch {
            print("Goal validation warning: \(error)")
        }

        return savedGoal
    }

    // MARK: - Private Helpers

    /// 목표 달성일로부터 주간 변화율을 역산합니다.
    ///
    /// weeklyRate = (target - current) / (daysBetween / 7.0)
    ///
    /// - Parameters:
    ///   - current: 현재값
    ///   - target: 목표값
    ///   - targetDate: 목표 달성일
    /// - Returns: 주간 변화율 (계산 불가 시 nil)
    private func calculateWeeklyRate(
        current: Decimal?,
        target: Decimal?,
        targetDate: Date?
    ) -> Decimal? {
        guard let current = current,
              let target = target,
              let targetDate = targetDate else {
            return nil
        }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let daysBetween = calendar.dateComponents([.day], from: today, to: targetDate).day ?? 0

        guard daysBetween > 0 else { return nil }

        let weeks = Decimal(daysBetween) / Decimal(7)
        guard weeks > 0 else { return nil }

        let difference = target - current
        return difference / weeks
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

    /// 편의 메서드 - 체중 유지 목표
    func setWeightMaintenanceGoal(
        userId: UUID,
        targetWeight: Decimal
    ) async throws -> Goal {
        return try await execute(
            userId: userId,
            goalType: .maintain,
            targetWeight: targetWeight
        )
    }
}

