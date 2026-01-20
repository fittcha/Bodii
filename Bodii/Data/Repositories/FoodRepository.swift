//
//  FoodRepository.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-13.
//

import Foundation
import CoreData

/// Food 엔티티에 대한 Core Data Repository 구현
///
/// FoodRepositoryProtocol을 구현하여 음식 데이터의 CRUD 및 검색 기능을 제공합니다.
///
/// - Note: Core Data의 NSManagedObjectContext를 사용하여 데이터를 관리합니다.
/// - Note: 모든 작업은 비동기로 수행되며 Swift Concurrency를 사용합니다.
///
/// - Example:
/// ```swift
/// let repository = FoodRepository(context: persistenceController.viewContext)
/// let food = Food(
///     id: UUID(),
///     name: "닭가슴살",
///     calories: 165,
///     carbohydrates: 0,
///     protein: 31,
///     fat: 3.6,
///     sodium: 74,
///     fiber: nil,
///     sugar: nil,
///     servingSize: 100,
///     servingUnit: "100g",
///     source: .governmentAPI,
///     apiCode: "D000001",
///     createdByUserId: nil,
///     createdAt: Date()
/// )
/// try await repository.save(food)
/// ```
final class FoodRepository: FoodRepositoryProtocol {

    // MARK: - Properties

    /// Core Data managed object context
    private let context: NSManagedObjectContext

    // MARK: - Initialization

    /// FoodRepository를 초기화합니다.
    ///
    /// - Parameter context: Core Data managed object context
    init(context: NSManagedObjectContext) {
        self.context = context
    }

    // MARK: - CRUD Operations

    func save(_ food: Food) async throws -> Food {
        try await context.perform { [weak self] in
            guard let self = self else {
                throw FoodRepositoryError.contextDeallocated
            }

            // Food가 이미 Core Data entity이면 직접 저장
            if food.managedObjectContext == self.context {
                try self.context.save()
                return food
            }

            // 다른 context에서 온 경우 새로 생성하여 복사
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

            // createdByUser relationship 설정
            if let createdByUser = food.createdByUser {
                newFood.createdByUser = createdByUser
            }

            try self.context.save()

            return newFood
        }
    }

    func findById(_ id: UUID) async throws -> Food? {
        try await context.perform { [weak self] in
            guard let self = self else {
                throw FoodRepositoryError.contextDeallocated
            }

            let fetchRequest: NSFetchRequest<Food> = Food.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            fetchRequest.fetchLimit = 1

            let results = try self.context.fetch(fetchRequest)

            return results.first
        }
    }

    func findAll() async throws -> [Food] {
        try await context.perform { [weak self] in
            guard let self = self else {
                throw FoodRepositoryError.contextDeallocated
            }

            let fetchRequest: NSFetchRequest<Food> = Food.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]

            return try self.context.fetch(fetchRequest)
        }
    }

    func update(_ food: Food) async throws -> Food {
        try await context.perform { [weak self] in
            guard let self = self else {
                throw FoodRepositoryError.contextDeallocated
            }

            guard let foodId = food.id else {
                throw FoodRepositoryError.invalidData
            }

            // food가 같은 context의 엔티티라면 직접 저장
            if food.managedObjectContext == self.context {
                try self.context.save()
                return food
            }

            // 다른 context에서 온 경우 fetch하여 업데이트
            let fetchRequest: NSFetchRequest<Food> = Food.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", foodId as CVarArg)
            fetchRequest.fetchLimit = 1

            let results = try self.context.fetch(fetchRequest)

            guard let existingFood = results.first else {
                throw FoodRepositoryError.notFound
            }

            // 값 복사
            existingFood.name = food.name
            existingFood.calories = food.calories
            existingFood.carbohydrates = food.carbohydrates
            existingFood.protein = food.protein
            existingFood.fat = food.fat
            existingFood.sodium = food.sodium
            existingFood.fiber = food.fiber
            existingFood.sugar = food.sugar
            existingFood.servingSize = food.servingSize
            existingFood.servingUnit = food.servingUnit
            existingFood.source = food.source
            existingFood.apiCode = food.apiCode

            try self.context.save()

            return existingFood
        }
    }

    func delete(_ id: UUID) async throws {
        try await context.perform { [weak self] in
            guard let self = self else {
                throw FoodRepositoryError.contextDeallocated
            }

            let fetchRequest: NSFetchRequest<Food> = Food.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            fetchRequest.fetchLimit = 1

            let results = try self.context.fetch(fetchRequest)

            guard let food = results.first else {
                throw FoodRepositoryError.notFound
            }

            self.context.delete(food)
            try self.context.save()
        }
    }

    // MARK: - Search Operations

    func search(name: String) async throws -> [Food] {
        try await context.perform { [weak self] in
            guard let self = self else {
                throw FoodRepositoryError.contextDeallocated
            }

            let fetchRequest: NSFetchRequest<Food> = Food.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "name CONTAINS[cd] %@", name)
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]

            return try self.context.fetch(fetchRequest)
        }
    }

    // MARK: - Recent & Frequent Foods

    func getRecentFoods(userId: UUID) async throws -> [Food] {
        try await context.perform { [weak self] in
            guard let self = self else {
                throw FoodRepositoryError.contextDeallocated
            }

            // 최근 30일 기준 날짜 계산
            let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()

            // FoodRecord를 통해 최근 사용된 음식 조회
            let fetchRequest: NSFetchRequest<FoodRecord> = FoodRecord.fetchRequest()
            fetchRequest.predicate = NSPredicate(
                format: "user.id == %@ AND date >= %@",
                userId as CVarArg,
                thirtyDaysAgo as CVarArg
            )
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]

            let foodRecords = try self.context.fetch(fetchRequest)

            // 중복 제거하면서 음식 추출
            var seenFoodIds = Set<UUID>()
            var recentFoods: [Food] = []

            for record in foodRecords {
                guard let food = record.food,
                      let foodId = food.id else {
                    continue
                }

                // 이미 추가된 음식은 건너뜀
                if seenFoodIds.contains(foodId) {
                    continue
                }

                recentFoods.append(food)
                seenFoodIds.insert(foodId)
            }

            return recentFoods
        }
    }

    func getFrequentFoods(userId: UUID) async throws -> [Food] {
        try await context.perform { [weak self] in
            guard let self = self else {
                throw FoodRepositoryError.contextDeallocated
            }

            // FoodRecord를 통해 음식별 사용 횟수 집계
            let fetchRequest: NSFetchRequest<FoodRecord> = FoodRecord.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "user.id == %@", userId as CVarArg)

            let foodRecords = try self.context.fetch(fetchRequest)

            // 음식별 사용 횟수 집계
            var foodUsageCount: [UUID: (food: Food, count: Int)] = [:]

            for record in foodRecords {
                guard let food = record.food,
                      let foodId = food.id else {
                    continue
                }

                if let existing = foodUsageCount[foodId] {
                    foodUsageCount[foodId] = (food: existing.food, count: existing.count + 1)
                } else {
                    foodUsageCount[foodId] = (food: food, count: 1)
                }
            }

            // 사용 횟수 내림차순으로 정렬하고 상위 20개 추출
            let sortedFoods = foodUsageCount.values
                .sorted { $0.count > $1.count }
                .prefix(20)
                .map { $0.food }

            return Array(sortedFoods)
        }
    }

    // MARK: - User-Defined Foods

    func getUserDefinedFoods(userId: UUID) async throws -> [Food] {
        try await context.perform { [weak self] in
            guard let self = self else {
                throw FoodRepositoryError.contextDeallocated
            }

            let fetchRequest: NSFetchRequest<Food> = Food.fetchRequest()
            fetchRequest.predicate = NSPredicate(
                format: "source == %d AND createdByUser.id == %@",
                FoodSource.userDefined.rawValue,
                userId as CVarArg
            )
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]

            return try self.context.fetch(fetchRequest)
        }
    }

    func findBySource(_ source: FoodSource) async throws -> [Food] {
        try await context.perform { [weak self] in
            guard let self = self else {
                throw FoodRepositoryError.contextDeallocated
            }

            let fetchRequest: NSFetchRequest<Food> = Food.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "source == %d", source.rawValue)
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]

            return try self.context.fetch(fetchRequest)
        }
    }

}

// MARK: - Repository Errors

/// Repository 레이어에서 발생하는 에러
enum FoodRepositoryError: Error, LocalizedError {
    case contextDeallocated
    case notFound
    case invalidData

    var errorDescription: String? {
        switch self {
        case .contextDeallocated:
            return "Core Data context has been deallocated"
        case .notFound:
            return "Entity not found"
        case .invalidData:
            return "Invalid data format"
        }
    }
}
