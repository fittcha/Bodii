//
//  NutritionCalculator.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-13.
//

import Foundation

/// 영양 계산 유틸리티
///
/// 섭취량에 따른 영양소 계산과 다량 영양소 비율을 계산하는 유틸리티입니다.
///
/// **핵심 기능:**
/// - 인분(serving) 또는 그램(grams) 단위로 영양소 계산
/// - 칼로리, 탄수화물, 단백질, 지방, 나트륨, 식이섬유, 당류 계산
/// - 다량 영양소(탄단지) 비율 계산
///
/// **계산 로직:**
/// - `.serving` 단위: `quantity * 영양소값` (Food의 servingSize가 기준)
/// - `.grams` 단위: `(quantity / servingSize) * 영양소값`
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
///     ...
/// )
///
/// // 1.5인분 계산
/// let nutrition1 = NutritionCalculator.calculate(
///     from: food,
///     quantity: 1.5,
///     unit: .serving
/// )
/// // nutrition1.calories == 495 (330 * 1.5)
///
/// // 300g 계산
/// let nutrition2 = NutritionCalculator.calculate(
///     from: food,
///     quantity: 300,
///     unit: .grams
/// )
/// // nutrition2.calories == 471 (330 * 300 / 210)
/// ```
///
/// - Note: Java Spring의 @Service 레이어와 유사하지만, Swift에서는 static utility로 구현
enum NutritionCalculator {

    // MARK: - Nutrition Calculation

    /// 섭취량에 따른 영양소를 계산합니다
    ///
    /// Food의 영양 정보를 기반으로 지정된 섭취량에 따라 영양소를 계산합니다.
    ///
    /// - Parameters:
    ///   - food: 음식 정보
    ///   - quantity: 섭취량 (인분 또는 그램)
    ///   - unit: 섭취량 단위 (serving 또는 grams)
    /// - Returns: 계산된 영양 정보
    ///
    /// - Note: `.serving` 단위는 Food의 servingSize를 기준으로 배수 계산
    /// - Note: `.grams` 단위는 그램 단위 직접 계산
    ///
    /// Example:
    /// ```swift
    /// let food = Food(name: "김치찌개", calories: 120, carbs: 10, protein: 8, fat: 5, servingSize: 250)
    /// let nutrition = NutritionCalculator.calculate(from: food, quantity: 2.0, unit: .serving)
    /// // nutrition.calories == 240, nutrition.protein == 16
    /// ```
    static func calculate(
        from food: Food,
        quantity: Decimal,
        unit: QuantityUnit
    ) -> CalculatedNutrition {
        // 배율 계산
        let multiplier = calculateMultiplier(
            servingSize: food.servingSize,
            quantity: quantity,
            unit: unit
        )

        // 영양소 계산
        let calories = calculateCalories(
            baseCalories: food.calories,
            multiplier: multiplier
        )

        let carbohydrates = calculateMacro(
            baseMacro: food.carbohydrates,
            multiplier: multiplier
        )

        let protein = calculateMacro(
            baseMacro: food.protein,
            multiplier: multiplier
        )

        let fat = calculateMacro(
            baseMacro: food.fat,
            multiplier: multiplier
        )

        let sodium = food.sodium.map { calculateMacro(baseMacro: $0, multiplier: multiplier) }
        let fiber = food.fiber.map { calculateMacro(baseMacro: $0, multiplier: multiplier) }
        let sugar = food.sugar.map { calculateMacro(baseMacro: $0, multiplier: multiplier) }

        // 다량 영양소 비율 계산
        let macroRatios = calculateMacroRatios(
            carbs: carbohydrates,
            protein: protein,
            fat: fat
        )

        return CalculatedNutrition(
            quantity: quantity,
            unit: unit,
            calories: calories,
            carbohydrates: carbohydrates,
            protein: protein,
            fat: fat,
            sodium: sodium,
            fiber: fiber,
            sugar: sugar,
            carbsPercentage: macroRatios.carbs,
            proteinPercentage: macroRatios.protein,
            fatPercentage: macroRatios.fat
        )
    }

    // MARK: - Multiplier Calculation

    /// 영양소 계산을 위한 배율을 계산합니다
    ///
    /// - Parameters:
    ///   - servingSize: 1회 제공량 (그램)
    ///   - quantity: 섭취량
    ///   - unit: 섭취량 단위
    /// - Returns: 영양소 계산 배율
    ///
    /// - Note: `.serving`: quantity를 그대로 배율로 사용 (1.5인분 = 1.5배)
    /// - Note: `.grams`: `quantity / servingSize`로 배율 계산 (300g / 210g = 1.43배)
    ///
    /// Example:
    /// ```swift
    /// let multiplier1 = calculateMultiplier(servingSize: 210, quantity: 1.5, unit: .serving)
    /// // Returns: 1.5
    ///
    /// let multiplier2 = calculateMultiplier(servingSize: 210, quantity: 300, unit: .grams)
    /// // Returns: 1.4286 (300 / 210)
    /// ```
    private static func calculateMultiplier(
        servingSize: Decimal,
        quantity: Decimal,
        unit: QuantityUnit
    ) -> Decimal {
        switch unit {
        case .serving:
            // 인분 단위: quantity가 배율
            // 예: 1.5인분 = 1.5배
            return quantity

        case .grams:
            // 그램 단위: (섭취량 / 1회 제공량)이 배율
            // 예: 300g 섭취, servingSize 210g = 300/210 = 1.43배
            guard servingSize > 0 else { return 0 }
            return quantity / servingSize
        }
    }

    // MARK: - Nutrient Calculation Helpers

    /// 칼로리를 계산합니다
    ///
    /// - Parameters:
    ///   - baseCalories: 기준 칼로리 (Food의 servingSize 기준)
    ///   - multiplier: 배율
    /// - Returns: 계산된 칼로리 (Int32, 반올림)
    ///
    /// Example:
    /// ```swift
    /// let calories = calculateCalories(baseCalories: 330, multiplier: 1.5)
    /// // Returns: 495 (330 * 1.5)
    /// ```
    private static func calculateCalories(
        baseCalories: Int32,
        multiplier: Decimal
    ) -> Int32 {
        let calculated = Decimal(baseCalories) * multiplier
        return calculated.rounded0.toInt32()
    }

    /// 다량 영양소(탄수화물, 단백질, 지방)를 계산합니다
    ///
    /// - Parameters:
    ///   - baseMacro: 기준 영양소 값 (Food의 servingSize 기준)
    ///   - multiplier: 배율
    /// - Returns: 계산된 영양소 값 (Decimal, 소수점 1자리 반올림)
    ///
    /// Example:
    /// ```swift
    /// let protein = calculateMacro(baseMacro: 6.8, multiplier: 1.5)
    /// // Returns: 10.2 (6.8 * 1.5)
    /// ```
    private static func calculateMacro(
        baseMacro: Decimal,
        multiplier: Decimal
    ) -> Decimal {
        let calculated = baseMacro * multiplier
        return calculated.rounded1
    }

    // MARK: - Macro Ratio Calculation

    /// 다량 영양소(탄단지) 비율을 계산합니다
    ///
    /// 칼로리 기준으로 탄수화물, 단백질, 지방의 비율을 백분율로 계산합니다.
    ///
    /// - Parameters:
    ///   - carbs: 탄수화물 (g)
    ///   - protein: 단백질 (g)
    ///   - fat: 지방 (g)
    /// - Returns: 탄단지 비율 (각각 0-100%)
    ///
    /// - Note: 탄수화물 = 4 kcal/g, 단백질 = 4 kcal/g, 지방 = 9 kcal/g
    ///
    /// Example:
    /// ```swift
    /// let ratios = calculateMacroRatios(carbs: 50, protein: 25, fat: 10)
    /// // 탄수화물: 50 * 4 = 200 kcal
    /// // 단백질: 25 * 4 = 100 kcal
    /// // 지방: 10 * 9 = 90 kcal
    /// // 총: 390 kcal
    /// // 비율: 51.3%, 25.6%, 23.1%
    /// ```
    static func calculateMacroRatios(
        carbs: Decimal,
        protein: Decimal,
        fat: Decimal
    ) -> MacroRatios {
        // 각 영양소의 칼로리 계산
        // 탄수화물: 4 kcal/g
        // 단백질: 4 kcal/g
        // 지방: 9 kcal/g
        let carbCalories = carbs * Constants.MacroNutrients.carbsCaloriesPerGram
        let proteinCalories = protein * Constants.MacroNutrients.proteinCaloriesPerGram
        let fatCalories = fat * Constants.MacroNutrients.fatCaloriesPerGram

        let totalCalories = carbCalories + proteinCalories + fatCalories

        // 총 칼로리가 0이면 모두 0% 반환
        guard totalCalories > 0 else {
            return MacroRatios(carbs: 0, protein: 0, fat: 0)
        }

        // 백분율 계산 (소수점 1자리)
        let carbsPercentage = (carbCalories / totalCalories * 100).rounded1
        let proteinPercentage = (proteinCalories / totalCalories * 100).rounded1
        let fatPercentage = (fatCalories / totalCalories * 100).rounded1

        return MacroRatios(
            carbs: carbsPercentage,
            protein: proteinPercentage,
            fat: fatPercentage
        )
    }

    // MARK: - Convenience Calculation Methods

    /// 인분 단위로 영양소를 계산합니다
    ///
    /// - Parameters:
    ///   - food: 음식 정보
    ///   - servings: 인분 수
    /// - Returns: 계산된 영양 정보
    ///
    /// Example:
    /// ```swift
    /// let nutrition = NutritionCalculator.calculateForServings(from: food, servings: 1.5)
    /// // 1.5인분 영양소 계산
    /// ```
    static func calculateForServings(
        from food: Food,
        servings: Decimal
    ) -> CalculatedNutrition {
        calculate(from: food, quantity: servings, unit: .serving)
    }

    /// 그램 단위로 영양소를 계산합니다
    ///
    /// - Parameters:
    ///   - food: 음식 정보
    ///   - grams: 그램 수
    /// - Returns: 계산된 영양 정보
    ///
    /// Example:
    /// ```swift
    /// let nutrition = NutritionCalculator.calculateForGrams(from: food, grams: 300)
    /// // 300g 영양소 계산
    /// ```
    static func calculateForGrams(
        from food: Food,
        grams: Decimal
    ) -> CalculatedNutrition {
        calculate(from: food, quantity: grams, unit: .grams)
    }
}

// MARK: - Supporting Types

/// 계산된 영양 정보
///
/// NutritionCalculator가 계산한 영양소 정보를 담는 구조체입니다.
///
/// - Note: FoodRecord 생성 시 이 정보를 사용합니다
struct CalculatedNutrition {
    /// 섭취량
    let quantity: Decimal

    /// 섭취량 단위
    let unit: QuantityUnit

    // MARK: - Calculated Nutrition Values

    /// 계산된 칼로리 (kcal)
    let calories: Int32

    /// 계산된 탄수화물 (g)
    let carbohydrates: Decimal

    /// 계산된 단백질 (g)
    let protein: Decimal

    /// 계산된 지방 (g)
    let fat: Decimal

    /// 계산된 나트륨 (mg)
    let sodium: Decimal?

    /// 계산된 식이섬유 (g)
    let fiber: Decimal?

    /// 계산된 당류 (g)
    let sugar: Decimal?

    // MARK: - Macro Ratios

    /// 탄수화물 비율 (%)
    let carbsPercentage: Decimal

    /// 단백질 비율 (%)
    let proteinPercentage: Decimal

    /// 지방 비율 (%)
    let fatPercentage: Decimal
}

// MARK: - CalculatedNutrition Extensions

extension CalculatedNutrition {
    /// FoodRecord 생성을 위한 헬퍼 메서드
    ///
    /// CalculatedNutrition을 기반으로 FoodRecord를 쉽게 생성할 수 있습니다.
    ///
    /// - Parameters:
    ///   - foodId: 음식 ID
    ///   - userId: 사용자 ID
    ///   - date: 섭취 일자
    ///   - mealType: 끼니 종류
    /// - Returns: 생성된 FoodRecord
    ///
    /// Example:
    /// ```swift
    /// let nutrition = NutritionCalculator.calculate(from: food, quantity: 1.5, unit: .serving)
    /// let record = nutrition.toFoodRecord(
    ///     foodId: food.id,
    ///     userId: currentUser.id,
    ///     date: Date(),
    ///     mealType: .breakfast
    /// )
    /// ```
    func toFoodRecord(
        foodId: UUID,
        userId: UUID,
        date: Date,
        mealType: MealType
    ) -> FoodRecord {
        FoodRecord(
            id: UUID(),
            userId: userId,
            foodId: foodId,
            date: date,
            mealType: mealType,
            quantity: quantity,
            quantityUnit: unit,
            calculatedCalories: calories,
            calculatedCarbs: carbohydrates,
            calculatedProtein: protein,
            calculatedFat: fat,
            createdAt: Date()
        )
    }
}

/// 다량 영양소 비율
///
/// 탄수화물, 단백질, 지방의 칼로리 기준 비율을 나타냅니다.
///
/// - Note: 총 합계는 일반적으로 100%이지만 반올림으로 인해 약간 다를 수 있습니다
struct MacroRatios {
    /// 탄수화물 비율 (%)
    let carbs: Decimal

    /// 단백질 비율 (%)
    let protein: Decimal

    /// 지방 비율 (%)
    let fat: Decimal
}

// MARK: - Constants Extension

extension Constants {
    /// 다량 영양소 칼로리 변환 상수
    enum MacroNutrients {
        /// 탄수화물 1g당 칼로리 (kcal/g)
        static let carbsCaloriesPerGram: Decimal = 4

        /// 단백질 1g당 칼로리 (kcal/g)
        static let proteinCaloriesPerGram: Decimal = 4

        /// 지방 1g당 칼로리 (kcal/g)
        static let fatCaloriesPerGram: Decimal = 9
    }
}
