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

    // MARK: - HealthKit Integration

    /// HealthKit UUID (외부 데이터 추적용)
    ///
    /// 📚 학습 포인트: External ID Tracking
    /// - Apple Health에서 가져온 운동 기록의 경우 원본 UUID 보존
    /// - 중복 임포트 방지: 같은 healthKitId가 이미 존재하면 건너뛰기
    /// - 수동 입력 운동은 nil
    /// 💡 Java 비교: externalId 필드와 유사
    ///
    /// - Note: 양방향 동기화 시 충돌 해결에 활용
    ///   - healthKitId가 있으면 → Apple Health에서 가져온 데이터
    ///   - healthKitId가 nil이면 → 사용자가 수동 입력한 데이터
    var healthKitId: String?

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

// MARK: - HealthKit Integration

extension ExerciseRecord {
    /// HealthKit에서 가져온 데이터인지 여부
    ///
    /// 📚 학습 포인트: Computed Property
    /// - healthKitId의 존재 여부로 데이터 출처 판별
    /// - UI에서 Apple Watch 아이콘 표시 여부 결정에 활용
    /// 💡 Java 비교: isExternal() getter 메서드와 유사
    ///
    /// - Returns: HealthKit에서 가져온 데이터이면 true, 수동 입력이면 false
    ///
    /// - Example:
    /// ```swift
    /// if exerciseRecord.isFromHealthKit {
    ///     // Apple Watch 아이콘 표시
    ///     Image(systemName: "applewatch")
    /// }
    /// ```
    var isFromHealthKit: Bool {
        return healthKitId != nil
    }
}
