//
//  GoalValidationServiceTests.swift
//  BodiiTests
//
//  Created by Auto-Claude on 2026-01-18.
//

import XCTest
@testable import Bodii

/// Unit tests for GoalValidationService validation logic
///
/// GoalValidationService 목표 검증 로직에 대한 단위 테스트
final class GoalValidationServiceTests: XCTestCase {

    // MARK: - Test Data

    /// Sample user ID for testing
    ///
    /// 테스트용 샘플 사용자 ID
    private let sampleUserId = UUID()

    // MARK: - Minimum Target Validation Tests

    /// Test: Valid goal with single target (weight only)
    ///
    /// 테스트: 단일 목표(체중만)로 유효한 목표
    func testValidate_SingleWeightTarget_Success() throws {
        // Given: Goal with only weight target
        let goal = Goal(
            id: UUID(),
            userId: sampleUserId,
            goalType: .lose,
            targetWeight: Decimal(65.0),
            targetBodyFatPct: nil,
            targetMuscleMass: nil,
            weeklyWeightRate: Decimal(-0.5),
            weeklyFatPctRate: nil,
            weeklyMuscleRate: nil,
            startWeight: Decimal(70.0),
            startBodyFatPct: nil,
            startMuscleMass: nil,
            startBMR: nil,
            startTDEE: nil,
            dailyCalorieTarget: nil,
            isActive: true,
            createdAt: Date(),
            updatedAt: Date()
        )

        // When/Then: Should not throw
        XCTAssertNoThrow(try GoalValidationService.validate(goal: goal))
    }

    /// Test: Valid goal with multiple targets
    ///
    /// 테스트: 복수 목표로 유효한 목표
    func testValidate_MultipleTargets_Success() throws {
        // Given: Goal with weight, body fat, and muscle targets
        let goal = Goal(
            id: UUID(),
            userId: sampleUserId,
            goalType: .lose,
            targetWeight: Decimal(65.0),
            targetBodyFatPct: Decimal(18.0),
            targetMuscleMass: Decimal(30.0),
            weeklyWeightRate: Decimal(-0.5),
            weeklyFatPctRate: Decimal(-0.5),
            weeklyMuscleRate: Decimal(0.0),
            startWeight: Decimal(70.0),
            startBodyFatPct: Decimal(22.0),
            startMuscleMass: Decimal(30.0),
            startBMR: nil,
            startTDEE: nil,
            dailyCalorieTarget: nil,
            isActive: true,
            createdAt: Date(),
            updatedAt: Date()
        )

        // When/Then: Should not throw
        XCTAssertNoThrow(try GoalValidationService.validate(goal: goal))
    }

    /// Test: Invalid goal with no targets
    ///
    /// 테스트: 목표가 없는 무효한 목표
    func testValidate_NoTargets_ThrowsError() {
        // Given: Goal with no targets
        let goal = Goal(
            id: UUID(),
            userId: sampleUserId,
            goalType: .lose,
            targetWeight: nil,
            targetBodyFatPct: nil,
            targetMuscleMass: nil,
            weeklyWeightRate: nil,
            weeklyFatPctRate: nil,
            weeklyMuscleRate: nil,
            startWeight: Decimal(70.0),
            startBodyFatPct: nil,
            startMuscleMass: nil,
            startBMR: nil,
            startTDEE: nil,
            dailyCalorieTarget: nil,
            isActive: true,
            createdAt: Date(),
            updatedAt: Date()
        )

        // When/Then: Should throw noTargetsSet error
        XCTAssertThrowsError(try GoalValidationService.validate(goal: goal)) { error in
            guard let validationError = error as? GoalValidationError else {
                XCTFail("Expected GoalValidationError")
                return
            }

            if case .noTargetsSet = validationError {
                // Success
            } else {
                XCTFail("Expected .noTargetsSet error, got \(validationError)")
            }
        }
    }

    // MARK: - Weekly Rate Validation Tests

    /// Test: Valid weekly weight rate within recommended range
    ///
    /// 테스트: 권장 범위 내의 유효한 주간 체중 변화율
    func testValidate_ValidWeeklyWeightRate_Success() throws {
        // Given: Goal with weekly weight rate -0.5 kg (within -2.0 to 2.0 range)
        let goal = Goal(
            id: UUID(),
            userId: sampleUserId,
            goalType: .lose,
            targetWeight: Decimal(65.0),
            targetBodyFatPct: nil,
            targetMuscleMass: nil,
            weeklyWeightRate: Decimal(-0.5),
            weeklyFatPctRate: nil,
            weeklyMuscleRate: nil,
            startWeight: Decimal(70.0),
            startBodyFatPct: nil,
            startMuscleMass: nil,
            startBMR: nil,
            startTDEE: nil,
            dailyCalorieTarget: nil,
            isActive: true,
            createdAt: Date(),
            updatedAt: Date()
        )

        // When/Then: Should not throw
        XCTAssertNoThrow(try GoalValidationService.validate(goal: goal))
    }

    /// Test: Unrealistic weekly weight rate (too fast)
    ///
    /// 테스트: 비현실적인 주간 체중 변화율 (너무 빠름)
    func testValidate_UnrealisticWeeklyWeightRate_ThrowsError() {
        // Given: Goal with weekly weight rate -3.0 kg (exceeds -2.0 limit)
        let goal = Goal(
            id: UUID(),
            userId: sampleUserId,
            goalType: .lose,
            targetWeight: Decimal(60.0),
            targetBodyFatPct: nil,
            targetMuscleMass: nil,
            weeklyWeightRate: Decimal(-3.0),
            weeklyFatPctRate: nil,
            weeklyMuscleRate: nil,
            startWeight: Decimal(70.0),
            startBodyFatPct: nil,
            startMuscleMass: nil,
            startBMR: nil,
            startTDEE: nil,
            dailyCalorieTarget: nil,
            isActive: true,
            createdAt: Date(),
            updatedAt: Date()
        )

        // When/Then: Should throw unrealisticRate error
        XCTAssertThrowsError(try GoalValidationService.validate(goal: goal)) { error in
            guard let validationError = error as? GoalValidationError else {
                XCTFail("Expected GoalValidationError")
                return
            }

            if case .unrealisticRate = validationError {
                // Success
            } else {
                XCTFail("Expected .unrealisticRate error, got \(validationError)")
            }
        }
    }

    /// Test: Unrealistic weekly body fat rate
    ///
    /// 테스트: 비현실적인 주간 체지방률 변화율
    func testValidate_UnrealisticWeeklyBodyFatRate_ThrowsError() {
        // Given: Goal with weekly body fat rate -4.0% (exceeds -3.0% limit)
        let goal = Goal(
            id: UUID(),
            userId: sampleUserId,
            goalType: .lose,
            targetWeight: nil,
            targetBodyFatPct: Decimal(15.0),
            targetMuscleMass: nil,
            weeklyWeightRate: nil,
            weeklyFatPctRate: Decimal(-4.0),
            weeklyMuscleRate: nil,
            startWeight: nil,
            startBodyFatPct: Decimal(25.0),
            startMuscleMass: nil,
            startBMR: nil,
            startTDEE: nil,
            dailyCalorieTarget: nil,
            isActive: true,
            createdAt: Date(),
            updatedAt: Date()
        )

        // When/Then: Should throw unrealisticRate error
        XCTAssertThrowsError(try GoalValidationService.validate(goal: goal)) { error in
            guard let validationError = error as? GoalValidationError else {
                XCTFail("Expected GoalValidationError")
                return
            }

            if case .unrealisticRate = validationError {
                // Success
            } else {
                XCTFail("Expected .unrealisticRate error, got \(validationError)")
            }
        }
    }

    /// Test: Unrealistic weekly muscle rate
    ///
    /// 테스트: 비현실적인 주간 근육량 변화율
    func testValidate_UnrealisticWeeklyMuscleRate_ThrowsError() {
        // Given: Goal with weekly muscle rate 2.0 kg (exceeds 1.0 kg limit)
        let goal = Goal(
            id: UUID(),
            userId: sampleUserId,
            goalType: .gain,
            targetWeight: nil,
            targetBodyFatPct: nil,
            targetMuscleMass: Decimal(35.0),
            weeklyWeightRate: nil,
            weeklyFatPctRate: nil,
            weeklyMuscleRate: Decimal(2.0),
            startWeight: nil,
            startBodyFatPct: nil,
            startMuscleMass: Decimal(30.0),
            startBMR: nil,
            startTDEE: nil,
            dailyCalorieTarget: nil,
            isActive: true,
            createdAt: Date(),
            updatedAt: Date()
        )

        // When/Then: Should throw unrealisticRate error
        XCTAssertThrowsError(try GoalValidationService.validate(goal: goal)) { error in
            guard let validationError = error as? GoalValidationError else {
                XCTFail("Expected GoalValidationError")
                return
            }

            if case .unrealisticRate = validationError {
                // Success
            } else {
                XCTFail("Expected .unrealisticRate error, got \(validationError)")
            }
        }
    }

    // MARK: - Goal Type Consistency Tests

    /// Test: Loss goal with decreasing weight
    ///
    /// 테스트: 체중 감소를 가진 감량 목표
    func testValidate_LossGoalWithDecreasingWeight_Success() throws {
        // Given: Loss goal with target weight < start weight
        let goal = Goal(
            id: UUID(),
            userId: sampleUserId,
            goalType: .lose,
            targetWeight: Decimal(65.0),
            targetBodyFatPct: nil,
            targetMuscleMass: nil,
            weeklyWeightRate: Decimal(-0.5),
            weeklyFatPctRate: nil,
            weeklyMuscleRate: nil,
            startWeight: Decimal(70.0),
            startBodyFatPct: nil,
            startMuscleMass: nil,
            startBMR: nil,
            startTDEE: nil,
            dailyCalorieTarget: nil,
            isActive: true,
            createdAt: Date(),
            updatedAt: Date()
        )

        // When/Then: Should not throw
        XCTAssertNoThrow(try GoalValidationService.validate(goal: goal))
    }

    /// Test: Loss goal with increasing weight (inconsistent)
    ///
    /// 테스트: 체중 증가를 가진 감량 목표 (일관성 없음)
    func testValidate_LossGoalWithIncreasingWeight_ThrowsError() {
        // Given: Loss goal with target weight >= start weight
        let goal = Goal(
            id: UUID(),
            userId: sampleUserId,
            goalType: .lose,
            targetWeight: Decimal(75.0),
            targetBodyFatPct: nil,
            targetMuscleMass: nil,
            weeklyWeightRate: Decimal(0.5),
            weeklyFatPctRate: nil,
            weeklyMuscleRate: nil,
            startWeight: Decimal(70.0),
            startBodyFatPct: nil,
            startMuscleMass: nil,
            startBMR: nil,
            startTDEE: nil,
            dailyCalorieTarget: nil,
            isActive: true,
            createdAt: Date(),
            updatedAt: Date()
        )

        // When/Then: Should throw inconsistentGoalType error
        XCTAssertThrowsError(try GoalValidationService.validate(goal: goal)) { error in
            guard let validationError = error as? GoalValidationError else {
                XCTFail("Expected GoalValidationError")
                return
            }

            if case .inconsistentGoalType = validationError {
                // Success
            } else {
                XCTFail("Expected .inconsistentGoalType error, got \(validationError)")
            }
        }
    }

    /// Test: Gain goal with increasing weight
    ///
    /// 테스트: 체중 증가를 가진 증량 목표
    func testValidate_GainGoalWithIncreasingWeight_Success() throws {
        // Given: Gain goal with target weight > start weight
        let goal = Goal(
            id: UUID(),
            userId: sampleUserId,
            goalType: .gain,
            targetWeight: Decimal(75.0),
            targetBodyFatPct: nil,
            targetMuscleMass: nil,
            weeklyWeightRate: Decimal(0.5),
            weeklyFatPctRate: nil,
            weeklyMuscleRate: nil,
            startWeight: Decimal(70.0),
            startBodyFatPct: nil,
            startMuscleMass: nil,
            startBMR: nil,
            startTDEE: nil,
            dailyCalorieTarget: nil,
            isActive: true,
            createdAt: Date(),
            updatedAt: Date()
        )

        // When/Then: Should not throw
        XCTAssertNoThrow(try GoalValidationService.validate(goal: goal))
    }

    /// Test: Gain goal with decreasing weight (inconsistent)
    ///
    /// 테스트: 체중 감소를 가진 증량 목표 (일관성 없음)
    func testValidate_GainGoalWithDecreasingWeight_ThrowsError() {
        // Given: Gain goal with target weight <= start weight
        let goal = Goal(
            id: UUID(),
            userId: sampleUserId,
            goalType: .gain,
            targetWeight: Decimal(65.0),
            targetBodyFatPct: nil,
            targetMuscleMass: nil,
            weeklyWeightRate: Decimal(-0.5),
            weeklyFatPctRate: nil,
            weeklyMuscleRate: nil,
            startWeight: Decimal(70.0),
            startBodyFatPct: nil,
            startMuscleMass: nil,
            startBMR: nil,
            startTDEE: nil,
            dailyCalorieTarget: nil,
            isActive: true,
            createdAt: Date(),
            updatedAt: Date()
        )

        // When/Then: Should throw inconsistentGoalType error
        XCTAssertThrowsError(try GoalValidationService.validate(goal: goal)) { error in
            guard let validationError = error as? GoalValidationError else {
                XCTFail("Expected GoalValidationError")
                return
            }

            if case .inconsistentGoalType = validationError {
                // Success
            } else {
                XCTFail("Expected .inconsistentGoalType error, got \(validationError)")
            }
        }
    }

    /// Test: Maintain goal with weight within tolerance
    ///
    /// 테스트: 허용 범위 내 체중을 가진 유지 목표
    func testValidate_MaintainGoalWithinTolerance_Success() throws {
        // Given: Maintain goal with target weight within ±5% of start weight
        let startWeight = Decimal(70.0)
        let targetWeight = Decimal(71.0) // 70 + (70 * 0.05) = 73.5, so 71 is within range

        let goal = Goal(
            id: UUID(),
            userId: sampleUserId,
            goalType: .maintain,
            targetWeight: targetWeight,
            targetBodyFatPct: nil,
            targetMuscleMass: nil,
            weeklyWeightRate: Decimal(0.0),
            weeklyFatPctRate: nil,
            weeklyMuscleRate: nil,
            startWeight: startWeight,
            startBodyFatPct: nil,
            startMuscleMass: nil,
            startBMR: nil,
            startTDEE: nil,
            dailyCalorieTarget: nil,
            isActive: true,
            createdAt: Date(),
            updatedAt: Date()
        )

        // When/Then: Should not throw
        XCTAssertNoThrow(try GoalValidationService.validate(goal: goal))
    }

    /// Test: Maintain goal with weight outside tolerance
    ///
    /// 테스트: 허용 범위 외 체중을 가진 유지 목표
    func testValidate_MaintainGoalOutsideTolerance_ThrowsError() {
        // Given: Maintain goal with target weight outside ±5% of start weight
        let startWeight = Decimal(70.0)
        let targetWeight = Decimal(80.0) // More than 5% change

        let goal = Goal(
            id: UUID(),
            userId: sampleUserId,
            goalType: .maintain,
            targetWeight: targetWeight,
            targetBodyFatPct: nil,
            targetMuscleMass: nil,
            weeklyWeightRate: Decimal(0.0),
            weeklyFatPctRate: nil,
            weeklyMuscleRate: nil,
            startWeight: startWeight,
            startBodyFatPct: nil,
            startMuscleMass: nil,
            startBMR: nil,
            startTDEE: nil,
            dailyCalorieTarget: nil,
            isActive: true,
            createdAt: Date(),
            updatedAt: Date()
        )

        // When/Then: Should throw inconsistentGoalType error
        XCTAssertThrowsError(try GoalValidationService.validate(goal: goal)) { error in
            guard let validationError = error as? GoalValidationError else {
                XCTFail("Expected GoalValidationError")
                return
            }

            if case .inconsistentGoalType = validationError {
                // Success
            } else {
                XCTFail("Expected .inconsistentGoalType error, got \(validationError)")
            }
        }
    }

    // MARK: - Physical Consistency Tests

    /// Test: Physically consistent multiple goals
    ///
    /// 테스트: 물리적으로 일관된 복수 목표
    func testValidate_PhysicallyConsistentMultipleGoals_Success() throws {
        // Given: Weight 65kg, Body Fat 18%, Muscle 30kg
        // Body Fat Mass = 65 × 0.18 = 11.7 kg
        // Lean Body Mass = 65 - 11.7 = 53.3 kg
        // Muscle Mass (30kg) < Lean Body Mass (53.3kg) ✓
        let goal = Goal(
            id: UUID(),
            userId: sampleUserId,
            goalType: .lose,
            targetWeight: Decimal(65.0),
            targetBodyFatPct: Decimal(18.0),
            targetMuscleMass: Decimal(30.0),
            weeklyWeightRate: Decimal(-0.5),
            weeklyFatPctRate: Decimal(-0.5),
            weeklyMuscleRate: Decimal(0.0),
            startWeight: Decimal(70.0),
            startBodyFatPct: Decimal(22.0),
            startMuscleMass: Decimal(30.0),
            startBMR: nil,
            startTDEE: nil,
            dailyCalorieTarget: nil,
            isActive: true,
            createdAt: Date(),
            updatedAt: Date()
        )

        // When/Then: Should not throw
        XCTAssertNoThrow(try GoalValidationService.validate(goal: goal))
    }

    /// Test: Physically impossible multiple goals (muscle > lean body mass)
    ///
    /// 테스트: 물리적으로 불가능한 복수 목표 (근육량 > 제지방량)
    func testValidate_PhysicallyImpossibleMultipleGoals_ThrowsError() {
        // Given: Weight 53kg, Body Fat 18%, Muscle 45kg
        // Body Fat Mass = 53 × 0.18 = 9.54 kg
        // Lean Body Mass = 53 - 9.54 = 43.46 kg
        // Muscle Mass (45kg) > Lean Body Mass (43.46kg) ✗
        let goal = Goal(
            id: UUID(),
            userId: sampleUserId,
            goalType: .lose,
            targetWeight: Decimal(53.0),
            targetBodyFatPct: Decimal(18.0),
            targetMuscleMass: Decimal(45.0),
            weeklyWeightRate: Decimal(-0.5),
            weeklyFatPctRate: Decimal(-0.5),
            weeklyMuscleRate: Decimal(0.0),
            startWeight: Decimal(70.0),
            startBodyFatPct: Decimal(22.0),
            startMuscleMass: Decimal(45.0),
            startBMR: nil,
            startTDEE: nil,
            dailyCalorieTarget: nil,
            isActive: true,
            createdAt: Date(),
            updatedAt: Date()
        )

        // When/Then: Should throw physicallyImpossible error
        XCTAssertThrowsError(try GoalValidationService.validate(goal: goal)) { error in
            guard let validationError = error as? GoalValidationError else {
                XCTFail("Expected GoalValidationError")
                return
            }

            if case .physicallyImpossible = validationError {
                // Success
            } else {
                XCTFail("Expected .physicallyImpossible error, got \(validationError)")
            }
        }
    }

    /// Test: Invalid body fat percentage (too low)
    ///
    /// 테스트: 유효하지 않은 체지방률 (너무 낮음)
    func testValidate_BodyFatPercentageTooLow_ThrowsError() {
        // Given: Body fat percentage 0.5% (below 1% limit)
        let goal = Goal(
            id: UUID(),
            userId: sampleUserId,
            goalType: .lose,
            targetWeight: Decimal(65.0),
            targetBodyFatPct: Decimal(0.5),
            targetMuscleMass: Decimal(30.0),
            weeklyWeightRate: Decimal(-0.5),
            weeklyFatPctRate: Decimal(-0.5),
            weeklyMuscleRate: Decimal(0.0),
            startWeight: Decimal(70.0),
            startBodyFatPct: Decimal(15.0),
            startMuscleMass: Decimal(30.0),
            startBMR: nil,
            startTDEE: nil,
            dailyCalorieTarget: nil,
            isActive: true,
            createdAt: Date(),
            updatedAt: Date()
        )

        // When/Then: Should throw physicallyImpossible error
        XCTAssertThrowsError(try GoalValidationService.validate(goal: goal)) { error in
            guard let validationError = error as? GoalValidationError else {
                XCTFail("Expected GoalValidationError")
                return
            }

            if case .physicallyImpossible = validationError {
                // Success
            } else {
                XCTFail("Expected .physicallyImpossible error, got \(validationError)")
            }
        }
    }

    /// Test: Invalid body fat percentage (too high)
    ///
    /// 테스트: 유효하지 않은 체지방률 (너무 높음)
    func testValidate_BodyFatPercentageTooHigh_ThrowsError() {
        // Given: Body fat percentage 65% (above 60% limit)
        let goal = Goal(
            id: UUID(),
            userId: sampleUserId,
            goalType: .lose,
            targetWeight: Decimal(100.0),
            targetBodyFatPct: Decimal(65.0),
            targetMuscleMass: Decimal(20.0),
            weeklyWeightRate: Decimal(-0.5),
            weeklyFatPctRate: Decimal(-1.0),
            weeklyMuscleRate: Decimal(0.0),
            startWeight: Decimal(110.0),
            startBodyFatPct: Decimal(70.0),
            startMuscleMass: Decimal(20.0),
            startBMR: nil,
            startTDEE: nil,
            dailyCalorieTarget: nil,
            isActive: true,
            createdAt: Date(),
            updatedAt: Date()
        )

        // When/Then: Should throw physicallyImpossible error
        XCTAssertThrowsError(try GoalValidationService.validate(goal: goal)) { error in
            guard let validationError = error as? GoalValidationError else {
                XCTFail("Expected GoalValidationError")
                return
            }

            if case .physicallyImpossible = validationError {
                // Success
            } else {
                XCTFail("Expected .physicallyImpossible error, got \(validationError)")
            }
        }
    }

    // MARK: - Target Date Validation Tests

    /// Test: Valid target date (realistic timeframe)
    ///
    /// 테스트: 유효한 목표 날짜 (현실적인 기간)
    func testValidate_RealisticTargetDate_Success() throws {
        // Given: Goal requiring 10 weeks (70kg → 65kg at -0.5kg/week)
        let goal = Goal(
            id: UUID(),
            userId: sampleUserId,
            goalType: .lose,
            targetWeight: Decimal(65.0),
            targetBodyFatPct: nil,
            targetMuscleMass: nil,
            weeklyWeightRate: Decimal(-0.5),
            weeklyFatPctRate: nil,
            weeklyMuscleRate: nil,
            startWeight: Decimal(70.0),
            startBodyFatPct: nil,
            startMuscleMass: nil,
            startBMR: nil,
            startTDEE: nil,
            dailyCalorieTarget: nil,
            isActive: true,
            createdAt: Date(),
            updatedAt: Date()
        )

        // When/Then: Should not throw (10 weeks is within 1-104 week range)
        XCTAssertNoThrow(try GoalValidationService.validate(goal: goal))
    }

    /// Test: Invalid target date (direction mismatch)
    ///
    /// 테스트: 유효하지 않은 목표 날짜 (방향 불일치)
    func testValidate_DirectionMismatch_ThrowsError() {
        // Given: Weight decreasing but positive rate (direction mismatch)
        let goal = Goal(
            id: UUID(),
            userId: sampleUserId,
            goalType: .lose,
            targetWeight: Decimal(65.0),
            targetBodyFatPct: nil,
            targetMuscleMass: nil,
            weeklyWeightRate: Decimal(0.5), // Positive rate but target < start
            weeklyFatPctRate: nil,
            weeklyMuscleRate: nil,
            startWeight: Decimal(70.0),
            startBodyFatPct: nil,
            startMuscleMass: nil,
            startBMR: nil,
            startTDEE: nil,
            dailyCalorieTarget: nil,
            isActive: true,
            createdAt: Date(),
            updatedAt: Date()
        )

        // When/Then: Should throw invalidTargetDate error
        XCTAssertThrowsError(try GoalValidationService.validate(goal: goal)) { error in
            guard let validationError = error as? GoalValidationError else {
                XCTFail("Expected GoalValidationError")
                return
            }

            if case .invalidTargetDate = validationError {
                // Success
            } else {
                XCTFail("Expected .invalidTargetDate error, got \(validationError)")
            }
        }
    }

    /// Test: Invalid target date (zero weekly rate)
    ///
    /// 테스트: 유효하지 않은 목표 날짜 (주간 변화율 0)
    func testValidate_ZeroWeeklyRate_ThrowsError() {
        // Given: Goal with zero weekly rate
        let goal = Goal(
            id: UUID(),
            userId: sampleUserId,
            goalType: .lose,
            targetWeight: Decimal(65.0),
            targetBodyFatPct: nil,
            targetMuscleMass: nil,
            weeklyWeightRate: Decimal(0.0),
            weeklyFatPctRate: nil,
            weeklyMuscleRate: nil,
            startWeight: Decimal(70.0),
            startBodyFatPct: nil,
            startMuscleMass: nil,
            startBMR: nil,
            startTDEE: nil,
            dailyCalorieTarget: nil,
            isActive: true,
            createdAt: Date(),
            updatedAt: Date()
        )

        // When/Then: Should throw invalidTargetDate error
        XCTAssertThrowsError(try GoalValidationService.validate(goal: goal)) { error in
            guard let validationError = error as? GoalValidationError else {
                XCTFail("Expected GoalValidationError")
                return
            }

            if case .invalidTargetDate = validationError {
                // Success
            } else {
                XCTFail("Expected .invalidTargetDate error, got \(validationError)")
            }
        }
    }

    /// Test: Target date too long (exceeds 104 weeks)
    ///
    /// 테스트: 목표 날짜가 너무 김 (104주 초과)
    func testValidate_TargetDateTooLong_ThrowsError() {
        // Given: Goal requiring 200 weeks (70kg → 60kg at -0.05kg/week)
        let goal = Goal(
            id: UUID(),
            userId: sampleUserId,
            goalType: .lose,
            targetWeight: Decimal(60.0),
            targetBodyFatPct: nil,
            targetMuscleMass: nil,
            weeklyWeightRate: Decimal(-0.05),
            weeklyFatPctRate: nil,
            weeklyMuscleRate: nil,
            startWeight: Decimal(70.0),
            startBodyFatPct: nil,
            startMuscleMass: nil,
            startBMR: nil,
            startTDEE: nil,
            dailyCalorieTarget: nil,
            isActive: true,
            createdAt: Date(),
            updatedAt: Date()
        )

        // When/Then: Should throw invalidTargetDate error
        XCTAssertThrowsError(try GoalValidationService.validate(goal: goal)) { error in
            guard let validationError = error as? GoalValidationError else {
                XCTFail("Expected GoalValidationError")
                return
            }

            if case .invalidTargetDate = validationError {
                // Success
            } else {
                XCTFail("Expected .invalidTargetDate error, got \(validationError)")
            }
        }
    }
}
