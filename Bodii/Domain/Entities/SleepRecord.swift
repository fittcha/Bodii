//
//  SleepRecord.swift
//  Bodii
//
//  Created by Auto-Claude on 2024-01-12.
//

import Foundation

/// 수면 기록 도메인 엔티티
///
/// 사용자의 수면 시간과 품질을 기록합니다.
///
/// - Note: date는 02:00 기준으로 하루를 구분합니다.
///         - 02:00 ~ 익일 01:59 = 같은 날
///         - 예: 2026-01-11 03:00 입력 → date = 2026-01-11
///         - 예: 2026-01-11 01:00 입력 → date = 2026-01-10
///
/// - Note: status는 duration(분 단위)에 따라 자동으로 결정됩니다.
///         - Bad (🔴): 330분 미만 (5시간 30분 미만)
///         - Soso (🟡): 330~390분 (5시간 30분 ~ 6시간 30분)
///         - Good (🟢): 390~450분 (6시간 30분 ~ 7시간 30분)
///         - Excellent (🔵): 450~540분 (7시간 30분 ~ 9시간)
///         - Oversleep (🟠): 540분 초과 (9시간 초과)
///
/// - Note: 수면 기록 입력 시 DailyLog의 sleepDuration, sleepStatus가 자동으로 업데이트됩니다.
///
/// - Example:
/// ```swift
/// let sleepRecord = SleepRecord(
///     id: UUID(),
///     userId: user.id,
///     date: Date(),
///     duration: 420,
///     status: .good,
///     createdAt: Date(),
///     updatedAt: Date()
/// )
/// ```
struct SleepRecord {
    // MARK: - Primary Key

    /// 고유 식별자
    let id: UUID

    // MARK: - Foreign Key

    /// User 참조
    let userId: UUID

    // MARK: - Sleep Data

    /// 수면 기준일 (02:00 기준)
    ///
    /// 02:00 ~ 익일 01:59까지를 같은 날로 취급합니다.
    /// - 03:00에 입력 시: 당일 날짜
    /// - 01:00에 입력 시: 전날 날짜
    var date: Date

    /// 수면 시간 (분 단위)
    ///
    /// 범위: 0분 이상 (밤샘 시 0분도 허용)
    var duration: Int32

    /// 수면 상태 (0: Bad, 1: Soso, 2: Good, 3: Excellent, 4: Oversleep)
    ///
    /// duration 값에 따라 자동으로 결정됩니다.
    /// SleepStatus.from(durationMinutes:) 메서드를 사용하여 계산합니다.
    var status: SleepStatus

    // MARK: - HealthKit Integration

    /// HealthKit UUID (외부 데이터 추적용)
    ///
    /// 📚 학습 포인트: External ID Tracking
    /// - Apple Health에서 가져온 수면 기록의 경우 원본 UUID 보존
    /// - 중복 임포트 방지: 같은 healthKitId가 이미 존재하면 건너뛰기
    /// - 수동 입력 수면은 nil
    /// 💡 Java 비교: externalId 필드와 유사
    ///
    /// - Note: 양방향 동기화 시 충돌 해결에 활용
    ///   - healthKitId가 있으면 → Apple Health에서 가져온 데이터
    ///   - healthKitId가 nil이면 → 사용자가 수동 입력한 데이터
    var healthKitId: String?

    // MARK: - Metadata

    /// 생성일시
    let createdAt: Date

    /// 수정일시
    var updatedAt: Date
}

// MARK: - Identifiable

extension SleepRecord: Identifiable {}

// MARK: - Equatable

extension SleepRecord: Equatable {
    static func == (lhs: SleepRecord, rhs: SleepRecord) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Hashable

extension SleepRecord: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - HealthKit Integration

extension SleepRecord {
    /// HealthKit에서 가져온 데이터인지 여부
    ///
    /// 📚 학습 포인트: Computed Property
    /// - healthKitId의 존재 여부로 데이터 출처 판별
    /// - UI에서 데이터 출처 표시에 활용
    /// 💡 Java 비교: isExternal() getter 메서드와 유사
    ///
    /// - Returns: HealthKit에서 가져온 데이터이면 true, 수동 입력이면 false
    ///
    /// - Example:
    /// ```swift
    /// if sleepRecord.isFromHealthKit {
    ///     // Apple Health 출처 표시
    ///     Image(systemName: "applewatch")
    /// }
    /// ```
    var isFromHealthKit: Bool {
        return healthKitId != nil
    }
}
