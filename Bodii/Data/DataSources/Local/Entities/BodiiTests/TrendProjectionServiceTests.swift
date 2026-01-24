//
//  TrendProjectionServiceTests.swift
//  BodiiTests
//
//  Created by Auto-Claude on 2026-01-18.
//

import XCTest
@testable import Bodii

/// Unit tests for TrendProjectionService trend analysis and completion date projection
///
/// TrendProjectionService 트렌드 분석 및 완료일 예측에 대한 단위 테스트
final class TrendProjectionServiceTests: XCTestCase {

    // MARK: - Test Data

    /// Sample user ID for testing
    ///
    /// 테스트용 샘플 사용자 ID
    private let sampleUserId = UUID()

    // MARK: - Helper Methods

    /// Create sample body composition records with linear trend
    ///
    /// 선형 추세를 가진 샘플 체성분 기록 생성
    private func createLinearTrendRecords(
        startDate: Date,
        startWeight: Decimal,
        dailyWeightChange: Decimal,
        count: Int
    ) -> [BodyCompositionEntry] {
        var records: [BodyCompositionEntry] = []

        for i in 0..<count {
            let date = Calendar.current.date(byAdding: .day, value: i, to: startDate)!
            let weight = startWeight + (dailyWeightChange * Decimal(i))

            let record = BodyCompositionEntry(
                date: date,
                weight: weight,
                bodyFatPercent: Decimal(20.0),
                muscleMass: Decimal(30.0)
            )
            records.append(record)
        }

        return records
    }

    // MARK: - Trend Calculation Tests

    /// Test: Calculate trend with sufficient data (10 points)
    ///
    /// 테스트: 충분한 데이터로 트렌드 계산 (10개 포인트)
    func testCalculateTrend_SufficientData_ReturnsHighConfidenceTrend() {
        // Given: 10 data points with -0.1 kg/day trend
        let startDate = Calendar.current.date(byAdding: .day, value: -9, to: Date())!
        let records = createLinearTrendRecords(
            startDate: startDate,
            startWeight: Decimal(70.0),
            dailyWeightChange: Decimal(-0.1),
            count: 10
        )

        // When: Calculating trend
        let trend = TrendProjectionService.calculateTrend(records: records, for: .weight)

        // Then: Should return high confidence trend
        XCTAssertNotNil(trend, "Should return trend with 10 data points")
        XCTAssertEqual(trend?.confidence, .high, "Should have high confidence with 10+ points")
        XCTAssertEqual(trend?.dataPointsCount, 10, "Should have 10 data points")

        // Daily rate should be approximately -0.1 kg/day
        let dailyRate = trend?.dailyRate ?? 0
        XCTAssertTrue(abs(dailyRate - Decimal(-0.1)) < Decimal(0.01), "Daily rate should be approximately -0.1 kg/day")

        // Weekly rate should be approximately -0.7 kg/week
        let weeklyRate = trend?.weeklyRate ?? 0
        XCTAssertTrue(abs(weeklyRate - Decimal(-0.7)) < Decimal(0.1), "Weekly rate should be approximately -0.7 kg/week")
    }

    /// Test: Calculate trend with medium data (7 points)
    ///
    /// 테스트: 중간 데이터로 트렌드 계산 (7개 포인트)
    func testCalculateTrend_MediumData_ReturnsMediumConfidenceTrend() {
        // Given: 7 data points with -0.1 kg/day trend
        let startDate = Calendar.current.date(byAdding: .day, value: -6, to: Date())!
        let records = createLinearTrendRecords(
            startDate: startDate,
            startWeight: Decimal(70.0),
            dailyWeightChange: Decimal(-0.1),
            count: 7
        )

        // When: Calculating trend
        let trend = TrendProjectionService.calculateTrend(records: records, for: .weight)

        // Then: Should return medium confidence trend
        XCTAssertNotNil(trend, "Should return trend with 7 data points")
        XCTAssertEqual(trend?.confidence, .medium, "Should have medium confidence with 5-9 points")
        XCTAssertEqual(trend?.dataPointsCount, 7, "Should have 7 data points")
    }

    /// Test: Calculate trend with minimum data (2 points)
    ///
    /// 테스트: 최소 데이터로 트렌드 계산 (2개 포인트)
    func testCalculateTrend_MinimumData_ReturnsLowConfidenceTrend() {
        // Given: 2 data points (minimum required)
        let startDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let records = createLinearTrendRecords(
            startDate: startDate,
            startWeight: Decimal(70.0),
            dailyWeightChange: Decimal(-0.1),
            count: 2
        )

        // When: Calculating trend
        let trend = TrendProjectionService.calculateTrend(records: records, for: .weight)

        // Then: Should return low confidence trend
        XCTAssertNotNil(trend, "Should return trend with 2 data points")
        XCTAssertEqual(trend?.confidence, .low, "Should have low confidence with 2-4 points")
        XCTAssertEqual(trend?.dataPointsCount, 2, "Should have 2 data points")
    }

    /// Test: Calculate trend with insufficient data (1 point)
    ///
    /// 테스트: 불충분한 데이터로 트렌드 계산 (1개 포인트)
    func testCalculateTrend_InsufficientData_ReturnsNil() {
        // Given: 1 data point (insufficient)
        let records = createLinearTrendRecords(
            startDate: Date(),
            startWeight: Decimal(70.0),
            dailyWeightChange: Decimal(-0.1),
            count: 1
        )

        // When: Calculating trend
        let trend = TrendProjectionService.calculateTrend(records: records, for: .weight)

        // Then: Should return nil
        XCTAssertNil(trend, "Should return nil with insufficient data")
    }

    /// Test: Calculate trend with no data
    ///
    /// 테스트: 데이터가 없을 때 트렌드 계산
    func testCalculateTrend_NoData_ReturnsNil() {
        // Given: No data points
        let records: [BodyCompositionEntry] = []

        // When: Calculating trend
        let trend = TrendProjectionService.calculateTrend(records: records, for: .weight)

        // Then: Should return nil
        XCTAssertNil(trend, "Should return nil with no data")
    }

    /// Test: Calculate trend for body fat percentage
    ///
    /// 테스트: 체지방률 트렌드 계산
    func testCalculateTrend_BodyFatMetric_ReturnsCorrectTrend() {
        // Given: 10 data points with varying body fat percentage
        let startDate = Calendar.current.date(byAdding: .day, value: -9, to: Date())!
        var records: [BodyCompositionEntry] = []

        for i in 0..<10 {
            let date = Calendar.current.date(byAdding: .day, value: i, to: startDate)!
            let bodyFatPercent = Decimal(25.0) + (Decimal(-0.1) * Decimal(i)) // -0.1% per day

            let record = BodyCompositionEntry(
                date: date,
                weight: Decimal(70.0),
                bodyFatPercent: bodyFatPercent,
                muscleMass: Decimal(30.0)
            )
            records.append(record)
        }

        // When: Calculating trend for body fat
        let trend = TrendProjectionService.calculateTrend(records: records, for: .bodyFat)

        // Then: Should calculate trend for body fat percentage
        XCTAssertNotNil(trend, "Should calculate trend for body fat")
        XCTAssertEqual(trend?.dataPointsCount, 10, "Should use all 10 data points")

        // Daily rate should be approximately -0.1% per day
        let dailyRate = trend?.dailyRate ?? 0
        XCTAssertTrue(abs(dailyRate - Decimal(-0.1)) < Decimal(0.02), "Daily rate should be approximately -0.1% per day")
    }

    /// Test: Calculate trend for muscle mass
    ///
    /// 테스트: 근육량 트렌드 계산
    func testCalculateTrend_MuscleMetric_ReturnsCorrectTrend() {
        // Given: 10 data points with increasing muscle mass
        let startDate = Calendar.current.date(byAdding: .day, value: -9, to: Date())!
        var records: [BodyCompositionEntry] = []

        for i in 0..<10 {
            let date = Calendar.current.date(byAdding: .day, value: i, to: startDate)!
            let muscleMass = Decimal(30.0) + (Decimal(0.05) * Decimal(i)) // +0.05 kg per day

            let record = BodyCompositionEntry(
                date: date,
                weight: Decimal(70.0),
                bodyFatPercent: Decimal(20.0),
                muscleMass: muscleMass
            )
            records.append(record)
        }

        // When: Calculating trend for muscle mass
        let trend = TrendProjectionService.calculateTrend(records: records, for: .muscle)

        // Then: Should calculate trend for muscle mass
        XCTAssertNotNil(trend, "Should calculate trend for muscle")
        XCTAssertEqual(trend?.dataPointsCount, 10, "Should use all 10 data points")

        // Daily rate should be approximately +0.05 kg per day
        let dailyRate = trend?.dailyRate ?? 0
        XCTAssertTrue(abs(dailyRate - Decimal(0.05)) < Decimal(0.01), "Daily rate should be approximately +0.05 kg per day")
    }

    // MARK: - Completion Date Projection Tests

    /// Test: Project completion date with positive trend (moving toward goal)
    ///
    /// 테스트: 긍정적 추세로 완료일 예측 (목표로 이동 중)
    func testProjectCompletionDate_PositiveTrend_ReturnsCompletionDate() {
        // Given: Goal 70kg → 65kg, Current 67kg
        // Trend: -0.1 kg/day (-0.7 kg/week)
        // Days to goal: (65 - 67) / -0.1 = 20 days
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

        let trend = TrendResult(
            dailyRate: Decimal(-0.1),
            weeklyRate: Decimal(-0.7),
            confidence: .high,
            dataPointsCount: 10
        )

        let currentValue = Decimal(67.0)

        // When: Projecting completion date
        let projection = TrendProjectionService.projectCompletionDate(
            goal: goal,
            currentValue: currentValue,
            trend: trend,
            metric: .weight
        )

        // Then: Should return completion date
        XCTAssertNotNil(projection, "Should return projection")
        XCTAssertNotNil(projection?.estimatedCompletionDate, "Should have completion date")
        XCTAssertEqual(projection?.daysToCompletion, 20, "Should be 20 days to completion")
        XCTAssertTrue(projection?.isOnTrack ?? false, "Should be on track (140% of plan)")
    }

    /// Test: Project completion date with trend in wrong direction
    ///
    /// 테스트: 반대 방향 추세로 완료일 예측
    func testProjectCompletionDate_WrongDirectionTrend_ReturnsNilDate() {
        // Given: Goal 70kg → 65kg (need to lose), but gaining weight
        // Trend: +0.1 kg/day (wrong direction)
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

        let trend = TrendResult(
            dailyRate: Decimal(0.1), // Gaining weight instead of losing
            weeklyRate: Decimal(0.7),
            confidence: .high,
            dataPointsCount: 10
        )

        let currentValue = Decimal(67.0)

        // When: Projecting completion date
        let projection = TrendProjectionService.projectCompletionDate(
            goal: goal,
            currentValue: currentValue,
            trend: trend,
            metric: .weight
        )

        // Then: Should return projection with nil completion date
        XCTAssertNotNil(projection, "Should return projection")
        XCTAssertNil(projection?.estimatedCompletionDate, "Should have nil completion date")
        XCTAssertNil(projection?.daysToCompletion, "Should have nil days to completion")
        XCTAssertFalse(projection?.isOnTrack ?? true, "Should not be on track")
    }

    /// Test: Project completion date with zero trend
    ///
    /// 테스트: 변화 없는 추세로 완료일 예측
    func testProjectCompletionDate_ZeroTrend_ReturnsNilDate() {
        // Given: Goal 70kg → 65kg, but no weight change
        // Trend: 0 kg/day (no progress)
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

        let trend = TrendResult(
            dailyRate: Decimal(0.0), // No change
            weeklyRate: Decimal(0.0),
            confidence: .medium,
            dataPointsCount: 7
        )

        let currentValue = Decimal(67.0)

        // When: Projecting completion date
        let projection = TrendProjectionService.projectCompletionDate(
            goal: goal,
            currentValue: currentValue,
            trend: trend,
            metric: .weight
        )

        // Then: Should return projection with nil completion date
        XCTAssertNotNil(projection, "Should return projection")
        XCTAssertNil(projection?.estimatedCompletionDate, "Should have nil completion date")
        XCTAssertFalse(projection?.isOnTrack ?? true, "Should not be on track")
    }

    /// Test: Project completion date when already at goal
    ///
    /// 테스트: 이미 목표 도달 시 완료일 예측
    func testProjectCompletionDate_AlreadyAtGoal_Returns0Days() {
        // Given: Goal 70kg → 65kg, Current 65kg (already at goal)
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

        let trend = TrendResult(
            dailyRate: Decimal(-0.1),
            weeklyRate: Decimal(-0.7),
            confidence: .high,
            dataPointsCount: 10
        )

        let currentValue = Decimal(65.0) // Already at goal

        // When: Projecting completion date
        let projection = TrendProjectionService.projectCompletionDate(
            goal: goal,
            currentValue: currentValue,
            trend: trend,
            metric: .weight
        )

        // Then: Should return 0 days to completion
        XCTAssertNotNil(projection, "Should return projection")
        XCTAssertEqual(projection?.daysToCompletion, 0, "Should be 0 days to completion")
    }

    // MARK: - Trend Comparison Tests

    /// Test: Compare trend to planned (on track)
    ///
    /// 테스트: 계획과 추세 비교 (계획대로 진행 중)
    func testCompareTrendToPlanned_OnTrack_ReturnsOnTrackStatus() {
        // Given: Actual -0.5 kg/week, Planned -0.5 kg/week (100% of plan)
        let actualRate = Decimal(-0.5)
        let plannedRate = Decimal(-0.5)

        // When: Comparing trend to planned
        let comparison = TrendProjectionService.compareTrendToPlanned(
            actualRate: actualRate,
            plannedRate: plannedRate
        )

        // Then: Should be on track
        XCTAssertEqual(comparison.actualWeeklyRate, Decimal(-0.5), "Actual rate should be -0.5")
        XCTAssertEqual(comparison.plannedWeeklyRate, Decimal(-0.5), "Planned rate should be -0.5")
        XCTAssertEqual(comparison.percentageOfPlan, Decimal(100.0), "Should be 100% of plan")
        XCTAssertEqual(comparison.status, .onTrack, "Should be on track")
    }

    /// Test: Compare trend to planned (ahead)
    ///
    /// 테스트: 계획과 추세 비교 (계획보다 빠름)
    func testCompareTrendToPlanned_Ahead_ReturnsAheadStatus() {
        // Given: Actual -0.7 kg/week, Planned -0.5 kg/week (140% of plan)
        let actualRate = Decimal(-0.7)
        let plannedRate = Decimal(-0.5)

        // When: Comparing trend to planned
        let comparison = TrendProjectionService.compareTrendToPlanned(
            actualRate: actualRate,
            plannedRate: plannedRate
        )

        // Then: Should be ahead
        XCTAssertEqual(comparison.percentageOfPlan, Decimal(140.0), "Should be 140% of plan")
        XCTAssertEqual(comparison.status, .ahead, "Should be ahead of plan")
    }

    /// Test: Compare trend to planned (behind)
    ///
    /// 테스트: 계획과 추세 비교 (계획보다 느림)
    func testCompareTrendToPlanned_Behind_ReturnsBehindStatus() {
        // Given: Actual -0.3 kg/week, Planned -0.5 kg/week (60% of plan)
        let actualRate = Decimal(-0.3)
        let plannedRate = Decimal(-0.5)

        // When: Comparing trend to planned
        let comparison = TrendProjectionService.compareTrendToPlanned(
            actualRate: actualRate,
            plannedRate: plannedRate
        )

        // Then: Should be behind
        XCTAssertEqual(comparison.percentageOfPlan, Decimal(60.0), "Should be 60% of plan")
        XCTAssertEqual(comparison.status, .behind, "Should be behind plan")
    }

    /// Test: Compare trend to planned (no progress)
    ///
    /// 테스트: 계획과 추세 비교 (진행 없음)
    func testCompareTrendToPlanned_NoProgress_ReturnsNoProgressStatus() {
        // Given: Actual 0.0 kg/week, Planned -0.5 kg/week (no progress)
        let actualRate = Decimal(0.0)
        let plannedRate = Decimal(-0.5)

        // When: Comparing trend to planned
        let comparison = TrendProjectionService.compareTrendToPlanned(
            actualRate: actualRate,
            plannedRate: plannedRate
        )

        // Then: Should be no progress
        XCTAssertEqual(comparison.status, .noProgress, "Should be no progress")
    }

    /// Test: Compare trend to planned (zero planned rate)
    ///
    /// 테스트: 계획과 추세 비교 (계획 변화율 0)
    func testCompareTrendToPlanned_ZeroPlannedRate_ReturnsNoProgressStatus() {
        // Given: Actual -0.5 kg/week, Planned 0.0 kg/week
        let actualRate = Decimal(-0.5)
        let plannedRate = Decimal(0.0)

        // When: Comparing trend to planned
        let comparison = TrendProjectionService.compareTrendToPlanned(
            actualRate: actualRate,
            plannedRate: plannedRate
        )

        // Then: Should be no progress (cannot divide by zero)
        XCTAssertEqual(comparison.status, .noProgress, "Should be no progress")
        XCTAssertEqual(comparison.percentageOfPlan, Decimal(0.0), "Percentage should be 0")
    }

    /// Test: Compare trend to planned (within tolerance)
    ///
    /// 테스트: 계획과 추세 비교 (허용 범위 내)
    func testCompareTrendToPlanned_WithinTolerance_ReturnsOnTrackStatus() {
        // Given: Actual -0.48 kg/week, Planned -0.5 kg/week (96% of plan, within ±10%)
        let actualRate = Decimal(-0.48)
        let plannedRate = Decimal(-0.5)

        // When: Comparing trend to planned
        let comparison = TrendProjectionService.compareTrendToPlanned(
            actualRate: actualRate,
            plannedRate: plannedRate
        )

        // Then: Should be on track (96% is within 90-110% range)
        XCTAssertEqual(comparison.percentageOfPlan, Decimal(96.0), "Should be 96% of plan")
        XCTAssertEqual(comparison.status, .onTrack, "Should be on track (within ±10% tolerance)")
    }

    /// Test: Compare trend to planned (weight gain scenario)
    ///
    /// 테스트: 계획과 추세 비교 (체중 증량 시나리오)
    func testCompareTrendToPlanned_WeightGain_ReturnsCorrectComparison() {
        // Given: Actual +0.6 kg/week, Planned +0.5 kg/week (120% of plan)
        let actualRate = Decimal(0.6)
        let plannedRate = Decimal(0.5)

        // When: Comparing trend to planned
        let comparison = TrendProjectionService.compareTrendToPlanned(
            actualRate: actualRate,
            plannedRate: plannedRate
        )

        // Then: Should be ahead (gaining faster than planned)
        XCTAssertEqual(comparison.percentageOfPlan, Decimal(120.0), "Should be 120% of plan")
        XCTAssertEqual(comparison.status, .ahead, "Should be ahead of plan")
    }

    // MARK: - Edge Case Tests

    /// Test: Calculate trend with unsorted records
    ///
    /// 테스트: 정렬되지 않은 기록으로 트렌드 계산
    func testCalculateTrend_UnsortedRecords_CalculatesCorrectTrend() {
        // Given: 5 data points in random order
        let baseDate = Date()
        let records = [
            BodyCompositionEntry(
                date: Calendar.current.date(byAdding: .day, value: -2, to: baseDate)!,
                weight: Decimal(69.8),
                bodyFatPercent: Decimal(20.0),
                muscleMass: Decimal(30.0)
            ),
            BodyCompositionEntry(
                date: Calendar.current.date(byAdding: .day, value: -4, to: baseDate)!,
                weight: Decimal(70.0),
                bodyFatPercent: Decimal(20.0),
                muscleMass: Decimal(30.0)
            ),
            BodyCompositionEntry(
                date: baseDate,
                weight: Decimal(69.6),
                bodyFatPercent: Decimal(20.0),
                muscleMass: Decimal(30.0)
            ),
            BodyCompositionEntry(
                date: Calendar.current.date(byAdding: .day, value: -3, to: baseDate)!,
                weight: Decimal(69.9),
                bodyFatPercent: Decimal(20.0),
                muscleMass: Decimal(30.0)
            ),
            BodyCompositionEntry(
                date: Calendar.current.date(byAdding: .day, value: -1, to: baseDate)!,
                weight: Decimal(69.7),
                bodyFatPercent: Decimal(20.0),
                muscleMass: Decimal(30.0)
            )
        ]

        // When: Calculating trend
        let trend = TrendProjectionService.calculateTrend(records: records, for: .weight)

        // Then: Should sort and calculate correct trend
        XCTAssertNotNil(trend, "Should calculate trend even with unsorted records")
        XCTAssertEqual(trend?.dataPointsCount, 5, "Should use all 5 data points")
        XCTAssertEqual(trend?.confidence, .medium, "Should have medium confidence")

        // Daily rate should be approximately -0.1 kg/day
        let dailyRate = trend?.dailyRate ?? 0
        XCTAssertTrue(abs(dailyRate - Decimal(-0.1)) < Decimal(0.05), "Daily rate should be approximately -0.1 kg/day")
    }
}
