//
//  BodyCompositionEntry.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-12.
//

// 📚 학습 포인트: Domain Entity
// Core Data와 독립적인 순수 도메인 엔티티
// 💡 Java 비교: POJO (Plain Old Java Object)와 유사하지만 Swift의 value type (struct) 사용

import Foundation

// MARK: - BodyCompositionEntry

/// 신체 구성 데이터 도메인 엔티티
/// 체중, 체지방률, 근육량 등의 신체 측정 데이터를 나타냅니다.
/// 📚 학습 포인트: Clean Architecture의 Domain Layer
/// - Core Data나 다른 infrastructure 의존성이 없는 순수한 비즈니스 엔티티
/// - Decimal을 사용하여 정밀도 보장 (Double의 부동소수점 오차 방지)
struct BodyCompositionEntry: Codable, Identifiable, Equatable {

    // MARK: - Properties

    /// 고유 식별자
    /// 📚 학습 포인트: UUID vs Int
    /// - UUID: 분산 시스템에서 충돌 없이 고유 ID 생성 가능
    /// - SwiftUI의 Identifiable 프로토콜 요구사항
    let id: UUID

    /// 측정 날짜 및 시간
    /// 📚 학습 포인트: Date Type
    /// - 시간대와 무관한 절대 시간 표현
    /// - 트렌드 분석 및 기록 추적에 필수
    let date: Date

    /// 체중 (kg)
    /// 📚 학습 포인트: Decimal Type
    /// - 정밀한 숫자 계산을 위해 Decimal 사용
    /// - Double 대신 Decimal을 사용하여 부동소수점 오차 방지
    /// 💡 Java 비교: java.math.BigDecimal과 유사
    let weight: Decimal

    /// 체지방률 (%)
    /// 전체 체중에서 체지방이 차지하는 비율 (1-60% 범위)
    let bodyFatPercent: Decimal

    /// 근육량 (kg)
    /// 총 근육 질량 (skeletal muscle mass)
    let muscleMass: Decimal

    /// 체지방량 (kg)
    /// 전체 체중에서 지방이 차지하는 실제 무게
    /// 📚 학습 포인트: Stored vs Computed Property
    /// - 계산 가능한 값이지만 historical data를 위해 저장
    /// - 과거 데이터의 일관성 유지 (나중에 계산식이 바뀌어도 과거 값은 그대로)
    let bodyFatMass: Decimal

    // MARK: - Initialization

    /// BodyCompositionEntry 생성자
    /// 📚 학습 포인트: Memberwise Initializer
    /// - Struct는 기본적으로 memberwise initializer 제공
    /// - 명시적으로 작성하여 문서화 및 validation 추가 가능
    /// - Parameter id: 고유 식별자 (기본값: 새 UUID)
    /// - Parameter date: 측정 날짜 (기본값: 현재 시간)
    /// - Parameter weight: 체중 (kg)
    /// - Parameter bodyFatPercent: 체지방률 (%)
    /// - Parameter muscleMass: 근육량 (kg)
    /// - Parameter bodyFatMass: 체지방량 (kg, 선택적 - 미제공시 자동 계산)
    init(
        id: UUID = UUID(),
        date: Date = Date(),
        weight: Decimal,
        bodyFatPercent: Decimal,
        muscleMass: Decimal,
        bodyFatMass: Decimal? = nil
    ) {
        self.id = id
        self.date = date
        self.weight = weight
        self.bodyFatPercent = bodyFatPercent
        self.muscleMass = muscleMass

        // 📚 학습 포인트: Nil Coalescing Operator (??)
        // bodyFatMass가 제공되지 않으면 자동으로 계산
        // 💡 Java 비교: Optional.orElse()와 유사
        self.bodyFatMass = bodyFatMass ?? Self.calculateBodyFatMass(
            weight: weight,
            bodyFatPercent: bodyFatPercent
        )
    }

    // MARK: - Computed Properties

    /// 제지방량 (Lean Body Mass) (kg)
    /// 📚 학습 포인트: Computed Property
    /// - 저장되지 않고 매번 계산되는 프로퍼티
    /// - get-only property (읽기 전용)
    /// 💡 Java 비교: getter 메서드와 유사하지만 프로퍼티처럼 접근
    ///
    /// 제지방량 = 전체 체중 - 체지방량
    /// 근육, 뼈, 장기, 물 등 지방을 제외한 모든 체중
    var leanBodyMass: Decimal {
        weight - bodyFatMass
    }

    /// 골격근 비율 (%)
    /// 전체 체중에서 근육량이 차지하는 비율
    ///
    /// 골격근 비율 = (근육량 / 체중) × 100
    var musclePercentage: Decimal {
        guard weight > 0 else { return 0 }
        return (muscleMass / weight) * 100
    }

    /// 체질량 지수 (BMI) 계산을 위한 헬퍼 메서드
    /// 📚 학습 포인트: Optional Chaining
    /// - height가 없으면 BMI를 계산할 수 없음
    /// - 이 메서드는 height를 외부에서 받아서 BMI 계산
    /// 💡 참고: BMI = 체중(kg) / (신장(m))²
    ///
    /// - Parameter heightInCm: 신장 (cm)
    /// - Returns: BMI 값 (kg/m²)
    func calculateBMI(heightInCm: Decimal) -> Decimal {
        guard heightInCm > 0 else { return 0 }
        let heightInMeters = heightInCm / 100
        return weight / (heightInMeters * heightInMeters)
    }

    // MARK: - Helper Methods

    /// 체지방량 계산 (정적 메서드)
    /// 📚 학습 포인트: Static Method
    /// - 인스턴스가 없어도 호출 가능한 타입 메서드
    /// - 유틸리티 함수로 재사용 가능
    /// 💡 Java 비교: static method와 동일
    ///
    /// - Parameter weight: 체중 (kg)
    /// - Parameter bodyFatPercent: 체지방률 (%)
    /// - Returns: 체지방량 (kg)
    static func calculateBodyFatMass(weight: Decimal, bodyFatPercent: Decimal) -> Decimal {
        return weight * (bodyFatPercent / 100)
    }

    /// 근육량 계산 (정적 메서드)
    /// 제지방량의 약 50-60%가 골격근이라고 가정
    /// 📚 학습 포인트: Domain Logic
    /// - 비즈니스 규칙을 도메인 엔티티에 캡슐화
    ///
    /// - Parameter weight: 체중 (kg)
    /// - Parameter bodyFatPercent: 체지방률 (%)
    /// - Parameter muscleRatio: 제지방량 중 골격근 비율 (기본값: 0.55)
    /// - Returns: 추정 근육량 (kg)
    static func estimateMuscleMass(
        weight: Decimal,
        bodyFatPercent: Decimal,
        muscleRatio: Decimal = 0.55
    ) -> Decimal {
        let bodyFatMass = calculateBodyFatMass(weight: weight, bodyFatPercent: bodyFatPercent)
        let leanBodyMass = weight - bodyFatMass
        return leanBodyMass * muscleRatio
    }
}

// MARK: - Sample Data

extension BodyCompositionEntry {
    /// 📚 학습 포인트: Preview Helper
    /// SwiftUI Preview 및 테스트를 위한 샘플 데이터
    /// 💡 Java 비교: Test fixture와 유사
    static let sample = BodyCompositionEntry(
        weight: Decimal(70.5),
        bodyFatPercent: Decimal(18.5),
        muscleMass: Decimal(32.0),
        bodyFatMass: Decimal(13.04)
    )

    /// 다양한 시나리오를 위한 샘플 데이터 배열
    static let samples = [
        BodyCompositionEntry(
            date: Calendar.current.date(byAdding: .day, value: -7, to: Date())!,
            weight: Decimal(72.0),
            bodyFatPercent: Decimal(20.0),
            muscleMass: Decimal(31.0)
        ),
        BodyCompositionEntry(
            date: Calendar.current.date(byAdding: .day, value: -3, to: Date())!,
            weight: Decimal(71.2),
            bodyFatPercent: Decimal(19.3),
            muscleMass: Decimal(31.5)
        ),
        BodyCompositionEntry(
            date: Date(),
            weight: Decimal(70.5),
            bodyFatPercent: Decimal(18.5),
            muscleMass: Decimal(32.0)
        )
    ]
}
