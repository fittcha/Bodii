//
//  UserProfile.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-12.
//

// 📚 학습 포인트: User Profile Domain Entity
// Core Data와 독립적인 순수 도메인 엔티티
// 💡 Java 비교: POJO (Plain Old Java Object)와 유사하지만 Swift의 value type (struct) 사용

import Foundation

// MARK: - UserProfile

/// 사용자 프로필 도메인 엔티티
/// BMR/TDEE 계산에 필요한 사용자의 기본 정보를 나타냅니다.
/// 📚 학습 포인트: Clean Architecture의 Domain Layer
/// - Core Data나 다른 infrastructure 의존성이 없는 순수한 비즈니스 엔티티
/// - Decimal을 사용하여 정밀도 보장 (Double의 부동소수점 오차 방지)
/// - BMR 계산에 필수적인 정보: 신장, 나이, 성별, 활동 수준
struct UserProfile: Codable, Identifiable, Equatable {

    // MARK: - Properties

    /// 고유 식별자
    /// 📚 학습 포인트: UUID vs Int
    /// - UUID: 분산 시스템에서 충돌 없이 고유 ID 생성 가능
    /// - SwiftUI의 Identifiable 프로토콜 요구사항
    let id: UUID

    /// 신장 (cm)
    /// 📚 학습 포인트: Decimal Type
    /// - 정밀한 숫자 계산을 위해 Decimal 사용
    /// - Double 대신 Decimal을 사용하여 부동소수점 오차 방지
    /// 💡 Java 비교: java.math.BigDecimal과 유사
    /// BMR 계산 공식에서 신장은 cm 단위로 사용됨
    let height: Decimal

    /// 생년월일
    /// 📚 학습 포인트: Date Type
    /// - 시간대와 무관한 절대 시간 표현
    /// - 나이 계산 시 현재 날짜와 비교하여 정확한 만 나이 산출
    let birthDate: Date

    /// 성별
    /// 📚 학습 포인트: Enum as Property
    /// - Mifflin-St Jeor 공식에서 남성과 여성의 계수가 다름
    /// - 남성: +5, 여성: -161
    let gender: Gender

    /// 활동 수준
    /// 📚 학습 포인트: ActivityLevel Enum
    /// - TDEE 계산에 사용되는 활동 계수
    /// - sedentary(1.2) ~ extraActive(1.9)
    let activityLevel: ActivityLevel

    // MARK: - Initialization

    /// UserProfile 생성자
    /// 📚 학습 포인트: Memberwise Initializer
    /// - Struct는 기본적으로 memberwise initializer 제공
    /// - 명시적으로 작성하여 문서화 및 validation 추가 가능
    /// - Parameter id: 고유 식별자 (기본값: 새 UUID)
    /// - Parameter height: 신장 (cm)
    /// - Parameter birthDate: 생년월일
    /// - Parameter gender: 성별
    /// - Parameter activityLevel: 활동 수준
    init(
        id: UUID = UUID(),
        height: Decimal,
        birthDate: Date,
        gender: Gender,
        activityLevel: ActivityLevel
    ) {
        self.id = id
        self.height = height
        self.birthDate = birthDate
        self.gender = gender
        self.activityLevel = activityLevel
    }

    // MARK: - Computed Properties

    /// 현재 만 나이 계산
    /// 📚 학습 포인트: Computed Property
    /// - 저장되지 않고 매번 계산되는 프로퍼티
    /// - get-only property (읽기 전용)
    /// 💡 Java 비교: getter 메서드와 유사하지만 프로퍼티처럼 접근
    ///
    /// Calendar를 사용하여 생년월일과 현재 날짜의 차이를 계산
    /// BMR 계산 공식에서 나이는 만 나이(정수)로 사용됨
    var age: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year], from: birthDate, to: Date())
        return components.year ?? 0
    }

    /// 신장을 미터 단위로 변환
    /// 📚 학습 포인트: Unit Conversion
    /// - BMI나 다른 계산에서 미터 단위가 필요한 경우 사용
    /// - 1m = 100cm
    var heightInMeters: Decimal {
        return height / 100
    }

    /// 신장을 피트/인치 단위로 변환 (참고용)
    /// 📚 학습 포인트: Tuple Return Type
    /// - 여러 값을 하나의 튜플로 반환
    /// - 1cm ≈ 0.393701 inch
    /// 💡 Java 비교: 별도의 클래스를 만들어야 하지만 Swift는 튜플 사용 가능
    ///
    /// - Returns: (feet: Int, inches: Double) 형태의 튜플
    var heightInFeetAndInches: (feet: Int, inches: Double) {
        let totalInches = Double(truncating: height as NSNumber) * 0.393701
        let feet = Int(totalInches / 12)
        let inches = totalInches.truncatingRemainder(dividingBy: 12)
        return (feet: feet, inches: inches)
    }

    // MARK: - Helper Methods

    /// 특정 날짜 기준으로 나이 계산
    /// 📚 학습 포인트: Instance Method with Parameter
    /// - 과거 또는 미래의 특정 시점에서의 나이를 계산할 때 사용
    /// - 예: 과거 기록 조회 시 당시의 나이를 알고 싶을 때
    ///
    /// - Parameter date: 기준 날짜
    /// - Returns: 해당 날짜 기준 만 나이
    func age(at date: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year], from: birthDate, to: date)
        return components.year ?? 0
    }

    /// 신장을 특정 단위로 포맷팅
    /// 📚 학습 포인트: String Formatting
    /// - UI 표시를 위한 포맷팅 헬퍼 메서드
    ///
    /// - Parameter unit: 단위 문자열 (기본값: "cm")
    /// - Returns: 포맷된 신장 문자열 (예: "175.5 cm")
    func formattedHeight(unit: String = "cm") -> String {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 1

        let heightString = formatter.string(from: height as NSNumber) ?? "\(height)"
        return "\(heightString) \(unit)"
    }
}

// MARK: - Sample Data

extension UserProfile {
    /// 📚 학습 포인트: Preview Helper
    /// SwiftUI Preview 및 테스트를 위한 샘플 데이터
    /// 💡 Java 비교: Test fixture와 유사
    static let sample = UserProfile(
        height: Decimal(175.5),
        birthDate: Calendar.current.date(from: DateComponents(year: 1990, month: 6, day: 15))!,
        gender: .male,
        activityLevel: .moderatelyActive
    )

    /// 다양한 시나리오를 위한 샘플 데이터 배열
    static let samples = [
        UserProfile(
            height: Decimal(175.5),
            birthDate: Calendar.current.date(from: DateComponents(year: 1990, month: 6, day: 15))!,
            gender: .male,
            activityLevel: .moderatelyActive
        ),
        UserProfile(
            height: Decimal(162.0),
            birthDate: Calendar.current.date(from: DateComponents(year: 1995, month: 3, day: 22))!,
            gender: .female,
            activityLevel: .lightlyActive
        ),
        UserProfile(
            height: Decimal(180.0),
            birthDate: Calendar.current.date(from: DateComponents(year: 1985, month: 12, day: 8))!,
            gender: .male,
            activityLevel: .veryActive
        )
    ]
}
