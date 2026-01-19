//
//  LocalFoodSearchService.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-13.
//

import Foundation

/// 로컬에 저장된 음식을 검색하는 서비스 구현
///
/// FoodSearchServiceProtocol을 구현하여 음식 검색, 정렬, 필터링 기능을 제공합니다.
/// 검색 결과는 한국 음식 우선 및 사용 빈도를 고려하여 정렬됩니다.
///
/// - Note: 모든 작업은 비동기로 수행되며 Swift Concurrency를 사용합니다.
/// - Note: 한국 음식(governmentAPI 출처)을 우선적으로 표시합니다.
///
/// - Example:
/// ```swift
/// let service = LocalFoodSearchService(foodRepository: foodRepository)
/// let results = try await service.searchFoods(query: "닭가슴살", userId: userId)
/// // 결과: 한국 음식 중 자주 사용하는 음식 -> 한국 음식 -> 기타 음식
/// ```
final class LocalFoodSearchService: FoodSearchServiceProtocol {

    // MARK: - Properties

    /// Food Repository
    private let foodRepository: FoodRepositoryProtocol

    // MARK: - Initialization

    /// LocalFoodSearchService를 초기화합니다.
    ///
    /// - Parameter foodRepository: Food Repository
    init(foodRepository: FoodRepositoryProtocol) {
        self.foodRepository = foodRepository
    }

    // MARK: - Search Operations

    func searchFoods(query: String, userId: UUID) async throws -> [Food] {
        // 빈 검색어는 빈 배열 반환
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }

        // 1. 검색어로 음식 검색
        let searchResults = try await foodRepository.search(name: query)

        // 빈 결과는 즉시 반환
        guard !searchResults.isEmpty else {
            return []
        }

        // 2. 사용자의 자주 사용하는 음식 목록 조회
        let frequentFoods = try await foodRepository.getFrequentFoods(userId: userId)
        let frequentFoodIds = Set(frequentFoods.compactMap { $0.id })

        // 3. 검색 결과를 우선순위에 따라 정렬
        let sortedResults = sortByPriority(
            foods: searchResults,
            frequentFoodIds: frequentFoodIds
        )

        return sortedResults
    }

    func getRecentFoods(userId: UUID) async throws -> [Food] {
        let recentFoods = try await foodRepository.getRecentFoods(userId: userId)

        // 최대 10개로 제한
        return Array(recentFoods.prefix(10))
    }

    func getFrequentFoods(userId: UUID) async throws -> [Food] {
        let frequentFoods = try await foodRepository.getFrequentFoods(userId: userId)

        // 최대 10개로 제한
        return Array(frequentFoods.prefix(10))
    }

    // MARK: - Private Helpers

    /// 검색 결과를 우선순위에 따라 정렬합니다.
    ///
    /// 정렬 우선순위:
    /// 1. 한국 음식(governmentAPI) 중 자주 사용하는 음식
    /// 2. 한국 음식(governmentAPI) 중 나머지
    /// 3. 기타 출처의 자주 사용하는 음식
    /// 4. 기타 출처의 나머지 음식
    ///
    /// - Parameters:
    ///   - foods: 정렬할 음식 목록
    ///   - frequentFoodIds: 자주 사용하는 음식의 ID 집합
    /// - Returns: 정렬된 음식 목록
    private func sortByPriority(foods: [Food], frequentFoodIds: Set<UUID>) -> [Food] {
        return foods.sorted { food1, food2 in
            let priority1 = calculatePriority(food: food1, frequentFoodIds: frequentFoodIds)
            let priority2 = calculatePriority(food: food2, frequentFoodIds: frequentFoodIds)

            // 우선순위가 다르면 우선순위 순으로 정렬
            if priority1 != priority2 {
                return priority1 < priority2
            }

            // 우선순위가 같으면 이름 순으로 정렬 (가나다순)
            return (food1.name ?? "") < (food2.name ?? "")
        }
    }

    /// 음식의 우선순위 값을 계산합니다.
    ///
    /// 낮은 숫자가 높은 우선순위를 의미합니다.
    ///
    /// - Parameters:
    ///   - food: 우선순위를 계산할 음식
    ///   - frequentFoodIds: 자주 사용하는 음식의 ID 집합
    /// - Returns: 우선순위 값 (1: 한국 음식 + 자주 사용, 2: 한국 음식, 3: 기타 + 자주 사용, 4: 기타)
    private func calculatePriority(food: Food, frequentFoodIds: Set<UUID>) -> Int {
        let isKoreanFood = food.source == FoodSource.governmentAPI.rawValue
        let isFrequent = food.id.map { frequentFoodIds.contains($0) } ?? false

        switch (isKoreanFood, isFrequent) {
        case (true, true):   return 1  // 한국 음식 + 자주 사용
        case (true, false):  return 2  // 한국 음식
        case (false, true):  return 3  // 기타 + 자주 사용
        case (false, false): return 4  // 기타
        }
    }
}
