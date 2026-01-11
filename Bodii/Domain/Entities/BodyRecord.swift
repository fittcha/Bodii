//
//  BodyRecord.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-11.
//

// 📚 학습 포인트: Auto-calculation Logic
// 체지방량과 체지방률은 상호 의존 관계 - 하나가 변경되면 다른 하나도 자동 재계산
// 💡 Java 비교: JPA의 @PrePersist/@PreUpdate와 유사하지만 Swift는 헬퍼 메서드로 구현

import Foundation

// MARK: - BodyRecord

/// 신체 기록 도메인 엔티티
/// - 사용자의 체중, 체지방량, 체지방률, 근육량을 기록
/// - 체지방량 ↔ 체지방률 자동 계산 기능 제공
/// - MetabolismSnapshot과 1:1 관계 (동일한 date로 매핑)
///
/// ## 주요 기능
/// - 체지방량/체지방률 상호 변환 계산
/// - 날짜별 신체 데이터 추적
/// - 대사량 스냅샷 자동 생성 트리거
///
/// ## 계산 공식
/// ```
/// 체지방량(kg) = 체중(kg) × (체지방률(%) / 100)
/// 체지방률(%) = (체지방량(kg) / 체중(kg)) × 100
/// 제지방량(kg) = 체중(kg) - 체지방량(kg)
/// ```
///
/// ## 사용 예시
/// ```swift
/// // 1. 체지방률로 생성 후 체지방량 자동 계산
/// var record = BodyRecord.from(
///     userId: userId,
///     date: Date(),
///     weight: 70.0,
///     bodyFatPercent: 18.5,
///     muscleMass: 32.0
/// )
/// print(record.bodyFatMass) // 12.95kg (자동 계산됨)
///
/// // 2. 체지방량으로 생성 후 체지방률 자동 계산
/// var record2 = BodyRecord.from(
///     userId: userId,
///     date: Date(),
///     weight: 70.0,
///     bodyFatMass: 12.95,
///     muscleMass: 32.0
/// )
/// print(record2.bodyFatPercent) // 18.5% (자동 계산됨)
/// ```
struct BodyRecord: Identifiable, Codable, Equatable {

    // MARK: - Properties

    // MARK: Identifier

    /// 신체 기록 고유 식별자
    /// - UUID 타입으로 전역 고유성 보장
    let id: UUID

    /// 사용자 고유 식별자
    /// - User 엔티티와의 외래 키 관계
    let userId: UUID

    // MARK: Record Data

    /// 기록 날짜
    /// - 하루에 하나의 BodyRecord만 존재 (unique constraint)
    /// - 동일 날짜의 MetabolismSnapshot과 1:1 매핑
    let date: Date

    /// 체중 (kg)
    /// - 허용 범위: 20-300kg (ValidationService.validateWeight로 검증)
    /// - 체지방량/체지방률 계산의 기준값
    var weight: Decimal

    /// 체지방량 (kg)
    /// - 계산 공식: weight × (bodyFatPercent / 100)
    /// - bodyFatPercent가 변경되면 자동으로 재계산 필요
    var bodyFatMass: Decimal

    /// 체지방률 (%)
    /// - 허용 범위: 3-60% (ValidationService.validateBodyFatPercent로 검증)
    /// - 계산 공식: (bodyFatMass / weight) × 100
    /// - bodyFatMass가 변경되면 자동으로 재계산 필요
    var bodyFatPercent: Decimal

    /// 근육량 (kg)
    /// - 허용 범위: 10-60kg (ValidationService.validateMuscleMass로 검증)
    /// - 제지방량(체중 - 체지방량)의 일부
    /// - 검증: 근육량 ≤ 제지방량 (ValidationService.validateBodyComposition으로 검증)
    var muscleMass: Decimal

    // MARK: Timestamps

    /// 생성 시각
    let createdAt: Date

    // MARK: - Computed Properties

    /// 제지방량 (kg)
    /// - 계산 공식: 체중 - 체지방량
    /// - 근육량 검증에 사용: 근육량 ≤ 제지방량
    ///
    /// ## 참고
    /// 제지방량(Lean Body Mass, LBM)은 체중에서 체지방량을 제외한 모든 조직의 무게
    /// - 포함: 근육, 뼈, 장기, 수분 등
    /// - 근육량은 제지방량의 일부이므로 반드시 제지방량보다 작거나 같아야 함
    var leanBodyMass: Decimal {
        weight - bodyFatMass
    }

    // MARK: - Factory Methods

    /// 체지방률을 기준으로 BodyRecord 생성 (체지방량 자동 계산)
    /// - Parameters:
    ///   - userId: 사용자 고유 식별자
    ///   - date: 기록 날짜
    ///   - weight: 체중 (kg)
    ///   - bodyFatPercent: 체지방률 (%)
    ///   - muscleMass: 근육량 (kg)
    /// - Returns: 체지방량이 자동 계산된 BodyRecord
    ///
    /// ## 계산 공식
    /// ```
    /// 체지방량(kg) = 체중(kg) × (체지방률(%) / 100)
    /// ```
    ///
    /// ## 사용 예시
    /// ```swift
    /// let record = BodyRecord.from(
    ///     userId: userId,
    ///     date: Date(),
    ///     weight: 70.0,
    ///     bodyFatPercent: 18.5,  // 입력
    ///     muscleMass: 32.0
    /// )
    /// // record.bodyFatMass = 12.95kg (자동 계산)
    /// ```
    static func from(
        userId: UUID,
        date: Date,
        weight: Decimal,
        bodyFatPercent: Decimal,
        muscleMass: Decimal
    ) -> BodyRecord {
        let bodyFatMass = calculateBodyFatMass(weight: weight, bodyFatPercent: bodyFatPercent)

        return BodyRecord(
            id: UUID(),
            userId: userId,
            date: date,
            weight: weight,
            bodyFatMass: bodyFatMass,
            bodyFatPercent: bodyFatPercent,
            muscleMass: muscleMass,
            createdAt: Date()
        )
    }

    /// 체지방량을 기준으로 BodyRecord 생성 (체지방률 자동 계산)
    /// - Parameters:
    ///   - userId: 사용자 고유 식별자
    ///   - date: 기록 날짜
    ///   - weight: 체중 (kg)
    ///   - bodyFatMass: 체지방량 (kg)
    ///   - muscleMass: 근육량 (kg)
    /// - Returns: 체지방률이 자동 계산된 BodyRecord
    ///
    /// ## 계산 공식
    /// ```
    /// 체지방률(%) = (체지방량(kg) / 체중(kg)) × 100
    /// ```
    ///
    /// ## 사용 예시
    /// ```swift
    /// let record = BodyRecord.from(
    ///     userId: userId,
    ///     date: Date(),
    ///     weight: 70.0,
    ///     bodyFatMass: 12.95,  // 입력
    ///     muscleMass: 32.0
    /// )
    /// // record.bodyFatPercent = 18.5% (자동 계산)
    /// ```
    static func from(
        userId: UUID,
        date: Date,
        weight: Decimal,
        bodyFatMass: Decimal,
        muscleMass: Decimal
    ) -> BodyRecord {
        let bodyFatPercent = calculateBodyFatPercent(weight: weight, bodyFatMass: bodyFatMass)

        return BodyRecord(
            id: UUID(),
            userId: userId,
            date: date,
            weight: weight,
            bodyFatMass: bodyFatMass,
            bodyFatPercent: bodyFatPercent,
            muscleMass: muscleMass,
            createdAt: Date()
        )
    }

    // MARK: - Helper Methods

    /// 체지방량 계산
    /// - Parameters:
    ///   - weight: 체중 (kg)
    ///   - bodyFatPercent: 체지방률 (%)
    /// - Returns: 계산된 체지방량 (kg)
    ///
    /// ## 계산 공식
    /// ```
    /// 체지방량(kg) = 체중(kg) × (체지방률(%) / 100)
    /// ```
    ///
    /// ## 예시
    /// ```swift
    /// let bodyFatMass = calculateBodyFatMass(weight: 70.0, bodyFatPercent: 18.5)
    /// // 결과: 12.95kg = 70 × (18.5 / 100)
    /// ```
    static func calculateBodyFatMass(weight: Decimal, bodyFatPercent: Decimal) -> Decimal {
        return weight * (bodyFatPercent / 100)
    }

    /// 체지방률 계산
    /// - Parameters:
    ///   - weight: 체중 (kg)
    ///   - bodyFatMass: 체지방량 (kg)
    /// - Returns: 계산된 체지방률 (%)
    ///
    /// ## 계산 공식
    /// ```
    /// 체지방률(%) = (체지방량(kg) / 체중(kg)) × 100
    /// ```
    ///
    /// ## 예시
    /// ```swift
    /// let bodyFatPercent = calculateBodyFatPercent(weight: 70.0, bodyFatMass: 12.95)
    /// // 결과: 18.5% = (12.95 / 70) × 100
    /// ```
    static func calculateBodyFatPercent(weight: Decimal, bodyFatMass: Decimal) -> Decimal {
        guard weight > 0 else { return 0 }
        return (bodyFatMass / weight) * 100
    }

    /// 체중 변경 시 체지방량 재계산 (체지방률 유지)
    /// - Parameter newWeight: 새로운 체중 (kg)
    /// - Returns: 체지방량이 재계산된 새 BodyRecord
    ///
    /// ## 사용 시나리오
    /// 사용자가 체중만 수정할 때 체지방률은 유지하고 체지방량만 재계산
    ///
    /// ## 예시
    /// ```swift
    /// let original = BodyRecord.from(userId: id, date: Date(), weight: 70.0, bodyFatPercent: 18.5, muscleMass: 32.0)
    /// // original.bodyFatMass = 12.95kg
    ///
    /// let updated = original.updatingWeight(72.0)
    /// // updated.bodyFatPercent = 18.5% (유지)
    /// // updated.bodyFatMass = 13.32kg (재계산)
    /// ```
    func updatingWeight(_ newWeight: Decimal) -> BodyRecord {
        let newBodyFatMass = Self.calculateBodyFatMass(weight: newWeight, bodyFatPercent: bodyFatPercent)

        return BodyRecord(
            id: id,
            userId: userId,
            date: date,
            weight: newWeight,
            bodyFatMass: newBodyFatMass,
            bodyFatPercent: bodyFatPercent,
            muscleMass: muscleMass,
            createdAt: createdAt
        )
    }

    /// 체지방률 변경 시 체지방량 재계산
    /// - Parameter newBodyFatPercent: 새로운 체지방률 (%)
    /// - Returns: 체지방량이 재계산된 새 BodyRecord
    ///
    /// ## 사용 시나리오
    /// 사용자가 체지방률을 수정할 때 체지방량을 자동 재계산
    ///
    /// ## 예시
    /// ```swift
    /// let original = BodyRecord.from(userId: id, date: Date(), weight: 70.0, bodyFatPercent: 18.5, muscleMass: 32.0)
    /// // original.bodyFatMass = 12.95kg
    ///
    /// let updated = original.updatingBodyFatPercent(20.0)
    /// // updated.bodyFatPercent = 20.0% (변경됨)
    /// // updated.bodyFatMass = 14.0kg (재계산)
    /// ```
    func updatingBodyFatPercent(_ newBodyFatPercent: Decimal) -> BodyRecord {
        let newBodyFatMass = Self.calculateBodyFatMass(weight: weight, bodyFatPercent: newBodyFatPercent)

        return BodyRecord(
            id: id,
            userId: userId,
            date: date,
            weight: weight,
            bodyFatMass: newBodyFatMass,
            bodyFatPercent: newBodyFatPercent,
            muscleMass: muscleMass,
            createdAt: createdAt
        )
    }

    /// 체지방량 변경 시 체지방률 재계산
    /// - Parameter newBodyFatMass: 새로운 체지방량 (kg)
    /// - Returns: 체지방률이 재계산된 새 BodyRecord
    ///
    /// ## 사용 시나리오
    /// 사용자가 체지방량을 직접 입력할 때 체지방률을 자동 재계산
    ///
    /// ## 예시
    /// ```swift
    /// let original = BodyRecord.from(userId: id, date: Date(), weight: 70.0, bodyFatPercent: 18.5, muscleMass: 32.0)
    /// // original.bodyFatPercent = 18.5%
    ///
    /// let updated = original.updatingBodyFatMass(14.0)
    /// // updated.bodyFatMass = 14.0kg (변경됨)
    /// // updated.bodyFatPercent = 20.0% (재계산)
    /// ```
    func updatingBodyFatMass(_ newBodyFatMass: Decimal) -> BodyRecord {
        let newBodyFatPercent = Self.calculateBodyFatPercent(weight: weight, bodyFatMass: newBodyFatMass)

        return BodyRecord(
            id: id,
            userId: userId,
            date: date,
            weight: weight,
            bodyFatMass: newBodyFatMass,
            bodyFatPercent: newBodyFatPercent,
            muscleMass: muscleMass,
            createdAt: createdAt
        )
    }
}

// MARK: - BodyRecord + CustomStringConvertible

extension BodyRecord: CustomStringConvertible {
    /// 디버깅용 문자열 표현
    var description: String {
        """
        BodyRecord(
          id: \(id.uuidString.prefix(8))...,
          userId: \(userId.uuidString.prefix(8))...,
          date: \(date.formatted(style: .short)),
          weight: \(weight)kg,
          bodyFatMass: \(bodyFatMass)kg,
          bodyFatPercent: \(bodyFatPercent)%,
          muscleMass: \(muscleMass)kg,
          leanBodyMass: \(leanBodyMass)kg (computed)
        )
        """
    }
}
