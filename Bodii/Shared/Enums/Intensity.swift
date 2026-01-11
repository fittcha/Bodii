//
//  Intensity.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-11.
//

// 📚 학습 포인트: Enum for Exercise Intensity
// Swift enum으로 운동 강도를 분류하여 ExerciseRecord에서 사용
// 💡 Java 비교: enum 타입으로 intensity level을 분류하는 것과 동일

import Foundation

// MARK: - Intensity

/// 운동 강도
/// - Core Data의 ExerciseRecord 엔티티에서 Int16으로 저장
/// - ExerciseType의 MET 값 계산 시 사용
enum Intensity: Int16, CaseIterable, Codable {

    // MARK: - Cases

    /// 낮음 (0)
    case low = 0

    /// 보통 (1)
    case medium = 1

    /// 높음 (2)
    case high = 2

    // MARK: - Display Name

    /// 한국어 표시 이름
    /// - 사용자 인터페이스에 표시되는 텍스트
    var displayName: String {
        switch self {
        case .low:
            return "낮음"
        case .medium:
            return "보통"
        case .high:
            return "높음"
        }
    }
}

// MARK: - Identifiable

extension Intensity: Identifiable {
    /// SwiftUI List와 ForEach에서 사용하기 위한 ID
    /// - rawValue를 ID로 사용하여 각 케이스를 고유하게 식별
    var id: Int16 {
        rawValue
    }
}
