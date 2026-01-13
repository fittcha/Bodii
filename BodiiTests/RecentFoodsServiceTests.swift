//
//  RecentFoodsServiceTests.swift
//  BodiiTests
//
//  Created by Auto-Claude on 2026-01-13.
//

import XCTest
@testable import Bodii

/// RecentFoodsService 단위 테스트
///
/// 최근/자주 사용한 음식 조회 기능을 검증합니다.
final class RecentFoodsServiceTests: XCTestCase {

    // MARK: - Properties

    var sut: RecentFoodsService!
    var mockFoodRepository: MockFoodRepository!
    let testUserId = UUID()

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()
        mockFoodRepository = MockFoodRepository()
        sut = RecentFoodsService(foodRepository: mockFoodRepository)
    }

    override func tearDown() {
        sut = nil
        mockFoodRepository = nil
        super.tearDown()
    }

    // MARK: - Recent Foods Tests

    /// 최근 사용 음식을 정상적으로 조회하는지 테스트
    func testGetRecentFoods_ReturnsRecentFoods() async throws {
        // Given: 15개의 최근 음식이 있음
        let recentFoods = createSampleFoods(count: 15, prefix: "최근음식")
        mockFoodRepository.recentFoodsToReturn = recentFoods

        // When: 최근 음식 조회
        let result = try await sut.getRecentFoods(userId: testUserId)

        // Then: 최대 10개만 반환
        XCTAssertEqual(result.count, 10, "최근 음식은 최대 10개까지 반환되어야 합니다")
        XCTAssertEqual(mockFoodRepository.getRecentFoodsCallCount, 1)
        XCTAssertEqual(mockFoodRepository.lastGetRecentFoodsUserId, testUserId)
    }

    /// 최근 음식이 없을 때 빈 배열을 반환하는지 테스트
    func testGetRecentFoods_WithNoFoods_ReturnsEmptyArray() async throws {
        // Given: 최근 음식이 없음
        mockFoodRepository.recentFoodsToReturn = []

        // When: 최근 음식 조회
        let result = try await sut.getRecentFoods(userId: testUserId)

        // Then: 빈 배열 반환
        XCTAssertTrue(result.isEmpty, "최근 음식이 없을 때는 빈 배열을 반환해야 합니다")
        XCTAssertEqual(mockFoodRepository.getRecentFoodsCallCount, 1)
    }

    /// 최근 음식이 10개 미만일 때 모두 반환하는지 테스트
    func testGetRecentFoods_WithFewerThanMax_ReturnsAll() async throws {
        // Given: 5개의 최근 음식이 있음
        let recentFoods = createSampleFoods(count: 5, prefix: "최근음식")
        mockFoodRepository.recentFoodsToReturn = recentFoods

        // When: 최근 음식 조회
        let result = try await sut.getRecentFoods(userId: testUserId)

        // Then: 5개 모두 반환
        XCTAssertEqual(result.count, 5, "최근 음식이 10개 미만일 때는 모두 반환해야 합니다")
    }

    // MARK: - Frequent Foods Tests

    /// 자주 사용하는 음식을 정상적으로 조회하는지 테스트
    func testGetFrequentFoods_ReturnsFrequentFoods() async throws {
        // Given: 20개의 자주 사용하는 음식이 있음
        let frequentFoods = createSampleFoods(count: 20, prefix: "자주먹는음식")
        mockFoodRepository.frequentFoodsToReturn = frequentFoods

        // When: 자주 사용하는 음식 조회
        let result = try await sut.getFrequentFoods(userId: testUserId)

        // Then: 최대 10개만 반환
        XCTAssertEqual(result.count, 10, "자주 사용하는 음식은 최대 10개까지 반환되어야 합니다")
        XCTAssertEqual(mockFoodRepository.getFrequentFoodsCallCount, 1)
        XCTAssertEqual(mockFoodRepository.lastGetFrequentFoodsUserId, testUserId)
    }

    /// 자주 사용하는 음식이 없을 때 빈 배열을 반환하는지 테스트
    func testGetFrequentFoods_WithNoFoods_ReturnsEmptyArray() async throws {
        // Given: 자주 사용하는 음식이 없음
        mockFoodRepository.frequentFoodsToReturn = []

        // When: 자주 사용하는 음식 조회
        let result = try await sut.getFrequentFoods(userId: testUserId)

        // Then: 빈 배열 반환
        XCTAssertTrue(result.isEmpty, "자주 사용하는 음식이 없을 때는 빈 배열을 반환해야 합니다")
        XCTAssertEqual(mockFoodRepository.getFrequentFoodsCallCount, 1)
    }

    /// 자주 사용하는 음식이 10개 미만일 때 모두 반환하는지 테스트
    func testGetFrequentFoods_WithFewerThanMax_ReturnsAll() async throws {
        // Given: 7개의 자주 사용하는 음식이 있음
        let frequentFoods = createSampleFoods(count: 7, prefix: "자주먹는음식")
        mockFoodRepository.frequentFoodsToReturn = frequentFoods

        // When: 자주 사용하는 음식 조회
        let result = try await sut.getFrequentFoods(userId: testUserId)

        // Then: 7개 모두 반환
        XCTAssertEqual(result.count, 7, "자주 사용하는 음식이 10개 미만일 때는 모두 반환해야 합니다")
    }

    // MARK: - Quick Add Foods Tests

    /// 빠른 추가 음식을 정상적으로 조회하는지 테스트
    func testGetQuickAddFoods_CombinesRecentAndFrequent() async throws {
        // Given: 최근 음식 8개, 자주 사용하는 음식 10개가 있음 (중복 없음)
        let recentFoods = createSampleFoods(count: 8, prefix: "최근음식")
        let frequentFoods = createSampleFoods(count: 10, prefix: "자주먹는음식")

        mockFoodRepository.recentFoodsToReturn = recentFoods
        mockFoodRepository.frequentFoodsToReturn = frequentFoods

        // When: 빠른 추가 음식 조회
        let result = try await sut.getQuickAddFoods(userId: testUserId)

        // Then: 최대 15개 반환 (최근 8개 + 자주 사용 7개)
        XCTAssertEqual(result.count, 15, "빠른 추가 음식은 최대 15개까지 반환되어야 합니다")

        // 최근 음식이 앞에 있어야 함
        for i in 0..<8 {
            XCTAssertEqual(result[i].id, recentFoods[i].id, "최근 음식이 우선순위로 포함되어야 합니다")
        }

        // 자주 사용하는 음식이 뒤에 추가되어야 함
        for i in 8..<15 {
            XCTAssertEqual(result[i].id, frequentFoods[i - 8].id, "자주 사용하는 음식이 추가되어야 합니다")
        }
    }

    /// 빠른 추가 음식에서 중복을 제거하는지 테스트
    func testGetQuickAddFoods_RemovesDuplicates() async throws {
        // Given: 최근 음식과 자주 사용하는 음식에 중복이 있음
        let sharedFood1 = createFood(name: "공통음식1")
        let sharedFood2 = createFood(name: "공통음식2")

        let recentFoods = [
            sharedFood1,
            createFood(name: "최근음식1"),
            sharedFood2,
            createFood(name: "최근음식2")
        ]

        let frequentFoods = [
            sharedFood1,  // 중복
            createFood(name: "자주먹는음식1"),
            sharedFood2,  // 중복
            createFood(name: "자주먹는음식2")
        ]

        mockFoodRepository.recentFoodsToReturn = recentFoods
        mockFoodRepository.frequentFoodsToReturn = frequentFoods

        // When: 빠른 추가 음식 조회
        let result = try await sut.getQuickAddFoods(userId: testUserId)

        // Then: 중복이 제거되어야 함
        XCTAssertEqual(result.count, 6, "중복이 제거되어야 합니다")

        let resultIds = result.map { $0.id }
        let uniqueIds = Set(resultIds)
        XCTAssertEqual(resultIds.count, uniqueIds.count, "모든 음식이 고유해야 합니다")

        // 최근 음식이 우선순위를 가져야 함
        XCTAssertEqual(result[0].id, sharedFood1.id)
        XCTAssertEqual(result[2].id, sharedFood2.id)
    }

    /// 빠른 추가 음식이 최근 음식만으로 15개를 채울 때 테스트
    func testGetQuickAddFoods_WithOnlyRecentFoods() async throws {
        // Given: 최근 음식 20개, 자주 사용하는 음식 없음
        let recentFoods = createSampleFoods(count: 20, prefix: "최근음식")
        mockFoodRepository.recentFoodsToReturn = recentFoods
        mockFoodRepository.frequentFoodsToReturn = []

        // When: 빠른 추가 음식 조회
        let result = try await sut.getQuickAddFoods(userId: testUserId)

        // Then: 최근 음식 10개만 반환 (getRecentFoods의 limit 적용)
        XCTAssertEqual(result.count, 10)
    }

    /// 빠른 추가 음식이 비어있을 때 빈 배열을 반환하는지 테스트
    func testGetQuickAddFoods_WithNoFoods_ReturnsEmptyArray() async throws {
        // Given: 최근 음식과 자주 사용하는 음식 모두 없음
        mockFoodRepository.recentFoodsToReturn = []
        mockFoodRepository.frequentFoodsToReturn = []

        // When: 빠른 추가 음식 조회
        let result = try await sut.getQuickAddFoods(userId: testUserId)

        // Then: 빈 배열 반환
        XCTAssertTrue(result.isEmpty, "음식이 없을 때는 빈 배열을 반환해야 합니다")
    }

    /// 빠른 추가 음식이 15개 미만일 때 모두 반환하는지 테스트
    func testGetQuickAddFoods_WithFewerThanMax_ReturnsAll() async throws {
        // Given: 최근 음식 3개, 자주 사용하는 음식 4개
        let recentFoods = createSampleFoods(count: 3, prefix: "최근음식")
        let frequentFoods = createSampleFoods(count: 4, prefix: "자주먹는음식")

        mockFoodRepository.recentFoodsToReturn = recentFoods
        mockFoodRepository.frequentFoodsToReturn = frequentFoods

        // When: 빠른 추가 음식 조회
        let result = try await sut.getQuickAddFoods(userId: testUserId)

        // Then: 7개 모두 반환
        XCTAssertEqual(result.count, 7, "음식이 15개 미만일 때는 모두 반환해야 합니다")
    }

    // MARK: - Custom Limits Tests

    /// 커스텀 limit 설정이 정상 작동하는지 테스트
    func testCustomLimits_ApplyCorrectly() async throws {
        // Given: 커스텀 limit로 서비스 생성
        let customService = RecentFoodsService(
            foodRepository: mockFoodRepository,
            maxRecentFoods: 5,
            maxFrequentFoods: 5,
            maxQuickAddFoods: 8
        )

        let recentFoods = createSampleFoods(count: 20, prefix: "최근음식")
        let frequentFoods = createSampleFoods(count: 20, prefix: "자주먹는음식")

        mockFoodRepository.recentFoodsToReturn = recentFoods
        mockFoodRepository.frequentFoodsToReturn = frequentFoods

        // When: 각 메서드 호출
        let recent = try await customService.getRecentFoods(userId: testUserId)
        let frequent = try await customService.getFrequentFoods(userId: testUserId)
        let quickAdd = try await customService.getQuickAddFoods(userId: testUserId)

        // Then: 커스텀 limit 적용 확인
        XCTAssertEqual(recent.count, 5, "커스텀 최근 음식 limit(5)이 적용되어야 합니다")
        XCTAssertEqual(frequent.count, 5, "커스텀 자주 사용 음식 limit(5)이 적용되어야 합니다")
        XCTAssertEqual(quickAdd.count, 8, "커스텀 빠른 추가 음식 limit(8)이 적용되어야 합니다")
    }

    // MARK: - Error Handling Tests

    /// Repository 에러가 전파되는지 테스트
    func testGetRecentFoods_PropagatesRepositoryError() async {
        // Given: Repository가 에러를 던지도록 설정
        mockFoodRepository.shouldThrowError = true

        // When & Then: 에러가 전파되어야 함
        do {
            _ = try await sut.getRecentFoods(userId: testUserId)
            XCTFail("에러가 발생해야 합니다")
        } catch {
            XCTAssertNotNil(error, "Repository 에러가 전파되어야 합니다")
        }
    }

    /// Repository 에러가 전파되는지 테스트 (자주 사용하는 음식)
    func testGetFrequentFoods_PropagatesRepositoryError() async {
        // Given: Repository가 에러를 던지도록 설정
        mockFoodRepository.shouldThrowError = true

        // When & Then: 에러가 전파되어야 함
        do {
            _ = try await sut.getFrequentFoods(userId: testUserId)
            XCTFail("에러가 발생해야 합니다")
        } catch {
            XCTAssertNotNil(error, "Repository 에러가 전파되어야 합니다")
        }
    }

    // MARK: - Helper Methods

    /// 테스트용 음식 목록 생성
    private func createSampleFoods(count: Int, prefix: String) -> [Food] {
        return (0..<count).map { index in
            createFood(name: "\(prefix)\(index)")
        }
    }

    /// 테스트용 음식 생성
    private func createFood(name: String) -> Food {
        return Food(
            id: UUID(),
            name: name,
            calories: 100,
            carbohydrates: Decimal(20),
            protein: Decimal(5),
            fat: Decimal(3),
            sodium: Decimal(100),
            fiber: nil,
            sugar: nil,
            servingSize: Decimal(100),
            servingUnit: "100g",
            source: .governmentAPI,
            apiCode: nil,
            createdByUserId: nil,
            createdAt: Date()
        )
    }
}

// MARK: - Mock Food Repository

/// 테스트용 Mock Food Repository
class MockFoodRepository: FoodRepositoryProtocol {

    // MARK: - Test Data

    var recentFoodsToReturn: [Food] = []
    var frequentFoodsToReturn: [Food] = []
    var shouldThrowError = false

    // MARK: - Call Tracking

    var getRecentFoodsCallCount = 0
    var lastGetRecentFoodsUserId: UUID?

    var getFrequentFoodsCallCount = 0
    var lastGetFrequentFoodsUserId: UUID?

    // MARK: - FoodRepositoryProtocol Implementation

    func save(_ food: Food) async throws -> Food {
        food
    }

    func findById(_ id: UUID) async throws -> Food? {
        nil
    }

    func findAll() async throws -> [Food] {
        []
    }

    func update(_ food: Food) async throws -> Food {
        food
    }

    func delete(_ id: UUID) async throws {
        // No-op
    }

    func search(name: String) async throws -> [Food] {
        []
    }

    func getRecentFoods(userId: UUID) async throws -> [Food] {
        getRecentFoodsCallCount += 1
        lastGetRecentFoodsUserId = userId

        if shouldThrowError {
            throw RepositoryError.notFound
        }

        return recentFoodsToReturn
    }

    func getFrequentFoods(userId: UUID) async throws -> [Food] {
        getFrequentFoodsCallCount += 1
        lastGetFrequentFoodsUserId = userId

        if shouldThrowError {
            throw RepositoryError.notFound
        }

        return frequentFoodsToReturn
    }

    func getUserDefinedFoods(userId: UUID) async throws -> [Food] {
        []
    }

    func findBySource(_ source: FoodSource) async throws -> [Food] {
        []
    }
}
