//
//  Gender.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-11.
//

// 📚 학습 포인트: Enum with RawValue
// Swift enum은 Int16 rawValue를 가져 Core Data의 정수 저장 타입과 매핑
// 💡 Java 비교: JPA의 @Enumerated(EnumType.ORDINAL)과 유사

import Foundation

// MARK: - Gender

/// 사용자 성별
/// - Core Data의 User 엔티티에서 Int16으로 저장
/// - 기초대사량(BMR) 계산 시 사용
enum Gender: Int16, CaseIterable, Codable {

    // MARK: - Cases

    /// 남성 (0)
    case male = 0

    /// 여성 (1)
    case female = 1

    // MARK: - Display Name

    /// 한국어 표시 이름
    /// - 사용자 인터페이스에 표시되는 텍스트
    var displayName: String {
        switch self {
        case .male:
            return "남성"
        case .female:
            return "여성"
        }
    }
}

// MARK: - Identifiable

extension Gender: Identifiable {
    /// SwiftUI List와 ForEach에서 사용하기 위한 ID
    /// - rawValue를 ID로 사용하여 각 케이스를 고유하게 식별
    var id: Int16 {
        rawValue
    }
}
