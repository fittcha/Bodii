//
//  FoodRecordServiceTests.swift
//  BodiiTests
//
//  Created by Auto-Claude on 2026-01-13.
//

import XCTest
@testable import Bodii

/// Unit tests for FoodRecordService business logic
///
/// FoodRecordService 비즈니스 로직에 대한 단위 테스트
final class FoodRecordServiceTests: XCTestCase {

    // MARK: - Properties

    private var service: FoodRecordService!
    private var mockFoodRecordRepository: MockFoodRecordRepository!
    private var mockDailyLogRepository: MockDailyLogRepository!
    private var mockFoodRepository: MockFoodRepository!

    // MARK: - Test Data

    private let testUserId = UUID()
    private let testFoodId = UUID()
    private let testDate = Date()

    /// Sample food for testing (현미밥 - Brown Rice)
    private lazy var sampleFood = Food(
        id: testFoodId,
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

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()
        mockFoodRecordRepository = MockFoodRecordRepository()
        mockDailyLogRepository = MockDailyLogRepository()
        mockFoodRepository = MockFoodRepository()

        service = FoodRecordService(
            foodRecordRepository: mockFoodRecordRepository,
            dailyLogRepository: mockDailyLogRepository,
            foodRepository: mockFoodRepository
        )
    }

    override func tearDown() {
        service = nil
        mockFoodRecordRepository = nil
        mockDailyLogRepository = nil
        mockFoodRepository = nil
        super.tearDown()
    }

    // MARK: - Add Food Record Tests

    /// Test: Add food record with 1 serving
    ///
    /// 테스트: 1인분 식단 기록 추가
    func testAddFoodRecord_OneServing_CalculatesCorrectNutrition() async throws {
        // Given: Mock food repository returns sample food
        mockFoodRepository.foodToReturn = sampleFood

        // Given: Mock daily log repository returns empty daily log
        let emptyDailyLog = createEmptyDailyLog()
        mockDailyLogRepository.dailyLogToReturn = emptyDailyLog

        // When: Adding 1 serving of food
        let result = try await service.addFoodRecord(
            userId: testUserId,
            foodId: testFoodId,
            date: testDate,
            mealType: .breakfast,
            quantity: Decimal(1.0),
            quantityUnit: .serving,
            bmr: 1650,
            tdee: 2310
        )

        // Then: Should calculate correct nutrition values
        XCTAssertEqual(result.calculatedCalories, 330, "1 serving should have 330 kcal")
        XCTAssertEqual(result.calculatedCarbs, Decimal(73.4), "1 serving should have 73.4g carbs")
        XCTAssertEqual(result.calculatedProtein, Decimal(6.8), "1 serving should have 6.8g protein")
        XCTAssertEqual(result.calculatedFat, Decimal(2.5), "1 serving should have 2.5g fat")

        // Then: Should save food record
        XCTAssertTrue(mockFoodRecordRepository.saveCalled, "Should save food record")
    }

    /// Test: Add food record updates DailyLog totals
    ///
    /// 테스트: 식단 기록 추가 시 DailyLog 총합 업데이트
    func testAddFoodRecord_UpdatesDailyLogTotals() async throws {
        // Given: Mock repositories
        mockFoodRepository.foodToReturn = sampleFood
        let emptyDailyLog = createEmptyDailyLog()
        mockDailyLogRepository.dailyLogToReturn = emptyDailyLog

        // When: Adding 1 serving of food
        _ = try await service.addFoodRecord(
            userId: testUserId,
            foodId: testFoodId,
            date: testDate,
            mealType: .breakfast,
            quantity: Decimal(1.0),
            quantityUnit: .serving,
            bmr: 1650,
            tdee: 2310
        )

        // Then: Should update daily log
        XCTAssertTrue(mockDailyLogRepository.updateCalled, "Should update daily log")
        let updatedLog = mockDailyLogRepository.lastUpdatedDailyLog!

        XCTAssertEqual(updatedLog.totalCaloriesIn, 330, "Should add calories to total")
        XCTAssertEqual(updatedLog.totalCarbs, Decimal(73.4), "Should add carbs to total")
        XCTAssertEqual(updatedLog.totalProtein, Decimal(6.8), "Should add protein to total")
        XCTAssertEqual(updatedLog.totalFat, Decimal(2.5), "Should add fat to total")
    }

    /// Test: Add food record calculates macro ratios
    ///
    /// 테스트: 식단 기록 추가 시 매크로 비율 계산
    func testAddFoodRecord_CalculatesMacroRatios() async throws {
        // Given: Mock repositories
        mockFoodRepository.foodToReturn = sampleFood
        let emptyDailyLog = createEmptyDailyLog()
        mockDailyLogRepository.dailyLogToReturn = emptyDailyLog

        // When: Adding 1 serving of food
        _ = try await service.addFoodRecord(
            userId: testUserId,
            foodId: testFoodId,
            date: testDate,
            mealType: .breakfast,
            quantity: Decimal(1.0),
            quantityUnit: .serving,
            bmr: 1650,
            tdee: 2310
        )

        // Then: Should calculate macro ratios
        let updatedLog = mockDailyLogRepository.lastUpdatedDailyLog!
        XCTAssertNotNil(updatedLog.carbsRatio, "Should have carbs ratio")
        XCTAssertNotNil(updatedLog.proteinRatio, "Should have protein ratio")
        XCTAssertNotNil(updatedLog.fatRatio, "Should have fat ratio")

        // 현미밥 (73.4g carbs, 6.8g protein, 2.5g fat)
        // Total calories from macros: (73.4*4) + (6.8*4) + (2.5*9) = 293.6 + 27.2 + 22.5 = 343.3 kcal
        // Note: This differs from food.calories (330) due to rounding in original data
        // Ratios: carbs ~85.5%, protein ~7.9%, fat ~6.6%
        XCTAssertTrue(updatedLog.carbsRatio! > Decimal(80), "Carbs should be > 80%")
    }

    /// Test: Add food record calculates net calories
    ///
    /// 테스트: 식단 기록 추가 시 순 칼로리 계산
    func testAddFoodRecord_CalculatesNetCalories() async throws {
        // Given: Mock repositories
        mockFoodRepository.foodToReturn = sampleFood
        let emptyDailyLog = createEmptyDailyLog()
        mockDailyLogRepository.dailyLogToReturn = emptyDailyLog

        // When: Adding 1 serving of food (330 kcal) with TDEE of 2310
        _ = try await service.addFoodRecord(
            userId: testUserId,
            foodId: testFoodId,
            date: testDate,
            mealType: .breakfast,
            quantity: Decimal(1.0),
            quantityUnit: .serving,
            bmr: 1650,
            tdee: 2310
        )

        // Then: Should calculate net calories (330 - 2310 = -1980)
        let updatedLog = mockDailyLogRepository.lastUpdatedDailyLog!
        XCTAssertEqual(updatedLog.netCalories, -1980, "Net calories should be totalCaloriesIn - TDEE")
    }

    /// Test: Add food record with grams unit
    ///
    /// 테스트: 그램 단위로 식단 기록 추가
    func testAddFoodRecord_WithGramsUnit_CalculatesCorrectNutrition() async throws {
        // Given: Mock repositories
        mockFoodRepository.foodToReturn = sampleFood
        let emptyDailyLog = createEmptyDailyLog()
        mockDailyLogRepository.dailyLogToReturn = emptyDailyLog

        // When: Adding 105g (0.5 servings)
        let result = try await service.addFoodRecord(
            userId: testUserId,
            foodId: testFoodId,
            date: testDate,
            mealType: .lunch,
            quantity: Decimal(105.0),
            quantityUnit: .grams,
            bmr: 1650,
            tdee: 2310
        )

        // Then: Should calculate for 0.5 servings
        XCTAssertEqual(result.calculatedCalories, 165, "105g should have 165 kcal")
        XCTAssertEqual(result.calculatedCarbs, Decimal(36.7), "105g should have 36.7g carbs")
        XCTAssertEqual(result.calculatedProtein, Decimal(3.4), "105g should have 3.4g protein")
        XCTAssertEqual(result.calculatedFat, Decimal(1.25), "105g should have 1.25g fat")
    }

    /// Test: Add food record throws error when food not found
    ///
    /// 테스트: 음식을 찾을 수 없을 때 에러 발생
    func testAddFoodRecord_FoodNotFound_ThrowsError() async throws {
        // Given: Mock food repository returns nil
        mockFoodRepository.foodToReturn = nil

        // When/Then: Should throw foodNotFound error
        do {
            _ = try await service.addFoodRecord(
                userId: testUserId,
                foodId: testFoodId,
                date: testDate,
                mealType: .breakfast,
                quantity: Decimal(1.0),
                quantityUnit: .serving,
                bmr: 1650,
                tdee: 2310
            )
            XCTFail("Should throw error when food not found")
        } catch let error as ServiceError {
            XCTAssertEqual(error, ServiceError.foodNotFound, "Should throw foodNotFound error")
        }
    }

    /// Test: Add food record creates DailyLog if not exists
    ///
    /// 테스트: DailyLog가 없으면 생성
    func testAddFoodRecord_CreatesDailyLogIfNotExists() async throws {
        // Given: Mock repositories
        mockFoodRepository.foodToReturn = sampleFood
        // DailyLog repository will create new one via getOrCreate
        let newDailyLog = createEmptyDailyLog()
        mockDailyLogRepository.dailyLogToReturn = newDailyLog

        // When: Adding food record
        _ = try await service.addFoodRecord(
            userId: testUserId,
            foodId: testFoodId,
            date: testDate,
            mealType: .breakfast,
            quantity: Decimal(1.0),
            quantityUnit: .serving,
            bmr: 1650,
            tdee: 2310
        )

        // Then: Should call getOrCreate on DailyLog repository
        XCTAssertTrue(mockDailyLogRepository.getOrCreateCalled, "Should call getOrCreate")
    }

    // MARK: - Update Food Record Tests

    /// Test: Update food record quantity
    ///
    /// 테스트: 식단 기록 수량 업데이트
    func testUpdateFoodRecord_UpdatesQuantityAndRecalculatesNutrition() async throws {
        // Given: Existing food record with 1 serving
        let existingRecord = FoodRecord(
            id: UUID(),
            userId: testUserId,
            foodId: testFoodId,
            date: testDate,
            mealType: .breakfast,
            quantity: Decimal(1.0),
            quantityUnit: .serving,
            calculatedCalories: 330,
            calculatedCarbs: Decimal(73.4),
            calculatedProtein: Decimal(6.8),
            calculatedFat: Decimal(2.5),
            createdAt: Date()
        )
        mockFoodRecordRepository.foodRecordToReturn = existingRecord

        // Given: Mock food and daily log
        mockFoodRepository.foodToReturn = sampleFood
        let dailyLog = createDailyLogWithFood()
        mockDailyLogRepository.dailyLogToReturn = dailyLog

        // When: Updating to 2 servings
        let result = try await service.updateFoodRecord(
            foodRecordId: existingRecord.id,
            quantity: Decimal(2.0),
            quantityUnit: .serving,
            mealType: nil
        )

        // Then: Should recalculate nutrition for 2 servings
        XCTAssertEqual(result.calculatedCalories, 660, "2 servings should have 660 kcal")
        XCTAssertEqual(result.calculatedCarbs, Decimal(146.8), "2 servings should have 146.8g carbs")
        XCTAssertEqual(result.calculatedProtein, Decimal(13.6), "2 servings should have 13.6g protein")
        XCTAssertEqual(result.calculatedFat, Decimal(5.0), "2 servings should have 5.0g fat")
    }

    /// Test: Update food record updates DailyLog correctly
    ///
    /// 테스트: 식단 기록 업데이트 시 DailyLog 올바르게 업데이트
    func testUpdateFoodRecord_UpdatesDailyLogCorrectly() async throws {
        // Given: Existing food record with 1 serving (330 kcal)
        let existingRecord = FoodRecord(
            id: UUID(),
            userId: testUserId,
            foodId: testFoodId,
            date: testDate,
            mealType: .breakfast,
            quantity: Decimal(1.0),
            quantityUnit: .serving,
            calculatedCalories: 330,
            calculatedCarbs: Decimal(73.4),
            calculatedProtein: Decimal(6.8),
            calculatedFat: Decimal(2.5),
            createdAt: Date()
        )
        mockFoodRecordRepository.foodRecordToReturn = existingRecord

        // Given: DailyLog with existing food (330 kcal)
        mockFoodRepository.foodToReturn = sampleFood
        let dailyLog = createDailyLogWithFood()
        mockDailyLogRepository.dailyLogToReturn = dailyLog

        // When: Updating to 0.5 servings (165 kcal)
        _ = try await service.updateFoodRecord(
            foodRecordId: existingRecord.id,
            quantity: Decimal(0.5),
            quantityUnit: .serving,
            mealType: nil
        )

        // Then: DailyLog should be updated (subtract old 330, add new 165 = net -165)
        let updatedLog = mockDailyLogRepository.lastUpdatedDailyLog!

        // Original: 330, subtract 330 = 0, add 165 = 165
        XCTAssertEqual(updatedLog.totalCaloriesIn, 165, "Should update total calories correctly")
    }

    /// Test: Update food record meal type
    ///
    /// 테스트: 식단 기록 끼니 타입 업데이트
    func testUpdateFoodRecord_UpdatesMealType() async throws {
        // Given: Existing breakfast record
        let existingRecord = FoodRecord(
            id: UUID(),
            userId: testUserId,
            foodId: testFoodId,
            date: testDate,
            mealType: .breakfast,
            quantity: Decimal(1.0),
            quantityUnit: .serving,
            calculatedCalories: 330,
            calculatedCarbs: Decimal(73.4),
            calculatedProtein: Decimal(6.8),
            calculatedFat: Decimal(2.5),
            createdAt: Date()
        )
        mockFoodRecordRepository.foodRecordToReturn = existingRecord

        mockFoodRepository.foodToReturn = sampleFood
        let dailyLog = createDailyLogWithFood()
        mockDailyLogRepository.dailyLogToReturn = dailyLog

        // When: Updating meal type to lunch
        let result = try await service.updateFoodRecord(
            foodRecordId: existingRecord.id,
            quantity: Decimal(1.0),
            quantityUnit: .serving,
            mealType: .lunch
        )

        // Then: Meal type should be updated
        XCTAssertEqual(result.mealType, .lunch, "Should update meal type")
    }

    /// Test: Update food record throws error when record not found
    ///
    /// 테스트: 식단 기록을 찾을 수 없을 때 에러 발생
    func testUpdateFoodRecord_RecordNotFound_ThrowsError() async throws {
        // Given: Mock repository returns nil
        mockFoodRecordRepository.foodRecordToReturn = nil

        // When/Then: Should throw foodRecordNotFound error
        do {
            _ = try await service.updateFoodRecord(
                foodRecordId: UUID(),
                quantity: Decimal(2.0),
                quantityUnit: .serving,
                mealType: nil
            )
            XCTFail("Should throw error when food record not found")
        } catch let error as ServiceError {
            XCTAssertEqual(error, ServiceError.foodRecordNotFound, "Should throw foodRecordNotFound error")
        }
    }

    // MARK: - Delete Food Record Tests

    /// Test: Delete food record
    ///
    /// 테스트: 식단 기록 삭제
    func testDeleteFoodRecord_DeletesRecordAndUpdatesDailyLog() async throws {
        // Given: Existing food record
        let existingRecord = FoodRecord(
            id: UUID(),
            userId: testUserId,
            foodId: testFoodId,
            date: testDate,
            mealType: .breakfast,
            quantity: Decimal(1.0),
            quantityUnit: .serving,
            calculatedCalories: 330,
            calculatedCarbs: Decimal(73.4),
            calculatedProtein: Decimal(6.8),
            calculatedFat: Decimal(2.5),
            createdAt: Date()
        )
        mockFoodRecordRepository.foodRecordToReturn = existingRecord

        // Given: DailyLog with the food
        let dailyLog = createDailyLogWithFood()
        mockDailyLogRepository.dailyLogToReturn = dailyLog

        // When: Deleting food record
        try await service.deleteFoodRecord(foodRecordId: existingRecord.id)

        // Then: Should delete the record
        XCTAssertTrue(mockFoodRecordRepository.deleteCalled, "Should delete food record")

        // Then: Should update daily log (subtract calories)
        let updatedLog = mockDailyLogRepository.lastUpdatedDailyLog!
        XCTAssertEqual(updatedLog.totalCaloriesIn, 0, "Should subtract calories from total")
        XCTAssertEqual(updatedLog.totalCarbs, Decimal(0), "Should subtract carbs from total")
        XCTAssertEqual(updatedLog.totalProtein, Decimal(0), "Should subtract protein from total")
        XCTAssertEqual(updatedLog.totalFat, Decimal(0), "Should subtract fat from total")
    }

    /// Test: Delete food record recalculates macro ratios
    ///
    /// 테스트: 식단 기록 삭제 시 매크로 비율 재계산
    func testDeleteFoodRecord_RecalculatesMacroRatios() async throws {
        // Given: Existing food record
        let existingRecord = FoodRecord(
            id: UUID(),
            userId: testUserId,
            foodId: testFoodId,
            date: testDate,
            mealType: .breakfast,
            quantity: Decimal(1.0),
            quantityUnit: .serving,
            calculatedCalories: 330,
            calculatedCarbs: Decimal(73.4),
            calculatedProtein: Decimal(6.8),
            calculatedFat: Decimal(2.5),
            createdAt: Date()
        )
        mockFoodRecordRepository.foodRecordToReturn = existingRecord

        // Given: DailyLog with the food
        let dailyLog = createDailyLogWithFood()
        mockDailyLogRepository.dailyLogToReturn = dailyLog

        // When: Deleting food record
        try await service.deleteFoodRecord(foodRecordId: existingRecord.id)

        // Then: Should recalculate macro ratios (should be nil when no food)
        let updatedLog = mockDailyLogRepository.lastUpdatedDailyLog!
        XCTAssertNil(updatedLog.carbsRatio, "Should have nil carbs ratio when no food")
        XCTAssertNil(updatedLog.proteinRatio, "Should have nil protein ratio when no food")
        XCTAssertNil(updatedLog.fatRatio, "Should have nil fat ratio when no food")
    }

    /// Test: Delete food record throws error when record not found
    ///
    /// 테스트: 식단 기록을 찾을 수 없을 때 에러 발생
    func testDeleteFoodRecord_RecordNotFound_ThrowsError() async throws {
        // Given: Mock repository returns nil
        mockFoodRecordRepository.foodRecordToReturn = nil

        // When/Then: Should throw foodRecordNotFound error
        do {
            try await service.deleteFoodRecord(foodRecordId: UUID())
            XCTFail("Should throw error when food record not found")
        } catch let error as ServiceError {
            XCTAssertEqual(error, ServiceError.foodRecordNotFound, "Should throw foodRecordNotFound error")
        }
    }

    /// Test: Delete food record throws error when daily log not found
    ///
    /// 테스트: DailyLog를 찾을 수 없을 때 에러 발생
    func testDeleteFoodRecord_DailyLogNotFound_ThrowsError() async throws {
        // Given: Food record exists but daily log doesn't
        let existingRecord = FoodRecord(
            id: UUID(),
            userId: testUserId,
            foodId: testFoodId,
            date: testDate,
            mealType: .breakfast,
            quantity: Decimal(1.0),
            quantityUnit: .serving,
            calculatedCalories: 330,
            calculatedCarbs: Decimal(73.4),
            calculatedProtein: Decimal(6.8),
            calculatedFat: Decimal(2.5),
            createdAt: Date()
        )
        mockFoodRecordRepository.foodRecordToReturn = existingRecord
        mockDailyLogRepository.dailyLogToReturn = nil

        // When/Then: Should throw dailyLogNotFound error
        do {
            try await service.deleteFoodRecord(foodRecordId: existingRecord.id)
            XCTFail("Should throw error when daily log not found")
        } catch let error as ServiceError {
            XCTAssertEqual(error, ServiceError.dailyLogNotFound, "Should throw dailyLogNotFound error")
        }
    }

    // MARK: - Query Operations Tests

    /// Test: Get food records for date
    ///
    /// 테스트: 날짜별 식단 기록 조회
    func testGetFoodRecords_ForDate_ReturnsRecords() async throws {
        // Given: Mock repository returns records
        let records = [
            FoodRecord(
                id: UUID(),
                userId: testUserId,
                foodId: testFoodId,
                date: testDate,
                mealType: .breakfast,
                quantity: Decimal(1.0),
                quantityUnit: .serving,
                calculatedCalories: 330,
                calculatedCarbs: Decimal(73.4),
                calculatedProtein: Decimal(6.8),
                calculatedFat: Decimal(2.5),
                createdAt: Date()
            )
        ]
        mockFoodRecordRepository.foodRecordsToReturn = records

        // When: Getting food records for date
        let result = try await service.getFoodRecords(for: testDate, userId: testUserId)

        // Then: Should return records
        XCTAssertEqual(result.count, 1, "Should return 1 record")
        XCTAssertTrue(mockFoodRecordRepository.findByDateCalled, "Should call findByDate")
    }

    /// Test: Get food records for date and meal type
    ///
    /// 테스트: 날짜와 끼니별 식단 기록 조회
    func testGetFoodRecords_ForDateAndMealType_ReturnsRecords() async throws {
        // Given: Mock repository returns records
        let records = [
            FoodRecord(
                id: UUID(),
                userId: testUserId,
                foodId: testFoodId,
                date: testDate,
                mealType: .breakfast,
                quantity: Decimal(1.0),
                quantityUnit: .serving,
                calculatedCalories: 330,
                calculatedCarbs: Decimal(73.4),
                calculatedProtein: Decimal(6.8),
                calculatedFat: Decimal(2.5),
                createdAt: Date()
            )
        ]
        mockFoodRecordRepository.foodRecordsToReturn = records

        // When: Getting food records for date and meal type
        let result = try await service.getFoodRecords(
            for: testDate,
            mealType: .breakfast,
            userId: testUserId
        )

        // Then: Should return records
        XCTAssertEqual(result.count, 1, "Should return 1 record")
        XCTAssertTrue(mockFoodRecordRepository.findByDateAndMealTypeCalled, "Should call findByDateAndMealType")
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
            bmr: 1650,
            tdee: 2310,
            netCalories: -2310,
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
    private func createDailyLogWithFood() -> DailyLog {
        return DailyLog(
            id: UUID(),
            userId: testUserId,
            date: testDate,
            totalCaloriesIn: 330,
            totalCarbs: Decimal(73.4),
            totalProtein: Decimal(6.8),
            totalFat: Decimal(2.5),
            carbsRatio: Decimal(85.5),
            proteinRatio: Decimal(7.9),
            fatRatio: Decimal(6.6),
            bmr: 1650,
            tdee: 2310,
            netCalories: -1980,
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

// MARK: - Mock Repositories

/// Mock FoodRecordRepository for testing
class MockFoodRecordRepository: FoodRecordRepositoryProtocol {
    var foodRecordToReturn: FoodRecord?
    var foodRecordsToReturn: [FoodRecord] = []
    var saveCalled = false
    var updateCalled = false
    var deleteCalled = false
    var findByIdCalled = false
    var findByDateCalled = false
    var findByDateAndMealTypeCalled = false

    func save(_ foodRecord: FoodRecord) async throws -> FoodRecord {
        saveCalled = true
        return foodRecord
    }

    func findById(_ id: UUID) async throws -> FoodRecord? {
        findByIdCalled = true
        return foodRecordToReturn
    }

    func update(_ foodRecord: FoodRecord) async throws -> FoodRecord {
        updateCalled = true
        return foodRecord
    }

    func delete(_ id: UUID) async throws {
        deleteCalled = true
    }

    func findByDate(_ date: Date, userId: UUID) async throws -> [FoodRecord] {
        findByDateCalled = true
        return foodRecordsToReturn
    }

    func findByDateAndMealType(_ date: Date, mealType: MealType, userId: UUID) async throws -> [FoodRecord] {
        findByDateAndMealTypeCalled = true
        return foodRecordsToReturn
    }
}

/// Mock DailyLogRepository for testing
class MockDailyLogRepository: DailyLogRepositoryProtocol {
    var dailyLogToReturn: DailyLog?
    var getOrCreateCalled = false
    var findByDateCalled = false
    var updateCalled = false
    var lastUpdatedDailyLog: DailyLog?

    func save(_ dailyLog: DailyLog) async throws -> DailyLog {
        return dailyLog
    }

    func findByDate(_ date: Date, userId: UUID) async throws -> DailyLog? {
        findByDateCalled = true
        return dailyLogToReturn
    }

    func update(_ dailyLog: DailyLog) async throws -> DailyLog {
        updateCalled = true
        lastUpdatedDailyLog = dailyLog
        return dailyLog
    }

    func delete(_ id: UUID) async throws {
    }

    func getOrCreate(for date: Date, userId: UUID, bmr: Int32, tdee: Int32) async throws -> DailyLog {
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
        return []
    }
}

/// Mock FoodRepository for testing
class MockFoodRepository: FoodRepositoryProtocol {
    var foodToReturn: Food?

    func save(_ food: Food) async throws -> Food {
        return food
    }

    func findById(_ id: UUID) async throws -> Food? {
        return foodToReturn
    }

    func findAll() async throws -> [Food] {
        return []
    }

    func update(_ food: Food) async throws -> Food {
        return food
    }

    func delete(_ id: UUID) async throws {
    }

    func search(by name: String) async throws -> [Food] {
        return []
    }

    func getRecentFoods(userId: UUID, days: Int, limit: Int) async throws -> [Food] {
        return []
    }

    func getFrequentFoods(userId: UUID, limit: Int) async throws -> [Food] {
        return []
    }

    func findBySource(_ source: FoodSource) async throws -> [Food] {
        return []
    }
}
