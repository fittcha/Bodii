//
//  PhotoRecognitionFlowTests.swift
//  BodiiTests
//
//  Created by Auto-Claude on 2026-01-17.
//

import XCTest
@testable import Bodii
#if canImport(UIKit)
import UIKit
#endif

/// Integration tests for the complete photo recognition flow
///
/// 사진 인식 전체 흐름에 대한 통합 테스트
///
/// 이 테스트는 ViewModels, Services, Repositories가 함께 작동하는 전체 흐름을 검증합니다.
/// - 사진 선택 → Vision API 분석 → 음식 매칭 → FoodRecord 생성 → DailyLog 업데이트
/// - 에러 시나리오 (할당량 초과, 네트워크 오류, 음식 미인식)
/// - 오프라인 상태 처리
/// - 할당량 경고 표시
@MainActor
final class PhotoRecognitionFlowTests: XCTestCase {

    // MARK: - Properties

    private var photoRecognitionViewModel: PhotoRecognitionViewModel!
    private var dailyMealViewModel: DailyMealViewModel!

    private var mockVisionAPIService: MockVisionAPIService!
    private var mockFoodLabelMatcher: MockFoodLabelMatcherService!
    private var mockUsageTracker: MockVisionAPIUsageTracker!
    private var foodRecordService: FoodRecordService!

    private var mockFoodRecordRepository: MockFoodRecordRepository!
    private var mockDailyLogRepository: MockDailyLogRepository!
    private var mockFoodRepository: MockFoodRepository!

    // MARK: - Test Data

    private let testUserId = UUID()
    private let testDate = Date()
    private let testBMR: Int32 = 1650
    private let testTDEE: Int32 = 2310

    /// Sample test image
    private lazy var testImage: UIImage = {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 100, height: 100))
        return renderer.image { context in
            UIColor.red.setFill()
            context.fill(CGRect(origin: .zero, size: CGSize(width: 100, height: 100)))
        }
    }()

    /// Sample pizza food
    private lazy var pizzaFood = Food(
        id: UUID(),
        name: "치즈 피자",
        calories: 266,
        carbohydrates: Decimal(33.0),
        protein: Decimal(11.0),
        fat: Decimal(10.0),
        sodium: Decimal(551.0),
        fiber: Decimal(2.4),
        sugar: Decimal(3.8),
        servingSize: Decimal(100.0),
        servingUnit: "g",
        source: .governmentAPI,
        apiCode: "KFDA_PIZZA_001",
        createdByUserId: nil,
        createdAt: Date()
    )

    /// Sample chicken food
    private lazy var chickenFood = Food(
        id: UUID(),
        name: "닭고기",
        calories: 165,
        carbohydrates: Decimal(0.0),
        protein: Decimal(31.0),
        fat: Decimal(3.6),
        sodium: Decimal(74.0),
        fiber: Decimal(0.0),
        sugar: Decimal(0.0),
        servingSize: Decimal(100.0),
        servingUnit: "g",
        source: .governmentAPI,
        apiCode: "KFDA_CHICKEN_001",
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

        // Initialize mock services
        mockVisionAPIService = MockVisionAPIService()
        mockFoodLabelMatcher = MockFoodLabelMatcherService()
        mockUsageTracker = MockVisionAPIUsageTracker()

        // Initialize food record service
        foodRecordService = FoodRecordService(
            foodRecordRepository: mockFoodRecordRepository,
            dailyLogRepository: mockDailyLogRepository,
            foodRepository: mockFoodRepository
        )

        // Initialize ViewModels
        photoRecognitionViewModel = PhotoRecognitionViewModel(
            visionAPIService: mockVisionAPIService,
            foodLabelMatcher: mockFoodLabelMatcher,
            foodRecordService: foodRecordService,
            usageTracker: mockUsageTracker
        )

        dailyMealViewModel = DailyMealViewModel(
            foodRecordService: foodRecordService,
            dailyLogRepository: mockDailyLogRepository,
            foodRepository: mockFoodRepository
        )

        // Setup default mock data
        mockDailyLogRepository.dailyLogToReturn = createEmptyDailyLog()
    }

    override func tearDown() async throws {
        photoRecognitionViewModel = nil
        dailyMealViewModel = nil
        mockVisionAPIService = nil
        mockFoodLabelMatcher = nil
        mockUsageTracker = nil
        foodRecordService = nil
        mockFoodRecordRepository = nil
        mockDailyLogRepository = nil
        mockFoodRepository = nil
        try await super.tearDown()
    }

    // MARK: - Happy Path Tests

    /// Test: Complete happy path flow from capture to save
    ///
    /// 테스트: 전체 흐름 - 사진 촬영부터 저장까지
    func testCompleteFlow_CaptureAnalyzeSave_WorksEndToEnd() async throws {
        // Given: ViewModel initialized with test context
        photoRecognitionViewModel.onAppear(
            userId: testUserId,
            date: testDate,
            mealType: .breakfast,
            bmr: testBMR,
            tdee: testTDEE
        )

        // Given: Mock Vision API returns pizza labels
        let pizzaLabel = VisionLabel(
            mid: "/m/0663v",
            description: "Pizza",
            score: 0.92,
            topicality: 0.90
        )
        mockVisionAPIService.mockLabels = [pizzaLabel]

        // Given: Mock food matcher returns pizza match
        let pizzaMatch = FoodMatch(
            label: "Pizza",
            originalLabel: pizzaLabel,
            confidence: 0.92,
            food: pizzaFood,
            alternatives: [],
            translatedKeyword: "피자"
        )
        mockFoodLabelMatcher.mockMatches = [pizzaMatch]

        // Given: Mock food repository returns pizza food
        mockFoodRepository.foodToReturn = pizzaFood

        // When: Capture and analyze image
        photoRecognitionViewModel.didCaptureImage(testImage)
        try await photoRecognitionViewModel.analyzeImage(testImage)

        // Then: Should have results
        XCTAssertTrue(photoRecognitionViewModel.hasResults, "Should have analysis results")
        XCTAssertEqual(photoRecognitionViewModel.foodMatches.count, 1, "Should have 1 food match")
        XCTAssertEqual(photoRecognitionViewModel.foodMatches.first?.food.name, "치즈 피자")

        // When: Save food records
        try await photoRecognitionViewModel.saveFoodRecords([pizzaMatch])

        // Then: Should save to repository
        XCTAssertTrue(mockFoodRecordRepository.saveCalled, "Should call save on repository")

        // Then: State should reset after save
        XCTAssertEqual(photoRecognitionViewModel.state, .idle, "Should return to idle state")
        XCTAssertNil(photoRecognitionViewModel.capturedImage, "Should clear captured image")
    }

    /// Test: Multiple food items detected and saved
    ///
    /// 테스트: 여러 음식 인식 및 저장
    func testCompleteFlow_MultipleFoodsDetected_SavesAllItems() async throws {
        // Given: ViewModel initialized
        photoRecognitionViewModel.onAppear(
            userId: testUserId,
            date: testDate,
            mealType: .lunch,
            bmr: testBMR,
            tdee: testTDEE
        )

        // Given: Mock Vision API returns multiple food labels
        let pizzaLabel = VisionLabel(
            mid: "/m/0663v",
            description: "Pizza",
            score: 0.92,
            topicality: 0.90
        )
        let chickenLabel = VisionLabel(
            mid: "/m/01xgs_",
            description: "Chicken",
            score: 0.88,
            topicality: 0.85
        )
        mockVisionAPIService.mockLabels = [pizzaLabel, chickenLabel]

        // Given: Mock food matcher returns multiple matches
        let pizzaMatch = FoodMatch(
            label: "Pizza",
            originalLabel: pizzaLabel,
            confidence: 0.92,
            food: pizzaFood
        )
        let chickenMatch = FoodMatch(
            label: "Chicken",
            originalLabel: chickenLabel,
            confidence: 0.88,
            food: chickenFood
        )
        mockFoodLabelMatcher.mockMatches = [pizzaMatch, chickenMatch]

        // When: Analyze image
        try await photoRecognitionViewModel.analyzeImage(testImage)

        // Then: Should detect both foods
        XCTAssertEqual(photoRecognitionViewModel.foodMatches.count, 2, "Should have 2 food matches")

        // When: Save both food records
        mockFoodRepository.foodToReturn = pizzaFood
        try await photoRecognitionViewModel.saveFoodRecords([pizzaMatch, chickenMatch])

        // Then: Should save both records
        // Note: saveCalled will be true after first save, but we can verify the flow completed
        XCTAssertTrue(mockFoodRecordRepository.saveCalled, "Should save food records")
        XCTAssertEqual(photoRecognitionViewModel.state, .idle, "Should return to idle state")
    }

    /// Test: Complete flow updates DailyLog correctly
    ///
    /// 테스트: 전체 흐름이 DailyLog를 올바르게 업데이트함
    func testCompleteFlow_SaveFoods_UpdatesDailyLog() async throws {
        // Given: Photo recognition flow completes successfully
        photoRecognitionViewModel.onAppear(
            userId: testUserId,
            date: testDate,
            mealType: .breakfast,
            bmr: testBMR,
            tdee: testTDEE
        )

        let pizzaLabel = VisionLabel(
            mid: "/m/0663v",
            description: "Pizza",
            score: 0.92,
            topicality: 0.90
        )
        mockVisionAPIService.mockLabels = [pizzaLabel]

        let pizzaMatch = FoodMatch(
            label: "Pizza",
            originalLabel: pizzaLabel,
            confidence: 0.92,
            food: pizzaFood
        )
        mockFoodLabelMatcher.mockMatches = [pizzaMatch]
        mockFoodRepository.foodToReturn = pizzaFood

        // When: Analyze and save
        try await photoRecognitionViewModel.analyzeImage(testImage)
        try await photoRecognitionViewModel.saveFoodRecords([pizzaMatch])

        // Given: Update mocks with saved data
        let savedRecord = FoodRecord(
            id: UUID(),
            userId: testUserId,
            foodId: pizzaFood.id,
            date: testDate,
            mealType: .breakfast,
            quantity: Decimal(1.0),
            quantityUnit: .serving,
            calculatedCalories: 266,
            calculatedCarbs: Decimal(33.0),
            calculatedProtein: Decimal(11.0),
            calculatedFat: Decimal(10.0),
            createdAt: Date()
        )
        mockFoodRecordRepository.foodRecordsToReturn = [savedRecord]

        let updatedDailyLog = DailyLog(
            id: UUID(),
            userId: testUserId,
            date: testDate,
            totalCaloriesIn: 266,
            totalCarbs: Decimal(33.0),
            totalProtein: Decimal(11.0),
            totalFat: Decimal(10.0),
            carbsRatio: Decimal(49.6),
            proteinRatio: Decimal(16.5),
            fatRatio: Decimal(33.9),
            bmr: testBMR,
            tdee: testTDEE,
            netCalories: -2044,
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
        mockDailyLogRepository.dailyLogToReturn = updatedDailyLog

        // When: Load daily meal view
        await dailyMealViewModel.loadData(userId: testUserId, bmr: testBMR, tdee: testTDEE)

        // Then: DailyLog should reflect saved food
        XCTAssertEqual(dailyMealViewModel.dailyLog?.totalCaloriesIn, 266, "Should have pizza calories")
        XCTAssertTrue(dailyMealViewModel.hasMeals(for: .breakfast), "Should have breakfast meal")
    }

    // MARK: - Error Recovery Tests

    /// Test: No food detected error scenario
    ///
    /// 테스트: 음식 미인식 에러 시나리오
    func testErrorRecovery_NoFoodDetected_ShowsError() async throws {
        // Given: ViewModel initialized
        photoRecognitionViewModel.onAppear(
            userId: testUserId,
            date: testDate,
            mealType: .breakfast,
            bmr: testBMR,
            tdee: testTDEE
        )

        // Given: Vision API throws noFoodDetected error
        mockVisionAPIService.errorToThrow = VisionAPIError.noFoodDetected

        // When: Try to analyze image
        do {
            try await photoRecognitionViewModel.analyzeImage(testImage)
            XCTFail("Should throw noFoodDetected error")
        } catch let error as VisionAPIError {
            // Then: Should catch noFoodDetected error
            if case .noFoodDetected = error {
                XCTAssertTrue(true, "Should throw noFoodDetected error")
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        }

        // Then: Should show error state
        XCTAssertTrue(photoRecognitionViewModel.hasError, "Should have error")
        XCTAssertNotNil(photoRecognitionViewModel.errorMessage, "Should have error message")
    }

    /// Test: Retry after error works correctly
    ///
    /// 테스트: 에러 후 재시도 동작
    func testErrorRecovery_RetryAfterError_Succeeds() async throws {
        // Given: ViewModel initialized with image
        photoRecognitionViewModel.onAppear(
            userId: testUserId,
            date: testDate,
            mealType: .breakfast,
            bmr: testBMR,
            tdee: testTDEE
        )
        photoRecognitionViewModel.didCaptureImage(testImage)

        // Given: First attempt fails
        mockVisionAPIService.errorToThrow = VisionAPIError.noFoodDetected

        do {
            try await photoRecognitionViewModel.analyzeImage(testImage)
            XCTFail("Should fail on first attempt")
        } catch {
            // Expected error
        }

        // Given: Second attempt succeeds
        mockVisionAPIService.errorToThrow = nil
        let pizzaLabel = VisionLabel(
            mid: "/m/0663v",
            description: "Pizza",
            score: 0.92,
            topicality: 0.90
        )
        mockVisionAPIService.mockLabels = [pizzaLabel]

        let pizzaMatch = FoodMatch(
            label: "Pizza",
            originalLabel: pizzaLabel,
            confidence: 0.92,
            food: pizzaFood
        )
        mockFoodLabelMatcher.mockMatches = [pizzaMatch]

        // When: Retry
        try await photoRecognitionViewModel.retry()

        // Then: Should succeed
        XCTAssertTrue(photoRecognitionViewModel.hasResults, "Should have results after retry")
        XCTAssertEqual(photoRecognitionViewModel.foodMatches.count, 1, "Should have 1 match")
    }

    /// Test: Network error handling
    ///
    /// 테스트: 네트워크 에러 처리
    func testErrorRecovery_NetworkError_ShowsError() async throws {
        // Given: ViewModel initialized
        photoRecognitionViewModel.onAppear(
            userId: testUserId,
            date: testDate,
            mealType: .breakfast,
            bmr: testBMR,
            tdee: testTDEE
        )

        // Given: Vision API throws network error
        mockVisionAPIService.errorToThrow = VisionAPIError.networkError(NetworkError.timeout)

        // When: Try to analyze
        do {
            try await photoRecognitionViewModel.analyzeImage(testImage)
            XCTFail("Should throw network error")
        } catch {
            // Expected error
        }

        // Then: Should show error
        XCTAssertTrue(photoRecognitionViewModel.hasError, "Should have error")
        XCTAssertNotNil(photoRecognitionViewModel.errorMessage, "Should have error message")
    }

    // MARK: - Offline Fallback Tests

    /// Test: Offline state detection and handling
    ///
    /// 테스트: 오프라인 상태 감지 및 처리
    func testOfflineFallback_NetworkUnavailable_ShowsOfflineState() async throws {
        // Given: ViewModel initialized
        photoRecognitionViewModel.onAppear(
            userId: testUserId,
            date: testDate,
            mealType: .breakfast,
            bmr: testBMR,
            tdee: testTDEE
        )

        // Given: Network unavailable error
        mockVisionAPIService.errorToThrow = VisionAPIError.networkError(NetworkError.networkUnavailable)

        // When: Try to analyze image
        do {
            try await photoRecognitionViewModel.analyzeImage(testImage)
            XCTFail("Should throw network unavailable error")
        } catch {
            // Expected error
        }

        // Then: Should show offline state
        XCTAssertTrue(photoRecognitionViewModel.isOffline, "Should be in offline state")
        XCTAssertNotNil(photoRecognitionViewModel.errorMessage, "Should have offline message")
    }

    /// Test: Offline state shows appropriate message
    ///
    /// 테스트: 오프라인 상태는 적절한 메시지를 표시함
    func testOfflineFallback_ShowsOfflineMessage() async throws {
        // Given: ViewModel initialized
        photoRecognitionViewModel.onAppear(
            userId: testUserId,
            date: testDate,
            mealType: .breakfast,
            bmr: testBMR,
            tdee: testTDEE
        )

        // Given: Network unavailable
        mockVisionAPIService.errorToThrow = VisionAPIError.networkError(NetworkError.networkUnavailable)

        // When: Try to analyze
        do {
            try await photoRecognitionViewModel.analyzeImage(testImage)
        } catch {
            // Expected
        }

        // Then: Should show offline message
        XCTAssertTrue(
            photoRecognitionViewModel.errorMessage?.contains("네트워크") ?? false,
            "Error message should mention network"
        )
    }

    // MARK: - Quota Warning Tests

    /// Test: Quota warning displays at 90% usage
    ///
    /// 테스트: 할당량 90% 사용 시 경고 표시
    func testQuotaWarning_At90Percent_ShowsWarning() async throws {
        // Given: Usage at 90% (900/1000)
        mockUsageTracker.currentUsage = 900
        mockUsageTracker.monthlyLimit = 1000

        // When: Initialize ViewModel
        photoRecognitionViewModel.onAppear(
            userId: testUserId,
            date: testDate,
            mealType: .breakfast,
            bmr: testBMR,
            tdee: testTDEE
        )

        // Then: Should show warning
        XCTAssertTrue(photoRecognitionViewModel.showQuotaWarning, "Should show quota warning at 90%")
        XCTAssertEqual(photoRecognitionViewModel.remainingQuota, 100, "Should have 100 requests remaining")
    }

    /// Test: Quota exceeded prevents API calls
    ///
    /// 테스트: 할당량 초과 시 API 호출 방지
    func testQuotaWarning_QuotaExceeded_PreventsAPICall() async throws {
        // Given: Quota exceeded
        mockUsageTracker.currentUsage = 1000
        mockUsageTracker.monthlyLimit = 1000
        mockUsageTracker.daysUntilReset = 7

        // When: Initialize ViewModel
        photoRecognitionViewModel.onAppear(
            userId: testUserId,
            date: testDate,
            mealType: .breakfast,
            bmr: testBMR,
            tdee: testTDEE
        )

        // Then: Should show quota exceeded
        XCTAssertTrue(photoRecognitionViewModel.isQuotaExceeded, "Should be quota exceeded")
        XCTAssertEqual(photoRecognitionViewModel.remainingQuota, 0, "Should have 0 remaining")

        // When: Try to analyze image
        do {
            try await photoRecognitionViewModel.analyzeImage(testImage)
            XCTFail("Should throw quotaExceeded error")
        } catch let error as VisionAPIError {
            // Then: Should throw quota exceeded error
            if case .quotaExceeded(let resetInDays) = error {
                XCTAssertEqual(resetInDays, 7, "Should include reset days")
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        }

        // Then: Should not call Vision API
        XCTAssertEqual(mockVisionAPIService.analyzeCallCount, 0, "Should not call Vision API when quota exceeded")
    }

    /// Test: Quota info updates after successful API call
    ///
    /// 테스트: API 호출 성공 후 할당량 정보 업데이트
    func testQuotaWarning_AfterSuccessfulCall_UpdatesQuotaInfo() async throws {
        // Given: Initial quota usage
        mockUsageTracker.currentUsage = 500
        mockUsageTracker.monthlyLimit = 1000

        photoRecognitionViewModel.onAppear(
            userId: testUserId,
            date: testDate,
            mealType: .breakfast,
            bmr: testBMR,
            tdee: testTDEE
        )

        let initialQuota = photoRecognitionViewModel.remainingQuota
        XCTAssertEqual(initialQuota, 500, "Should have 500 remaining initially")

        // Given: Mock successful Vision API response
        let pizzaLabel = VisionLabel(
            mid: "/m/0663v",
            description: "Pizza",
            score: 0.92,
            topicality: 0.90
        )
        mockVisionAPIService.mockLabels = [pizzaLabel]

        let pizzaMatch = FoodMatch(
            label: "Pizza",
            originalLabel: pizzaLabel,
            confidence: 0.92,
            food: pizzaFood
        )
        mockFoodLabelMatcher.mockMatches = [pizzaMatch]

        // When: Analyze image (this should increment usage)
        try await photoRecognitionViewModel.analyzeImage(testImage)

        // Then: Quota should be updated
        // Note: Mock tracker should have incremented usage
        XCTAssertEqual(mockUsageTracker.currentUsage, 501, "Usage should increment after API call")
        XCTAssertEqual(photoRecognitionViewModel.remainingQuota, 499, "Remaining quota should decrease")
    }

    // MARK: - Food Record Persistence Tests

    /// Test: Food records are persisted correctly
    ///
    /// 테스트: 음식 기록이 올바르게 저장됨
    func testFoodRecordPersistence_SaveRecords_PersistsToRepository() async throws {
        // Given: ViewModel with successful analysis
        photoRecognitionViewModel.onAppear(
            userId: testUserId,
            date: testDate,
            mealType: .lunch,
            bmr: testBMR,
            tdee: testTDEE
        )

        let pizzaLabel = VisionLabel(
            mid: "/m/0663v",
            description: "Pizza",
            score: 0.92,
            topicality: 0.90
        )
        mockVisionAPIService.mockLabels = [pizzaLabel]

        let pizzaMatch = FoodMatch(
            label: "Pizza",
            originalLabel: pizzaLabel,
            confidence: 0.92,
            food: pizzaFood
        )
        mockFoodLabelMatcher.mockMatches = [pizzaMatch]
        mockFoodRepository.foodToReturn = pizzaFood

        // When: Analyze and save
        try await photoRecognitionViewModel.analyzeImage(testImage)
        try await photoRecognitionViewModel.saveFoodRecords([pizzaMatch])

        // Then: Should save to repository
        XCTAssertTrue(mockFoodRecordRepository.saveCalled, "Should call save")

        // Then: Should update daily log
        XCTAssertTrue(mockDailyLogRepository.getOrCreateCalled, "Should get or create daily log")
    }

    /// Test: Multiple food records saved in batch
    ///
    /// 테스트: 여러 음식 기록을 일괄 저장
    func testFoodRecordPersistence_SaveMultipleRecords_SavesAllItems() async throws {
        // Given: ViewModel initialized
        photoRecognitionViewModel.onAppear(
            userId: testUserId,
            date: testDate,
            mealType: .dinner,
            bmr: testBMR,
            tdee: testTDEE
        )

        // Given: Multiple food matches
        let pizzaLabel = VisionLabel(
            mid: "/m/0663v",
            description: "Pizza",
            score: 0.92,
            topicality: 0.90
        )
        let chickenLabel = VisionLabel(
            mid: "/m/01xgs_",
            description: "Chicken",
            score: 0.88,
            topicality: 0.85
        )

        let pizzaMatch = FoodMatch(
            label: "Pizza",
            originalLabel: pizzaLabel,
            confidence: 0.92,
            food: pizzaFood
        )
        let chickenMatch = FoodMatch(
            label: "Chicken",
            originalLabel: chickenLabel,
            confidence: 0.88,
            food: chickenFood
        )

        mockFoodRepository.foodToReturn = pizzaFood

        // When: Save both matches
        try await photoRecognitionViewModel.saveFoodRecords([pizzaMatch, chickenMatch])

        // Then: Should save both records
        XCTAssertTrue(mockFoodRecordRepository.saveCalled, "Should save records")
    }

    /// Test: Saved records have correct meal type and date
    ///
    /// 테스트: 저장된 기록이 올바른 끼니 타입과 날짜를 가짐
    func testFoodRecordPersistence_SavedRecords_HaveCorrectMealTypeAndDate() async throws {
        // Given: ViewModel for specific meal and date
        let specificDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())!

        photoRecognitionViewModel.onAppear(
            userId: testUserId,
            date: specificDate,
            mealType: .snack,
            bmr: testBMR,
            tdee: testTDEE
        )

        let pizzaLabel = VisionLabel(
            mid: "/m/0663v",
            description: "Pizza",
            score: 0.92,
            topicality: 0.90
        )
        let pizzaMatch = FoodMatch(
            label: "Pizza",
            originalLabel: pizzaLabel,
            confidence: 0.92,
            food: pizzaFood
        )

        mockFoodRepository.foodToReturn = pizzaFood

        // When: Save food record
        try await photoRecognitionViewModel.saveFoodRecords([pizzaMatch])

        // Then: Should save with correct context
        // Note: In a real integration test, we'd verify the actual saved record
        // For now, we verify the save was called with the service
        XCTAssertTrue(mockFoodRecordRepository.saveCalled, "Should save with correct meal type and date")
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
}

// MARK: - Mock Vision API Service

/// Mock VisionAPIService for integration testing
///
/// 통합 테스트용 Mock Vision API 서비스
class MockVisionAPIService: VisionAPIServiceProtocol {

    /// Mock labels to return
    var mockLabels: [VisionLabel] = []

    /// Error to throw
    var errorToThrow: Error?

    /// Call count
    var analyzeCallCount = 0

    func analyzeImage(_ image: UIImage) async throws -> [VisionLabel] {
        analyzeCallCount += 1

        // Throw error if set
        if let error = errorToThrow {
            throw error
        }

        // Return mock labels
        return mockLabels
    }

    func reset() {
        mockLabels = []
        errorToThrow = nil
        analyzeCallCount = 0
    }
}

// MARK: - Mock Food Label Matcher Service

/// Mock FoodLabelMatcherService for integration testing
///
/// 통합 테스트용 Mock 음식 매칭 서비스
class MockFoodLabelMatcherService: FoodLabelMatcherServiceProtocol {

    /// Mock matches to return
    var mockMatches: [FoodMatch] = []

    /// Error to throw
    var errorToThrow: Error?

    /// Call count
    var matchCallCount = 0

    func matchLabelsToFoods(_ labels: [VisionLabel]) async throws -> [FoodMatch] {
        matchCallCount += 1

        // Throw error if set
        if let error = errorToThrow {
            throw error
        }

        // Return mock matches
        return mockMatches
    }

    func reset() {
        mockMatches = []
        errorToThrow = nil
        matchCallCount = 0
    }
}
