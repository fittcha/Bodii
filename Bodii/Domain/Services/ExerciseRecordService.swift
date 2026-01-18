//
//  ExerciseRecordService.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-13.
//

import Foundation

/// 운동 기록 서비스
///
/// 운동 기록의 비즈니스 로직을 처리합니다.
final class ExerciseRecordService {

    // MARK: - Properties

    private let exerciseRecordRepository: ExerciseRecordRepository
    private let userRepository: UserRepository

    // MARK: - Initialization

    init(
        exerciseRecordRepository: ExerciseRecordRepository,
        userRepository: UserRepository
    ) {
        self.exerciseRecordRepository = exerciseRecordRepository
        self.userRepository = userRepository
    }

    // MARK: - Public Methods

    /// 운동 추가
    func addExercise(
        userId: UUID,
        date: Date,
        exerciseType: ExerciseType,
        duration: Int32,
        intensity: Intensity
    ) async throws -> UUID {
        // 1. Duration 유효성 검증
        guard duration >= 1 else {
            throw ExerciseServiceError.invalidInput("Duration must be at least 1 minute")
        }

        // 2. 사용자 현재 체중 조회
        guard let user = try userRepository.fetchCurrentUser() else {
            throw ExerciseServiceError.userNotFound("Current user not found")
        }

        guard let weight = user.currentWeight else {
            throw ExerciseServiceError.invalidInput("User weight is not set. Please update weight in profile.")
        }

        // 3. 칼로리 계산
        let caloriesBurned = ExerciseCalcService.calculateCalories(
            exerciseType: exerciseType,
            duration: duration,
            intensity: intensity,
            weight: weight as Decimal
        )

        // 4. ExerciseRecord 생성
        let exerciseRecord = ExerciseRecord(
            id: UUID(),
            userId: userId,
            date: date,
            exerciseType: exerciseType,
            duration: duration,
            intensity: intensity,
            caloriesBurned: caloriesBurned,
            createdAt: Date()
        )

        // 5. ExerciseRecord 저장
        let savedRecord = try await exerciseRecordRepository.create(exerciseRecord)

        return savedRecord.id
    }

    /// 운동 수정
    func updateExercise(
        id: UUID,
        userId: UUID,
        date: Date,
        exerciseType: ExerciseType,
        duration: Int32,
        intensity: Intensity
    ) async throws {
        // 1. Duration 유효성 검증
        guard duration >= 1 else {
            throw ExerciseServiceError.invalidInput("Duration must be at least 1 minute")
        }

        // 2. 기존 ExerciseRecord 조회
        guard let oldExercise = try await exerciseRecordRepository.fetchById(id, userId: userId) else {
            throw ExerciseServiceError.recordNotFound("ExerciseRecord with id \(id) not found")
        }

        // 3. 사용자 현재 체중 조회
        guard let user = try userRepository.fetchCurrentUser() else {
            throw ExerciseServiceError.userNotFound("Current user not found")
        }

        guard let weight = user.currentWeight else {
            throw ExerciseServiceError.invalidInput("User weight is not set. Please update weight in profile.")
        }

        // 4. 새로운 칼로리 계산
        let newCaloriesBurned = ExerciseCalcService.calculateCalories(
            exerciseType: exerciseType,
            duration: duration,
            intensity: intensity,
            weight: weight as Decimal
        )

        // 5. ExerciseRecord 업데이트
        let updatedRecord = ExerciseRecord(
            id: oldExercise.id,
            userId: oldExercise.userId,
            date: date,
            exerciseType: exerciseType,
            duration: duration,
            intensity: intensity,
            caloriesBurned: newCaloriesBurned,
            createdAt: oldExercise.createdAt
        )

        _ = try await exerciseRecordRepository.update(updatedRecord)
    }

    /// 운동 삭제
    func deleteExercise(id: UUID, userId: UUID) async throws {
        // 1. ExerciseRecord 조회 (존재 확인)
        guard try await exerciseRecordRepository.fetchById(id, userId: userId) != nil else {
            throw ExerciseServiceError.recordNotFound("ExerciseRecord with id \(id) not found")
        }

        // 2. ExerciseRecord 삭제
        try await exerciseRecordRepository.delete(id: id, userId: userId)
    }

    /// 특정 날짜의 운동 기록 목록 조회
    func fetchExercises(for userId: UUID, on date: Date) async throws -> [ExerciseRecord] {
        return try await exerciseRecordRepository.fetchByDate(date, userId: userId)
    }

    /// 특정 운동 기록 조회
    func fetchExercise(by id: UUID, userId: UUID) async throws -> ExerciseRecord? {
        return try await exerciseRecordRepository.fetchById(id, userId: userId)
    }
}

// MARK: - Exercise Service Errors

/// 운동 서비스 레이어에서 발생하는 에러
enum ExerciseServiceError: Error, LocalizedError {
    case invalidInput(String)
    case recordNotFound(String)
    case userNotFound(String)
    case saveFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidInput(let message):
            return "Invalid input: \(message)"
        case .recordNotFound(let message):
            return "Record not found: \(message)"
        case .userNotFound(let message):
            return "User not found: \(message)"
        case .saveFailed(let message):
            return "Save failed: \(message)"
        }
    }
}
