//
//  FoodRecord.swift
//  Bodii
//
//  Created by Auto-Claude on 2024-01-12.
//

import Foundation

/// 식단 기록 도메인 엔티티
///
/// 사용자가 섭취한 음식의 기록을 저장합니다.
/// 섭취량과 끼니 정보를 포함하며, 영양소는 자동으로 계산되어 저장됩니다.
///
/// - Note: calculatedCalories, calculatedCarbs, calculatedProtein, calculatedFat는
///         Food의 영양 정보를 기반으로 quantity에 비례하여 계산된 값입니다.
///
/// - Example:
/// ```swift
/// let foodRecord = FoodRecord(
///     id: UUID(),
///     userId: UUID(),
///     foodId: UUID(),
///     date: Date(),
///     mealType: .breakfast,
///     quantity: Decimal(1.5),
///     quantityUnit: .serving,
///     calculatedCalories: 495,
///     calculatedCarbs: Decimal(110.1),
///     calculatedProtein: Decimal(10.2),
///     calculatedFat: Decimal(3.75),
///     createdAt: Date()
/// )
/// ```
struct FoodRecord {
    // MARK: - Primary Key

    /// 고유 식별자
    let id: UUID

    // MARK: - Foreign Keys

    /// 사용자 ID
    ///
    /// User 참조
    let userId: UUID

    /// 음식 ID
    ///
    /// Food 참조
    let foodId: UUID

    // MARK: - Basic Information

    /// 섭취일
    ///
    /// 음식을 섭취한 날짜입니다.
    var date: Date

    /// 끼니 종류 (0: 아침, 1: 점심, 2: 저녁, 3: 간식)
    ///
    /// 어떤 끼니에 해당하는 음식인지 나타냅니다.
    var mealType: MealType

    // MARK: - Quantity Information

    /// 섭취량
    ///
    /// quantityUnit에 따라 인분 또는 그램 단위입니다.
    var quantity: Decimal

    /// 단위 (0: 인분, 1: g)
    ///
    /// - serving: Food의 servingSize 기준 인분
    /// - grams: 그램 단위
    var quantityUnit: QuantityUnit

    // MARK: - Calculated Nutrition

    /// 계산된 칼로리 (kcal)
    ///
    /// Food의 영양 정보를 기반으로 quantity에 비례하여 계산된 칼로리입니다.
    var calculatedCalories: Int32

    /// 계산된 탄수화물 (g)
    ///
    /// Food의 영양 정보를 기반으로 quantity에 비례하여 계산된 탄수화물입니다.
    var calculatedCarbs: Decimal

    /// 계산된 단백질 (g)
    ///
    /// Food의 영양 정보를 기반으로 quantity에 비례하여 계산된 단백질입니다.
    var calculatedProtein: Decimal

    /// 계산된 지방 (g)
    ///
    /// Food의 영양 정보를 기반으로 quantity에 비례하여 계산된 지방입니다.
    var calculatedFat: Decimal

    // MARK: - Metadata

    /// 생성일시
    let createdAt: Date
}

// MARK: - Identifiable

extension FoodRecord: Identifiable {}

// MARK: - Equatable

extension FoodRecord: Equatable {
    static func == (lhs: FoodRecord, rhs: FoodRecord) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Hashable

extension FoodRecord: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
