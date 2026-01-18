//
//  FoodLocalDataSource.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-13.
//

import Foundation
import CoreData

/// 식품 로컬 데이터 소스 구현체
final class FoodLocalDataSourceImpl: FoodLocalDataSource {

    // MARK: - Properties

    private let context: NSManagedObjectContext
    private let defaultMaxCacheSize = 500

    // MARK: - Initialization

    init(persistenceController: PersistenceController = .shared) {
        self.context = persistenceController.viewContext
    }

    // MARK: - FoodLocalDataSource Protocol Implementation

    /// 캐시에서 식품 검색
    func searchFoods(query: String, limit: Int) async throws -> [Food] {
        return try await context.perform {
            let request = Food.fetchByName(query, limit: limit)
            let foods = try self.context.fetch(request)

            #if DEBUG
            print("✅ [FoodLocalDataSource] Found \(foods.count) foods for query '\(query)'")
            #endif

            return foods
        }
    }

    /// 최근 검색한 식품 조회
    func getRecentFoods(limit: Int) async throws -> [Food] {
        return try await context.perform {
            let request = Food.fetchRecentFoods(limit: limit)
            let foods = try self.context.fetch(request)

            #if DEBUG
            print("✅ [FoodLocalDataSource] Retrieved \(foods.count) recent foods")
            #endif

            return foods
        }
    }

    /// 식품 저장 (중복 체크 포함)
    func saveFoods(_ foods: [Food]) async throws {
        guard !foods.isEmpty else {
            #if DEBUG
            print("ℹ️ [FoodLocalDataSource] No foods to save")
            #endif
            return
        }

        try await context.perform {
            var savedCount = 0

            for food in foods {
                // apiCode로 중복 체크
                if let apiCode = food.apiCode {
                    let request = Food.fetchRequestByApiCode(apiCode)
                    if let existing = try? self.context.fetch(request).first {
                        // 기존 데이터 업데이트
                        self.updateFood(existing, from: food)
                        continue
                    }
                }

                // 다른 컨텍스트의 Food인 경우 새로 생성
                if food.managedObjectContext != self.context {
                    let newFood = Food(context: self.context)
                    newFood.id = food.id ?? UUID()
                    newFood.name = food.name
                    newFood.calories = food.calories
                    newFood.carbohydrates = food.carbohydrates
                    newFood.protein = food.protein
                    newFood.fat = food.fat
                    newFood.sodium = food.sodium
                    newFood.fiber = food.fiber
                    newFood.sugar = food.sugar
                    newFood.servingSize = food.servingSize
                    newFood.servingUnit = food.servingUnit
                    newFood.source = food.source
                    newFood.apiCode = food.apiCode
                    newFood.createdAt = food.createdAt ?? Date()
                    newFood.lastAccessedAt = Date()
                    newFood.searchCount = 0
                    savedCount += 1
                } else {
                    // 같은 컨텍스트면 그대로 사용
                    food.lastAccessedAt = Date()
                    savedCount += 1
                }
            }

            if self.context.hasChanges {
                try self.context.save()
            }

            #if DEBUG
            print("✅ [FoodLocalDataSource] Saved \(savedCount) new foods (total: \(foods.count))")
            #endif
        }
    }

    /// 접근 시간 업데이트
    func updateAccessTime(foodId: UUID) async throws {
        try await context.perform {
            let request: NSFetchRequest<Food> = Food.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", foodId as CVarArg)
            request.fetchLimit = 1

            guard let food = try self.context.fetch(request).first else {
                #if DEBUG
                print("ℹ️ [FoodLocalDataSource] Food not found: \(foodId)")
                #endif
                return
            }

            food.updateAccessTime()

            if self.context.hasChanges {
                try self.context.save()
            }

            #if DEBUG
            print("✅ [FoodLocalDataSource] Updated access time for: \(food.name ?? "unknown")")
            #endif
        }
    }

    /// 오래된 캐시 정리
    func cleanupOldFoods(maxCount: Int) async throws {
        let targetMaxCount = maxCount > 0 ? maxCount : defaultMaxCacheSize

        try await context.perform {
            // 1단계: 만료된 캐시 삭제
            let expiredRequest = Food.fetchExpiredCache(days: 30)
            let expiredFoods = try self.context.fetch(expiredRequest)

            var deletedCount = 0
            for food in expiredFoods {
                self.context.delete(food)
                deletedCount += 1
            }

            #if DEBUG
            if deletedCount > 0 {
                print("🗑️ [FoodLocalDataSource] Deleted \(deletedCount) expired foods")
            }
            #endif

            // 2단계: LRU 기반 추가 정리
            let countRequest: NSFetchRequest<Food> = Food.fetchRequest()
            let totalCount = try self.context.count(for: countRequest)

            if totalCount > targetMaxCount {
                let excessCount = totalCount - targetMaxCount
                let oldestRequest: NSFetchRequest<Food> = Food.fetchRequest()
                oldestRequest.sortDescriptors = [NSSortDescriptor(key: "lastAccessedAt", ascending: true)]
                oldestRequest.fetchLimit = excessCount

                let oldestFoods = try self.context.fetch(oldestRequest)
                for food in oldestFoods {
                    self.context.delete(food)
                    deletedCount += 1
                }

                #if DEBUG
                print("🗑️ [FoodLocalDataSource] Deleted \(excessCount) oldest foods (LRU)")
                #endif
            }

            if self.context.hasChanges {
                try self.context.save()
            }

            #if DEBUG
            let finalCount = try self.context.count(for: countRequest)
            print("✅ [FoodLocalDataSource] Cache cleanup completed (deleted: \(deletedCount), remaining: \(finalCount))")
            #endif
        }
    }

    // MARK: - Private Helpers

    private func updateFood(_ existing: Food, from source: Food) {
        existing.name = source.name
        existing.calories = source.calories
        existing.carbohydrates = source.carbohydrates
        existing.protein = source.protein
        existing.fat = source.fat
        existing.sodium = source.sodium
        existing.fiber = source.fiber
        existing.sugar = source.sugar
        existing.servingSize = source.servingSize
        existing.servingUnit = source.servingUnit
        existing.lastAccessedAt = Date()
    }
}

// MARK: - FoodLocalDataSource Error

enum FoodLocalDataSourceError: Error {
    case fetchFailed(Error)
    case saveFailed(Error)
    case updateFailed(Error)
    case deleteFailed(Error)
    case conversionFailed(String)

    var localizedDescription: String {
        switch self {
        case .fetchFailed(let error):
            return "캐시 조회에 실패했습니다: \(error.localizedDescription)"
        case .saveFailed(let error):
            return "캐시 저장에 실패했습니다: \(error.localizedDescription)"
        case .updateFailed(let error):
            return "캐시 업데이트에 실패했습니다: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "캐시 삭제에 실패했습니다: \(error.localizedDescription)"
        case .conversionFailed(let message):
            return "데이터 변환에 실패했습니다: \(message)"
        }
    }
}

// MARK: - Testing Support

#if DEBUG
/// 테스트용 Mock FoodLocalDataSource
final class MockFoodLocalDataSource: FoodLocalDataSource {

    private var mockFoods: [Food] = []
    var shouldThrowError: Error?
    var searchCallCount = 0
    var getRecentCallCount = 0
    var saveCallCount = 0
    var updateAccessTimeCallCount = 0
    var cleanupCallCount = 0

    func searchFoods(query: String, limit: Int) async throws -> [Food] {
        searchCallCount += 1
        if let error = shouldThrowError { throw error }

        let results = mockFoods.filter { food in
            food.name?.localizedCaseInsensitiveContains(query) ?? false
        }
        return Array(results.prefix(limit))
    }

    func getRecentFoods(limit: Int) async throws -> [Food] {
        getRecentCallCount += 1
        if let error = shouldThrowError { throw error }
        return Array(mockFoods.prefix(limit))
    }

    func saveFoods(_ foods: [Food]) async throws {
        saveCallCount += 1
        if let error = shouldThrowError { throw error }
        // Mock: 실제 저장하지 않음
    }

    func updateAccessTime(foodId: UUID) async throws {
        updateAccessTimeCallCount += 1
        if let error = shouldThrowError { throw error }
    }

    func cleanupOldFoods(maxCount: Int) async throws {
        cleanupCallCount += 1
        if let error = shouldThrowError { throw error }
    }

    func reset() {
        mockFoods.removeAll()
        shouldThrowError = nil
        searchCallCount = 0
        getRecentCallCount = 0
        saveCallCount = 0
        updateAccessTimeCallCount = 0
        cleanupCallCount = 0
    }

    func addMockFood(_ food: Food) {
        mockFoods.append(food)
    }
}
#endif
