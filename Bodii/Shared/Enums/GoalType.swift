//
//  GoalType.swift
//  Bodii
//
//  Created by Auto-Claude on 2024-01-12.
//

import Foundation

/// 목표 유형 열거형
///
/// 사용자의 체중 관리 목표 유형을 나타냅니다.
/// Core Data 호환성을 위해 Int16 rawValue를 사용합니다.
///
/// - Cases:
///   - lose: 감량 (체중 감소)
///   - maintain: 유지 (현재 체중 유지)
///   - gain: 증량 (체중 증가)
///
/// - Example:
/// ```swift
/// let goalType = GoalType.lose
/// print(goalType.displayName) // "감량"
/// ```
enum GoalType: Int16, CaseIterable, Codable {
    case lose = 0
    case maintain = 1
    case gain = 2

    /// 사용자에게 표시할 목표 유형 이름
    var displayName: String {
        switch self {
        case .lose: return "감량"
        case .maintain: return "유지"
        case .gain: return "증량"
        }
    }
}

// MARK: - Identifiable

extension GoalType: Identifiable {
    var id: Int16 { rawValue }
}
