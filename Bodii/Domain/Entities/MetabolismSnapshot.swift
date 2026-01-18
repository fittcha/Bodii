//
//  MetabolismSnapshot.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-11.
//

// 📚 학습 포인트: 1:1 Relationship Entity Pattern
// MetabolismSnapshot은 BodyRecord와 1:1 관계로 신체 기록 시점의 대사량을 스냅샷으로 보존
// 💡 Java 비교: JPA의 @OneToOne 관계와 유사하지만 별도 테이블로 관리하여 이력 조회 최적화

import Foundation

// MARK: - MetabolismSnapshot

/// 대사량 스냅샷 도메인 엔티티
/// - BodyRecord와 1:1 관계로 신체 기록 시점의 BMR/TDEE를 저장
/// - 시간에 따른 대사량 변화 추적 및 대시보드 차트 표시에 사용
/// - Core Data의 MetabolismSnapshotEntity와 1:1 매핑되지만 순수 Swift 타입으로 비즈니스 로직에서 사용
///
/// ## 주요 기능
/// - 특정 시점의 대사량 정보 스냅샷 보존
/// - BMR(기초대사량)과 TDEE(총 에너지 소비량) 계산 결과 저장
/// - 활동 수준 변화에 따른 대사량 변화 추적
/// - BodyRecord와 동일한 date로 1:1 매핑
///
/// ## 1:1 관계 설명
/// ```
/// BodyRecord (체중 70kg, 체지방률 18.5%)
///     ↓ (1:1, 같은 date)
/// MetabolismSnapshot (BMR 1650kcal, TDEE 2550kcal)
/// ```
///
/// ## 계산 공식
/// ```
/// BMR (Mifflin-St Jeor 공식):
///   남성: (10 × 체중kg) + (6.25 × 키cm) - (5 × 나이) + 5
///   여성: (10 × 체중kg) + (6.25 × 키cm) - (5 × 나이) - 161
///
/// TDEE (Total Daily Energy Expenditure):
///   TDEE = BMR × activityLevel.multiplier
/// ```
///
/// ## 사용 예시
/// ```swift
/// // BodyRecord 저장 시 자동으로 생성됨
/// let snapshot = MetabolismSnapshot(
///     id: UUID(),
///     userId: userId,
///     bodyRecordId: bodyRecord.id,
///     date: bodyRecord.date,
///     weight: 70.0,
///     bodyFatPct: 18.5,
///     bmr: 1650,
///     tdee: 2550,
///     activityLevel: .moderate,
///     createdAt: Date()
/// )
///
/// // 대시보드 차트에서 대사량 변화 조회
/// let recentSnapshots = await repository.fetchRecentSnapshots(userId: userId, days: 30)
/// let bmrTrend = recentSnapshots.map { ($0.date, $0.bmr) }
/// ```
struct MetabolismSnapshot: Identifiable, Codable, Equatable {

    // MARK: - Properties

    // MARK: Identifier

    /// 대사량 스냅샷 고유 식별자
    /// - UUID 타입으로 전역 고유성 보장
    let id: UUID

    /// 사용자 고유 식별자
    /// - User 엔티티와의 외래 키 관계
    let userId: UUID

    /// 신체 기록 고유 식별자
    /// - BodyRecord 엔티티와 1:1 관계
    /// - 동일한 date 값을 가진 BodyRecord와 매핑
    let bodyRecordId: UUID

    // MARK: Snapshot Data

    /// 기록 날짜
    /// - BodyRecord의 date와 동일한 값
    /// - 하루에 하나의 MetabolismSnapshot만 존재 (unique constraint)
    let date: Date

    /// 체중 (kg)
    /// - BodyRecord의 weight 값을 스냅샷으로 보존
    /// - BMR 계산에 사용된 체중 값
    /// - 허용 범위: 20-300kg
    let weight: Decimal

    /// 체지방률 (%)
    /// - BodyRecord의 bodyFatPercent 값을 스냅샷으로 보존
    /// - 대시보드에서 체지방률 변화 추적에 사용
    /// - 허용 범위: 3-60%
    let bodyFatPct: Decimal

    // MARK: Metabolism Data

    /// 기초대사량 (kcal/day)
    /// - Mifflin-St Jeor 공식으로 계산된 BMR
    /// - 계산식: (10 × 체중kg) + (6.25 × 키cm) - (5 × 나이) + 성별계수
    /// - 성별계수: 남성 +5, 여성 -161
    /// - 아무 활동도 하지 않을 때 하루에 소비되는 최소 열량
    let bmr: Int

    /// 일일 총 에너지 소비량 (kcal/day)
    /// - 활동 수준을 고려한 실제 하루 총 소비 열량
    /// - 계산식: BMR × activityLevel.multiplier
    /// - 목표 칼로리 설정의 기준값
    let tdee: Int

    /// 활동 수준
    /// - TDEE 계산 시 사용된 활동 수준
    /// - 활동 수준 변경 시 대사량 변화 추적 가능
    /// - 범위: sedentary(1.2) ~ veryActive(1.9)
    let activityLevel: ActivityLevel

    // MARK: Timestamps

    /// 생성 시각
    /// - 스냅샷이 생성된 시각
    /// - BodyRecord 저장 시점과 동일
    let createdAt: Date
}

// MARK: - MetabolismSnapshot + CustomStringConvertible

extension MetabolismSnapshot: CustomStringConvertible {
    /// 디버깅용 문자열 표현
    var description: String {
        """
        MetabolismSnapshot(
          id: \(id.uuidString.prefix(8))...,
          userId: \(userId.uuidString.prefix(8))...,
          bodyRecordId: \(bodyRecordId.uuidString.prefix(8))...,
          date: \(date.formatted(style: .short)),
          weight: \(weight)kg,
          bodyFatPct: \(bodyFatPct)%,
          bmr: \(bmr)kcal,
          tdee: \(tdee)kcal,
          activityLevel: \(activityLevel.displayName)
        )
        """
    }
}
