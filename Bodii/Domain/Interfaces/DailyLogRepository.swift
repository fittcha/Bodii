//
//  DailyLogRepository.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-13.
//

import Foundation

/// DailyLog 저장소 프로토콜
///
/// Clean Architecture의 Repository 패턴을 따르며,
/// 데이터 소스(Core Data, 네트워크 등)와 도메인 계층 사이의 추상화를 제공합니다.
///
/// ## 책임
/// - DailyLog의 CRUD 작업
/// - 날짜 기반 조회
/// - 운동 데이터 업데이트
/// - 데이터 영속성 관리
///
/// ## 구현 참고사항
/// - 모든 메서드는 async/await 패턴을 사용합니다
/// - 에러 발생 시 적절한 예외를 throw해야 합니다
/// - 트랜잭션 처리는 구현체에서 담당합니다
///
/// - Example:
/// ```swift
/// let repository: DailyLogRepository = DailyLogRepositoryImpl()
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
protocol DailyLogRepository {

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
    func getOrCreate(for date: Date, userId: UUID, bmr: Int32, tdee: Int32) async throws -> DailyLog

    /// 특정 날짜의 DailyLog를 조회합니다.
    ///
    /// - Parameters:
    ///   - date: 조회할 날짜
    ///   - userId: 사용자 ID
    /// - Throws: 조회 실패 시 에러
    /// - Returns: 조회된 DailyLog, 없으면 nil
    func fetch(for date: Date, userId: UUID) async throws -> DailyLog?

    // MARK: - Update

    /// DailyLog를 업데이트합니다.
    ///
    /// - Parameter dailyLog: 업데이트할 DailyLog
    /// - Throws: 업데이트 실패 시 에러
    /// - Returns: 업데이트된 DailyLog
    func update(_ dailyLog: DailyLog) async throws -> DailyLog

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
    func addExercise(date: Date, userId: UUID, calories: Int32, duration: Int32) async throws

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
    func removeExercise(date: Date, userId: UUID, calories: Int32, duration: Int32) async throws

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
    ) async throws
}
