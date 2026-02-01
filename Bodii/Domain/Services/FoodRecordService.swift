//
//  FoodRecordService.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-13.
//

import Foundation
import CoreData

/// FoodRecord 비즈니스 로직을 처리하는 서비스 구현
///
/// FoodRecordServiceProtocol을 구현하여 식단 기록 추가/삭제 시 DailyLog를 자동으로 업데이트합니다.
///
/// - Note: 모든 작업은 비동기로 수행되며 Swift Concurrency를 사용합니다.
/// - Note: Food의 영양소 정보를 기반으로 quantity에 비례하여 실제 섭취량을 계산합니다.
///
/// - Example:
/// ```swift
/// let service = FoodRecordService(
///     foodRecordRepository: foodRecordRepository,
///     dailyLogRepository: dailyLogRepository,
///     foodRepository: foodRepository,
///     context: persistenceController.viewContext
/// )
/// let foodRecord = try await service.addFoodRecord(
///     userId: userId,
///     foodId: foodId,
///     date: Date(),
///     mealType: .breakfast,
///     quantity: Decimal(1.5),
///     quantityUnit: .serving,
///     bmr: 1650,
///     tdee: 2310
/// )
/// ```
final class FoodRecordService: FoodRecordServiceProtocol {

    // MARK: - Properties

    /// FoodRecord Repository
    private let foodRecordRepository: FoodRecordRepositoryProtocol

    /// DailyLog Repository
    private let dailyLogRepository: DailyLogRepository

    /// Food Repository
    private let foodRepository: FoodRepositoryProtocol

    /// Core Data Context
    private let context: NSManagedObjectContext

    // MARK: - Initialization

    /// FoodRecordService를 초기화합니다.
    ///
    /// - Parameters:
    ///   - foodRecordRepository: FoodRecord Repository
    ///   - dailyLogRepository: DailyLog Repository
    ///   - foodRepository: Food Repository
    ///   - context: Core Data context
    init(
        foodRecordRepository: FoodRecordRepositoryProtocol,
        dailyLogRepository: DailyLogRepository,
        foodRepository: FoodRepositoryProtocol,
        context: NSManagedObjectContext
    ) {
        self.foodRecordRepository = foodRecordRepository
        self.dailyLogRepository = dailyLogRepository
        self.foodRepository = foodRepository
        self.context = context
    }

    // MARK: - Food Record Operations

    func addFoodRecord(
        userId: UUID,
        foodId: UUID,
        date: Date,
        mealType: MealType,
        quantity: Decimal,
        quantityUnit: QuantityUnit,
        bmr: Int32,
        tdee: Int32
    ) async throws -> FoodRecord {
        // 1. Food 정보 조회
        guard let food = try await foodRepository.findById(foodId) else {
            throw ServiceError.foodNotFound
        }

        // 2. 실제 섭취량 계산
        let nutritionValues = calculateNutrition(
            food: food,
            quantity: quantity,
            quantityUnit: quantityUnit
        )

        // 3. 새 FoodRecord 생성 (한 끼에 여러 음식 추가 가능)
        let foodRecord = FoodRecord(context: context)
        foodRecord.id = UUID()
        foodRecord.food = food
        foodRecord.date = date
        foodRecord.mealType = mealType.rawValue
        foodRecord.quantity = NSDecimalNumber(decimal: quantity)
        foodRecord.quantityUnit = quantityUnit.rawValue
        foodRecord.calculatedCalories = nutritionValues.calories
        foodRecord.calculatedCarbs = NSDecimalNumber(decimal: nutritionValues.carbs)
        foodRecord.calculatedProtein = NSDecimalNumber(decimal: nutritionValues.protein)
        foodRecord.calculatedFat = NSDecimalNumber(decimal: nutritionValues.fat)
        foodRecord.createdAt = Date()

        // User 연결 (필수 relationship)
        let userRequest: NSFetchRequest<User> = User.fetchRequest()
        userRequest.predicate = NSPredicate(format: "id == %@", userId as CVarArg)
        userRequest.fetchLimit = 1
        if let user = try context.fetch(userRequest).first {
            foodRecord.user = user
        }

        let savedFoodRecord = try await foodRecordRepository.save(foodRecord)

        // 4. DailyLog 조회 또는 생성
        let dailyLog = try await dailyLogRepository.getOrCreate(
            for: date,
            userId: userId,
            bmr: bmr,
            tdee: tdee
        )

        // 5. DailyLog에 영양소 추가 (additive)
        updateDailyLogWithAddition(
            dailyLog: dailyLog,
            calories: nutritionValues.calories,
            carbs: nutritionValues.carbs,
            protein: nutritionValues.protein,
            fat: nutritionValues.fat
        )

        // 6. DailyLog 저장
        _ = try await dailyLogRepository.update(dailyLog)

        return savedFoodRecord
    }

    func updateFoodRecord(
        foodRecordId: UUID,
        quantity: Decimal,
        quantityUnit: QuantityUnit,
        mealType: MealType?
    ) async throws -> FoodRecord {
        // 1. 기존 FoodRecord 조회
        guard let foodRecord = try await foodRecordRepository.findById(foodRecordId) else {
            throw ServiceError.foodRecordNotFound
        }

        // 2. Food 정보 조회
        guard let food = foodRecord.food else {
            throw ServiceError.foodNotFound
        }

        // 3. 이전 영양소 값 저장
        let oldCalories = foodRecord.calculatedCalories
        let oldCarbs = foodRecord.calculatedCarbs?.decimalValue ?? Decimal(0)
        let oldProtein = foodRecord.calculatedProtein?.decimalValue ?? Decimal(0)
        let oldFat = foodRecord.calculatedFat?.decimalValue ?? Decimal(0)

        // 4. 새로운 영양소 계산
        let nutritionValues = calculateNutrition(
            food: food,
            quantity: quantity,
            quantityUnit: quantityUnit
        )

        // 5. FoodRecord 업데이트 (Core Data 엔티티 직접 수정)
        foodRecord.quantity = NSDecimalNumber(decimal: quantity)
        foodRecord.quantityUnit = quantityUnit.rawValue
        foodRecord.calculatedCalories = nutritionValues.calories
        foodRecord.calculatedCarbs = NSDecimalNumber(decimal: nutritionValues.carbs)
        foodRecord.calculatedProtein = NSDecimalNumber(decimal: nutritionValues.protein)
        foodRecord.calculatedFat = NSDecimalNumber(decimal: nutritionValues.fat)

        if let newMealType = mealType {
            foodRecord.mealType = newMealType.rawValue
        }

        let updatedFoodRecord = try await foodRecordRepository.update(foodRecord)

        // 6. DailyLog 조회
        guard let recordDate = foodRecord.date,
              let user = foodRecord.user,
              let userId = user.id else {
            throw ServiceError.dailyLogNotFound
        }

        guard let dailyLog = try await dailyLogRepository.fetch(
            for: recordDate,
            userId: userId
        ) else {
            throw ServiceError.dailyLogNotFound
        }

        // 7. DailyLog에서 이전 값 차감
        updateDailyLogWithDeletion(
            dailyLog: dailyLog,
            calories: oldCalories,
            carbs: oldCarbs,
            protein: oldProtein,
            fat: oldFat
        )

        // 8. DailyLog에 새로운 값 추가
        updateDailyLogWithAddition(
            dailyLog: dailyLog,
            calories: nutritionValues.calories,
            carbs: nutritionValues.carbs,
            protein: nutritionValues.protein,
            fat: nutritionValues.fat
        )

        // 9. DailyLog 저장
        _ = try await dailyLogRepository.update(dailyLog)

        return updatedFoodRecord
    }

    func deleteFoodRecord(foodRecordId: UUID) async throws {
        // 1. FoodRecord 조회
        guard let foodRecord = try await foodRecordRepository.findById(foodRecordId) else {
            throw ServiceError.foodRecordNotFound
        }

        // 2. DailyLog 조회
        guard let recordDate = foodRecord.date,
              let user = foodRecord.user,
              let userId = user.id else {
            throw ServiceError.dailyLogNotFound
        }

        guard let dailyLog = try await dailyLogRepository.fetch(
            for: recordDate,
            userId: userId
        ) else {
            throw ServiceError.dailyLogNotFound
        }

        // 3. DailyLog 총합에서 차감
        updateDailyLogWithDeletion(
            dailyLog: dailyLog,
            calories: foodRecord.calculatedCalories,
            carbs: foodRecord.calculatedCarbs?.decimalValue ?? Decimal(0),
            protein: foodRecord.calculatedProtein?.decimalValue ?? Decimal(0),
            fat: foodRecord.calculatedFat?.decimalValue ?? Decimal(0)
        )

        // 4. DailyLog 저장
        _ = try await dailyLogRepository.update(dailyLog)

        // 5. FoodRecord 삭제
        try await foodRecordRepository.delete(foodRecordId)
    }

    // MARK: - Query Operations

    func getFoodRecords(for date: Date, userId: UUID) async throws -> [FoodRecord] {
        return try await foodRecordRepository.findByDate(date, userId: userId)
    }

    func getFoodRecords(for date: Date, mealType: MealType, userId: UUID) async throws -> [FoodRecord] {
        return try await foodRecordRepository.findByDateAndMealType(date, mealType: mealType, userId: userId)
    }

    // MARK: - Gemini AI Food Record

    func addFoodRecordFromGemini(
        userId: UUID,
        foodName: String,
        date: Date,
        mealType: MealType,
        estimatedGrams: Double,
        calories: Double,
        carbohydrates: Double,
        protein: Double,
        fat: Double,
        bmr: Int32,
        tdee: Int32
    ) async throws -> FoodRecord {
        // 1. Food 엔티티 조회 또는 생성 (이름 기반)
        let food: Food
        let searchResults = try await foodRepository.search(name: foodName)
        if let existingFood = searchResults.first(where: { $0.name == foodName }) {
            food = existingFood
        } else {
            // AI 분석 결과로 새 Food 엔티티 생성
            let newFood = Food(context: context)
            newFood.id = UUID()
            newFood.name = foodName
            newFood.calories = Int32((calories / (estimatedGrams / 100.0)).rounded()) // 100g 기준
            newFood.carbohydrates = NSDecimalNumber(value: carbohydrates / (estimatedGrams / 100.0))
            newFood.protein = NSDecimalNumber(value: protein / (estimatedGrams / 100.0))
            newFood.fat = NSDecimalNumber(value: fat / (estimatedGrams / 100.0))
            newFood.servingSize = NSDecimalNumber(value: estimatedGrams)
            newFood.servingUnit = "g"
            newFood.source = FoodSource.userDefined.rawValue
            newFood.createdAt = Date()
            food = newFood
        }

        // 2. FoodRecord 생성 (AI 추정값 직접 사용)
        let caloriesInt32 = Int32(calories.rounded())
        let carbsDecimal = Decimal(carbohydrates)
        let proteinDecimal = Decimal(protein)
        let fatDecimal = Decimal(fat)

        let foodRecord = FoodRecord(context: context)
        foodRecord.id = UUID()
        foodRecord.food = food
        foodRecord.date = date
        foodRecord.mealType = mealType.rawValue
        foodRecord.quantity = NSDecimalNumber(value: estimatedGrams)
        foodRecord.quantityUnit = QuantityUnit.grams.rawValue
        foodRecord.calculatedCalories = caloriesInt32
        foodRecord.calculatedCarbs = NSDecimalNumber(decimal: carbsDecimal)
        foodRecord.calculatedProtein = NSDecimalNumber(decimal: proteinDecimal)
        foodRecord.calculatedFat = NSDecimalNumber(decimal: fatDecimal)
        foodRecord.createdAt = Date()

        // User 연결 (필수 relationship)
        let userRequest: NSFetchRequest<User> = User.fetchRequest()
        userRequest.predicate = NSPredicate(format: "id == %@", userId as CVarArg)
        userRequest.fetchLimit = 1
        if let user = try context.fetch(userRequest).first {
            foodRecord.user = user
        }

        let savedFoodRecord = try await foodRecordRepository.save(foodRecord)

        // 3. DailyLog 업데이트
        let dailyLog = try await dailyLogRepository.getOrCreate(
            for: date,
            userId: userId,
            bmr: bmr,
            tdee: tdee
        )

        updateDailyLogWithAddition(
            dailyLog: dailyLog,
            calories: caloriesInt32,
            carbs: carbsDecimal,
            protein: proteinDecimal,
            fat: fatDecimal
        )

        _ = try await dailyLogRepository.update(dailyLog)

        return savedFoodRecord
    }

    // MARK: - Private Helpers

    /// Food 정보와 섭취량을 기반으로 실제 영양소 값을 계산합니다.
    ///
    /// - Parameters:
    ///   - food: 음식 정보
    ///   - quantity: 섭취량
    ///   - quantityUnit: 섭취량 단위
    /// - Returns: 계산된 영양소 값
    private func calculateNutrition(
        food: Food,
        quantity: Decimal,
        quantityUnit: QuantityUnit
    ) -> (calories: Int32, carbs: Decimal, protein: Decimal, fat: Decimal) {
        // NutritionCalculator 사용
        let nutrition = NutritionCalculator.calculateNutrition(
            food: food,
            quantity: quantity,
            unit: quantityUnit
        )

        return (nutrition.calories, nutrition.carbs, nutrition.protein, nutrition.fat)
    }

    /// DailyLog에 영양소를 추가하고 비율과 순 칼로리를 재계산합니다.
    ///
    /// - Parameters:
    ///   - dailyLog: 업데이트할 DailyLog (Core Data 엔티티)
    ///   - calories: 추가할 칼로리 (kcal)
    ///   - carbs: 추가할 탄수화물 (g)
    ///   - protein: 추가할 단백질 (g)
    ///   - fat: 추가할 지방 (g)
    private func updateDailyLogWithAddition(
        dailyLog: DailyLog,
        calories: Int32,
        carbs: Decimal,
        protein: Decimal,
        fat: Decimal
    ) {
        // 총합 증가
        dailyLog.totalCaloriesIn += calories

        let currentCarbs = dailyLog.totalCarbs?.decimalValue ?? Decimal(0)
        let currentProtein = dailyLog.totalProtein?.decimalValue ?? Decimal(0)
        let currentFat = dailyLog.totalFat?.decimalValue ?? Decimal(0)

        dailyLog.totalCarbs = NSDecimalNumber(decimal: currentCarbs + carbs)
        dailyLog.totalProtein = NSDecimalNumber(decimal: currentProtein + protein)
        dailyLog.totalFat = NSDecimalNumber(decimal: currentFat + fat)

        // 매크로 비율 재계산
        let newCarbs = dailyLog.totalCarbs?.decimalValue ?? Decimal(0)
        let newProtein = dailyLog.totalProtein?.decimalValue ?? Decimal(0)
        let newFat = dailyLog.totalFat?.decimalValue ?? Decimal(0)

        let macroRatios = calculateMacroRatios(
            carbs: newCarbs,
            protein: newProtein,
            fat: newFat
        )
        if let carbsRatio = macroRatios.carbsRatio {
            dailyLog.carbsRatio = NSDecimalNumber(decimal: carbsRatio)
        }
        if let proteinRatio = macroRatios.proteinRatio {
            dailyLog.proteinRatio = NSDecimalNumber(decimal: proteinRatio)
        }
        if let fatRatio = macroRatios.fatRatio {
            dailyLog.fatRatio = NSDecimalNumber(decimal: fatRatio)
        }

        // 순 칼로리 재계산
        dailyLog.netCalories = dailyLog.totalCaloriesIn - dailyLog.tdee

        // 수정일시 업데이트
        dailyLog.updatedAt = Date()
    }

    /// DailyLog에서 영양소를 차감하고 비율과 순 칼로리를 재계산합니다.
    ///
    /// - Parameters:
    ///   - dailyLog: 업데이트할 DailyLog (Core Data 엔티티)
    ///   - calories: 차감할 칼로리 (kcal)
    ///   - carbs: 차감할 탄수화물 (g)
    ///   - protein: 차감할 단백질 (g)
    ///   - fat: 차감할 지방 (g)
    private func updateDailyLogWithDeletion(
        dailyLog: DailyLog,
        calories: Int32,
        carbs: Decimal,
        protein: Decimal,
        fat: Decimal
    ) {
        // 총합 감소 (음수가 되지 않도록 max(0, ...) 처리)
        dailyLog.totalCaloriesIn = max(0, dailyLog.totalCaloriesIn - calories)

        let currentCarbs = dailyLog.totalCarbs?.decimalValue ?? Decimal(0)
        let currentProtein = dailyLog.totalProtein?.decimalValue ?? Decimal(0)
        let currentFat = dailyLog.totalFat?.decimalValue ?? Decimal(0)

        dailyLog.totalCarbs = NSDecimalNumber(decimal: max(0, currentCarbs - carbs))
        dailyLog.totalProtein = NSDecimalNumber(decimal: max(0, currentProtein - protein))
        dailyLog.totalFat = NSDecimalNumber(decimal: max(0, currentFat - fat))

        // 매크로 비율 재계산
        let newCarbs = dailyLog.totalCarbs?.decimalValue ?? Decimal(0)
        let newProtein = dailyLog.totalProtein?.decimalValue ?? Decimal(0)
        let newFat = dailyLog.totalFat?.decimalValue ?? Decimal(0)

        let macroRatios = calculateMacroRatios(
            carbs: newCarbs,
            protein: newProtein,
            fat: newFat
        )
        if let carbsRatio = macroRatios.carbsRatio {
            dailyLog.carbsRatio = NSDecimalNumber(decimal: carbsRatio)
        }
        if let proteinRatio = macroRatios.proteinRatio {
            dailyLog.proteinRatio = NSDecimalNumber(decimal: proteinRatio)
        }
        if let fatRatio = macroRatios.fatRatio {
            dailyLog.fatRatio = NSDecimalNumber(decimal: fatRatio)
        }

        // 순 칼로리 재계산
        dailyLog.netCalories = dailyLog.totalCaloriesIn - dailyLog.tdee

        // 수정일시 업데이트
        dailyLog.updatedAt = Date()
    }

    /// 매크로 영양소 비율을 계산합니다.
    ///
    /// 각 영양소의 칼로리를 계산하여 전체 칼로리 대비 비율을 구합니다.
    /// - 탄수화물: 1g = 4 kcal
    /// - 단백질: 1g = 4 kcal
    /// - 지방: 1g = 9 kcal
    ///
    /// - Parameters:
    ///   - carbs: 탄수화물 (g)
    ///   - protein: 단백질 (g)
    ///   - fat: 지방 (g)
    /// - Returns: 각 영양소의 비율 (%) 또는 nil (총 칼로리가 0인 경우)
    private func calculateMacroRatios(
        carbs: Decimal,
        protein: Decimal,
        fat: Decimal
    ) -> (carbsRatio: Decimal?, proteinRatio: Decimal?, fatRatio: Decimal?) {
        // NutritionCalculator 사용
        let ratios = NutritionCalculator.calculateMacroRatios(
            carbs: carbs,
            protein: protein,
            fat: fat
        )

        return (ratios.carbsRatio, ratios.proteinRatio, ratios.fatRatio)
    }
}

// MARK: - Service Errors

/// 서비스 레이어에서 발생하는 에러
enum ServiceError: Error, LocalizedError {
    case foodNotFound
    case foodRecordNotFound
    case dailyLogNotFound
    case invalidQuantity

    var errorDescription: String? {
        switch self {
        case .foodNotFound:
            return "음식을 찾을 수 없습니다"
        case .foodRecordNotFound:
            return "식단 기록을 찾을 수 없습니다"
        case .dailyLogNotFound:
            return "일일 집계를 찾을 수 없습니다"
        case .invalidQuantity:
            return "섭취량은 0보다 커야 합니다"
        }
    }
}
