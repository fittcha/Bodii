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
                throw RepositoryError.contextDeallocated
            }

            let foodEntity = NSEntityDescription.insertNewObject(forEntityName: "Food", into: self.context)

            self.updateEntity(foodEntity, from: food)

            try self.context.save()

            return food
        }
    }

    func findById(_ id: UUID) async throws -> Food? {
        try await context.perform { [weak self] in
            guard let self = self else {
                throw RepositoryError.contextDeallocated
            }

            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Food")
            fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            fetchRequest.fetchLimit = 1

            let results = try self.context.fetch(fetchRequest)

            return results.first.flatMap { self.mapToFood($0) }
        }
    }

    func findAll() async throws -> [Food] {
        try await context.perform { [weak self] in
            guard let self = self else {
                throw RepositoryError.contextDeallocated
            }

            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Food")
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]

            let results = try self.context.fetch(fetchRequest)

            return results.compactMap { self.mapToFood($0) }
        }
    }

    func update(_ food: Food) async throws -> Food {
        try await context.perform { [weak self] in
            guard let self = self else {
                throw RepositoryError.contextDeallocated
            }

            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Food")
            fetchRequest.predicate = NSPredicate(format: "id == %@", food.id as CVarArg)
            fetchRequest.fetchLimit = 1

            let results = try self.context.fetch(fetchRequest)

            guard let foodEntity = results.first else {
                throw RepositoryError.notFound
            }

            self.updateEntity(foodEntity, from: food)

            try self.context.save()

            return food
        }
    }

    func delete(_ id: UUID) async throws {
        try await context.perform { [weak self] in
            guard let self = self else {
                throw RepositoryError.contextDeallocated
            }

            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Food")
            fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            fetchRequest.fetchLimit = 1

            let results = try self.context.fetch(fetchRequest)

            guard let foodEntity = results.first else {
                throw RepositoryError.notFound
            }

            self.context.delete(foodEntity)
            try self.context.save()
        }
    }

    // MARK: - Search Operations

    func search(name: String) async throws -> [Food] {
        try await context.perform { [weak self] in
            guard let self = self else {
                throw RepositoryError.contextDeallocated
            }

            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Food")
            fetchRequest.predicate = NSPredicate(format: "name CONTAINS[cd] %@", name)
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]

            let results = try self.context.fetch(fetchRequest)

            return results.compactMap { self.mapToFood($0) }
        }
    }

    // MARK: - Recent & Frequent Foods

    func getRecentFoods(userId: UUID) async throws -> [Food] {
        try await context.perform { [weak self] in
            guard let self = self else {
                throw RepositoryError.contextDeallocated
            }

            // 최근 30일 기준 날짜 계산
            let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()

            // FoodRecord를 통해 최근 사용된 음식 조회
            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "FoodRecord")
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
                guard let foodEntity = record.value(forKey: "food") as? NSManagedObject,
                      let foodId = foodEntity.value(forKey: "id") as? UUID else {
                    continue
                }

                // 이미 추가된 음식은 건너뜀
                if seenFoodIds.contains(foodId) {
                    continue
                }

                if let food = self.mapToFood(foodEntity) {
                    recentFoods.append(food)
                    seenFoodIds.insert(foodId)
                }
            }

            return recentFoods
        }
    }

    func getFrequentFoods(userId: UUID) async throws -> [Food] {
        try await context.perform { [weak self] in
            guard let self = self else {
                throw RepositoryError.contextDeallocated
            }

            // FoodRecord를 통해 음식별 사용 횟수 집계
            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "FoodRecord")
            fetchRequest.predicate = NSPredicate(format: "user.id == %@", userId as CVarArg)

            let foodRecords = try self.context.fetch(fetchRequest)

            // 음식별 사용 횟수 집계
            var foodUsageCount: [UUID: (food: NSManagedObject, count: Int)] = [:]

            for record in foodRecords {
                guard let foodEntity = record.value(forKey: "food") as? NSManagedObject,
                      let foodId = foodEntity.value(forKey: "id") as? UUID else {
                    continue
                }

                if let existing = foodUsageCount[foodId] {
                    foodUsageCount[foodId] = (food: existing.food, count: existing.count + 1)
                } else {
                    foodUsageCount[foodId] = (food: foodEntity, count: 1)
                }
            }

            // 사용 횟수 내림차순으로 정렬하고 상위 20개 추출
            let sortedFoods = foodUsageCount.values
                .sorted { $0.count > $1.count }
                .prefix(20)
                .compactMap { self.mapToFood($0.food) }

            return sortedFoods
        }
    }

    // MARK: - User-Defined Foods

    func getUserDefinedFoods(userId: UUID) async throws -> [Food] {
        try await context.perform { [weak self] in
            guard let self = self else {
                throw RepositoryError.contextDeallocated
            }

            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Food")
            fetchRequest.predicate = NSPredicate(
                format: "source == %d AND createdByUser.id == %@",
                FoodSource.userDefined.rawValue,
                userId as CVarArg
            )
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]

            let results = try self.context.fetch(fetchRequest)

            return results.compactMap { self.mapToFood($0) }
        }
    }

    func findBySource(_ source: FoodSource) async throws -> [Food] {
        try await context.perform { [weak self] in
            guard let self = self else {
                throw RepositoryError.contextDeallocated
            }

            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Food")
            fetchRequest.predicate = NSPredicate(format: "source == %d", source.rawValue)
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]

            let results = try self.context.fetch(fetchRequest)

            return results.compactMap { self.mapToFood($0) }
        }
    }

    // MARK: - Private Helpers

    /// Core Data 엔티티를 도메인 모델로 변환합니다.
    ///
    /// - Parameter entity: Core Data NSManagedObject
    /// - Returns: Food 도메인 모델
    private func mapToFood(_ entity: NSManagedObject) -> Food? {
        guard let id = entity.value(forKey: "id") as? UUID,
              let name = entity.value(forKey: "name") as? String,
              let calories = entity.value(forKey: "calories") as? Int32,
              let carbohydrates = entity.value(forKey: "carbohydrates") as? Decimal,
              let protein = entity.value(forKey: "protein") as? Decimal,
              let fat = entity.value(forKey: "fat") as? Decimal,
              let servingSize = entity.value(forKey: "servingSize") as? Decimal,
              let sourceRaw = entity.value(forKey: "source") as? Int16,
              let source = FoodSource(rawValue: sourceRaw),
              let createdAt = entity.value(forKey: "createdAt") as? Date else {
            return nil
        }

        let sodium = entity.value(forKey: "sodium") as? Decimal
        let fiber = entity.value(forKey: "fiber") as? Decimal
        let sugar = entity.value(forKey: "sugar") as? Decimal
        let servingUnit = entity.value(forKey: "servingUnit") as? String
        let apiCode = entity.value(forKey: "apiCode") as? String

        // createdByUser relationship에서 userId 추출
        let createdByUserId: UUID?
        if let createdByUser = entity.value(forKey: "createdByUser") as? NSManagedObject {
            createdByUserId = createdByUser.value(forKey: "id") as? UUID
        } else {
            createdByUserId = nil
        }

        return Food(
            id: id,
            name: name,
            calories: calories,
            carbohydrates: carbohydrates,
            protein: protein,
            fat: fat,
            sodium: sodium,
            fiber: fiber,
            sugar: sugar,
            servingSize: servingSize,
            servingUnit: servingUnit,
            source: source,
            apiCode: apiCode,
            createdByUserId: createdByUserId,
            createdAt: createdAt
        )
    }

    /// 도메인 모델의 값으로 Core Data 엔티티를 업데이트합니다.
    ///
    /// - Parameters:
    ///   - entity: 업데이트할 Core Data NSManagedObject
    ///   - food: 소스 Food 도메인 모델
    private func updateEntity(_ entity: NSManagedObject, from food: Food) {
        entity.setValue(food.id, forKey: "id")
        entity.setValue(food.name, forKey: "name")
        entity.setValue(food.calories, forKey: "calories")
        entity.setValue(food.carbohydrates, forKey: "carbohydrates")
        entity.setValue(food.protein, forKey: "protein")
        entity.setValue(food.fat, forKey: "fat")
        entity.setValue(food.sodium, forKey: "sodium")
        entity.setValue(food.fiber, forKey: "fiber")
        entity.setValue(food.sugar, forKey: "sugar")
        entity.setValue(food.servingSize, forKey: "servingSize")
        entity.setValue(food.servingUnit, forKey: "servingUnit")
        entity.setValue(food.source.rawValue, forKey: "source")
        entity.setValue(food.apiCode, forKey: "apiCode")
        entity.setValue(food.createdAt, forKey: "createdAt")

        // createdByUserId가 있으면 User relationship 설정
        if let createdByUserId = food.createdByUserId {
            let userFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "User")
            userFetchRequest.predicate = NSPredicate(format: "id == %@", createdByUserId as CVarArg)
            userFetchRequest.fetchLimit = 1

            if let userEntity = try? context.fetch(userFetchRequest).first {
                entity.setValue(userEntity, forKey: "createdByUser")
            }
        } else {
            entity.setValue(nil, forKey: "createdByUser")
        }
    }
}

// MARK: - Repository Errors

/// Repository 레이어에서 발생하는 에러
enum RepositoryError: Error, LocalizedError {
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
