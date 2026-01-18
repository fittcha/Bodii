//
//  SleepRecord.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-11.
//

// 📚 학습 포인트: Auto-Status Calculation
// SleepRecord는 수면 시간(분)에 따라 수면 상태를 자동으로 계산
// 💡 Java 비교: JPA의 @PrePersist/@PreUpdate와 유사하지만 Swift는 factory method 사용

import Foundation

// MARK: - SleepRecord

/// 수면 기록 도메인 엔티티
/// - 사용자의 수면 시간과 상태를 기록
/// - 수면 시간(분)에 따라 수면 상태 자동 계산
/// - HealthKit 연동 지원 (자동 기록)
///
/// ## 주요 기능
/// - 수면 시간 기반 수면 상태 자동 결정
/// - DailyLog에서 일일 수면 데이터 집계에 사용
/// - HealthKit 데이터 연동 지원
/// - 02:00 수면 경계 로직 적용
///
/// ## 수면 상태 결정 기준
/// ```
/// 나쁨 (bad): 0-329분 (0-5.5시간)
/// 보통 (soso): 330-389분 (5.5-6.5시간)
/// 좋음 (good): 390-449분 (6.5-7.5시간)
/// 매우 좋음 (excellent): 450-540분 (7.5-9시간)
/// 과수면 (oversleep): 541분 이상 (9시간 초과)
/// ```
///
/// ## 02:00 수면 경계 로직
/// - 00:00 ~ 01:59에 기록된 수면은 전날의 수면으로 간주
/// - 02:00 ~ 23:59에 기록된 수면은 당일의 수면으로 간주
/// - DateUtils.getLogicalDate()를 사용하여 논리적 날짜 결정
///
/// ## 데이터 관계
/// - DailyLog (N:1): 같은 날짜의 SleepRecord들이 DailyLog에 집계됨
/// - HealthKit: fromHealthKit이 true면 HealthKit에서 자동 기록된 데이터
///
/// ## 사용 예시
/// ```swift
/// // 1. 수동 수면 기록 (사용자 입력)
/// let record = SleepRecord.create(
///     userId: userId,
///     date: Date(),
///     duration: 420
/// )
/// print(record.status) // .good (자동 계산: 420분 = 7시간)
///
/// // 2. HealthKit 연동 기록
/// let healthKitRecord = SleepRecord.createFromHealthKit(
///     userId: userId,
///     date: Date(),
///     duration: 480,
///     healthKitId: "HK-SLEEP-12345"
/// )
/// print(healthKitRecord.status) // .excellent (자동 계산: 480분 = 8시간)
/// print(healthKitRecord.fromHealthKit) // true
/// ```
struct SleepRecord: Identifiable, Codable, Equatable {

    // MARK: - Properties

    // MARK: Identifier

    /// 수면 기록 고유 식별자
    /// - UUID 타입으로 전역 고유성 보장
    let id: UUID

    /// 사용자 고유 식별자
    /// - User 엔티티와의 외래 키 관계
    let userId: UUID

    // MARK: Record Data

    /// 수면 날짜
    /// - 02:00 sleep boundary 로직 적용 (DateUtils.getLogicalDate)
    /// - DailyLog 집계 시 이 날짜 기준으로 그룹화
    ///
    /// ## 예시
    /// - 2024-01-02 01:30에 수면 종료 → 2024-01-01로 기록 (전날 수면)
    /// - 2024-01-02 07:00에 수면 종료 → 2024-01-02로 기록 (당일 수면)
    let date: Date

    /// 수면 시간 (분)
    /// - 총 수면 시간 (수면 시작부터 종료까지)
    /// - 수면 상태(status) 자동 계산에 사용
    ///
    /// ## 예시
    /// - 420분 = 7시간 → good
    /// - 480분 = 8시간 → excellent
    /// - 300분 = 5시간 → bad
    let duration: Int

    /// 수면 상태
    /// - duration(분)으로부터 자동 계산
    /// - SleepStatus.from(durationMinutes:)을 사용하여 결정
    /// - .bad, .soso, .good, .excellent, .oversleep 중 하나
    let status: SleepStatus

    // MARK: HealthKit Integration

    /// HealthKit 연동 여부
    /// - true: HealthKit에서 자동으로 기록된 수면
    /// - false: 사용자가 수동으로 입력한 수면
    let fromHealthKit: Bool

    /// HealthKit 수면 고유 식별자
    /// - HealthKit에서 가져온 수면 데이터의 원본 ID
    /// - 중복 방지 및 동기화에 사용
    let healthKitId: String?

    // MARK: Timestamps

    /// 생성 시각
    /// - 수면 기록이 DB에 추가된 시각
    let createdAt: Date

    /// 수정 시각
    /// - 수면 기록이 마지막으로 수정된 시각
    var updatedAt: Date

    // MARK: - Factory Methods

    /// 수면 기록 생성 (수동 입력)
    /// - Parameters:
    ///   - userId: 사용자 고유 식별자
    ///   - date: 수면 날짜 (논리적 날짜, 02:00 boundary 적용된 날짜)
    ///   - duration: 수면 시간 (분)
    /// - Returns: 수면 상태가 자동 계산된 SleepRecord
    ///
    /// ## 사용 예시
    /// ```swift
    /// let record = SleepRecord.create(
    ///     userId: userId,
    ///     date: Date(),
    ///     duration: 420
    /// )
    /// print(record.duration) // 420분 (7시간)
    /// print(record.status) // .good (자동 계산)
    /// print(record.fromHealthKit) // false
    /// ```
    static func create(
        userId: UUID,
        date: Date,
        duration: Int
    ) -> SleepRecord {
        let status = SleepStatus.from(durationMinutes: duration)

        let now = Date()
        return SleepRecord(
            id: UUID(),
            userId: userId,
            date: date,
            duration: duration,
            status: status,
            fromHealthKit: false,
            healthKitId: nil,
            createdAt: now,
            updatedAt: now
        )
    }

    /// HealthKit 연동 수면 기록 생성
    /// - Parameters:
    ///   - userId: 사용자 고유 식별자
    ///   - date: 수면 날짜 (논리적 날짜, 02:00 boundary 적용된 날짜)
    ///   - duration: 수면 시간 (분)
    ///   - healthKitId: HealthKit 수면 고유 식별자
    /// - Returns: 수면 상태가 자동 계산된 SleepRecord (HealthKit 연동)
    ///
    /// ## 사용 예시
    /// ```swift
    /// let record = SleepRecord.createFromHealthKit(
    ///     userId: userId,
    ///     date: Date(),
    ///     duration: 480,
    ///     healthKitId: "HK-SLEEP-12345"
    /// )
    /// print(record.status) // .excellent (자동 계산: 480분 = 8시간)
    /// print(record.fromHealthKit) // true
    /// print(record.healthKitId) // "HK-SLEEP-12345"
    /// ```
    static func createFromHealthKit(
        userId: UUID,
        date: Date,
        duration: Int,
        healthKitId: String
    ) -> SleepRecord {
        let status = SleepStatus.from(durationMinutes: duration)

        let now = Date()
        return SleepRecord(
            id: UUID(),
            userId: userId,
            date: date,
            duration: duration,
            status: status,
            fromHealthKit: true,
            healthKitId: healthKitId,
            createdAt: now,
            updatedAt: now
        )
    }

    // MARK: - Helper Methods

    /// 수면 시간 업데이트
    /// - Parameter newDuration: 새로운 수면 시간 (분)
    /// - Returns: 수면 상태가 재계산된 SleepRecord
    ///
    /// ## 사용 시나리오
    /// 사용자가 수면 시간을 수정할 때 수면 상태를 자동으로 재계산
    ///
    /// ## 예시
    /// ```swift
    /// let original = SleepRecord.create(userId: userId, date: Date(), duration: 360)
    /// // original.duration = 360분 (6시간)
    /// // original.status = .soso
    ///
    /// let updated = original.updatingDuration(420)
    /// // updated.duration = 420분 (7시간)
    /// // updated.status = .good (재계산)
    /// ```
    func updatingDuration(_ newDuration: Int) -> SleepRecord {
        let newStatus = SleepStatus.from(durationMinutes: newDuration)

        return SleepRecord(
            id: id,
            userId: userId,
            date: date,
            duration: newDuration,
            status: newStatus,
            fromHealthKit: fromHealthKit,
            healthKitId: healthKitId,
            createdAt: createdAt,
            updatedAt: Date()
        )
    }

    // MARK: - Computed Properties

    /// 수면 시간을 시간 단위로 반환
    /// - Returns: 수면 시간 (소수점 1자리, 시간 단위)
    ///
    /// ## 예시
    /// ```swift
    /// let record = SleepRecord.create(..., duration: 420)
    /// print(record.durationInHours) // 7.0시간
    ///
    /// let record2 = SleepRecord.create(..., duration: 450)
    /// print(record2.durationInHours) // 7.5시간
    /// ```
    var durationInHours: Double {
        return Double(duration) / 60.0
    }
}

// MARK: - SleepRecord + CustomStringConvertible

extension SleepRecord: CustomStringConvertible {
    /// 디버깅용 문자열 표현
    var description: String {
        let healthKitText = fromHealthKit ? " [HealthKit]" : ""
        let hoursText = String(format: "%.1f", durationInHours)

        return """
        SleepRecord(
          id: \(id.uuidString.prefix(8))...,
          userId: \(userId.uuidString.prefix(8))...,
          date: \(date.formatted(style: .short)),
          duration: \(duration)분 (\(hoursText)시간),
          status: \(status.displayName),
          fromHealthKit: \(fromHealthKit)\(healthKitText),
          createdAt: \(createdAt.formatted(style: .dateTime))
        )
        """
    }
}
