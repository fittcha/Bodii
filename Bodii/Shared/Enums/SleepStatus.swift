//
//  SleepStatus.swift
//  Bodii
//
//  Created by Auto-Claude on 2024-01-12.
//

import Foundation
import SwiftUI

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

    // MARK: - Constants

    /// 수면 품질 기준 시간 (분 단위)
    /// 📚 학습 포인트: Named Constants for Business Rules
    /// - 매직 넘버를 상수로 추출하여 가독성과 유지보수성 향상
    /// - 기준 변경 시 한 곳만 수정하면 됨
    private static let BAD_THRESHOLD: Int32 = 330        // 5시간 30분
    private static let SOSO_THRESHOLD: Int32 = 390       // 6시간 30분
    private static let GOOD_THRESHOLD: Int32 = 450       // 7시간 30분
    private static let EXCELLENT_THRESHOLD: Int32 = 540  // 9시간

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

    /// 수면 상태에 해당하는 SwiftUI Color
    ///
    /// 시각적 피드백을 위한 상태별 색상을 반환합니다.
    ///
    /// - bad: 빨강 (수면 부족)
    /// - soso: 노랑 (보통)
    /// - good: 초록 (적정)
    /// - excellent: 파랑 (매우 좋음)
    /// - oversleep: 주황 (과다 수면)
    var color: Color {
        switch self {
        case .bad: return .red
        case .soso: return .yellow
        case .good: return .green
        case .excellent: return .blue
        case .oversleep: return .orange
        }
    }

    /// 수면 상태에 해당하는 SF Symbol 아이콘 이름
    ///
    /// 시각적 피드백을 위한 상태별 아이콘을 반환합니다.
    ///
    /// - bad: moon.fill (수면 부족)
    /// - soso: moon.stars (보통)
    /// - good: moon.stars.fill (적정)
    /// - excellent: sparkles (매우 좋음)
    /// - oversleep: zzz (과다 수면)
    var iconName: String {
        switch self {
        case .bad: return "moon.fill"
        case .soso: return "moon.stars"
        case .good: return "moon.stars.fill"
        case .excellent: return "sparkles"
        case .oversleep: return "zzz"
        }
    }

    /// 수면 시간(분)으로부터 수면 상태를 결정하는 팩토리 메서드
    ///
    /// - Parameter durationMinutes: 수면 시간 (분 단위)
    /// - Returns: 수면 시간에 해당하는 수면 상태
    ///
    /// 수면 상태 기준:
    /// - bad: BAD_THRESHOLD 미만 (5시간 30분 미만)
    /// - soso: BAD_THRESHOLD ~ SOSO_THRESHOLD 미만 (5시간 30분 ~ 6시간 30분)
    /// - good: SOSO_THRESHOLD ~ GOOD_THRESHOLD 미만 (6시간 30분 ~ 7시간 30분)
    /// - excellent: GOOD_THRESHOLD ~ EXCELLENT_THRESHOLD 이하 (7시간 30분 ~ 9시간)
    /// - oversleep: EXCELLENT_THRESHOLD 초과 (9시간 초과)
    static func from(durationMinutes: Int32) -> SleepStatus {
        switch durationMinutes {
        case ..<BAD_THRESHOLD:
            return .bad
        case BAD_THRESHOLD..<SOSO_THRESHOLD:
            return .soso
        case SOSO_THRESHOLD..<GOOD_THRESHOLD:
            return .good
        case GOOD_THRESHOLD...EXCELLENT_THRESHOLD:
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
