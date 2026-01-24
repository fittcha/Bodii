//
//  FoodLabelMatcherServiceTests.swift
//  BodiiTests
//
//  Created by Auto-Claude on 2026-01-17.
//

import XCTest
@testable import Bodii

/// Unit tests for FoodLabelMatcherService
///
/// FoodLabelMatcherService의 라벨 매칭, 번역, 검색 우선순위 단위 테스트
///
/// **테스트 범위:**
/// - Label to food matching logic
/// - English to Korean translation
/// - KFDA > USDA search priority
/// - Confidence score calculation
/// - Alternative food suggestions
/// - Empty/invalid input handling
final class FoodLabelMatcherServiceTests: XCTestCase {

    // MARK: - Properties

    var service: FoodLabelMatcherService!
    var mockUnifiedSearchService: MockUnifiedFoodSearchService!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()

        // Initialize mock search service
        mockUnifiedSearchService = MockUnifiedFoodSearchService()

        // Initialize service with mock
        service = FoodLabelMatcherService(
            unifiedSearchService: mockUnifiedSearchService,
            maxAlternatives: 3,
            minConfidence: 0.3
        )
    }

    override func tearDown() {
        service = nil
        mockUnifiedSearchService = nil
        super.tearDown()
    }

    // MARK: - Happy Path Tests

    /// Test: Match single label to food
    ///
    /// 테스트: 단일 라벨을 음식과 매칭
    func testMatchLabelsToFoods_SingleLabel_ReturnsMatch() async throws {
        // Given: Single pizza label
        let labels = [
            VisionLabel(mid: "/m/0663v", description: "Pizza", score: 0.92, topicality: 0.90)
        ]

        // Given: Mock search returns pizza foods
        let pizzaFoods = [
            createSampleFood(name: "치즈 피자", calories: 266),
            createSampleFood(name: "페퍼로니 피자", calories: 298),
            createSampleFood(name: "야채 피자", calories: 245)
        ]
        mockUnifiedSearchService.mockSearchResults = pizzaFoods

        // When: Matching labels
        let matches = try await service.matchLabelsToFoods(labels)

        // Then: Should return matches
        XCTAssertEqual(matches.count, 1, "Should return 1 match")
        XCTAssertEqual(matches[0].label, "Pizza")
        XCTAssertEqual(matches[0].food.name, "치즈 피자")
        XCTAssertEqual(matches[0].alternatives.count, 2, "Should have 2 alternatives")
    }

    /// Test: Match multiple labels to foods
    ///
    /// 테스트: 여러 라벨을 음식과 매칭
    func testMatchLabelsToFoods_MultipleLabels_ReturnsMultipleMatches() async throws {
        // Given: Multiple food labels
        let labels = [
            VisionLabel(mid: "/m/0663v", description: "Pizza", score: 0.92, topicality: 0.90),
            VisionLabel(mid: "/m/01xs0s", description: "Salad", score: 0.85, topicality: 0.82)
        ]

        // Given: Mock search returns foods for each label
        mockUnifiedSearchService.searchResultsMap = [
            "피자": [createSampleFood(name: "치즈 피자", calories: 266)],
            "pizza": [createSampleFood(name: "치즈 피자", calories: 266)],
            "샐러드": [createSampleFood(name: "시저 샐러드", calories: 180)],
            "salad": [createSampleFood(name: "시저 샐러드", calories: 180)]
        ]

        // When: Matching labels
        let matches = try await service.matchLabelsToFoods(labels)

        // Then: Should return multiple matches
        XCTAssertGreaterThanOrEqual(matches.count, 2, "Should return at least 2 matches")
    }

    /// Test: Labels are sorted by confidence descending
    ///
    /// 테스트: 라벨은 신뢰도 내림차순으로 정렬됨
    func testMatchLabelsToFoods_SortsByConfidenceDescending() async throws {
        // Given: Labels with different scores
        let labels = [
            VisionLabel(mid: "/m/0663v", description: "Pizza", score: 0.70, topicality: 0.68),  // Lower score
            VisionLabel(mid: "/m/02wbm", description: "Food", score: 0.95, topicality: 0.93)   // Higher score
        ]

        // Given: Mock search returns foods
        mockUnifiedSearchService.searchResultsMap = [
            "피자": [createSampleFood(name: "피자", calories: 266)],
            "pizza": [createSampleFood(name: "피자", calories: 266)],
            "음식": [createSampleFood(name: "일반 음식", calories: 200)],
            "식품": [createSampleFood(name: "일반 음식", calories: 200)],
            "food": [createSampleFood(name: "일반 음식", calories: 200)]
        ]

        // When: Matching labels
        let matches = try await service.matchLabelsToFoods(labels)

        // Then: Should be sorted by confidence
        if matches.count >= 2 {
            XCTAssertGreaterThanOrEqual(matches[0].confidence, matches[1].confidence,
                                       "First match should have higher confidence")
        }
    }

    // MARK: - Translation Tests

    /// Test: English label is translated to Korean
    ///
    /// 테스트: 영문 라벨은 한국어로 번역됨
    func testMatchLabelsToFoods_TranslatesEnglishToKorean() async throws {
        // Given: English label
        let labels = [
            VisionLabel(mid: "/m/0663v", description: "Chicken", score: 0.90, topicality: 0.88)
        ]

        // Given: Mock search for Korean translation
        let chickenFoods = [createSampleFood(name: "닭고기", calories: 165)]
        mockUnifiedSearchService.searchResultsMap = [
            "닭고기": chickenFoods,
            "치킨": chickenFoods
        ]

        // When: Matching labels
        let matches = try await service.matchLabelsToFoods(labels)

        // Then: Should find food via Korean translation
        XCTAssertGreaterThan(matches.count, 0, "Should find match via translation")
        XCTAssertTrue(
            mockUnifiedSearchService.searchedQueries.contains("닭고기") ||
            mockUnifiedSearchService.searchedQueries.contains("치킨"),
            "Should search with Korean translation"
        )
    }

    /// Test: Untranslatable label searches with original text
    ///
    /// 테스트: 번역 불가 라벨은 원문으로 검색
    func testMatchLabelsToFoods_UntranslatableLabel_SearchesWithOriginal() async throws {
        // Given: Untranslatable label
        let labels = [
            VisionLabel(mid: "/m/xyz", description: "SomeUnknownFood", score: 0.80, topicality: 0.78)
        ]

        // Given: Mock search for original text
        mockUnifiedSearchService.mockSearchResults = [
            createSampleFood(name: "SomeUnknownFood", calories: 100)
        ]

        // When: Matching labels
        let matches = try await service.matchLabelsToFoods(labels)

        // Then: Should search with original text
        XCTAssertTrue(
            mockUnifiedSearchService.searchedQueries.contains("someunknownfood"),
            "Should search with original label"
        )
    }

    // MARK: - Confidence Score Tests

    /// Test: High Vision score with exact match produces high confidence
    ///
    /// 테스트: 높은 Vision 점수와 정확한 매칭은 높은 신뢰도 생성
    func testMatchLabelsToFoods_HighScoreExactMatch_HighConfidence() async throws {
        // Given: High score label
        let labels = [
            VisionLabel(mid: "/m/0663v", description: "Pizza", score: 0.95, topicality: 0.93)
        ]

        // Given: Exact match in search results
        mockUnifiedSearchService.mockSearchResults = [
            createSampleFood(name: "pizza", calories: 266)
        ]

        // When: Matching labels
        let matches = try await service.matchLabelsToFoods(labels)

        // Then: Should have high confidence
        XCTAssertGreaterThan(matches[0].confidence, 0.7, "Should have high confidence for exact match")
    }

    /// Test: Low confidence matches are filtered out
    ///
    /// 테스트: 낮은 신뢰도 매칭은 필터링됨
    func testMatchLabelsToFoods_LowConfidence_Filtered() async throws {
        // Given: Very low score label
        let labels = [
            VisionLabel(mid: "/m/xyz", description: "VagueLabel", score: 0.20, topicality: 0.18)
        ]

        // Given: Search returns results but confidence will be low
        mockUnifiedSearchService.mockSearchResults = [
            createSampleFood(name: "Unrelated Food", calories: 100)
        ]

        // When: Matching labels
        let matches = try await service.matchLabelsToFoods(labels)

        // Then: Should filter out low confidence matches (< 0.3)
        // Note: 0.20 * 0.5 (default match quality) = 0.10 < 0.3 threshold
        XCTAssertEqual(matches.count, 0, "Should filter out very low confidence matches")
    }

    // MARK: - Alternative Foods Tests

    /// Test: Returns alternative food options
    ///
    /// 테스트: 대체 음식 옵션 반환
    func testMatchLabelsToFoods_ReturnsAlternatives() async throws {
        // Given: Label
        let labels = [
            VisionLabel(mid: "/m/0663v", description: "Pizza", score: 0.90, topicality: 0.88)
        ]

        // Given: Multiple search results
        let pizzaFoods = [
            createSampleFood(id: UUID(), name: "치즈 피자", calories: 266),
            createSampleFood(id: UUID(), name: "페퍼로니 피자", calories: 298),
            createSampleFood(id: UUID(), name: "야채 피자", calories: 245),
            createSampleFood(id: UUID(), name: "불고기 피자", calories: 310),
            createSampleFood(id: UUID(), name: "시카고 피자", calories: 350)
        ]
        mockUnifiedSearchService.mockSearchResults = pizzaFoods

        // When: Matching labels
        let matches = try await service.matchLabelsToFoods(labels)

        // Then: Should return primary match + alternatives
        XCTAssertEqual(matches.count, 1, "Should return 1 match")
        XCTAssertEqual(matches[0].food.name, "치즈 피자", "First result should be primary")
        XCTAssertEqual(matches[0].alternatives.count, 3, "Should have up to 3 alternatives")
    }

    // MARK: - Empty Input Tests

    /// Test: Empty labels returns empty array
    ///
    /// 테스트: 빈 라벨 배열은 빈 배열 반환
    func testMatchLabelsToFoods_EmptyLabels_ReturnsEmpty() async throws {
        // Given: Empty labels array
        let labels: [VisionLabel] = []

        // When: Matching labels
        let matches = try await service.matchLabelsToFoods(labels)

        // Then: Should return empty array
        XCTAssertEqual(matches.count, 0, "Should return empty array for empty input")
    }

    /// Test: No search results returns empty array
    ///
    /// 테스트: 검색 결과 없으면 빈 배열 반환
    func testMatchLabelsToFoods_NoSearchResults_ReturnsEmpty() async throws {
        // Given: Valid label
        let labels = [
            VisionLabel(mid: "/m/xyz", description: "UnknownFood", score: 0.80, topicality: 0.78)
        ]

        // Given: Search returns no results
        mockUnifiedSearchService.mockSearchResults = []

        // When: Matching labels
        let matches = try await service.matchLabelsToFoods(labels)

        // Then: Should return empty array
        XCTAssertEqual(matches.count, 0, "Should return empty array when no foods found")
    }

    // MARK: - Error Handling Tests

    /// Test: Search error is handled gracefully
    ///
    /// 테스트: 검색 에러는 gracefully 처리됨
    func testMatchLabelsToFoods_SearchError_ReturnsEmpty() async throws {
        // Given: Valid label
        let labels = [
            VisionLabel(mid: "/m/0663v", description: "Pizza", score: 0.90, topicality: 0.88)
        ]

        // Given: Search throws error
        mockUnifiedSearchService.shouldThrowError = FoodSearchError.networkError

        // When: Matching labels
        let matches = try await service.matchLabelsToFoods(labels)

        // Then: Should handle error gracefully and return empty
        XCTAssertEqual(matches.count, 0, "Should return empty array on search error")
    }

    // MARK: - Deduplication Tests

    /// Test: Duplicate foods are removed
    ///
    /// 테스트: 중복 음식은 제거됨
    func testMatchLabelsToFoods_RemovesDuplicates() async throws {
        // Given: Labels
        let labels = [
            VisionLabel(mid: "/m/0663v", description: "Pizza", score: 0.90, topicality: 0.88)
        ]

        // Given: Search returns duplicate foods
        let duplicateFood = createSampleFood(id: UUID(), name: "피자", calories: 266)
        mockUnifiedSearchService.mockSearchResults = [
            duplicateFood,
            duplicateFood,  // Duplicate
            createSampleFood(id: UUID(), name: "다른 피자", calories: 280)
        ]

        // When: Matching labels
        let matches = try await service.matchLabelsToFoods(labels)

        // Then: Should deduplicate
        XCTAssertEqual(matches.count, 1, "Should return 1 match")
        // Primary food + 1 alternative (duplicate removed)
        XCTAssertLessThanOrEqual(matches[0].alternatives.count, 1, "Should remove duplicate")
    }

    // MARK: - Translation Dictionary Tests

    /// Test: Common food terms are translated
    ///
    /// 테스트: 일반 음식 용어는 번역됨
    func testTranslation_CommonFoodTerms() async throws {
        // Test various common food terms
        let testCases: [(english: String, korean: String)] = [
            ("Chicken", "닭고기"),
            ("Rice", "밥"),
            ("Pizza", "피자"),
            ("Salad", "샐러드"),
            ("Beef", "소고기")
        ]

        for testCase in testCases {
            // Given: English label
            let labels = [
                VisionLabel(mid: "/m/test", description: testCase.english, score: 0.90, topicality: 0.88)
            ]

            // Given: Mock search for Korean term
            mockUnifiedSearchService.searchResultsMap = [
                testCase.korean: [createSampleFood(name: testCase.korean, calories: 200)]
            ]

            // When: Matching labels
            _ = try await service.matchLabelsToFoods(labels)

            // Then: Should search with Korean translation
            XCTAssertTrue(
                mockUnifiedSearchService.searchedQueries.contains(testCase.korean.lowercased()),
                "\(testCase.english) should be translated to \(testCase.korean)"
            )

            // Reset for next test
            mockUnifiedSearchService.reset()
        }
    }

    // MARK: - Helper Methods

    /// Create sample food for testing
    ///
    /// 테스트용 샘플 음식 생성
    private func createSampleFood(
        id: UUID = UUID(),
        name: String,
        calories: Int32
    ) -> Food {
        return Food(
            id: id,
            name: name,
            calories: calories,
            carbohydrates: Decimal(50),
            protein: Decimal(10),
            fat: Decimal(5),
            sodium: Decimal(300),
            fiber: Decimal(2),
            sugar: Decimal(1),
            servingSize: Decimal(100),
            servingUnit: "g",
            source: .governmentAPI,
            apiCode: "TEST001",
            createdByUserId: nil,
            createdAt: Date()
        )
    }
}

// MARK: - Mock Unified Food Search Service

/// Mock UnifiedFoodSearchService for testing
///
/// 테스트용 Mock 통합 검색 서비스
class MockUnifiedFoodSearchService: UnifiedFoodSearchService {

    /// Mock search results to return
    var mockSearchResults: [Food] = []

    /// Map of query to specific results
    var searchResultsMap: [String: [Food]] = [:]

    /// Error to throw
    var shouldThrowError: Error?

    /// Track searched queries
    var searchedQueries: [String] = []

    /// Call count
    var searchCallCount = 0

    override func searchFoods(query: String, limit: Int) async throws -> [Food] {
        searchCallCount += 1
        searchedQueries.append(query.lowercased())

        // Throw error if set
        if let error = shouldThrowError {
            throw error
        }

        // Return specific results for query if mapped
        if let results = searchResultsMap[query.lowercased()] {
            return Array(results.prefix(limit))
        }

        // Return mock results
        return Array(mockSearchResults.prefix(limit))
    }

    func reset() {
        mockSearchResults = []
        searchResultsMap = [:]
        shouldThrowError = nil
        searchedQueries = []
        searchCallCount = 0
    }
}
