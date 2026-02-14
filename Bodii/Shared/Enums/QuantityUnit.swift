//
//  QuantityUnit.swift
//  Bodii
//
//  Created by Auto-Claude on 2024-01-12.
//

import Foundation

/// 섭취량 단위 열거형
///
/// 식품 섭취 시 수량의 단위를 나타냅니다.
/// Core Data 호환성을 위해 Int16 rawValue를 사용합니다.
///
/// - Cases:
///   - serving: 인분
///   - grams: 그램 (g)
///   - tablespoon: 큰술 (Ts) - 약 15g
///   - teaspoon: 작은술 (ts) - 약 5g
///   - ml: 밀리리터 (ml) - 약 1g (물 기준)
///   - piece: 개
///   - cup: 컵 - 약 240g
enum QuantityUnit: Int16, CaseIterable, Codable {
    case serving = 0
    case grams = 1
    case tablespoon = 2
    case teaspoon = 3
    case ml = 4
    case piece = 5
    case cup = 6
    case pack = 7       // 봉지/팩
    case can = 8        // 캔
    case bottle = 9     // 병
    case slice = 10     // 조각/쪽
    case plate = 11     // 접시
    case bowl = 12      // 공기/그릇

    /// 사용자에게 표시할 단위 이름
    var displayName: String {
        switch self {
        case .serving: return "인분"
        case .grams: return "g"
        case .tablespoon: return "큰술"
        case .teaspoon: return "작은술"
        case .ml: return "ml"
        case .piece: return "개"
        case .cup: return "컵"
        case .pack: return "봉지"
        case .can: return "캔"
        case .bottle: return "병"
        case .slice: return "조각"
        case .plate: return "접시"
        case .bowl: return "공기"
        }
    }

    /// 단위당 그램 환산값 (nil이면 그램 환산 불가 - 개수 기반 단위)
    ///
    /// 영양소 계산 시 그램으로 변환하여 servingSize 기반 비례 계산에 사용합니다.
    var gramsPerUnit: Decimal? {
        switch self {
        case .serving, .piece, .pack, .can, .bottle, .slice, .plate, .bowl:
            return nil // 개수 기반 단위는 직접 곱셈
        case .grams:
            return Decimal(1)
        case .tablespoon:
            return Decimal(15)
        case .teaspoon:
            return Decimal(5)
        case .ml:
            return Decimal(1)
        case .cup:
            return Decimal(240)
        }
    }

    /// 이 단위가 그램 기반인지 여부 (인분/개수 기반이 아닌 경우)
    var isGramBased: Bool {
        gramsPerUnit != nil
    }
}

// MARK: - Identifiable

extension QuantityUnit: Identifiable {
    var id: Int16 { rawValue }
}
