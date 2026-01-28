//
//  AddExerciseRecordUseCase.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-13.
//

import Foundation

/// 운동 기록 추가 유스케이스
///
/// 새로운 운동 기록을 생성하고, 칼로리를 계산하여 DailyLog를 업데이트합니다.
///
/// ## 책임
/// - 운동 입력값 검증 (duration 최소 1분)
/// - 사용자 체중 확인 (MET 계산에 필요)
/// - MET 기반 칼로리 계산
/// - ExerciseRecord 생성 및 저장
/// - DailyLog 업데이트
///
/// ## 의존성
/// - ExerciseRecordRepository: 운동 기록 저장
/// - DailyLogService: DailyLog 업데이트
///
/// ## 사용 시나리오
/// ```swift
/// let useCase = AddExerciseRecordUseCase(
///     exerciseRepository: exerciseRepository,
///     dailyLogService: dailyLogService
/// )
///
/// let record = try await useCase.execute(
///     userId: userId,
///     date: Date(),
///     exerciseType: .running,
///     duration: 30,
///     intensity: .high,
///     note: "아침 조깅",
///     userWeight: user.currentWeight ?? 70.0,
///     userGender: Gender(rawValue: user.gender) ?? .male,
///     userBMR: user.currentBMR ?? 1650,
///     userTDEE: user.currentTDEE ?? 2310
/// )
/// ```
///
/// ## 에러 케이스
/// - duration < 1분: ValidationError
/// - userWeight가 nil: InsufficientDataError
final class AddExerciseRecordUseCase {

    // MARK: - Properties

    /// 운동 기록 저장소
    private let exerciseRepository: ExerciseRecordRepository

    /// DailyLog 관리 서비스
    private let dailyLogService: DailyLogService

    // MARK: - Initialization

    /// AddExerciseRecordUseCase 초기화
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

    /// 새로운 운동 기록을 추가합니다.
    ///
    /// ## 실행 순서
    /// 1. 입력값 검증 (duration ≥ 1분)
    /// 2. MET 기반 칼로리 계산
    /// 3. ExerciseRecord 엔티티 생성
    /// 4. ExerciseRecordRepository를 통해 저장
    /// 5. DailyLogService를 통해 DailyLog 업데이트
    ///
    /// - Parameters:
    ///   - userId: 사용자 ID
    ///   - date: 운동일
    ///   - exerciseType: 운동 종류
    ///   - duration: 운동 시간 (분)
    ///   - intensity: 운동 강도
    ///   - note: 메모 (선택사항)
    ///   - userWeight: 사용자 체중 (kg) - MET 계산에 사용
    ///   - userGender: 사용자 성별 - 칼로리 보정에 사용
    ///   - userBMR: 사용자 BMR - DailyLog 생성 시 사용
    ///   - userTDEE: 사용자 TDEE - DailyLog 생성 시 사용
    ///
    /// - Throws:
    ///   - ValidationError: 입력값이 유효하지 않을 때
    ///   - InsufficientDataError: 필수 데이터(체중)가 없을 때
    ///   - RepositoryError: 저장 실패 시
    ///
    /// - Returns: 생성된 ExerciseRecord
    ///
    /// - Example:
    /// ```swift
    /// do {
    ///     let record = try await useCase.execute(
    ///         userId: user.id,
    ///         date: Date(),
    ///         exerciseType: .running,
    ///         duration: 30,
    ///         intensity: .high,
    ///         note: "아침 조깅",
    ///         userWeight: user.currentWeight ?? 70.0,
    ///         userGender: Gender(rawValue: user.gender) ?? .male,
    ///         userBMR: user.currentBMR ?? 1650,
    ///         userTDEE: user.currentTDEE ?? 2310
    ///     )
    ///     print("운동 기록 생성: \(record.caloriesBurned)kcal")
    /// } catch {
    ///     print("운동 기록 실패: \(error)")
    /// }
    /// ```
    func execute(
        userId: UUID,
        date: Date,
        exerciseType: ExerciseType,
        duration: Int32,
        intensity: Intensity,
        note: String? = nil,
        userWeight: Decimal,
        userGender: Gender,
        userBMR: Decimal,
        userTDEE: Decimal
    ) async throws -> ExerciseRecord {
        // 1. 입력값 검증
        try validateInput(duration: duration)

        // 2. MET 기반 칼로리 계산 (성별 고려)
        let caloriesBurned = ExerciseCalcService.calculateCalories(
            exerciseType: exerciseType,
            duration: duration,
            intensity: intensity,
            weight: userWeight,
            gender: userGender
        )

        // 3-4. ExerciseRecord 생성 및 저장
        let savedRecord = try await exerciseRepository.createRecord(
            userId: userId,
            date: date,
            exerciseType: exerciseType,
            duration: duration,
            intensity: intensity,
            caloriesBurned: caloriesBurned,
            note: note,
            fromHealthKit: false,
            healthKitId: nil
        )

        // 5. DailyLog 업데이트
        try await dailyLogService.addExercise(
            date: savedRecord.date ?? date,
            userId: userId,
            calories: savedRecord.caloriesBurned,
            duration: savedRecord.duration,
            userBMR: userBMR,
            userTDEE: userTDEE
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
}

// MARK: - Error Types

/// 검증 에러
enum ValidationError: LocalizedError {
    case invalidDuration(String)

    var errorDescription: String? {
        switch self {
        case .invalidDuration(let message):
            return message
        }
    }
}

// MARK: - UseCase Pattern 설명

/// ## UseCase Pattern이란?
///
/// UseCase는 비즈니스 로직을 캡슐화하고 여러 Repository와 Service를 조정하는 역할을 합니다.
///
/// ### UseCase vs Service vs Repository
///
/// **Repository**:
/// - 단일 엔티티의 CRUD 작업
/// - 데이터 영속성에 집중
/// - 예: ExerciseRecordRepository (ExerciseRecord만 관리)
///
/// **Service**:
/// - 도메인 로직 캡슐화
/// - 여러 엔티티 간 조정
/// - 예: DailyLogService (DailyLog 생성 및 업데이트)
///
/// **UseCase**:
/// - 사용자 액션에 대한 비즈니스 플로우 정의
/// - 여러 Repository와 Service를 조율
/// - 입력 검증 및 에러 처리
/// - 예: AddExerciseRecordUseCase (운동 기록 추가 전체 플로우)
///
/// ### 사용 예시
///
/// ```swift
/// // ViewModel에서 UseCase 사용
/// final class ExerciseInputViewModel: ObservableObject {
///     let addExerciseUseCase: AddExerciseRecordUseCase
///
///     func saveExercise() async {
///         do {
///             // UseCase가 모든 비즈니스 로직 처리
///             let record = try await addExerciseUseCase.execute(
///                 userId: currentUser.id,
///                 date: selectedDate,
///                 exerciseType: selectedType,
///                 duration: duration,
///                 intensity: intensity,
///                 note: note,
///                 userWeight: currentUser.currentWeight ?? 70.0,
///                 userBMR: currentUser.currentBMR ?? 1650,
///                 userTDEE: currentUser.currentTDEE ?? 2310
///             )
///             // UI 업데이트만 담당
///             self.isSuccess = true
///         } catch {
///             self.errorMessage = error.localizedDescription
///         }
///     }
/// }
/// ```
///
/// ### 왜 UseCase가 필요한가?
///
/// 1. **단일 책임 원칙**:
///    - ViewModel은 UI 로직에만 집중
///    - UseCase는 비즈니스 로직에만 집중
///
/// 2. **재사용성**:
///    - AddExerciseRecordUseCase는 여러 ViewModel에서 재사용 가능
///    - 위젯, 백그라운드 작업, Siri Shortcut 등 다양한 진입점에서 사용
///
/// 3. **테스트 용이성**:
///    - UseCase 단위로 비즈니스 로직 테스트 가능
///    - Repository와 Service를 Mock으로 대체하여 격리된 테스트
///
/// 4. **변경 격리**:
///    - 비즈니스 로직 변경 시 UseCase만 수정
///    - ViewModel과 UI는 영향 받지 않음
///
/// 5. **복잡도 관리**:
///    - 복잡한 플로우를 UseCase에 캡슐화
///    - ViewModel은 간결하게 유지
///
/// ### Clean Architecture 계층
///
/// ```
/// [Presentation]     ViewModel → UseCase를 호출
///       ↓
/// [Domain]          UseCase → Repository/Service 조율
///       ↓
/// [Data]            Repository → DataSource 호출
/// ```
