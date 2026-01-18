//
//  Food.swift
//  Bodii
//
//  Created by Auto-Claude on 2024-01-12.
//

import Foundation

/// 음식 마스터 도메인 엔티티
///
/// 음식의 영양 정보를 저장하는 마스터 데이터입니다.
/// 식약처 API, USDA API, 사용자 직접 입력 등 다양한 출처에서 제공됩니다.
///
/// - Note: servingSize는 1회 제공량의 기준이 되며, 모든 영양 정보는 이 기준량에 대한 값입니다.
///
/// - Note: source가 userDefined일 경우 createdByUserId가 설정됩니다.
///
/// - Example:
/// ```swift
/// let food = Food(
///     id: UUID(),
///     name: "현미밥",
///     calories: 330,
///     carbohydrates: Decimal(73.4),
///     protein: Decimal(6.8),
///     fat: Decimal(2.5),
///     sodium: Decimal(5.0),
///     fiber: Decimal(3.0),
///     sugar: Decimal(0.5),
///     servingSize: Decimal(210.0),
///     servingUnit: "1공기",
///     source: .governmentAPI,
///     apiCode: "D000001",
///     createdByUserId: nil,
///     createdAt: Date()
/// )
/// ```
struct Food {
    // MARK: - Primary Key

    /// 고유 식별자
    let id: UUID

    // MARK: - Basic Information

    /// 음식명
    var name: String

    // MARK: - Nutrition Information

    /// 칼로리 (kcal)
    ///
    /// servingSize 기준 칼로리 정보입니다.
    var calories: Int32

    /// 탄수화물 (g)
    ///
    /// servingSize 기준 탄수화물 함량입니다.
    var carbohydrates: Decimal

    /// 단백질 (g)
    ///
    /// servingSize 기준 단백질 함량입니다.
    var protein: Decimal

    /// 지방 (g)
    ///
    /// servingSize 기준 지방 함량입니다.
    var fat: Decimal

    /// 나트륨 (mg)
    ///
    /// servingSize 기준 나트륨 함량입니다.
    var sodium: Decimal?

    /// 식이섬유 (g)
    ///
    /// servingSize 기준 식이섬유 함량입니다.
    var fiber: Decimal?

    /// 당류 (g)
    ///
    /// servingSize 기준 당류 함량입니다.
    var sugar: Decimal?

    // MARK: - Serving Information

    /// 1회 제공량 (g)
    ///
    /// 영양 정보의 기준이 되는 제공량입니다.
    var servingSize: Decimal

    /// 단위 (예: "1인분", "1개", "1공기")
    ///
    /// 사용자에게 표시할 제공량 단위입니다.
    var servingUnit: String?

    // MARK: - Source Information

    /// 출처 (0: 식약처 API, 1: USDA API, 2: 사용자 직접 입력)
    ///
    /// - 0: 식약처 API (공공데이터) - 한국 음식
    /// - 1: USDA FoodData Central - 외국 음식
    /// - 2: 사용자 직접 입력
    var source: FoodSource

    /// API 식품코드
    ///
    /// 외부 API에서 제공하는 고유 식품 코드입니다.
    /// source가 governmentAPI 또는 usda일 경우 설정됩니다.
    var apiCode: String?

    // MARK: - Foreign Key

    /// 사용자 정의 음식 생성자
    ///
    /// source가 userDefined일 경우 생성한 사용자의 ID가 설정됩니다.
    var createdByUserId: UUID?

    // MARK: - Metadata

    /// 생성일시
    let createdAt: Date
}

// MARK: - Identifiable

extension Food: Identifiable {}

// MARK: - Equatable

extension Food: Equatable {
    static func == (lhs: Food, rhs: Food) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Hashable

extension Food: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
