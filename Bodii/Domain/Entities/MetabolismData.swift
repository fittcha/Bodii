//
//  MetabolismData.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-12.
//

// 📚 학습 포인트: Domain Entity for Metabolism Calculations
// Core Data와 독립적인 순수 도메인 엔티티
// 💡 Java 비교: POJO (Plain Old Java Object)와 유사하지만 Swift의 value type (struct) 사용

import Foundation

// MARK: - MetabolismData

/// 대사율 데이터 도메인 엔티티
/// BMR(기초대사량)과 TDEE(총 일일 에너지 소비량) 계산 결과를 나타냅니다.
/// 📚 학습 포인트: Clean Architecture의 Domain Layer
/// - Core Data나 다른 infrastructure 의존성이 없는 순수한 비즈니스 엔티티
/// - Decimal을 사용하여 정밀도 보장 (Double의 부동소수점 오차 방지)
/// - 각 신체 기록과 함께 저장되어 시간에 따른 대사율 변화 추적 가능
struct MetabolismData: Codable, Identifiable, Equatable {

    // MARK: - Properties

    /// 고유 식별자
    /// 📚 학습 포인트: UUID vs Int
    /// - UUID: 분산 시스템에서 충돌 없이 고유 ID 생성 가능
    /// - SwiftUI의 Identifiable 프로토콜 요구사항
    let id: UUID

    /// 측정 날짜 및 시간
    /// 📚 학습 포인트: Date Type
    /// - 시간대와 무관한 절대 시간 표현
    /// - 대사율의 시계열 추적에 필수
    let date: Date

    /// 기초대사량 (Basal Metabolic Rate) (kcal/day)
    /// 📚 학습 포인트: BMR
    /// - 생명 유지를 위해 필요한 최소한의 에너지
    /// - Mifflin-St Jeor 공식으로 계산: (10 × weight) + (6.25 × height) - (5 × age) + gender adjustment
    /// - 아무 활동도 하지 않고 하루 종일 누워있어도 소비되는 칼로리
    let bmr: Decimal

    /// 총 일일 에너지 소비량 (Total Daily Energy Expenditure) (kcal/day)
    /// 📚 학습 포인트: TDEE
    /// - BMR에 활동 수준을 곱한 값
    /// - TDEE = BMR × Activity Level Multiplier
    /// - 실제로 하루에 소비하는 총 칼로리 (활동량 포함)
    let tdee: Decimal

    /// 측정 당시의 체중 (kg)
    /// 📚 학습 포인트: Decimal Type
    /// - 정밀한 숫자 계산을 위해 Decimal 사용
    /// - Double 대신 Decimal을 사용하여 부동소수점 오차 방지
    /// 💡 Java 비교: java.math.BigDecimal과 유사
    let weight: Decimal

    /// 측정 당시의 체지방률 (%)
    /// 전체 체중에서 체지방이 차지하는 비율 (1-60% 범위)
    let bodyFatPercent: Decimal

    /// 활동 수준
    /// 📚 학습 포인트: Enum as Property
    /// - TDEE 계산에 사용된 활동 수준 저장
    /// - 과거 계산 시점의 설정을 보존하여 데이터 일관성 유지
    let activityLevel: ActivityLevel

    // MARK: - Initialization

    /// MetabolismData 생성자
    /// 📚 학습 포인트: Memberwise Initializer
    /// - Struct는 기본적으로 memberwise initializer 제공
    /// - 명시적으로 작성하여 문서화 및 validation 추가 가능
    /// - Parameter id: 고유 식별자 (기본값: 새 UUID)
    /// - Parameter date: 측정 날짜 (기본값: 현재 시간)
    /// - Parameter bmr: 기초대사량 (kcal/day)
    /// - Parameter tdee: 총 일일 에너지 소비량 (kcal/day)
    /// - Parameter weight: 체중 (kg)
    /// - Parameter bodyFatPercent: 체지방률 (%)
    /// - Parameter activityLevel: 활동 수준
    init(
        id: UUID = UUID(),
        date: Date = Date(),
        bmr: Decimal,
        tdee: Decimal,
        weight: Decimal,
        bodyFatPercent: Decimal,
        activityLevel: ActivityLevel
    ) {
        self.id = id
        self.date = date
        self.bmr = bmr
        self.tdee = tdee
        self.weight = weight
        self.bodyFatPercent = bodyFatPercent
        self.activityLevel = activityLevel
    }

    // MARK: - Computed Properties

    /// 활동으로 인한 추가 칼로리 소비량 (kcal/day)
    /// 📚 학습 포인트: Computed Property
    /// - 저장되지 않고 매번 계산되는 프로퍼티
    /// - get-only property (읽기 전용)
    /// 💡 Java 비교: getter 메서드와 유사하지만 프로퍼티처럼 접근
    ///
    /// 활동 칼로리 = TDEE - BMR
    /// BMR 외에 활동으로 인해 추가로 소비되는 칼로리
    var activityCalories: Decimal {
        tdee - bmr
    }

    /// 칼로리 결핍/잉여 계산 헬퍼 메서드
    /// 📚 학습 포인트: Instance Method
    /// - 섭취 칼로리와 비교하여 칼로리 균형 계산
    /// - 양수: 칼로리 잉여 (체중 증가 경향)
    /// - 음수: 칼로리 결핍 (체중 감소 경향)
    ///
    /// - Parameter calorieIntake: 일일 섭취 칼로리 (kcal)
    /// - Returns: 칼로리 균형 (섭취 - TDEE)
    func calculateCalorieBalance(calorieIntake: Decimal) -> Decimal {
        return calorieIntake - tdee
    }

    /// 주간 체중 변화 예측 (kg/week)
    /// 📚 학습 포인트: Business Logic in Domain
    /// - 7,700 kcal ≈ 1 kg 체지방
    /// - 하루 칼로리 차이 × 7일 = 주간 총 칼로리 차이
    /// - 주간 총 칼로리 차이 / 7,700 = 주간 체중 변화 (kg)
    ///
    /// - Parameter calorieIntake: 일일 섭취 칼로리 (kcal)
    /// - Returns: 예상 주간 체중 변화 (kg/week), 양수는 증가, 음수는 감소
    func estimatedWeeklyWeightChange(calorieIntake: Decimal) -> Decimal {
        let dailyBalance = calculateCalorieBalance(calorieIntake: calorieIntake)
        let weeklyBalance = dailyBalance * 7
        // 📚 학습 포인트: Magic Number
        // 7700 kcal ≈ 1 kg body fat (과학적으로 증명된 상수)
        return weeklyBalance / 7700
    }
}

// MARK: - Sample Data

extension MetabolismData {
    /// 📚 학습 포인트: Preview Helper
    /// SwiftUI Preview 및 테스트를 위한 샘플 데이터
    /// 💡 Java 비교: Test fixture와 유사
    static let sample = MetabolismData(
        bmr: Decimal(1650),
        tdee: Decimal(2280),
        weight: Decimal(70.5),
        bodyFatPercent: Decimal(18.5),
        activityLevel: .moderatelyActive
    )

    /// 다양한 시나리오를 위한 샘플 데이터 배열
    static let samples = [
        MetabolismData(
            date: Calendar.current.date(byAdding: .day, value: -7, to: Date())!,
            bmr: Decimal(1680),
            tdee: Decimal(2016),
            weight: Decimal(72.0),
            bodyFatPercent: Decimal(20.0),
            activityLevel: .sedentary
        ),
        MetabolismData(
            date: Calendar.current.date(byAdding: .day, value: -3, to: Date())!,
            bmr: Decimal(1665),
            tdee: Decimal(2290),
            weight: Decimal(71.2),
            bodyFatPercent: Decimal(19.3),
            activityLevel: .lightlyActive
        ),
        MetabolismData(
            date: Date(),
            bmr: Decimal(1650),
            tdee: Decimal(2280),
            weight: Decimal(70.5),
            bodyFatPercent: Decimal(18.5),
            activityLevel: .moderatelyActive
        )
    ]
}
