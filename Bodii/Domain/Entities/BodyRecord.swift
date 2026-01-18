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
