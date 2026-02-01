//
//  DailyLogLocalDataSource.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-13.
//

import Foundation
import CoreData

// MARK: - DailyLogLocalDataSource

/// DailyLog의 Core Data 작업을 담당하는 로컬 데이터 소스
final class DailyLogLocalDataSource {

    // MARK: - Properties

    private let context: NSManagedObjectContext

    // MARK: - Initialization

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    // MARK: - Get or Create

    /// 특정 날짜의 DailyLog를 조회하거나 없으면 생성합니다.
    func getOrCreate(
        for date: Date,
        userId: UUID,
        bmr: Int32,
        tdee: Int32
    ) async throws -> DailyLog {
        return try await context.perform { [weak self] in
            guard let self = self else {
                throw DataSourceError.contextDeallocated
            }

            if let existing = try self.fetchDailyLog(for: date, userId: userId) {
                // BMR/TDEE가 0인 기존 DailyLog에 유효한 값이 전달되면 업데이트
                if existing.tdee == 0 && tdee > 0 {
                    existing.bmr = bmr
                    existing.tdee = tdee
                    existing.netCalories = existing.totalCaloriesIn - tdee
                    existing.updatedAt = Date()
                    try self.context.save()
                }
                return existing
            }

            return try self.createDailyLog(date: date, userId: userId, bmr: bmr, tdee: tdee)
        }
    }

    /// 특정 날짜의 DailyLog를 조회합니다.
    func fetch(for date: Date, userId: UUID) async throws -> DailyLog? {
        return try await context.perform { [weak self] in
            guard let self = self else {
                throw DataSourceError.contextDeallocated
            }

            return try self.fetchDailyLog(for: date, userId: userId)
        }
    }

    /// 오늘 날짜의 DailyLog를 조회합니다.
    func fetchCurrentDay(userId: UUID) async throws -> DailyLog? {
        let today = Date()
        return try await fetch(for: today, userId: userId)
    }

    // MARK: - Update

    /// DailyLog를 저장합니다.
    func save(_ dailyLog: DailyLog) async throws {
        try await context.perform { [weak self] in
            guard let self = self else {
                throw DataSourceError.contextDeallocated
            }

            dailyLog.updatedAt = Date()
            try self.context.save()
        }
    }

    // MARK: - Exercise Updates

    /// 운동 추가 시 DailyLog를 업데이트합니다.
    func addExercise(
        date: Date,
        userId: UUID,
        calories: Int32,
        duration: Int32
    ) async throws {
        try await context.perform { [weak self] in
            guard let self = self else {
                throw DataSourceError.contextDeallocated
            }

            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: date)

            guard let dailyLog = try self.fetchDailyLog(for: startOfDay, userId: userId) else {
                throw DataSourceError.recordNotFound
            }

            dailyLog.totalCaloriesOut += calories
            dailyLog.exerciseMinutes += duration
            dailyLog.exerciseCount += 1
            dailyLog.updatedAt = Date()

            try self.context.save()
        }
    }

    /// 운동 삭제 시 DailyLog를 업데이트합니다.
    func removeExercise(
        date: Date,
        userId: UUID,
        calories: Int32,
        duration: Int32
    ) async throws {
        try await context.perform { [weak self] in
            guard let self = self else {
                throw DataSourceError.contextDeallocated
            }

            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: date)

            guard let dailyLog = try self.fetchDailyLog(for: startOfDay, userId: userId) else {
                throw DataSourceError.recordNotFound
            }

            dailyLog.totalCaloriesOut = max(0, dailyLog.totalCaloriesOut - calories)
            dailyLog.exerciseMinutes = max(0, dailyLog.exerciseMinutes - duration)
            dailyLog.exerciseCount = max(0, dailyLog.exerciseCount - 1)
            dailyLog.updatedAt = Date()

            try self.context.save()
        }
    }

    // MARK: - AI Comment Persistence

    /// AI 식단 코멘트를 DailyLog에 저장합니다.
    ///
    /// - Parameters:
    ///   - comment: 저장할 DietComment
    ///   - date: 대상 날짜
    ///   - userId: 사용자 ID
    func saveAIComment(_ comment: DietComment, for date: Date, userId: UUID) async throws {
        try await context.perform { [weak self] in
            guard let self = self else {
                throw DataSourceError.contextDeallocated
            }

            guard let dailyLog = try self.fetchDailyLog(for: date, userId: userId) else {
                throw DataSourceError.recordNotFound
            }

            DietCommentSerializer.saveToDailyLog(comment, dailyLog: dailyLog)
            dailyLog.updatedAt = Date()
            try self.context.save()
        }
    }

    /// DailyLog에 저장된 AI 식단 코멘트를 조회합니다.
    ///
    /// - Parameters:
    ///   - date: 대상 날짜
    ///   - userId: 사용자 ID
    /// - Returns: 저장된 DietComment (없으면 nil)
    func fetchAIComment(for date: Date, userId: UUID) async throws -> DietComment? {
        return try await context.perform { [weak self] in
            guard let self = self else {
                throw DataSourceError.contextDeallocated
            }

            guard let dailyLog = try self.fetchDailyLog(for: date, userId: userId) else {
                return nil
            }

            return DietCommentSerializer.toDietComment(from: dailyLog, userId: userId)
        }
    }

    // MARK: - Exercise Updates

    /// 운동 수정 시 DailyLog를 업데이트합니다.
    func updateExercise(
        date: Date,
        userId: UUID,
        oldCalories: Int32,
        newCalories: Int32,
        oldDuration: Int32,
        newDuration: Int32
    ) async throws {
        try await context.perform { [weak self] in
            guard let self = self else {
                throw DataSourceError.contextDeallocated
            }

            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: date)

            guard let dailyLog = try self.fetchDailyLog(for: startOfDay, userId: userId) else {
                throw DataSourceError.recordNotFound
            }

            let caloriesDiff = newCalories - oldCalories
            let durationDiff = newDuration - oldDuration

            dailyLog.totalCaloriesOut += caloriesDiff
            dailyLog.exerciseMinutes += durationDiff
            dailyLog.updatedAt = Date()

            try self.context.save()
        }
    }
}

// MARK: - Private Helpers

extension DailyLogLocalDataSource {

    private func fetchDailyLog(for date: Date, userId: UUID) throws -> DailyLog? {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)

        let request: NSFetchRequest<DailyLog> = DailyLog.fetchRequest()
        request.predicate = NSPredicate(
            format: "date == %@ AND user.id == %@",
            startOfDay as CVarArg,
            userId as CVarArg
        )
        request.fetchLimit = 1

        return try context.fetch(request).first
    }

    private func createDailyLog(
        date: Date,
        userId: UUID,
        bmr: Int32,
        tdee: Int32
    ) throws -> DailyLog {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)

        let dailyLog = DailyLog(context: context)
        let now = Date()

        dailyLog.id = UUID()
        dailyLog.date = startOfDay
        dailyLog.bmr = bmr
        dailyLog.tdee = tdee
        dailyLog.totalCaloriesIn = 0
        dailyLog.totalCaloriesOut = 0
        dailyLog.activeCaloriesOut = 0
        dailyLog.exerciseMinutes = 0
        dailyLog.exerciseCount = 0
        dailyLog.totalCarbs = 0
        dailyLog.totalProtein = 0
        dailyLog.totalFat = 0
        dailyLog.netCalories = -tdee
        dailyLog.createdAt = now
        dailyLog.updatedAt = now

        // User relationship (필수)
        let userRequest: NSFetchRequest<User> = User.fetchRequest()
        userRequest.predicate = NSPredicate(format: "id == %@", userId as CVarArg)
        userRequest.fetchLimit = 1

        guard let user = try context.fetch(userRequest).first else {
            context.delete(dailyLog)
            throw DataSourceError.recordNotFound
        }
        dailyLog.user = user

        try context.save()

        return dailyLog
    }
}
