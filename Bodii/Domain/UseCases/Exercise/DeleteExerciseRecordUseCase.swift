//
//  DeleteExerciseRecordUseCase.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-14.
//

import Foundation

/// 운동 기록 삭제 유스케이스
///
/// 기존 운동 기록을 삭제하고 DailyLog를 업데이트합니다.
///
/// ## 책임
/// - 운동 기록 조회 (ID로)
/// - 사용자 권한 확인
/// - DailyLog 업데이트 (칼로리 및 시간 차감)
/// - ExerciseRecord 삭제
///
/// ## 의존성
/// - ExerciseRecordRepository: 운동 기록 조회 및 삭제
/// - DailyLogService: DailyLog 업데이트
///
/// ## 사용 시나리오
/// ```swift
/// let useCase = DeleteExerciseRecordUseCase(
///     exerciseRepository: exerciseRepository,
///     dailyLogService: dailyLogService
/// )
///
/// try await useCase.execute(
///     recordId: existingRecord.id,
///     userId: userId
/// )
/// ```
///
/// ## 에러 케이스
/// - recordId에 해당하는 기록이 없음: RecordNotFoundError
/// - userId 불일치: UnauthorizedError
final class DeleteExerciseRecordUseCase {

    // MARK: - Properties

    /// 운동 기록 저장소
    private let exerciseRepository: ExerciseRecordRepository

    /// DailyLog 관리 서비스
    private let dailyLogService: DailyLogService

    // MARK: - Initialization

    /// DeleteExerciseRecordUseCase 초기화
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

    /// 운동 기록을 삭제합니다.
    ///
    /// ## 실행 순서
    /// 1. 기존 운동 기록 조회 (ID로)
    /// 2. 권한 확인 (userId 일치 여부)
    /// 3. DailyLogService를 통해 DailyLog 업데이트 (칼로리 및 시간 차감)
    /// 4. ExerciseRecord 삭제
    ///
    /// - Parameters:
    ///   - recordId: 삭제할 운동 기록 ID
    ///   - userId: 사용자 ID
    ///
    /// - Throws:
    ///   - RecordNotFoundError: 운동 기록을 찾을 수 없을 때
    ///   - UnauthorizedError: userId가 일치하지 않을 때
    ///   - RepositoryError: 삭제 실패 시
    ///
    /// - Example:
    /// ```swift
    /// do {
    ///     try await useCase.execute(
    ///         recordId: record.id,
    ///         userId: user.id
    ///     )
    ///     print("운동 기록 삭제 완료")
    /// } catch {
    ///     print("운동 기록 삭제 실패: \(error)")
    /// }
    /// ```
    func execute(
        recordId: UUID,
        userId: UUID
    ) async throws {
        // 1. 기존 운동 기록 조회
        guard let existingRecord = try await exerciseRepository.fetchById(recordId, userId: userId) else {
            throw RecordNotFoundError.exerciseRecordNotFound("운동 기록을 찾을 수 없습니다.")
        }

        // 2. 권한 확인
        guard existingRecord.userId == userId else {
            throw UnauthorizedError.notOwner("해당 운동 기록을 삭제할 권한이 없습니다.")
        }

        // 3. DailyLog 업데이트 (칼로리 및 시간 차감)
        try await dailyLogService.removeExercise(
            date: existingRecord.date,
            userId: userId,
            calories: existingRecord.caloriesBurned,
            duration: existingRecord.duration
        )

        // 4. ExerciseRecord 삭제
        try await exerciseRepository.delete(id: recordId, userId: userId)
    }
}

// MARK: - Delete Pattern 설명

/// ## Delete UseCase Pattern
///
/// Delete UseCase는 데이터를 삭제할 때 다음 패턴을 따릅니다:
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
/// ### 3. 연관 데이터 정리 (DailyLog 업데이트)
/// ```swift
/// try await dailyLogService.removeExercise(
///     date: existingRecord.date,
///     userId: userId,
///     calories: existingRecord.caloriesBurned,
///     duration: existingRecord.duration
/// )
/// ```
///
/// ### 4. 데이터 삭제
/// ```swift
/// try await exerciseRepository.delete(id: recordId, userId: userId)
/// ```
///
/// ### 왜 이런 패턴을 사용하는가?
///
/// 1. **데이터 일관성**:
///    - 삭제 전 존재 여부 확인
///    - DailyLog와 ExerciseRecord 간 일관성 유지
///
/// 2. **보안**:
///    - userId 확인으로 다른 사용자의 기록 삭제 방지
///    - 권한 검증은 필수
///
/// 3. **연관 데이터 처리**:
///    - ExerciseRecord를 삭제하기 전에 DailyLog에서 해당 값을 차감
///    - 삭제 순서가 중요: DailyLog 업데이트 → ExerciseRecord 삭제
///
/// 4. **트랜잭션 무결성**:
///    - DailyLog 업데이트와 ExerciseRecord 삭제를 순차적으로 실행
///    - 하나라도 실패하면 전체 롤백 (async/await의 throw 메커니즘)
///
/// 5. **감사 추적**:
///    - 기존 기록을 먼저 조회하여 삭제할 데이터를 확인
///    - 로깅이 필요한 경우 삭제 전 기록 내용 저장 가능
///
/// ### Add vs Update vs Delete 차이점
///
/// **Add (생성)**:
/// 1. 입력값 검증
/// 2. 칼로리 계산
/// 3. ExerciseRecord 생성
/// 4. DailyLog 증가 (addExercise)
///
/// **Update (수정)**:
/// 1. 기존 기록 조회 및 권한 확인
/// 2. 입력값 검증
/// 3. 칼로리 재계산 (필요 시)
/// 4. ExerciseRecord 업데이트
/// 5. DailyLog 조정 (updateExercise - 차이값만큼)
///
/// **Delete (삭제)**:
/// 1. 기존 기록 조회 및 권한 확인
/// 2. DailyLog 감소 (removeExercise)
/// 3. ExerciseRecord 삭제
///
/// ### 삭제 순서의 중요성
///
/// ```swift
/// // ✅ 올바른 순서: DailyLog 먼저 업데이트
/// try await dailyLogService.removeExercise(...)
/// try await exerciseRepository.delete(...)
///
/// // ❌ 잘못된 순서: ExerciseRecord를 먼저 삭제하면
/// //    removeExercise에서 참조할 데이터가 사라짐
/// try await exerciseRepository.delete(...)
/// try await dailyLogService.removeExercise(...)  // 이미 삭제됨!
/// ```
///
/// 삭제 전에 기록을 먼저 조회하는 이유:
/// - DailyLog 업데이트에 필요한 정보 (date, calories, duration) 확보
/// - 삭제 후에는 이 정보를 얻을 수 없음
///
/// ### 사용 예시
///
/// ```swift
/// // ViewModel에서 DeleteExerciseRecordUseCase 사용
/// final class ExerciseListViewModel: ObservableObject {
///     let deleteExerciseUseCase: DeleteExerciseRecordUseCase
///
///     func deleteExercise(recordId: UUID) async {
///         do {
///             try await deleteExerciseUseCase.execute(
///                 recordId: recordId,
///                 userId: currentUser.id
///             )
///             // UI 업데이트: 리스트에서 제거
///             await loadExercises()
///             self.isSuccess = true
///         } catch RecordNotFoundError.exerciseRecordNotFound {
///             self.errorMessage = "운동 기록을 찾을 수 없습니다."
///         } catch UnauthorizedError.notOwner {
///             self.errorMessage = "삭제 권한이 없습니다."
///         } catch {
///             self.errorMessage = "삭제 실패: \(error.localizedDescription)"
///         }
///     }
/// }
/// ```
///
/// ### SwiftUI에서 스와이프 삭제 구현
///
/// ```swift
/// List {
///     ForEach(exercises) { exercise in
///         ExerciseCardView(exercise: exercise)
///     }
///     .onDelete { indexSet in
///         Task {
///             for index in indexSet {
///                 await viewModel.deleteExercise(recordId: exercises[index].id)
///             }
///         }
///     }
/// }
/// ```
///
