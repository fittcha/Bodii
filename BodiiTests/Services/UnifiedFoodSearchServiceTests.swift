//
//  UnifiedFoodSearchServiceTests.swift
//  BodiiTests
//
//  Created by Auto-Claude on 2026-01-13.
//

import XCTest
import CoreData
@testable import Bodii

/// Unit tests for UnifiedFoodSearchService
///
/// UnifiedFoodSearchService의 검색 우선순위, 폴백, 에러 처리 단위 테스트
///
/// **테스트 범위:**
/// - Korean query prioritization (식약처 우선)
/// - USDA fallback when KFDA returns empty or insufficient results
/// - Concurrent search for English queries
/// - Deduplication logic
/// - Error handling and retry logic
/// - Edge cases and boundary conditions
final class UnifiedFoodSearchServiceTests: XCTestCase {

    // MARK: - Properties

    var service: UnifiedFoodSearchService!
    var mockKFDAService: MockKFDAFoodAPIService!
    var mockUSDAService: MockUSDAFoodAPIService!
    var testContext: NSManagedObjectContext!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()

        // Create in-memory Core Data context for testing
        let container = NSPersistentContainer(name: "Bodii")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Failed to load in-memory store: \(error)")
            }
        }
        testContext = container.viewContext

        // Initialize mock services
        mockKFDAService = MockKFDAFoodAPIService()
        mockUSDAService = MockUSDAFoodAPIService()

        // Initialize service with mocks and test context
        service = UnifiedFoodSearchService(
            context: testContext,
            kfdaService: mockKFDAService,
            usdaService: mockUSDAService
        )
    }

    override func tearDown() {
        service = nil
        mockKFDAService = nil
        mockUSDAService = nil
        testContext = nil
        super.tearDown()
    }

    // MARK: - Korean Query Tests (식약처 우선)

    /// Test: Korean query searches KFDA first and returns KFDA results if sufficient
    ///
    /// 테스트: 한글 검색어는 식약처 먼저 검색하고 결과가 충분하면 식약처 결과만 반환
    func testSearchFoods_KoreanQuery_SufficientKFDAResults_ReturnsOnlyKFDA() async throws {
        // Given: Korean query with sufficient KFDA results (≥5)
        let kfdaFoods = createSampleKFDAFoods(count: 10)
        mockKFDAService.mockSearchResponse = createKFDAResponse(foods: kfdaFoods)

        // USDA service should not be called
        mockUSDAService.mockSearchResponse = createUSDAResponse(foods: [])

        // When: Searching with Korean query
        let results = try await service.searchFoods(query: "김치찌개", limit: 20)

        // Then: Should return KFDA results only
        XCTAssertEqual(results.count, 10, "Should return 10 KFDA foods")
        XCTAssertEqual(mockKFDAService.searchFoodsCallCount, 1, "KFDA should be called once")
        XCTAssertEqual(mockUSDAService.searchFoodsCallCount, 0, "USDA should not be called")

        // Verify all results are from KFDA
        for food in results {
            XCTAssertEqual(food.source, FoodSource.governmentAPI.rawValue, "All foods should be from governmentAPI")
        }
    }

    /// Test: Korean query searches USDA as fallback when KFDA returns insufficient results
    ///
    /// 테스트: 한글 검색어에 식약처 결과가 부족하면 USDA도 검색하여 추가
    func testSearchFoods_KoreanQuery_InsufficientKFDAResults_FallsBackToUSDA() async throws {
        // Given: Korean query with insufficient KFDA results (<5)
        let kfdaFoods = createSampleKFDAFoods(count: 3)
        mockKFDAService.mockSearchResponse = createKFDAResponse(foods: kfdaFoods)

        let usdaFoods = createSampleUSDAFoods(count: 7)
        mockUSDAService.mockSearchResponse = createUSDAResponse(foods: usdaFoods)

        // When: Searching with Korean query
        let results = try await service.searchFoods(query: "김치", limit: 20)

        // Then: Should return both KFDA and USDA results
        XCTAssertEqual(results.count, 10, "Should return 3 KFDA + 7 USDA foods")
        XCTAssertEqual(mockKFDAService.searchFoodsCallCount, 1, "KFDA should be called once")
        XCTAssertEqual(mockUSDAService.searchFoodsCallCount, 1, "USDA should be called once")
    }

    /// Test: Korean query with no KFDA results falls back to USDA
    ///
    /// 테스트: 한글 검색어에 식약처 결과가 없으면 USDA 결과 반환
    func testSearchFoods_KoreanQuery_NoKFDAResults_ReturnsUSDAResults() async throws {
        // Given: Korean query with no KFDA results
        mockKFDAService.mockSearchResponse = createKFDAResponse(foods: [])

        let usdaFoods = createSampleUSDAFoods(count: 5)
        mockUSDAService.mockSearchResponse = createUSDAResponse(foods: usdaFoods)

        // When: Searching with Korean query
        let results = try await service.searchFoods(query: "한식", limit: 20)

        // Then: Should return USDA results
        XCTAssertEqual(results.count, 5, "Should return 5 USDA foods")
        XCTAssertEqual(mockKFDAService.searchFoodsCallCount, 1, "KFDA should be called once")
        XCTAssertEqual(mockUSDAService.searchFoodsCallCount, 1, "USDA should be called once")
    }

    /// Test: Korean query prioritizes KFDA results first in merged list
    ///
    /// 테스트: 한글 검색어는 식약처 결과를 먼저 배치
    func testSearchFoods_KoreanQuery_KFDAResultsAppearFirst() async throws {
        // Given: Korean query with both KFDA and USDA results
        let kfdaFoods = createSampleKFDAFoods(count: 2)
        mockKFDAService.mockSearchResponse = createKFDAResponse(foods: kfdaFoods)

        let usdaFoods = createSampleUSDAFoods(count: 3)
        mockUSDAService.mockSearchResponse = createUSDAResponse(foods: usdaFoods)

        // When: Searching with Korean query
        let results = try await service.searchFoods(query: "김치", limit: 20)

        // Then: KFDA results should appear first
        XCTAssertEqual(results.count, 5, "Should return 5 total foods")
        XCTAssertEqual(results[0].source, .governmentAPI, "First result should be KFDA")
        XCTAssertEqual(results[1].source, .governmentAPI, "Second result should be KFDA")
        XCTAssertEqual(results[2].source, .usda, "Third result should be USDA")
        XCTAssertEqual(results[3].source, .usda, "Fourth result should be USDA")
        XCTAssertEqual(results[4].source, .usda, "Fifth result should be USDA")
    }

    // MARK: - English Query Tests (병렬 검색)

    /// Test: English query searches both APIs concurrently
    ///
    /// 테스트: 영문 검색어는 양쪽 API를 병렬로 검색
    func testSearchFoods_EnglishQuery_SearchesBothAPIsConcurrently() async throws {
        // Given: English query with results from both APIs
        let kfdaFoods = createSampleKFDAFoods(count: 5)
        mockKFDAService.mockSearchResponse = createKFDAResponse(foods: kfdaFoods)

        let usdaFoods = createSampleUSDAFoods(count: 8)
        mockUSDAService.mockSearchResponse = createUSDAResponse(foods: usdaFoods)

        // When: Searching with English query
        let results = try await service.searchFoods(query: "chicken", limit: 20)

        // Then: Should return combined results
        XCTAssertEqual(results.count, 13, "Should return 5 KFDA + 8 USDA foods")
        XCTAssertEqual(mockKFDAService.searchFoodsCallCount, 1, "KFDA should be called once")
        XCTAssertEqual(mockUSDAService.searchFoodsCallCount, 1, "USDA should be called once")
    }

    /// Test: English query prioritizes USDA results first
    ///
    /// 테스트: 영문 검색어는 USDA 결과를 먼저 배치
    func testSearchFoods_EnglishQuery_USDAResultsAppearFirst() async throws {
        // Given: English query with results from both APIs
        let kfdaFoods = createSampleKFDAFoods(count: 3)
        mockKFDAService.mockSearchResponse = createKFDAResponse(foods: kfdaFoods)

        let usdaFoods = createSampleUSDAFoods(count: 2)
        mockUSDAService.mockSearchResponse = createUSDAResponse(foods: usdaFoods)

        // When: Searching with English query
        let results = try await service.searchFoods(query: "apple", limit: 20)

        // Then: USDA results should appear first
        XCTAssertEqual(results.count, 5, "Should return 5 total foods")
        XCTAssertEqual(results[0].source, .usda, "First result should be USDA")
        XCTAssertEqual(results[1].source, .usda, "Second result should be USDA")
        XCTAssertEqual(results[2].source, .governmentAPI, "Third result should be KFDA")
        XCTAssertEqual(results[3].source, .governmentAPI, "Fourth result should be KFDA")
        XCTAssertEqual(results[4].source, .governmentAPI, "Fifth result should be KFDA")
    }

    /// Test: English query with only USDA results
    ///
    /// 테스트: 영문 검색어에 USDA 결과만 있는 경우
    func testSearchFoods_EnglishQuery_OnlyUSDAResults() async throws {
        // Given: English query with only USDA results
        mockKFDAService.mockSearchResponse = createKFDAResponse(foods: [])

        let usdaFoods = createSampleUSDAFoods(count: 10)
        mockUSDAService.mockSearchResponse = createUSDAResponse(foods: usdaFoods)

        // When: Searching with English query
        let results = try await service.searchFoods(query: "steak", limit: 20)

        // Then: Should return USDA results only
        XCTAssertEqual(results.count, 10, "Should return 10 USDA foods")
        XCTAssertEqual(mockKFDAService.searchFoodsCallCount, 1, "KFDA should still be called")
        XCTAssertEqual(mockUSDAService.searchFoodsCallCount, 1, "USDA should be called")
    }

    // MARK: - Deduplication Tests

    /// Test: Deduplication by apiCode removes duplicates
    ///
    /// 테스트: apiCode 기준으로 중복 제거
    func testSearchFoods_Deduplication_RemovesDuplicatesByApiCode() async throws {
        // Given: Both APIs return foods with same apiCode
        let kfdaFoods = [
            createKFDAFood(apiCode: "FOOD001", name: "김치"),
            createKFDAFood(apiCode: "FOOD002", name: "된장"),
        ]
        mockKFDAService.mockSearchResponse = createKFDAResponse(foods: kfdaFoods)

        let usdaFoods = [
            createUSDAFood(fdcId: 12345, name: "Kimchi", apiCode: "FOOD001"), // Duplicate
            createUSDAFood(fdcId: 67890, name: "Rice", apiCode: "FOOD003"),
        ]
        mockUSDAService.mockSearchResponse = createUSDAResponse(foods: usdaFoods)

        // When: Searching with Korean query
        let results = try await service.searchFoods(query: "김치", limit: 20)

        // Then: Should remove duplicate (keep first occurrence)
        XCTAssertEqual(results.count, 3, "Should return 3 unique foods (4 - 1 duplicate)")

        // Verify that first occurrence is kept (KFDA version)
        let kimchiFood = results.first { $0.apiCode == "FOOD001" }
        XCTAssertNotNil(kimchiFood, "Kimchi should be in results")
        XCTAssertEqual(kimchiFood?.source, .governmentAPI, "Should keep KFDA version (first occurrence)")
    }

    /// Test: Deduplication by name when apiCode is missing
    ///
    /// 테스트: apiCode가 없으면 name으로 중복 제거
    func testSearchFoods_Deduplication_RemovesDuplicatesByName() async throws {
        // Given: Foods with same name but no apiCode
        let kfdaFoods = [
            createKFDAFood(apiCode: nil, name: "김치찌개"),
        ]
        mockKFDAService.mockSearchResponse = createKFDAResponse(foods: kfdaFoods)

        let usdaFoods = [
            createUSDAFood(fdcId: 12345, name: "김치찌개", apiCode: nil), // Duplicate by name
            createUSDAFood(fdcId: 67890, name: "Rice", apiCode: nil),
        ]
        mockUSDAService.mockSearchResponse = createUSDAResponse(foods: usdaFoods)

        // When: Searching with Korean query
        let results = try await service.searchFoods(query: "김치", limit: 20)

        // Then: Should remove duplicate by name
        XCTAssertEqual(results.count, 2, "Should return 2 unique foods (3 - 1 duplicate)")
    }

    // MARK: - Error Handling and Fallback Tests

    /// Test: KFDA failure falls back to USDA for Korean query
    ///
    /// 테스트: 식약처 API 실패 시 USDA로 폴백 (한글 검색어)
    func testSearchFoods_KoreanQuery_KFDAFails_FallsBackToUSDA() async throws {
        // Given: KFDA fails, USDA succeeds
        mockKFDAService.shouldThrowError = NetworkError.timeout

        let usdaFoods = createSampleUSDAFoods(count: 5)
        mockUSDAService.mockSearchResponse = createUSDAResponse(foods: usdaFoods)

        // When: Searching with Korean query
        let results = try await service.searchFoods(query: "김치", limit: 20)

        // Then: Should return USDA results (graceful degradation)
        XCTAssertEqual(results.count, 5, "Should return 5 USDA foods")
        XCTAssertEqual(mockUSDAService.searchFoodsCallCount, 1, "USDA should be called once")
    }

    /// Test: USDA failure returns only KFDA results for English query
    ///
    /// 테스트: USDA API 실패 시 KFDA 결과만 반환 (영문 검색어)
    func testSearchFoods_EnglishQuery_USDAFails_ReturnsKFDAResults() async throws {
        // Given: USDA fails, KFDA succeeds
        mockUSDAService.shouldThrowError = NetworkError.networkUnavailable

        let kfdaFoods = createSampleKFDAFoods(count: 5)
        mockKFDAService.mockSearchResponse = createKFDAResponse(foods: kfdaFoods)

        // When: Searching with English query
        let results = try await service.searchFoods(query: "chicken", limit: 20)

        // Then: Should return KFDA results (graceful degradation)
        XCTAssertEqual(results.count, 5, "Should return 5 KFDA foods")
        XCTAssertEqual(mockKFDAService.searchFoodsCallCount, 1, "KFDA should be called once")
    }

    /// Test: Both APIs fail returns empty array
    ///
    /// 테스트: 양쪽 API 모두 실패하면 빈 배열 반환 (graceful degradation)
    func testSearchFoods_BothAPIsFail_ReturnsEmptyArray() async throws {
        // Given: Both APIs fail
        mockKFDAService.shouldThrowError = NetworkError.timeout
        mockUSDAService.shouldThrowError = NetworkError.networkUnavailable

        // When: Searching with any query
        let results = try await service.searchFoods(query: "test", limit: 20)

        // Then: Should return empty array (no exception thrown)
        XCTAssertEqual(results.count, 0, "Should return empty array")
        XCTAssertNoThrow(results, "Should not throw error (graceful degradation)")
    }

    // MARK: - Limit and Boundary Tests

    /// Test: Results respect limit parameter
    ///
    /// 테스트: 결과가 limit 파라미터를 준수함
    func testSearchFoods_RespectsLimitParameter() async throws {
        // Given: More results than limit
        let kfdaFoods = createSampleKFDAFoods(count: 30)
        mockKFDAService.mockSearchResponse = createKFDAResponse(foods: kfdaFoods)

        // When: Searching with limit of 10
        let results = try await service.searchFoods(query: "김치", limit: 10)

        // Then: Should return exactly 10 results
        XCTAssertEqual(results.count, 10, "Should return exactly 10 foods")
    }

    /// Test: Empty query throws error
    ///
    /// 테스트: 빈 검색어는 에러 발생
    func testSearchFoods_EmptyQuery_ThrowsError() async {
        // Given: Empty query
        let emptyQuery = ""

        // When/Then: Should throw invalidQuery error
        do {
            _ = try await service.searchFoods(query: emptyQuery, limit: 20)
            XCTFail("Should throw error for empty query")
        } catch let error as FoodSearchError {
            if case .invalidQuery = error {
                // Expected error
                XCTAssertTrue(true, "Should throw invalidQuery error")
            } else {
                XCTFail("Should throw invalidQuery error, got \(error)")
            }
        } catch {
            XCTFail("Should throw FoodSearchError, got \(error)")
        }
    }

    /// Test: Whitespace-only query throws error
    ///
    /// 테스트: 공백만 있는 검색어는 에러 발생
    func testSearchFoods_WhitespaceQuery_ThrowsError() async {
        // Given: Whitespace-only query
        let whitespaceQuery = "   "

        // When/Then: Should throw invalidQuery error
        do {
            _ = try await service.searchFoods(query: whitespaceQuery, limit: 20)
            XCTFail("Should throw error for whitespace query")
        } catch let error as FoodSearchError {
            if case .invalidQuery = error {
                // Expected error
                XCTAssertTrue(true, "Should throw invalidQuery error")
            } else {
                XCTFail("Should throw invalidQuery error, got \(error)")
            }
        } catch {
            XCTFail("Should throw FoodSearchError, got \(error)")
        }
    }

    /// Test: Zero limit returns empty results
    ///
    /// 테스트: limit이 0이면 빈 결과 반환
    func testSearchFoods_ZeroLimit_ReturnsEmpty() async throws {
        // Given: Valid results but limit of 0
        let kfdaFoods = createSampleKFDAFoods(count: 10)
        mockKFDAService.mockSearchResponse = createKFDAResponse(foods: kfdaFoods)

        // When: Searching with limit of 0
        let results = try await service.searchFoods(query: "김치", limit: 0)

        // Then: Should return empty array
        XCTAssertEqual(results.count, 0, "Should return empty array")
    }

    // MARK: - Korean Character Detection Tests

    /// Test: Mixed Korean-English query is treated as Korean
    ///
    /// 테스트: 한글+영문 혼합 검색어는 한글로 취급
    func testSearchFoods_MixedKoreanEnglish_TreatedAsKorean() async throws {
        // Given: Mixed Korean-English query
        let kfdaFoods = createSampleKFDAFoods(count: 10)
        mockKFDAService.mockSearchResponse = createKFDAResponse(foods: kfdaFoods)

        // When: Searching with mixed query
        let results = try await service.searchFoods(query: "김치 kimchi", limit: 20)

        // Then: Should search KFDA first (Korean strategy)
        XCTAssertEqual(results.count, 10, "Should return 10 KFDA foods")
        XCTAssertEqual(mockKFDAService.searchFoodsCallCount, 1, "KFDA should be called")
        // USDA should not be called because KFDA returned sufficient results (≥5)
        XCTAssertEqual(mockUSDAService.searchFoodsCallCount, 0, "USDA should not be called")
    }

    /// Test: Pure English query uses parallel search
    ///
    /// 테스트: 순수 영문 검색어는 병렬 검색
    func testSearchFoods_PureEnglish_UsesParallelSearch() async throws {
        // Given: Pure English query
        let kfdaFoods = createSampleKFDAFoods(count: 5)
        mockKFDAService.mockSearchResponse = createKFDAResponse(foods: kfdaFoods)

        let usdaFoods = createSampleUSDAFoods(count: 5)
        mockUSDAService.mockSearchResponse = createUSDAResponse(foods: usdaFoods)

        // When: Searching with English query
        let results = try await service.searchFoods(query: "apple juice", limit: 20)

        // Then: Should call both APIs
        XCTAssertEqual(results.count, 10, "Should return 10 total foods")
        XCTAssertEqual(mockKFDAService.searchFoodsCallCount, 1, "KFDA should be called")
        XCTAssertEqual(mockUSDAService.searchFoodsCallCount, 1, "USDA should be called")
    }

    // MARK: - Helper Methods

    /// Create sample KFDA foods
    private func createSampleKFDAFoods(count: Int) -> [KFDAFoodDTO] {
        return (1...count).map { index in
            KFDAFoodDTO(
                foodCd: "KFDA\(String(format: "%03d", index))",
                descKor: "한국음식\(index)",
                groupCode: "01",
                groupName: "곡류",
                enercKcal: "300",
                prot: "10.0",
                fat: "5.0",
                chocdf: "50.0",
                na: "100",
                fibtg: "2.0",
                sugar: "1.0",
                servingSize: "210",
                servingWt: "200",
                servingUnit: "1인분"
            )
        }
    }

    /// Create sample USDA foods
    private func createSampleUSDAFoods(count: Int) -> [USDAFoodDTO] {
        return (1...count).map { index in
            USDAFoodDTO(
                fdcId: 100000 + index,
                description: "International Food \(index)",
                dataType: "Foundation",
                foodCode: "USDA\(String(format: "%03d", index))",
                foodNutrients: [
                    USDANutrientDTO(nutrientId: 1008, nutrientName: "Energy", value: 250.0, unitName: "kcal"),
                    USDANutrientDTO(nutrientId: 1003, nutrientName: "Protein", value: 8.0, unitName: "g"),
                    USDANutrientDTO(nutrientId: 1004, nutrientName: "Fat", value: 4.0, unitName: "g"),
                    USDANutrientDTO(nutrientId: 1005, nutrientName: "Carbohydrate", value: 40.0, unitName: "g"),
                ],
                servingSize: 100.0,
                servingSizeUnit: "g",
                householdServingFullText: "1 serving",
                brandOwner: nil,
                brandName: nil,
                gtinUpc: nil,
                ingredients: nil,
                foodCategoryId: nil,
                foodCategory: nil
            )
        }
    }

    /// Create KFDA search response
    private func createKFDAResponse(foods: [KFDAFoodDTO]) -> KFDASearchResponseDTO {
        return KFDASearchResponseDTO(
            header: KFDASearchResponseDTO.Header(
                resultCode: "00",
                resultMsg: "SUCCESS"
            ),
            body: KFDASearchResponseDTO.Body(
                totalCount: String(foods.count),
                pageNo: "1",
                numOfRows: String(foods.count),
                items: foods.isEmpty ? [] : foods
            )
        )
    }

    /// Create USDA search response
    private func createUSDAResponse(foods: [USDAFoodDTO]) -> USDASearchResponseDTO {
        return USDASearchResponseDTO(
            totalHits: foods.count,
            currentPage: 1,
            totalPages: 1,
            pageList: nil,
            foodSearchCriteria: nil,
            foods: foods.isEmpty ? nil : foods
        )
    }

    /// Create single KFDA food with custom properties
    private func createKFDAFood(apiCode: String?, name: String) -> KFDAFoodDTO {
        return KFDAFoodDTO(
            foodCd: apiCode ?? "DEFAULT",
            descKor: name,
            groupCode: "01",
            groupName: "곡류",
            enercKcal: "300",
            prot: "10.0",
            fat: "5.0",
            chocdf: "50.0",
            na: "100",
            fibtg: "2.0",
            sugar: "1.0",
            servingSize: "210",
            servingWt: "200",
            servingUnit: "1인분"
        )
    }

    /// Create single USDA food with custom properties
    private func createUSDAFood(fdcId: Int, name: String, apiCode: String?) -> USDAFoodDTO {
        return USDAFoodDTO(
            fdcId: fdcId,
            description: name,
            dataType: "Foundation",
            foodCode: apiCode,
            foodNutrients: [
                USDANutrientDTO(nutrientId: 1008, nutrientName: "Energy", value: 250.0, unitName: "kcal"),
                USDANutrientDTO(nutrientId: 1003, nutrientName: "Protein", value: 8.0, unitName: "g"),
                USDANutrientDTO(nutrientId: 1004, nutrientName: "Fat", value: 4.0, unitName: "g"),
                USDANutrientDTO(nutrientId: 1005, nutrientName: "Carbohydrate", value: 40.0, unitName: "g"),
            ],
            servingSize: 100.0,
            servingSizeUnit: "g",
            householdServingFullText: "1 serving",
            brandOwner: nil,
            brandName: nil,
            gtinUpc: nil,
            ingredients: nil,
            foodCategoryId: nil,
            foodCategory: nil
        )
    }
}
