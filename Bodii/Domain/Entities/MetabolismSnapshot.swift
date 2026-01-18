//
//  MetabolismSnapshot.swift
//  Bodii
//
//  Created by Auto-Claude on 2024-01-12.
//

import Foundation

/// 대사량 스냅샷 도메인 엔티티
///
/// BodyRecord 입력 시 자동으로 생성되는 대사량 계산 결과를 기록합니다.
///
/// - Note: BodyRecord와 1:1 관계를 가지며, 체성분 변화에 따른 BMR/TDEE 추이 분석에 사용됩니다.
///
/// - Note: BMR은 체지방률 유무에 따라 다른 공식을 사용합니다:
///         - 체지방률 있음: Katch-McArdle 공식
///         - 체지방률 없음: Mifflin-St Jeor 공식
///
/// - Example:
/// ```swift
/// let snapshot = MetabolismSnapshot(
///     id: UUID(),
///     userId: user.id,
///     bodyRecordId: bodyRecord.id,
///     date: Date(),
///     weight: Decimal(70.5),
///     bodyFatPct: Decimal(21.5),
///     bmr: Decimal(1698.4),
///     tdee: Decimal(2632.5),
///     activityLevel: .moderatelyActive,
///     createdAt: Date()
/// )
/// ```
struct MetabolismSnapshot {
    // MARK: - Primary Key

    /// 고유 식별자
    let id: UUID

    // MARK: - Foreign Keys

    /// User 참조
    let userId: UUID

    /// BodyRecord 참조 (1:1 관계)
    let bodyRecordId: UUID

    // MARK: - Snapshot Data

    /// 측정일시
    var date: Date

    /// 체중 (kg)
    ///
    /// BodyRecord의 weight 값을 복사하여 저장합니다.
    var weight: Decimal

    /// 체지방률 (%)
    ///
    /// BodyRecord의 bodyFatPercent 값을 복사하여 저장합니다.
    /// BMR 계산 공식 선택에 사용됩니다.
    var bodyFatPct: Decimal?

    /// 기초대사량 (kcal)
    ///
    /// - 체지방률 있음: Katch-McArdle 공식 (BMR = 370 + 21.6 × LBM)
    /// - 체지방률 없음: Mifflin-St Jeor 공식 (성별, 나이, 키, 체중 기반)
    var bmr: Decimal

    /// 활동대사량 (kcal)
    ///
    /// TDEE = BMR × 활동계수
    var tdee: Decimal

    /// 계산 당시 활동 수준 (1~5)
    ///
    /// - 1: 비활동적 (Sedentary) - 좌식 생활, 계수 1.2
    /// - 2: 가벼운 활동 (Light) - 주 1-3일 운동, 계수 1.375
    /// - 3: 보통 활동 (Moderate) - 주 3-5일 운동, 계수 1.55
    /// - 4: 활동적 (Active) - 주 6-7일 운동, 계수 1.725
    /// - 5: 매우 활동적 (Very Active) - 고강도 매일, 계수 1.9
    var activityLevel: ActivityLevel

    // MARK: - Metadata

    /// 생성일시
    let createdAt: Date
}

// MARK: - Identifiable

extension MetabolismSnapshot: Identifiable {}

// MARK: - Equatable

extension MetabolismSnapshot: Equatable {
    static func == (lhs: MetabolismSnapshot, rhs: MetabolismSnapshot) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Hashable

extension MetabolismSnapshot: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
