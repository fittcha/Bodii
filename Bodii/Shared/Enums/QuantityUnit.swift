//
//  QuantityUnit.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-11.
//

// 📚 학습 포인트: Enum for Quantity Units
// Swift enum으로 음식 수량 단위를 정의하여 Food 및 FoodRecord에서 사용
// 💡 Java 비교: enum 타입으로 측정 단위를 관리하는 것과 동일

import Foundation

// MARK: - QuantityUnit

/// 음식 수량 단위
/// - Core Data의 Food 및 FoodRecord 엔티티에서 Int16으로 저장
/// - 음식 섭취량을 인분 또는 그램 단위로 기록
enum QuantityUnit: Int16, CaseIterable, Codable {

    // MARK: - Cases

    /// 인분 (0)
    case serving = 0

    /// 그램 (1)
    case gram = 1

    // MARK: - Display Name

    /// 한국어 표시 이름
    /// - 사용자 인터페이스에 표시되는 텍스트
    var displayName: String {
        switch self {
        case .serving:
            return "인분"
        case .gram:
            return "그램"
        }
    }
}

// MARK: - Identifiable

extension QuantityUnit: Identifiable {
    /// SwiftUI List와 ForEach에서 사용하기 위한 ID
    /// - rawValue를 ID로 사용하여 각 케이스를 고유하게 식별
    var id: Int16 {
        rawValue
    }
}
