//
//  CustomFoodEditViewModel.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-31.
//

import Foundation
import CoreData

/// 커스텀 음식 수정 화면의 ViewModel
@MainActor
final class CustomFoodEditViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var foodName: String = ""
    @Published var servingSize: String = ""
    @Published var servingUnit: String = ""
    @Published var calories: String = ""
    @Published var carbohydrates: String = ""
    @Published var protein: String = ""
    @Published var fat: String = ""
    @Published var sodium: String = ""
    @Published var fiber: String = ""
    @Published var sugar: String = ""
    @Published var isSaving: Bool = false
    @Published var errorMessage: String?
    @Published var validationErrors: FoodValidationErrors = FoodValidationErrors()

    // MARK: - Private Properties

    private let food: Food
    private let context: NSManagedObjectContext

    // MARK: - Initialization

    init(food: Food, context: NSManagedObjectContext) {
        self.food = food
        self.context = context

        // 기존 값으로 초기화
        foodName = food.name ?? ""
        servingSize = food.servingSize.map { "\($0)" } ?? ""
        servingUnit = food.servingUnit ?? ""
        calories = "\(food.calories)"
        carbohydrates = food.carbohydrates.map { "\($0)" } ?? ""
        protein = food.protein.map { "\($0)" } ?? ""
        fat = food.fat.map { "\($0)" } ?? ""
        sodium = food.sodium.map { "\($0)" } ?? ""
        fiber = food.fiber.map { "\($0)" } ?? ""
        sugar = food.sugar.map { "\($0)" } ?? ""
    }

    // MARK: - Public Methods

    /// 수정된 음식을 저장합니다.
    func saveChanges() async throws {
        guard validate() else {
            throw ServiceError.invalidQuantity
        }

        isSaving = true
        errorMessage = nil

        do {
            food.name = foodName.trimmingCharacters(in: .whitespacesAndNewlines)
            food.calories = parsedCalories
            food.carbohydrates = NSDecimalNumber(decimal: parsedCarbohydrates)
            food.protein = NSDecimalNumber(decimal: parsedProtein)
            food.fat = NSDecimalNumber(decimal: parsedFat)
            food.sodium = parsedSodium.map { NSDecimalNumber(decimal: $0) }
            food.fiber = parsedFiber.map { NSDecimalNumber(decimal: $0) }
            food.sugar = parsedSugar.map { NSDecimalNumber(decimal: $0) }
            food.servingSize = NSDecimalNumber(decimal: parsedServingSize)
            food.servingUnit = servingUnit.isEmpty ? nil : servingUnit.trimmingCharacters(in: .whitespacesAndNewlines)

            try context.save()
            isSaving = false
        } catch {
            isSaving = false
            errorMessage = "저장 실패: \(error.localizedDescription)"
            throw error
        }
    }

    // MARK: - Validation

    private func validate() -> Bool {
        validationErrors = FoodValidationErrors()
        var isValid = true

        let trimmedName = foodName.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedName.isEmpty {
            validationErrors.foodName = "음식명을 입력해주세요"
            isValid = false
        } else if trimmedName.count > 100 {
            validationErrors.foodName = "음식명은 100자 이내로 입력해주세요"
            isValid = false
        }

        if calories.isEmpty {
            validationErrors.calories = "칼로리를 입력해주세요"
            isValid = false
        } else if parsedCalories < 0 {
            validationErrors.calories = "칼로리는 0 이상이어야 합니다"
            isValid = false
        }

        if servingSize.isEmpty {
            validationErrors.servingSize = "1회 제공량을 입력해주세요"
            isValid = false
        } else if parsedServingSize <= 0 {
            validationErrors.servingSize = "1회 제공량은 0보다 커야 합니다"
            isValid = false
        }

        return isValid
    }
}

// MARK: - Computed Properties

extension CustomFoodEditViewModel {

    var parsedCalories: Int32 { Int32(calories) ?? 0 }
    var parsedServingSize: Decimal { Decimal(string: servingSize) ?? 0 }
    var parsedCarbohydrates: Decimal { carbohydrates.isEmpty ? 0 : (Decimal(string: carbohydrates) ?? 0) }
    var parsedProtein: Decimal { protein.isEmpty ? 0 : (Decimal(string: protein) ?? 0) }
    var parsedFat: Decimal { fat.isEmpty ? 0 : (Decimal(string: fat) ?? 0) }

    var parsedSodium: Decimal? {
        guard !sodium.isEmpty, let value = Decimal(string: sodium) else { return nil }
        return value
    }

    var parsedFiber: Decimal? {
        guard !fiber.isEmpty, let value = Decimal(string: fiber) else { return nil }
        return value
    }

    var parsedSugar: Decimal? {
        guard !sugar.isEmpty, let value = Decimal(string: sugar) else { return nil }
        return value
    }

    var canSave: Bool {
        !isSaving &&
        !foodName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !calories.isEmpty &&
        !servingSize.isEmpty
    }
}
