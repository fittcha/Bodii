//
//  FoodSource.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-11.
//

// 📚 학습 포인트: Enum for Food Data Source
// Swift enum으로 음식 데이터의 출처를 분류하여 Food 엔티티에서 사용
// 💡 Java 비교: enum 타입으로 data source를 분류하는 것과 동일

import Foundation

// MARK: - FoodSource

/// 음식 데이터 출처
/// - Core Data의 Food 엔티티에서 Int16으로 저장
/// - API 출처별 데이터 추적 및 사용자 생성 음식 구분
enum FoodSource: Int16, CaseIterable, Codable {

    // MARK: - Cases

    /// 식품의약품안전처 API (0)
    case kfdaAPI = 0

    /// 미국 농무부 API (1)
    case usdaAPI = 1

    /// 사용자 생성 (2)
    case userCreated = 2

    // MARK: - Display Name

    /// 한국어 표시 이름
    /// - 사용자 인터페이스에 표시되는 텍스트
    var displayName: String {
        switch self {
        case .kfdaAPI:
            return "식품의약품안전처"
        case .usdaAPI:
            return "미국 농무부"
        case .userCreated:
            return "사용자 생성"
        }
    }
}

// MARK: - Identifiable

extension FoodSource: Identifiable {
    /// SwiftUI List와 ForEach에서 사용하기 위한 ID
    /// - rawValue를 ID로 사용하여 각 케이스를 고유하게 식별
    var id: Int16 {
        rawValue
    }
}
