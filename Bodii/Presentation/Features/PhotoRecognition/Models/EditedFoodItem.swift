//
//  EditedFoodItem.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-17.
//

// 📚 학습 포인트: Edited Food Item Model
// FoodMatch와 사용자가 편집한 수량/단위 정보를 함께 저장하는 모델
// 💡 최종 저장 전에 계산된 영양 정보를 포함합니다.

import Foundation

/// 편집된 음식 항목
///
/// 📚 학습 포인트: Edited Food Item with Quantities
/// FoodMatch와 사용자가 편집한 수량/단위 정보를 함께 저장하는 모델
///
/// - Note: 최종 저장 전에 계산된 영양 정보를 포함합니다.
struct EditedFoodItem: Identifiable {

    // MARK: - Properties

    /// 고유 ID
    let id: UUID

    /// 음식 매칭 정보
    let match: FoodMatch

    /// 섭취 수량
    let quantity: Decimal

    /// 수량 단위
    let unit: QuantityUnit

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        match: FoodMatch,
        quantity: Decimal = 1.0,
        unit: QuantityUnit = .serving
    ) {
        self.id = id
        self.match = match
        self.quantity = quantity
        self.unit = unit
    }

    // MARK: - Computed Properties

    /// 배수 (인분 또는 그램 기준)
    ///
    /// 📚 학습 포인트: Quantity Multiplier Calculation
    /// 수량 단위에 따라 영양 정보 계산을 위한 배수를 구합니다.
    private var multiplier: Decimal {
        if let gramsPerUnit = unit.gramsPerUnit {
            let servingSize = match.food.servingSize?.decimalValue ?? Decimal(100)
            guard servingSize > 0 else { return quantity }
            let totalGrams = quantity * gramsPerUnit
            return totalGrams / servingSize
        } else {
            // serving, piece: 수량 그대로 사용
            return quantity
        }
    }

    /// 계산된 칼로리
    var calculatedCalories: String {
        let calories = Decimal(match.food.calories) * multiplier
        return formattedDecimal(calories)
    }

    /// 계산된 탄수화물
    var calculatedCarbohydrates: String {
        let carbs = (match.food.carbohydrates?.decimalValue ?? Decimal(0)) * multiplier
        return formattedDecimal(carbs)
    }

    /// 계산된 단백질
    var calculatedProtein: String {
        let protein = (match.food.protein?.decimalValue ?? Decimal(0)) * multiplier
        return formattedDecimal(protein)
    }

    /// 계산된 지방
    var calculatedFat: String {
        let fat = (match.food.fat?.decimalValue ?? Decimal(0)) * multiplier
        return formattedDecimal(fat)
    }

    // MARK: - Helpers

    /// Decimal 값을 포맷팅
    private func formattedDecimal(_ value: Decimal) -> String {
        let nsDecimal = value as NSDecimalNumber
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 0
        return formatter.string(from: nsDecimal) ?? "0"
    }
}
