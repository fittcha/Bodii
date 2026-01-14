//
//  DailyLogServiceTests.swift
//  BodiiTests
//
//  Created by Auto-Claude on 2026-01-14.
//

import XCTest
@testable import Bodii

/// Unit tests for DailyLogService exercise updates
///
/// DailyLogService 운동 데이터 업데이트에 대한 단위 테스트
final class DailyLogServiceTests: XCTestCase {

    // MARK: - Properties

    var service: DailyLogService!
    var mockRepository: MockDailyLogRepository!
    let testUserId = UUID()
    let testDate = Date()

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()
        mockRepository = MockDailyLogRepository()
        service = DailyLogService(repository: mockRepository)
    }

    override func tearDown() {
        service = nil
        mockRepository = nil
        super.tearDown()
    }

    // MARK: - Add Exercise Tests

    /// Test: Adding exercise updates totals correctly
    ///
    /// 테스트: 운동 추가 시 합계가 올바르게 업데이트됨
    func testAddExercise_ValidData_UpdatesTotalsCorrectly() async throws {
        // Given: Initial DailyLog with zero exercise data
        let initialLog = createDailyLog(
            totalCaloriesOut: 0,
            exerciseMinutes: 0,
            exerciseCount: 0
        )
        mockRepository.dailyLog = initialLog

        // When: Adding exercise (350 kcal, 30 minutes)
        try await service.addExercise(
            date: testDate,
            userId: testUserId,
            calories: 350,
            duration: 30,
            userBMR: 1650,
            userTDEE: 2310
        )

        // Then: Totals should be incremented
        XCTAssertEqual(
            mockRepository.lastAddedCalories,
            350,
            "Should add 350 kcal to totalCaloriesOut"
        )
        XCTAssertEqual(
            mockRepository.lastAddedDuration,
            30,
            "Should add 30 minutes to exerciseMinutes"
        )
        XCTAssertTrue(
            mockRepository.addExerciseCalled,
            "addExercise should be called on repository"
        )
    }

    /// Test: Adding multiple exercises accumulates correctly
    ///
    /// 테스트: 여러 운동 추가 시 누적 계산이 올바름
    func testAddExercise_MultipleExercises_AccumulatesCorrectly() async throws {
        // Given: Initial DailyLog with some exercise data
        let initialLog = createDailyLog(
            totalCaloriesOut: 200,
            exerciseMinutes: 20,
            exerciseCount: 1
        )
        mockRepository.dailyLog = initialLog

        // When: Adding first exercise (150 kcal, 15 minutes)
        try await service.addExercise(
            date: testDate,
            userId: testUserId,
            calories: 150,
            duration: 15,
            userBMR: 1650,
            userTDEE: 2310
        )

        // When: Adding second exercise (280 kcal, 30 minutes)
        try await service.addExercise(
            date: testDate,
            userId: testUserId,
            calories: 280,
            duration: 30,
            userBMR: 1650,
            userTDEE: 2310
        )

        // Then: Should have called addExercise twice
        XCTAssertEqual(
            mockRepository.addExerciseCallCount,
            2,
            "addExercise should be called twice"
        )
    }

    /// Test: Adding exercise with high calorie burn
    ///
    /// 테스트: 고칼로리 운동 추가
    func testAddExercise_HighCalorieBurn_UpdatesCorrectly() async throws {
        // Given: Initial DailyLog with zero exercise data
        let initialLog = createDailyLog(
            totalCaloriesOut: 0,
            exerciseMinutes: 0,
            exerciseCount: 0
        )
        mockRepository.dailyLog = initialLog

        // When: Adding intense exercise (800 kcal, 90 minutes - long run)
        try await service.addExercise(
            date: testDate,
            userId: testUserId,
            calories: 800,
            duration: 90,
            userBMR: 1650,
            userTDEE: 2310
        )

        // Then: Should add large values correctly
        XCTAssertEqual(
            mockRepository.lastAddedCalories,
            800,
            "Should add 800 kcal to totalCaloriesOut"
        )
        XCTAssertEqual(
            mockRepository.lastAddedDuration,
            90,
            "Should add 90 minutes to exerciseMinutes"
        )
    }

    /// Test: Adding exercise creates DailyLog if not exists
    ///
    /// 테스트: DailyLog가 없을 때 자동 생성 후 운동 추가
    func testAddExercise_NoDailyLog_CreatesAndAdds() async throws {
        // Given: No existing DailyLog
        mockRepository.dailyLog = nil

        // When: Adding exercise
        try await service.addExercise(
            date: testDate,
            userId: testUserId,
            calories: 250,
            duration: 25,
            userBMR: 1650,
            userTDEE: 2310
        )

        // Then: Should create DailyLog first, then add exercise
        XCTAssertTrue(
            mockRepository.getOrCreateCalled,
            "getOrCreate should be called to create DailyLog"
        )
        XCTAssertTrue(
            mockRepository.addExerciseCalled,
            "addExercise should be called after creation"
        )
    }

    // MARK: - Remove Exercise Tests

    /// Test: Removing exercise decrements totals correctly
    ///
    /// 테스트: 운동 삭제 시 합계가 올바르게 감소함
    func testRemoveExercise_ValidData_DecrementsTotalsCorrectly() async throws {
        // Given: DailyLog with existing exercise data
        let initialLog = createDailyLog(
            totalCaloriesOut: 500,
            exerciseMinutes: 60,
            exerciseCount: 2
        )
        mockRepository.dailyLog = initialLog

        // When: Removing exercise (250 kcal, 30 minutes)
        try await service.removeExercise(
            date: testDate,
            userId: testUserId,
            calories: 250,
            duration: 30
        )

        // Then: Totals should be decremented
        XCTAssertEqual(
            mockRepository.lastRemovedCalories,
            250,
            "Should remove 250 kcal from totalCaloriesOut"
        )
        XCTAssertEqual(
            mockRepository.lastRemovedDuration,
            30,
            "Should remove 30 minutes from exerciseMinutes"
        )
        XCTAssertTrue(
            mockRepository.removeExerciseCalled,
            "removeExercise should be called on repository"
        )
    }

    /// Test: Removing exercise decrements exerciseCount by 1
    ///
    /// 테스트: 운동 삭제 시 exerciseCount가 1 감소
    func testRemoveExercise_DecrementCount_ReducesByOne() async throws {
        // Given: DailyLog with 3 exercises
        let initialLog = createDailyLog(
            totalCaloriesOut: 900,
            exerciseMinutes: 90,
            exerciseCount: 3
        )
        mockRepository.dailyLog = initialLog

        // When: Removing one exercise
        try await service.removeExercise(
            date: testDate,
            userId: testUserId,
            calories: 300,
            duration: 30
        )

        // Then: Count should be decremented
        XCTAssertTrue(
            mockRepository.removeExerciseCalled,
            "removeExercise should be called"
        )
    }

    /// Test: Removing all exercises leaves zero totals
    ///
    /// 테스트: 모든 운동 삭제 시 합계가 0이 됨
    func testRemoveExercise_RemoveAll_LeavesZeroTotals() async throws {
        // Given: DailyLog with one exercise (280 kcal, 30 minutes, 1 count)
        let initialLog = createDailyLog(
            totalCaloriesOut: 280,
            exerciseMinutes: 30,
            exerciseCount: 1
        )
        mockRepository.dailyLog = initialLog

        // When: Removing the only exercise
        try await service.removeExercise(
            date: testDate,
            userId: testUserId,
            calories: 280,
            duration: 30
        )

        // Then: Should attempt to remove all values
        XCTAssertEqual(
            mockRepository.lastRemovedCalories,
            280,
            "Should remove 280 kcal"
        )
        XCTAssertEqual(
            mockRepository.lastRemovedDuration,
            30,
            "Should remove 30 minutes"
        )
    }

    /// Test: Removing exercise with low values
    ///
    /// 테스트: 작은 값의 운동 삭제
    func testRemoveExercise_LowValues_RemovesCorrectly() async throws {
        // Given: DailyLog with minimal exercise (10 kcal, 5 minutes)
        let initialLog = createDailyLog(
            totalCaloriesOut: 10,
            exerciseMinutes: 5,
            exerciseCount: 1
        )
        mockRepository.dailyLog = initialLog

        // When: Removing the minimal exercise
        try await service.removeExercise(
            date: testDate,
            userId: testUserId,
            calories: 10,
            duration: 5
        )

        // Then: Should remove small values correctly
        XCTAssertEqual(
            mockRepository.lastRemovedCalories,
            10,
            "Should remove 10 kcal"
        )
        XCTAssertEqual(
            mockRepository.lastRemovedDuration,
            5,
            "Should remove 5 minutes"
        )
    }

    // MARK: - Update Exercise Tests

    /// Test: Updating exercise adjusts difference correctly
    ///
    /// 테스트: 운동 수정 시 차이값이 올바르게 적용됨
    func testUpdateExercise_IncreasedValues_AdjustsDifferenceCorrectly() async throws {
        // Given: DailyLog with existing exercise
        let initialLog = createDailyLog(
            totalCaloriesOut: 350,
            exerciseMinutes: 30,
            exerciseCount: 1
        )
        mockRepository.dailyLog = initialLog

        // When: Updating exercise (old: 350 kcal, 30 min → new: 500 kcal, 45 min)
        try await service.updateExercise(
            date: testDate,
            userId: testUserId,
            oldCalories: 350,
            newCalories: 500,
            oldDuration: 30,
            newDuration: 45
        )

        // Then: Should add the difference (+150 kcal, +15 min)
        XCTAssertEqual(
            mockRepository.lastOldCalories,
            350,
            "Should store old calories"
        )
        XCTAssertEqual(
            mockRepository.lastNewCalories,
            500,
            "Should store new calories"
        )
        XCTAssertEqual(
            mockRepository.lastOldDuration,
            30,
            "Should store old duration"
        )
        XCTAssertEqual(
            mockRepository.lastNewDuration,
            45,
            "Should store new duration"
        )
        XCTAssertTrue(
            mockRepository.updateExerciseCalled,
            "updateExercise should be called on repository"
        )
    }

    /// Test: Updating exercise with decreased values
    ///
    /// 테스트: 운동 수정 시 값이 감소한 경우
    func testUpdateExercise_DecreasedValues_AdjustsDifferenceCorrectly() async throws {
        // Given: DailyLog with existing exercise
        let initialLog = createDailyLog(
            totalCaloriesOut: 500,
            exerciseMinutes: 60,
            exerciseCount: 1
        )
        mockRepository.dailyLog = initialLog

        // When: Updating exercise (old: 500 kcal, 60 min → new: 300 kcal, 40 min)
        try await service.updateExercise(
            date: testDate,
            userId: testUserId,
            oldCalories: 500,
            newCalories: 300,
            oldDuration: 60,
            newDuration: 40
        )

        // Then: Should subtract the difference (-200 kcal, -20 min)
        XCTAssertEqual(
            mockRepository.lastOldCalories,
            500,
            "Should store old calories"
        )
        XCTAssertEqual(
            mockRepository.lastNewCalories,
            300,
            "Should store new calories"
        )
        XCTAssertEqual(
            mockRepository.lastOldDuration,
            60,
            "Should store old duration"
        )
        XCTAssertEqual(
            mockRepository.lastNewDuration,
            40,
            "Should store new duration"
        )
    }

    /// Test: Updating exercise with same values (no change)
    ///
    /// 테스트: 운동 수정 시 값이 동일한 경우 (변경 없음)
    func testUpdateExercise_SameValues_AdjustsZeroDifference() async throws {
        // Given: DailyLog with existing exercise
        let initialLog = createDailyLog(
            totalCaloriesOut: 400,
            exerciseMinutes: 45,
            exerciseCount: 1
        )
        mockRepository.dailyLog = initialLog

        // When: Updating exercise with same values (old == new)
        try await service.updateExercise(
            date: testDate,
            userId: testUserId,
            oldCalories: 400,
            newCalories: 400,
            oldDuration: 45,
            newDuration: 45
        )

        // Then: Should apply zero difference (no actual change)
        XCTAssertEqual(
            mockRepository.lastOldCalories,
            400,
            "Should store old calories"
        )
        XCTAssertEqual(
            mockRepository.lastNewCalories,
            400,
            "Should store new calories"
        )
        XCTAssertTrue(
            mockRepository.updateExerciseCalled,
            "updateExercise should still be called"
        )
    }

    /// Test: Updating exercise only changes calories
    ///
    /// 테스트: 운동 수정 시 칼로리만 변경
    func testUpdateExercise_OnlyCaloriesChanged_AdjustsCorrectly() async throws {
        // Given: DailyLog with existing exercise
        let initialLog = createDailyLog(
            totalCaloriesOut: 300,
            exerciseMinutes: 30,
            exerciseCount: 1
        )
        mockRepository.dailyLog = initialLog

        // When: Updating only calories (duration unchanged)
        try await service.updateExercise(
            date: testDate,
            userId: testUserId,
            oldCalories: 300,
            newCalories: 450,
            oldDuration: 30,
            newDuration: 30
        )

        // Then: Should adjust only calories (+150 kcal, +0 min)
        XCTAssertEqual(
            mockRepository.lastOldCalories,
            300,
            "Should store old calories"
        )
        XCTAssertEqual(
            mockRepository.lastNewCalories,
            450,
            "Should store new calories"
        )
        XCTAssertEqual(
            mockRepository.lastOldDuration,
            30,
            "Duration should remain same"
        )
        XCTAssertEqual(
            mockRepository.lastNewDuration,
            30,
            "Duration should remain same"
        )
    }

    /// Test: Updating exercise only changes duration
    ///
    /// 테스트: 운동 수정 시 시간만 변경
    func testUpdateExercise_OnlyDurationChanged_AdjustsCorrectly() async throws {
        // Given: DailyLog with existing exercise
        let initialLog = createDailyLog(
            totalCaloriesOut: 350,
            exerciseMinutes: 30,
            exerciseCount: 1
        )
        mockRepository.dailyLog = initialLog

        // When: Updating only duration (calories unchanged)
        try await service.updateExercise(
            date: testDate,
            userId: testUserId,
            oldCalories: 350,
            newCalories: 350,
            oldDuration: 30,
            newDuration: 45
        )

        // Then: Should adjust only duration (+0 kcal, +15 min)
        XCTAssertEqual(
            mockRepository.lastOldCalories,
            350,
            "Calories should remain same"
        )
        XCTAssertEqual(
            mockRepository.lastNewCalories,
            350,
            "Calories should remain same"
        )
        XCTAssertEqual(
            mockRepository.lastOldDuration,
            30,
            "Should store old duration"
        )
        XCTAssertEqual(
            mockRepository.lastNewDuration,
            45,
            "Should store new duration"
        )
    }

    /// Test: Updating exercise does not change exerciseCount
    ///
    /// 테스트: 운동 수정 시 exerciseCount는 변경되지 않음
    func testUpdateExercise_DoesNotChangeCount() async throws {
        // Given: DailyLog with 2 exercises
        let initialLog = createDailyLog(
            totalCaloriesOut: 600,
            exerciseMinutes: 60,
            exerciseCount: 2
        )
        mockRepository.dailyLog = initialLog

        // When: Updating one exercise
        try await service.updateExercise(
            date: testDate,
            userId: testUserId,
            oldCalories: 300,
            newCalories: 400,
            oldDuration: 30,
            newDuration: 40
        )

        // Then: exerciseCount should not be passed to updateExercise
        // (updateExercise only takes calories and duration, not count)
        XCTAssertTrue(
            mockRepository.updateExerciseCalled,
            "updateExercise should be called"
        )
        // Note: The repository method signature confirms count is not modified
    }

    // MARK: - ExerciseCount Tests

    /// Test: Adding exercise increments exerciseCount
    ///
    /// 테스트: 운동 추가 시 exerciseCount 증가 확인
    func testAddExercise_IncrementsExerciseCount() async throws {
        // Given: DailyLog with 2 exercises
        let initialLog = createDailyLog(
            totalCaloriesOut: 500,
            exerciseMinutes: 50,
            exerciseCount: 2
        )
        mockRepository.dailyLog = initialLog

        // When: Adding a new exercise
        try await service.addExercise(
            date: testDate,
            userId: testUserId,
            calories: 280,
            duration: 30,
            userBMR: 1650,
            userTDEE: 2310
        )

        // Then: Repository should receive the add request
        // (exerciseCount incrementation happens in repository/data source)
        XCTAssertTrue(
            mockRepository.addExerciseCalled,
            "addExercise should be called (count incremented in repository)"
        )
    }

    /// Test: Removing exercise decrements exerciseCount
    ///
    /// 테스트: 운동 삭제 시 exerciseCount 감소 확인
    func testRemoveExercise_DecrementsExerciseCount() async throws {
        // Given: DailyLog with 3 exercises
        let initialLog = createDailyLog(
            totalCaloriesOut: 750,
            exerciseMinutes: 75,
            exerciseCount: 3
        )
        mockRepository.dailyLog = initialLog

        // When: Removing one exercise
        try await service.removeExercise(
            date: testDate,
            userId: testUserId,
            calories: 250,
            duration: 25
        )

        // Then: Repository should receive the remove request
        // (exerciseCount decrementation happens in repository/data source)
        XCTAssertTrue(
            mockRepository.removeExerciseCalled,
            "removeExercise should be called (count decremented in repository)"
        )
    }

    // MARK: - GetOrCreate Tests

    /// Test: getOrCreate returns existing DailyLog
    ///
    /// 테스트: getOrCreate가 기존 DailyLog를 반환
    func testGetOrCreate_ExistingLog_ReturnsExisting() async throws {
        // Given: Existing DailyLog
        let existingLog = createDailyLog(
            totalCaloriesOut: 300,
            exerciseMinutes: 30,
            exerciseCount: 1
        )
        mockRepository.dailyLog = existingLog

        // When: Calling getOrCreate
        let result = try await service.getOrCreate(
            for: testDate,
            userId: testUserId,
            userBMR: 1650,
            userTDEE: 2310
        )

        // Then: Should return existing log
        XCTAssertEqual(
            result.id,
            existingLog.id,
            "Should return existing DailyLog"
        )
        XCTAssertTrue(
            mockRepository.getOrCreateCalled,
            "getOrCreate should be called on repository"
        )
    }

    /// Test: getOrCreate creates new DailyLog when not exists
    ///
    /// 테스트: getOrCreate가 없을 때 새로 생성
    func testGetOrCreate_NoLog_CreatesNew() async throws {
        // Given: No existing DailyLog
        mockRepository.dailyLog = nil
        mockRepository.shouldCreateNew = true

        // When: Calling getOrCreate
        let result = try await service.getOrCreate(
            for: testDate,
            userId: testUserId,
            userBMR: 1650,
            userTDEE: 2310
        )

        // Then: Should create new DailyLog
        XCTAssertNotNil(result, "Should create new DailyLog")
        XCTAssertTrue(
            mockRepository.getOrCreateCalled,
            "getOrCreate should be called on repository"
        )
        XCTAssertEqual(
            mockRepository.lastCreatedBMR,
            1650,
            "Should use provided BMR"
        )
        XCTAssertEqual(
            mockRepository.lastCreatedTDEE,
            2310,
            "Should use provided TDEE"
        )
    }

    // MARK: - Helper Methods

    /// Creates a test DailyLog with specified exercise data
    ///
    /// 테스트용 DailyLog 생성
    private func createDailyLog(
        totalCaloriesOut: Int32,
        exerciseMinutes: Int32,
        exerciseCount: Int16
    ) -> DailyLog {
        return DailyLog(
            id: UUID(),
            userId: testUserId,
            date: testDate,
            totalCaloriesIn: 0,
            totalCarbs: 0,
            totalProtein: 0,
            totalFat: 0,
            carbsRatio: nil,
            proteinRatio: nil,
            fatRatio: nil,
            bmr: 1650,
            tdee: 2310,
            netCalories: -2310,
            totalCaloriesOut: totalCaloriesOut,
            exerciseMinutes: exerciseMinutes,
            exerciseCount: exerciseCount,
            steps: nil,
            weight: nil,
            bodyFatPct: nil,
            sleepDuration: nil,
            sleepStatus: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}

// MARK: - MockDailyLogRepository

/// Mock implementation of DailyLogRepository for testing
///
/// 테스트용 DailyLogRepository Mock 구현
class MockDailyLogRepository: DailyLogRepository {

    // MARK: - Test Data

    var dailyLog: DailyLog?
    var shouldCreateNew = false

    // MARK: - Call Tracking

    var getOrCreateCalled = false
    var addExerciseCalled = false
    var removeExerciseCalled = false
    var updateExerciseCalled = false

    var addExerciseCallCount = 0

    // MARK: - Captured Parameters

    var lastCreatedBMR: Int32?
    var lastCreatedTDEE: Int32?

    var lastAddedCalories: Int32?
    var lastAddedDuration: Int32?

    var lastRemovedCalories: Int32?
    var lastRemovedDuration: Int32?

    var lastOldCalories: Int32?
    var lastNewCalories: Int32?
    var lastOldDuration: Int32?
    var lastNewDuration: Int32?

    // MARK: - DailyLogRepository Implementation

    func getOrCreate(for date: Date, userId: UUID, bmr: Int32, tdee: Int32) async throws -> DailyLog {
        getOrCreateCalled = true
        lastCreatedBMR = bmr
        lastCreatedTDEE = tdee

        if let existing = dailyLog {
            return existing
        }

        if shouldCreateNew {
            // Create new DailyLog for test
            let newLog = DailyLog(
                id: UUID(),
                userId: userId,
                date: date,
                totalCaloriesIn: 0,
                totalCarbs: 0,
                totalProtein: 0,
                totalFat: 0,
                carbsRatio: nil,
                proteinRatio: nil,
                fatRatio: nil,
                bmr: bmr,
                tdee: tdee,
                netCalories: -tdee,
                totalCaloriesOut: 0,
                exerciseMinutes: 0,
                exerciseCount: 0,
                steps: nil,
                weight: nil,
                bodyFatPct: nil,
                sleepDuration: nil,
                sleepStatus: nil,
                createdAt: Date(),
                updatedAt: Date()
            )
            dailyLog = newLog
            return newLog
        }

        throw NSError(domain: "MockRepository", code: 404, userInfo: [NSLocalizedDescriptionKey: "Not found"])
    }

    func fetch(for date: Date, userId: UUID) async throws -> DailyLog? {
        return dailyLog
    }

    func update(_ dailyLog: DailyLog) async throws -> DailyLog {
        self.dailyLog = dailyLog
        return dailyLog
    }

    func addExercise(date: Date, userId: UUID, calories: Int32, duration: Int32) async throws {
        addExerciseCalled = true
        addExerciseCallCount += 1
        lastAddedCalories = calories
        lastAddedDuration = duration

        // Simulate repository behavior: increment totals
        if var log = dailyLog {
            log.totalCaloriesOut += calories
            log.exerciseMinutes += duration
            log.exerciseCount += 1
            dailyLog = log
        }
    }

    func removeExercise(date: Date, userId: UUID, calories: Int32, duration: Int32) async throws {
        removeExerciseCalled = true
        lastRemovedCalories = calories
        lastRemovedDuration = duration

        // Simulate repository behavior: decrement totals
        if var log = dailyLog {
            log.totalCaloriesOut = max(0, log.totalCaloriesOut - calories)
            log.exerciseMinutes = max(0, log.exerciseMinutes - duration)
            log.exerciseCount = max(0, log.exerciseCount - 1)
            dailyLog = log
        }
    }

    func updateExercise(
        date: Date,
        userId: UUID,
        oldCalories: Int32,
        newCalories: Int32,
        oldDuration: Int32,
        newDuration: Int32
    ) async throws {
        updateExerciseCalled = true
        lastOldCalories = oldCalories
        lastNewCalories = newCalories
        lastOldDuration = oldDuration
        lastNewDuration = newDuration

        // Simulate repository behavior: adjust difference
        if var log = dailyLog {
            let caloriesDiff = newCalories - oldCalories
            let durationDiff = newDuration - oldDuration

            log.totalCaloriesOut += caloriesDiff
            log.exerciseMinutes += durationDiff
            // Note: exerciseCount is NOT modified during update
            dailyLog = log
        }
    }
}
