//
//  NutritionCalculatorTests.swift
//  BodiiTests
//
//  Created by Auto-Claude on 2026-01-13.
//

import XCTest
@testable import Bodii

/// Unit tests for NutritionCalculator utility
///
/// NutritionCalculator의 영양소 계산 및 다량 영양소 비율 계산 단위 테스트
final class NutritionCalculatorTests: XCTestCase {

    // MARK: - Test Data

    /// Sample food for testing
    /// 테스트용 샘플 음식 (현미밥)
    var sampleFood: Food!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()

        // 현미밥: 210g 기준
        sampleFood = Food(
            id: UUID(),
            name: "현미밥",
            calories: 330,
            carbohydrates: Decimal(string: "73.4")!,
            protein: Decimal(string: "6.8")!,
            fat: Decimal(string: "2.5")!,
            sodium: Decimal(5),
            fiber: Decimal(3.0),
            sugar: Decimal(0.5),
            servingSize: Decimal(210),
            servingUnit: "1공기",
            source: .governmentAPI,
            apiCode: "D000001",
            createdByUserId: nil,
            createdAt: Date()
        )
    }

    override func tearDown() {
        sampleFood = nil
        super.tearDown()
    }

    // MARK: - Serving-Based Calculation Tests

    /// Test: 1 serving calculation
    ///
    /// 테스트: 1인분 계산
    func testCalculate_OneServing_ReturnsBaseline() {
        // Given: 1 serving
        let quantity: Decimal = 1.0
        let unit: QuantityUnit = .serving

        // When: Calculate nutrition
        let result = NutritionCalculator.calculate(
            from: sampleFood,
            quantity: quantity,
            unit: unit
        )

        // Then: Should match original food values
        XCTAssertEqual(result.quantity, 1.0, "Quantity should be 1.0")
        XCTAssertEqual(result.unit, .serving, "Unit should be serving")
        XCTAssertEqual(result.calories, 330, "Calories should match baseline")
        XCTAssertEqual(result.carbohydrates, Decimal(string: "73.4"), "Carbs should match baseline")
        XCTAssertEqual(result.protein, Decimal(string: "6.8"), "Protein should match baseline")
        XCTAssertEqual(result.fat, Decimal(string: "2.5"), "Fat should match baseline")
        XCTAssertEqual(result.sodium, Decimal(5), "Sodium should match baseline")
        XCTAssertEqual(result.fiber, Decimal(3.0), "Fiber should match baseline")
        XCTAssertEqual(result.sugar, Decimal(0.5), "Sugar should match baseline")
    }

    /// Test: 1.5 servings calculation
    ///
    /// 테스트: 1.5인분 계산
    func testCalculate_OneAndHalfServings_ReturnsMultiplied() {
        // Given: 1.5 servings
        let quantity: Decimal = 1.5
        let unit: QuantityUnit = .serving

        // When: Calculate nutrition
        let result = NutritionCalculator.calculate(
            from: sampleFood,
            quantity: quantity,
            unit: unit
        )

        // Then: Should multiply all values by 1.5
        XCTAssertEqual(result.quantity, 1.5, "Quantity should be 1.5")
        XCTAssertEqual(result.unit, .serving, "Unit should be serving")
        XCTAssertEqual(result.calories, 495, "Calories should be 330 * 1.5 = 495")
        XCTAssertEqual(result.carbohydrates, Decimal(string: "110.1"), "Carbs should be 73.4 * 1.5 = 110.1")
        XCTAssertEqual(result.protein, Decimal(string: "10.2"), "Protein should be 6.8 * 1.5 = 10.2")
        XCTAssertEqual(result.fat, Decimal(string: "3.8"), "Fat should be 2.5 * 1.5 = 3.75 ≈ 3.8")
        XCTAssertEqual(result.sodium, Decimal(string: "7.5"), "Sodium should be 5 * 1.5 = 7.5")
        XCTAssertEqual(result.fiber, Decimal(4.5), "Fiber should be 3.0 * 1.5 = 4.5")
        XCTAssertEqual(result.sugar, Decimal(string: "0.8"), "Sugar should be 0.5 * 1.5 = 0.75 ≈ 0.8")
    }

    /// Test: 2 servings calculation
    ///
    /// 테스트: 2인분 계산
    func testCalculate_TwoServings_ReturnsDoubled() {
        // Given: 2 servings
        let quantity: Decimal = 2.0
        let unit: QuantityUnit = .serving

        // When: Calculate nutrition
        let result = NutritionCalculator.calculate(
            from: sampleFood,
            quantity: quantity,
            unit: unit
        )

        // Then: Should double all values
        XCTAssertEqual(result.quantity, 2.0, "Quantity should be 2.0")
        XCTAssertEqual(result.unit, .serving, "Unit should be serving")
        XCTAssertEqual(result.calories, 660, "Calories should be 330 * 2 = 660")
        XCTAssertEqual(result.carbohydrates, Decimal(string: "146.8"), "Carbs should be 73.4 * 2 = 146.8")
        XCTAssertEqual(result.protein, Decimal(string: "13.6"), "Protein should be 6.8 * 2 = 13.6")
        XCTAssertEqual(result.fat, Decimal(5.0), "Fat should be 2.5 * 2 = 5.0")
        XCTAssertEqual(result.sodium, Decimal(10), "Sodium should be 5 * 2 = 10")
        XCTAssertEqual(result.fiber, Decimal(6.0), "Fiber should be 3.0 * 2 = 6.0")
        XCTAssertEqual(result.sugar, Decimal(1.0), "Sugar should be 0.5 * 2 = 1.0")
    }

    /// Test: 0.5 serving calculation
    ///
    /// 테스트: 0.5인분 계산
    func testCalculate_HalfServing_ReturnsHalved() {
        // Given: 0.5 serving
        let quantity: Decimal = 0.5
        let unit: QuantityUnit = .serving

        // When: Calculate nutrition
        let result = NutritionCalculator.calculate(
            from: sampleFood,
            quantity: quantity,
            unit: unit
        )

        // Then: Should halve all values
        XCTAssertEqual(result.quantity, 0.5, "Quantity should be 0.5")
        XCTAssertEqual(result.unit, .serving, "Unit should be serving")
        XCTAssertEqual(result.calories, 165, "Calories should be 330 * 0.5 = 165")
        XCTAssertEqual(result.carbohydrates, Decimal(string: "36.7"), "Carbs should be 73.4 * 0.5 = 36.7")
        XCTAssertEqual(result.protein, Decimal(string: "3.4"), "Protein should be 6.8 * 0.5 = 3.4")
        XCTAssertEqual(result.fat, Decimal(string: "1.3"), "Fat should be 2.5 * 0.5 = 1.25 ≈ 1.3")
        XCTAssertEqual(result.sodium, Decimal(string: "2.5"), "Sodium should be 5 * 0.5 = 2.5")
        XCTAssertEqual(result.fiber, Decimal(1.5), "Fiber should be 3.0 * 0.5 = 1.5")
        XCTAssertEqual(result.sugar, Decimal(string: "0.3"), "Sugar should be 0.5 * 0.5 = 0.25 ≈ 0.3")
    }

    // MARK: - Gram-Based Calculation Tests

    /// Test: Same gram as serving size
    ///
    /// 테스트: 서빙 사이즈와 동일한 그램 (210g)
    func testCalculate_SameGramsAsServingSize_ReturnsBaseline() {
        // Given: 210g (same as serving size)
        let quantity: Decimal = 210
        let unit: QuantityUnit = .grams

        // When: Calculate nutrition
        let result = NutritionCalculator.calculate(
            from: sampleFood,
            quantity: quantity,
            unit: unit
        )

        // Then: Should match original food values (210g / 210g = 1.0x)
        XCTAssertEqual(result.quantity, 210, "Quantity should be 210")
        XCTAssertEqual(result.unit, .grams, "Unit should be grams")
        XCTAssertEqual(result.calories, 330, "Calories should match baseline")
        XCTAssertEqual(result.carbohydrates, Decimal(string: "73.4"), "Carbs should match baseline")
        XCTAssertEqual(result.protein, Decimal(string: "6.8"), "Protein should match baseline")
        XCTAssertEqual(result.fat, Decimal(string: "2.5"), "Fat should match baseline")
    }

    /// Test: 300g calculation
    ///
    /// 테스트: 300g 계산 (210g 서빙 사이즈 기준)
    func testCalculate_300Grams_ReturnsScaled() {
        // Given: 300g (300 / 210 = 1.4286x)
        let quantity: Decimal = 300
        let unit: QuantityUnit = .grams

        // When: Calculate nutrition
        let result = NutritionCalculator.calculate(
            from: sampleFood,
            quantity: quantity,
            unit: unit
        )

        // Then: Should scale by (300 / 210)
        let multiplier = Decimal(300) / Decimal(210) // 1.4286

        XCTAssertEqual(result.quantity, 300, "Quantity should be 300")
        XCTAssertEqual(result.unit, .grams, "Unit should be grams")

        // 330 * 1.4286 = 471.43 ≈ 471
        XCTAssertEqual(result.calories, 471, "Calories should be 330 * (300/210) ≈ 471")

        // 73.4 * 1.4286 = 104.86 ≈ 104.9
        let expectedCarbs = (Decimal(string: "73.4")! * multiplier).rounded1
        XCTAssertEqual(result.carbohydrates, expectedCarbs, "Carbs should be 73.4 * (300/210)")

        // 6.8 * 1.4286 = 9.71 ≈ 9.7
        let expectedProtein = (Decimal(string: "6.8")! * multiplier).rounded1
        XCTAssertEqual(result.protein, expectedProtein, "Protein should be 6.8 * (300/210)")

        // 2.5 * 1.4286 = 3.57 ≈ 3.6
        let expectedFat = (Decimal(string: "2.5")! * multiplier).rounded1
        XCTAssertEqual(result.fat, expectedFat, "Fat should be 2.5 * (300/210)")
    }

    /// Test: 100g calculation (less than serving size)
    ///
    /// 테스트: 100g 계산 (서빙 사이즈보다 적음)
    func testCalculate_100Grams_ReturnsScaled() {
        // Given: 100g (100 / 210 = 0.4762x)
        let quantity: Decimal = 100
        let unit: QuantityUnit = .grams

        // When: Calculate nutrition
        let result = NutritionCalculator.calculate(
            from: sampleFood,
            quantity: quantity,
            unit: unit
        )

        // Then: Should scale by (100 / 210)
        let multiplier = Decimal(100) / Decimal(210) // 0.4762

        XCTAssertEqual(result.quantity, 100, "Quantity should be 100")
        XCTAssertEqual(result.unit, .grams, "Unit should be grams")

        // 330 * 0.4762 = 157.14 ≈ 157
        XCTAssertEqual(result.calories, 157, "Calories should be 330 * (100/210) ≈ 157")

        // 73.4 * 0.4762 = 34.95 ≈ 35.0
        let expectedCarbs = (Decimal(string: "73.4")! * multiplier).rounded1
        XCTAssertEqual(result.carbohydrates, expectedCarbs, "Carbs should be 73.4 * (100/210)")

        // 6.8 * 0.4762 = 3.24 ≈ 3.2
        let expectedProtein = (Decimal(string: "6.8")! * multiplier).rounded1
        XCTAssertEqual(result.protein, expectedProtein, "Protein should be 6.8 * (100/210)")
    }

    // MARK: - Decimal Precision Tests

    /// Test: Calorie rounding (Int32)
    ///
    /// 테스트: 칼로리 반올림 (정수)
    func testCalculate_CaloriesRounding_ReturnsInt32() {
        // Given: 1.3 servings (330 * 1.3 = 429)
        let quantity: Decimal = 1.3
        let unit: QuantityUnit = .serving

        // When: Calculate nutrition
        let result = NutritionCalculator.calculate(
            from: sampleFood,
            quantity: quantity,
            unit: unit
        )

        // Then: Calories should be rounded to Int32
        XCTAssertEqual(result.calories, 429, "Calories should be rounded to Int32: 330 * 1.3 = 429")
    }

    /// Test: Macro rounding (1 decimal place)
    ///
    /// 테스트: 다량 영양소 반올림 (소수점 1자리)
    func testCalculate_MacroRounding_ReturnsOneDecimalPlace() {
        // Given: 1.33 servings (should produce decimal values)
        let quantity: Decimal = 1.33
        let unit: QuantityUnit = .serving

        // When: Calculate nutrition
        let result = NutritionCalculator.calculate(
            from: sampleFood,
            quantity: quantity,
            unit: unit
        )

        // Then: Macros should be rounded to 1 decimal place
        // 73.4 * 1.33 = 97.622 ≈ 97.6
        let expectedCarbs = (Decimal(string: "73.4")! * quantity).rounded1
        XCTAssertEqual(result.carbohydrates, expectedCarbs, "Carbs should be rounded to 1 decimal place")

        // 6.8 * 1.33 = 9.044 ≈ 9.0
        let expectedProtein = (Decimal(string: "6.8")! * quantity).rounded1
        XCTAssertEqual(result.protein, expectedProtein, "Protein should be rounded to 1 decimal place")

        // 2.5 * 1.33 = 3.325 ≈ 3.3
        let expectedFat = (Decimal(string: "2.5")! * quantity).rounded1
        XCTAssertEqual(result.fat, expectedFat, "Fat should be rounded to 1 decimal place")
    }

    // MARK: - Edge Case Tests

    /// Test: 0 serving calculation
    ///
    /// 테스트: 0인분 계산
    func testCalculate_ZeroServing_ReturnsZero() {
        // Given: 0 servings
        let quantity: Decimal = 0
        let unit: QuantityUnit = .serving

        // When: Calculate nutrition
        let result = NutritionCalculator.calculate(
            from: sampleFood,
            quantity: quantity,
            unit: unit
        )

        // Then: All nutrition values should be 0
        XCTAssertEqual(result.quantity, 0, "Quantity should be 0")
        XCTAssertEqual(result.calories, 0, "Calories should be 0")
        XCTAssertEqual(result.carbohydrates, 0, "Carbs should be 0")
        XCTAssertEqual(result.protein, 0, "Protein should be 0")
        XCTAssertEqual(result.fat, 0, "Fat should be 0")
        XCTAssertEqual(result.sodium, 0, "Sodium should be 0")
        XCTAssertEqual(result.fiber, 0, "Fiber should be 0")
        XCTAssertEqual(result.sugar, 0, "Sugar should be 0")
    }

    /// Test: Very large serving calculation
    ///
    /// 테스트: 매우 큰 인분 계산
    func testCalculate_VeryLargeServing_ReturnsScaled() {
        // Given: 10 servings (large but realistic)
        let quantity: Decimal = 10
        let unit: QuantityUnit = .serving

        // When: Calculate nutrition
        let result = NutritionCalculator.calculate(
            from: sampleFood,
            quantity: quantity,
            unit: unit
        )

        // Then: Should scale correctly
        XCTAssertEqual(result.quantity, 10, "Quantity should be 10")
        XCTAssertEqual(result.calories, 3300, "Calories should be 330 * 10 = 3300")
        XCTAssertEqual(result.carbohydrates, Decimal(734), "Carbs should be 73.4 * 10 = 734")
        XCTAssertEqual(result.protein, Decimal(68), "Protein should be 6.8 * 10 = 68")
        XCTAssertEqual(result.fat, Decimal(25), "Fat should be 2.5 * 10 = 25")
    }

    /// Test: Food without optional nutrients
    ///
    /// 테스트: 선택적 영양소가 없는 음식
    func testCalculate_FoodWithoutOptionalNutrients_ReturnsNilForOptionals() {
        // Given: Food without sodium, fiber, sugar
        let minimalFood = Food(
            id: UUID(),
            name: "단순 음식",
            calories: 100,
            carbohydrates: Decimal(20),
            protein: Decimal(5),
            fat: Decimal(3),
            sodium: nil,
            fiber: nil,
            sugar: nil,
            servingSize: Decimal(100),
            servingUnit: nil,
            source: .userDefined,
            apiCode: nil,
            createdByUserId: UUID(),
            createdAt: Date()
        )

        // When: Calculate nutrition
        let result = NutritionCalculator.calculate(
            from: minimalFood,
            quantity: 2.0,
            unit: .serving
        )

        // Then: Required nutrients should be calculated, optional should be nil
        XCTAssertEqual(result.calories, 200, "Calories should be calculated")
        XCTAssertEqual(result.carbohydrates, Decimal(40), "Carbs should be calculated")
        XCTAssertEqual(result.protein, Decimal(10), "Protein should be calculated")
        XCTAssertEqual(result.fat, Decimal(6), "Fat should be calculated")
        XCTAssertNil(result.sodium, "Sodium should be nil")
        XCTAssertNil(result.fiber, "Fiber should be nil")
        XCTAssertNil(result.sugar, "Sugar should be nil")
    }

    /// Test: Zero serving size edge case
    ///
    /// 테스트: 서빙 사이즈가 0인 경우 (엣지 케이스)
    func testCalculate_ZeroServingSize_ReturnsZeroForGrams() {
        // Given: Food with 0 serving size (edge case, should not happen in reality)
        let zeroServingFood = Food(
            id: UUID(),
            name: "제로 서빙",
            calories: 100,
            carbohydrates: Decimal(20),
            protein: Decimal(5),
            fat: Decimal(3),
            servingSize: Decimal(0), // Edge case
            servingUnit: nil,
            source: .userDefined,
            apiCode: nil,
            createdByUserId: UUID(),
            createdAt: Date()
        )

        // When: Calculate with grams (division by zero scenario)
        let result = NutritionCalculator.calculate(
            from: zeroServingFood,
            quantity: 100,
            unit: .grams
        )

        // Then: Should return 0 for all values (safe handling)
        XCTAssertEqual(result.calories, 0, "Calories should be 0 when serving size is 0")
        XCTAssertEqual(result.carbohydrates, 0, "Carbs should be 0 when serving size is 0")
        XCTAssertEqual(result.protein, 0, "Protein should be 0 when serving size is 0")
        XCTAssertEqual(result.fat, 0, "Fat should be 0 when serving size is 0")
    }

    // MARK: - Macro Ratio Calculation Tests

    /// Test: Macro ratio calculation
    ///
    /// 테스트: 다량 영양소 비율 계산
    func testCalculateMacroRatios_ValidValues_ReturnsPercentages() {
        // Given: Sample macro values
        // Carbs: 50g * 4 kcal/g = 200 kcal
        // Protein: 25g * 4 kcal/g = 100 kcal
        // Fat: 10g * 9 kcal/g = 90 kcal
        // Total: 390 kcal
        // Percentages: 51.3%, 25.6%, 23.1%
        let carbs = Decimal(50)
        let protein = Decimal(25)
        let fat = Decimal(10)

        // When: Calculate ratios
        let ratios = NutritionCalculator.calculateMacroRatios(
            carbs: carbs,
            protein: protein,
            fat: fat
        )

        // Then: Should return correct percentages
        XCTAssertEqual(ratios.carbs, Decimal(string: "51.3"), "Carbs percentage should be 51.3%")
        XCTAssertEqual(ratios.protein, Decimal(string: "25.6"), "Protein percentage should be 25.6%")
        XCTAssertEqual(ratios.fat, Decimal(string: "23.1"), "Fat percentage should be 23.1%")

        // Verify sum is approximately 100% (may have small rounding differences)
        let sum = ratios.carbs + ratios.protein + ratios.fat
        XCTAssertEqual(sum, Decimal(100), accuracy: Decimal(0.5), "Sum should be approximately 100%")
    }

    /// Test: Macro ratio calculation with zero values
    ///
    /// 테스트: 모든 값이 0일 때 비율 계산
    func testCalculateMacroRatios_ZeroValues_ReturnsZero() {
        // Given: All zero values
        let carbs = Decimal(0)
        let protein = Decimal(0)
        let fat = Decimal(0)

        // When: Calculate ratios
        let ratios = NutritionCalculator.calculateMacroRatios(
            carbs: carbs,
            protein: protein,
            fat: fat
        )

        // Then: All percentages should be 0
        XCTAssertEqual(ratios.carbs, Decimal(0), "Carbs percentage should be 0%")
        XCTAssertEqual(ratios.protein, Decimal(0), "Protein percentage should be 0%")
        XCTAssertEqual(ratios.fat, Decimal(0), "Fat percentage should be 0%")
    }

    /// Test: Macro ratios in calculated nutrition
    ///
    /// 테스트: 계산된 영양 정보에 포함된 비율 검증
    func testCalculate_IncludesMacroRatios() {
        // Given: 1 serving of sample food
        let quantity: Decimal = 1.0
        let unit: QuantityUnit = .serving

        // When: Calculate nutrition
        let result = NutritionCalculator.calculate(
            from: sampleFood,
            quantity: quantity,
            unit: unit
        )

        // Then: Should include macro ratios
        // Carbs: 73.4g * 4 = 293.6 kcal
        // Protein: 6.8g * 4 = 27.2 kcal
        // Fat: 2.5g * 9 = 22.5 kcal
        // Total: 343.3 kcal
        let totalCalories = Decimal(string: "73.4")! * 4 + Decimal(string: "6.8")! * 4 + Decimal(string: "2.5")! * 9

        let expectedCarbsPct = ((Decimal(string: "73.4")! * 4) / totalCalories * 100).rounded1
        let expectedProteinPct = ((Decimal(string: "6.8")! * 4) / totalCalories * 100).rounded1
        let expectedFatPct = ((Decimal(string: "2.5")! * 9) / totalCalories * 100).rounded1

        XCTAssertEqual(result.carbsPercentage, expectedCarbsPct, "Carbs percentage should be calculated")
        XCTAssertEqual(result.proteinPercentage, expectedProteinPct, "Protein percentage should be calculated")
        XCTAssertEqual(result.fatPercentage, expectedFatPct, "Fat percentage should be calculated")
    }

    // MARK: - Convenience Method Tests

    /// Test: calculateForServings convenience method
    ///
    /// 테스트: 인분 계산 편의 메서드
    func testCalculateForServings_ReturnsCorrectResult() {
        // Given: 1.5 servings
        let servings: Decimal = 1.5

        // When: Use convenience method
        let result = NutritionCalculator.calculateForServings(
            from: sampleFood,
            servings: servings
        )

        // Then: Should match full method with serving unit
        XCTAssertEqual(result.quantity, 1.5, "Quantity should be 1.5")
        XCTAssertEqual(result.unit, .serving, "Unit should be serving")
        XCTAssertEqual(result.calories, 495, "Calories should be 330 * 1.5 = 495")
    }

    /// Test: calculateForGrams convenience method
    ///
    /// 테스트: 그램 계산 편의 메서드
    func testCalculateForGrams_ReturnsCorrectResult() {
        // Given: 300g
        let grams: Decimal = 300

        // When: Use convenience method
        let result = NutritionCalculator.calculateForGrams(
            from: sampleFood,
            grams: grams
        )

        // Then: Should match full method with grams unit
        XCTAssertEqual(result.quantity, 300, "Quantity should be 300")
        XCTAssertEqual(result.unit, .grams, "Unit should be grams")

        // 330 * (300/210) = 471.43 ≈ 471
        XCTAssertEqual(result.calories, 471, "Calories should be 330 * (300/210) ≈ 471")
    }

    // MARK: - Integration Tests

    /// Test: Full workflow - serving to FoodRecord
    ///
    /// 테스트: 전체 흐름 - 인분 계산 후 FoodRecord 변환
    func testCalculate_ToFoodRecord_Integration() {
        // Given: Calculate nutrition for 1.5 servings
        let nutrition = NutritionCalculator.calculateForServings(
            from: sampleFood,
            servings: 1.5
        )

        // When: Convert to FoodRecord
        let userId = UUID()
        let date = Date()
        let mealType = MealType.breakfast

        let record = nutrition.toFoodRecord(
            foodId: sampleFood.id,
            userId: userId,
            date: date,
            mealType: mealType
        )

        // Then: FoodRecord should have correct values
        XCTAssertEqual(record.foodId, sampleFood.id, "Food ID should match")
        XCTAssertEqual(record.userId, userId, "User ID should match")
        XCTAssertEqual(record.mealType, mealType, "Meal type should match")
        XCTAssertEqual(record.quantity, 1.5, "Quantity should match")
        XCTAssertEqual(record.quantityUnit, .serving, "Unit should match")
        XCTAssertEqual(record.calculatedCalories, 495, "Calculated calories should match")
        XCTAssertEqual(record.calculatedCarbs, Decimal(string: "110.1"), "Calculated carbs should match")
        XCTAssertEqual(record.calculatedProtein, Decimal(string: "10.2"), "Calculated protein should match")
        XCTAssertEqual(record.calculatedFat, Decimal(string: "3.8"), "Calculated fat should match")
    }

    /// Test: Comparison between serving and gram calculations
    ///
    /// 테스트: 인분과 그램 계산 비교
    func testCalculate_ServingVsGrams_ProducesSameResult() {
        // Given: 1 serving = 210g
        let servingResult = NutritionCalculator.calculateForServings(
            from: sampleFood,
            servings: 1.0
        )

        let gramsResult = NutritionCalculator.calculateForGrams(
            from: sampleFood,
            grams: 210
        )

        // Then: Both should produce same nutrition values
        XCTAssertEqual(servingResult.calories, gramsResult.calories, "Calories should match")
        XCTAssertEqual(servingResult.carbohydrates, gramsResult.carbohydrates, "Carbs should match")
        XCTAssertEqual(servingResult.protein, gramsResult.protein, "Protein should match")
        XCTAssertEqual(servingResult.fat, gramsResult.fat, "Fat should match")
        XCTAssertEqual(servingResult.sodium, gramsResult.sodium, "Sodium should match")
        XCTAssertEqual(servingResult.fiber, gramsResult.fiber, "Fiber should match")
        XCTAssertEqual(servingResult.sugar, gramsResult.sugar, "Sugar should match")
    }
}
