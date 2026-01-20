//
//  NutritionCalculator.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-13.
//

import Foundation

/// 영양소 계산 결과
///
/// 계산된 영양소 값을 담는 구조체입니다.
///
/// - Example:
/// ```swift
/// let nutrition = NutritionValues(
///     calories: 330,
///     carbs: Decimal(73.4),
///     protein: Decimal(6.8),
///     fat: Decimal(2.5)
/// )
/// ```
struct NutritionValues {
    /// 칼로리 (kcal)
    let calories: Int32

    /// 탄수화물 (g)
    let carbs: Decimal

    /// 단백질 (g)
    let protein: Decimal

    /// 지방 (g)
    let fat: Decimal
}

/// 계산된 영양소 결과 (확장 버전)
///
/// FoodWithQuantity에서 사용하는 영양소 계산 결과 구조체입니다.
/// NutritionValues보다 더 많은 영양소 정보를 포함합니다.
///
/// - Example:
/// ```swift
/// let nutrition = CalculatedNutrition(
///     calories: 330,
///     carbohydrates: Decimal(73.4),
///     protein: Decimal(6.8),
///     fat: Decimal(2.5),
///     sodium: Decimal(10),
///     fiber: Decimal(3.5)
/// )
/// ```
struct CalculatedNutrition {
    /// 칼로리 (kcal)
    let calories: Int32

    /// 탄수화물 (g)
    let carbohydrates: Decimal

    /// 단백질 (g)
    let protein: Decimal

    /// 지방 (g)
    let fat: Decimal

    /// 나트륨 (mg, optional)
    let sodium: Decimal?

    /// 식이섬유 (g, optional)
    let fiber: Decimal?

    /// 당류 (g, optional)
    let sugar: Decimal?
}

/// 매크로 영양소 비율
///
/// 탄수화물, 단백질, 지방의 비율을 담는 구조체입니다.
/// 각 값은 백분율(%)로 표현되며, 합계는 100%입니다.
///
/// - Example:
/// ```swift
/// let ratios = MacroRatios(
///     carbsRatio: Decimal(40.0),
///     proteinRatio: Decimal(30.0),
///     fatRatio: Decimal(30.0)
/// )
/// ```
struct MacroRatios {
    /// 탄수화물 비율 (%)
    let carbsRatio: Decimal?

    /// 단백질 비율 (%)
    let proteinRatio: Decimal?

    /// 지방 비율 (%)
    let fatRatio: Decimal?
}

/// 영양소 계산 유틸리티
///
/// Food의 영양 정보를 기반으로 실제 섭취량의 영양소를 계산합니다.
/// 인분 단위와 그램 단위를 모두 지원하며, 매크로 비율 계산도 제공합니다.
///
/// - Note: 이 유틸리티는 stateless하며 모든 메서드는 static입니다.
/// - Note: 영양소 정보는 Food의 servingSize를 기준으로 계산됩니다.
///
/// ## 사용 예시
/// ```swift
/// // 인분 단위 계산
/// let food = Food(name: "현미밥", calories: 330, servingSize: 210, ...)
/// let nutrition = NutritionCalculator.calculateNutrition(
///     food: food,
///     quantity: 1.5,
///     unit: .serving
/// )
/// // nutrition.calories = 495 (330 * 1.5)
///
/// // 그램 단위 계산
/// let nutrition2 = NutritionCalculator.calculateNutrition(
///     food: food,
///     quantity: 105,  // 반공기 (210g의 절반)
///     unit: .grams
/// )
/// // nutrition2.calories = 165 (330 * 0.5)
///
/// // 매크로 비율 계산
/// let ratios = NutritionCalculator.calculateMacroRatios(
///     carbs: 100,
///     protein: 50,
///     fat: 30
/// )
/// // ratios.carbsRatio = 50.0%
/// // ratios.proteinRatio = 25.0%
/// // ratios.fatRatio = 25.0%
/// ```
enum NutritionCalculator {

    // MARK: - Nutrition Calculation

    /// Food 정보와 섭취량을 기반으로 실제 영양소 값을 계산합니다.
    ///
    /// Food의 영양소 정보는 servingSize 기준이며, 이를 기준으로 섭취량에 비례하여 계산합니다.
    ///
    /// ## 계산 방식
    ///
    /// **인분 단위 (.serving):**
    /// ```
    /// multiplier = quantity
    /// 예) quantity=1.5 → 1.5인분
    /// ```
    ///
    /// **그램 단위 (.grams):**
    /// ```
    /// multiplier = quantity / servingSize
    /// 예) quantity=105g, servingSize=210g → 0.5인분
    /// ```
    ///
    /// **영양소 계산:**
    /// ```
    /// calories = food.calories * multiplier
    /// carbs = food.carbohydrates * multiplier
    /// protein = food.protein * multiplier
    /// fat = food.fat * multiplier
    /// ```
    ///
    /// - Parameters:
    ///   - food: 음식 정보
    ///   - quantity: 섭취량 (unit에 따라 인분 또는 그램)
    ///   - unit: 섭취량 단위
    /// - Returns: 계산된 영양소 값
    ///
    /// - Example:
    /// ```swift
    /// let food = Food(
    ///     name: "현미밥",
    ///     calories: 330,
    ///     carbohydrates: 73.4,
    ///     protein: 6.8,
    ///     fat: 2.5,
    ///     servingSize: 210  // 1공기 = 210g
    /// )
    ///
    /// // 0.5인분
    /// let half = NutritionCalculator.calculateNutrition(
    ///     food: food,
    ///     quantity: 0.5,
    ///     unit: .serving
    /// )
    /// // half.calories = 165
    /// // half.carbs = 36.7
    ///
    /// // 105g (실제로는 0.5인분)
    /// let halfGrams = NutritionCalculator.calculateNutrition(
    ///     food: food,
    ///     quantity: 105,
    ///     unit: .grams
    /// )
    /// // halfGrams.calories = 165 (same as above)
    /// ```
    static func calculateNutrition(
        food: Food,
        quantity: Decimal,
        unit: QuantityUnit
    ) -> NutritionValues {
        // Food의 영양소는 servingSize 기준
        let multiplier: Decimal

        switch unit {
        case .serving:
            // 인분 단위: quantity는 인분 수
            // 예) quantity=1.5 → 1.5인분
            multiplier = quantity

        case .grams:
            // 그램 단위: quantity는 그램 수, servingSize로 나누어 인분 수 계산
            // 예) quantity=105g, servingSize=210g → 0.5인분
            multiplier = quantity / food.servingSize
        }

        // 영양소 계산 (비례)
        let calories = Int32((Decimal(food.calories) * multiplier).rounded())
        let carbs = food.carbohydrates * multiplier
        let protein = food.protein * multiplier
        let fat = food.fat * multiplier

        return NutritionValues(
            calories: calories,
            carbs: carbs,
            protein: protein,
            fat: fat
        )
    }

    /// Food 정보와 섭취량을 기반으로 확장된 영양소 값을 계산합니다.
    ///
    /// FoodWithQuantity에서 사용하는 메서드입니다.
    /// calculateNutrition과 동일하지만 나트륨, 식이섬유, 당류도 포함합니다.
    ///
    /// - Parameters:
    ///   - from: 음식 정보
    ///   - quantity: 섭취량 (unit에 따라 인분 또는 그램)
    ///   - unit: 섭취량 단위
    /// - Returns: 계산된 영양소 값 (확장)
    static func calculate(
        from food: Food,
        quantity: Decimal,
        unit: QuantityUnit
    ) -> CalculatedNutrition {
        // Food의 영양소는 servingSize 기준
        let multiplier: Decimal

        switch unit {
        case .serving:
            multiplier = quantity
        case .grams:
            let servingSize = food.servingSize as Decimal? ?? Decimal(100)
            multiplier = servingSize > 0 ? quantity / servingSize : Decimal(0)
        }

        // 영양소 계산 (비례)
        let calories = Int32((Decimal(food.calories) * multiplier).rounded0)
        let carbohydrates = (food.carbohydrates as Decimal? ?? Decimal(0)) * multiplier
        let protein = (food.protein as Decimal? ?? Decimal(0)) * multiplier
        let fat = (food.fat as Decimal? ?? Decimal(0)) * multiplier

        // Optional 영양소 계산
        let sodium: Decimal? = (food.sodium as Decimal?).map { $0 * multiplier }
        let fiber: Decimal? = (food.fiber as Decimal?).map { $0 * multiplier }
        let sugar: Decimal? = (food.sugar as Decimal?).map { $0 * multiplier }

        return CalculatedNutrition(
            calories: calories,
            carbohydrates: carbohydrates,
            protein: protein,
            fat: fat,
            sodium: sodium,
            fiber: fiber,
            sugar: sugar
        )
    }

    // MARK: - Macro Ratio Calculation

    /// 매크로 영양소 비율을 계산합니다.
    ///
    /// 각 영양소의 칼로리를 계산하여 전체 칼로리 대비 비율을 구합니다.
    ///
    /// ## 칼로리 변환 계수
    /// - 탄수화물: 1g = 4 kcal
    /// - 단백질: 1g = 4 kcal
    /// - 지방: 1g = 9 kcal
    ///
    /// ## 계산 공식
    /// ```
    /// carbsCalories = carbs(g) × 4
    /// proteinCalories = protein(g) × 4
    /// fatCalories = fat(g) × 9
    /// totalCalories = carbsCalories + proteinCalories + fatCalories
    ///
    /// carbsRatio = (carbsCalories / totalCalories) × 100
    /// proteinRatio = (proteinCalories / totalCalories) × 100
    /// fatRatio = (fatCalories / totalCalories) × 100
    /// ```
    ///
    /// - Parameters:
    ///   - carbs: 탄수화물 (g)
    ///   - protein: 단백질 (g)
    ///   - fat: 지방 (g)
    /// - Returns: 각 영양소의 비율 (%) 또는 nil (총 칼로리가 0인 경우)
    ///
    /// - Example:
    /// ```swift
    /// // 하루 식단: 탄수화물 300g, 단백질 150g, 지방 67g
    /// let ratios = NutritionCalculator.calculateMacroRatios(
    ///     carbs: 300,    // 300g × 4 = 1200 kcal
    ///     protein: 150,  // 150g × 4 = 600 kcal
    ///     fat: 67        // 67g × 9 = 603 kcal
    /// )
    /// // 총 칼로리 = 2403 kcal
    /// // ratios.carbsRatio = 49.94% (1200 / 2403)
    /// // ratios.proteinRatio = 24.97% (600 / 2403)
    /// // ratios.fatRatio = 25.09% (603 / 2403)
    ///
    /// // 영양소가 없는 경우
    /// let emptyRatios = NutritionCalculator.calculateMacroRatios(
    ///     carbs: 0,
    ///     protein: 0,
    ///     fat: 0
    /// )
    /// // emptyRatios.carbsRatio = nil
    /// // emptyRatios.proteinRatio = nil
    /// // emptyRatios.fatRatio = nil
    /// ```
    static func calculateMacroRatios(
        carbs: Decimal,
        protein: Decimal,
        fat: Decimal
    ) -> MacroRatios {
        // 각 영양소의 칼로리 계산
        // 탄수화물: 1g = 4 kcal
        // 단백질: 1g = 4 kcal
        // 지방: 1g = 9 kcal
        let carbsCalories = carbs * 4
        let proteinCalories = protein * 4
        let fatCalories = fat * 9

        let totalCalories = carbsCalories + proteinCalories + fatCalories

        // 총 칼로리가 0이면 비율을 계산할 수 없음
        guard totalCalories > 0 else {
            return MacroRatios(carbsRatio: nil, proteinRatio: nil, fatRatio: nil)
        }

        // 비율 계산 (백분율)
        let carbsRatio = (carbsCalories / totalCalories * 100).rounded(2)
        let proteinRatio = (proteinCalories / totalCalories * 100).rounded(2)
        let fatRatio = (fatCalories / totalCalories * 100).rounded(2)

        return MacroRatios(
            carbsRatio: carbsRatio,
            proteinRatio: proteinRatio,
            fatRatio: fatRatio
        )
    }

    // MARK: - Serving Conversion

    /// 그램을 인분으로 변환합니다.
    ///
    /// - Parameters:
    ///   - grams: 그램 수
    ///   - servingSize: 1인분 그램 수
    /// - Returns: 인분 수
    ///
    /// - Example:
    /// ```swift
    /// // 현미밥 1공기 = 210g
    /// let servings = NutritionCalculator.gramsToServings(
    ///     grams: 105,
    ///     servingSize: 210
    /// )
    /// // servings = 0.5
    /// ```
    static func gramsToServings(grams: Decimal, servingSize: Decimal) -> Decimal {
        guard servingSize > 0 else { return 0 }
        return grams / servingSize
    }

    /// 인분을 그램으로 변환합니다.
    ///
    /// - Parameters:
    ///   - servings: 인분 수
    ///   - servingSize: 1인분 그램 수
    /// - Returns: 그램 수
    ///
    /// - Example:
    /// ```swift
    /// // 현미밥 1공기 = 210g
    /// let grams = NutritionCalculator.servingsToGrams(
    ///     servings: 1.5,
    ///     servingSize: 210
    /// )
    /// // grams = 315
    /// ```
    static func servingsToGrams(servings: Decimal, servingSize: Decimal) -> Decimal {
        return servings * servingSize
    }
}

// MARK: - Decimal Extensions

/// Decimal 소수점 반올림을 위한 확장
extension Decimal {
    /// 소수점 n자리에서 반올림합니다.
    ///
    /// - Parameter places: 소수점 자리수
    /// - Returns: 반올림된 Decimal 값
    ///
    /// - Example:
    /// ```swift
    /// let value = Decimal(3.14159)
    /// let rounded = value.rounded(2)  // 3.14
    /// ```
    func rounded(_ places: Int = 0) -> Decimal {
        var result = self
        var rounded = Decimal()
        NSDecimalRound(&rounded, &result, places, .plain)
        return rounded
    }
}
