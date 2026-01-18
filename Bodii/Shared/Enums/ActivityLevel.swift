//
//  ActivityLevel.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-11.
//

// 📚 학습 포인트: Enum with Computed Properties
// Swift enum은 stored property를 가질 수 없지만 computed property는 가능
// 💡 Java 비교: enum의 final 필드와 유사하지만 Swift는 computed property로 구현

import Foundation

// MARK: - ActivityLevel

/// 사용자 활동 수준
/// - Core Data의 User 엔티티에서 Int16으로 저장
/// - TDEE(일일 총 에너지 소비량) 계산 시 BMR에 곱할 계수 제공
enum ActivityLevel: Int16, CaseIterable, Codable {

    // MARK: - Cases

    /// 거의 활동 없음 (1) - 주로 앉아서 생활, 운동 거의 안함
    case sedentary = 1

    /// 가벼운 활동 (2) - 주 1-3회 가벼운 운동
    case light = 2

    /// 보통 활동 (3) - 주 3-5회 중간 강도 운동
    case moderate = 3

    /// 활발한 활동 (4) - 주 6-7회 고강도 운동
    case active = 4

    /// 매우 활발한 활동 (5) - 하루 2회 운동 또는 육체 노동
    case veryActive = 5

    // MARK: - Display Name

    /// 한국어 표시 이름
    /// - 사용자 인터페이스에 표시되는 텍스트
    var displayName: String {
        switch self {
        case .sedentary:
            return "거의 활동 없음"
        case .light:
            return "가벼운 활동"
        case .moderate:
            return "보통 활동"
        case .active:
            return "활발한 활동"
        case .veryActive:
            return "매우 활발한 활동"
        }
    }

    // MARK: - TDEE Multiplier

    /// TDEE 계산용 활동 계수
    /// - TDEE = BMR × multiplier
    /// - Returns: 활동 수준에 따른 TDEE 계수
    var multiplier: Double {
        switch self {
        case .sedentary:
            return 1.2      // 거의 활동 없음
        case .light:
            return 1.375    // 가벼운 활동
        case .moderate:
            return 1.55     // 보통 활동
        case .active:
            return 1.725    // 활발한 활동
        case .veryActive:
            return 1.9      // 매우 활발한 활동
        }
    }
}

// MARK: - Identifiable

extension ActivityLevel: Identifiable {
    /// SwiftUI List와 ForEach에서 사용하기 위한 ID
    /// - rawValue를 ID로 사용하여 각 케이스를 고유하게 식별
    var id: Int16 {
        rawValue
    }
}
