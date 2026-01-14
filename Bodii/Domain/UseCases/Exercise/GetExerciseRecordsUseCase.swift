//
//  GetExerciseRecordsUseCase.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-14.
//

import Foundation

/// 운동 기록 조회 유스케이스
///
/// 특정 날짜 또는 날짜 범위의 운동 기록을 조회합니다.
///
/// ## 책임
/// - 날짜 기반 운동 기록 조회
/// - 날짜 범위 기반 운동 기록 조회
/// - 정렬된 결과 반환 (최신순)
///
/// ## 의존성
/// - ExerciseRecordRepository: 운동 기록 조회
///
/// ## 사용 시나리오
/// ```swift
/// let useCase = GetExerciseRecordsUseCase(
///     exerciseRepository: exerciseRepository
/// )
///
/// // 특정 날짜 조회
/// let todayRecords = try await useCase.execute(
///     forDate: Date(),
///     userId: userId
/// )
///
/// // 날짜 범위 조회
/// let weekRecords = try await useCase.execute(
///     startDate: weekAgo,
///     endDate: today,
///     userId: userId
/// )
/// ```
final class GetExerciseRecordsUseCase {

    // MARK: - Properties

    /// 운동 기록 저장소
    private let exerciseRepository: ExerciseRecordRepository

    // MARK: - Initialization

    /// GetExerciseRecordsUseCase 초기화
    ///
    /// - Parameter exerciseRepository: 운동 기록 저장소
    init(exerciseRepository: ExerciseRecordRepository) {
        self.exerciseRepository = exerciseRepository
    }

    // MARK: - Public Methods

    /// 특정 날짜의 운동 기록을 조회합니다.
    ///
    /// ## 실행 순서
    /// 1. ExerciseRecordRepository를 통해 해당 날짜의 기록 조회
    /// 2. 정렬된 결과 반환 (최신순)
    ///
    /// - Parameters:
    ///   - date: 조회할 날짜
    ///   - userId: 사용자 ID
    ///
    /// - Throws: RepositoryError - 조회 실패 시
    ///
    /// - Returns: 운동 기록 배열 (없으면 빈 배열)
    ///
    /// - Example:
    /// ```swift
    /// do {
    ///     let todayRecords = try await useCase.execute(
    ///         forDate: Date(),
    ///         userId: user.id
    ///     )
    ///     print("\(todayRecords.count)개의 운동 기록")
    /// } catch {
    ///     print("조회 실패: \(error)")
    /// }
    /// ```
    func execute(
        forDate date: Date,
        userId: UUID
    ) async throws -> [ExerciseRecord] {
        // ExerciseRecordRepository를 통해 해당 날짜의 기록 조회
        // Repository가 이미 최신순(createdAt desc)으로 정렬하여 반환
        let records = try await exerciseRepository.fetchByDate(date, userId: userId)

        return records
    }

    /// 날짜 범위의 운동 기록을 조회합니다.
    ///
    /// ## 실행 순서
    /// 1. ExerciseRecordRepository를 통해 날짜 범위의 기록 조회
    /// 2. 정렬된 결과 반환 (최신순)
    ///
    /// - Parameters:
    ///   - startDate: 시작 날짜 (포함)
    ///   - endDate: 종료 날짜 (포함)
    ///   - userId: 사용자 ID
    ///
    /// - Throws: RepositoryError - 조회 실패 시
    ///
    /// - Returns: 운동 기록 배열 (없으면 빈 배열)
    ///
    /// - Example:
    /// ```swift
    /// do {
    ///     let calendar = Calendar.current
    ///     let today = Date()
    ///     let weekAgo = calendar.date(byAdding: .day, value: -7, to: today)!
    ///
    ///     let weekRecords = try await useCase.execute(
    ///         startDate: weekAgo,
    ///         endDate: today,
    ///         userId: user.id
    ///     )
    ///     print("최근 7일간 \(weekRecords.count)개의 운동 기록")
    /// } catch {
    ///     print("조회 실패: \(error)")
    /// }
    /// ```
    func execute(
        startDate: Date,
        endDate: Date,
        userId: UUID
    ) async throws -> [ExerciseRecord] {
        // ExerciseRecordRepository를 통해 날짜 범위의 기록 조회
        // Repository가 이미 최신순(date desc, createdAt desc)으로 정렬하여 반환
        let records = try await exerciseRepository.fetchByDateRange(
            startDate: startDate,
            endDate: endDate,
            userId: userId
        )

        return records
    }
}

// MARK: - Read UseCase Pattern 설명

/// ## Read UseCase Pattern
///
/// Read (조회) UseCase는 다른 UseCase(Create, Update, Delete)와 달리 매우 단순한 패턴을 따릅니다:
///
/// ### 1. 단순 조회의 특징
///
/// ```swift
/// func execute(...) async throws -> [ExerciseRecord] {
///     // Repository 호출만 하고 바로 반환
///     return try await repository.fetchByDate(date, userId: userId)
/// }
/// ```
///
/// ### 2. 왜 UseCase가 필요한가?
///
/// 단순 조회의 경우 "Repository를 직접 호출하면 되지 않나?" 라는 질문이 생길 수 있습니다.
/// 하지만 UseCase는 다음과 같은 이유로 여전히 유용합니다:
///
/// **일관성**:
/// - 모든 비즈니스 로직이 UseCase를 통해 실행
/// - ViewModel은 Repository를 직접 알지 못함 (의존성 역전)
///
/// **확장성**:
/// - 현재는 단순하지만, 나중에 비즈니스 로직 추가 가능
/// - 예: 조회 시 필터링, 캐싱, 권한 체크 등
///
/// **테스트 용이성**:
/// - UseCase를 Mock으로 대체하여 ViewModel 테스트
/// - Repository 구현과 독립적으로 비즈니스 로직 테스트
///
/// **진입점 통일**:
/// - UI, 위젯, 백그라운드 작업 등 모든 진입점이 동일한 UseCase 사용
/// - 일관된 에러 처리 및 로깅
///
/// ### 3. Read vs Write UseCase
///
/// **Read UseCase (조회)**:
/// ```swift
/// func execute(...) async throws -> [ExerciseRecord] {
///     return try await repository.fetchByDate(...)
/// }
/// ```
/// - 단순하고 직관적
/// - Repository를 얇게 감싸는 래퍼
/// - 주로 데이터를 있는 그대로 반환
///
/// **Write UseCase (생성/수정/삭제)**:
/// ```swift
/// func execute(...) async throws -> ExerciseRecord {
///     // 1. 입력 검증
///     try validateInput(duration: duration)
///
///     // 2. 비즈니스 로직 (계산, 변환 등)
///     let calories = ExerciseCalcService.calculateCalories(...)
///
///     // 3. Repository 호출
///     let record = try await repository.create(...)
///
///     // 4. 부가 작업 (DailyLog 업데이트 등)
///     try await dailyLogService.addExercise(...)
///
///     return record
/// }
/// ```
/// - 복잡한 비즈니스 로직
/// - 여러 Service와 Repository 조율
/// - 입력 검증, 에러 처리, 트랜잭션 관리
///
/// ### 4. 언제 Read UseCase를 생략할 수 있나?
///
/// 프로젝트 규모가 작고 비즈니스 로직이 거의 없다면, Read UseCase를 생략하고
/// ViewModel에서 Repository를 직접 호출하는 것도 고려할 수 있습니다:
///
/// ```swift
/// // UseCase 사용 (권장)
/// final class ExerciseListViewModel: ObservableObject {
///     let getExerciseRecordsUseCase: GetExerciseRecordsUseCase
///
///     func loadRecords() async {
///         records = try await getExerciseRecordsUseCase.execute(...)
///     }
/// }
///
/// // Repository 직접 사용 (소규모 프로젝트에서 고려)
/// final class ExerciseListViewModel: ObservableObject {
///     let exerciseRepository: ExerciseRecordRepository
///
///     func loadRecords() async {
///         records = try await exerciseRepository.fetchByDate(...)
///     }
/// }
/// ```
///
/// 하지만 대부분의 경우, **일관성**과 **확장성**을 위해 Read UseCase를 사용하는 것이 좋습니다.
///
/// ### 5. 사용 예시
///
/// ```swift
/// // ViewModel에서 GetExerciseRecordsUseCase 사용
/// final class ExerciseListViewModel: ObservableObject {
///     @Published var records: [ExerciseRecord] = []
///     @Published var isLoading = false
///     @Published var errorMessage: String?
///
///     private let getExerciseRecordsUseCase: GetExerciseRecordsUseCase
///
///     init(getExerciseRecordsUseCase: GetExerciseRecordsUseCase) {
///         self.getExerciseRecordsUseCase = getExerciseRecordsUseCase
///     }
///
///     func loadTodayRecords(userId: UUID) async {
///         isLoading = true
///         defer { isLoading = false }
///
///         do {
///             // UseCase를 통해 조회
///             records = try await getExerciseRecordsUseCase.execute(
///                 forDate: Date(),
///                 userId: userId
///             )
///         } catch {
///             errorMessage = "운동 기록 조회 실패: \(error.localizedDescription)"
///         }
///     }
///
///     func loadWeekRecords(userId: UUID) async {
///         isLoading = true
///         defer { isLoading = false }
///
///         do {
///             let calendar = Calendar.current
///             let today = Date()
///             let weekAgo = calendar.date(byAdding: .day, value: -7, to: today)!
///
///             // 날짜 범위 조회
///             records = try await getExerciseRecordsUseCase.execute(
///                 startDate: weekAgo,
///                 endDate: today,
///                 userId: userId
///             )
///         } catch {
///             errorMessage = "운동 기록 조회 실패: \(error.localizedDescription)"
///         }
///     }
/// }
/// ```
///
/// ### 6. 향후 확장 가능성
///
/// 현재는 단순한 조회지만, 나중에 다음과 같은 기능을 추가할 수 있습니다:
///
/// ```swift
/// func execute(forDate date: Date, userId: UUID) async throws -> [ExerciseRecord] {
///     // 1. 권한 체크 (예: 프리미엄 사용자만 과거 30일 이상 조회 가능)
///     try await checkUserPermission(userId: userId, date: date)
///
///     // 2. 캐시 확인
///     if let cached = cache.get(key: "\(userId)-\(date)") {
///         return cached
///     }
///
///     // 3. Repository 조회
///     let records = try await exerciseRepository.fetchByDate(date, userId: userId)
///
///     // 4. 캐시 저장
///     cache.set(key: "\(userId)-\(date)", value: records)
///
///     // 5. 로깅
///     logger.log("Fetched \(records.count) exercise records for date: \(date)")
///
///     return records
/// }
/// ```
///
/// UseCase를 미리 정의해두면, 이런 확장이 필요할 때 ViewModel 수정 없이
/// UseCase만 수정하면 됩니다.
