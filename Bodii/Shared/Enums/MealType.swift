//
//  MealType.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-11.
//

// 📚 학습 포인트: Enum for Meal Classification
// Swift enum으로 식사 유형을 분류하여 FoodRecord에서 사용
// 💡 Java 비교: enum 타입으로 meal type을 분류하는 것과 동일

import Foundation

// MARK: - MealType

/// 식사 유형
/// - Core Data의 FoodRecord 엔티티에서 Int16으로 저장
/// - 사용자가 섭취한 음식을 식사 시간대별로 분류
enum MealType: Int16, CaseIterable, Codable {

    // MARK: - Cases

    /// 아침 (0)
    case breakfast = 0

    /// 점심 (1)
    case lunch = 1

    /// 저녁 (2)
    case dinner = 2

    /// 간식 (3)
    case snack = 3

    // MARK: - Display Name

    /// 한국어 표시 이름
    /// - 사용자 인터페이스에 표시되는 텍스트
    var displayName: String {
        switch self {
        case .breakfast:
            return "아침"
        case .lunch:
            return "점심"
        case .dinner:
            return "저녁"
        case .snack:
            return "간식"
        }
    }
}

// MARK: - Identifiable

extension MealType: Identifiable {
    /// SwiftUI List와 ForEach에서 사용하기 위한 ID
    /// - rawValue를 ID로 사용하여 각 케이스를 고유하게 식별
    var id: Int16 {
        rawValue
    }
}
