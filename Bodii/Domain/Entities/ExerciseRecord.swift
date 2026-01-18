//
//  ExerciseRecord.swift
//  Bodii
//
//  Created by Auto-Claude on 2024-01-12.
//

import Foundation

/// 운동 기록 도메인 엔티티
///
/// 사용자의 운동 활동을 기록하고 소모 칼로리를 추적합니다.
///
/// - Note: caloriesBurned는 MET 기반 공식으로 계산됩니다.
///         소모 칼로리 = MET × 체중(kg) × 시간(hour)
///         강도에 따라 MET 값이 보정됩니다 (저강도: ×0.8, 중강도: ×1.0, 고강도: ×1.2)
///
/// - Note: 운동 기록 입력 시 DailyLog의 totalCaloriesOut, exerciseMinutes, exerciseCount가
///         자동으로 업데이트됩니다.
///
/// - Example:
/// ```swift
/// let exerciseRecord = ExerciseRecord(
///     id: UUID(),
///     userId: user.id,
///     date: Date(),
///     exerciseType: .running,
///     duration: 30,
///     intensity: .high,
///     caloriesBurned: 350,
///     createdAt: Date()
/// )
/// ```
struct ExerciseRecord {
    // MARK: - Primary Key

    /// 고유 식별자
    let id: UUID

    // MARK: - Foreign Key

    /// User 참조
    let userId: UUID

    // MARK: - Exercise Data

    /// 운동일
    var date: Date

    /// 운동 종류 (0: 걷기, 1: 러닝, 2: 자전거, 3: 수영, 4: 웨이트, 5: 크로스핏, 6: 요가, 7: 기타)
    var exerciseType: ExerciseType

    /// 운동 시간 (분)
    var duration: Int32

    /// 강도 (0: 저강도, 1: 중강도, 2: 고강도)
    ///
    /// MET 보정 계수:
    /// - 저강도: 기본 MET × 0.8
    /// - 중강도: 기본 MET × 1.0
    /// - 고강도: 기본 MET × 1.2
    var intensity: Intensity

    /// 소모 칼로리 (kcal)
    ///
    /// MET 기반 공식으로 계산: MET × 체중(kg) × 시간(hour)
    var caloriesBurned: Int32

    // MARK: - Metadata

    /// 생성일시
    let createdAt: Date
}

// MARK: - Identifiable

extension ExerciseRecord: Identifiable {}

// MARK: - Equatable

extension ExerciseRecord: Equatable {
    static func == (lhs: ExerciseRecord, rhs: ExerciseRecord) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Hashable

extension ExerciseRecord: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
