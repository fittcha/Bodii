//
//  DailyLogRepository.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-13.
//

import Foundation
import CoreData

/// DailyLog 엔티티에 대한 Core Data Repository 구현
///
/// DailyLogRepositoryProtocol을 구현하여 일일 집계 데이터의 CRUD 및 조회 기능을 제공합니다.
///
/// - Note: Core Data의 NSManagedObjectContext를 사용하여 데이터를 관리합니다.
/// - Note: 모든 작업은 비동기로 수행되며 Swift Concurrency를 사용합니다.
/// - Note: DailyLog는 사용자별/날짜별로 고유하므로 getOrCreate 패턴을 사용합니다.
///
/// - Example:
/// ```swift
/// let repository = DailyLogRepository(context: persistenceController.viewContext)
/// let dailyLog = try await repository.getOrCreate(
///     for: Date(),
///     userId: user.id,
///     bmr: 1650,
///     tdee: 2310
/// )
/// ```
final class DailyLogRepository: DailyLogRepositoryProtocol {

    // MARK: - Properties

    /// Core Data managed object context
    private let context: NSManagedObjectContext

    // MARK: - Initialization

    /// DailyLogRepository를 초기화합니다.
    ///
    /// - Parameter context: Core Data managed object context
    init(context: NSManagedObjectContext) {
        self.context = context
    }

    // MARK: - CRUD Operations

    func save(_ dailyLog: DailyLog) async throws -> DailyLog {
        try await context.perform { [weak self] in
            guard let self = self else {
                throw RepositoryError.contextDeallocated
            }

            let dailyLogEntity = NSEntityDescription.insertNewObject(forEntityName: "DailyLog", into: self.context)

            self.updateEntity(dailyLogEntity, from: dailyLog)

            try self.context.save()

            return dailyLog
        }
    }

    func update(_ dailyLog: DailyLog) async throws -> DailyLog {
        try await context.perform { [weak self] in
            guard let self = self else {
                throw RepositoryError.contextDeallocated
            }

            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "DailyLog")
            fetchRequest.predicate = NSPredicate(format: "id == %@", dailyLog.id as CVarArg)
            fetchRequest.fetchLimit = 1

            let results = try self.context.fetch(fetchRequest)

            guard let dailyLogEntity = results.first else {
                throw RepositoryError.notFound
            }

            self.updateEntity(dailyLogEntity, from: dailyLog)

            try self.context.save()

            return dailyLog
        }
    }

    func delete(_ id: UUID) async throws {
        try await context.perform { [weak self] in
            guard let self = self else {
                throw RepositoryError.contextDeallocated
            }

            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "DailyLog")
            fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            fetchRequest.fetchLimit = 1

            let results = try self.context.fetch(fetchRequest)

            guard let dailyLogEntity = results.first else {
                throw RepositoryError.notFound
            }

            self.context.delete(dailyLogEntity)
            try self.context.save()
        }
    }

    // MARK: - Query Operations

    func findByDate(_ date: Date, userId: UUID) async throws -> DailyLog? {
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

            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "DailyLog")
            fetchRequest.predicate = NSPredicate(
                format: "user.id == %@ AND date >= %@ AND date < %@",
                userId as CVarArg,
                startOfDay as CVarArg,
                endOfDay as CVarArg
            )
            fetchRequest.fetchLimit = 1

            let results = try self.context.fetch(fetchRequest)

            return results.first.flatMap { self.mapToDailyLog($0) }
        }
    }

    func getOrCreate(for date: Date, userId: UUID, bmr: Int32, tdee: Int32) async throws -> DailyLog {
        // 먼저 기존 레코드를 조회
        if let existing = try await findByDate(date, userId: userId) {
            return existing
        }

        // 없으면 새로 생성
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)

        let newDailyLog = DailyLog(
            id: UUID(),
            userId: userId,
            date: startOfDay,
            totalCaloriesIn: 0,
            totalCarbs: 0,
            totalProtein: 0,
            totalFat: 0,
            carbsRatio: nil,
            proteinRatio: nil,
            fatRatio: nil,
            bmr: bmr,
            tdee: tdee,
            netCalories: -Int32(tdee),
            totalCaloriesOut: 0,
            exerciseMinutes: 0,
            exerciseCount: 0,
            steps: nil,
            weight: nil,
            bodyFatPct: nil,
            sleepDuration: nil,
            sleepStatus: nil,
            createdAt: Date(),
            updatedAt: Date()
        )

        return try await save(newDailyLog)
    }

    func findByDateRange(startDate: Date, endDate: Date, userId: UUID) async throws -> [DailyLog] {
        try await context.perform { [weak self] in
            guard let self = self else {
                throw RepositoryError.contextDeallocated
            }

            // 날짜의 시작과 끝 시간 계산
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: startDate)
            let endOfDayBase = calendar.startOfDay(for: endDate)
            guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: endOfDayBase) else {
                throw RepositoryError.invalidData
            }

            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "DailyLog")
            fetchRequest.predicate = NSPredicate(
                format: "user.id == %@ AND date >= %@ AND date < %@",
                userId as CVarArg,
                startOfDay as CVarArg,
                endOfDay as CVarArg
            )
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]

            let results = try self.context.fetch(fetchRequest)

            return results.compactMap { self.mapToDailyLog($0) }
        }
    }

    // MARK: - Private Helpers

    /// Core Data 엔티티를 도메인 모델로 변환합니다.
    ///
    /// - Parameter entity: Core Data NSManagedObject
    /// - Returns: DailyLog 도메인 모델
    private func mapToDailyLog(_ entity: NSManagedObject) -> DailyLog? {
        guard let id = entity.value(forKey: "id") as? UUID,
              let date = entity.value(forKey: "date") as? Date,
              let totalCaloriesIn = entity.value(forKey: "totalCaloriesIn") as? Int32,
              let totalCarbs = entity.value(forKey: "totalCarbs") as? Decimal,
              let totalProtein = entity.value(forKey: "totalProtein") as? Decimal,
              let totalFat = entity.value(forKey: "totalFat") as? Decimal,
              let bmr = entity.value(forKey: "bmr") as? Int32,
              let tdee = entity.value(forKey: "tdee") as? Int32,
              let netCalories = entity.value(forKey: "netCalories") as? Int32,
              let totalCaloriesOut = entity.value(forKey: "totalCaloriesOut") as? Int32,
              let exerciseMinutes = entity.value(forKey: "exerciseMinutes") as? Int32,
              let exerciseCount = entity.value(forKey: "exerciseCount") as? Int16,
              let createdAt = entity.value(forKey: "createdAt") as? Date,
              let updatedAt = entity.value(forKey: "updatedAt") as? Date else {
            return nil
        }

        // user relationship에서 userId 추출
        guard let userEntity = entity.value(forKey: "user") as? NSManagedObject,
              let userId = userEntity.value(forKey: "id") as? UUID else {
            return nil
        }

        // Optional fields
        let carbsRatio = entity.value(forKey: "carbsRatio") as? Decimal
        let proteinRatio = entity.value(forKey: "proteinRatio") as? Decimal
        let fatRatio = entity.value(forKey: "fatRatio") as? Decimal
        let steps = entity.value(forKey: "steps") as? Int32
        let weight = entity.value(forKey: "weight") as? Decimal
        let bodyFatPct = entity.value(forKey: "bodyFatPct") as? Decimal
        let sleepDuration = entity.value(forKey: "sleepDuration") as? Int32

        // sleepStatus enum
        let sleepStatus: SleepStatus?
        if let sleepStatusRaw = entity.value(forKey: "sleepStatus") as? Int16 {
            sleepStatus = SleepStatus(rawValue: sleepStatusRaw)
        } else {
            sleepStatus = nil
        }

        return DailyLog(
            id: id,
            userId: userId,
            date: date,
            totalCaloriesIn: totalCaloriesIn,
            totalCarbs: totalCarbs,
            totalProtein: totalProtein,
            totalFat: totalFat,
            carbsRatio: carbsRatio,
            proteinRatio: proteinRatio,
            fatRatio: fatRatio,
            bmr: bmr,
            tdee: tdee,
            netCalories: netCalories,
            totalCaloriesOut: totalCaloriesOut,
            exerciseMinutes: exerciseMinutes,
            exerciseCount: exerciseCount,
            steps: steps,
            weight: weight,
            bodyFatPct: bodyFatPct,
            sleepDuration: sleepDuration,
            sleepStatus: sleepStatus,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    /// 도메인 모델의 값으로 Core Data 엔티티를 업데이트합니다.
    ///
    /// - Parameters:
    ///   - entity: 업데이트할 Core Data NSManagedObject
    ///   - dailyLog: 소스 DailyLog 도메인 모델
    private func updateEntity(_ entity: NSManagedObject, from dailyLog: DailyLog) {
        entity.setValue(dailyLog.id, forKey: "id")
        entity.setValue(dailyLog.date, forKey: "date")
        entity.setValue(dailyLog.totalCaloriesIn, forKey: "totalCaloriesIn")
        entity.setValue(dailyLog.totalCarbs, forKey: "totalCarbs")
        entity.setValue(dailyLog.totalProtein, forKey: "totalProtein")
        entity.setValue(dailyLog.totalFat, forKey: "totalFat")
        entity.setValue(dailyLog.carbsRatio, forKey: "carbsRatio")
        entity.setValue(dailyLog.proteinRatio, forKey: "proteinRatio")
        entity.setValue(dailyLog.fatRatio, forKey: "fatRatio")
        entity.setValue(dailyLog.bmr, forKey: "bmr")
        entity.setValue(dailyLog.tdee, forKey: "tdee")
        entity.setValue(dailyLog.netCalories, forKey: "netCalories")
        entity.setValue(dailyLog.totalCaloriesOut, forKey: "totalCaloriesOut")
        entity.setValue(dailyLog.exerciseMinutes, forKey: "exerciseMinutes")
        entity.setValue(dailyLog.exerciseCount, forKey: "exerciseCount")
        entity.setValue(dailyLog.steps, forKey: "steps")
        entity.setValue(dailyLog.weight, forKey: "weight")
        entity.setValue(dailyLog.bodyFatPct, forKey: "bodyFatPct")
        entity.setValue(dailyLog.sleepDuration, forKey: "sleepDuration")
        entity.setValue(dailyLog.sleepStatus?.rawValue, forKey: "sleepStatus")
        entity.setValue(dailyLog.createdAt, forKey: "createdAt")
        entity.setValue(dailyLog.updatedAt, forKey: "updatedAt")

        // User relationship 설정
        let userFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "User")
        userFetchRequest.predicate = NSPredicate(format: "id == %@", dailyLog.userId as CVarArg)
        userFetchRequest.fetchLimit = 1

        if let userEntity = try? context.fetch(userFetchRequest).first {
            entity.setValue(userEntity, forKey: "user")
        }
    }
}
