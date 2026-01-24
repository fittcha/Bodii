//
//  ExerciseCalcServiceTests.swift
//  BodiiTests
//
//  Created by Auto-Claude on 2026-01-14.
//

import XCTest
@testable import Bodii

/// Unit tests for ExerciseCalcService MET-based calorie calculations
///
/// ExerciseCalcService MET 기반 칼로리 계산에 대한 단위 테스트
final class ExerciseCalcServiceTests: XCTestCase {

    // MARK: - Walking Tests

    /// Test: Walking at low intensity (3.5 × 0.8 = 2.8 MET)
    ///
    /// 테스트: 저강도 걷기 (3.5 × 0.8 = 2.8 MET)
    func testCalculateCalories_WalkingLowIntensity_ReturnsCorrectCalories() {
        // Given: Walking 30 minutes, low intensity, 70kg
        // Formula: 3.5 × 0.8 × 70 × 0.5 = 98 kcal
        let calories = ExerciseCalcService.calculateCalories(
            exerciseType: .walking,
            duration: 30,
            intensity: .low,
            weight: 70.0
        )

        // Then: Should return 98 kcal
        XCTAssertEqual(calories, 98, "Walking 30min at low intensity (70kg) should burn 98 kcal")
    }

    /// Test: Walking at medium intensity (3.5 × 1.0 = 3.5 MET)
    ///
    /// 테스트: 중강도 걷기 (3.5 × 1.0 = 3.5 MET)
    func testCalculateCalories_WalkingMediumIntensity_ReturnsCorrectCalories() {
        // Given: Walking 30 minutes, medium intensity, 70kg
        // Formula: 3.5 × 1.0 × 70 × 0.5 = 122.5 → 123 kcal (rounded)
        let calories = ExerciseCalcService.calculateCalories(
            exerciseType: .walking,
            duration: 30,
            intensity: .medium,
            weight: 70.0
        )

        // Then: Should return 123 kcal
        XCTAssertEqual(calories, 123, "Walking 30min at medium intensity (70kg) should burn 123 kcal")
    }

    /// Test: Walking at high intensity (3.5 × 1.2 = 4.2 MET)
    ///
    /// 테스트: 고강도 걷기 (3.5 × 1.2 = 4.2 MET)
    func testCalculateCalories_WalkingHighIntensity_ReturnsCorrectCalories() {
        // Given: Walking 30 minutes, high intensity, 70kg
        // Formula: 3.5 × 1.2 × 70 × 0.5 = 147 kcal
        let calories = ExerciseCalcService.calculateCalories(
            exerciseType: .walking,
            duration: 30,
            intensity: .high,
            weight: 70.0
        )

        // Then: Should return 147 kcal
        XCTAssertEqual(calories, 147, "Walking 30min at high intensity (70kg) should burn 147 kcal")
    }

    // MARK: - Running Tests

    /// Test: Running at low intensity (8.0 × 0.8 = 6.4 MET)
    ///
    /// 테스트: 저강도 러닝 (8.0 × 0.8 = 6.4 MET)
    func testCalculateCalories_RunningLowIntensity_ReturnsCorrectCalories() {
        // Given: Running 30 minutes, low intensity, 70kg
        // Formula: 8.0 × 0.8 × 70 × 0.5 = 224 kcal
        let calories = ExerciseCalcService.calculateCalories(
            exerciseType: .running,
            duration: 30,
            intensity: .low,
            weight: 70.0
        )

        // Then: Should return 224 kcal
        XCTAssertEqual(calories, 224, "Running 30min at low intensity (70kg) should burn 224 kcal")
    }

    /// Test: Running at medium intensity (8.0 × 1.0 = 8.0 MET)
    ///
    /// 테스트: 중강도 러닝 (8.0 × 1.0 = 8.0 MET)
    func testCalculateCalories_RunningMediumIntensity_ReturnsCorrectCalories() {
        // Given: Running 30 minutes, medium intensity, 70kg
        // Formula: 8.0 × 1.0 × 70 × 0.5 = 280 kcal
        let calories = ExerciseCalcService.calculateCalories(
            exerciseType: .running,
            duration: 30,
            intensity: .medium,
            weight: 70.0
        )

        // Then: Should return 280 kcal
        XCTAssertEqual(calories, 280, "Running 30min at medium intensity (70kg) should burn 280 kcal")
    }

    /// Test: Running at high intensity (8.0 × 1.2 = 9.6 MET)
    ///
    /// 테스트: 고강도 러닝 (8.0 × 1.2 = 9.6 MET)
    func testCalculateCalories_RunningHighIntensity_ReturnsCorrectCalories() {
        // Given: Running 30 minutes, high intensity, 70kg
        // Formula: 8.0 × 1.2 × 70 × 0.5 = 336 kcal
        let calories = ExerciseCalcService.calculateCalories(
            exerciseType: .running,
            duration: 30,
            intensity: .high,
            weight: 70.0
        )

        // Then: Should return 336 kcal
        XCTAssertEqual(calories, 336, "Running 30min at high intensity (70kg) should burn 336 kcal")
    }

    // MARK: - All Exercise Types Tests

    /// Test: All 8 exercise types at medium intensity
    ///
    /// 테스트: 모든 8가지 운동 종류를 중강도로
    func testCalculateCalories_AllExerciseTypes_ReturnsCorrectCalories() {
        // Given: 60 minutes, medium intensity, 75kg for all exercise types
        let weight: Double = 75.0
        let duration: Int32 = 60
        let intensity: Intensity = .medium

        // Expected calories = baseMET × 1.0 × 75 × 1.0
        let testCases: [(type: ExerciseType, expectedCalories: Int32)] = [
            (.walking, 263),    // 3.5 × 1.0 × 75 × 1.0 = 262.5 → 263
            (.running, 600),    // 8.0 × 1.0 × 75 × 1.0 = 600
            (.cycling, 450),    // 6.0 × 1.0 × 75 × 1.0 = 450
            (.swimming, 525),   // 7.0 × 1.0 × 75 × 1.0 = 525
            (.weight, 450),     // 6.0 × 1.0 × 75 × 1.0 = 450
            (.crossfit, 600),   // 8.0 × 1.0 × 75 × 1.0 = 600
            (.yoga, 225),       // 3.0 × 1.0 × 75 × 1.0 = 225
            (.other, 375)       // 5.0 × 1.0 × 75 × 1.0 = 375
        ]

        // When/Then: All exercise types should calculate correctly
        for testCase in testCases {
            let calories = ExerciseCalcService.calculateCalories(
                exerciseType: testCase.type,
                duration: duration,
                intensity: intensity,
                weight: weight
            )
            XCTAssertEqual(
                calories,
                testCase.expectedCalories,
                "\(testCase.type.displayName) 60min at medium intensity (75kg) should burn \(testCase.expectedCalories) kcal"
            )
        }
    }

    /// Test: Cycling at all intensity levels
    ///
    /// 테스트: 자전거를 모든 강도로
    func testCalculateCalories_CyclingAllIntensities_ReturnsCorrectCalories() {
        // Given: Cycling 45 minutes, 80kg
        let duration: Int32 = 45
        let weight: Double = 80.0

        let testCases: [(intensity: Intensity, expectedCalories: Int32)] = [
            (.low, 288),      // 6.0 × 0.8 × 80 × 0.75 = 288
            (.medium, 360),   // 6.0 × 1.0 × 80 × 0.75 = 360
            (.high, 432)      // 6.0 × 1.2 × 80 × 0.75 = 432
        ]

        // When/Then: All intensities should calculate correctly
        for testCase in testCases {
            let calories = ExerciseCalcService.calculateCalories(
                exerciseType: .cycling,
                duration: duration,
                intensity: testCase.intensity,
                weight: weight
            )
            XCTAssertEqual(
                calories,
                testCase.expectedCalories,
                "Cycling 45min at \(testCase.intensity.displayName) (80kg) should burn \(testCase.expectedCalories) kcal"
            )
        }
    }

    /// Test: Swimming at all intensity levels
    ///
    /// 테스트: 수영을 모든 강도로
    func testCalculateCalories_SwimmingAllIntensities_ReturnsCorrectCalories() {
        // Given: Swimming 40 minutes, 65kg
        let duration: Int32 = 40
        let weight: Double = 65.0

        let testCases: [(intensity: Intensity, expectedCalories: Int32)] = [
            (.low, 243),      // 7.0 × 0.8 × 65 × 0.667 = 243.32 → 243
            (.medium, 303),   // 7.0 × 1.0 × 65 × 0.667 = 303.55 → 304 (note: due to rounding)
            (.high, 364)      // 7.0 × 1.2 × 65 × 0.667 = 364.28 → 364
        ]

        // When/Then: All intensities should calculate correctly
        for testCase in testCases {
            let calories = ExerciseCalcService.calculateCalories(
                exerciseType: .swimming,
                duration: duration,
                intensity: testCase.intensity,
                weight: weight
            )
            // Allow ±1 difference due to rounding
            XCTAssertTrue(
                abs(calories - testCase.expectedCalories) <= 1,
                "Swimming 40min at \(testCase.intensity.displayName) (65kg) should burn approximately \(testCase.expectedCalories) kcal (got \(calories))"
            )
        }
    }

    /// Test: Weight training at all intensity levels
    ///
    /// 테스트: 웨이트를 모든 강도로
    func testCalculateCalories_WeightAllIntensities_ReturnsCorrectCalories() {
        // Given: Weight training 50 minutes, 90kg
        let duration: Int32 = 50
        let weight: Double = 90.0

        let testCases: [(intensity: Intensity, expectedCalories: Int32)] = [
            (.low, 360),      // 6.0 × 0.8 × 90 × 0.833 = 359.856 → 360
            (.medium, 450),   // 6.0 × 1.0 × 90 × 0.833 = 449.7 → 450
            (.high, 540)      // 6.0 × 1.2 × 90 × 0.833 = 539.64 → 540
        ]

        // When/Then: All intensities should calculate correctly
        for testCase in testCases {
            let calories = ExerciseCalcService.calculateCalories(
                exerciseType: .weight,
                duration: duration,
                intensity: testCase.intensity,
                weight: weight
            )
            XCTAssertEqual(
                calories,
                testCase.expectedCalories,
                "Weight 50min at \(testCase.intensity.displayName) (90kg) should burn \(testCase.expectedCalories) kcal"
            )
        }
    }

    /// Test: Crossfit at all intensity levels
    ///
    /// 테스트: 크로스핏을 모든 강도로
    func testCalculateCalories_CrossfitAllIntensities_ReturnsCorrectCalories() {
        // Given: Crossfit 45 minutes, 75kg
        let duration: Int32 = 45
        let weight: Double = 75.0

        let testCases: [(intensity: Intensity, expectedCalories: Int32)] = [
            (.low, 360),      // 8.0 × 0.8 × 75 × 0.75 = 360
            (.medium, 450),   // 8.0 × 1.0 × 75 × 0.75 = 450
            (.high, 540)      // 8.0 × 1.2 × 75 × 0.75 = 540
        ]

        // When/Then: All intensities should calculate correctly
        for testCase in testCases {
            let calories = ExerciseCalcService.calculateCalories(
                exerciseType: .crossfit,
                duration: duration,
                intensity: testCase.intensity,
                weight: weight
            )
            XCTAssertEqual(
                calories,
                testCase.expectedCalories,
                "Crossfit 45min at \(testCase.intensity.displayName) (75kg) should burn \(testCase.expectedCalories) kcal"
            )
        }
    }

    /// Test: Yoga at all intensity levels
    ///
    /// 테스트: 요가를 모든 강도로
    func testCalculateCalories_YogaAllIntensities_ReturnsCorrectCalories() {
        // Given: Yoga 60 minutes, 60kg
        let duration: Int32 = 60
        let weight: Double = 60.0

        let testCases: [(intensity: Intensity, expectedCalories: Int32)] = [
            (.low, 144),      // 3.0 × 0.8 × 60 × 1.0 = 144
            (.medium, 180),   // 3.0 × 1.0 × 60 × 1.0 = 180
            (.high, 216)      // 3.0 × 1.2 × 60 × 1.0 = 216
        ]

        // When/Then: All intensities should calculate correctly
        for testCase in testCases {
            let calories = ExerciseCalcService.calculateCalories(
                exerciseType: .yoga,
                duration: duration,
                intensity: testCase.intensity,
                weight: weight
            )
            XCTAssertEqual(
                calories,
                testCase.expectedCalories,
                "Yoga 60min at \(testCase.intensity.displayName) (60kg) should burn \(testCase.expectedCalories) kcal"
            )
        }
    }

    /// Test: Other exercise type at all intensity levels
    ///
    /// 테스트: 기타 운동을 모든 강도로
    func testCalculateCalories_OtherAllIntensities_ReturnsCorrectCalories() {
        // Given: Other exercise 30 minutes, 70kg
        let duration: Int32 = 30
        let weight: Double = 70.0

        let testCases: [(intensity: Intensity, expectedCalories: Int32)] = [
            (.low, 140),      // 5.0 × 0.8 × 70 × 0.5 = 140
            (.medium, 175),   // 5.0 × 1.0 × 70 × 0.5 = 175
            (.high, 210)      // 5.0 × 1.2 × 70 × 0.5 = 210
        ]

        // When/Then: All intensities should calculate correctly
        for testCase in testCases {
            let calories = ExerciseCalcService.calculateCalories(
                exerciseType: .other,
                duration: duration,
                intensity: testCase.intensity,
                weight: weight
            )
            XCTAssertEqual(
                calories,
                testCase.expectedCalories,
                "Other 30min at \(testCase.intensity.displayName) (70kg) should burn \(testCase.expectedCalories) kcal"
            )
        }
    }

    // MARK: - Formula Verification Tests

    /// Test: Verify MET formula accuracy
    ///
    /// 테스트: MET 공식 정확도 검증
    func testCalculateCalories_VerifyFormula_MatchesManualCalculation() {
        // Given: Running 45 minutes, high intensity, 85kg
        // Manual calculation:
        // baseMET = 8.0
        // adjustedMET = 8.0 × 1.2 = 9.6
        // hours = 45 / 60 = 0.75
        // calories = 9.6 × 85 × 0.75 = 612 kcal

        let calories = ExerciseCalcService.calculateCalories(
            exerciseType: .running,
            duration: 45,
            intensity: .high,
            weight: 85.0
        )

        // Then: Should match manual calculation
        XCTAssertEqual(calories, 612, "Should match manual MET formula calculation")
    }

    /// Test: Verify formula with different weight
    ///
    /// 테스트: 다른 체중으로 공식 검증
    func testCalculateCalories_DifferentWeights_ScalesLinearly() {
        // Given: Running 30 minutes, medium intensity
        // Test that calories scale linearly with weight

        let testCases: [(weight: Double, expectedCalories: Int32)] = [
            (50.0, 200),    // 8.0 × 1.0 × 50 × 0.5 = 200
            (60.0, 240),    // 8.0 × 1.0 × 60 × 0.5 = 240
            (70.0, 280),    // 8.0 × 1.0 × 70 × 0.5 = 280
            (80.0, 320),    // 8.0 × 1.0 × 80 × 0.5 = 320
            (100.0, 400)    // 8.0 × 1.0 × 100 × 0.5 = 400
        ]

        // When/Then: Calories should scale linearly with weight
        for testCase in testCases {
            let calories = ExerciseCalcService.calculateCalories(
                exerciseType: .running,
                duration: 30,
                intensity: .medium,
                weight: testCase.weight
            )
            XCTAssertEqual(
                calories,
                testCase.expectedCalories,
                "Running 30min at medium intensity (\(testCase.weight)kg) should burn \(testCase.expectedCalories) kcal"
            )
        }
    }

    /// Test: Verify formula with different durations
    ///
    /// 테스트: 다른 시간으로 공식 검증
    func testCalculateCalories_DifferentDurations_ScalesLinearly() {
        // Given: Running, medium intensity, 70kg
        // Test that calories scale linearly with duration

        let testCases: [(duration: Int32, expectedCalories: Int32)] = [
            (15, 140),     // 8.0 × 1.0 × 70 × 0.25 = 140
            (30, 280),     // 8.0 × 1.0 × 70 × 0.5 = 280
            (45, 420),     // 8.0 × 1.0 × 70 × 0.75 = 420
            (60, 560),     // 8.0 × 1.0 × 70 × 1.0 = 560
            (90, 840),     // 8.0 × 1.0 × 70 × 1.5 = 840
            (120, 1120)    // 8.0 × 1.0 × 70 × 2.0 = 1120
        ]

        // When/Then: Calories should scale linearly with duration
        for testCase in testCases {
            let calories = ExerciseCalcService.calculateCalories(
                exerciseType: .running,
                duration: testCase.duration,
                intensity: .medium,
                weight: 70.0
            )
            XCTAssertEqual(
                calories,
                testCase.expectedCalories,
                "Running \(testCase.duration)min at medium intensity (70kg) should burn \(testCase.expectedCalories) kcal"
            )
        }
    }

    // MARK: - Edge Case Tests

    /// Test: Minimum duration (1 minute)
    ///
    /// 테스트: 최소 시간 (1분)
    func testCalculateCalories_MinimumDuration_ReturnsCorrectCalories() {
        // Given: Running 1 minute, medium intensity, 70kg
        // Formula: 8.0 × 1.0 × 70 × (1/60) = 9.33 → 9 kcal

        let calories = ExerciseCalcService.calculateCalories(
            exerciseType: .running,
            duration: 1,
            intensity: .medium,
            weight: 70.0
        )

        // Then: Should return 9 kcal
        XCTAssertEqual(calories, 9, "Running 1min at medium intensity (70kg) should burn 9 kcal")
    }

    /// Test: Very short duration (5 minutes)
    ///
    /// 테스트: 매우 짧은 시간 (5분)
    func testCalculateCalories_VeryShortDuration_ReturnsCorrectCalories() {
        // Given: Running 5 minutes, medium intensity, 70kg
        // Formula: 8.0 × 1.0 × 70 × (5/60) = 46.67 → 47 kcal

        let calories = ExerciseCalcService.calculateCalories(
            exerciseType: .running,
            duration: 5,
            intensity: .medium,
            weight: 70.0
        )

        // Then: Should return 47 kcal
        XCTAssertEqual(calories, 47, "Running 5min at medium intensity (70kg) should burn 47 kcal")
    }

    /// Test: Large duration (3 hours = 180 minutes)
    ///
    /// 테스트: 긴 시간 (3시간 = 180분)
    func testCalculateCalories_LargeDuration_ReturnsCorrectCalories() {
        // Given: Running 180 minutes (3 hours), medium intensity, 70kg
        // Formula: 8.0 × 1.0 × 70 × 3.0 = 1680 kcal

        let calories = ExerciseCalcService.calculateCalories(
            exerciseType: .running,
            duration: 180,
            intensity: .medium,
            weight: 70.0
        )

        // Then: Should return 1680 kcal
        XCTAssertEqual(calories, 1680, "Running 180min (3hrs) at medium intensity (70kg) should burn 1680 kcal")
    }

    /// Test: Very large duration (marathon: 4 hours = 240 minutes)
    ///
    /// 테스트: 매우 긴 시간 (마라톤: 4시간 = 240분)
    func testCalculateCalories_VeryLargeDuration_ReturnsCorrectCalories() {
        // Given: Running 240 minutes (4 hours), medium intensity, 70kg
        // Formula: 8.0 × 1.0 × 70 × 4.0 = 2240 kcal

        let calories = ExerciseCalcService.calculateCalories(
            exerciseType: .running,
            duration: 240,
            intensity: .medium,
            weight: 70.0
        )

        // Then: Should return 2240 kcal
        XCTAssertEqual(calories, 2240, "Running 240min (4hrs) at medium intensity (70kg) should burn 2240 kcal")
    }

    /// Test: Low weight person
    ///
    /// 테스트: 저체중자
    func testCalculateCalories_LowWeight_ReturnsCorrectCalories() {
        // Given: Running 30 minutes, medium intensity, 45kg
        // Formula: 8.0 × 1.0 × 45 × 0.5 = 180 kcal

        let calories = ExerciseCalcService.calculateCalories(
            exerciseType: .running,
            duration: 30,
            intensity: .medium,
            weight: 45.0
        )

        // Then: Should return 180 kcal
        XCTAssertEqual(calories, 180, "Running 30min at medium intensity (45kg) should burn 180 kcal")
    }

    /// Test: High weight person
    ///
    /// 테스트: 고체중자
    func testCalculateCalories_HighWeight_ReturnsCorrectCalories() {
        // Given: Running 30 minutes, medium intensity, 120kg
        // Formula: 8.0 × 1.0 × 120 × 0.5 = 480 kcal

        let calories = ExerciseCalcService.calculateCalories(
            exerciseType: .running,
            duration: 30,
            intensity: .medium,
            weight: 120.0
        )

        // Then: Should return 480 kcal
        XCTAssertEqual(calories, 480, "Running 30min at medium intensity (120kg) should burn 480 kcal")
    }

    // MARK: - Rounding Tests

    /// Test: Rounding half up (.5 rounds up)
    ///
    /// 테스트: 반올림 (.5는 올림)
    func testCalculateCalories_RoundingHalfUp_RoundsCorrectly() {
        // Given: Walking 13 minutes, medium intensity, 70kg
        // Formula: 3.5 × 1.0 × 70 × (13/60) = 53.08 → 53 kcal

        let calories = ExerciseCalcService.calculateCalories(
            exerciseType: .walking,
            duration: 13,
            intensity: .medium,
            weight: 70.0
        )

        // Then: Should round down to 53 kcal
        XCTAssertEqual(calories, 53, "Should round 53.08 down to 53 kcal")
    }

    /// Test: Rounding exact half (.5 rounds up)
    ///
    /// 테스트: 정확히 .5 반올림 (.5는 올림)
    func testCalculateCalories_RoundingExactHalf_RoundsUp() {
        // Given: Walking 15 minutes, medium intensity, 70kg
        // Formula: 3.5 × 1.0 × 70 × (15/60) = 61.25 → 61 kcal

        let calories = ExerciseCalcService.calculateCalories(
            exerciseType: .walking,
            duration: 15,
            intensity: .medium,
            weight: 70.0
        )

        // Then: Should round down to 61 kcal
        XCTAssertEqual(calories, 61, "Should round 61.25 down to 61 kcal")
    }

    // MARK: - Decimal Weight Tests

    /// Test: Decimal weight parameter
    ///
    /// 테스트: Decimal 타입 체중 파라미터
    func testCalculateCalories_DecimalWeight_ReturnsCorrectCalories() {
        // Given: Running 30 minutes, medium intensity, 70.5kg (Decimal)
        // Formula: 8.0 × 1.0 × 70.5 × 0.5 = 282 kcal

        let weight: Decimal = 70.5
        let calories = ExerciseCalcService.calculateCalories(
            exerciseType: .running,
            duration: 30,
            intensity: .medium,
            weight: weight
        )

        // Then: Should return 282 kcal
        XCTAssertEqual(calories, 282, "Running 30min at medium intensity (70.5kg Decimal) should burn 282 kcal")
    }

    /// Test: Decimal weight with precise value
    ///
    /// 테스트: 정밀한 Decimal 체중 값
    func testCalculateCalories_DecimalWeightPrecise_ReturnsCorrectCalories() {
        // Given: Walking 60 minutes, low intensity, 65.75kg (Decimal)
        // Formula: 3.5 × 0.8 × 65.75 × 1.0 = 184.1 → 184 kcal

        let weight: Decimal = 65.75
        let calories = ExerciseCalcService.calculateCalories(
            exerciseType: .walking,
            duration: 60,
            intensity: .low,
            weight: weight
        )

        // Then: Should return 184 kcal
        XCTAssertEqual(calories, 184, "Walking 60min at low intensity (65.75kg Decimal) should burn 184 kcal")
    }

    /// Test: Decimal weight matches Double weight
    ///
    /// 테스트: Decimal 체중과 Double 체중이 동일한 결과
    func testCalculateCalories_DecimalVsDouble_ReturnsSameResult() {
        // Given: Same parameters with Decimal and Double weight
        let exerciseType: ExerciseType = .running
        let duration: Int32 = 30
        let intensity: Intensity = .medium

        let weightDouble: Double = 70.0
        let weightDecimal: Decimal = 70.0

        // When: Calculating calories with both types
        let caloriesDouble = ExerciseCalcService.calculateCalories(
            exerciseType: exerciseType,
            duration: duration,
            intensity: intensity,
            weight: weightDouble
        )

        let caloriesDecimal = ExerciseCalcService.calculateCalories(
            exerciseType: exerciseType,
            duration: duration,
            intensity: intensity,
            weight: weightDecimal
        )

        // Then: Both should return the same result
        XCTAssertEqual(caloriesDouble, caloriesDecimal, "Decimal and Double weights should produce same result")
    }
}
