//
//  FoodSource.swift
//  Bodii
//
//  Created by Auto-Claude on 2024-01-12.
//

import Foundation

/// 식품 데이터 출처 열거형
///
/// 식품 정보의 출처를 나타냅니다.
/// Core Data 호환성을 위해 Int16 rawValue를 사용합니다.
///
/// - Cases:
///   - governmentAPI: 정부 공공 데이터 API
///   - usda: USDA 식품 데이터베이스
///   - userDefined: 사용자 정의 식품
///
/// - Example:
/// ```swift
/// let source = FoodSource.usda
/// print(source.displayName) // "USDA 데이터베이스"
/// ```
enum FoodSource: Int16, CaseIterable, Codable {
    case governmentAPI = 0
    case usda = 1
    case userDefined = 2
    case openFoodFacts = 3

    /// 사용자에게 표시할 출처 이름
    var displayName: String {
        switch self {
        case .governmentAPI: return "정부 공공 데이터 API"
        case .usda: return "USDA 데이터베이스"
        case .userDefined: return "사용자 정의"
        case .openFoodFacts: return "Open Food Facts"
        }
    }
}

// MARK: - Identifiable

extension FoodSource: Identifiable {
    var id: Int16 { rawValue }
}
