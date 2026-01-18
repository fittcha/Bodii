//
//  BodyRecord.swift
//  Bodii
//
//  Created by Auto-Claude on 2024-01-12.
//

import Foundation

/// 체성분 기록 도메인 엔티티
///
/// 사용자의 체중, 체지방량, 체지방률, 골격근량을 기록합니다.
///
/// - Note: bodyFatMass와 bodyFatPercent는 앱 레벨에서 자동 계산됩니다.
///         - bodyFatMass 입력 시: bodyFatPercent = (bodyFatMass / weight) × 100
///         - bodyFatPercent 입력 시: bodyFatMass = weight × (bodyFatPercent / 100)
///
/// - Note: 체성분 기록 입력 시 User의 current* 필드와 MetabolismSnapshot이 자동으로 업데이트됩니다.
///
/// - Example:
/// ```swift
/// let bodyRecord = BodyRecord(
///     id: UUID(),
///     userId: user.id,
///     date: Date(),
///     weight: Decimal(70.5),
///     bodyFatMass: Decimal(15.2),
///     bodyFatPercent: Decimal(21.5),
///     muscleMass: Decimal(30.8),
///     createdAt: Date()
/// )
/// ```
struct BodyRecord {
    // MARK: - Primary Key

    /// 고유 식별자
    let id: UUID

    // MARK: - Foreign Key

    /// User 참조
    let userId: UUID

    // MARK: - Body Composition Data

    /// 측정일시 (기본값: 현재 일시)
    var date: Date

    /// 몸무게 (kg)
    var weight: Decimal

    /// 체지방량 (kg)
    ///
    /// bodyFatPercent 입력 시 자동 계산: weight × (bodyFatPercent / 100)
    var bodyFatMass: Decimal?

    /// 체지방률 (%)
    ///
    /// bodyFatMass 입력 시 자동 계산: (bodyFatMass / weight) × 100
    var bodyFatPercent: Decimal?

    /// 골격근량 (kg)
    var muscleMass: Decimal?

    // MARK: - HealthKit Integration

    /// HealthKit UUID (외부 데이터 추적용)
    ///
    /// 📚 학습 포인트: External ID Tracking
    /// - Apple Health에서 가져온 체성분 기록의 경우 원본 UUID 보존
    /// - 중복 임포트 방지: 같은 healthKitId가 이미 존재하면 건너뛰기
    /// - 수동 입력 체성분은 nil
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

extension BodyRecord: Identifiable {}

// MARK: - Equatable

extension BodyRecord: Equatable {
    static func == (lhs: BodyRecord, rhs: BodyRecord) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Hashable

extension BodyRecord: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - HealthKit Integration

extension BodyRecord {
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
    /// if bodyRecord.isFromHealthKit {
    ///     // Apple Health 출처 표시
    ///     Text("Apple Health에서 동기화됨")
    /// }
    /// ```
    var isFromHealthKit: Bool {
        return healthKitId != nil
    }
}
