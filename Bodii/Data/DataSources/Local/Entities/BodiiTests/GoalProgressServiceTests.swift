//
//  GoalProgressServiceTests.swift
//  BodiiTests
//
//  Created by Auto-Claude on 2026-01-18.
//

import XCTest
@testable import Bodii

/// Unit tests for GoalProgressService progress calculation and milestone detection
///
/// GoalProgressService 진행률 계산 및 마일스톤 감지에 대한 단위 테스트
final class GoalProgressServiceTests: XCTestCase {

    // MARK: - Test Data

    /// Sample user ID for testing
    ///
    /// 테스트용 샘플 사용자 ID
    private let sampleUserId = UUID()

    // MARK: - Progress Calculation Tests (Weight Loss)

    /// Test: Weight loss progress at 50%
    ///
    /// 테스트: 체중 감량 진행률 50%
    func testCalculateProgress_WeightLoss50Percent_ReturnsCorrectProgress() {
        // Given: Weight loss 70kg → 65kg (현재 67.5kg)
        // Progress: (67.5 - 70) / (65 - 70) × 100 = -2.5 / -5 × 100 = 50%
        let result = GoalProgressService.calculateProgress(
            current: Decimal(67.5),
            start: Decimal(70.0),
            target: Decimal(65.0)
        )

        // Then: Should return 50% progress
        XCTAssertEqual(result.percentage, Decimal(50.0), "Progress should be 50%")
        XCTAssertEqual(result.remaining, Decimal(2.5), "Remaining should be 2.5kg")
        XCTAssertEqual(result.direction, .loss, "Direction should be loss")
    }

    /// Test: Weight loss progress at 0% (just started)
    ///
    /// 테스트: 체중 감량 진행률 0% (방금 시작)
    func testCalculateProgress_WeightLossJustStarted_Returns0Percent() {
        // Given: Weight loss 70kg → 65kg (현재 70kg)
        // Progress: (70 - 70) / (65 - 70) × 100 = 0 / -5 × 100 = 0%
        let result = GoalProgressService.calculateProgress(
            current: Decimal(70.0),
            start: Decimal(70.0),
            target: Decimal(65.0)
        )

        // Then: Should return 0% progress
        XCTAssertEqual(result.percentage, Decimal(0.0), "Progress should be 0%")
        XCTAssertEqual(result.remaining, Decimal(5.0), "Remaining should be 5kg")
        XCTAssertEqual(result.direction, .loss, "Direction should be loss")
    }

    /// Test: Weight loss progress at 100% (goal achieved)
    ///
    /// 테스트: 체중 감량 진행률 100% (목표 달성)
    func testCalculateProgress_WeightLossGoalAchieved_Returns100Percent() {
        // Given: Weight loss 70kg → 65kg (현재 65kg)
        // Progress: (65 - 70) / (65 - 70) × 100 = -5 / -5 × 100 = 100%
        let result = GoalProgressService.calculateProgress(
            current: Decimal(65.0),
            start: Decimal(70.0),
            target: Decimal(65.0)
        )

        // Then: Should return 100% progress
        XCTAssertEqual(result.percentage, Decimal(100.0), "Progress should be 100%")
        XCTAssertEqual(result.remaining, Decimal(0.0), "Remaining should be 0kg")
        XCTAssertEqual(result.direction, .loss, "Direction should be loss")
    }

    /// Test: Weight loss progress at 120% (over-achievement)
    ///
    /// 테스트: 체중 감량 진행률 120% (초과 달성)
    func testCalculateProgress_WeightLossOverAchievement_Returns120Percent() {
        // Given: Weight loss 70kg → 65kg (현재 64kg)
        // Progress: (64 - 70) / (65 - 70) × 100 = -6 / -5 × 100 = 120%
        let result = GoalProgressService.calculateProgress(
            current: Decimal(64.0),
            start: Decimal(70.0),
            target: Decimal(65.0)
        )

        // Then: Should return 120% progress
        XCTAssertEqual(result.percentage, Decimal(120.0), "Progress should be 120%")
        XCTAssertEqual(result.remaining, Decimal(1.0), "Remaining should be 1kg (absolute)")
        XCTAssertEqual(result.direction, .loss, "Direction should be loss")
    }

    // MARK: - Progress Calculation Tests (Weight Gain)

    /// Test: Weight gain progress at 60%
    ///
    /// 테스트: 체중 증량 진행률 60%
    func testCalculateProgress_WeightGain60Percent_ReturnsCorrectProgress() {
        // Given: Weight gain 30kg → 35kg (현재 33kg)
        // Progress: (33 - 30) / (35 - 30) × 100 = 3 / 5 × 100 = 60%
        let result = GoalProgressService.calculateProgress(
            current: Decimal(33.0),
            start: Decimal(30.0),
            target: Decimal(35.0)
        )

        // Then: Should return 60% progress
        XCTAssertEqual(result.percentage, Decimal(60.0), "Progress should be 60%")
        XCTAssertEqual(result.remaining, Decimal(2.0), "Remaining should be 2kg")
        XCTAssertEqual(result.direction, .gain, "Direction should be gain")
    }

    /// Test: Weight gain progress at 0% (just started)
    ///
    /// 테스트: 체중 증량 진행률 0% (방금 시작)
    func testCalculateProgress_WeightGainJustStarted_Returns0Percent() {
        // Given: Weight gain 30kg → 35kg (현재 30kg)
        // Progress: (30 - 30) / (35 - 30) × 100 = 0 / 5 × 100 = 0%
        let result = GoalProgressService.calculateProgress(
            current: Decimal(30.0),
            start: Decimal(30.0),
            target: Decimal(35.0)
        )

        // Then: Should return 0% progress
        XCTAssertEqual(result.percentage, Decimal(0.0), "Progress should be 0%")
        XCTAssertEqual(result.remaining, Decimal(5.0), "Remaining should be 5kg")
        XCTAssertEqual(result.direction, .gain, "Direction should be gain")
    }

    /// Test: Weight gain progress at 100% (goal achieved)
    ///
    /// 테스트: 체중 증량 진행률 100% (목표 달성)
    func testCalculateProgress_WeightGainGoalAchieved_Returns100Percent() {
        // Given: Weight gain 30kg → 35kg (현재 35kg)
        // Progress: (35 - 30) / (35 - 30) × 100 = 5 / 5 × 100 = 100%
        let result = GoalProgressService.calculateProgress(
            current: Decimal(35.0),
            start: Decimal(30.0),
            target: Decimal(35.0)
        )

        // Then: Should return 100% progress
        XCTAssertEqual(result.percentage, Decimal(100.0), "Progress should be 100%")
        XCTAssertEqual(result.remaining, Decimal(0.0), "Remaining should be 0kg")
        XCTAssertEqual(result.direction, .gain, "Direction should be gain")
    }

    // MARK: - Edge Case Tests

    /// Test: Progress when start equals target (already at goal)
    ///
    /// 테스트: 시작값과 목표값이 같은 경우 (이미 목표 도달)
    func testCalculateProgress_StartEqualsTarget_Returns100Percent() {
        // Given: Start 70kg, Target 70kg, Current 70kg
        let result = GoalProgressService.calculateProgress(
            current: Decimal(70.0),
            start: Decimal(70.0),
            target: Decimal(70.0)
        )

        // Then: Should return 100% (already at goal)
        XCTAssertEqual(result.percentage, Decimal(100.0), "Progress should be 100%")
        XCTAssertEqual(result.remaining, Decimal(0.0), "Remaining should be 0kg")
    }

    /// Test: Progress when start equals target but current differs
    ///
    /// 테스트: 시작값과 목표값이 같지만 현재값이 다른 경우
    func testCalculateProgress_StartEqualsTargetButCurrentDiffers_Returns0Percent() {
        // Given: Start 70kg, Target 70kg, Current 75kg
        let result = GoalProgressService.calculateProgress(
            current: Decimal(75.0),
            start: Decimal(70.0),
            target: Decimal(70.0)
        )

        // Then: Should return 0% (not at goal)
        XCTAssertEqual(result.percentage, Decimal(0.0), "Progress should be 0%")
        XCTAssertEqual(result.remaining, Decimal(5.0), "Remaining should be 5kg")
    }

    /// Test: Progress clamped at 150% (maximum allowed over-achievement)
    ///
    /// 테스트: 진행률이 150%로 제한됨 (최대 허용 초과 달성)
    func testCalculateProgress_OverAchievement_ClampedAt150Percent() {
        // Given: Weight loss 70kg → 65kg (현재 60kg)
        // Progress: (60 - 70) / (65 - 70) × 100 = -10 / -5 × 100 = 200%
        // Should be clamped to 150%
        let result = GoalProgressService.calculateProgress(
            current: Decimal(60.0),
            start: Decimal(70.0),
            target: Decimal(65.0)
        )

        // Then: Should be clamped at 150%
        XCTAssertEqual(result.percentage, Decimal(150.0), "Progress should be clamped at 150%")
    }

    /// Test: Progress clamped at 0% (moving in wrong direction)
    ///
    /// 테스트: 진행률이 0%로 제한됨 (반대 방향 이동)
    func testCalculateProgress_MovingWrongDirection_ClampedAt0Percent() {
        // Given: Weight loss 70kg → 65kg (현재 75kg)
        // Progress: (75 - 70) / (65 - 70) × 100 = 5 / -5 × 100 = -100%
        // Should be clamped to 0%
        let result = GoalProgressService.calculateProgress(
            current: Decimal(75.0),
            start: Decimal(70.0),
            target: Decimal(65.0)
        )

        // Then: Should be clamped at 0%
        XCTAssertEqual(result.percentage, Decimal(0.0), "Progress should be clamped at 0%")
    }

    // MARK: - Goal Progress Calculation Tests

    /// Test: Calculate goal progress with multiple targets
    ///
    /// 테스트: 복수 목표를 가진 목표 진행률 계산
    func testCalculateGoalProgress_MultipleTargets_ReturnsCorrectOverallProgress() {
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
            startMuscleMass: Decimal(28.0),
            startBMR: nil,
            startTDEE: nil,
            dailyCalorieTarget: nil,
            isActive: true,
            createdAt: Date(),
            updatedAt: Date()
        )

        // Current values
        let currentWeight = Decimal(67.5) // 50% progress: (67.5-70)/(65-70) = 50%
        let currentBodyFatPct = Decimal(20.0) // 50% progress: (20-22)/(18-22) = 50%
        let currentMuscleMass = Decimal(29.0) // 50% progress: (29-28)/(30-28) = 50%

        // When: Calculating goal progress
        let result = GoalProgressService.calculateGoalProgress(
            goal: goal,
            currentWeight: currentWeight,
            currentBodyFatPct: currentBodyFatPct,
            currentMuscleMass: currentMuscleMass
        )

        // Then: All should be at 50%, overall average is 50%
        XCTAssertNotNil(result.weightProgress)
        XCTAssertNotNil(result.bodyFatProgress)
        XCTAssertNotNil(result.muscleProgress)

        XCTAssertEqual(result.weightProgress?.percentage, Decimal(50.0), "Weight progress should be 50%")
        XCTAssertEqual(result.bodyFatProgress?.percentage, Decimal(50.0), "Body fat progress should be 50%")
        XCTAssertEqual(result.muscleProgress?.percentage, Decimal(50.0), "Muscle progress should be 50%")
        XCTAssertEqual(result.overallProgress, Decimal(50.0), "Overall progress should be 50%")
    }

    /// Test: Calculate goal progress with single target
    ///
    /// 테스트: 단일 목표를 가진 목표 진행률 계산
    func testCalculateGoalProgress_SingleTarget_ReturnsCorrectProgress() {
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

        // Current value
        let currentWeight = Decimal(67.5) // 50% progress

        // When: Calculating goal progress
        let result = GoalProgressService.calculateGoalProgress(
            goal: goal,
            currentWeight: currentWeight,
            currentBodyFatPct: nil,
            currentMuscleMass: nil
        )

        // Then: Only weight progress, overall equals weight progress
        XCTAssertNotNil(result.weightProgress)
        XCTAssertNil(result.bodyFatProgress)
        XCTAssertNil(result.muscleProgress)

        XCTAssertEqual(result.weightProgress?.percentage, Decimal(50.0), "Weight progress should be 50%")
        XCTAssertEqual(result.overallProgress, Decimal(50.0), "Overall progress should equal weight progress")
    }

    // MARK: - Milestone Detection Tests

    /// Test: Detect milestones at 0% progress
    ///
    /// 테스트: 0% 진행률의 마일스톤 감지
    func testDetectMilestones_0Percent_ReturnsNoMilestones() {
        // Given: 0% progress
        let progress = Decimal(0.0)

        // When: Detecting milestones
        let milestones = GoalProgressService.detectMilestones(progressPercentage: progress)

        // Then: Should return empty array
        XCTAssertTrue(milestones.isEmpty, "Should have no milestones at 0%")
    }

    /// Test: Detect milestones at 24% progress (no milestone)
    ///
    /// 테스트: 24% 진행률의 마일스톤 감지 (마일스톤 없음)
    func testDetectMilestones_24Percent_ReturnsNoMilestones() {
        // Given: 24% progress (just below first milestone)
        let progress = Decimal(24.0)

        // When: Detecting milestones
        let milestones = GoalProgressService.detectMilestones(progressPercentage: progress)

        // Then: Should return empty array
        XCTAssertTrue(milestones.isEmpty, "Should have no milestones at 24%")
    }

    /// Test: Detect milestones at 25% progress (first milestone)
    ///
    /// 테스트: 25% 진행률의 마일스톤 감지 (첫 번째 마일스톤)
    func testDetectMilestones_25Percent_ReturnsQuarterMilestone() {
        // Given: 25% progress
        let progress = Decimal(25.0)

        // When: Detecting milestones
        let milestones = GoalProgressService.detectMilestones(progressPercentage: progress)

        // Then: Should return only quarter milestone
        XCTAssertEqual(milestones.count, 1, "Should have 1 milestone")
        XCTAssertTrue(milestones.contains(.quarter), "Should contain quarter milestone")
    }

    /// Test: Detect milestones at 50% progress (two milestones)
    ///
    /// 테스트: 50% 진행률의 마일스톤 감지 (두 개 마일스톤)
    func testDetectMilestones_50Percent_ReturnsQuarterAndHalfMilestones() {
        // Given: 50% progress
        let progress = Decimal(50.0)

        // When: Detecting milestones
        let milestones = GoalProgressService.detectMilestones(progressPercentage: progress)

        // Then: Should return quarter and half milestones
        XCTAssertEqual(milestones.count, 2, "Should have 2 milestones")
        XCTAssertTrue(milestones.contains(.quarter), "Should contain quarter milestone")
        XCTAssertTrue(milestones.contains(.half), "Should contain half milestone")
    }

    /// Test: Detect milestones at 75% progress (three milestones)
    ///
    /// 테스트: 75% 진행률의 마일스톤 감지 (세 개 마일스톤)
    func testDetectMilestones_75Percent_ReturnsThreeMilestones() {
        // Given: 75% progress
        let progress = Decimal(75.0)

        // When: Detecting milestones
        let milestones = GoalProgressService.detectMilestones(progressPercentage: progress)

        // Then: Should return three milestones
        XCTAssertEqual(milestones.count, 3, "Should have 3 milestones")
        XCTAssertTrue(milestones.contains(.quarter), "Should contain quarter milestone")
        XCTAssertTrue(milestones.contains(.half), "Should contain half milestone")
        XCTAssertTrue(milestones.contains(.threeQuarters), "Should contain three quarters milestone")
    }

    /// Test: Detect milestones at 100% progress (all milestones)
    ///
    /// 테스트: 100% 진행률의 마일스톤 감지 (모든 마일스톤)
    func testDetectMilestones_100Percent_ReturnsAllMilestones() {
        // Given: 100% progress
        let progress = Decimal(100.0)

        // When: Detecting milestones
        let milestones = GoalProgressService.detectMilestones(progressPercentage: progress)

        // Then: Should return all four milestones
        XCTAssertEqual(milestones.count, 4, "Should have 4 milestones")
        XCTAssertTrue(milestones.contains(.quarter), "Should contain quarter milestone")
        XCTAssertTrue(milestones.contains(.half), "Should contain half milestone")
        XCTAssertTrue(milestones.contains(.threeQuarters), "Should contain three quarters milestone")
        XCTAssertTrue(milestones.contains(.complete), "Should contain complete milestone")
    }

    /// Test: Detect milestones at 120% progress (all milestones including over-achievement)
    ///
    /// 테스트: 120% 진행률의 마일스톤 감지 (초과 달성 포함 모든 마일스톤)
    func testDetectMilestones_120Percent_ReturnsAllMilestones() {
        // Given: 120% progress (over-achievement)
        let progress = Decimal(120.0)

        // When: Detecting milestones
        let milestones = GoalProgressService.detectMilestones(progressPercentage: progress)

        // Then: Should still return all four milestones
        XCTAssertEqual(milestones.count, 4, "Should have 4 milestones")
        XCTAssertTrue(milestones.contains(.complete), "Should contain complete milestone")
    }

    // MARK: - New Milestone Detection Tests

    /// Test: Detect new milestones (40% → 60%)
    ///
    /// 테스트: 새로운 마일스톤 감지 (40% → 60%)
    func testDetectNewMilestones_40To60Percent_ReturnsHalfMilestone() {
        // Given: Progress from 40% to 60%
        let previousProgress = Decimal(40.0)
        let currentProgress = Decimal(60.0)

        // When: Detecting new milestones
        let newMilestones = GoalProgressService.detectNewMilestones(
            currentProgress: currentProgress,
            previousProgress: previousProgress
        )

        // Then: Should return only half milestone (50% newly achieved)
        XCTAssertEqual(newMilestones.count, 1, "Should have 1 new milestone")
        XCTAssertTrue(newMilestones.contains(.half), "Should contain half milestone")
    }

    /// Test: Detect new milestones (20% → 80%)
    ///
    /// 테스트: 새로운 마일스톤 감지 (20% → 80%)
    func testDetectNewMilestones_20To80Percent_ReturnsThreeNewMilestones() {
        // Given: Progress from 20% to 80%
        let previousProgress = Decimal(20.0)
        let currentProgress = Decimal(80.0)

        // When: Detecting new milestones
        let newMilestones = GoalProgressService.detectNewMilestones(
            currentProgress: currentProgress,
            previousProgress: previousProgress
        )

        // Then: Should return quarter, half, and three quarters milestones
        XCTAssertEqual(newMilestones.count, 3, "Should have 3 new milestones")
        XCTAssertTrue(newMilestones.contains(.quarter), "Should contain quarter milestone")
        XCTAssertTrue(newMilestones.contains(.half), "Should contain half milestone")
        XCTAssertTrue(newMilestones.contains(.threeQuarters), "Should contain three quarters milestone")
    }

    /// Test: Detect new milestones (no progress change)
    ///
    /// 테스트: 새로운 마일스톤 감지 (진행률 변화 없음)
    func testDetectNewMilestones_NoProgressChange_ReturnsNoNewMilestones() {
        // Given: Progress stays at 60%
        let previousProgress = Decimal(60.0)
        let currentProgress = Decimal(60.0)

        // When: Detecting new milestones
        let newMilestones = GoalProgressService.detectNewMilestones(
            currentProgress: currentProgress,
            previousProgress: previousProgress
        )

        // Then: Should return empty array
        XCTAssertTrue(newMilestones.isEmpty, "Should have no new milestones")
    }

    /// Test: Detect new milestones (progress decrease - regression)
    ///
    /// 테스트: 새로운 마일스톤 감지 (진행률 감소 - 역행)
    func testDetectNewMilestones_ProgressDecrease_ReturnsNoNewMilestones() {
        // Given: Progress decreased from 60% to 40%
        let previousProgress = Decimal(60.0)
        let currentProgress = Decimal(40.0)

        // When: Detecting new milestones
        let newMilestones = GoalProgressService.detectNewMilestones(
            currentProgress: currentProgress,
            previousProgress: previousProgress
        )

        // Then: Should return empty array (no NEW milestones)
        XCTAssertTrue(newMilestones.isEmpty, "Should have no new milestones when progress decreases")
    }

    /// Test: Milestone ordering (should be in correct order)
    ///
    /// 테스트: 마일스톤 순서 (올바른 순서여야 함)
    func testDetectNewMilestones_MultipleNewMilestones_ReturnsInCorrectOrder() {
        // Given: Progress from 0% to 100%
        let previousProgress = Decimal(0.0)
        let currentProgress = Decimal(100.0)

        // When: Detecting new milestones
        let newMilestones = GoalProgressService.detectNewMilestones(
            currentProgress: currentProgress,
            previousProgress: previousProgress
        )

        // Then: Should return milestones in correct order
        XCTAssertEqual(newMilestones.count, 4, "Should have 4 new milestones")
        XCTAssertEqual(newMilestones[0], .quarter, "First should be quarter")
        XCTAssertEqual(newMilestones[1], .half, "Second should be half")
        XCTAssertEqual(newMilestones[2], .threeQuarters, "Third should be three quarters")
        XCTAssertEqual(newMilestones[3], .complete, "Fourth should be complete")
    }
}
