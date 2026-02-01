//
//  DailyLogService.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-13.
//

import Foundation

/// DailyLog 관리 서비스
///
/// DailyLog의 생성, 조회 및 운동 데이터 업데이트를 담당합니다.
///
/// ## 책임
/// - DailyLog 조회 또는 생성 (getOrCreate)
/// - 운동 추가 시 DailyLog 업데이트
/// - 운동 수정 시 DailyLog 업데이트
/// - 운동 삭제 시 DailyLog 업데이트
/// - HealthKit 데이터 동기화 (걸음 수)
///
/// ## 의존성
/// - DailyLogRepository: DailyLog 데이터 영속성
/// - HealthKitReadService: HealthKit 데이터 읽기 (optional)
///
/// ## 사용 시나리오
/// 1. **운동 추가**: AddExerciseRecordUseCase에서 운동 기록 생성 후 `addExercise` 호출
/// 2. **운동 수정**: UpdateExerciseRecordUseCase에서 운동 기록 수정 후 `updateExercise` 호출
/// 3. **운동 삭제**: DeleteExerciseRecordUseCase에서 운동 기록 삭제 후 `removeExercise` 호출
/// 4. **HealthKit 동기화**: getOrCreate() 호출 시 자동으로 HealthKit 걸음 수 동기화
///
/// - Example:
/// ```swift
/// let service = DailyLogService(
///     repository: dailyLogRepository,
///     healthKitReadService: healthKitReadService
/// )
///
/// // DailyLog 생성 또는 조회 (User의 현재 BMR/TDEE 사용)
/// // HealthKit 걸음 수가 자동으로 동기화됩니다
/// let dailyLog = try await service.getOrCreate(
///     for: Date(),
///     userId: userId,
///     userBMR: user.currentBMR ?? 1650,
///     userTDEE: user.currentTDEE ?? 2310
/// )
///
/// // 운동 추가 (ExerciseRecord 생성 후 호출)
/// try await service.addExercise(
///     date: exerciseRecord.date,
///     userId: userId,
///     calories: exerciseRecord.caloriesBurned,
///     duration: exerciseRecord.duration,
///     userBMR: user.currentBMR ?? 1650,
///     userTDEE: user.currentTDEE ?? 2310
/// )
/// ```
final class DailyLogService {

    // MARK: - Properties

    /// DailyLog 저장소
    private let repository: DailyLogRepository

    /// HealthKit 읽기 서비스 (optional)
    ///
    /// 📚 학습 포인트: Optional Dependency
    /// - HealthKit이 없거나 권한이 없어도 앱이 동작해야 함
    /// - nil이면 HealthKit 동기화를 건너뜀
    /// 💡 Java 비교: @Autowired(required = false)와 유사
    private let healthKitReadService: HealthKitReadService?

    // MARK: - Initialization

    /// DailyLogService 초기화
    ///
    /// - Parameters:
    ///   - repository: DailyLog 저장소
    ///   - healthKitReadService: HealthKit 읽기 서비스 (optional, 기본값: nil)
    init(
        repository: DailyLogRepository,
        healthKitReadService: HealthKitReadService? = nil
    ) {
        self.repository = repository
        self.healthKitReadService = healthKitReadService
    }

    // MARK: - Public Methods

    /// 특정 날짜의 DailyLog를 조회하거나 없으면 생성합니다.
    ///
    /// DailyLog가 없을 경우, 사용자의 현재 BMR/TDEE 값으로 새로 생성합니다.
    /// HealthKit이 설정되어 있으면, 백그라운드에서 걸음 수를 자동으로 동기화합니다.
    ///
    /// 📚 학습 포인트: Non-blocking HealthKit Sync
    /// - DailyLog 생성/조회는 즉시 반환 (빠른 응답)
    /// - HealthKit 데이터는 백그라운드에서 비동기로 업데이트
    /// - HealthKit 실패해도 DailyLog 작업은 성공
    /// 💡 Java 비교: @Async 메서드와 유사
    ///
    /// - Parameters:
    ///   - date: 조회할 날짜
    ///   - userId: 사용자 ID
    ///   - userBMR: 사용자의 현재 BMR (User.currentBMR)
    ///   - userTDEE: 사용자의 현재 TDEE (User.currentTDEE)
    /// - Throws: 데이터 작업 실패 시 에러
    /// - Returns: 조회되거나 생성된 DailyLog
    ///
    /// - Note: userBMR과 userTDEE는 User.currentBMR, User.currentTDEE에서 가져와야 합니다.
    ///         값이 없는 경우 기본값(BMR: 1650, TDEE: 2310)을 사용하세요.
    /// - Note: HealthKit 걸음 수는 백그라운드에서 동기화되며, 실패해도 메서드는 성공합니다.
    func getOrCreate(
        for date: Date,
        userId: UUID,
        userBMR: Decimal,
        userTDEE: Decimal
    ) async throws -> DailyLog {
        // Decimal → Int32 변환
        let bmr = Int32(truncating: userBMR as NSNumber)
        let tdee = Int32(truncating: userTDEE as NSNumber)

        // DailyLog 조회 또는 생성
        let dailyLog = try await repository.getOrCreate(
            for: date,
            userId: userId,
            bmr: bmr,
            tdee: tdee
        )

        // 📚 학습 포인트: Detached Task for Background Work
        // Task.detached로 백그라운드에서 HealthKit 동기화 실행
        // 메인 스레드를 블로킹하지 않고 즉시 반환
        // 💡 Java 비교: CompletableFuture.runAsync()와 유사
        Task.detached { [weak self] in
            await self?.syncHealthKitData(for: date, userId: userId)
        }

        return dailyLog
    }

    /// 운동 추가 시 DailyLog를 업데이트합니다.
    ///
    /// totalCaloriesOut, exerciseMinutes, exerciseCount를 증가시킵니다.
    /// DailyLog가 없으면 자동으로 생성한 후 업데이트합니다.
    ///
    /// - Parameters:
    ///   - date: 운동 날짜
    ///   - userId: 사용자 ID
    ///   - calories: 소모 칼로리 (kcal)
    ///   - duration: 운동 시간 (분)
    ///   - userBMR: 사용자의 현재 BMR (User.currentBMR)
    ///   - userTDEE: 사용자의 현재 TDEE (User.currentTDEE)
    /// - Throws: 업데이트 실패 시 에러
    ///
    /// - Note: UseCase에서 ExerciseRecord 생성 후 이 메서드를 호출해야 합니다.
    ///
    /// - Example:
    /// ```swift
    /// // ExerciseRecord 생성 후
    /// try await dailyLogService.addExercise(
    ///     date: exerciseRecord.date,
    ///     userId: userId,
    ///     calories: exerciseRecord.caloriesBurned,
    ///     duration: exerciseRecord.duration,
    ///     userBMR: user.currentBMR ?? 1650,
    ///     userTDEE: user.currentTDEE ?? 2310
    /// )
    /// ```
    func addExercise(
        date: Date,
        userId: UUID,
        calories: Int32,
        duration: Int32,
        userBMR: Decimal,
        userTDEE: Decimal
    ) async throws {
        // DailyLog가 없으면 생성
        _ = try await getOrCreate(
            for: date,
            userId: userId,
            userBMR: userBMR,
            userTDEE: userTDEE
        )

        // 운동 데이터 추가
        try await repository.addExercise(
            date: date,
            userId: userId,
            calories: calories,
            duration: duration
        )
    }

    /// 운동 삭제 시 DailyLog를 업데이트합니다.
    ///
    /// totalCaloriesOut, exerciseMinutes, exerciseCount를 감소시킵니다.
    ///
    /// - Parameters:
    ///   - date: 운동 날짜
    ///   - userId: 사용자 ID
    ///   - calories: 소모 칼로리 (kcal)
    ///   - duration: 운동 시간 (분)
    /// - Throws: 업데이트 실패 시 에러
    ///
    /// - Note: UseCase에서 ExerciseRecord 삭제 전 이 메서드를 호출해야 합니다.
    ///
    /// - Example:
    /// ```swift
    /// // ExerciseRecord 삭제 전
    /// try await dailyLogService.removeExercise(
    ///     date: exerciseRecord.date,
    ///     userId: userId,
    ///     calories: exerciseRecord.caloriesBurned,
    ///     duration: exerciseRecord.duration
    /// )
    /// // ExerciseRecord 삭제
    /// try await exerciseRepository.delete(id: recordId, userId: userId)
    /// ```
    func removeExercise(
        date: Date,
        userId: UUID,
        calories: Int32,
        duration: Int32
    ) async throws {
        try await repository.removeExercise(
            date: date,
            userId: userId,
            calories: calories,
            duration: duration
        )
    }

    /// 운동 수정 시 DailyLog를 업데이트합니다.
    ///
    /// 이전 값과 새 값의 차이만큼 조정합니다.
    /// exerciseCount는 변경되지 않습니다 (개수는 그대로).
    ///
    /// - Parameters:
    ///   - date: 운동 날짜
    ///   - userId: 사용자 ID
    ///   - oldCalories: 이전 소모 칼로리 (kcal)
    ///   - newCalories: 새로운 소모 칼로리 (kcal)
    ///   - oldDuration: 이전 운동 시간 (분)
    ///   - newDuration: 새로운 운동 시간 (분)
    /// - Throws: 업데이트 실패 시 에러
    ///
    /// - Note: UseCase에서 ExerciseRecord 수정 후 이 메서드를 호출해야 합니다.
    ///
    /// - Example:
    /// ```swift
    /// // ExerciseRecord 수정 후
    /// try await dailyLogService.updateExercise(
    ///     date: exerciseRecord.date,
    ///     userId: userId,
    ///     oldCalories: oldRecord.caloriesBurned,
    ///     newCalories: newRecord.caloriesBurned,
    ///     oldDuration: oldRecord.duration,
    ///     newDuration: newRecord.duration
    /// )
    /// ```
    func updateExercise(
        date: Date,
        userId: UUID,
        oldCalories: Int32,
        newCalories: Int32,
        oldDuration: Int32,
        newDuration: Int32
    ) async throws {
        try await repository.updateExercise(
            date: date,
            userId: userId,
            oldCalories: oldCalories,
            newCalories: newCalories,
            oldDuration: oldDuration,
            newDuration: newDuration
        )
    }

    // MARK: - Private Methods - HealthKit Sync

    /// HealthKit 데이터 동기화
    ///
    /// 📚 학습 포인트: Background HealthKit Sync
    /// - 백그라운드에서 실행되어 메인 스레드를 블로킹하지 않음
    /// - 에러가 발생해도 조용히 실패 (silent failure)
    /// - 로그만 남기고 앱 실행에는 영향 없음
    /// 💡 Java 비교: @Async void 메서드와 유사
    ///
    /// - Parameters:
    ///   - date: 동기화할 날짜
    ///   - userId: 사용자 ID
    ///
    /// - Note: 이 메서드는 절대 throw하지 않으며, 에러 발생 시 조용히 실패합니다.
    ///
    /// - Example:
    /// ```swift
    /// // Task.detached로 백그라운드 실행
    /// Task.detached {
    ///     await service.syncHealthKitData(for: Date(), userId: userId)
    /// }
    /// ```
    private func syncHealthKitData(for date: Date, userId: UUID) async {
        // 📚 학습 포인트: Early Return Guard
        // HealthKit 서비스가 없으면 조기 반환
        // 💡 Java 비교: if (service == null) return; 패턴
        guard let healthKitService = healthKitReadService else {
            return
        }

        do {
            let steps = try await healthKitService.fetchSteps(for: date)
            let activeCalories = try await healthKitService.fetchActiveCalories(for: date)

            // steps 또는 activeCalories가 있으면 DailyLog 업데이트
            if steps != nil || activeCalories != nil {
                if var dailyLog = try await repository.fetch(for: date, userId: userId) {
                    var needsSave = false

                    if let stepsValue = steps {
                        dailyLog.steps = Int32(truncating: stepsValue as NSNumber)
                        needsSave = true
                    }

                    if let activeCaloriesValue = activeCalories {
                        dailyLog.activeCaloriesOut = Int32(truncating: activeCaloriesValue as NSNumber)
                        needsSave = true
                    }

                    if needsSave {
                        dailyLog.updatedAt = Date()
                        _ = try await repository.update(dailyLog)
                    }
                }
            }
        } catch {
            #if DEBUG
            print("[DailyLogService] HealthKit sync failed: \(error.localizedDescription)")
            #endif
        }
    }
}

// MARK: - Service Pattern 설명

/// ## Service Pattern이란?
///
/// Service는 도메인 로직을 캡슐화하고 여러 Repository를 조정하는 역할을 합니다.
///
/// ### Repository vs Service
///
/// **Repository**:
/// - 단일 엔티티의 CRUD 작업
/// - 데이터 영속성에 집중
/// - 예: ExerciseRecordRepository, DailyLogRepository
///
/// **Service**:
/// - 여러 엔티티 간 조정
/// - 도메인 로직 캡슐화
/// - 트랜잭션 경계 관리
/// - 예: DailyLogService (DailyLog 생성 및 운동 데이터 동기화)
///
/// ### 사용 예시
///
/// ```swift
/// // UseCase에서 Service 사용
/// final class AddExerciseRecordUseCase {
///     let exerciseRepository: ExerciseRecordRepository
///     let dailyLogService: DailyLogService
///     let exerciseCalcService: ExerciseCalcService
///
///     func execute(...) async throws {
///         // 1. 칼로리 계산
///         let calories = exerciseCalcService.calculateCalories(...)
///
///         // 2. ExerciseRecord 생성
///         let record = ExerciseRecord(...)
///         let created = try await exerciseRepository.create(record)
///
///         // 3. DailyLog 업데이트 (Service가 처리)
///         try await dailyLogService.addExercise(
///             date: created.date,
///             userId: userId,
///             calories: created.caloriesBurned,
///             duration: created.duration,
///             userBMR: user.currentBMR ?? 1650,
///             userTDEE: user.currentTDEE ?? 2310
///         )
///     }
/// }
/// ```
///
/// ### 왜 Service가 필요한가?
///
/// 1. **복잡한 비즈니스 로직 캡슐화**:
///    - DailyLog가 없으면 생성하고, 있으면 업데이트하는 로직을 Service에 캡슐화
///    - UseCase는 "운동 추가 시 DailyLog 업데이트"라는 고수준 작업만 호출
///
/// 2. **재사용성**:
///    - AddExerciseRecordUseCase, UpdateExerciseRecordUseCase, DeleteExerciseRecordUseCase
///      모두 DailyLogService를 재사용
///
/// 3. **테스트 용이성**:
///    - DailyLogService를 Mock으로 대체하여 UseCase 테스트 가능
///
/// 4. **변경 격리**:
///    - DailyLog 업데이트 로직이 변경되어도 Service만 수정하면 됨
///    - 모든 UseCase는 영향 받지 않음
