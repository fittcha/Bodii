//
//  ActivityLevel.swift
//  Bodii
//
//  Created by Auto-Claude on 2024-01-12.
//

import Foundation

/// 활동 수준 열거형
///
/// 사용자의 일상 활동 수준을 나타냅니다. TDEE 계산 시 사용됩니다.
/// Core Data 호환성을 위해 Int16 rawValue를 사용합니다.
///
/// - Cases:
///   - sedentary: 비활동적 (좌식 생활, 운동 안 함)
///   - lightlyActive: 가벼운 활동 (주 1-3일 가벼운 운동)
///   - moderatelyActive: 보통 활동 (주 3-5일 적당한 운동)
///   - veryActive: 활동적 (주 6-7일 강한 운동)
///   - extraActive: 매우 활동적 (하루 2회 운동, 육체 노동)
///
/// - Example:
/// ```swift
/// let level = ActivityLevel.moderatelyActive
/// print(level.displayName) // "보통 활동"
/// print(level.tdeeMultiplier) // 1.55
/// ```
enum ActivityLevel: Int16, CaseIterable, Codable {
    case sedentary = 0
    case lightlyActive = 1
    case moderatelyActive = 2
    case veryActive = 3
    case extraActive = 4

    /// 사용자에게 표시할 활동 수준 이름
    var displayName: String {
        switch self {
        case .sedentary: return "비활동적"
        case .lightlyActive: return "가벼운 활동"
        case .moderatelyActive: return "보통 활동"
        case .veryActive: return "활동적"
        case .extraActive: return "매우 활동적"
        }
    }

    /// TDEE 계산용 활동 계수
    ///
    /// BMR에 이 계수를 곱하여 일일 총 에너지 소비량(TDEE)을 계산합니다.
    ///
    /// - Returns: 활동 수준에 따른 TDEE 승수
    var tdeeMultiplier: Double {
        switch self {
        case .sedentary: return 1.2
        case .lightlyActive: return 1.375
        case .moderatelyActive: return 1.55
        case .veryActive: return 1.725
        case .extraActive: return 1.9
        }
    }
}

// MARK: - Identifiable

extension ActivityLevel: Identifiable {
    var id: Int16 { rawValue }
}
