//
//  FoodWithQuantity.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-13.
//

import Foundation

/// 섭취량이 지정된 음식 모델
///
/// Food 엔티티에 사용자가 선택한 섭취량 정보를 결합한 모델입니다.
/// 섭취량에 따라 자동으로 계산된 영양 정보를 제공합니다.
///
/// **주요 용도:**
/// - 음식 검색 결과에서 사용자가 섭취량을 조정할 때
/// - FoodRecord 생성 전 미리보기 (preview)
/// - 식단 계획 및 영양소 시뮬레이션
///
/// **계산 로직:**
/// - NutritionCalculator를 사용하여 섭취량에 비례한 영양소 계산
/// - 모든 계산은 computed property로 구현되어 항상 최신 상태 유지
///
/// **Example:**
/// ```swift
/// let food = Food(
///     id: UUID(),
///     name: "현미밥",
///     calories: 330,
///     carbohydrates: 73.4,
///     protein: 6.8,
///     fat: 2.5,
///     servingSize: 210.0,
///     servingUnit: "1공기",
///     source: .governmentAPI,
///     createdAt: Date()
/// )
///
/// // 1.5인분 섭취
/// let foodWithQuantity = FoodWithQuantity(
///     food: food,
///     quantity: 1.5,
///     unit: .serving
/// )
///
/// print(foodWithQuantity.calculatedCalories)  // 495 (330 * 1.5)
/// print(foodWithQuantity.calculatedProtein)   // 10.2 (6.8 * 1.5)
///
/// // FoodRecord로 변환
/// let record = foodWithQuantity.toFoodRecord(
///     userId: currentUser.id,
///     date: Date(),
///     mealType: .breakfast
/// )
/// ```
///
/// - Note: Java의 DTO/VO 패턴과 유사하지만, Swift에서는 struct로 구현하여 불변성과 값 타입 특성 활용
struct FoodWithQuantity {
    // MARK: - Food Information

    /// 음식 정보
    ///
    /// 영양 정보의 기준이 되는 Food 엔티티입니다.
    let food: Food

    // MARK: - Quantity Information

    /// 섭취량
    ///
    /// unit에 따라 인분 또는 그램 단위입니다.
    let quantity: Decimal

    /// 섭취량 단위
    ///
    /// - `.serving`: Food의 servingSize 기준 인분
    /// - `.grams`: 그램 단위 직접 입력
    let unit: QuantityUnit

    // MARK: - Calculated Nutrition (Computed Properties)

    /// 계산된 영양 정보
    ///
    /// NutritionCalculator를 사용하여 계산된 영양소 정보를 반환합니다.
    /// 이 계산은 캐싱되지 않으므로, 자주 접근하는 경우 결과를 변수에 저장하는 것이 좋습니다.
    ///
    /// - Note: Lazy 연산 - 접근할 때마다 계산됨
    ///
    /// Example:
    /// ```swift
    /// let nutrition = foodWithQuantity.calculatedNutrition
    /// print(nutrition.calories)
    /// print(nutrition.protein)
    /// ```
    var calculatedNutrition: NutritionValues {
        NutritionCalculator.calculate(
            from: food,
            quantity: quantity,
            unit: unit
        )
    }

    /// 계산된 칼로리 (kcal)
    ///
    /// 섭취량에 비례하여 계산된 칼로리입니다.
    var calculatedCalories: Int32 {
        calculatedNutrition.calories
    }

    /// 계산된 탄수화물 (g)
    ///
    /// 섭취량에 비례하여 계산된 탄수화물입니다.
    var calculatedCarbohydrates: Decimal {
        calculatedNutrition.carbs
    }

    /// 계산된 단백질 (g)
    ///
    /// 섭취량에 비례하여 계산된 단백질입니다.
    var calculatedProtein: Decimal {
        calculatedNutrition.protein
    }

    /// 계산된 지방 (g)
    ///
    /// 섭취량에 비례하여 계산된 지방입니다.
    var calculatedFat: Decimal {
        calculatedNutrition.fat
    }

    // MARK: - Extended Nutrition (직접 계산)

    /// 섭취량 배수 계산
    private var multiplier: Decimal {
        switch unit {
        case .serving:
            return quantity
        case .grams:
            let servingSize = food.servingSize?.decimalValue ?? Decimal(100)
            guard servingSize > 0 else { return Decimal(0) }
            return quantity / servingSize
        }
    }

    /// 계산된 나트륨 (mg)
    ///
    /// 섭취량에 비례하여 계산된 나트륨입니다. (optional)
    var calculatedSodium: Decimal? {
        guard let sodium = food.sodium?.decimalValue else { return nil }
        return sodium * multiplier
    }

    /// 계산된 식이섬유 (g)
    ///
    /// 섭취량에 비례하여 계산된 식이섬유입니다. (optional)
    var calculatedFiber: Decimal? {
        guard let fiber = food.fiber?.decimalValue else { return nil }
        return fiber * multiplier
    }

    /// 계산된 당류 (g)
    ///
    /// 섭취량에 비례하여 계산된 당류입니다. (optional)
    var calculatedSugar: Decimal? {
        guard let sugar = food.sugar?.decimalValue else { return nil }
        return sugar * multiplier
    }

    // MARK: - Macro Ratios

    /// 탄수화물 비율 (%)
    ///
    /// 칼로리 기준 탄수화물 비율입니다.
    var carbsPercentage: Decimal {
        let macros = NutritionCalculator.calculateMacroRatios(
            carbs: calculatedCarbohydrates,
            protein: calculatedProtein,
            fat: calculatedFat
        )
        return macros.carbsRatio ?? Decimal(0)
    }

    /// 단백질 비율 (%)
    ///
    /// 칼로리 기준 단백질 비율입니다.
    var proteinPercentage: Decimal {
        let macros = NutritionCalculator.calculateMacroRatios(
            carbs: calculatedCarbohydrates,
            protein: calculatedProtein,
            fat: calculatedFat
        )
        return macros.proteinRatio ?? Decimal(0)
    }

    /// 지방 비율 (%)
    ///
    /// 칼로리 기준 지방 비율입니다.
    var fatPercentage: Decimal {
        let macros = NutritionCalculator.calculateMacroRatios(
            carbs: calculatedCarbohydrates,
            protein: calculatedProtein,
            fat: calculatedFat
        )
        return macros.fatRatio ?? Decimal(0)
    }
}

// MARK: - Convenience Initializers

extension FoodWithQuantity {
    /// 인분 단위로 FoodWithQuantity를 생성합니다
    ///
    /// - Parameters:
    ///   - food: 음식 정보
    ///   - servings: 인분 수
    /// - Returns: 생성된 FoodWithQuantity
    ///
    /// Example:
    /// ```swift
    /// let foodWithQuantity = FoodWithQuantity.withServings(food: food, servings: 1.5)
    /// // 1.5인분으로 생성
    /// ```
    static func withServings(food: Food, servings: Decimal) -> FoodWithQuantity {
        FoodWithQuantity(
            food: food,
            quantity: servings,
            unit: .serving
        )
    }

    /// 그램 단위로 FoodWithQuantity를 생성합니다
    ///
    /// - Parameters:
    ///   - food: 음식 정보
    ///   - grams: 그램 수
    /// - Returns: 생성된 FoodWithQuantity
    ///
    /// Example:
    /// ```swift
    /// let foodWithQuantity = FoodWithQuantity.withGrams(food: food, grams: 300)
    /// // 300g으로 생성
    /// ```
    static func withGrams(food: Food, grams: Decimal) -> FoodWithQuantity {
        FoodWithQuantity(
            food: food,
            quantity: grams,
            unit: .grams
        )
    }
}

// MARK: - FoodRecord Data
// 📚 학습 포인트: Core Data Managed Object Creation
// FoodRecord는 Core Data 엔티티이므로 struct 초기화 방식을 사용할 수 없습니다.
// FoodRecord 생성은 FoodRecordRepository를 통해 수행해야 합니다.
//
// 이 extension은 FoodRecord 생성에 필요한 데이터를 제공합니다.

extension FoodWithQuantity {
    /// FoodRecord 생성에 필요한 데이터를 반환합니다
    ///
    /// Core Data FoodRecord 생성을 위해 Repository에서 사용할 데이터입니다.
    ///
    /// - Returns: (calories: Int32, carbs: Decimal, protein: Decimal, fat: Decimal)
    var foodRecordNutritionData: (calories: Int32, carbs: Decimal, protein: Decimal, fat: Decimal) {
        let nutrition = calculatedNutrition
        return (nutrition.calories, nutrition.carbs, nutrition.protein, nutrition.fat)
    }
}

// MARK: - Identifiable

extension FoodWithQuantity: Identifiable {
    /// 고유 식별자
    ///
    /// Food의 ID를 사용합니다.
    /// - Note: 같은 Food라도 quantity가 다르면 다른 인스턴스이지만, ID는 동일합니다.
    var id: UUID {
        food.id ?? UUID()
    }
}

// MARK: - Equatable

extension FoodWithQuantity: Equatable {
    /// 두 FoodWithQuantity가 같은지 비교합니다
    ///
    /// Food, quantity, unit이 모두 같아야 같다고 판단합니다.
    static func == (lhs: FoodWithQuantity, rhs: FoodWithQuantity) -> Bool {
        lhs.food == rhs.food &&
        lhs.quantity == rhs.quantity &&
        lhs.unit == rhs.unit
    }
}

// MARK: - Hashable

extension FoodWithQuantity: Hashable {
    /// Hash 값을 계산합니다
    ///
    /// Food, quantity, unit을 모두 hash에 포함합니다.
    func hash(into hasher: inout Hasher) {
        hasher.combine(food)
        hasher.combine(quantity)
        hasher.combine(unit)
    }
}

// MARK: - Quantity Adjustment

extension FoodWithQuantity {
    /// 섭취량을 변경한 새로운 FoodWithQuantity를 반환합니다
    ///
    /// 불변(immutable) 구조체이므로 새 인스턴스를 생성하여 반환합니다.
    ///
    /// - Parameter newQuantity: 새로운 섭취량
    /// - Returns: 섭취량이 변경된 새 FoodWithQuantity
    ///
    /// Example:
    /// ```swift
    /// let original = FoodWithQuantity(food: food, quantity: 1.0, unit: .serving)
    /// let updated = original.withQuantity(1.5)
    /// // 1.0인분 → 1.5인분으로 변경
    /// ```
    func withQuantity(_ newQuantity: Decimal) -> FoodWithQuantity {
        FoodWithQuantity(
            food: food,
            quantity: newQuantity,
            unit: unit
        )
    }

    /// 섭취량 단위를 변경한 새로운 FoodWithQuantity를 반환합니다
    ///
    /// 불변(immutable) 구조체이므로 새 인스턴스를 생성하여 반환합니다.
    ///
    /// - Parameters:
    ///   - newQuantity: 새로운 섭취량
    ///   - newUnit: 새로운 단위
    /// - Returns: 섭취량과 단위가 변경된 새 FoodWithQuantity
    ///
    /// Example:
    /// ```swift
    /// let original = FoodWithQuantity(food: food, quantity: 1.0, unit: .serving)
    /// let updated = original.withQuantity(300, unit: .grams)
    /// // 1.0인분 → 300g으로 변경
    /// ```
    func withQuantity(_ newQuantity: Decimal, unit newUnit: QuantityUnit) -> FoodWithQuantity {
        FoodWithQuantity(
            food: food,
            quantity: newQuantity,
            unit: newUnit
        )
    }
}

// MARK: - Display Helpers

extension FoodWithQuantity {
    /// 섭취량을 사용자에게 표시할 형식으로 반환합니다
    ///
    /// - Returns: "1.5인분" 또는 "300g" 형식의 문자열
    ///
    /// Example:
    /// ```swift
    /// let display = foodWithQuantity.quantityDisplay
    /// // "1.5인분" 또는 "300g"
    /// ```
    var quantityDisplay: String {
        let quantityString = quantity.formatted()
        return "\(quantityString)\(unit.displayName)"
    }

    /// 음식명과 섭취량을 결합한 전체 표시 문자열을 반환합니다
    ///
    /// - Returns: "현미밥 1.5인분" 형식의 문자열
    ///
    /// Example:
    /// ```swift
    /// let display = foodWithQuantity.fullDisplay
    /// // "현미밥 1.5인분"
    /// ```
    var fullDisplay: String {
        "\(food.name ?? "알 수 없는 음식") \(quantityDisplay)"
    }
}
