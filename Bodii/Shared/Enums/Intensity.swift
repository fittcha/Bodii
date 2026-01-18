//
//  Intensity.swift
//  Bodii
//
//  Created by Auto-Claude on 2024-01-12.
//

import Foundation

/// 운동 강도 열거형
///
/// 운동 기록 시 운동의 강도를 나타냅니다.
/// MET 계산 시 강도 보정 계수로 사용됩니다.
/// Core Data 호환성을 위해 Int16 rawValue를 사용합니다.
///
/// - Cases:
///   - low: 저강도 (MET × 0.8)
///   - medium: 중강도 (MET × 1.0)
///   - high: 고강도 (MET × 1.2)
///
/// - Example:
/// ```swift
/// let intensity = Intensity.high
/// print(intensity.displayName) // "고강도"
/// print(intensity.metMultiplier) // 1.2
/// ```
enum Intensity: Int16, CaseIterable, Codable {
    case low = 0
    case medium = 1
    case high = 2

    /// 사용자에게 표시할 강도 이름
    var displayName: String {
        switch self {
        case .low: return "저강도"
        case .medium: return "중강도"
        case .high: return "고강도"
        }
    }

    /// MET 강도 보정 계수
    ///
    /// 기본 MET 값에 이 계수를 곱하여 실제 운동 강도를 반영합니다.
    ///
    /// - 저강도: 기본 MET × 0.8
    /// - 중강도: 기본 MET × 1.0
    /// - 고강도: 기본 MET × 1.2
    ///
    /// - Returns: 강도 보정 계수
    var metMultiplier: Double {
        switch self {
        case .low: return 0.8
        case .medium: return 1.0
        case .high: return 1.2
        }
    }
}

// MARK: - Identifiable

extension Intensity: Identifiable {
    var id: Int16 { rawValue }
}
