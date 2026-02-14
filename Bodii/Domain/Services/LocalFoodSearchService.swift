//
//  LocalFoodSearchService.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-13.
//

import Foundation

/// 음식 검색 서비스 (로컬 DB 우선 + API 폴백)
///
/// FoodSearchServiceProtocol을 구현하여 음식 검색, 정렬, 필터링 기능을 제공합니다.
/// 로컬 DB를 먼저 검색하고, 결과가 부족하면 API를 호출하여 보충합니다.
/// API 결과는 자동으로 로컬 DB에 캐시되어 다음 검색 시 빠르게 반환됩니다.
///
/// - Note: 모든 작업은 비동기로 수행되며 Swift Concurrency를 사용합니다.
/// - Note: 한국 음식(governmentAPI 출처)을 우선적으로 표시합니다.
final class LocalFoodSearchService: FoodSearchServiceProtocol {

    // MARK: - Properties

    /// Food Repository (로컬 DB 검색)
    private let foodRepository: FoodRepositoryProtocol

    /// API 검색 서비스 (KFDA + USDA, 로컬 결과 부족 시 폴백)
    private let apiSearchService: UnifiedFoodSearchService?

    /// 로컬 캐시 데이터 소스 (API 결과 저장용)
    private let cacheDataSource: FoodLocalDataSource?

    /// 로컬 검색 최소 결과 수 (이 수보다 적으면 API 호출)
    private let minimumLocalResults: Int

    // MARK: - Initialization

    /// LocalFoodSearchService를 초기화합니다.
    ///
    /// - Parameters:
    ///   - foodRepository: Food Repository (로컬 DB 검색)
    ///   - apiSearchService: API 검색 서비스 (nil이면 로컬 전용)
    ///   - cacheDataSource: 캐시 데이터 소스 (nil이면 캐싱 비활성화)
    ///   - minimumLocalResults: API 폴백 트리거 기준 (기본값: 5)
    init(
        foodRepository: FoodRepositoryProtocol,
        apiSearchService: UnifiedFoodSearchService? = nil,
        cacheDataSource: FoodLocalDataSource? = nil,
        minimumLocalResults: Int = 5
    ) {
        self.foodRepository = foodRepository
        self.apiSearchService = apiSearchService
        self.cacheDataSource = cacheDataSource
        self.minimumLocalResults = minimumLocalResults
    }

    // MARK: - Search Operations

    func searchFoods(query: String, userId: UUID) async throws -> [Food] {
        // 빈 검색어는 빈 배열 반환
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }

        // Phase 1: 로컬 DB 검색 (빠름, 네트워크 불필요)
        let localResults = try await foodRepository.search(name: query)

        #if DEBUG
        print("[LocalFoodSearchService] 로컬 검색 결과: \(localResults.count)개 ('\(query)')")
        #endif

        // Phase 2: 로컬 결과가 충분하면 API 호출 생략
        var combinedResults = localResults

        if localResults.count < minimumLocalResults, let apiService = apiSearchService {
            #if DEBUG
            print("[LocalFoodSearchService] 로컬 결과 부족 (\(localResults.count) < \(minimumLocalResults)), API 폴백 시작")
            #endif

            do {
                let apiResults = try await apiService.searchFoods(
                    query: query,
                    limit: 20,
                    offset: 0
                )

                // 중복 제거: 로컬에 이미 있는 결과 제외 (apiCode 또는 name 기준)
                let localApiCodes = Set(localResults.compactMap { $0.apiCode })
                let localNames = Set(localResults.compactMap { $0.name })

                let newApiResults = apiResults.filter { food in
                    if let apiCode = food.apiCode, localApiCodes.contains(apiCode) {
                        return false
                    }
                    if let name = food.name, localNames.contains(name) {
                        return false
                    }
                    return true
                }

                combinedResults = localResults + newApiResults

                #if DEBUG
                print("[LocalFoodSearchService] API 결과: \(apiResults.count)개, 신규: \(newApiResults.count)개, 합계: \(combinedResults.count)개")
                #endif

                // Phase 3: API 결과를 로컬 DB에 캐시 (백그라운드, fire-and-forget)
                if !newApiResults.isEmpty, let cache = cacheDataSource {
                    Task {
                        do {
                            try await cache.saveFoods(newApiResults)
                            #if DEBUG
                            print("[LocalFoodSearchService] \(newApiResults.count)개 음식 캐시 저장 완료")
                            #endif
                        } catch {
                            #if DEBUG
                            print("[LocalFoodSearchService] 캐시 저장 실패: \(error.localizedDescription)")
                            #endif
                        }
                    }
                }
            } catch {
                // API 실패 시 로컬 결과만 반환 (graceful degradation)
                #if DEBUG
                print("[LocalFoodSearchService] API 폴백 실패: \(error.localizedDescription). 로컬 결과만 반환")
                #endif
            }
        }

        // 결과 없으면 빈 배열 반환
        guard !combinedResults.isEmpty else {
            return []
        }

        // Phase 4: 사용자의 자주 사용하는 음식 목록 조회 + 우선순위 정렬
        let frequentFoods = try await foodRepository.getFrequentFoods(userId: userId)
        let frequentFoodIds = Set(frequentFoods.compactMap { $0.id })

        let sortedResults = sortByPriority(
            foods: combinedResults,
            frequentFoodIds: frequentFoodIds
        )

        return sortedResults
    }

    func getRecentFoods(userId: UUID) async throws -> [Food] {
        let recentFoods = try await foodRepository.getRecentFoods(userId: userId)

        // 최대 20개로 제한
        return Array(recentFoods.prefix(20))
    }

    func getFrequentFoods(userId: UUID) async throws -> [Food] {
        let frequentFoods = try await foodRepository.getFrequentFoods(userId: userId)

        // 최대 20개로 제한
        return Array(frequentFoods.prefix(20))
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

            // 우선순위가 같으면 기존 순서 유지 (FoodRepository의 연관성 정렬 보존)
            return false
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
