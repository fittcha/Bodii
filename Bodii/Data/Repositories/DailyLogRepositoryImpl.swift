//
//  DailyLogRepositoryImpl.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-13.
//

// 📚 학습 포인트: Repository 구현체
// Repository Pattern은 Clean Architecture에서 데이터 소스 추상화를 담당
// 도메인 계층은 이 인터페이스만 알고, 실제 구현 (Core Data, 네트워크 등)을 알 필요 없음
// 💡 Java 비교: Spring Data JPA의 Repository 인터페이스 구현체와 유사

import Foundation

// MARK: - DailyLogRepositoryImpl

/// DailyLogRepository의 구현체
///
/// ## 책임
/// - DailyLogRepository 프로토콜 구현
/// - LocalDataSource와 도메인 계층 간 조정
/// - 데이터 소스 변경(Core Data → 네트워크)에 대한 유연성 제공
///
/// ## 의존성
/// - DailyLogLocalDataSource: Core Data 작업 담당
///
/// - Example:
/// ```swift
/// let context = PersistenceController.shared.viewContext
/// let dataSource = DailyLogLocalDataSource(context: context)
/// let repository: DailyLogRepository = DailyLogRepositoryImpl(
///     localDataSource: dataSource
/// )
///
/// // DailyLog 조회 또는 생성
/// let dailyLog = try await repository.getOrCreate(
///     for: Date(),
///     userId: userId,
///     bmr: 1650,
///     tdee: 2310
/// )
///
/// // 운동 추가
/// try await repository.addExercise(
///     date: Date(),
///     userId: userId,
///     calories: 350,
///     duration: 30
/// )
/// ```
final class DailyLogRepositoryImpl: DailyLogRepository {

    // MARK: - Properties

    // 📚 학습 포인트: 의존성 주입 (Dependency Injection)
    // 구체적인 구현체가 아닌 프로토콜에 의존하지 않고,
    // LocalDataSource 클래스에 직접 의존 (현재는 하나의 데이터 소스만 사용)
    // 💡 향후 확장: RemoteDataSource 추가 시 프로토콜로 추상화 가능
    private let localDataSource: DailyLogLocalDataSource

    // MARK: - Initialization

    /// Repository 초기화
    ///
    /// - Parameter localDataSource: Core Data 작업을 담당하는 로컬 데이터 소스
    init(localDataSource: DailyLogLocalDataSource) {
        self.localDataSource = localDataSource
    }

    // MARK: - Create / Get

    /// 특정 날짜의 DailyLog를 조회하거나 없으면 생성합니다.
    ///
    /// 해당 날짜의 DailyLog가 존재하면 반환하고,
    /// 없으면 제공된 bmr, tdee 값으로 새로 생성합니다.
    ///
    /// - Parameters:
    ///   - date: 조회할 날짜
    ///   - userId: 사용자 ID
    ///   - bmr: 기초대사량 (kcal), DailyLog 생성 시 사용
    ///   - tdee: 활동대사량 (kcal), DailyLog 생성 시 사용
    /// - Throws: 데이터 작업 실패 시 에러
    /// - Returns: 조회되거나 생성된 DailyLog
    func getOrCreate(for date: Date, userId: UUID, bmr: Int32, tdee: Int32) async throws -> DailyLog {
        // 📚 학습 포인트: Repository는 단순히 DataSource에 위임
        // 비즈니스 로직은 UseCase에서 처리하고,
        // Repository는 데이터 영속성만 담당
        return try await localDataSource.getOrCreate(for: date, userId: userId, bmr: bmr, tdee: tdee)
    }

    /// 특정 날짜의 DailyLog를 조회합니다.
    ///
    /// - Parameters:
    ///   - date: 조회할 날짜
    ///   - userId: 사용자 ID
    /// - Throws: 조회 실패 시 에러
    /// - Returns: 조회된 DailyLog, 없으면 nil
    func fetch(for date: Date, userId: UUID) async throws -> DailyLog? {
        return try await localDataSource.fetch(for: date, userId: userId)
    }

    /// 오늘 날짜의 DailyLog를 조회합니다.
    ///
    /// 대시보드에서 사용하는 단일 진입점으로, 오늘 날짜의 DailyLog를 반환합니다.
    /// DailyLog에는 모든 사전 계산된 값(칼로리, 매크로, 운동, 수면 등)이 포함되어 있습니다.
    ///
    /// - Parameter userId: 사용자 ID
    /// - Throws: 조회 실패 시 에러
    /// - Returns: 조회된 DailyLog, 없으면 nil
    func fetchCurrentDay(userId: UUID) async throws -> DailyLog? {
        return try await localDataSource.fetchCurrentDay(userId: userId)
    }

    // MARK: - Update

    /// DailyLog를 업데이트합니다.
    ///
    /// - Parameter dailyLog: 업데이트할 DailyLog
    /// - Throws: 업데이트 실패 시 에러
    /// - Returns: 업데이트된 DailyLog
    func update(_ dailyLog: DailyLog) async throws -> DailyLog {
        try await localDataSource.save(dailyLog)
        return dailyLog
    }

    // MARK: - Exercise Updates

    /// 운동 추가 시 DailyLog를 업데이트합니다.
    ///
    /// totalCaloriesOut, exerciseMinutes, exerciseCount를 증가시킵니다.
    /// netCalories도 자동으로 재계산됩니다.
    ///
    /// - Parameters:
    ///   - date: 운동 날짜
    ///   - userId: 사용자 ID
    ///   - calories: 소모 칼로리 (kcal)
    ///   - duration: 운동 시간 (분)
    /// - Throws: 업데이트 실패 시 에러
    func addExercise(date: Date, userId: UUID, calories: Int32, duration: Int32) async throws {
        try await localDataSource.addExercise(
            date: date,
            userId: userId,
            calories: calories,
            duration: duration
        )
    }

    /// 운동 삭제 시 DailyLog를 업데이트합니다.
    ///
    /// totalCaloriesOut, exerciseMinutes, exerciseCount를 감소시킵니다.
    /// netCalories도 자동으로 재계산됩니다.
    ///
    /// - Parameters:
    ///   - date: 운동 날짜
    ///   - userId: 사용자 ID
    ///   - calories: 소모 칼로리 (kcal)
    ///   - duration: 운동 시간 (분)
    /// - Throws: 업데이트 실패 시 에러
    func removeExercise(date: Date, userId: UUID, calories: Int32, duration: Int32) async throws {
        try await localDataSource.removeExercise(
            date: date,
            userId: userId,
            calories: calories,
            duration: duration
        )
    }

    /// 운동 수정 시 DailyLog를 업데이트합니다.
    ///
    /// 이전 값과 새 값의 차이만큼 조정합니다.
    /// netCalories도 자동으로 재계산됩니다.
    ///
    /// - Parameters:
    ///   - date: 운동 날짜
    ///   - userId: 사용자 ID
    ///   - oldCalories: 이전 소모 칼로리 (kcal)
    ///   - newCalories: 새로운 소모 칼로리 (kcal)
    ///   - oldDuration: 이전 운동 시간 (분)
    ///   - newDuration: 새로운 운동 시간 (분)
    /// - Throws: 업데이트 실패 시 에러
    func updateExercise(
        date: Date,
        userId: UUID,
        oldCalories: Int32,
        newCalories: Int32,
        oldDuration: Int32,
        newDuration: Int32
    ) async throws {
        try await localDataSource.updateExercise(
            date: date,
            userId: userId,
            oldCalories: oldCalories,
            newCalories: newCalories,
            oldDuration: oldDuration,
            newDuration: newDuration
        )
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
/// class DailyLogRepositoryImpl {
///     let localDataSource: DailyLogLocalDataSource
/// }
///
/// // 향후: 네트워크 동기화 추가
/// class DailyLogRepositoryImpl {
///     let localDataSource: DailyLogLocalDataSource
///     let remoteDataSource: DailyLogRemoteDataSource
///
///     func addExercise(...) async throws {
///         // 1. 로컬에 반영
///         try await localDataSource.addExercise(...)
///         // 2. 네트워크에 동기화 (백그라운드)
///         Task { try? await remoteDataSource.sync(...) }
///     }
/// }
/// ```
