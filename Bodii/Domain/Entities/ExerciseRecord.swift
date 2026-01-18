//
//  ExerciseRecord.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-11.
//

// 📚 학습 포인트: MET-based Calorie Calculation
// ExerciseRecord는 MET 값(대사당량)을 사용하여 운동 칼로리 소모량을 자동 계산
// 💡 Java 비교: JPA에서 @PrePersist로 계산하는 것과 유사하지만 Swift는 factory method 사용

import Foundation

// MARK: - ExerciseRecord

/// 운동 기록 도메인 엔티티
/// - 사용자의 운동 내용과 칼로리 소모량을 기록
/// - MET 값을 기반으로 칼로리 소모량 자동 계산
/// - HealthKit 연동 지원 (자동 기록)
///
/// ## 주요 기능
/// - 운동 유형별, 강도별 칼로리 소모량 자동 계산
/// - DailyLog에서 일일 운동 합계 계산에 사용
/// - HealthKit 데이터 연동 지원
/// - 운동 메모 기능 제공
///
/// ## 칼로리 계산 공식
/// ```
/// MET = ExerciseType의 metValue(for: intensity)
/// 시간(hours) = duration(분) / 60
/// 칼로리 소모량(kcal) = MET × 체중(kg) × 시간(hours)
/// ```
///
/// ## 데이터 관계
/// - DailyLog (N:1): 같은 날짜의 ExerciseRecord들이 DailyLog에 집계됨
/// - HealthKit: fromHealthKit이 true면 HealthKit에서 자동 기록된 데이터
///
/// ## 사용 예시
/// ```swift
/// // 1. 수동 운동 기록 (사용자 입력)
/// let record = ExerciseRecord.create(
///     userId: userId,
///     date: Date(),
///     exerciseType: .running,
///     duration: 30,
///     intensity: .medium,
///     weight: 70.0,
///     note: "아침 조깅"
/// )
/// print(record.caloriesBurned) // 280 kcal (자동 계산)
///
/// // 2. HealthKit 연동 기록
/// let healthKitRecord = ExerciseRecord.createFromHealthKit(
///     userId: userId,
///     date: Date(),
///     exerciseType: .walking,
///     duration: 45,
///     intensity: .low,
///     weight: 70.0,
///     healthKitId: "HK-12345"
/// )
/// print(healthKitRecord.fromHealthKit) // true
/// ```
struct ExerciseRecord: Identifiable, Codable, Equatable {

    // MARK: - Properties

    // MARK: Identifier

    /// 운동 기록 고유 식별자
    /// - UUID 타입으로 전역 고유성 보장
    let id: UUID

    /// 사용자 고유 식별자
    /// - User 엔티티와의 외래 키 관계
    let userId: UUID

    // MARK: Record Data

    /// 운동 날짜
    /// - 02:00 sleep boundary 로직 적용 (DateUtils.getLogicalDate)
    /// - DailyLog 집계 시 이 날짜 기준으로 그룹화
    let date: Date

    /// 운동 유형
    /// - .walking, .running, .cycling, .swimming, .weight, .crossfit, .yoga, .other
    /// - 각 운동 유형별로 다른 MET 값 적용
    let exerciseType: ExerciseType

    /// 운동 시간 (분)
    /// - 허용 범위: 1-480분 (ValidationService.validateExerciseDuration으로 검증)
    /// - 칼로리 소모량 계산에 사용
    let duration: Int

    /// 운동 강도
    /// - .low (낮음), .medium (보통), .high (높음)
    /// - ExerciseType의 MET 값 결정에 사용
    let intensity: Intensity

    /// 소모 칼로리 (kcal)
    /// - MET × 체중 × (운동시간/60) 공식으로 자동 계산
    /// - DailyLog의 totalCaloriesOut 집계에 사용
    let caloriesBurned: Int

    /// 운동 메모 (선택 사항)
    /// - 사용자가 입력한 운동 관련 메모
    /// - 예: "아침 조깅", "체육관 PT 세션"
    var note: String?

    // MARK: HealthKit Integration

    /// HealthKit 연동 여부
    /// - true: HealthKit에서 자동으로 기록된 운동
    /// - false: 사용자가 수동으로 입력한 운동
    let fromHealthKit: Bool

    /// HealthKit 운동 고유 식별자
    /// - HealthKit에서 가져온 운동 데이터의 원본 ID
    /// - 중복 방지 및 동기화에 사용
    let healthKitId: String?

    // MARK: Timestamps

    /// 생성 시각
    /// - 운동 기록이 DB에 추가된 시각
    let createdAt: Date

    /// 수정 시각
    /// - 운동 기록이 마지막으로 수정된 시각
    var updatedAt: Date

    // MARK: - Factory Methods

    /// 운동 기록 생성 (수동 입력)
    /// - Parameters:
    ///   - userId: 사용자 고유 식별자
    ///   - date: 운동 날짜
    ///   - exerciseType: 운동 유형
    ///   - duration: 운동 시간 (분)
    ///   - intensity: 운동 강도
    ///   - weight: 사용자 체중 (kg) - 칼로리 계산에 사용
    ///   - note: 운동 메모 (선택 사항)
    /// - Returns: 칼로리가 자동 계산된 ExerciseRecord
    ///
    /// ## 사용 예시
    /// ```swift
    /// let record = ExerciseRecord.create(
    ///     userId: userId,
    ///     date: Date(),
    ///     exerciseType: .running,
    ///     duration: 30,
    ///     intensity: .medium,
    ///     weight: 70.0,
    ///     note: "아침 조깅"
    /// )
    /// print(record.caloriesBurned) // 280 kcal (자동 계산)
    /// print(record.fromHealthKit) // false
    /// ```
    static func create(
        userId: UUID,
        date: Date,
        exerciseType: ExerciseType,
        duration: Int,
        intensity: Intensity,
        weight: Decimal,
        note: String? = nil
    ) -> ExerciseRecord {
        let caloriesBurned = calculateCaloriesBurned(
            exerciseType: exerciseType,
            intensity: intensity,
            duration: duration,
            weight: weight
        )

        let now = Date()
        return ExerciseRecord(
            id: UUID(),
            userId: userId,
            date: date,
            exerciseType: exerciseType,
            duration: duration,
            intensity: intensity,
            caloriesBurned: caloriesBurned,
            note: note,
            fromHealthKit: false,
            healthKitId: nil,
            createdAt: now,
            updatedAt: now
        )
    }

    /// HealthKit 연동 운동 기록 생성
    /// - Parameters:
    ///   - userId: 사용자 고유 식별자
    ///   - date: 운동 날짜
    ///   - exerciseType: 운동 유형
    ///   - duration: 운동 시간 (분)
    ///   - intensity: 운동 강도
    ///   - weight: 사용자 체중 (kg) - 칼로리 계산에 사용
    ///   - healthKitId: HealthKit 운동 고유 식별자
    ///   - note: 운동 메모 (선택 사항)
    /// - Returns: 칼로리가 자동 계산된 ExerciseRecord (HealthKit 연동)
    ///
    /// ## 사용 예시
    /// ```swift
    /// let record = ExerciseRecord.createFromHealthKit(
    ///     userId: userId,
    ///     date: Date(),
    ///     exerciseType: .walking,
    ///     duration: 45,
    ///     intensity: .low,
    ///     weight: 70.0,
    ///     healthKitId: "HK-12345"
    /// )
    /// print(record.fromHealthKit) // true
    /// print(record.healthKitId) // "HK-12345"
    /// ```
    static func createFromHealthKit(
        userId: UUID,
        date: Date,
        exerciseType: ExerciseType,
        duration: Int,
        intensity: Intensity,
        weight: Decimal,
        healthKitId: String,
        note: String? = nil
    ) -> ExerciseRecord {
        let caloriesBurned = calculateCaloriesBurned(
            exerciseType: exerciseType,
            intensity: intensity,
            duration: duration,
            weight: weight
        )

        let now = Date()
        return ExerciseRecord(
            id: UUID(),
            userId: userId,
            date: date,
            exerciseType: exerciseType,
            duration: duration,
            intensity: intensity,
            caloriesBurned: caloriesBurned,
            note: note,
            fromHealthKit: true,
            healthKitId: healthKitId,
            createdAt: now,
            updatedAt: now
        )
    }

    // MARK: - Helper Methods

    /// 칼로리 소모량 계산
    /// - Parameters:
    ///   - exerciseType: 운동 유형
    ///   - intensity: 운동 강도
    ///   - duration: 운동 시간 (분)
    ///   - weight: 체중 (kg)
    /// - Returns: 계산된 칼로리 소모량 (kcal)
    ///
    /// ## 계산 공식
    /// ```
    /// 1. MET 값 조회: exerciseType.metValue(for: intensity.rawValue)
    /// 2. 운동 시간 변환: duration(분) / 60 = hours
    /// 3. 칼로리 계산: MET × weight(kg) × hours
    /// ```
    ///
    /// ## 예시
    /// ```swift
    /// // 체중 70kg, 달리기(보통 강도), 30분
    /// let calories = calculateCaloriesBurned(
    ///     exerciseType: .running,
    ///     intensity: .medium,
    ///     duration: 30,
    ///     weight: 70.0
    /// )
    /// // 계산:
    /// // MET = 8.0 (running, medium intensity)
    /// // hours = 30 / 60 = 0.5
    /// // calories = 8.0 × 70 × 0.5 = 280 kcal
    /// ```
    ///
    /// ## MET (Metabolic Equivalent of Task)
    /// - 운동의 강도를 나타내는 단위
    /// - 1 MET = 안정 시 대사량 (약 1 kcal/kg/hour)
    /// - 예: 걷기 3.5-5.0 MET, 달리기 7.0-10.0 MET
    static func calculateCaloriesBurned(
        exerciseType: ExerciseType,
        intensity: Intensity,
        duration: Int,
        weight: Decimal
    ) -> Int {
        // 1. MET 값 조회
        let met = exerciseType.metValue(for: intensity.rawValue)

        // 2. 시간 단위 변환 (분 → 시간)
        let hours = Double(duration) / 60.0

        // 3. 칼로리 계산: MET × 체중(kg) × 시간(hours)
        let calories = met * weight.doubleValue * hours

        // 4. 정수로 반올림
        return Int(calories.rounded())
    }

    /// 운동 시간 업데이트
    /// - Parameter newDuration: 새로운 운동 시간 (분)
    /// - Parameter weight: 사용자 체중 (kg) - 칼로리 재계산에 사용
    /// - Returns: 칼로리가 재계산된 ExerciseRecord
    ///
    /// ## 사용 시나리오
    /// 사용자가 운동 시간을 수정할 때 칼로리를 자동으로 재계산
    ///
    /// ## 예시
    /// ```swift
    /// let original = ExerciseRecord.create(..., duration: 30, ...)
    /// // original.caloriesBurned = 280 kcal
    ///
    /// let updated = original.updatingDuration(45, weight: 70.0)
    /// // updated.duration = 45
    /// // updated.caloriesBurned = 420 kcal (재계산)
    /// ```
    func updatingDuration(_ newDuration: Int, weight: Decimal) -> ExerciseRecord {
        let newCalories = Self.calculateCaloriesBurned(
            exerciseType: exerciseType,
            intensity: intensity,
            duration: newDuration,
            weight: weight
        )

        return ExerciseRecord(
            id: id,
            userId: userId,
            date: date,
            exerciseType: exerciseType,
            duration: newDuration,
            intensity: intensity,
            caloriesBurned: newCalories,
            note: note,
            fromHealthKit: fromHealthKit,
            healthKitId: healthKitId,
            createdAt: createdAt,
            updatedAt: Date()
        )
    }

    /// 운동 강도 업데이트
    /// - Parameter newIntensity: 새로운 운동 강도
    /// - Parameter weight: 사용자 체중 (kg) - 칼로리 재계산에 사용
    /// - Returns: 칼로리가 재계산된 ExerciseRecord
    ///
    /// ## 사용 시나리오
    /// 사용자가 운동 강도를 수정할 때 칼로리를 자동으로 재계산
    ///
    /// ## 예시
    /// ```swift
    /// let original = ExerciseRecord.create(..., intensity: .medium, ...)
    /// // original.caloriesBurned = 280 kcal (MET 8.0)
    ///
    /// let updated = original.updatingIntensity(.high, weight: 70.0)
    /// // updated.intensity = .high
    /// // updated.caloriesBurned = 350 kcal (MET 10.0, 재계산)
    /// ```
    func updatingIntensity(_ newIntensity: Intensity, weight: Decimal) -> ExerciseRecord {
        let newCalories = Self.calculateCaloriesBurned(
            exerciseType: exerciseType,
            intensity: newIntensity,
            duration: duration,
            weight: weight
        )

        return ExerciseRecord(
            id: id,
            userId: userId,
            date: date,
            exerciseType: exerciseType,
            duration: duration,
            intensity: newIntensity,
            caloriesBurned: newCalories,
            note: note,
            fromHealthKit: fromHealthKit,
            healthKitId: healthKitId,
            createdAt: createdAt,
            updatedAt: Date()
        )
    }

    /// 운동 메모 업데이트
    /// - Parameter newNote: 새로운 운동 메모
    /// - Returns: 메모가 업데이트된 ExerciseRecord
    ///
    /// ## 예시
    /// ```swift
    /// let original = ExerciseRecord.create(..., note: "아침 조깅")
    /// let updated = original.updatingNote("아침 조깅 - 날씨 좋음")
    /// ```
    func updatingNote(_ newNote: String?) -> ExerciseRecord {
        ExerciseRecord(
            id: id,
            userId: userId,
            date: date,
            exerciseType: exerciseType,
            duration: duration,
            intensity: intensity,
            caloriesBurned: caloriesBurned,
            note: newNote,
            fromHealthKit: fromHealthKit,
            healthKitId: healthKitId,
            createdAt: createdAt,
            updatedAt: Date()
        )
    }
}

// MARK: - ExerciseRecord + CustomStringConvertible

extension ExerciseRecord: CustomStringConvertible {
    /// 디버깅용 문자열 표현
    var description: String {
        let noteText = note.map { " (\($0))" } ?? ""
        let healthKitText = fromHealthKit ? " [HealthKit]" : ""

        return """
        ExerciseRecord(
          id: \(id.uuidString.prefix(8))...,
          userId: \(userId.uuidString.prefix(8))...,
          date: \(date.formatted(style: .short)),
          exerciseType: \(exerciseType.displayName),
          duration: \(duration)분,
          intensity: \(intensity.displayName),
          caloriesBurned: \(caloriesBurned) kcal,
          note: \(noteText),
          fromHealthKit: \(fromHealthKit)\(healthKitText),
          createdAt: \(createdAt.formatted(style: .dateTime))
        )
        """
    }
}
