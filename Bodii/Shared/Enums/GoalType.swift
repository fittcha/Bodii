//
//  GoalType.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-11.
//

// 📚 학습 포인트: Enum for Goal Type
// Swift enum으로 사용자 목표 유형을 분류하여 Goal 엔티티에서 사용
// 💡 Java 비교: enum 타입으로 목표 유형을 분류하는 것과 동일

import Foundation

// MARK: - GoalType

/// 사용자 목표 유형
/// - Core Data의 Goal 엔티티에서 Int16으로 저장
/// - 체중 감량, 유지, 증량 목표 구분
enum GoalType: Int16, CaseIterable, Codable {

    // MARK: - Cases

    /// 감량 (0)
    case lose = 0

    /// 유지 (1)
    case maintain = 1

    /// 증량 (2)
    case gain = 2

    // MARK: - Display Name

    /// 한국어 표시 이름
    /// - 사용자 인터페이스에 표시되는 텍스트
    var displayName: String {
        switch self {
        case .lose:
            return "감량"
        case .maintain:
            return "유지"
        case .gain:
            return "증량"
        }
    }
}

// MARK: - Identifiable

extension GoalType: Identifiable {
    /// SwiftUI List와 ForEach에서 사용하기 위한 ID
    /// - rawValue를 ID로 사용하여 각 케이스를 고유하게 식별
    var id: Int16 {
        rawValue
    }
}
