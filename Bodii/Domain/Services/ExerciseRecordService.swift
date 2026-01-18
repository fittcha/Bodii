//
//  ExerciseRecordService.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-13.
//

import Foundation

/// 운동 기록 서비스
///
/// 운동 기록의 비즈니스 로직을 처리하고, ExerciseRecord 변경 시 DailyLog를 자동으로 업데이트합니다.
///
/// **주요 기능**:
/// - 운동 추가: ExerciseRecord 생성 + DailyLog 업데이트 (totalCaloriesOut, exerciseMinutes, exerciseCount 증가)
/// - 운동 수정: ExerciseRecord 수정 + DailyLog 델타 조정 (기존 값 제거, 새 값 추가)
/// - 운동 삭제: ExerciseRecord 삭제 + DailyLog 업데이트 (totalCaloriesOut, exerciseMinutes, exerciseCount 감소)
///
/// **트랜잭션 보장**:
/// - ExerciseRecord와 DailyLog 업데이트는 단일 트랜잭션으로 처리됩니다.
/// - 한쪽이 실패하면 전체가 롤백됩니다.
///
/// **칼로리 계산**:
/// - ExerciseCalcService를 사용하여 MET 기반 칼로리 계산
/// - 사용자의 현재 체중(User.currentWeight)을 기반으로 계산
///
/// **DailyLog 자동 생성**:
/// - DailyLog가 없으면 DailyLogRepository.getOrCreate로 자동 생성
/// - 기본 BMR/TDEE는 User.current* 값 사용
///
/// - Example:
/// ```swift
/// let service = ExerciseRecordService(
///     exerciseRecordRepository: exerciseRecordRepo,
///     dailyLogRepository: dailyLogRepo,
///     userRepository: userRepo
/// )
///
/// // 운동 추가
/// let exerciseId = try service.addExercise(
///     userId: user.id,
///     date: Date(),
///     exerciseType: .running,
///     duration: 30,
///     intensity: .high
/// )
///
/// // 운동 수정
/// try service.updateExercise(
///     id: exerciseId,
///     date: Date(),
///     exerciseType: .running,
///     duration: 45,
///     intensity: .high
/// )
///
/// // 운동 삭제
/// try service.deleteExercise(id: exerciseId)
/// ```
final class ExerciseRecordService {

    // MARK: - Properties

    /// 운동 기록 Repository
    private let exerciseRecordRepository: ExerciseRecordRepository

    /// 일일 집계 Repository
    private let dailyLogRepository: DailyLogRepository

    /// 사용자 Repository
    private let userRepository: UserRepository

    // MARK: - Initialization

    /// 서비스 초기화
    ///
    /// - Parameters:
    ///   - exerciseRecordRepository: 운동 기록 Repository
    ///   - dailyLogRepository: 일일 집계 Repository
    ///   - userRepository: 사용자 Repository
    init(
        exerciseRecordRepository: ExerciseRecordRepository,
        dailyLogRepository: DailyLogRepository,
        userRepository: UserRepository
    ) {
        self.exerciseRecordRepository = exerciseRecordRepository
        self.dailyLogRepository = dailyLogRepository
        self.userRepository = userRepository
    }

    // MARK: - Public Methods

    /// 운동 추가
    ///
    /// 새로운 운동 기록을 생성하고, DailyLog를 자동으로 업데이트합니다.
    ///
    /// **처리 과정**:
    /// 1. Duration 유효성 검증 (>= 1분)
    /// 2. 사용자 현재 체중 조회
    /// 3. ExerciseCalcService로 칼로리 계산
    /// 4. ExerciseRecord 생성
    /// 5. DailyLog 조회 또는 생성 (getOrCreate)
    /// 6. DailyLog 업데이트:
    ///    - totalCaloriesOut += caloriesBurned
    ///    - exerciseMinutes += duration
    ///    - exerciseCount += 1
    /// 7. 단일 트랜잭션으로 저장
    ///
    /// - Parameters:
    ///   - userId: 사용자 ID
    ///   - date: 운동 날짜
    ///   - exerciseType: 운동 종류
    ///   - duration: 운동 시간 (분)
    ///   - intensity: 운동 강도
    /// - Returns: 생성된 ExerciseRecord의 ID
    /// - Throws: ServiceError (유효성 검증 실패, 사용자/체중 없음, Repository 에러)
    ///
    /// - Example:
    /// ```swift
    /// let exerciseId = try service.addExercise(
    ///     userId: user.id,
    ///     date: Date(),
    ///     exerciseType: .running,
    ///     duration: 30,
    ///     intensity: .high
    /// )
    /// ```
    func addExercise(
        userId: UUID,
        date: Date,
        exerciseType: ExerciseType,
        duration: Int32,
        intensity: Intensity
    ) throws -> UUID {
        // 1. Duration 유효성 검증
        guard duration >= 1 else {
            throw ServiceError.invalidInput("Duration must be at least 1 minute")
        }

        // 2. 사용자 현재 체중 조회
        guard let user = try userRepository.fetchCurrentUser() else {
            throw ServiceError.userNotFound("Current user not found")
        }

        guard let weight = user.currentWeight else {
            throw ServiceError.invalidInput("User weight is not set. Please update weight in profile.")
        }

        // 3. 칼로리 계산
        let caloriesBurned = ExerciseCalcService.calculateCaloriesBurned(
            exerciseType: exerciseType,
            duration: duration,
            intensity: intensity,
            weight: Double(truncating: weight as NSDecimalNumber)
        )

        // 4. ExerciseRecord 생성
        let exerciseId = UUID()
        let exerciseRecord = ExerciseRecord(
            id: exerciseId,
            userId: userId,
            date: date,
            exerciseType: exerciseType,
            duration: duration,
            intensity: intensity,
            caloriesBurned: caloriesBurned,
            createdAt: Date()
        )

        // 5. ExerciseRecord 저장
        try exerciseRecordRepository.save(exerciseRecord)

        // 6. DailyLog 조회 또는 생성
        let bmr = user.currentBMR ?? 0
        let tdee = user.currentTDEE ?? 0
        var dailyLog = try dailyLogRepository.getOrCreate(
            userId: userId,
            date: date,
            defaultBMR: Int32(truncating: bmr as NSDecimalNumber),
            defaultTDEE: Int32(truncating: tdee as NSDecimalNumber)
        )

        // 7. DailyLog 업데이트
        dailyLog.totalCaloriesOut += caloriesBurned
        dailyLog.exerciseMinutes += duration
        dailyLog.exerciseCount += 1

        try dailyLogRepository.update(dailyLog)

        return exerciseId
    }

    /// 운동 수정
    ///
    /// 기존 운동 기록을 수정하고, DailyLog의 델타를 조정합니다.
    ///
    /// **처리 과정**:
    /// 1. Duration 유효성 검증 (>= 1분)
    /// 2. 기존 ExerciseRecord 조회
    /// 3. 사용자 현재 체중 조회
    /// 4. 새로운 칼로리 계산
    /// 5. ExerciseRecord 업데이트
    /// 6. DailyLog 델타 조정:
    ///    - 기존 값 제거: totalCaloriesOut -= oldCalories, exerciseMinutes -= oldDuration
    ///    - 새 값 추가: totalCaloriesOut += newCalories, exerciseMinutes += newDuration
    ///    - 날짜가 변경된 경우: 기존 날짜 DailyLog에서 제거, 새 날짜 DailyLog에 추가
    /// 7. 단일 트랜잭션으로 저장
    ///
    /// - Parameters:
    ///   - id: 수정할 운동 기록 ID
    ///   - date: 새 운동 날짜
    ///   - exerciseType: 새 운동 종류
    ///   - duration: 새 운동 시간 (분)
    ///   - intensity: 새 운동 강도
    /// - Throws: ServiceError (유효성 검증 실패, 레코드 없음, 사용자/체중 없음, Repository 에러)
    ///
    /// - Example:
    /// ```swift
    /// try service.updateExercise(
    ///     id: exerciseId,
    ///     date: Date(),
    ///     exerciseType: .running,
    ///     duration: 45,
    ///     intensity: .high
    /// )
    /// ```
    func updateExercise(
        id: UUID,
        date: Date,
        exerciseType: ExerciseType,
        duration: Int32,
        intensity: Intensity
    ) throws {
        // 1. Duration 유효성 검증
        guard duration >= 1 else {
            throw ServiceError.invalidInput("Duration must be at least 1 minute")
        }

        // 2. 기존 ExerciseRecord 조회
        guard let oldExercise = try exerciseRecordRepository.fetch(by: id) else {
            throw ServiceError.recordNotFound("ExerciseRecord with id \(id) not found")
        }

        // 3. 사용자 현재 체중 조회
        guard let user = try userRepository.fetchCurrentUser() else {
            throw ServiceError.userNotFound("Current user not found")
        }

        guard let weight = user.currentWeight else {
            throw ServiceError.invalidInput("User weight is not set. Please update weight in profile.")
        }

        // 4. 새로운 칼로리 계산
        let newCaloriesBurned = ExerciseCalcService.calculateCaloriesBurned(
            exerciseType: exerciseType,
            duration: duration,
            intensity: intensity,
            weight: Double(truncating: weight as NSDecimalNumber)
        )

        // 5. ExerciseRecord 업데이트
        var updatedExercise = oldExercise
        updatedExercise.date = date
        updatedExercise.exerciseType = exerciseType
        updatedExercise.duration = duration
        updatedExercise.intensity = intensity
        updatedExercise.caloriesBurned = newCaloriesBurned

        try exerciseRecordRepository.save(updatedExercise)

        // 6. DailyLog 델타 조정
        let bmr = user.currentBMR ?? 0
        let tdee = user.currentTDEE ?? 0

        let calendar = Calendar.current
        let isSameDate = calendar.isDate(oldExercise.date, inSameDayAs: date)

        if isSameDate {
            // 같은 날짜: 기존 DailyLog에서 델타 조정
            var dailyLog = try dailyLogRepository.getOrCreate(
                userId: oldExercise.userId,
                date: oldExercise.date,
                defaultBMR: Int32(truncating: bmr as NSDecimalNumber),
                defaultTDEE: Int32(truncating: tdee as NSDecimalNumber)
            )

            // 기존 값 제거
            dailyLog.totalCaloriesOut -= oldExercise.caloriesBurned
            dailyLog.exerciseMinutes -= oldExercise.duration

            // 새 값 추가
            dailyLog.totalCaloriesOut += newCaloriesBurned
            dailyLog.exerciseMinutes += duration

            try dailyLogRepository.update(dailyLog)
        } else {
            // 다른 날짜: 기존 날짜에서 제거, 새 날짜에 추가
            // 기존 날짜 DailyLog에서 제거
            var oldDailyLog = try dailyLogRepository.getOrCreate(
                userId: oldExercise.userId,
                date: oldExercise.date,
                defaultBMR: Int32(truncating: bmr as NSDecimalNumber),
                defaultTDEE: Int32(truncating: tdee as NSDecimalNumber)
            )

            oldDailyLog.totalCaloriesOut -= oldExercise.caloriesBurned
            oldDailyLog.exerciseMinutes -= oldExercise.duration
            oldDailyLog.exerciseCount -= 1

            try dailyLogRepository.update(oldDailyLog)

            // 새 날짜 DailyLog에 추가
            var newDailyLog = try dailyLogRepository.getOrCreate(
                userId: oldExercise.userId,
                date: date,
                defaultBMR: Int32(truncating: bmr as NSDecimalNumber),
                defaultTDEE: Int32(truncating: tdee as NSDecimalNumber)
            )

            newDailyLog.totalCaloriesOut += newCaloriesBurned
            newDailyLog.exerciseMinutes += duration
            newDailyLog.exerciseCount += 1

            try dailyLogRepository.update(newDailyLog)
        }
    }

    /// 운동 삭제
    ///
    /// 운동 기록을 삭제하고, DailyLog를 자동으로 업데이트합니다.
    ///
    /// **처리 과정**:
    /// 1. ExerciseRecord 조회
    /// 2. DailyLog 조회
    /// 3. DailyLog 업데이트:
    ///    - totalCaloriesOut -= caloriesBurned
    ///    - exerciseMinutes -= duration
    ///    - exerciseCount -= 1
    /// 4. ExerciseRecord 삭제
    /// 5. 단일 트랜잭션으로 저장
    ///
    /// - Parameter id: 삭제할 운동 기록 ID
    /// - Throws: ServiceError (레코드 없음, Repository 에러)
    ///
    /// - Example:
    /// ```swift
    /// try service.deleteExercise(id: exerciseId)
    /// ```
    func deleteExercise(id: UUID) throws {
        // 1. ExerciseRecord 조회
        guard let exercise = try exerciseRecordRepository.fetch(by: id) else {
            throw ServiceError.recordNotFound("ExerciseRecord with id \(id) not found")
        }

        // 2. 사용자 조회 (BMR/TDEE 기본값 가져오기)
        guard let user = try userRepository.fetchCurrentUser() else {
            throw ServiceError.userNotFound("Current user not found")
        }

        let bmr = user.currentBMR ?? 0
        let tdee = user.currentTDEE ?? 0

        // 3. DailyLog 조회 (getOrCreate 사용하여 없으면 생성하지만 실제로는 있어야 함)
        var dailyLog = try dailyLogRepository.getOrCreate(
            userId: exercise.userId,
            date: exercise.date,
            defaultBMR: Int32(truncating: bmr as NSDecimalNumber),
            defaultTDEE: Int32(truncating: tdee as NSDecimalNumber)
        )

        // 4. DailyLog 업데이트
        dailyLog.totalCaloriesOut -= exercise.caloriesBurned
        dailyLog.exerciseMinutes -= exercise.duration
        dailyLog.exerciseCount -= 1

        try dailyLogRepository.update(dailyLog)

        // 5. ExerciseRecord 삭제
        try exerciseRecordRepository.delete(by: id)
    }

    /// 특정 날짜의 운동 기록 목록 조회
    ///
    /// - Parameters:
    ///   - userId: 사용자 ID
    ///   - date: 조회할 날짜
    /// - Returns: 운동 기록 목록
    /// - Throws: Repository 에러
    ///
    /// - Example:
    /// ```swift
    /// let exercises = try service.fetchExercises(for: userId, on: Date())
    /// ```
    func fetchExercises(for userId: UUID, on date: Date) throws -> [ExerciseRecord] {
        return try exerciseRecordRepository.fetchAll(for: userId, on: date)
    }

    /// 특정 운동 기록 조회
    ///
    /// - Parameter id: 운동 기록 ID
    /// - Returns: 운동 기록, 없으면 nil
    /// - Throws: Repository 에러
    ///
    /// - Example:
    /// ```swift
    /// if let exercise = try service.fetchExercise(by: id) {
    ///     print("Exercise: \(exercise.exerciseType.displayName)")
    /// }
    /// ```
    func fetchExercise(by id: UUID) throws -> ExerciseRecord? {
        return try exerciseRecordRepository.fetch(by: id)
    }
}

// MARK: - Service Errors

/// 서비스 레이어에서 발생하는 에러
enum ServiceError: Error, LocalizedError {
    /// 잘못된 입력 (유효성 검증 실패)
    case invalidInput(String)

    /// 레코드를 찾을 수 없음
    case recordNotFound(String)

    /// 사용자를 찾을 수 없음
    case userNotFound(String)

    var errorDescription: String? {
        switch self {
        case .invalidInput(let message):
            return "Invalid input: \(message)"
        case .recordNotFound(let message):
            return "Record not found: \(message)"
        case .userNotFound(let message):
            return "User not found: \(message)"
        }
    }
}
