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
/// let records = try await repository.findByDate(date, userId: userId)
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
            guard self != nil else {
                throw RepositoryError.contextDeallocated
            }

            try self?.context.save()

            return foodRecord
        }
    }

    func findById(_ id: UUID) async throws -> FoodRecord? {
        try await context.perform { [weak self] in
            guard let self = self else {
                throw RepositoryError.contextDeallocated
            }

            let fetchRequest: NSFetchRequest<FoodRecord> = FoodRecord.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            fetchRequest.fetchLimit = 1

            let results = try self.context.fetch(fetchRequest)

            return results.first
        }
    }

    func update(_ foodRecord: FoodRecord) async throws -> FoodRecord {
        try await context.perform { [weak self] in
            guard let self = self else {
                throw RepositoryError.contextDeallocated
            }

            // FoodRecord는 이미 Core Data 엔티티이므로 context를 저장하면 됨
            try self.context.save()

            return foodRecord
        }
    }

    func delete(_ id: UUID) async throws {
        try await context.perform { [weak self] in
            guard let self = self else {
                throw RepositoryError.contextDeallocated
            }

            let fetchRequest: NSFetchRequest<FoodRecord> = FoodRecord.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            fetchRequest.fetchLimit = 1

            let results = try self.context.fetch(fetchRequest)

            guard let foodRecordEntity = results.first else {
                throw RepositoryError.notFound(id)
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
                throw RepositoryError.invalidData("날짜 계산 실패")
            }

            let fetchRequest: NSFetchRequest<FoodRecord> = FoodRecord.fetchRequest()
            fetchRequest.predicate = NSPredicate(
                format: "user.id == %@ AND date >= %@ AND date < %@",
                userId as CVarArg,
                startOfDay as CVarArg,
                endOfDay as CVarArg
            )
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]

            let results = try self.context.fetch(fetchRequest)

            return results
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
                throw RepositoryError.invalidData("날짜 계산 실패")
            }

            let fetchRequest: NSFetchRequest<FoodRecord> = FoodRecord.fetchRequest()
            fetchRequest.predicate = NSPredicate(
                format: "user.id == %@ AND date >= %@ AND date < %@ AND mealType == %d",
                userId as CVarArg,
                startOfDay as CVarArg,
                endOfDay as CVarArg,
                mealType.rawValue
            )
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]

            let results = try self.context.fetch(fetchRequest)

            return results
        }
    }
}
