//
//  ExerciseRecordRepository.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-13.
//

import Foundation

/// ExerciseRecord 저장소 프로토콜
///
/// Clean Architecture의 Repository 패턴을 따르며,
/// 데이터 소스(Core Data, 네트워크 등)와 도메인 계층 사이의 추상화를 제공합니다.
///
/// ## 책임
/// - ExerciseRecord의 CRUD 작업
/// - 날짜 기반 조회 및 필터링
/// - 데이터 영속성 관리
///
/// ## 구현 참고사항
/// - 모든 메서드는 async/await 패턴을 사용합니다
/// - 에러 발생 시 적절한 예외를 throw해야 합니다
/// - 트랜잭션 처리는 구현체에서 담당합니다
///
/// - Example:
/// ```swift
/// let repository: ExerciseRecordRepository = ExerciseRecordRepositoryImpl()
///
/// // 운동 기록 생성
/// let record = ExerciseRecord(
///     id: UUID(),
///     userId: userId,
///     date: Date(),
///     exerciseType: .running,
///     duration: 30,
///     intensity: .high,
///     caloriesBurned: 350,
///     createdAt: Date()
/// )
/// try await repository.create(record)
///
/// // 오늘 운동 기록 조회
/// let todayRecords = try await repository.fetchByDate(Date(), userId: userId)
/// ```
protocol ExerciseRecordRepository {

    // MARK: - Create

    /// 새로운 운동 기록을 생성합니다.
    ///
    /// - Parameter record: 생성할 운동 기록
    /// - Throws: 데이터 저장 실패 시 에러
    /// - Returns: 생성된 운동 기록 (저장소에서 할당된 ID 포함)
    func create(_ record: ExerciseRecord) async throws -> ExerciseRecord

    // MARK: - Read

    /// ID로 운동 기록을 조회합니다.
    ///
    /// - Parameters:
    ///   - id: 운동 기록 고유 식별자
    ///   - userId: 사용자 ID (권한 확인용)
    /// - Throws: 조회 실패 시 에러
    /// - Returns: 조회된 운동 기록, 없으면 nil
    func fetchById(_ id: UUID, userId: UUID) async throws -> ExerciseRecord?

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
    func fetchByDate(_ date: Date, userId: UUID) async throws -> [ExerciseRecord]

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
    func fetchByDateRange(startDate: Date, endDate: Date, userId: UUID) async throws -> [ExerciseRecord]

    /// 사용자의 모든 운동 기록을 조회합니다.
    ///
    /// 결과는 날짜순(최신순)으로 정렬됩니다.
    ///
    /// - Parameter userId: 사용자 ID
    /// - Throws: 조회 실패 시 에러
    /// - Returns: 운동 기록 배열 (없으면 빈 배열)
    func fetchAll(userId: UUID) async throws -> [ExerciseRecord]

    // MARK: - Update

    /// 기존 운동 기록을 수정합니다.
    ///
    /// ID가 일치하는 기록을 찾아 제공된 데이터로 업데이트합니다.
    /// userId가 일치하지 않으면 권한 에러를 throw해야 합니다.
    ///
    /// - Parameter record: 수정할 운동 기록 (ID 필수)
    /// - Throws: 업데이트 실패 또는 권한 없음 시 에러
    /// - Returns: 수정된 운동 기록
    func update(_ record: ExerciseRecord) async throws -> ExerciseRecord

    // MARK: - Delete

    /// 운동 기록을 삭제합니다.
    ///
    /// userId가 일치하지 않으면 권한 에러를 throw해야 합니다.
    ///
    /// - Parameters:
    ///   - id: 삭제할 운동 기록 ID
    ///   - userId: 사용자 ID (권한 확인용)
    /// - Throws: 삭제 실패 또는 권한 없음 시 에러
    func delete(id: UUID, userId: UUID) async throws

    // MARK: - Utility

    /// 특정 날짜의 운동 기록 개수를 반환합니다.
    ///
    /// - Parameters:
    ///   - date: 조회할 날짜
    ///   - userId: 사용자 ID
    /// - Throws: 조회 실패 시 에러
    /// - Returns: 운동 기록 개수
    func count(forDate date: Date, userId: UUID) async throws -> Int

    /// 특정 날짜의 총 운동 시간(분)을 반환합니다.
    ///
    /// - Parameters:
    ///   - date: 조회할 날짜
    ///   - userId: 사용자 ID
    /// - Throws: 조회 실패 시 에러
    /// - Returns: 총 운동 시간 (분)
    func totalDuration(forDate date: Date, userId: UUID) async throws -> Int32

    /// 특정 날짜의 총 소모 칼로리를 반환합니다.
    ///
    /// - Parameters:
    ///   - date: 조회할 날짜
    ///   - userId: 사용자 ID
    /// - Throws: 조회 실패 시 에러
    /// - Returns: 총 소모 칼로리 (kcal)
    func totalCaloriesBurned(forDate date: Date, userId: UUID) async throws -> Int32
}
