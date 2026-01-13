//
//  FoodRecordService.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-13.
//

import Foundation

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
///     foodRepository: foodRepository
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
    private let dailyLogRepository: DailyLogRepositoryProtocol

    /// Food Repository
    private let foodRepository: FoodRepositoryProtocol

    // MARK: - Initialization

    /// FoodRecordService를 초기화합니다.
    ///
    /// - Parameters:
    ///   - foodRecordRepository: FoodRecord Repository
    ///   - dailyLogRepository: DailyLog Repository
    ///   - foodRepository: Food Repository
    init(
        foodRecordRepository: FoodRecordRepositoryProtocol,
        dailyLogRepository: DailyLogRepositoryProtocol,
        foodRepository: FoodRepositoryProtocol
    ) {
        self.foodRecordRepository = foodRecordRepository
        self.dailyLogRepository = dailyLogRepository
        self.foodRepository = foodRepository
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

        // 3. FoodRecord 생성 및 저장
        let foodRecord = FoodRecord(
            id: UUID(),
            userId: userId,
            foodId: foodId,
            date: date,
            mealType: mealType,
            quantity: quantity,
            quantityUnit: quantityUnit,
            calculatedCalories: nutritionValues.calories,
            calculatedCarbs: nutritionValues.carbs,
            calculatedProtein: nutritionValues.protein,
            calculatedFat: nutritionValues.fat,
            createdAt: Date()
        )

        let savedFoodRecord = try await foodRecordRepository.save(foodRecord)

        // 4. DailyLog 조회 또는 생성
        var dailyLog = try await dailyLogRepository.getOrCreate(
            for: date,
            userId: userId,
            bmr: bmr,
            tdee: tdee
        )

        // 5. DailyLog 총합 업데이트
        dailyLog = updateDailyLogWithAddition(
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
        guard var foodRecord = try await foodRecordRepository.findById(foodRecordId) else {
            throw ServiceError.foodRecordNotFound
        }

        // 2. Food 정보 조회
        guard let food = try await foodRepository.findById(foodRecord.foodId) else {
            throw ServiceError.foodNotFound
        }

        // 3. 이전 영양소 값 저장
        let oldCalories = foodRecord.calculatedCalories
        let oldCarbs = foodRecord.calculatedCarbs
        let oldProtein = foodRecord.calculatedProtein
        let oldFat = foodRecord.calculatedFat

        // 4. 새로운 영양소 계산
        let nutritionValues = calculateNutrition(
            food: food,
            quantity: quantity,
            quantityUnit: quantityUnit
        )

        // 5. FoodRecord 업데이트
        foodRecord.quantity = quantity
        foodRecord.quantityUnit = quantityUnit
        foodRecord.calculatedCalories = nutritionValues.calories
        foodRecord.calculatedCarbs = nutritionValues.carbs
        foodRecord.calculatedProtein = nutritionValues.protein
        foodRecord.calculatedFat = nutritionValues.fat

        if let newMealType = mealType {
            foodRecord.mealType = newMealType
        }

        let updatedFoodRecord = try await foodRecordRepository.update(foodRecord)

        // 6. DailyLog 조회
        guard var dailyLog = try await dailyLogRepository.findByDate(
            foodRecord.date,
            userId: foodRecord.userId
        ) else {
            throw ServiceError.dailyLogNotFound
        }

        // 7. DailyLog에서 이전 값 차감
        dailyLog = updateDailyLogWithDeletion(
            dailyLog: dailyLog,
            calories: oldCalories,
            carbs: oldCarbs,
            protein: oldProtein,
            fat: oldFat
        )

        // 8. DailyLog에 새로운 값 추가
        dailyLog = updateDailyLogWithAddition(
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
        guard var dailyLog = try await dailyLogRepository.findByDate(
            foodRecord.date,
            userId: foodRecord.userId
        ) else {
            throw ServiceError.dailyLogNotFound
        }

        // 3. DailyLog 총합에서 차감
        dailyLog = updateDailyLogWithDeletion(
            dailyLog: dailyLog,
            calories: foodRecord.calculatedCalories,
            carbs: foodRecord.calculatedCarbs,
            protein: foodRecord.calculatedProtein,
            fat: foodRecord.calculatedFat
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
        // Food의 영양소는 servingSize 기준
        let multiplier: Decimal

        switch quantityUnit {
        case .serving:
            // 인분 단위: quantity는 인분 수
            multiplier = quantity
        case .grams:
            // 그램 단위: quantity는 그램 수, servingSize로 나누어 인분 수 계산
            multiplier = quantity / food.servingSize
        }

        // 영양소 계산 (비례)
        let calories = Int32((Decimal(food.calories) * multiplier).rounded())
        let carbs = food.carbohydrates * multiplier
        let protein = food.protein * multiplier
        let fat = food.fat * multiplier

        return (calories, carbs, protein, fat)
    }

    /// DailyLog에 영양소를 추가하고 비율과 순 칼로리를 재계산합니다.
    ///
    /// - Parameters:
    ///   - dailyLog: 업데이트할 DailyLog
    ///   - calories: 추가할 칼로리 (kcal)
    ///   - carbs: 추가할 탄수화물 (g)
    ///   - protein: 추가할 단백질 (g)
    ///   - fat: 추가할 지방 (g)
    /// - Returns: 업데이트된 DailyLog
    private func updateDailyLogWithAddition(
        dailyLog: DailyLog,
        calories: Int32,
        carbs: Decimal,
        protein: Decimal,
        fat: Decimal
    ) -> DailyLog {
        var updatedLog = dailyLog

        // 총합 증가
        updatedLog.totalCaloriesIn += calories
        updatedLog.totalCarbs += carbs
        updatedLog.totalProtein += protein
        updatedLog.totalFat += fat

        // 매크로 비율 재계산
        let macroRatios = calculateMacroRatios(
            carbs: updatedLog.totalCarbs,
            protein: updatedLog.totalProtein,
            fat: updatedLog.totalFat
        )
        updatedLog.carbsRatio = macroRatios.carbsRatio
        updatedLog.proteinRatio = macroRatios.proteinRatio
        updatedLog.fatRatio = macroRatios.fatRatio

        // 순 칼로리 재계산
        updatedLog.netCalories = updatedLog.totalCaloriesIn - updatedLog.tdee

        // 수정일시 업데이트
        updatedLog.updatedAt = Date()

        return updatedLog
    }

    /// DailyLog에서 영양소를 차감하고 비율과 순 칼로리를 재계산합니다.
    ///
    /// - Parameters:
    ///   - dailyLog: 업데이트할 DailyLog
    ///   - calories: 차감할 칼로리 (kcal)
    ///   - carbs: 차감할 탄수화물 (g)
    ///   - protein: 차감할 단백질 (g)
    ///   - fat: 차감할 지방 (g)
    /// - Returns: 업데이트된 DailyLog
    private func updateDailyLogWithDeletion(
        dailyLog: DailyLog,
        calories: Int32,
        carbs: Decimal,
        protein: Decimal,
        fat: Decimal
    ) -> DailyLog {
        var updatedLog = dailyLog

        // 총합 감소 (음수가 되지 않도록 max(0, ...) 처리)
        updatedLog.totalCaloriesIn = max(0, updatedLog.totalCaloriesIn - calories)
        updatedLog.totalCarbs = max(0, updatedLog.totalCarbs - carbs)
        updatedLog.totalProtein = max(0, updatedLog.totalProtein - protein)
        updatedLog.totalFat = max(0, updatedLog.totalFat - fat)

        // 매크로 비율 재계산
        let macroRatios = calculateMacroRatios(
            carbs: updatedLog.totalCarbs,
            protein: updatedLog.totalProtein,
            fat: updatedLog.totalFat
        )
        updatedLog.carbsRatio = macroRatios.carbsRatio
        updatedLog.proteinRatio = macroRatios.proteinRatio
        updatedLog.fatRatio = macroRatios.fatRatio

        // 순 칼로리 재계산
        updatedLog.netCalories = updatedLog.totalCaloriesIn - updatedLog.tdee

        // 수정일시 업데이트
        updatedLog.updatedAt = Date()

        return updatedLog
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
        // 각 영양소의 칼로리 계산
        let carbsCalories = carbs * 4
        let proteinCalories = protein * 4
        let fatCalories = fat * 9

        let totalCalories = carbsCalories + proteinCalories + fatCalories

        // 총 칼로리가 0이면 비율을 계산할 수 없음
        guard totalCalories > 0 else {
            return (nil, nil, nil)
        }

        // 비율 계산 (백분율)
        let carbsRatio = (carbsCalories / totalCalories * 100).rounded(2)
        let proteinRatio = (proteinCalories / totalCalories * 100).rounded(2)
        let fatRatio = (fatCalories / totalCalories * 100).rounded(2)

        return (carbsRatio, proteinRatio, fatRatio)
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

// MARK: - Decimal Extensions

/// Decimal 소수점 반올림을 위한 확장
extension Decimal {
    /// 소수점 n자리에서 반올림합니다.
    ///
    /// - Parameter places: 소수점 자리수
    /// - Returns: 반올림된 Decimal 값
    func rounded(_ places: Int) -> Decimal {
        var result = self
        var rounded = Decimal()
        NSDecimalRound(&rounded, &result, places, .plain)
        return rounded
    }
}
