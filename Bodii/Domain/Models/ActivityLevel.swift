//
//  ActivityLevel.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-12.
//

// 📚 학습 포인트: Activity Level Enumeration
// 사용자의 활동 수준을 나타내는 enum with associated TDEE multipliers
// 💡 Java 비교: enum with properties와 유사하지만 Swift는 computed property 사용

import Foundation

// MARK: - ActivityLevel

/// 사용자의 일상 활동 수준
/// TDEE(Total Daily Energy Expenditure) 계산에 사용되는 활동 계수
enum ActivityLevel: Int16, CaseIterable, Codable {

    // MARK: - Cases

    /// 거의 운동하지 않음 (주로 앉아서 생활)
    case sedentary = 0

    /// 가벼운 활동 (주 1-3일 가벼운 운동)
    case lightlyActive = 1

    /// 보통 활동 (주 3-5일 중간 강도 운동)
    case moderatelyActive = 2

    /// 매우 활동적 (주 6-7일 강한 운동)
    case veryActive = 3

    /// 극도로 활동적 (하루 2회 이상 매우 강한 운동 또는 육체 노동)
    case extraActive = 4

    // MARK: - Properties

    /// TDEE 계산을 위한 활동 계수
    /// 📚 학습 포인트: Computed Property
    /// 각 케이스에 대응하는 multiplier 값을 반환
    /// 💡 Java 비교: getter 메서드와 유사하지만 프로퍼티처럼 접근
    var multiplier: Double {
        switch self {
        case .sedentary:
            return 1.2
        case .lightlyActive:
            return 1.375
        case .moderatelyActive:
            return 1.55
        case .veryActive:
            return 1.725
        case .extraActive:
            return 1.9
        }
    }

    /// 활동 수준의 표시 이름
    /// 📚 학습 포인트: Localization 고려
    /// 향후 NSLocalizedString으로 교체 가능
    var displayName: String {
        switch self {
        case .sedentary:
            return "Sedentary"
        case .lightlyActive:
            return "Lightly Active"
        case .moderatelyActive:
            return "Moderately Active"
        case .veryActive:
            return "Very Active"
        case .extraActive:
            return "Extra Active"
        }
    }

    /// 활동 수준에 대한 설명
    /// 사용자가 자신의 활동 수준을 선택할 때 참고할 수 있는 설명
    var description: String {
        switch self {
        case .sedentary:
            return "Little or no exercise, desk job"
        case .lightlyActive:
            return "Light exercise 1-3 days per week"
        case .moderatelyActive:
            return "Moderate exercise 3-5 days per week"
        case .veryActive:
            return "Hard exercise 6-7 days per week"
        case .extraActive:
            return "Very hard exercise twice per day, or physical job"
        }
    }
}

// MARK: - Identifiable

/// 📚 학습 포인트: Identifiable Protocol
/// SwiftUI의 ForEach 등에서 사용하기 위한 고유 식별자 제공
/// 💡 Java 비교: equals/hashCode 메서드와 유사한 역할
extension ActivityLevel: Identifiable {
    var id: Int16 {
        rawValue
    }
}
