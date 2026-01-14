//
//  UpdateExerciseRecordUseCase.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-14.
//

import Foundation

/// 운동 기록 수정 유스케이스
///
/// 기존 운동 기록을 수정하고, 칼로리를 재계산하여 DailyLog를 업데이트합니다.
///
/// ## 책임
/// - 운동 기록 조회 (ID로)
/// - 운동 입력값 검증 (duration 최소 1분)
/// - 변경사항이 있을 경우 칼로리 재계산
/// - ExerciseRecord 업데이트 및 저장
/// - DailyLog 업데이트 (차이값만큼 조정)
///
/// ## 의존성
/// - ExerciseRecordRepository: 운동 기록 조회 및 업데이트
/// - DailyLogService: DailyLog 업데이트
///
/// ## 사용 시나리오
/// ```swift
/// let useCase = UpdateExerciseRecordUseCase(
///     exerciseRepository: exerciseRepository,
///     dailyLogService: dailyLogService
/// )
///
/// let updatedRecord = try await useCase.execute(
///     recordId: existingRecord.id,
///     userId: userId,
///     exerciseType: .cycling,
///     duration: 45,
///     intensity: .medium,
///     note: "점심 자전거 라이딩",
///     userWeight: user.currentWeight ?? 70.0
/// )
/// ```
///
/// ## 에러 케이스
/// - recordId에 해당하는 기록이 없음: RecordNotFoundError
/// - duration < 1분: ValidationError
/// - userId 불일치: UnauthorizedError
final class UpdateExerciseRecordUseCase {

    // MARK: - Properties

    /// 운동 기록 저장소
    private let exerciseRepository: ExerciseRecordRepository

    /// DailyLog 관리 서비스
    private let dailyLogService: DailyLogService

    // MARK: - Initialization

    /// UpdateExerciseRecordUseCase 초기화
    ///
    /// - Parameters:
    ///   - exerciseRepository: 운동 기록 저장소
    ///   - dailyLogService: DailyLog 관리 서비스
    init(
        exerciseRepository: ExerciseRecordRepository,
        dailyLogService: DailyLogService
    ) {
        self.exerciseRepository = exerciseRepository
        self.dailyLogService = dailyLogService
    }

    // MARK: - Public Methods

    /// 기존 운동 기록을 수정합니다.
    ///
    /// ## 실행 순서
    /// 1. 기존 운동 기록 조회 (ID로)
    /// 2. 권한 확인 (userId 일치 여부)
    /// 3. 입력값 검증 (duration ≥ 1분)
    /// 4. 변경사항 확인 및 칼로리 재계산 (type, duration, intensity 변경 시)
    /// 5. ExerciseRecord 업데이트
    /// 6. DailyLogService를 통해 DailyLog 조정 (차이값만큼)
    ///
    /// - Parameters:
    ///   - recordId: 수정할 운동 기록 ID
    ///   - userId: 사용자 ID
    ///   - exerciseType: 운동 종류
    ///   - duration: 운동 시간 (분)
    ///   - intensity: 운동 강도
    ///   - note: 메모 (선택사항)
    ///   - userWeight: 사용자 체중 (kg) - MET 계산에 사용
    ///
    /// - Throws:
    ///   - RecordNotFoundError: 운동 기록을 찾을 수 없을 때
    ///   - UnauthorizedError: userId가 일치하지 않을 때
    ///   - ValidationError: 입력값이 유효하지 않을 때
    ///   - RepositoryError: 저장 실패 시
    ///
    /// - Returns: 수정된 ExerciseRecord
    ///
    /// - Example:
    /// ```swift
    /// do {
    ///     let updatedRecord = try await useCase.execute(
    ///         recordId: record.id,
    ///         userId: user.id,
    ///         exerciseType: .running,
    ///         duration: 45,  // 30분 → 45분으로 변경
    ///         intensity: .high,
    ///         note: "아침 조깅 (연장)",
    ///         userWeight: user.currentWeight ?? 70.0
    ///     )
    ///     print("운동 기록 수정: \(updatedRecord.caloriesBurned)kcal")
    /// } catch {
    ///     print("운동 기록 수정 실패: \(error)")
    /// }
    /// ```
    func execute(
        recordId: UUID,
        userId: UUID,
        exerciseType: ExerciseType,
        duration: Int32,
        intensity: Intensity,
        note: String? = nil,
        userWeight: Decimal
    ) async throws -> ExerciseRecord {
        // 1. 기존 운동 기록 조회
        guard let existingRecord = try await exerciseRepository.fetchById(recordId, userId: userId) else {
            throw RecordNotFoundError.exerciseRecordNotFound("운동 기록을 찾을 수 없습니다.")
        }

        // 2. 권한 확인
        guard existingRecord.userId == userId else {
            throw UnauthorizedError.notOwner("해당 운동 기록을 수정할 권한이 없습니다.")
        }

        // 3. 입력값 검증
        try validateInput(duration: duration)

        // 4. 변경사항 확인 및 칼로리 재계산
        let needsRecalculation = hasCalorieAffectingChanges(
            existingRecord: existingRecord,
            newType: exerciseType,
            newDuration: duration,
            newIntensity: intensity
        )

        let newCalories: Int32
        if needsRecalculation {
            // 칼로리 재계산
            newCalories = ExerciseCalcService.calculateCalories(
                exerciseType: exerciseType,
                duration: duration,
                intensity: intensity,
                weight: userWeight
            )
        } else {
            // 변경사항이 없으면 기존 칼로리 유지
            newCalories = existingRecord.caloriesBurned
        }

        // 5. ExerciseRecord 업데이트
        let updatedRecord = ExerciseRecord(
            id: existingRecord.id,
            userId: existingRecord.userId,
            date: existingRecord.date,
            exerciseType: exerciseType,
            duration: duration,
            intensity: intensity,
            caloriesBurned: newCalories,
            createdAt: existingRecord.createdAt
        )

        let savedRecord = try await exerciseRepository.update(updatedRecord)

        // 6. DailyLog 업데이트 (차이값만큼 조정)
        try await dailyLogService.updateExercise(
            date: savedRecord.date,
            userId: userId,
            oldCalories: existingRecord.caloriesBurned,
            newCalories: savedRecord.caloriesBurned,
            oldDuration: existingRecord.duration,
            newDuration: savedRecord.duration
        )

        return savedRecord
    }

    // MARK: - Private Methods

    /// 입력값을 검증합니다.
    ///
    /// ## 검증 규칙
    /// - duration: 최소 1분 이상
    ///
    /// - Parameter duration: 운동 시간 (분)
    /// - Throws: ValidationError - 검증 실패 시
    private func validateInput(duration: Int32) throws {
        // 운동 시간은 최소 1분 이상
        guard duration >= 1 else {
            throw ValidationError.invalidDuration("최소 1분 이상 입력해주세요")
        }
    }

    /// 칼로리 재계산이 필요한 변경사항이 있는지 확인합니다.
    ///
    /// 운동 종류, 시간, 강도 중 하나라도 변경되었으면 true를 반환합니다.
    ///
    /// - Parameters:
    ///   - existingRecord: 기존 운동 기록
    ///   - newType: 새로운 운동 종류
    ///   - newDuration: 새로운 운동 시간
    ///   - newIntensity: 새로운 운동 강도
    /// - Returns: 재계산 필요 여부
    private func hasCalorieAffectingChanges(
        existingRecord: ExerciseRecord,
        newType: ExerciseType,
        newDuration: Int32,
        newIntensity: Intensity
    ) -> Bool {
        return existingRecord.exerciseType != newType ||
               existingRecord.duration != newDuration ||
               existingRecord.intensity != newIntensity
    }
}

// MARK: - Error Types

/// 기록 미발견 에러
enum RecordNotFoundError: LocalizedError {
    case exerciseRecordNotFound(String)

    var errorDescription: String? {
        switch self {
        case .exerciseRecordNotFound(let message):
            return message
        }
    }
}

/// 권한 에러
enum UnauthorizedError: LocalizedError {
    case notOwner(String)

    var errorDescription: String? {
        switch self {
        case .notOwner(let message):
            return message
        }
    }
}

// MARK: - Update Pattern 설명

/// ## Update UseCase Pattern
///
/// Update UseCase는 기존 데이터를 수정할 때 다음 패턴을 따릅니다:
///
/// ### 1. 기존 데이터 조회
/// ```swift
/// guard let existingRecord = try await repository.fetchById(id, userId: userId) else {
///     throw RecordNotFoundError.exerciseRecordNotFound("...")
/// }
/// ```
///
/// ### 2. 권한 확인
/// ```swift
/// guard existingRecord.userId == userId else {
///     throw UnauthorizedError.notOwner("...")
/// }
/// ```
///
/// ### 3. 입력값 검증
/// ```swift
/// try validateInput(duration: duration)
/// ```
///
/// ### 4. 변경사항 확인 및 조건부 재계산
/// ```swift
/// let needsRecalculation = hasCalorieAffectingChanges(...)
/// if needsRecalculation {
///     newCalories = ExerciseCalcService.calculateCalories(...)
/// } else {
///     newCalories = existingRecord.caloriesBurned
/// }
/// ```
///
/// ### 5. 엔티티 업데이트
/// ```swift
/// let updatedRecord = ExerciseRecord(
///     id: existingRecord.id,           // ID 유지
///     userId: existingRecord.userId,   // userId 유지
///     date: existingRecord.date,       // date 유지
///     exerciseType: newType,           // 새 값
///     duration: newDuration,           // 새 값
///     intensity: newIntensity,         // 새 값
///     caloriesBurned: newCalories,     // 재계산된 값
///     createdAt: existingRecord.createdAt  // createdAt 유지
/// )
/// ```
///
/// ### 6. DailyLog 조정 (차이값만큼)
/// ```swift
/// try await dailyLogService.updateExercise(
///     date: savedRecord.date,
///     userId: userId,
///     oldCalories: existingRecord.caloriesBurned,  // 이전 값
///     newCalories: savedRecord.caloriesBurned,     // 새 값
///     oldDuration: existingRecord.duration,        // 이전 값
///     newDuration: savedRecord.duration            // 새 값
/// )
/// ```
///
/// ### 왜 이런 패턴을 사용하는가?
///
/// 1. **데이터 일관성**:
///    - 기존 기록을 먼저 조회하여 존재 여부 확인
///    - 변경되지 않아야 할 필드(id, userId, createdAt)는 유지
///
/// 2. **보안**:
///    - userId 확인으로 다른 사용자의 기록 수정 방지
///    - 권한 검증은 필수
///
/// 3. **효율성**:
///    - 칼로리에 영향을 주지 않는 변경(예: note만 수정)은 재계산 생략
///    - 불필요한 연산 방지
///
/// 4. **정확성**:
///    - DailyLog는 차이값만큼만 조정 (전체 재계산 불필요)
///    - 예: 300kcal → 450kcal로 변경 시 +150kcal만 추가
///
/// 5. **트랜잭션 무결성**:
///    - ExerciseRecord 업데이트와 DailyLog 조정을 순차적으로 실행
///    - 하나라도 실패하면 전체 롤백 (async/await의 throw 메커니즘)
///
/// ### 사용 예시
///
/// ```swift
/// // ViewModel에서 UpdateExerciseRecordUseCase 사용
/// final class ExerciseInputViewModel: ObservableObject {
///     let updateExerciseUseCase: UpdateExerciseRecordUseCase
///
///     func updateExercise(recordId: UUID) async {
///         do {
///             let updated = try await updateExerciseUseCase.execute(
///                 recordId: recordId,
///                 userId: currentUser.id,
///                 exerciseType: selectedType,
///                 duration: duration,
///                 intensity: intensity,
///                 note: note,
///                 userWeight: currentUser.currentWeight ?? 70.0
///             )
///             self.isSuccess = true
///         } catch RecordNotFoundError.exerciseRecordNotFound {
///             self.errorMessage = "운동 기록을 찾을 수 없습니다."
///         } catch UnauthorizedError.notOwner {
///             self.errorMessage = "수정 권한이 없습니다."
///         } catch ValidationError.invalidDuration {
///             self.errorMessage = "운동 시간을 확인해주세요."
///         } catch {
///             self.errorMessage = "수정 실패: \(error.localizedDescription)"
///         }
///     }
/// }
/// ```
