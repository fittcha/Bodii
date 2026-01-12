//
//  QuantityUnit.swift
//  Bodii
//
//  Created by Auto-Claude on 2024-01-12.
//

import Foundation

/// 섭취량 단위 열거형
///
/// 식품 섭취 시 수량의 단위를 나타냅니다.
/// Core Data 호환성을 위해 Int16 rawValue를 사용합니다.
///
/// - Cases:
///   - serving: 인분
///   - grams: 그램 (g)
///
/// - Example:
/// ```swift
/// let unit = QuantityUnit.serving
/// print(unit.displayName) // "인분"
/// ```
enum QuantityUnit: Int16, CaseIterable, Codable {
    case serving = 0
    case grams = 1

    /// 사용자에게 표시할 단위 이름
    var displayName: String {
        switch self {
        case .serving: return "인분"
        case .grams: return "g"
        }
    }
}

// MARK: - Identifiable

extension QuantityUnit: Identifiable {
    var id: Int16 { rawValue }
}
