//
//  ExerciseRecordRepositoryImpl.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-13.
//

// 📚 학습 포인트: Repository 구현체
// Repository Pattern은 Clean Architecture에서 데이터 소스 추상화를 담당
// 도메인 계층은 이 인터페이스만 알고, 실제 구현 (Core Data, 네트워크 등)을 알 필요 없음
// 💡 Java 비교: Spring Data JPA의 Repository 인터페이스 구현체와 유사

import Foundation

// MARK: - ExerciseRecordRepositoryImpl

/// ExerciseRecordRepository의 구현체
///
/// ## 책임
/// - ExerciseRecordRepository 프로토콜 구현
/// - LocalDataSource와 도메인 계층 간 조정
/// - 데이터 소스 변경(Core Data → 네트워크)에 대한 유연성 제공
///
/// ## 의존성
/// - ExerciseRecordLocalDataSource: Core Data 작업 담당
///
/// - Example:
/// ```swift
/// let context = PersistenceController.shared.viewContext
/// let dataSource = ExerciseRecordLocalDataSource(context: context)
/// let repository: ExerciseRecordRepository = ExerciseRecordRepositoryImpl(
///     localDataSource: dataSource
/// )
///
/// // 운동 기록 생성
/// let record = ExerciseRecord(...)
/// let created = try await repository.create(record)
///
/// // 오늘 운동 조회
/// let todayRecords = try await repository.fetchByDate(Date(), userId: userId)
/// ```
final class ExerciseRecordRepositoryImpl: ExerciseRecordRepository {

    // MARK: - Properties

    // 📚 학습 포인트: 의존성 주입 (Dependency Injection)
    // 구체적인 구현체가 아닌 프로토콜에 의존하지 않고,
    // LocalDataSource 클래스에 직접 의존 (현재는 하나의 데이터 소스만 사용)
    // 💡 향후 확장: RemoteDataSource 추가 시 프로토콜로 추상화 가능
    private let localDataSource: ExerciseRecordLocalDataSource

    // MARK: - Initialization

    /// Repository 초기화
    ///
    /// - Parameter localDataSource: Core Data 작업을 담당하는 로컬 데이터 소스
    init(localDataSource: ExerciseRecordLocalDataSource) {
        self.localDataSource = localDataSource
    }

    // MARK: - Create

    /// 새로운 운동 기록을 생성합니다.
    ///
    /// - Parameter record: 생성할 운동 기록
    /// - Throws: 데이터 저장 실패 시 에러
    /// - Returns: 생성된 운동 기록 (저장소에서 할당된 ID 포함)
    func create(_ record: ExerciseRecord) async throws -> ExerciseRecord {
        // 📚 학습 포인트: Repository는 단순히 DataSource에 위임
        // 비즈니스 로직은 UseCase에서 처리하고,
        // Repository는 데이터 영속성만 담당
        return try await localDataSource.save(record)
    }

    /// 입력 데이터로 새로운 운동 기록을 생성합니다.
    func createRecord(
        userId: UUID,
        date: Date,
        exerciseType: ExerciseType,
        duration: Int32,
        intensity: Intensity,
        caloriesBurned: Int32,
        note: String?,
        fromHealthKit: Bool,
        healthKitId: String?
    ) async throws -> ExerciseRecord {
        return try await localDataSource.createRecord(
            userId: userId,
            date: date,
            exerciseType: exerciseType,
            duration: duration,
            intensity: intensity,
            caloriesBurned: caloriesBurned,
            note: note,
            fromHealthKit: fromHealthKit,
            healthKitId: healthKitId
        )
    }

    // MARK: - Read

    /// ID로 운동 기록을 조회합니다.
    ///
    /// - Parameters:
    ///   - id: 운동 기록 고유 식별자
    ///   - userId: 사용자 ID (권한 확인용)
    /// - Throws: 조회 실패 시 에러
    /// - Returns: 조회된 운동 기록, 없으면 nil
    func fetchById(_ id: UUID, userId: UUID) async throws -> ExerciseRecord? {
        return try await localDataSource.fetchById(id, userId: userId)
    }

    /// 특정 날짜의 모든 운동 기록을 조회합니다.
    ///
    /// 해당 날짜의 00:00:00 ~ 23:59:59 범위 내 운동 기록을 반환합니다.
    /// 결과는 생성 시간순(최신순)으로 정렬됩니다.
    ///
    /// - Parameters:
    ///   - date: 조회할 날짜
    ///   - userId: 사용자 ID
    /// - Throws: 조회 실패 시 에러
    /// - Returns: 운동 기록 배열 (없으면 빈 배열)
    func fetchByDate(_ date: Date, userId: UUID) async throws -> [ExerciseRecord] {
        return try await localDataSource.fetchByDate(date, userId: userId)
    }

    /// 날짜 범위 내 모든 운동 기록을 조회합니다.
    ///
    /// startDate(00:00:00)부터 endDate(23:59:59)까지의 운동 기록을 반환합니다.
    /// 결과는 날짜순(최신순)으로 정렬됩니다.
    ///
    /// - Parameters:
    ///   - startDate: 시작 날짜 (포함)
    ///   - endDate: 종료 날짜 (포함)
    ///   - userId: 사용자 ID
    /// - Throws: 조회 실패 시 에러
    /// - Returns: 운동 기록 배열 (없으면 빈 배열)
    func fetchByDateRange(startDate: Date, endDate: Date, userId: UUID) async throws -> [ExerciseRecord] {
        return try await localDataSource.fetchByDateRange(
            startDate: startDate,
            endDate: endDate,
            userId: userId
        )
    }

    /// 사용자의 모든 운동 기록을 조회합니다.
    ///
    /// 결과는 날짜순(최신순)으로 정렬됩니다.
    ///
    /// - Parameter userId: 사용자 ID
    /// - Throws: 조회 실패 시 에러
    /// - Returns: 운동 기록 배열 (없으면 빈 배열)
    func fetchAll(userId: UUID) async throws -> [ExerciseRecord] {
        return try await localDataSource.fetchAll(userId: userId)
    }

    func fetchByHealthKitId(_ healthKitId: String, userId: UUID) async throws -> ExerciseRecord? {
        return try await localDataSource.fetchByHealthKitId(healthKitId, userId: userId)
    }

    // MARK: - Update

    /// 기존 운동 기록을 수정합니다.
    ///
    /// ID가 일치하는 기록을 찾아 제공된 데이터로 업데이트합니다.
    /// userId가 일치하지 않으면 권한 에러를 throw해야 합니다.
    ///
    /// - Parameter record: 수정할 운동 기록 (ID 필수)
    /// - Throws: 업데이트 실패 또는 권한 없음 시 에러
    /// - Returns: 수정된 운동 기록
    func update(_ record: ExerciseRecord) async throws -> ExerciseRecord {
        return try await localDataSource.update(record)
    }

    // MARK: - Delete

    /// 운동 기록을 삭제합니다.
    ///
    /// userId가 일치하지 않으면 권한 에러를 throw해야 합니다.
    ///
    /// - Parameters:
    ///   - id: 삭제할 운동 기록 ID
    ///   - userId: 사용자 ID (권한 확인용)
    /// - Throws: 삭제 실패 또는 권한 없음 시 에러
    func delete(id: UUID, userId: UUID) async throws {
        try await localDataSource.delete(id: id, userId: userId)
    }

    // MARK: - Utility

    /// 특정 날짜의 운동 기록 개수를 반환합니다.
    ///
    /// - Parameters:
    ///   - date: 조회할 날짜
    ///   - userId: 사용자 ID
    /// - Throws: 조회 실패 시 에러
    /// - Returns: 운동 기록 개수
    func count(forDate date: Date, userId: UUID) async throws -> Int {
        return try await localDataSource.count(forDate: date, userId: userId)
    }

    /// 특정 날짜의 총 운동 시간(분)을 반환합니다.
    ///
    /// - Parameters:
    ///   - date: 조회할 날짜
    ///   - userId: 사용자 ID
    /// - Throws: 조회 실패 시 에러
    /// - Returns: 총 운동 시간 (분)
    func totalDuration(forDate date: Date, userId: UUID) async throws -> Int32 {
        return try await localDataSource.totalDuration(forDate: date, userId: userId)
    }

    /// 특정 날짜의 총 소모 칼로리를 반환합니다.
    ///
    /// - Parameters:
    ///   - date: 조회할 날짜
    ///   - userId: 사용자 ID
    /// - Throws: 조회 실패 시 에러
    /// - Returns: 총 소모 칼로리 (kcal)
    func totalCaloriesBurned(forDate date: Date, userId: UUID) async throws -> Int32 {
        return try await localDataSource.totalCaloriesBurned(forDate: date, userId: userId)
    }
}

// MARK: - Repository Pattern 설명

/// ## Repository Pattern이란?
///
/// Repository는 데이터 소스와 도메인 계층 사이의 추상화 계층입니다.
///
/// ### 역할
/// 1. **데이터 소스 추상화**: 도메인 계층은 데이터가 Core Data, API, 파일 등 어디서 오는지 알 필요 없음
/// 2. **비즈니스 로직 분리**: 데이터 영속성 로직과 비즈니스 로직 분리
/// 3. **테스트 용이성**: Mock Repository로 쉽게 테스트 가능
/// 4. **확장성**: 데이터 소스 변경 시 Repository 구현체만 교체하면 됨
///
/// ### 계층 구조
/// ```
/// UseCase (Domain)
///    ↓ depends on
/// Repository Protocol (Domain/Interfaces)
///    ↑ implements
/// Repository Implementation (Data)
///    ↓ uses
/// DataSource (Data)
///    ↓ uses
/// Core Data / Network / File System
/// ```
///
/// ### 향후 확장 예시
/// ```swift
/// // 현재: 로컬만 사용
/// class ExerciseRecordRepositoryImpl {
///     let localDataSource: ExerciseRecordLocalDataSource
/// }
///
/// // 향후: 네트워크 동기화 추가
/// class ExerciseRecordRepositoryImpl {
///     let localDataSource: ExerciseRecordLocalDataSource
///     let remoteDataSource: ExerciseRecordRemoteDataSource
///
///     func create(_ record: ExerciseRecord) async throws -> ExerciseRecord {
///         // 1. 로컬에 저장
///         let saved = try await localDataSource.create(record)
///         // 2. 네트워크에 동기화 (백그라운드)
///         Task { try? await remoteDataSource.sync(saved) }
///         return saved
///     }
/// }
/// ```
