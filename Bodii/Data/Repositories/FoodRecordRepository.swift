//
//  FoodRecordRepository.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-13.
//

import Foundation
import CoreData

/// FoodRecord 엔티티에 대한 Core Data Repository 구현
///
/// FoodRecordRepositoryProtocol을 구현하여 식단 기록 데이터의 CRUD 및 조회 기능을 제공합니다.
///
/// - Note: Core Data의 NSManagedObjectContext를 사용하여 데이터를 관리합니다.
/// - Note: 모든 작업은 비동기로 수행되며 Swift Concurrency를 사용합니다.
///
/// - Example:
/// ```swift
/// let repository = FoodRecordRepository(context: persistenceController.viewContext)
/// let foodRecord = FoodRecord(
///     id: UUID(),
///     userId: UUID(),
///     foodId: UUID(),
///     date: Date(),
///     mealType: .breakfast,
///     quantity: Decimal(1.0),
///     quantityUnit: .serving,
///     calculatedCalories: 330,
///     calculatedCarbs: Decimal(73.4),
///     calculatedProtein: Decimal(6.8),
///     calculatedFat: Decimal(2.5),
///     createdAt: Date()
/// )
/// try await repository.save(foodRecord)
/// ```
final class FoodRecordRepository: FoodRecordRepositoryProtocol {

    // MARK: - Properties

    /// Core Data managed object context
    private let context: NSManagedObjectContext

    // MARK: - Initialization

    /// FoodRecordRepository를 초기화합니다.
    ///
    /// - Parameter context: Core Data managed object context
    init(context: NSManagedObjectContext) {
        self.context = context
    }

    // MARK: - CRUD Operations

    func save(_ foodRecord: FoodRecord) async throws -> FoodRecord {
        try await context.perform { [weak self] in
            guard let self = self else {
                throw RepositoryError.contextDeallocated
            }

            let foodRecordEntity = NSEntityDescription.insertNewObject(forEntityName: "FoodRecord", into: self.context)

            self.updateEntity(foodRecordEntity, from: foodRecord)

            try self.context.save()

            return foodRecord
        }
    }

    func findById(_ id: UUID) async throws -> FoodRecord? {
        try await context.perform { [weak self] in
            guard let self = self else {
                throw RepositoryError.contextDeallocated
            }

            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "FoodRecord")
            fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            fetchRequest.fetchLimit = 1

            let results = try self.context.fetch(fetchRequest)

            return results.first.flatMap { self.mapToFoodRecord($0) }
        }
    }

    func update(_ foodRecord: FoodRecord) async throws -> FoodRecord {
        try await context.perform { [weak self] in
            guard let self = self else {
                throw RepositoryError.contextDeallocated
            }

            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "FoodRecord")
            fetchRequest.predicate = NSPredicate(format: "id == %@", foodRecord.id as CVarArg)
            fetchRequest.fetchLimit = 1

            let results = try self.context.fetch(fetchRequest)

            guard let foodRecordEntity = results.first else {
                throw RepositoryError.notFound
            }

            self.updateEntity(foodRecordEntity, from: foodRecord)

            try self.context.save()

            return foodRecord
        }
    }

    func delete(_ id: UUID) async throws {
        try await context.perform { [weak self] in
            guard let self = self else {
                throw RepositoryError.contextDeallocated
            }

            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "FoodRecord")
            fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            fetchRequest.fetchLimit = 1

            let results = try self.context.fetch(fetchRequest)

            guard let foodRecordEntity = results.first else {
                throw RepositoryError.notFound
            }

            self.context.delete(foodRecordEntity)
            try self.context.save()
        }
    }

    // MARK: - Query Operations

    func findByDate(_ date: Date, userId: UUID) async throws -> [FoodRecord] {
        try await context.perform { [weak self] in
            guard let self = self else {
                throw RepositoryError.contextDeallocated
            }

            // 날짜의 시작과 끝 시간 계산
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: date)
            guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
                throw RepositoryError.invalidData
            }

            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "FoodRecord")
            fetchRequest.predicate = NSPredicate(
                format: "user.id == %@ AND date >= %@ AND date < %@",
                userId as CVarArg,
                startOfDay as CVarArg,
                endOfDay as CVarArg
            )
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]

            let results = try self.context.fetch(fetchRequest)

            return results.compactMap { self.mapToFoodRecord($0) }
        }
    }

    func findByDateAndMealType(_ date: Date, mealType: MealType, userId: UUID) async throws -> [FoodRecord] {
        try await context.perform { [weak self] in
            guard let self = self else {
                throw RepositoryError.contextDeallocated
            }

            // 날짜의 시작과 끝 시간 계산
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: date)
            guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
                throw RepositoryError.invalidData
            }

            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "FoodRecord")
            fetchRequest.predicate = NSPredicate(
                format: "user.id == %@ AND date >= %@ AND date < %@ AND mealType == %d",
                userId as CVarArg,
                startOfDay as CVarArg,
                endOfDay as CVarArg,
                mealType.rawValue
            )
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]

            let results = try self.context.fetch(fetchRequest)

            return results.compactMap { self.mapToFoodRecord($0) }
        }
    }

    // MARK: - Private Helpers

    /// Core Data 엔티티를 도메인 모델로 변환합니다.
    ///
    /// - Parameter entity: Core Data NSManagedObject
    /// - Returns: FoodRecord 도메인 모델
    private func mapToFoodRecord(_ entity: NSManagedObject) -> FoodRecord? {
        guard let id = entity.value(forKey: "id") as? UUID,
              let date = entity.value(forKey: "date") as? Date,
              let mealTypeRaw = entity.value(forKey: "mealType") as? Int16,
              let mealType = MealType(rawValue: mealTypeRaw),
              let quantity = entity.value(forKey: "quantity") as? Decimal,
              let quantityUnitRaw = entity.value(forKey: "quantityUnit") as? Int16,
              let quantityUnit = QuantityUnit(rawValue: quantityUnitRaw),
              let calculatedCalories = entity.value(forKey: "calculatedCalories") as? Int32,
              let calculatedCarbs = entity.value(forKey: "calculatedCarbs") as? Decimal,
              let calculatedProtein = entity.value(forKey: "calculatedProtein") as? Decimal,
              let calculatedFat = entity.value(forKey: "calculatedFat") as? Decimal,
              let createdAt = entity.value(forKey: "createdAt") as? Date else {
            return nil
        }

        // user relationship에서 userId 추출
        guard let userEntity = entity.value(forKey: "user") as? NSManagedObject,
              let userId = userEntity.value(forKey: "id") as? UUID else {
            return nil
        }

        // food relationship에서 foodId 추출
        guard let foodEntity = entity.value(forKey: "food") as? NSManagedObject,
              let foodId = foodEntity.value(forKey: "id") as? UUID else {
            return nil
        }

        return FoodRecord(
            id: id,
            userId: userId,
            foodId: foodId,
            date: date,
            mealType: mealType,
            quantity: quantity,
            quantityUnit: quantityUnit,
            calculatedCalories: calculatedCalories,
            calculatedCarbs: calculatedCarbs,
            calculatedProtein: calculatedProtein,
            calculatedFat: calculatedFat,
            createdAt: createdAt
        )
    }

    /// 도메인 모델의 값으로 Core Data 엔티티를 업데이트합니다.
    ///
    /// - Parameters:
    ///   - entity: 업데이트할 Core Data NSManagedObject
    ///   - foodRecord: 소스 FoodRecord 도메인 모델
    private func updateEntity(_ entity: NSManagedObject, from foodRecord: FoodRecord) {
        entity.setValue(foodRecord.id, forKey: "id")
        entity.setValue(foodRecord.date, forKey: "date")
        entity.setValue(foodRecord.mealType.rawValue, forKey: "mealType")
        entity.setValue(foodRecord.quantity, forKey: "quantity")
        entity.setValue(foodRecord.quantityUnit.rawValue, forKey: "quantityUnit")
        entity.setValue(foodRecord.calculatedCalories, forKey: "calculatedCalories")
        entity.setValue(foodRecord.calculatedCarbs, forKey: "calculatedCarbs")
        entity.setValue(foodRecord.calculatedProtein, forKey: "calculatedProtein")
        entity.setValue(foodRecord.calculatedFat, forKey: "calculatedFat")
        entity.setValue(foodRecord.createdAt, forKey: "createdAt")

        // User relationship 설정
        let userFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "User")
        userFetchRequest.predicate = NSPredicate(format: "id == %@", foodRecord.userId as CVarArg)
        userFetchRequest.fetchLimit = 1

        if let userEntity = try? context.fetch(userFetchRequest).first {
            entity.setValue(userEntity, forKey: "user")
        }

        // Food relationship 설정
        let foodFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Food")
        foodFetchRequest.predicate = NSPredicate(format: "id == %@", foodRecord.foodId as CVarArg)
        foodFetchRequest.fetchLimit = 1

        if let foodEntity = try? context.fetch(foodFetchRequest).first {
            entity.setValue(foodEntity, forKey: "food")
        }
    }
}
