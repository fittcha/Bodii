//
//  GoalLocalDataSource.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-18.
//

import Foundation
import CoreData

// MARK: - GoalLocalDataSource

/// Goal의 Core Data 작업을 담당하는 로컬 데이터 소스
final class GoalLocalDataSource {

    // MARK: - Properties

    private let persistenceController: PersistenceController

    // MARK: - Initialization

    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
    }

    // MARK: - Create

    /// 새로운 목표를 생성합니다.
    func create(
        userId: UUID,
        goalType: GoalType,
        targetWeight: Decimal? = nil,
        targetBodyFatPct: Decimal? = nil,
        targetMuscleMass: Decimal? = nil,
        weeklyWeightRate: Decimal? = nil,
        dailyCalorieTarget: Int32? = nil,
        startWeight: Decimal? = nil,
        startBodyFatPct: Decimal? = nil,
        startMuscleMass: Decimal? = nil,
        startBMR: Decimal? = nil,
        startTDEE: Decimal? = nil
    ) async throws -> Goal {
        let context = persistenceController.newBackgroundContext()

        return try await context.perform {
            let goal = Goal(context: context)
            let now = Date()

            goal.id = UUID()
            goal.goalType = goalType.rawValue
            goal.targetWeight = targetWeight as NSDecimalNumber?
            goal.targetBodyFatPct = targetBodyFatPct as NSDecimalNumber?
            goal.targetMuscleMass = targetMuscleMass as NSDecimalNumber?
            goal.weeklyWeightRate = weeklyWeightRate as NSDecimalNumber?
            goal.dailyCalorieTarget = dailyCalorieTarget ?? 0
            goal.startWeight = startWeight as NSDecimalNumber?
            goal.startBodyFatPct = startBodyFatPct as NSDecimalNumber?
            goal.startMuscleMass = startMuscleMass as NSDecimalNumber?
            goal.startBMR = startBMR as NSDecimalNumber?
            goal.startTDEE = startTDEE as NSDecimalNumber?
            goal.isActive = true
            goal.createdAt = now
            goal.updatedAt = now

            // User relationship
            let userRequest: NSFetchRequest<User> = User.fetchRequest()
            userRequest.predicate = NSPredicate(format: "id == %@", userId as CVarArg)
            userRequest.fetchLimit = 1

            if let user = try? context.fetch(userRequest).first {
                goal.user = user
            }

            try context.save()

            return goal
        }
    }

    // MARK: - Read

    /// ID로 특정 목표를 조회합니다.
    func fetch(by id: UUID) async throws -> Goal? {
        let context = persistenceController.viewContext

        return try await context.perform {
            let request: NSFetchRequest<Goal> = Goal.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1

            return try context.fetch(request).first
        }
    }

    /// 활성 목표를 조회합니다.
    func fetchActiveGoal() async throws -> Goal? {
        let context = persistenceController.viewContext

        return try await context.perform {
            let request: NSFetchRequest<Goal> = Goal.fetchRequest()
            request.predicate = NSPredicate(format: "isActive == YES")
            request.fetchLimit = 1

            return try context.fetch(request).first
        }
    }

    /// 모든 목표를 조회합니다.
    func fetchAll() async throws -> [Goal] {
        let context = persistenceController.viewContext

        return try await context.perform {
            let request: NSFetchRequest<Goal> = Goal.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
            request.fetchLimit = 100

            return try context.fetch(request)
        }
    }

    /// 비활성 목표 기록을 조회합니다.
    func fetchHistory() async throws -> [Goal] {
        let context = persistenceController.viewContext

        return try await context.perform {
            let request: NSFetchRequest<Goal> = Goal.fetchRequest()
            request.predicate = NSPredicate(format: "isActive == NO")
            request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
            request.fetchLimit = 50

            return try context.fetch(request)
        }
    }

    // MARK: - Update

    /// 목표를 저장합니다.
    func save(_ goal: Goal) async throws {
        let context = goal.managedObjectContext ?? persistenceController.viewContext

        try await context.perform {
            goal.updatedAt = Date()
            try context.save()
        }
    }

    /// 모든 활성 목표를 비활성화합니다.
    func deactivateAllGoals() async throws {
        let context = persistenceController.newBackgroundContext()

        try await context.perform {
            let request: NSFetchRequest<Goal> = Goal.fetchRequest()
            request.predicate = NSPredicate(format: "isActive == YES")

            let results = try context.fetch(request)

            for goal in results {
                goal.isActive = false
                goal.updatedAt = Date()
            }

            try context.save()
        }
    }

    // MARK: - Delete

    /// 특정 목표를 삭제합니다.
    func delete(_ goal: Goal) async throws {
        let context = goal.managedObjectContext ?? persistenceController.viewContext

        try await context.perform {
            context.delete(goal)
            try context.save()
        }
    }

    /// ID로 목표를 삭제합니다.
    func delete(by id: UUID) async throws {
        let context = persistenceController.newBackgroundContext()

        try await context.perform {
            let request: NSFetchRequest<Goal> = Goal.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1

            guard let goal = try context.fetch(request).first else {
                throw DataSourceError.recordNotFound
            }

            context.delete(goal)
            try context.save()
        }
    }
}
