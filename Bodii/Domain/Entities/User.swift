//
//  User.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-11.
//

// 📚 학습 포인트: Domain Entity Pattern
// Domain 계층의 순수 Swift 구조체로 비즈니스 로직에서 사용
// Core Data 엔티티(UserEntity)와 분리하여 테스트 가능성과 유지보수성 향상
// 💡 Java 비교: JPA Entity를 그대로 사용하지 않고 별도 Domain 모델을 두는 Clean Architecture 패턴

import Foundation

// MARK: - User

/// 사용자 도메인 엔티티
/// - 앱의 핵심 엔티티로 사용자의 기본 정보와 현재 대사 상태를 관리
/// - Core Data의 UserEntity와 1:1 매핑되지만 순수 Swift 타입으로 비즈니스 로직에서 사용
///
/// ## 주요 기능
/// - 사용자 프로필 정보 (이름, 성별, 생년월일, 키, 활동 수준)
/// - 현재 신체 데이터 (체중, 체지방률, 근육량)
/// - 현재 대사 정보 (기초대사량 BMR, 일일 총 에너지 소비량 TDEE)
/// - 자동 계산되는 나이 (생년월일 기반)
///
/// ## 사용 예시
/// ```swift
/// let user = User(
///     id: UUID(),
///     name: "홍길동",
///     gender: .male,
///     birthDate: Date(),
///     height: 175.0,
///     activityLevel: .moderate,
///     currentWeight: 70.0,
///     currentBodyFatPct: 18.5,
///     currentMuscleMass: 32.0,
///     currentBMR: 1650,
///     currentTDEE: 2550,
///     metabolismUpdatedAt: Date(),
///     createdAt: Date(),
///     updatedAt: Date()
/// )
/// print(user.age) // 나이 자동 계산
/// ```
struct User: Identifiable, Codable, Equatable {

    // MARK: - Properties

    // MARK: Identifier

    /// 사용자 고유 식별자
    /// - UUID 타입으로 전역 고유성 보장
    let id: UUID

    // MARK: Profile Information

    /// 사용자 이름
    /// - 길이 제한: 1-20자 (ValidationService.validateName으로 검증)
    var name: String

    /// 성별
    /// - BMR 계산 시 사용 (남성/여성에 따라 계산식 다름)
    var gender: Gender

    /// 생년월일
    /// - 나이 계산의 기준
    /// - 허용 범위: 1900년 ~ 현재 (ValidationService.validateAge로 검증)
    var birthDate: Date

    /// 키 (cm)
    /// - BMR 계산 시 사용
    /// - 허용 범위: 100-250cm (ValidationService.validateHeight로 검증)
    var height: Decimal

    /// 활동 수준
    /// - TDEE 계산 시 BMR에 곱할 계수 제공 (1.2 ~ 1.9)
    /// - 기본값: .moderate (보통 활동)
    var activityLevel: ActivityLevel

    // MARK: Current Body Data

    /// 현재 체중 (kg)
    /// - 가장 최근 BodyRecord의 weight 값
    /// - 허용 범위: 20-300kg (ValidationService.validateWeight로 검증)
    var currentWeight: Decimal

    /// 현재 체지방률 (%)
    /// - 가장 최근 BodyRecord의 bodyFatPercent 값
    /// - 허용 범위: 3-60% (ValidationService.validateBodyFatPercent로 검증)
    var currentBodyFatPct: Decimal

    /// 현재 근육량 (kg)
    /// - 가장 최근 BodyRecord의 muscleMass 값
    /// - 허용 범위: 10-60kg (ValidationService.validateMuscleMass로 검증)
    var currentMuscleMass: Decimal

    // MARK: Current Metabolism Data

    /// 현재 기초대사량 (kcal/day)
    /// - Mifflin-St Jeor 공식으로 계산: BMR = (10 × 체중kg) + (6.25 × 키cm) - (5 × 나이) + 성별계수
    /// - 성별계수: 남성 +5, 여성 -161
    /// - 가장 최근 MetabolismSnapshot의 bmr 값
    var currentBMR: Int

    /// 현재 일일 총 에너지 소비량 (kcal/day)
    /// - TDEE = BMR × activityLevel.multiplier
    /// - 가장 최근 MetabolismSnapshot의 tdee 값
    var currentTDEE: Int

    // MARK: Timestamps

    /// 대사 정보 마지막 업데이트 시각
    /// - BodyRecord 저장 시 자동으로 업데이트
    var metabolismUpdatedAt: Date

    /// 생성 시각
    let createdAt: Date

    /// 마지막 수정 시각
    var updatedAt: Date

    // MARK: - Computed Properties

    /// 만 나이
    /// - 생년월일 기반으로 자동 계산
    /// - 현재 날짜를 기준으로 계산
    ///
    /// ## 계산 방식
    /// ```swift
    /// // 예: 1990-05-15 생일, 2024-01-15 기준 → 33세
    /// let age = Date.age(from: birthDate)
    /// ```
    var age: Int {
        Date.age(from: birthDate)
    }
}

// MARK: - User + CustomStringConvertible

extension User: CustomStringConvertible {
    /// 디버깅용 문자열 표현
    var description: String {
        """
        User(
          id: \(id.uuidString.prefix(8))...,
          name: \(name),
          gender: \(gender.displayName),
          age: \(age)세,
          height: \(height)cm,
          activityLevel: \(activityLevel.displayName),
          currentWeight: \(currentWeight)kg,
          currentBodyFatPct: \(currentBodyFatPct)%,
          currentMuscleMass: \(currentMuscleMass)kg,
          currentBMR: \(currentBMR)kcal,
          currentTDEE: \(currentTDEE)kcal
        )
        """
    }
}
