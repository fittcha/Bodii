//
//  SleepStatus.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-11.
//

// 📚 학습 포인트: Enum with Static Factory Method
// Swift enum에 static 메서드를 추가하여 duration 값으로부터 적절한 상태를 결정
// 💡 Java 비교: enum의 static factory method 패턴과 동일

import Foundation

// MARK: - SleepStatus

/// 수면 상태
/// - Core Data의 SleepRecord 엔티티에서 Int16으로 저장
/// - 수면 시간(분 단위)에 따라 자동으로 상태 결정
enum SleepStatus: Int16, CaseIterable, Codable {

    // MARK: - Cases

    /// 나쁨 (0) - 330분(5.5시간) 미만
    case bad = 0

    /// 보통 (1) - 330분 이상 390분 미만 (5.5-6.5시간)
    case soso = 1

    /// 좋음 (2) - 390분 이상 450분 미만 (6.5-7.5시간)
    case good = 2

    /// 매우 좋음 (3) - 450분 이상 540분 이하 (7.5-9시간)
    case excellent = 3

    /// 과수면 (4) - 540분(9시간) 초과
    case oversleep = 4

    // MARK: - Display Name

    /// 한국어 표시 이름 (이모지 포함)
    /// - 사용자 인터페이스에 표시되는 텍스트
    var displayName: String {
        switch self {
        case .bad:
            return "나쁨🔴"
        case .soso:
            return "보통🟡"
        case .good:
            return "좋음🟢"
        case .excellent:
            return "매우 좋음🔵"
        case .oversleep:
            return "과수면🟠"
        }
    }

    // MARK: - Status Determination

    /// 수면 시간(분)으로부터 수면 상태 결정
    /// - Parameter durationMinutes: 수면 시간 (분 단위)
    /// - Returns: 해당하는 수면 상태
    ///
    /// ## 기준 (분 단위)
    /// - 나쁨: 0-329분 (0-5.5시간)
    /// - 보통: 330-389분 (5.5-6.5시간)
    /// - 좋음: 390-449분 (6.5-7.5시간)
    /// - 매우 좋음: 450-540분 (7.5-9시간)
    /// - 과수면: 541분 이상 (9시간 초과)
    static func from(durationMinutes: Int) -> SleepStatus {
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
    /// SwiftUI List와 ForEach에서 사용하기 위한 ID
    /// - rawValue를 ID로 사용하여 각 케이스를 고유하게 식별
    var id: Int16 {
        rawValue
    }
}
