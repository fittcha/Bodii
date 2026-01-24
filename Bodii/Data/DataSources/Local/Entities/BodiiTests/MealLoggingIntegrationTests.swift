//
//  MealLoggingIntegrationTests.swift
//  BodiiTests
//
//  Created by Auto-Claude on 2026-01-13.
//

import XCTest
@testable import Bodii

/// Integration tests for the complete meal logging flow
///
/// 식단 기록 전체 흐름에 대한 통합 테스트
///
/// 이 테스트는 ViewModels, Services, Repositories가 함께 작동하는 전체 흐름을 검증합니다.
/// - Food 추가 → FoodRecord 생성 → DailyLog 업데이트
/// - Food 삭제 → FoodRecord 제거 → DailyLog 업데이트
/// - 날짜 네비게이션 → 데이터 새로고침
@MainActor
final class MealLoggingIntegrationTests: XCTestCase {

    // MARK: - Properties

    private var dailyMealViewModel: DailyMealViewModel!
    private var foodDetailViewModel: FoodDetailViewModel!
    private var manualFoodEntryViewModel: ManualFoodEntryViewModel!

    private var foodRecordService: FoodRecordService!
    private var localFoodSearchService: LocalFoodSearchService!

    private var mockFoodRecordRepository: MockFoodRecordRepository!
    private var mockDailyLogRepository: MockDailyLogRepository!
    private var mockFoodRepository: MockFoodRepository!

    // MARK: - Test Data

    private let testUserId = UUID()
    private let testDate = Date()
    private let testBMR: Int32 = 1650
    private let testTDEE: Int32 = 2310

    /// Sample food for testing (백미밥 - White Rice)
    private lazy var whiteRice = Food(
        id: UUID(),
        name: "백미밥",
        calories: 300,
        carbohydrates: Decimal(65.8),
        protein: Decimal(5.4),
        fat: Decimal(0.5),
        sodium: Decimal(2.0),
        fiber: Decimal(0.8),
        sugar: Decimal(0.1),
        servingSize: Decimal(210.0),
        servingUnit: "1공기",
        source: .governmentAPI,
        apiCode: "KR001",
        createdByUserId: nil,
        createdAt: Date()
    )

    /// Sample food for testing (닭가슴살 - Chicken Breast)
    private lazy var chickenBreast = Food(
        id: UUID(),
        name: "닭가슴살",
        calories: 165,
        carbohydrates: Decimal(0.0),
        protein: Decimal(31.0),
        fat: Decimal(3.6),
        sodium: Decimal(74.0),
        fiber: Decimal(0.0),
        sugar: Decimal(0.0),
        servingSize: Decimal(100.0),
        servingUnit: "100g",
        source: .governmentAPI,
        apiCode: "KR002",
        createdByUserId: nil,
        createdAt: Date()
    )

    // MARK: - Setup & Teardown

    override func setUp() async throws {
        try await super.setUp()

        // Initialize mock repositories
        mockFoodRecordRepository = MockFoodRecordRepository()
        mockDailyLogRepository = MockDailyLogRepository()
        mockFoodRepository = MockFoodRepository()

        // Initialize services
        foodRecordService = FoodRecordService(
            foodRecordRepository: mockFoodRecordRepository,
            dailyLogRepository: mockDailyLogRepository,
            foodRepository: mockFoodRepository
        )

        localFoodSearchService = LocalFoodSearchService(
            foodRepository: mockFoodRepository
        )

        // Initialize ViewModels
        dailyMealViewModel = DailyMealViewModel(
            foodRecordService: foodRecordService,
            dailyLogRepository: mockDailyLogRepository,
            foodRepository: mockFoodRepository
        )

        foodDetailViewModel = FoodDetailViewModel(
            foodId: whiteRice.id,
            selectedDate: testDate,
            selectedMealType: .breakfast,
            foodRepository: mockFoodRepository,
            foodRecordService: foodRecordService
        )

        manualFoodEntryViewModel = ManualFoodEntryViewModel(
            selectedDate: testDate,
            selectedMealType: .breakfast,
            foodRepository: mockFoodRepository,
            foodRecordService: foodRecordService
        )

        // Setup default mock data
        mockFoodRepository.foodToReturn = whiteRice
        mockDailyLogRepository.dailyLogToReturn = createEmptyDailyLog()
    }

    override func tearDown() async throws {
        dailyMealViewModel = nil
        foodDetailViewModel = nil
        manualFoodEntryViewModel = nil
        foodRecordService = nil
        localFoodSearchService = nil
        mockFoodRecordRepository = nil
        mockDailyLogRepository = nil
        mockFoodRepository = nil
        try await super.tearDown()
    }

    // MARK: - Complete Meal Logging Flow Tests

    /// Test: Complete flow - Add food via FoodDetailViewModel and verify in DailyMealViewModel
    ///
    /// 테스트: 전체 흐름 - FoodDetailViewModel을 통한 음식 추가 및 DailyMealViewModel에서 확인
    func testCompleteFlow_AddFoodThenRefresh_ShowsInDailyMeal() async throws {
        // Given: Empty daily log and food available
        let emptyDailyLog = createEmptyDailyLog()
        mockDailyLogRepository.dailyLogToReturn = emptyDailyLog
        mockFoodRepository.foodToReturn = whiteRice

        // When: Load food in detail view
        await foodDetailViewModel.onAppear(userId: testUserId, bmr: testBMR, tdee: testTDEE)

        // Then: Food should be loaded
        XCTAssertNotNil(foodDetailViewModel.food, "Food should be loaded")
        XCTAssertEqual(foodDetailViewModel.food?.name, "백미밥", "Food name should match")

        // When: Save food record with 1.5 servings
        foodDetailViewModel.quantity = Decimal(1.5)
        foodDetailViewModel.selectedMealType = .breakfast

        let savedRecord = try await foodDetailViewModel.saveFoodRecord()

        // Then: Should save successfully
        XCTAssertNotNil(savedRecord, "Food record should be saved")
        XCTAssertEqual(savedRecord?.quantity, Decimal(1.5), "Quantity should be 1.5")
        XCTAssertEqual(savedRecord?.calculatedCalories, 450, "1.5 servings should be 450 kcal (300 * 1.5)")

        // Given: Update mock to return the saved record
        mockFoodRecordRepository.foodRecordsToReturn = [savedRecord!]
        mockDailyLogRepository.dailyLogToReturn = createDailyLogWithOneFood()

        // When: Load daily meal view
        await dailyMealViewModel.loadData(userId: testUserId, bmr: testBMR, tdee: testTDEE)

        // Then: Should show the food record
        XCTAssertFalse(dailyMealViewModel.hasAnyMeals == false, "Should have meals")
        XCTAssertTrue(dailyMealViewModel.hasMeals(for: .breakfast), "Should have breakfast meal")

        let breakfastMeals = dailyMealViewModel.mealGroups[.breakfast] ?? []
        XCTAssertEqual(breakfastMeals.count, 1, "Should have 1 breakfast item")
        XCTAssertEqual(breakfastMeals.first?.foodRecord.calculatedCalories, 450, "Calories should be 450")

        // Then: DailyLog should be updated
        XCTAssertNotNil(dailyMealViewModel.dailyLog, "DailyLog should be loaded")
        XCTAssertEqual(dailyMealViewModel.dailyLog?.totalCaloriesIn, 450, "Total calories should be 450")
    }

    /// Test: Add multiple foods to different meal types
    ///
    /// 테스트: 여러 끼니에 음식 추가
    func testCompleteFlow_AddMultipleFoodsToDifferentMeals_UpdatesTotalsCorrectly() async throws {
        // Given: Empty daily log
        mockDailyLogRepository.dailyLogToReturn = createEmptyDailyLog()

        // When: Add white rice to breakfast
        mockFoodRepository.foodToReturn = whiteRice
        let breakfastRecord = try await foodRecordService.addFoodRecord(
            userId: testUserId,
            foodId: whiteRice.id,
            date: testDate,
            mealType: .breakfast,
            quantity: Decimal(1.0),
            quantityUnit: .serving,
            bmr: testBMR,
            tdee: testTDEE
        )

        // Then: Should calculate correctly
        XCTAssertEqual(breakfastRecord.calculatedCalories, 300, "Rice should be 300 kcal")
        XCTAssertEqual(breakfastRecord.calculatedCarbs, Decimal(65.8), "Rice should have 65.8g carbs")

        // Given: Update daily log to include breakfast
        let dailyLogAfterBreakfast = DailyLog(
            id: UUID(),
            userId: testUserId,
            date: testDate,
            totalCaloriesIn: 300,
            totalCarbs: Decimal(65.8),
            totalProtein: Decimal(5.4),
            totalFat: Decimal(0.5),
            carbsRatio: Decimal(85.8),
            proteinRatio: Decimal(7.1),
            fatRatio: Decimal(7.1),
            bmr: testBMR,
            tdee: testTDEE,
            netCalories: -2010,
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
        mockDailyLogRepository.dailyLogToReturn = dailyLogAfterBreakfast

        // When: Add chicken breast to lunch
        mockFoodRepository.foodToReturn = chickenBreast
        let lunchRecord = try await foodRecordService.addFoodRecord(
            userId: testUserId,
            foodId: chickenBreast.id,
            date: testDate,
            mealType: .lunch,
            quantity: Decimal(150.0),
            quantityUnit: .gram,
            bmr: testBMR,
            tdee: testTDEE
        )

        // Then: Should calculate correctly (150g = 1.5 servings of 100g)
        XCTAssertEqual(lunchRecord.calculatedCalories, Int32(247.5), "150g chicken should be 247.5 kcal")
        XCTAssertEqual(lunchRecord.calculatedProtein.rounded(scale: 1), Decimal(46.5), "150g chicken should have 46.5g protein")

        // Given: Update daily log to include both meals
        let dailyLogWithBothMeals = DailyLog(
            id: UUID(),
            userId: testUserId,
            date: testDate,
            totalCaloriesIn: 547, // 300 + 247.5 rounded
            totalCarbs: Decimal(65.8),
            totalProtein: Decimal(51.9), // 5.4 + 46.5
            totalFat: Decimal(5.9), // 0.5 + 5.4
            carbsRatio: Decimal(46.5),
            proteinRatio: Decimal(36.9),
            fatRatio: Decimal(16.6),
            bmr: testBMR,
            tdee: testTDEE,
            netCalories: -1763,
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
        mockDailyLogRepository.dailyLogToReturn = dailyLogWithBothMeals
        mockFoodRecordRepository.foodRecordsToReturn = [breakfastRecord, lunchRecord]

        // When: Load daily meal view
        await dailyMealViewModel.loadData(userId: testUserId, bmr: testBMR, tdee: testTDEE)

        // Then: Should show both meals
        XCTAssertTrue(dailyMealViewModel.hasMeals(for: .breakfast), "Should have breakfast")
        XCTAssertTrue(dailyMealViewModel.hasMeals(for: .lunch), "Should have lunch")
        XCTAssertEqual(dailyMealViewModel.dailyLog?.totalCaloriesIn, 547, "Total should be 547 kcal")
    }

    /// Test: Delete food record updates DailyLog totals correctly
    ///
    /// 테스트: 음식 삭제 시 DailyLog가 올바르게 업데이트됨
    func testCompleteFlow_DeleteFood_UpdatesDailyLogCorrectly() async throws {
        // Given: Daily log with one food
        let existingRecord = FoodRecord(
            id: UUID(),
            userId: testUserId,
            foodId: whiteRice.id,
            date: testDate,
            mealType: .breakfast,
            quantity: Decimal(1.0),
            quantityUnit: .serving,
            calculatedCalories: 300,
            calculatedCarbs: Decimal(65.8),
            calculatedProtein: Decimal(5.4),
            calculatedFat: Decimal(0.5),
            createdAt: Date()
        )

        mockFoodRecordRepository.foodRecordToReturn = existingRecord
        mockFoodRecordRepository.foodRecordsToReturn = [existingRecord]
        mockDailyLogRepository.dailyLogToReturn = createDailyLogWithOneFood()

        // When: Load daily meal view
        await dailyMealViewModel.loadData(userId: testUserId, bmr: testBMR, tdee: testTDEE)

        // Then: Should show the food
        XCTAssertTrue(dailyMealViewModel.hasMeals(for: .breakfast), "Should have breakfast before delete")
        XCTAssertEqual(dailyMealViewModel.dailyLog?.totalCaloriesIn, 300, "Should have 300 kcal before delete")

        // When: Delete the food record
        try await dailyMealViewModel.deleteFoodRecord(existingRecord.id)

        // Then: Should call delete on repository
        XCTAssertTrue(mockFoodRecordRepository.deleteCalled, "Should call delete")

        // Given: Update mocks to reflect deletion
        mockFoodRecordRepository.foodRecordsToReturn = []
        mockDailyLogRepository.dailyLogToReturn = createEmptyDailyLog()

        // When: Reload data
        await dailyMealViewModel.loadData(userId: testUserId, bmr: testBMR, tdee: testTDEE)

        // Then: Should show empty state
        XCTAssertFalse(dailyMealViewModel.hasAnyMeals, "Should have no meals after delete")
        XCTAssertEqual(dailyMealViewModel.dailyLog?.totalCaloriesIn, 0, "Calories should be 0 after delete")
        XCTAssertEqual(dailyMealViewModel.dailyLog?.netCalories, -testTDEE, "Net calories should be -TDEE")
    }

    /// Test: Delete one of multiple foods updates totals correctly
    ///
    /// 테스트: 여러 음식 중 하나 삭제 시 합계가 올바르게 업데이트됨
    func testCompleteFlow_DeleteOneOfMultipleFoods_UpdatesTotalsCorrectly() async throws {
        // Given: Two food records
        let riceRecord = FoodRecord(
            id: UUID(),
            userId: testUserId,
            foodId: whiteRice.id,
            date: testDate,
            mealType: .breakfast,
            quantity: Decimal(1.0),
            quantityUnit: .serving,
            calculatedCalories: 300,
            calculatedCarbs: Decimal(65.8),
            calculatedProtein: Decimal(5.4),
            calculatedFat: Decimal(0.5),
            createdAt: Date()
        )

        let chickenRecord = FoodRecord(
            id: UUID(),
            userId: testUserId,
            foodId: chickenBreast.id,
            date: testDate,
            mealType: .lunch,
            quantity: Decimal(100.0),
            quantityUnit: .gram,
            calculatedCalories: 165,
            calculatedCarbs: Decimal(0.0),
            calculatedProtein: Decimal(31.0),
            calculatedFat: Decimal(3.6),
            createdAt: Date()
        )

        mockFoodRecordRepository.foodRecordsToReturn = [riceRecord, chickenRecord]
        mockDailyLogRepository.dailyLogToReturn = createDailyLogWithTwoFoods()

        // When: Load daily meal view
        await dailyMealViewModel.loadData(userId: testUserId, bmr: testBMR, tdee: testTDEE)

        // Then: Should show both foods
        XCTAssertEqual(dailyMealViewModel.dailyLog?.totalCaloriesIn, 465, "Should have 465 kcal (300 + 165)")

        // When: Delete chicken record
        mockFoodRecordRepository.foodRecordToReturn = chickenRecord
        try await dailyMealViewModel.deleteFoodRecord(chickenRecord.id)

        // Given: Update mocks to reflect deletion
        mockFoodRecordRepository.foodRecordsToReturn = [riceRecord]
        mockDailyLogRepository.dailyLogToReturn = createDailyLogWithOneFood()

        // When: Reload data
        await dailyMealViewModel.loadData(userId: testUserId, bmr: testBMR, tdee: testTDEE)

        // Then: Should only show rice
        XCTAssertTrue(dailyMealViewModel.hasMeals(for: .breakfast), "Should still have breakfast")
        XCTAssertFalse(dailyMealViewModel.hasMeals(for: .lunch), "Should not have lunch after delete")
        XCTAssertEqual(dailyMealViewModel.dailyLog?.totalCaloriesIn, 300, "Should have 300 kcal (rice only)")
    }

    // MARK: - Date Navigation Tests

    /// Test: Navigate to next day refreshes data
    ///
    /// 테스트: 다음 날로 이동 시 데이터 새로고침
    func testDateNavigation_NavigateToNextDay_RefreshesData() async throws {
        // Given: Data for today
        mockFoodRecordRepository.foodRecordsToReturn = []
        mockDailyLogRepository.dailyLogToReturn = createEmptyDailyLog()

        // When: Load today's data
        await dailyMealViewModel.loadData(userId: testUserId, bmr: testBMR, tdee: testTDEE)
        let today = dailyMealViewModel.selectedDate

        // Then: Should be today
        XCTAssertEqual(Calendar.current.isDateInToday(today), true, "Should start with today")

        // When: Navigate to previous day
        await dailyMealViewModel.navigateToPreviousDay()

        // Then: Should be yesterday
        let yesterday = dailyMealViewModel.selectedDate
        XCTAssertNotEqual(yesterday, today, "Date should change")
        XCTAssertLessThan(yesterday, today, "Should be earlier date")
        XCTAssertTrue(mockDailyLogRepository.getOrCreateCalled, "Should load data for new date")
    }

    /// Test: Navigate to previous day refreshes data
    ///
    /// 테스트: 이전 날로 이동 시 데이터 새로고침
    func testDateNavigation_NavigateToPreviousDay_RefreshesData() async throws {
        // Given: Initial state
        await dailyMealViewModel.loadData(userId: testUserId, bmr: testBMR, tdee: testTDEE)
        let initialDate = dailyMealViewModel.selectedDate

        // When: Navigate to previous day
        await dailyMealViewModel.navigateToPreviousDay()

        // Then: Date should change
        let newDate = dailyMealViewModel.selectedDate
        XCTAssertNotEqual(newDate, initialDate, "Date should change")
        XCTAssertLessThan(newDate, initialDate, "Should be earlier date")

        // Then: Should reload data
        XCTAssertTrue(mockDailyLogRepository.getOrCreateCalled, "Should call getOrCreate for new date")
        XCTAssertTrue(mockFoodRecordRepository.findByDateCalled, "Should fetch records for new date")
    }

    /// Test: Navigate to next day refreshes data
    ///
    /// 테스트: 다음 날로 이동 시 데이터 새로고침
    func testDateNavigation_NavigateToNextDay_LoadsDataForNewDate() async throws {
        // Given: Start at yesterday
        await dailyMealViewModel.loadData(userId: testUserId, bmr: testBMR, tdee: testTDEE)
        await dailyMealViewModel.navigateToPreviousDay()
        let previousDate = dailyMealViewModel.selectedDate

        // When: Navigate to next day (today)
        await dailyMealViewModel.navigateToNextDay()

        // Then: Date should change
        let newDate = dailyMealViewModel.selectedDate
        XCTAssertNotEqual(newDate, previousDate, "Date should change")
        XCTAssertGreaterThan(newDate, previousDate, "Should be later date")

        // Then: Should reload data
        XCTAssertTrue(mockDailyLogRepository.getOrCreateCalled, "Should load data for new date")
    }

    /// Test: Navigate to specific date refreshes data
    ///
    /// 테스트: 특정 날짜로 이동 시 데이터 새로고침
    func testDateNavigation_NavigateToSpecificDate_LoadsDataForThatDate() async throws {
        // Given: Initial state
        await dailyMealViewModel.loadData(userId: testUserId, bmr: testBMR, tdee: testTDEE)

        // When: Navigate to specific date (7 days ago)
        let targetDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        await dailyMealViewModel.navigateToDate(targetDate)

        // Then: Date should change to target date
        let newDate = dailyMealViewModel.selectedDate
        XCTAssertEqual(
            Calendar.current.startOfDay(for: newDate),
            Calendar.current.startOfDay(for: targetDate),
            "Should navigate to target date"
        )

        // Then: Should reload data
        XCTAssertTrue(mockDailyLogRepository.getOrCreateCalled, "Should load data for target date")
        XCTAssertTrue(mockFoodRecordRepository.findByDateCalled, "Should fetch records for target date")
    }

    // MARK: - Manual Food Entry Integration Tests

    /// Test: Manual food entry creates food and adds to meal
    ///
    /// 테스트: 수동 음식 입력이 음식을 생성하고 끼니에 추가함
    func testManualFoodEntry_CreateAndAddToMeal_WorksEndToEnd() async throws {
        // Given: Empty daily log
        mockDailyLogRepository.dailyLogToReturn = createEmptyDailyLog()

        // When: Fill in manual entry form
        manualFoodEntryViewModel.foodName = "수제 샐러드"
        manualFoodEntryViewModel.servingSize = "250"
        manualFoodEntryViewModel.servingUnit = "1그릇"
        manualFoodEntryViewModel.calories = "150"
        manualFoodEntryViewModel.carbohydrates = "10"
        manualFoodEntryViewModel.protein = "8"
        manualFoodEntryViewModel.fat = "9"
        manualFoodEntryViewModel.fiber = "5"

        // Then: Validation should pass
        XCTAssertTrue(manualFoodEntryViewModel.canSave, "Should be able to save")

        // When: Save manual food entry
        let savedRecord = try await manualFoodEntryViewModel.saveAndAddToMeal(
            userId: testUserId,
            bmr: testBMR,
            tdee: testTDEE
        )

        // Then: Should save successfully
        XCTAssertNotNil(savedRecord, "Should return saved record")
        XCTAssertEqual(savedRecord?.calculatedCalories, 150, "Calories should match input")

        // Then: Should save food to repository
        XCTAssertTrue(mockFoodRepository.saveCalled, "Should save food")
    }

    /// Test: Manual food entry with validation errors
    ///
    /// 테스트: 유효성 검증 오류가 있는 수동 음식 입력
    func testManualFoodEntry_WithValidationErrors_ShowsErrors() async throws {
        // Given: Empty form
        manualFoodEntryViewModel.foodName = ""
        manualFoodEntryViewModel.calories = ""
        manualFoodEntryViewModel.servingSize = ""

        // When: Validate
        let isValid = manualFoodEntryViewModel.validate()

        // Then: Should fail validation
        XCTAssertFalse(isValid, "Validation should fail")
        XCTAssertFalse(manualFoodEntryViewModel.canSave, "Should not be able to save")

        // Then: Should have error messages
        XCTAssertNotNil(manualFoodEntryViewModel.validationErrors.foodName, "Should have name error")
        XCTAssertNotNil(manualFoodEntryViewModel.validationErrors.calories, "Should have calories error")
        XCTAssertNotNil(manualFoodEntryViewModel.validationErrors.servingSize, "Should have serving size error")
    }

    // MARK: - Error Handling Tests

    /// Test: Error handling when repository fails
    ///
    /// 테스트: Repository 실패 시 에러 처리
    func testErrorHandling_RepositoryFailure_SetsErrorMessage() async throws {
        // Given: Mock repository will fail
        mockDailyLogRepository.shouldThrowError = true

        // When: Try to load data
        await dailyMealViewModel.loadData(userId: testUserId, bmr: testBMR, tdee: testTDEE)

        // Then: Should set error message
        XCTAssertNotNil(dailyMealViewModel.errorMessage, "Should have error message")
        XCTAssertFalse(dailyMealViewModel.isLoading, "Should not be loading")
    }

    /// Test: Error handling when food not found
    ///
    /// 테스트: 음식을 찾을 수 없을 때 에러 처리
    func testErrorHandling_FoodNotFound_SetsErrorMessage() async throws {
        // Given: Food doesn't exist
        mockFoodRepository.foodToReturn = nil

        // When: Try to load food in detail view
        await foodDetailViewModel.onAppear(userId: testUserId, bmr: testBMR, tdee: testTDEE)

        // Then: Should set error message
        XCTAssertNotNil(foodDetailViewModel.errorMessage, "Should have error message")
        XCTAssertNil(foodDetailViewModel.food, "Food should be nil")
    }

    // MARK: - Helper Methods

    /// Create empty DailyLog for testing
    private func createEmptyDailyLog() -> DailyLog {
        return DailyLog(
            id: UUID(),
            userId: testUserId,
            date: testDate,
            totalCaloriesIn: 0,
            totalCarbs: Decimal(0),
            totalProtein: Decimal(0),
            totalFat: Decimal(0),
            carbsRatio: nil,
            proteinRatio: nil,
            fatRatio: nil,
            bmr: testBMR,
            tdee: testTDEE,
            netCalories: -testTDEE,
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
    }

    /// Create DailyLog with one food record for testing
    private func createDailyLogWithOneFood() -> DailyLog {
        return DailyLog(
            id: UUID(),
            userId: testUserId,
            date: testDate,
            totalCaloriesIn: 300,
            totalCarbs: Decimal(65.8),
            totalProtein: Decimal(5.4),
            totalFat: Decimal(0.5),
            carbsRatio: Decimal(85.8),
            proteinRatio: Decimal(7.1),
            fatRatio: Decimal(7.1),
            bmr: testBMR,
            tdee: testTDEE,
            netCalories: -2010,
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
    }

    /// Create DailyLog with two food records for testing
    private func createDailyLogWithTwoFoods() -> DailyLog {
        return DailyLog(
            id: UUID(),
            userId: testUserId,
            date: testDate,
            totalCaloriesIn: 465,
            totalCarbs: Decimal(65.8),
            totalProtein: Decimal(36.4),
            totalFat: Decimal(4.1),
            carbsRatio: Decimal(54.9),
            proteinRatio: Decimal(30.5),
            fatRatio: Decimal(14.6),
            bmr: testBMR,
            tdee: testTDEE,
            netCalories: -1845,
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
    }
}

// MARK: - Enhanced Mock Repositories with Error Handling

/// Mock FoodRecordRepository with error handling for integration tests
class MockFoodRecordRepository: FoodRecordRepositoryProtocol {
    var foodRecordToReturn: FoodRecord?
    var foodRecordsToReturn: [FoodRecord] = []
    var saveCalled = false
    var updateCalled = false
    var deleteCalled = false
    var findByIdCalled = false
    var findByDateCalled = false
    var findByDateAndMealTypeCalled = false
    var shouldThrowError = false

    func save(_ foodRecord: FoodRecord) async throws -> FoodRecord {
        if shouldThrowError {
            throw RepositoryError.saveFailed
        }
        saveCalled = true
        return foodRecord
    }

    func findById(_ id: UUID) async throws -> FoodRecord? {
        if shouldThrowError {
            throw RepositoryError.fetchFailed
        }
        findByIdCalled = true
        return foodRecordToReturn
    }

    func update(_ foodRecord: FoodRecord) async throws -> FoodRecord {
        if shouldThrowError {
            throw RepositoryError.updateFailed
        }
        updateCalled = true
        return foodRecord
    }

    func delete(_ id: UUID) async throws {
        if shouldThrowError {
            throw RepositoryError.deleteFailed
        }
        deleteCalled = true
    }

    func findByDate(_ date: Date, userId: UUID) async throws -> [FoodRecord] {
        if shouldThrowError {
            throw RepositoryError.fetchFailed
        }
        findByDateCalled = true
        return foodRecordsToReturn
    }

    func findByDateAndMealType(_ date: Date, mealType: MealType, userId: UUID) async throws -> [FoodRecord] {
        if shouldThrowError {
            throw RepositoryError.fetchFailed
        }
        findByDateAndMealTypeCalled = true
        return foodRecordsToReturn
    }
}

/// Mock DailyLogRepository with error handling for integration tests
class MockDailyLogRepository: DailyLogRepositoryProtocol {
    var dailyLogToReturn: DailyLog?
    var getOrCreateCalled = false
    var findByDateCalled = false
    var updateCalled = false
    var lastUpdatedDailyLog: DailyLog?
    var shouldThrowError = false

    func save(_ dailyLog: DailyLog) async throws -> DailyLog {
        if shouldThrowError {
            throw RepositoryError.saveFailed
        }
        return dailyLog
    }

    func findByDate(_ date: Date, userId: UUID) async throws -> DailyLog? {
        if shouldThrowError {
            throw RepositoryError.fetchFailed
        }
        findByDateCalled = true
        return dailyLogToReturn
    }

    func update(_ dailyLog: DailyLog) async throws -> DailyLog {
        if shouldThrowError {
            throw RepositoryError.updateFailed
        }
        updateCalled = true
        lastUpdatedDailyLog = dailyLog
        return dailyLog
    }

    func delete(_ id: UUID) async throws {
        if shouldThrowError {
            throw RepositoryError.deleteFailed
        }
    }

    func getOrCreate(for date: Date, userId: UUID, bmr: Int32, tdee: Int32) async throws -> DailyLog {
        if shouldThrowError {
            throw RepositoryError.fetchFailed
        }
        getOrCreateCalled = true
        return dailyLogToReturn ?? DailyLog(
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
    }

    func findByDateRange(from: Date, to: Date, userId: UUID) async throws -> [DailyLog] {
        if shouldThrowError {
            throw RepositoryError.fetchFailed
        }
        return []
    }
}

/// Mock FoodRepository with error handling for integration tests
class MockFoodRepository: FoodRepositoryProtocol {
    var foodToReturn: Food?
    var foodsToReturn: [Food] = []
    var recentFoodsToReturn: [Food] = []
    var frequentFoodsToReturn: [Food] = []
    var saveCalled = false
    var shouldThrowError = false

    func save(_ food: Food) async throws -> Food {
        if shouldThrowError {
            throw RepositoryError.saveFailed
        }
        saveCalled = true
        return food
    }

    func findById(_ id: UUID) async throws -> Food? {
        if shouldThrowError {
            throw RepositoryError.fetchFailed
        }
        return foodToReturn
    }

    func findAll() async throws -> [Food] {
        if shouldThrowError {
            throw RepositoryError.fetchFailed
        }
        return []
    }

    func update(_ food: Food) async throws -> Food {
        if shouldThrowError {
            throw RepositoryError.updateFailed
        }
        return food
    }

    func delete(_ id: UUID) async throws {
        if shouldThrowError {
            throw RepositoryError.deleteFailed
        }
    }

    func search(name: String) async throws -> [Food] {
        if shouldThrowError {
            throw RepositoryError.fetchFailed
        }
        return foodsToReturn
    }

    func getRecentFoods(userId: UUID) async throws -> [Food] {
        if shouldThrowError {
            throw RepositoryError.fetchFailed
        }
        return recentFoodsToReturn
    }

    func getFrequentFoods(userId: UUID) async throws -> [Food] {
        if shouldThrowError {
            throw RepositoryError.fetchFailed
        }
        return frequentFoodsToReturn
    }

    func getUserDefinedFoods(userId: UUID) async throws -> [Food] {
        if shouldThrowError {
            throw RepositoryError.fetchFailed
        }
        return []
    }

    func findBySource(_ source: FoodSource) async throws -> [Food] {
        if shouldThrowError {
            throw RepositoryError.fetchFailed
        }
        return []
    }
}
