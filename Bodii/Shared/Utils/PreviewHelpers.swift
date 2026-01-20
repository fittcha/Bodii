//
//  PreviewHelpers.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-19.
//

import Foundation
import CoreData

// MARK: - Preview용 Core Data 엔티티 생성 헬퍼

/// Preview에서 Core Data 엔티티를 쉽게 생성하기 위한 헬퍼
enum PreviewHelpers {

    /// Preview용 NSManagedObjectContext
    @MainActor
    static var context: NSManagedObjectContext {
        PersistenceController.preview.container.viewContext
    }

    // MARK: - ExerciseRecord

    /// Preview용 ExerciseRecord 생성
    @MainActor
    static func createExerciseRecord(
        id: UUID = UUID(),
        date: Date = Date(),
        exerciseType: Int16 = 0,
        duration: Int32 = 30,
        intensity: Int16 = 1,
        caloriesBurned: Int32 = 200,
        note: String? = nil,
        fromHealthKit: Bool = false,
        healthKitId: String? = nil
    ) -> ExerciseRecord {
        let record = ExerciseRecord(context: context)
        record.id = id
        record.date = date
        record.exerciseType = exerciseType
        record.duration = duration
        record.intensity = intensity
        record.caloriesBurned = caloriesBurned
        record.note = note
        record.fromHealthKit = fromHealthKit
        record.healthKitId = healthKitId
        record.createdAt = Date()
        return record
    }

    // MARK: - Food

    /// Preview용 Food 생성
    @MainActor
    static func createFood(
        id: UUID = UUID(),
        name: String = "샘플 음식",
        calories: Int32 = 200,
        carbohydrates: Decimal = 25,
        protein: Decimal = 10,
        fat: Decimal = 8,
        sodium: Decimal = 300,
        fiber: Decimal? = nil,
        sugar: Decimal? = nil,
        servingSize: Decimal = 100,
        servingUnit: String = "g",
        source: Int16 = 0,
        apiCode: String? = nil,
        createdByUserId: UUID? = nil
    ) -> Food {
        let food = Food(context: context)
        food.id = id
        food.name = name
        food.calories = calories
        food.carbohydrates = carbohydrates as NSDecimalNumber
        food.protein = protein as NSDecimalNumber
        food.fat = fat as NSDecimalNumber
        food.sodium = sodium as NSDecimalNumber
        food.fiber = fiber.map { $0 as NSDecimalNumber }
        food.sugar = sugar.map { $0 as NSDecimalNumber }
        food.servingSize = servingSize as NSDecimalNumber
        food.servingUnit = servingUnit
        food.source = source
        food.apiCode = apiCode
        food.createdByUserId = createdByUserId
        food.createdAt = Date()
        return food
    }

    // MARK: - FoodRecord

    /// Preview용 FoodRecord 생성
    @MainActor
    static func createFoodRecord(
        id: UUID = UUID(),
        date: Date = Date(),
        mealType: Int16 = 0,
        quantity: Decimal = 1,
        quantityUnit: Int16 = 0,
        food: Food? = nil
    ) -> FoodRecord {
        let record = FoodRecord(context: context)
        record.id = id
        record.date = date
        record.mealType = mealType
        record.quantity = quantity as NSDecimalNumber
        record.quantityUnit = quantityUnit
        record.food = food
        record.createdAt = Date()
        return record
    }

    // MARK: - DailyLog

    /// Preview용 DailyLog 생성
    @MainActor
    static func createDailyLog(
        id: UUID = UUID(),
        date: Date = Date(),
        totalCaloriesIn: Int32 = 2000,
        totalCaloriesOut: Int32 = 500,
        totalCarbs: Decimal = 250,
        totalProtein: Decimal = 100,
        totalFat: Decimal = 70
    ) -> DailyLog {
        let log = DailyLog(context: context)
        log.id = id
        log.date = date
        log.totalCaloriesIn = totalCaloriesIn
        log.totalCaloriesOut = totalCaloriesOut
        log.totalCarbs = totalCarbs as NSDecimalNumber
        log.totalProtein = totalProtein as NSDecimalNumber
        log.totalFat = totalFat as NSDecimalNumber
        log.createdAt = Date()
        log.updatedAt = Date()
        return log
    }
}

// MARK: - ExerciseType 상수 (Preview용)

/// Preview에서 사용할 운동 타입 상수
enum PreviewExerciseType {
    static let running: Int16 = 0
    static let walking: Int16 = 1
    static let cycling: Int16 = 2
    static let swimming: Int16 = 3
    static let weight: Int16 = 4
    static let yoga: Int16 = 5
    static let hiking: Int16 = 6
    static let other: Int16 = 7
}

/// Preview에서 사용할 강도 상수
enum PreviewIntensity {
    static let low: Int16 = 0
    static let medium: Int16 = 1
    static let high: Int16 = 2
}

/// Preview에서 사용할 식사 타입 상수
enum PreviewMealType {
    static let breakfast: Int16 = 0
    static let lunch: Int16 = 1
    static let dinner: Int16 = 2
    static let snack: Int16 = 3
}

/// Preview에서 사용할 음식 소스 상수
enum PreviewFoodSource {
    static let governmentAPI: Int16 = 0
    static let usda: Int16 = 1
    static let userCreated: Int16 = 2
}

/// Preview에서 사용할 수량 단위 상수
enum PreviewQuantityUnit {
    static let serving: Int16 = 0
    static let gram: Int16 = 1
    static let piece: Int16 = 2
}
