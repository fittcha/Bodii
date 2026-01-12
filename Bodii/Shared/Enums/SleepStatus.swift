//
//  SleepStatus.swift
//  Bodii
//
//  Created by Auto-Claude on 2024-01-12.
//

import Foundation

/// 수면 상태 열거형
///
/// 수면 시간(분)에 따른 수면 품질 상태를 나타냅니다.
/// Core Data 호환성을 위해 Int16 rawValue를 사용합니다.
///
/// - Cases:
///   - bad: 나쁨 (5시간 30분 미만)
///   - soso: 보통 (5시간 30분 ~ 6시간 30분)
///   - good: 좋음 (6시간 30분 ~ 7시간 30분)
///   - excellent: 매우 좋음 (7시간 30분 ~ 9시간)
///   - oversleep: 과다 수면 (9시간 초과)
///
/// - Example:
/// ```swift
/// let status = SleepStatus.from(durationMinutes: 420) // 7시간
/// print(status.displayName) // "좋음"
/// ```
enum SleepStatus: Int16, CaseIterable, Codable {
    case bad = 0
    case soso = 1
    case good = 2
    case excellent = 3
    case oversleep = 4

    /// 사용자에게 표시할 수면 상태 이름
    var displayName: String {
        switch self {
        case .bad: return "나쁨"
        case .soso: return "보통"
        case .good: return "좋음"
        case .excellent: return "매우 좋음"
        case .oversleep: return "과다 수면"
        }
    }

    /// 수면 시간(분)으로부터 수면 상태를 결정하는 팩토리 메서드
    ///
    /// - Parameter durationMinutes: 수면 시간 (분 단위)
    /// - Returns: 수면 시간에 해당하는 수면 상태
    ///
    /// 수면 상태 기준:
    /// - bad: 330분 미만 (5시간 30분 미만)
    /// - soso: 330분 ~ 390분 미만 (5시간 30분 ~ 6시간 30분)
    /// - good: 390분 ~ 450분 미만 (6시간 30분 ~ 7시간 30분)
    /// - excellent: 450분 ~ 540분 이하 (7시간 30분 ~ 9시간)
    /// - oversleep: 540분 초과 (9시간 초과)
    static func from(durationMinutes: Int32) -> SleepStatus {
        switch durationMinutes {
        case ..<330:
            return .bad
        case 330..<390:
            return .soso
        case 390..<450:
            return .good
        case 450...540:
            return .excellent
        default:
            return .oversleep
        }
    }
}

// MARK: - Identifiable

extension SleepStatus: Identifiable {
    var id: Int16 { rawValue }
}
