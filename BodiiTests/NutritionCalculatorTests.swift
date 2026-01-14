//
//  NutritionCalculatorTests.swift
//  BodiiTests
//
//  Created by Auto-Claude on 2026-01-13.
//

import XCTest
@testable import Bodii

/// Unit tests for NutritionCalculator nutrition calculations
///
/// NutritionCalculator 영양소 계산에 대한 단위 테스트
final class NutritionCalculatorTests: XCTestCase {

    // MARK: - Test Data

    /// Sample food for testing (현미밥 - Brown Rice)
    ///
    /// 1공기 (210g) 기준 영양 정보
    private let sampleFood = Food(
        id: UUID(),
        name: "현미밥",
        calories: 330,
        carbohydrates: Decimal(73.4),
        protein: Decimal(6.8),
        fat: Decimal(2.5),
        sodium: Decimal(5.0),
        fiber: Decimal(3.0),
        sugar: Decimal(0.5),
        servingSize: Decimal(210.0),
        servingUnit: "1공기",
        source: .governmentAPI,
        apiCode: "D000001",
        createdByUserId: nil,
        createdAt: Date()
    )

    // MARK: - Nutrition Calculation Tests (Serving Unit)

    /// Test: Calculate nutrition for 1 serving
    ///
    /// 테스트: 1인분에 대한 영양소 계산
    func testCalculateNutrition_OneServing_ReturnsExactValues() {
        // Given: 1 serving quantity
        let quantity = Decimal(1.0)
        let unit = QuantityUnit.serving

        // When: Calculating nutrition
        let result = NutritionCalculator.calculateNutrition(
            food: sampleFood,
            quantity: quantity,
            unit: unit
        )

        // Then: Should return exact food values
        XCTAssertEqual(result.calories, 330, "1 serving should have exact calories")
        XCTAssertEqual(result.carbs, Decimal(73.4), "1 serving should have exact carbs")
        XCTAssertEqual(result.protein, Decimal(6.8), "1 serving should have exact protein")
        XCTAssertEqual(result.fat, Decimal(2.5), "1 serving should have exact fat")
    }

    /// Test: Calculate nutrition for 0.5 servings
    ///
    /// 테스트: 0.5인분에 대한 영양소 계산
    func testCalculateNutrition_HalfServing_ReturnsHalfValues() {
        // Given: 0.5 serving quantity
        let quantity = Decimal(0.5)
        let unit = QuantityUnit.serving

        // When: Calculating nutrition
        let result = NutritionCalculator.calculateNutrition(
            food: sampleFood,
            quantity: quantity,
            unit: unit
        )

        // Then: Should return half of food values
        XCTAssertEqual(result.calories, 165, "0.5 serving should have half calories (330 * 0.5)")
        XCTAssertEqual(result.carbs, Decimal(36.7), "0.5 serving should have half carbs (73.4 * 0.5)")
        XCTAssertEqual(result.protein, Decimal(3.4), "0.5 serving should have half protein (6.8 * 0.5)")
        XCTAssertEqual(result.fat, Decimal(1.25), "0.5 serving should have half fat (2.5 * 0.5)")
    }

    /// Test: Calculate nutrition for 1.5 servings
    ///
    /// 테스트: 1.5인분에 대한 영양소 계산
    func testCalculateNutrition_OneAndHalfServings_ReturnsScaledValues() {
        // Given: 1.5 serving quantity
        let quantity = Decimal(1.5)
        let unit = QuantityUnit.serving

        // When: Calculating nutrition
        let result = NutritionCalculator.calculateNutrition(
            food: sampleFood,
            quantity: quantity,
            unit: unit
        )

        // Then: Should return 1.5x food values
        XCTAssertEqual(result.calories, 495, "1.5 servings should have 1.5x calories (330 * 1.5)")
        XCTAssertEqual(result.carbs, Decimal(110.1), "1.5 servings should have 1.5x carbs (73.4 * 1.5)")
        XCTAssertEqual(result.protein, Decimal(10.2), "1.5 servings should have 1.5x protein (6.8 * 1.5)")
        XCTAssertEqual(result.fat, Decimal(3.75), "1.5 servings should have 1.5x fat (2.5 * 1.5)")
    }

    /// Test: Calculate nutrition for 2 servings
    ///
    /// 테스트: 2인분에 대한 영양소 계산
    func testCalculateNutrition_TwoServings_ReturnsDoubleValues() {
        // Given: 2 serving quantity
        let quantity = Decimal(2.0)
        let unit = QuantityUnit.serving

        // When: Calculating nutrition
        let result = NutritionCalculator.calculateNutrition(
            food: sampleFood,
            quantity: quantity,
            unit: unit
        )

        // Then: Should return double food values
        XCTAssertEqual(result.calories, 660, "2 servings should have double calories (330 * 2)")
        XCTAssertEqual(result.carbs, Decimal(146.8), "2 servings should have double carbs (73.4 * 2)")
        XCTAssertEqual(result.protein, Decimal(13.6), "2 servings should have double protein (6.8 * 2)")
        XCTAssertEqual(result.fat, Decimal(5.0), "2 servings should have double fat (2.5 * 2)")
    }

    /// Test: Calculate nutrition for 0.25 servings (quarter)
    ///
    /// 테스트: 0.25인분에 대한 영양소 계산
    func testCalculateNutrition_QuarterServing_ReturnsQuarterValues() {
        // Given: 0.25 serving quantity
        let quantity = Decimal(0.25)
        let unit = QuantityUnit.serving

        // When: Calculating nutrition
        let result = NutritionCalculator.calculateNutrition(
            food: sampleFood,
            quantity: quantity,
            unit: unit
        )

        // Then: Should return quarter of food values
        XCTAssertEqual(result.calories, 83, "0.25 serving should have quarter calories (330 * 0.25 = 82.5, rounded to 83)")
        XCTAssertEqual(result.carbs, Decimal(18.35), "0.25 serving should have quarter carbs (73.4 * 0.25)")
        XCTAssertEqual(result.protein, Decimal(1.7), "0.25 serving should have quarter protein (6.8 * 0.25)")
        XCTAssertEqual(result.fat, Decimal(0.625), "0.25 serving should have quarter fat (2.5 * 0.25)")
    }

    // MARK: - Nutrition Calculation Tests (Grams Unit)

    /// Test: Calculate nutrition for exact serving size in grams
    ///
    /// 테스트: 정확한 1인분 그램 수에 대한 영양소 계산
    func testCalculateNutrition_ExactServingSizeGrams_ReturnsExactValues() {
        // Given: Exact serving size (210g = 1 serving)
        let quantity = Decimal(210.0)
        let unit = QuantityUnit.grams

        // When: Calculating nutrition
        let result = NutritionCalculator.calculateNutrition(
            food: sampleFood,
            quantity: quantity,
            unit: unit
        )

        // Then: Should return exact food values
        XCTAssertEqual(result.calories, 330, "210g (1 serving) should have exact calories")
        XCTAssertEqual(result.carbs, Decimal(73.4), "210g (1 serving) should have exact carbs")
        XCTAssertEqual(result.protein, Decimal(6.8), "210g (1 serving) should have exact protein")
        XCTAssertEqual(result.fat, Decimal(2.5), "210g (1 serving) should have exact fat")
    }

    /// Test: Calculate nutrition for half serving size in grams
    ///
    /// 테스트: 절반 인분 그램 수에 대한 영양소 계산
    func testCalculateNutrition_HalfServingSizeGrams_ReturnsHalfValues() {
        // Given: Half serving size (105g = 0.5 serving)
        let quantity = Decimal(105.0)
        let unit = QuantityUnit.grams

        // When: Calculating nutrition
        let result = NutritionCalculator.calculateNutrition(
            food: sampleFood,
            quantity: quantity,
            unit: unit
        )

        // Then: Should return half of food values
        XCTAssertEqual(result.calories, 165, "105g (0.5 serving) should have half calories")
        XCTAssertEqual(result.carbs, Decimal(36.7), "105g (0.5 serving) should have half carbs")
        XCTAssertEqual(result.protein, Decimal(3.4), "105g (0.5 serving) should have half protein")
        XCTAssertEqual(result.fat, Decimal(1.25), "105g (0.5 serving) should have half fat")
    }

    /// Test: Calculate nutrition for 315g (1.5 servings)
    ///
    /// 테스트: 315g (1.5인분)에 대한 영양소 계산
    func testCalculateNutrition_315Grams_ReturnsOneAndHalfValues() {
        // Given: 315g = 1.5 servings
        let quantity = Decimal(315.0)
        let unit = QuantityUnit.grams

        // When: Calculating nutrition
        let result = NutritionCalculator.calculateNutrition(
            food: sampleFood,
            quantity: quantity,
            unit: unit
        )

        // Then: Should return 1.5x food values
        XCTAssertEqual(result.calories, 495, "315g (1.5 servings) should have 1.5x calories")
        XCTAssertEqual(result.carbs, Decimal(110.1), "315g (1.5 servings) should have 1.5x carbs")
        XCTAssertEqual(result.protein, Decimal(10.2), "315g (1.5 servings) should have 1.5x protein")
        XCTAssertEqual(result.fat, Decimal(3.75), "315g (1.5 servings) should have 1.5x fat")
    }

    /// Test: Calculate nutrition for 100g (non-exact serving multiple)
    ///
    /// 테스트: 100g (정확하지 않은 인분 배수)에 대한 영양소 계산
    func testCalculateNutrition_100Grams_ReturnsProportionalValues() {
        // Given: 100g (100/210 = ~0.476 servings)
        let quantity = Decimal(100.0)
        let unit = QuantityUnit.grams

        // When: Calculating nutrition
        let result = NutritionCalculator.calculateNutrition(
            food: sampleFood,
            quantity: quantity,
            unit: unit
        )

        // Then: Should return proportional values
        // 100g / 210g = 0.476190476... serving
        // Expected: 330 * 0.476190476 = 157.142857 -> rounds to 157
        XCTAssertEqual(result.calories, 157, "100g should have proportional calories")

        // For Decimal values, check with tolerance
        let expectedCarbs = Decimal(73.4) * Decimal(100.0) / Decimal(210.0)
        XCTAssertEqual(result.carbs.rounded(2), expectedCarbs.rounded(2), "100g should have proportional carbs")
    }

    // MARK: - Edge Cases

    /// Test: Calculate nutrition for zero quantity
    ///
    /// 테스트: 0 수량에 대한 영양소 계산
    func testCalculateNutrition_ZeroQuantity_ReturnsZeroValues() {
        // Given: Zero quantity
        let quantity = Decimal(0)
        let unit = QuantityUnit.serving

        // When: Calculating nutrition
        let result = NutritionCalculator.calculateNutrition(
            food: sampleFood,
            quantity: quantity,
            unit: unit
        )

        // Then: Should return all zeros
        XCTAssertEqual(result.calories, 0, "0 quantity should have 0 calories")
        XCTAssertEqual(result.carbs, Decimal(0), "0 quantity should have 0 carbs")
        XCTAssertEqual(result.protein, Decimal(0), "0 quantity should have 0 protein")
        XCTAssertEqual(result.fat, Decimal(0), "0 quantity should have 0 fat")
    }

    /// Test: Calculate nutrition for very large quantity
    ///
    /// 테스트: 매우 큰 수량에 대한 영양소 계산
    func testCalculateNutrition_VeryLargeQuantity_ReturnsScaledValues() {
        // Given: Very large quantity (10 servings)
        let quantity = Decimal(10.0)
        let unit = QuantityUnit.serving

        // When: Calculating nutrition
        let result = NutritionCalculator.calculateNutrition(
            food: sampleFood,
            quantity: quantity,
            unit: unit
        )

        // Then: Should return scaled values
        XCTAssertEqual(result.calories, 3300, "10 servings should have 10x calories")
        XCTAssertEqual(result.carbs, Decimal(734.0), "10 servings should have 10x carbs")
        XCTAssertEqual(result.protein, Decimal(68.0), "10 servings should have 10x protein")
        XCTAssertEqual(result.fat, Decimal(25.0), "10 servings should have 10x fat")
    }

    /// Test: Calculate nutrition for very small quantity
    ///
    /// 테스트: 매우 작은 수량에 대한 영양소 계산
    func testCalculateNutrition_VerySmallQuantity_ReturnsSmallValues() {
        // Given: Very small quantity (0.01 servings)
        let quantity = Decimal(0.01)
        let unit = QuantityUnit.serving

        // When: Calculating nutrition
        let result = NutritionCalculator.calculateNutrition(
            food: sampleFood,
            quantity: quantity,
            unit: unit
        )

        // Then: Should return very small values
        XCTAssertEqual(result.calories, 3, "0.01 serving should have tiny calories (330 * 0.01 = 3.3, rounds to 3)")
        XCTAssertEqual(result.carbs.rounded(2), Decimal(0.73), "0.01 serving should have tiny carbs")
        XCTAssertEqual(result.protein.rounded(2), Decimal(0.07), "0.01 serving should have tiny protein")
        XCTAssertEqual(result.fat.rounded(2), Decimal(0.03), "0.01 serving should have tiny fat")
    }

    // MARK: - Macro Ratio Calculation Tests

    /// Test: Calculate macro ratios for balanced diet
    ///
    /// 테스트: 균형 잡힌 식단의 매크로 비율 계산
    func testCalculateMacroRatios_BalancedDiet_ReturnsCorrectRatios() {
        // Given: Balanced macros (300g carbs, 150g protein, 67g fat)
        // Total calories: (300*4) + (150*4) + (67*9) = 1200 + 600 + 603 = 2403 kcal
        // Ratios: carbs 49.94%, protein 24.97%, fat 25.09%
        let carbs = Decimal(300.0)
        let protein = Decimal(150.0)
        let fat = Decimal(67.0)

        // When: Calculating macro ratios
        let result = NutritionCalculator.calculateMacroRatios(
            carbs: carbs,
            protein: protein,
            fat: fat
        )

        // Then: Should return correct percentages
        XCTAssertNotNil(result.carbsRatio, "Should have carbs ratio")
        XCTAssertNotNil(result.proteinRatio, "Should have protein ratio")
        XCTAssertNotNil(result.fatRatio, "Should have fat ratio")

        // Check ratios (with 0.1% tolerance due to rounding)
        XCTAssertEqual(result.carbsRatio?.rounded(1), Decimal(49.9), "Carbs ratio should be ~49.9%")
        XCTAssertEqual(result.proteinRatio?.rounded(1), Decimal(25.0), "Protein ratio should be ~25.0%")
        XCTAssertEqual(result.fatRatio?.rounded(1), Decimal(25.1), "Fat ratio should be ~25.1%")
    }

    /// Test: Calculate macro ratios for high carb diet
    ///
    /// 테스트: 고탄수 식단의 매크로 비율 계산
    func testCalculateMacroRatios_HighCarb_ReturnsHighCarbRatio() {
        // Given: High carb macros (400g carbs, 100g protein, 50g fat)
        // Total calories: (400*4) + (100*4) + (50*9) = 1600 + 400 + 450 = 2450 kcal
        // Ratios: carbs 65.3%, protein 16.3%, fat 18.4%
        let carbs = Decimal(400.0)
        let protein = Decimal(100.0)
        let fat = Decimal(50.0)

        // When: Calculating macro ratios
        let result = NutritionCalculator.calculateMacroRatios(
            carbs: carbs,
            protein: protein,
            fat: fat
        )

        // Then: Carbs ratio should be highest
        XCTAssertNotNil(result.carbsRatio)
        XCTAssertNotNil(result.proteinRatio)
        XCTAssertNotNil(result.fatRatio)

        XCTAssertTrue(result.carbsRatio! > Decimal(60), "Carbs ratio should be > 60%")
        XCTAssertTrue(result.carbsRatio! > result.proteinRatio!, "Carbs should be higher than protein")
        XCTAssertTrue(result.carbsRatio! > result.fatRatio!, "Carbs should be higher than fat")
    }

    /// Test: Calculate macro ratios for high protein diet
    ///
    /// 테스트: 고단백 식단의 매크로 비율 계산
    func testCalculateMacroRatios_HighProtein_ReturnsHighProteinRatio() {
        // Given: High protein macros (200g carbs, 200g protein, 50g fat)
        // Total calories: (200*4) + (200*4) + (50*9) = 800 + 800 + 450 = 2050 kcal
        // Ratios: carbs 39.0%, protein 39.0%, fat 22.0%
        let carbs = Decimal(200.0)
        let protein = Decimal(200.0)
        let fat = Decimal(50.0)

        // When: Calculating macro ratios
        let result = NutritionCalculator.calculateMacroRatios(
            carbs: carbs,
            protein: protein,
            fat: fat
        )

        // Then: Protein ratio should be high
        XCTAssertNotNil(result.proteinRatio)
        XCTAssertTrue(result.proteinRatio! > Decimal(35), "Protein ratio should be > 35%")
    }

    /// Test: Calculate macro ratios for high fat diet (keto)
    ///
    /// 테스트: 고지방 식단(케토)의 매크로 비율 계산
    func testCalculateMacroRatios_HighFat_ReturnsHighFatRatio() {
        // Given: High fat macros (50g carbs, 100g protein, 150g fat)
        // Total calories: (50*4) + (100*4) + (150*9) = 200 + 400 + 1350 = 1950 kcal
        // Ratios: carbs 10.3%, protein 20.5%, fat 69.2%
        let carbs = Decimal(50.0)
        let protein = Decimal(100.0)
        let fat = Decimal(150.0)

        // When: Calculating macro ratios
        let result = NutritionCalculator.calculateMacroRatios(
            carbs: carbs,
            protein: protein,
            fat: fat
        )

        // Then: Fat ratio should be highest
        XCTAssertNotNil(result.fatRatio)
        XCTAssertTrue(result.fatRatio! > Decimal(65), "Fat ratio should be > 65%")
        XCTAssertTrue(result.fatRatio! > result.carbsRatio!, "Fat should be higher than carbs")
        XCTAssertTrue(result.fatRatio! > result.proteinRatio!, "Fat should be higher than protein")
    }

    /// Test: Calculate macro ratios for zero macros
    ///
    /// 테스트: 영양소가 없는 경우의 매크로 비율 계산
    func testCalculateMacroRatios_ZeroMacros_ReturnsNil() {
        // Given: No macros
        let carbs = Decimal(0)
        let protein = Decimal(0)
        let fat = Decimal(0)

        // When: Calculating macro ratios
        let result = NutritionCalculator.calculateMacroRatios(
            carbs: carbs,
            protein: protein,
            fat: fat
        )

        // Then: Should return nil for all ratios
        XCTAssertNil(result.carbsRatio, "Carbs ratio should be nil when total calories is 0")
        XCTAssertNil(result.proteinRatio, "Protein ratio should be nil when total calories is 0")
        XCTAssertNil(result.fatRatio, "Fat ratio should be nil when total calories is 0")
    }

    /// Test: Calculate macro ratios totals to 100%
    ///
    /// 테스트: 매크로 비율 합계가 100%인지 확인
    func testCalculateMacroRatios_TotalsTo100Percent() {
        // Given: Various macro combinations
        let testCases: [(carbs: Decimal, protein: Decimal, fat: Decimal)] = [
            (Decimal(250), Decimal(125), Decimal(55)),
            (Decimal(100), Decimal(50), Decimal(30)),
            (Decimal(350), Decimal(175), Decimal(77))
        ]

        for testCase in testCases {
            // When: Calculating macro ratios
            let result = NutritionCalculator.calculateMacroRatios(
                carbs: testCase.carbs,
                protein: testCase.protein,
                fat: testCase.fat
            )

            // Then: Sum should be ~100% (allowing 0.5% rounding tolerance)
            let sum = (result.carbsRatio ?? 0) + (result.proteinRatio ?? 0) + (result.fatRatio ?? 0)
            XCTAssertTrue(
                sum >= Decimal(99.5) && sum <= Decimal(100.5),
                "Sum of ratios should be ~100%, got \(sum)% for macros C:\(testCase.carbs) P:\(testCase.protein) F:\(testCase.fat)"
            )
        }
    }

    // MARK: - Serving Conversion Tests

    /// Test: Convert grams to servings
    ///
    /// 테스트: 그램을 인분으로 변환
    func testGramsToServings_ValidValues_ReturnsCorrectServings() {
        // Given: Various gram amounts
        let testCases: [(grams: Decimal, expected: Decimal)] = [
            (Decimal(210), Decimal(1.0)),    // 1 serving
            (Decimal(105), Decimal(0.5)),    // 0.5 serving
            (Decimal(315), Decimal(1.5)),    // 1.5 servings
            (Decimal(420), Decimal(2.0))     // 2 servings
        ]

        for testCase in testCases {
            // When: Converting grams to servings
            let result = NutritionCalculator.gramsToServings(
                grams: testCase.grams,
                servingSize: Decimal(210)
            )

            // Then: Should return correct servings
            XCTAssertEqual(
                result,
                testCase.expected,
                "\(testCase.grams)g should convert to \(testCase.expected) servings"
            )
        }
    }

    /// Test: Convert grams to servings with zero serving size
    ///
    /// 테스트: 인분 크기가 0일 때 그램을 인분으로 변환
    func testGramsToServings_ZeroServingSize_ReturnsZero() {
        // Given: Zero serving size
        let grams = Decimal(100)
        let servingSize = Decimal(0)

        // When: Converting grams to servings
        let result = NutritionCalculator.gramsToServings(
            grams: grams,
            servingSize: servingSize
        )

        // Then: Should return 0 to avoid division by zero
        XCTAssertEqual(result, Decimal(0), "Should return 0 when serving size is 0")
    }

    /// Test: Convert servings to grams
    ///
    /// 테스트: 인분을 그램으로 변환
    func testServingsToGrams_ValidValues_ReturnsCorrectGrams() {
        // Given: Various serving amounts
        let testCases: [(servings: Decimal, expected: Decimal)] = [
            (Decimal(1.0), Decimal(210)),    // 1 serving
            (Decimal(0.5), Decimal(105)),    // 0.5 serving
            (Decimal(1.5), Decimal(315)),    // 1.5 servings
            (Decimal(2.0), Decimal(420))     // 2 servings
        ]

        for testCase in testCases {
            // When: Converting servings to grams
            let result = NutritionCalculator.servingsToGrams(
                servings: testCase.servings,
                servingSize: Decimal(210)
            )

            // Then: Should return correct grams
            XCTAssertEqual(
                result,
                testCase.expected,
                "\(testCase.servings) servings should convert to \(testCase.expected)g"
            )
        }
    }

    /// Test: Round trip conversion (grams -> servings -> grams)
    ///
    /// 테스트: 왕복 변환 (그램 -> 인분 -> 그램)
    func testConversion_RoundTrip_ReturnsOriginalValue() {
        // Given: Original gram amount
        let originalGrams = Decimal(157.5)
        let servingSize = Decimal(210)

        // When: Converting to servings and back to grams
        let servings = NutritionCalculator.gramsToServings(
            grams: originalGrams,
            servingSize: servingSize
        )
        let convertedGrams = NutritionCalculator.servingsToGrams(
            servings: servings,
            servingSize: servingSize
        )

        // Then: Should return original value
        XCTAssertEqual(
            convertedGrams.rounded(2),
            originalGrams.rounded(2),
            "Round trip conversion should return original value"
        )
    }
}
