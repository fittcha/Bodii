//
//  RecentFoodsService.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-13.
//

import Foundation

/// 최근/자주 사용한 음식을 관리하는 서비스 구현
///
/// RecentFoodsServiceProtocol을 구현하여 빠른 추가 기능을 위한
/// 최근 사용 음식과 자주 사용하는 음식을 제공합니다.
///
/// - Note: 모든 작업은 비동기로 수행되며 Swift Concurrency를 사용합니다.
/// - Note: FoodRepository의 getRecentFoods와 getFrequentFoods를 래핑하여
///         빠른 추가 UI에 최적화된 결과를 제공합니다.
///
/// - Example:
/// ```swift
/// let service = RecentFoodsService(foodRepository: foodRepository)
/// let recentFoods = try await service.getRecentFoods(userId: userId)
/// // 최근 30일 이내 사용한 음식 최대 10개
/// ```
final class RecentFoodsService: RecentFoodsServiceProtocol {

    // MARK: - Properties

    /// Food Repository
    private let foodRepository: FoodRepositoryProtocol

    /// 최근 음식 최대 개수
    private let maxRecentFoods: Int

    /// 자주 사용하는 음식 최대 개수
    private let maxFrequentFoods: Int

    /// 빠른 추가 음식 최대 개수
    private let maxQuickAddFoods: Int

    // MARK: - Initialization

    /// RecentFoodsService를 초기화합니다.
    ///
    /// - Parameters:
    ///   - foodRepository: Food Repository
    ///   - maxRecentFoods: 최근 음식 최대 개수 (기본값: 10)
    ///   - maxFrequentFoods: 자주 사용하는 음식 최대 개수 (기본값: 10)
    ///   - maxQuickAddFoods: 빠른 추가 음식 최대 개수 (기본값: 15)
    init(
        foodRepository: FoodRepositoryProtocol,
        maxRecentFoods: Int = 10,
        maxFrequentFoods: Int = 10,
        maxQuickAddFoods: Int = 15
    ) {
        self.foodRepository = foodRepository
        self.maxRecentFoods = maxRecentFoods
        self.maxFrequentFoods = maxFrequentFoods
        self.maxQuickAddFoods = maxQuickAddFoods
    }

    // MARK: - Recent Foods

    func getRecentFoods(userId: UUID) async throws -> [Food] {
        // FoodRepository에서 최근 사용 음식 조회
        let recentFoods = try await foodRepository.getRecentFoods(userId: userId)

        // 최대 개수로 제한
        return Array(recentFoods.prefix(maxRecentFoods))
    }

    func getFrequentFoods(userId: UUID) async throws -> [Food] {
        // FoodRepository에서 자주 사용하는 음식 조회
        let frequentFoods = try await foodRepository.getFrequentFoods(userId: userId)

        // 최대 개수로 제한
        return Array(frequentFoods.prefix(maxFrequentFoods))
    }

    func getQuickAddFoods(userId: UUID) async throws -> [Food] {
        // 최근 사용 음식과 자주 사용하는 음식을 병렬로 조회
        async let recentFoods = getRecentFoods(userId: userId)
        async let frequentFoods = getFrequentFoods(userId: userId)

        let recent = try await recentFoods
        let frequent = try await frequentFoods

        // 최근 사용 음식을 우선적으로 추가
        var result = recent
        var seenIds = Set(recent.map { $0.id })

        // 자주 사용하는 음식 중 중복되지 않은 것 추가
        for food in frequent {
            // 이미 결과에 포함되어 있으면 건너뜀
            if seenIds.contains(food.id) {
                continue
            }

            result.append(food)
            seenIds.insert(food.id)

            // 최대 개수에 도달하면 중단
            if result.count >= maxQuickAddFoods {
                break
            }
        }

        return result
    }
}
