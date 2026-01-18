//
//  Gender.swift
//  Bodii
//
//  Created by Auto-Claude on 2024-01-12.
//

import Foundation

/// 성별 열거형
///
/// 사용자의 성별을 나타냅니다. Core Data 호환성을 위해 Int16 rawValue를 사용합니다.
///
/// - Cases:
///   - male: 남성
///   - female: 여성
///
/// - Example:
/// ```swift
/// let gender = Gender.male
/// print(gender.displayName) // "남성"
/// ```
enum Gender: Int16, CaseIterable, Codable {
    case male = 0
    case female = 1

    /// 사용자에게 표시할 성별 이름
    var displayName: String {
        switch self {
        case .male: return "남성"
        case .female: return "여성"
        }
    }
}

// MARK: - Identifiable

extension Gender: Identifiable {
    var id: Int16 { rawValue }
}
