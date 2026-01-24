//
//  MockFoodLocalDataSource.swift
//  BodiiTests
//
//  Created by Auto-Claude on 2026-01-13.
//

// 📚 학습 포인트: Mock Data Source for Unit Testing
// 테스트에서 실제 Core Data 없이 동작을 검증할 수 있는 Mock 객체
// 💡 Java 비교: Mockito의 @Mock 어노테이션 + in-memory repository

import Foundation
@testable import Bodii

/// 테스트용 Mock Food Local Data Source
///
/// 📚 학습 포인트: In-Memory Mock Repository
/// Core Data 없이 메모리 내에서 CRUD 작업을 시뮬레이션합니다
/// - Success/Failure 시나리오
/// - 지연 시뮬레이션
/// - 호출 추적
/// 💡 Java 비교: H2 in-memory database 또는 HashMap 기반 mock repository
///
/// **주요 기능:**
/// - 메모리 기반 식품 저장소
/// - 실제 검색/필터링 로직 구현
/// - 에러 시나리오 시뮬레이션
/// - 호출 횟수 추적
///
/// **사용 예시:**
/// ```swift
/// let mockDataSource = MockFoodLocalDataSource()
///
/// // 식품 저장
/// let food = Food(...)
/// try await mockDataSource.saveFoods([food])
///
/// // 식품 검색
/// let results = try await mockDataSource.searchFoods(query: "김치", limit: 10)
///
/// // 에러 시나리오
/// mockDataSource.shouldThrowError = FoodLocalDataSourceError.saveFailed(...)
/// do {
///     try await mockDataSource.saveFoods([food])
/// } catch {
///     // 에러 처리 테스트
/// }
/// ```
final class MockFoodLocalDataSource: FoodLocalDataSource {

    // MARK: - Mock Configuration

    /// Mock 저장소 (in-memory)
    ///
    /// 📚 학습 포인트: In-Memory Storage
    /// 실제 Core Data 대신 Dictionary를 사용하여 데이터 저장
    /// 💡 Java 비교: HashMap<UUID, Food>
    private var mockStorage: [UUID: Food] = [:]

    /// 에러 시뮬레이션
    ///
    /// 📚 학습 포인트: Error Simulation
    /// nil이 아닌 경우 항상 해당 에러를 throw
    /// 💡 Java 비교: Mockito.when().thenThrow()
    var shouldThrowError: Error?

    /// 작업 지연 시뮬레이션 (초)
    ///
    /// 📚 학습 포인트: Delay Simulation
    /// Core Data의 I/O 지연을 시뮬레이션
    /// 💡 0.0 = 지연 없음, 0.1 = 100ms 지연
    var simulatedDelay: TimeInterval = 0.0

    // MARK: - Call Tracking

    /// 호출 횟수 추적: searchFoods()
    ///
    /// 📚 학습 포인트: Call Tracking
    /// 메서드가 몇 번 호출되었는지 추적하여 테스트 검증
    /// 💡 Java 비교: Mockito.verify(mock, times(n))
    var searchCallCount = 0

    /// 호출 횟수 추적: getRecentFoods()
    var getRecentCallCount = 0

    /// 호출 횟수 추적: saveFoods()
    var saveCallCount = 0

    /// 호출 횟수 추적: updateAccessTime()
    var updateAccessTimeCallCount = 0

    /// 호출 횟수 추적: cleanupOldFoods()
    var cleanupCallCount = 0

    /// 마지막 검색 쿼리
    ///
    /// 📚 학습 포인트: Argument Capture
    /// 메서드 호출 시 전달된 인자를 캡처하여 검증
    /// 💡 Java 비교: ArgumentCaptor
    var lastSearchQuery: String?

    /// 마지막 limit 값
    var lastLimit: Int?

    /// 마지막 저장한 식품 목록
    var lastSavedFoods: [Food]?

    /// 마지막 업데이트한 식품 ID
    var lastUpdatedFoodId: UUID?

    /// 마지막 cleanup maxCount 값
    var lastCleanupMaxCount: Int?

    // MARK: - FoodLocalDataSource Protocol Implementation

    /// 캐시에서 식품 검색
    ///
    /// 📚 학습 포인트: In-Memory Search
    /// 실제 검색 로직을 구현하여 현실적인 테스트 가능
    ///
    /// - Parameters:
    ///   - query: 검색어
    ///   - limit: 최대 결과 개수
    ///
    /// - Returns: 검색 결과 (이름에 query가 포함된 식품)
    ///
    /// - Throws: shouldThrowError가 설정된 경우 해당 에러
    func searchFoods(query: String, limit: Int) async throws -> [Food] {
        // 호출 추적
        searchCallCount += 1
        lastSearchQuery = query
        lastLimit = limit

        // 작업 지연 시뮬레이션
        if simulatedDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(simulatedDelay * 1_000_000_000))
        }

        // 에러 시뮬레이션
        if let error = shouldThrowError {
            throw error
        }

        // 이름에 검색어가 포함된 식품 필터링
        let results = mockStorage.values.filter { food in
            food.name.localizedCaseInsensitiveContains(query)
        }

        // limit 적용 및 반환
        return Array(results.prefix(limit))
    }

    /// 최근 검색한 식품 조회
    ///
    /// 📚 학습 포인트: LRU Cache Simulation
    /// 실제 LRU 정렬은 하지 않지만, 저장된 식품을 반환
    ///
    /// - Parameter limit: 최대 결과 개수
    ///
    /// - Returns: 최근 식품 목록
    ///
    /// - Throws: shouldThrowError가 설정된 경우 해당 에러
    func getRecentFoods(limit: Int) async throws -> [Food] {
        // 호출 추적
        getRecentCallCount += 1
        lastLimit = limit

        // 작업 지연 시뮬레이션
        if simulatedDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(simulatedDelay * 1_000_000_000))
        }

        // 에러 시뮬레이션
        if let error = shouldThrowError {
            throw error
        }

        // Mock: 저장된 식품 반환 (실제로는 LRU 정렬 필요)
        return Array(mockStorage.values.prefix(limit))
    }

    /// 식품 저장
    ///
    /// 📚 학습 포인트: In-Memory Save
    /// Dictionary에 식품 추가/업데이트 (upsert 동작)
    ///
    /// - Parameter foods: 저장할 식품 목록
    ///
    /// - Throws: shouldThrowError가 설정된 경우 해당 에러
    func saveFoods(_ foods: [Food]) async throws {
        // 호출 추적
        saveCallCount += 1
        lastSavedFoods = foods

        // 작업 지연 시뮬레이션
        if simulatedDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(simulatedDelay * 1_000_000_000))
        }

        // 에러 시뮬레이션
        if let error = shouldThrowError {
            throw error
        }

        // Mock 저장소에 추가 (upsert)
        for food in foods {
            mockStorage[food.id] = food
        }
    }

    /// 접근 시간 업데이트
    ///
    /// 📚 학습 포인트: LRU Tracking
    /// Mock에서는 실제 업데이트하지 않지만, 호출 추적은 수행
    ///
    /// - Parameter foodId: 업데이트할 식품 ID
    ///
    /// - Throws: shouldThrowError가 설정된 경우 해당 에러
    func updateAccessTime(foodId: UUID) async throws {
        // 호출 추적
        updateAccessTimeCallCount += 1
        lastUpdatedFoodId = foodId

        // 작업 지연 시뮬레이션
        if simulatedDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(simulatedDelay * 1_000_000_000))
        }

        // 에러 시뮬레이션
        if let error = shouldThrowError {
            throw error
        }

        // Mock: 실제로는 lastAccessedAt 업데이트 필요
        // 여기서는 단순히 호출 추적만 수행
    }

    /// 오래된 캐시 정리
    ///
    /// 📚 학습 포인트: Cache Eviction
    /// 저장소 크기가 maxCount를 초과하면 오래된 항목 삭제
    ///
    /// - Parameter maxCount: 최대 캐시 크기
    ///
    /// - Throws: shouldThrowError가 설정된 경우 해당 에러
    func cleanupOldFoods(maxCount: Int) async throws {
        // 호출 추적
        cleanupCallCount += 1
        lastCleanupMaxCount = maxCount

        // 작업 지연 시뮬레이션
        if simulatedDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(simulatedDelay * 1_000_000_000))
        }

        // 에러 시뮬레이션
        if let error = shouldThrowError {
            throw error
        }

        // Mock: 초과분 삭제 (LRU 기반으로 해야 하지만, 여기서는 단순 삭제)
        if mockStorage.count > maxCount {
            let excessCount = mockStorage.count - maxCount
            let keysToRemove = Array(mockStorage.keys.prefix(excessCount))
            for key in keysToRemove {
                mockStorage.removeValue(forKey: key)
            }
        }
    }

    // MARK: - Test Helpers

    /// Mock 상태 초기화
    ///
    /// 📚 학습 포인트: Test Setup/Teardown
    /// 각 테스트 전후에 호출하여 Mock 상태를 깨끗하게 유지
    /// 💡 Java 비교: @Before, @After 어노테이션
    ///
    /// **사용 예시:**
    /// ```swift
    /// class MyTests: XCTestCase {
    ///     var mockDataSource: MockFoodLocalDataSource!
    ///
    ///     override func setUp() {
    ///         super.setUp()
    ///         mockDataSource = MockFoodLocalDataSource()
    ///     }
    ///
    ///     override func tearDown() {
    ///         mockDataSource.reset()
    ///         super.tearDown()
    ///     }
    /// }
    /// ```
    func reset() {
        mockStorage.removeAll()
        shouldThrowError = nil
        simulatedDelay = 0.0
        searchCallCount = 0
        getRecentCallCount = 0
        saveCallCount = 0
        updateAccessTimeCallCount = 0
        cleanupCallCount = 0
        lastSearchQuery = nil
        lastLimit = nil
        lastSavedFoods = nil
        lastUpdatedFoodId = nil
        lastCleanupMaxCount = nil
    }

    /// 테스트 헬퍼: Mock 저장소에 식품 추가
    ///
    /// 📚 학습 포인트: Test Data Setup
    /// 테스트 시작 전에 초기 데이터를 쉽게 설정
    /// 💡 Java 비교: @BeforeEach에서 데이터 준비
    ///
    /// - Parameter food: 추가할 식품
    ///
    /// **사용 예시:**
    /// ```swift
    /// override func setUp() {
    ///     super.setUp()
    ///     mockDataSource = MockFoodLocalDataSource()
    ///
    ///     // 테스트 데이터 추가
    ///     let food = Food(name: "김치", calories: 50, ...)
    ///     mockDataSource.addMockFood(food)
    /// }
    /// ```
    func addMockFood(_ food: Food) {
        mockStorage[food.id] = food
    }

    /// 테스트 헬퍼: Mock 저장소에 여러 식품 추가
    ///
    /// - Parameter foods: 추가할 식품 목록
    func addMockFoods(_ foods: [Food]) {
        for food in foods {
            mockStorage[food.id] = food
        }
    }

    /// 테스트 헬퍼: 저장소 크기 조회
    ///
    /// 📚 학습 포인트: Test Assertion Helper
    /// 테스트에서 저장소 상태를 검증할 때 사용
    ///
    /// - Returns: 저장된 식품 개수
    func storageCount() -> Int {
        return mockStorage.count
    }

    /// 테스트 헬퍼: 특정 식품이 저장소에 있는지 확인
    ///
    /// - Parameter foodId: 확인할 식품 ID
    ///
    /// - Returns: 저장 여부
    func contains(foodId: UUID) -> Bool {
        return mockStorage[foodId] != nil
    }

    /// 테스트 헬퍼: 특정 ID의 식품 조회
    ///
    /// - Parameter foodId: 조회할 식품 ID
    ///
    /// - Returns: 식품 (없으면 nil)
    func getFood(id: UUID) -> Food? {
        return mockStorage[id]
    }

    /// 테스트 헬퍼: Sample 식품 생성
    ///
    /// 📚 학습 포인트: Test Data Builder
    /// 테스트용 샘플 식품을 쉽게 생성
    /// 💡 Java 비교: Builder 패턴 또는 ObjectMother 패턴
    ///
    /// - Parameters:
    ///   - name: 식품명
    ///   - calories: 칼로리
    ///   - source: 식품 소스
    ///
    /// - Returns: 샘플 Food 엔티티
    static func createSampleFood(
        name: String = "김치찌개",
        calories: Int32 = 50,
        source: FoodSource = .governmentAPI
    ) -> Food {
        return Food(
            name: name,
            calories: calories,
            carbohydrates: Decimal(7.8),
            protein: Decimal(3.5),
            fat: Decimal(1.2),
            servingSize: Decimal(210.0),
            servingUnit: "g",
            source: source,
            sodium: 450,
            fiber: Decimal(1.5),
            sugar: Decimal(2.3),
            apiCode: nil,
            createdByUserId: nil,
            createdAt: Date()
        )
    }
}
