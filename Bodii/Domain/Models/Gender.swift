//
//  Gender.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-12.
//

// 📚 학습 포인트: Gender Enumeration
// 사용자의 성별을 나타내는 enum for BMR 계산
// 💡 Java 비교: enum with properties와 유사하지만 Swift는 computed property 사용

import Foundation

// MARK: - Gender

/// 사용자의 성별
/// BMR(Basal Metabolic Rate) 계산에 사용되는 성별 구분
/// Mifflin-St Jeor 공식에서 남성과 여성의 계수가 다름
enum Gender: Int16, CaseIterable, Codable {

    // MARK: - Cases

    /// 남성
    case male = 0

    /// 여성
    case female = 1

    // MARK: - Properties

    /// 성별의 표시 이름
    /// 📚 학습 포인트: Localization 고려
    /// 향후 NSLocalizedString으로 교체 가능
    var displayName: String {
        switch self {
        case .male:
            return "Male"
        case .female:
            return "Female"
        }
    }

    /// BMR 계산을 위한 성별 계수
    /// 📚 학습 포인트: Mifflin-St Jeor Formula
    /// 남성: BMR = (10 × weight) + (6.25 × height) - (5 × age) + 5
    /// 여성: BMR = (10 × weight) + (6.25 × height) - (5 × age) - 161
    /// 💡 이 계수는 최종 단계에서 더하거나 빼는 값
    var bmrAdjustment: Double {
        switch self {
        case .male:
            return 5.0
        case .female:
            return -161.0
        }
    }

    /// 운동 칼로리 계산을 위한 성별 보정 계수
    /// 📚 학습 포인트: Gender-based Exercise Calorie Adjustment
    /// - 여성은 일반적으로 남성보다 근육량이 적고 체지방률이 높아
    ///   동일한 운동에서 약 10% 적은 칼로리를 소모합니다.
    /// - 참고: ACSM (American College of Sports Medicine) 가이드라인
    var exerciseCalorieMultiplier: Double {
        switch self {
        case .male:
            return 1.0
        case .female:
            return 0.9
        }
    }
}

// MARK: - Identifiable

/// 📚 학습 포인트: Identifiable Protocol
/// SwiftUI의 ForEach 등에서 사용하기 위한 고유 식별자 제공
/// 💡 Java 비교: equals/hashCode 메서드와 유사한 역할
extension Gender: Identifiable {
    var id: Int16 {
        rawValue
    }
}
