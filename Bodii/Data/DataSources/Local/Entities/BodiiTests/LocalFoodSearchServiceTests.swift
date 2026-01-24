//
//  LocalFoodSearchServiceTests.swift
//  BodiiTests
//
//  Created by Auto-Claude on 2026-01-13.
//

import XCTest
@testable import Bodii

/// Unit tests for LocalFoodSearchService
///
/// LocalFoodSearchService 비즈니스 로직에 대한 단위 테스트
final class LocalFoodSearchServiceTests: XCTestCase {

    // MARK: - Properties

    private var service: LocalFoodSearchService!
    private var mockFoodRepository: MockFoodRepository!

    // MARK: - Test Data

    private let testUserId = UUID()

    /// Sample Korean food (한국 음식 - 자주 사용)
    private lazy var koreanFrequentFood = Food(
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

    /// Sample Korean food (한국 음식 - 일반)
    private lazy var koreanRegularFood = Food(
        id: UUID(),
        name: "현미밥 영양밥",
        calories: 350,
        carbohydrates: Decimal(75.0),
        protein: Decimal(7.0),
        fat: Decimal(3.0),
        sodium: Decimal(10.0),
        fiber: Decimal(4.0),
        sugar: Decimal(1.0),
        servingSize: Decimal(210.0),
        servingUnit: "1공기",
        source: .governmentAPI,
        apiCode: "D000002",
        createdByUserId: nil,
        createdAt: Date()
    )

    /// Sample USDA food (외국 음식 - 자주 사용)
    private lazy var usdaFrequentFood = Food(
        id: UUID(),
        name: "Brown Rice",
        calories: 320,
        carbohydrates: Decimal(70.0),
        protein: Decimal(6.5),
        fat: Decimal(2.0),
        sodium: Decimal(0.0),
        fiber: Decimal(3.5),
        sugar: Decimal(0.0),
        servingSize: Decimal(200.0),
        servingUnit: "1 cup",
        source: .usda,
        apiCode: "U123456",
        createdByUserId: nil,
        createdAt: Date()
    )

    /// Sample user-defined food (사용자 정의 음식)
    private lazy var userDefinedFood = Food(
        id: UUID(),
        name: "내가 만든 현미밥",
        calories: 340,
        carbohydrates: Decimal(72.0),
        protein: Decimal(7.0),
        fat: Decimal(2.8),
        sodium: nil,
        fiber: nil,
        sugar: nil,
        servingSize: Decimal(210.0),
        servingUnit: "1그릇",
        source: .userDefined,
        apiCode: nil,
        createdByUserId: testUserId,
        createdAt: Date()
    )

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()
        mockFoodRepository = MockFoodRepository()
        service = LocalFoodSearchService(foodRepository: mockFoodRepository)
    }

    override func tearDown() {
        service = nil
        mockFoodRepository = nil
        super.tearDown()
    }

    // MARK: - Search Foods Tests

    /// Test: Search with empty query returns empty array
    ///
    /// 테스트: 빈 검색어는 빈 배열 반환
    func testSearchFoods_EmptyQuery_ReturnsEmptyArray() async throws {
        // Given: Empty search query
        let query = ""

        // When: Searching with empty query
        let results = try await service.searchFoods(query: query, userId: testUserId)

        // Then: Should return empty array
        XCTAssertTrue(results.isEmpty, "Empty query should return empty array")
    }

    /// Test: Search with whitespace-only query returns empty array
    ///
    /// 테스트: 공백만 있는 검색어는 빈 배열 반환
    func testSearchFoods_WhitespaceQuery_ReturnsEmptyArray() async throws {
        // Given: Whitespace-only search query
        let query = "   "

        // When: Searching with whitespace query
        let results = try await service.searchFoods(query: query, userId: testUserId)

        // Then: Should return empty array
        XCTAssertTrue(results.isEmpty, "Whitespace query should return empty array")
    }

    /// Test: Search with no results returns empty array
    ///
    /// 테스트: 검색 결과 없으면 빈 배열 반환
    func testSearchFoods_NoResults_ReturnsEmptyArray() async throws {
        // Given: Repository returns no results
        mockFoodRepository.searchResults = []
        mockFoodRepository.frequentFoods = []

        // When: Searching for food
        let results = try await service.searchFoods(query: "없는음식", userId: testUserId)

        // Then: Should return empty array
        XCTAssertTrue(results.isEmpty, "No search results should return empty array")
    }

    /// Test: Search prioritizes Korean frequent foods first
    ///
    /// 테스트: 한국 음식 중 자주 사용하는 음식이 1순위
    func testSearchFoods_PrioritizesKoreanFrequentFoods() async throws {
        // Given: Mixed search results
        mockFoodRepository.searchResults = [
            userDefinedFood,      // 4순위: 기타
            usdaFrequentFood,     // 3순위: 기타 + 자주 사용
            koreanRegularFood,    // 2순위: 한국 음식
            koreanFrequentFood    // 1순위: 한국 음식 + 자주 사용
        ]

        // Given: Frequent foods list
        mockFoodRepository.frequentFoods = [koreanFrequentFood, usdaFrequentFood]

        // When: Searching for food
        let results = try await service.searchFoods(query: "밥", userId: testUserId)

        // Then: Should be sorted by priority
        XCTAssertEqual(results.count, 4, "Should return all 4 results")
        XCTAssertEqual(results[0].id, koreanFrequentFood.id, "1st should be Korean frequent food")
        XCTAssertEqual(results[1].id, koreanRegularFood.id, "2nd should be Korean regular food")
        XCTAssertEqual(results[2].id, usdaFrequentFood.id, "3rd should be USDA frequent food")
        XCTAssertEqual(results[3].id, userDefinedFood.id, "4th should be user-defined food")
    }

    /// Test: Search sorts by name within same priority
    ///
    /// 테스트: 같은 우선순위 내에서는 이름순 정렬
    func testSearchFoods_SortsByNameWithinSamePriority() async throws {
        // Given: Multiple Korean foods with same priority
        let koreanFood1 = Food(
            id: UUID(),
            name: "흰쌀밥",
            calories: 300,
            carbohydrates: Decimal(70.0),
            protein: Decimal(5.0),
            fat: Decimal(1.0),
            sodium: nil,
            fiber: nil,
            sugar: nil,
            servingSize: Decimal(210.0),
            servingUnit: "1공기",
            source: .governmentAPI,
            apiCode: "D000003",
            createdByUserId: nil,
            createdAt: Date()
        )

        let koreanFood2 = Food(
            id: UUID(),
            name: "검은쌀밥",
            calories: 310,
            carbohydrates: Decimal(71.0),
            protein: Decimal(5.5),
            fat: Decimal(1.2),
            sodium: nil,
            fiber: nil,
            sugar: nil,
            servingSize: Decimal(210.0),
            servingUnit: "1공기",
            source: .governmentAPI,
            apiCode: "D000004",
            createdByUserId: nil,
            createdAt: Date()
        )

        mockFoodRepository.searchResults = [koreanFood1, koreanFood2]
        mockFoodRepository.frequentFoods = []

        // When: Searching for food
        let results = try await service.searchFoods(query: "쌀밥", userId: testUserId)

        // Then: Should be sorted alphabetically (Korean alphabetical order)
        XCTAssertEqual(results.count, 2)
        XCTAssertEqual(results[0].name, "검은쌀밥", "Should be sorted by Korean alphabetical order")
        XCTAssertEqual(results[1].name, "흰쌀밥", "Should be sorted by Korean alphabetical order")
    }

    /// Test: Search handles all food sources correctly
    ///
    /// 테스트: 모든 음식 출처를 올바르게 처리
    func testSearchFoods_HandlesAllFoodSources() async throws {
        // Given: Foods from all three sources
        mockFoodRepository.searchResults = [
            userDefinedFood,      // userDefined
            usdaFrequentFood,     // usda (frequent)
            koreanRegularFood     // governmentAPI
        ]
        mockFoodRepository.frequentFoods = [usdaFrequentFood]

        // When: Searching for food
        let results = try await service.searchFoods(query: "rice", userId: testUserId)

        // Then: Should handle all sources
        XCTAssertEqual(results.count, 3)
        XCTAssertTrue(results.contains(where: { $0.source == .governmentAPI }))
        XCTAssertTrue(results.contains(where: { $0.source == .usda }))
        XCTAssertTrue(results.contains(where: { $0.source == .userDefined }))
    }

    /// Test: Search returns nutrition preview in results
    ///
    /// 테스트: 검색 결과에 영양 정보가 포함됨
    func testSearchFoods_IncludesNutritionPreview() async throws {
        // Given: Search results with nutrition info
        mockFoodRepository.searchResults = [koreanFrequentFood]
        mockFoodRepository.frequentFoods = [koreanFrequentFood]

        // When: Searching for food
        let results = try await service.searchFoods(query: "현미밥", userId: testUserId)

        // Then: Should include nutrition information
        XCTAssertEqual(results.count, 1)
        let food = results[0]
        XCTAssertEqual(food.calories, 330, "Should include calories")
        XCTAssertEqual(food.carbohydrates, Decimal(73.4), "Should include carbs")
        XCTAssertEqual(food.protein, Decimal(6.8), "Should include protein")
        XCTAssertEqual(food.fat, Decimal(2.5), "Should include fat")
        XCTAssertEqual(food.servingSize, Decimal(210.0), "Should include serving size")
    }

    // MARK: - Get Recent Foods Tests

    /// Test: Get recent foods returns limited results
    ///
    /// 테스트: 최근 음식은 최대 10개로 제한
    func testGetRecentFoods_LimitsToTenResults() async throws {
        // Given: Repository returns more than 10 recent foods
        mockFoodRepository.recentFoods = Array(repeating: koreanFrequentFood, count: 15)

        // When: Getting recent foods
        let results = try await service.getRecentFoods(userId: testUserId)

        // Then: Should return only 10 results
        XCTAssertEqual(results.count, 10, "Should limit to 10 recent foods")
    }

    /// Test: Get recent foods returns all when less than 10
    ///
    /// 테스트: 최근 음식이 10개 미만이면 모두 반환
    func testGetRecentFoods_ReturnsAllWhenLessThanTen() async throws {
        // Given: Repository returns 5 recent foods
        mockFoodRepository.recentFoods = [
            koreanFrequentFood,
            koreanRegularFood,
            usdaFrequentFood,
            userDefinedFood,
            koreanFrequentFood
        ]

        // When: Getting recent foods
        let results = try await service.getRecentFoods(userId: testUserId)

        // Then: Should return all 5 results
        XCTAssertEqual(results.count, 5, "Should return all 5 recent foods")
    }

    /// Test: Get recent foods handles empty results
    ///
    /// 테스트: 최근 음식이 없으면 빈 배열 반환
    func testGetRecentFoods_HandlesEmptyResults() async throws {
        // Given: Repository returns no recent foods
        mockFoodRepository.recentFoods = []

        // When: Getting recent foods
        let results = try await service.getRecentFoods(userId: testUserId)

        // Then: Should return empty array
        XCTAssertTrue(results.isEmpty, "Should return empty array when no recent foods")
    }

    // MARK: - Get Frequent Foods Tests

    /// Test: Get frequent foods returns limited results
    ///
    /// 테스트: 자주 사용하는 음식은 최대 10개로 제한
    func testGetFrequentFoods_LimitsToTenResults() async throws {
        // Given: Repository returns more than 10 frequent foods
        mockFoodRepository.frequentFoods = Array(repeating: koreanFrequentFood, count: 20)

        // When: Getting frequent foods
        let results = try await service.getFrequentFoods(userId: testUserId)

        // Then: Should return only 10 results
        XCTAssertEqual(results.count, 10, "Should limit to 10 frequent foods")
    }

    /// Test: Get frequent foods returns all when less than 10
    ///
    /// 테스트: 자주 사용하는 음식이 10개 미만이면 모두 반환
    func testGetFrequentFoods_ReturnsAllWhenLessThanTen() async throws {
        // Given: Repository returns 3 frequent foods
        mockFoodRepository.frequentFoods = [
            koreanFrequentFood,
            usdaFrequentFood,
            koreanRegularFood
        ]

        // When: Getting frequent foods
        let results = try await service.getFrequentFoods(userId: testUserId)

        // Then: Should return all 3 results
        XCTAssertEqual(results.count, 3, "Should return all 3 frequent foods")
    }

    /// Test: Get frequent foods handles empty results
    ///
    /// 테스트: 자주 사용하는 음식이 없으면 빈 배열 반환
    func testGetFrequentFoods_HandlesEmptyResults() async throws {
        // Given: Repository returns no frequent foods
        mockFoodRepository.frequentFoods = []

        // When: Getting frequent foods
        let results = try await service.getFrequentFoods(userId: testUserId)

        // Then: Should return empty array
        XCTAssertTrue(results.isEmpty, "Should return empty array when no frequent foods")
    }
}

// MARK: - Mock Food Repository Extension

extension MockFoodRepository {
    /// Search results for testing
    var searchResults: [Food] {
        get { foodsToReturn }
        set { foodsToReturn = newValue }
    }

    /// Recent foods for testing
    var recentFoods: [Food] {
        get { recentFoodsToReturn }
        set { recentFoodsToReturn = newValue }
    }

    /// Frequent foods for testing
    var frequentFoods: [Food] {
        get { frequentFoodsToReturn }
        set { frequentFoodsToReturn = newValue }
    }
}
