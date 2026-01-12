//
//  User.swift
//  Bodii
//
//  Created by Auto-Claude on 2024-01-12.
//

import Foundation

/// 사용자 도메인 엔티티
///
/// 앱을 사용하는 사용자의 기본 정보와 현재 체성분 상태를 나타냅니다.
///
/// - Note: currentWeight, currentBodyFatPct, currentMuscleMass, currentBMR, currentTDEE는
///         체성분 기록(BodyRecord) 입력 시 자동으로 업데이트됩니다.
///
/// - Example:
/// ```swift
/// let user = User(
///     id: UUID(),
///     name: "홍길동",
///     gender: .male,
///     birthDate: Date(),
///     height: Decimal(175.0),
///     activityLevel: .moderatelyActive,
///     createdAt: Date(),
///     updatedAt: Date()
/// )
/// ```
struct User {
    // MARK: - Primary Key

    /// 고유 식별자
    let id: UUID

    // MARK: - Basic Information

    /// 사용자 이름
    var name: String

    /// 성별 (0: 남성, 1: 여성)
    var gender: Gender

    /// 생년월일
    var birthDate: Date

    /// 키 (cm)
    var height: Decimal

    /// 활동 수준 (1~5)
    ///
    /// - 1: 비활동적 (Sedentary) - 좌식 생활, 계수 1.2
    /// - 2: 가벼운 활동 (Light) - 주 1-3일 운동, 계수 1.375
    /// - 3: 보통 활동 (Moderate) - 주 3-5일 운동, 계수 1.55
    /// - 4: 활동적 (Active) - 주 6-7일 운동, 계수 1.725
    /// - 5: 매우 활동적 (Very Active) - 고강도 매일, 계수 1.9
    var activityLevel: ActivityLevel

    // MARK: - Current Metabolism State

    /// 최신 체중 (kg)
    ///
    /// 체성분 기록(BodyRecord) 입력 시 자동 업데이트됩니다.
    var currentWeight: Decimal?

    /// 최신 체지방률 (%)
    ///
    /// 체성분 기록(BodyRecord) 입력 시 자동 업데이트됩니다.
    var currentBodyFatPct: Decimal?

    /// 최신 골격근량 (kg)
    ///
    /// 체성분 기록(BodyRecord) 입력 시 자동 업데이트됩니다.
    var currentMuscleMass: Decimal?

    /// 현재 기초대사량 (kcal)
    ///
    /// 체성분 기록 입력, 활동 수준 변경, 키/생년월일 변경 시 자동 업데이트됩니다.
    var currentBMR: Decimal?

    /// 현재 활동대사량 (kcal)
    ///
    /// 체성분 기록 입력, 활동 수준 변경, 키/생년월일 변경 시 자동 업데이트됩니다.
    var currentTDEE: Decimal?

    /// 대사량 마지막 계산 시점
    ///
    /// BMR/TDEE가 마지막으로 계산된 일시를 나타냅니다.
    var metabolismUpdatedAt: Date?

    // MARK: - Metadata

    /// 생성일시
    let createdAt: Date

    /// 수정일시
    var updatedAt: Date
}

// MARK: - Identifiable

extension User: Identifiable {}

// MARK: - Equatable

extension User: Equatable {
    static func == (lhs: User, rhs: User) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Hashable

extension User: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
