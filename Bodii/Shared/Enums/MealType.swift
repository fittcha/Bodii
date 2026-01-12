//
//  MealType.swift
//  Bodii
//
//  Created by Auto-Claude on 2024-01-12.
//

import Foundation

/// 끼니 종류 열거형
///
/// 식사 기록 시 어떤 끼니에 해당하는지 나타냅니다.
/// Core Data 호환성을 위해 Int16 rawValue를 사용합니다.
///
/// - Cases:
///   - breakfast: 아침
///   - lunch: 점심
///   - dinner: 저녁
///   - snack: 간식
///
/// - Example:
/// ```swift
/// let mealType = MealType.breakfast
/// print(mealType.displayName) // "아침"
/// ```
enum MealType: Int16, CaseIterable, Codable {
    case breakfast = 0
    case lunch = 1
    case dinner = 2
    case snack = 3

    /// 사용자에게 표시할 끼니 이름
    var displayName: String {
        switch self {
        case .breakfast: return "아침"
        case .lunch: return "점심"
        case .dinner: return "저녁"
        case .snack: return "간식"
        }
    }
}

// MARK: - Identifiable

extension MealType: Identifiable {
    var id: Int16 { rawValue }
}
