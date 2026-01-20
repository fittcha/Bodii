//
//  ManualFoodEntryViewModel.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-13.
//

import Foundation
import Combine

/// 음식 직접 입력 화면의 ViewModel
///
/// 사용자가 데이터베이스에 없는 음식을 직접 입력하여 저장하고 식단에 추가합니다.
/// 필수 입력값(음식명, 칼로리, 1회 제공량)을 검증하고 선택적 영양소 정보도 지원합니다.
///
/// - Note: ObservableObject를 준수하여 SwiftUI View와 바인딩됩니다.
/// - Note: 저장된 음식은 FoodSource.userDefined로 분류되어 사용자 정의 음식으로 관리됩니다.
///
/// - Example:
/// ```swift
/// let viewModel = ManualFoodEntryViewModel(
///     foodRepository: foodRepository,
///     foodRecordService: foodRecordService
/// )
/// viewModel.onAppear(
///     userId: userId,
///     date: Date(),
///     mealType: .breakfast,
///     bmr: 1650,
///     tdee: 2310
/// )
/// viewModel.foodName = "수제 샐러드"
/// viewModel.calories = "350"
/// viewModel.servingSize = "250"
/// try await viewModel.saveFood()
/// ```
@MainActor
final class ManualFoodEntryViewModel: ObservableObject {

    // MARK: - Published Properties

    /// 음식명 (필수)
    @Published var foodName: String = ""

    /// 1회 제공량 (g) (필수)
    @Published var servingSize: String = ""

    /// 단위 설명 (예: "1인분", "1개", "1공기")
    @Published var servingUnit: String = ""

    /// 칼로리 (kcal) (필수)
    @Published var calories: String = ""

    /// 탄수화물 (g)
    @Published var carbohydrates: String = ""

    /// 단백질 (g)
    @Published var protein: String = ""

    /// 지방 (g)
    @Published var fat: String = ""

    /// 나트륨 (mg)
    @Published var sodium: String = ""

    /// 식이섬유 (g)
    @Published var fiber: String = ""

    /// 당류 (g)
    @Published var sugar: String = ""

    /// 저장 중 여부
    @Published var isSaving: Bool = false

    /// 에러 메시지
    @Published var errorMessage: String?

    /// 필드별 유효성 검증 에러
    @Published var validationErrors: FoodValidationErrors = FoodValidationErrors()

    // MARK: - Private Properties

    /// 음식 Repository
    private let foodRepository: FoodRepositoryProtocol

    /// 식단 기록 서비스
    private let foodRecordService: FoodRecordServiceProtocol

    /// 현재 사용자 ID
    private var currentUserId: UUID?

    /// 섭취 날짜
    private var currentDate: Date?

    /// 선택된 끼니 종류
    private var currentMealType: MealType = .breakfast

    /// 기초대사량 (kcal)
    private var currentBMR: Int32 = 0

    /// 활동대사량 (kcal)
    private var currentTDEE: Int32 = 0

    // MARK: - Initialization

    /// ManualFoodEntryViewModel을 초기화합니다.
    ///
    /// - Parameters:
    ///   - foodRepository: 음식 Repository
    ///   - foodRecordService: 식단 기록 서비스
    init(
        foodRepository: FoodRepositoryProtocol,
        foodRecordService: FoodRecordServiceProtocol
    ) {
        self.foodRepository = foodRepository
        self.foodRecordService = foodRecordService
    }

    // MARK: - Public Methods

    /// 화면 진입 시 호출됩니다.
    ///
    /// - Parameters:
    ///   - userId: 사용자 ID
    ///   - date: 섭취 날짜
    ///   - mealType: 끼니 종류
    ///   - bmr: 기초대사량 (kcal)
    ///   - tdee: 활동대사량 (kcal)
    func onAppear(
        userId: UUID,
        date: Date,
        mealType: MealType,
        bmr: Int32,
        tdee: Int32
    ) {
        self.currentUserId = userId
        self.currentDate = date
        self.currentMealType = mealType
        self.currentBMR = bmr
        self.currentTDEE = tdee
    }

    /// 음식을 저장하고 식단에 추가합니다.
    ///
    /// 이 메서드는 다음 작업을 수행합니다:
    /// 1. 입력값 유효성 검증
    /// 2. Food 엔티티 생성 (source: userDefined)
    /// 3. FoodRepository에 저장
    /// 4. FoodRecordService를 통해 식단에 추가 (1인분 기준)
    ///
    /// - Throws: 유효성 검증 실패 또는 저장 중 에러 발생 시
    func saveFood() async throws {
        guard let userId = currentUserId,
              let date = currentDate else {
            throw ServiceError.invalidQuantity
        }

        // 유효성 검증
        guard validate() else {
            throw ServiceError.invalidQuantity
        }

        isSaving = true
        errorMessage = nil

        do {
            // Food 엔티티 생성
            let food = Food(
                id: UUID(),
                name: foodName.trimmingCharacters(in: .whitespacesAndNewlines),
                calories: parsedCalories,
                carbohydrates: parsedCarbohydrates,
                protein: parsedProtein,
                fat: parsedFat,
                sodium: parsedSodium,
                fiber: parsedFiber,
                sugar: parsedSugar,
                servingSize: parsedServingSize,
                servingUnit: servingUnit.isEmpty ? nil : servingUnit.trimmingCharacters(in: .whitespacesAndNewlines),
                source: .userDefined,
                apiCode: nil,
                createdByUserId: userId,
                createdAt: Date()
            )

            // Food 저장
            let savedFood = try await foodRepository.save(food)

            // 식단에 추가 (기본 1인분)
            _ = try await foodRecordService.addFoodRecord(
                userId: userId,
                foodId: savedFood.id,
                date: date,
                mealType: currentMealType,
                quantity: 1.0,
                quantityUnit: .serving,
                bmr: currentBMR,
                tdee: currentTDEE
            )

            isSaving = false
        } catch {
            isSaving = false
            handleError(error)
            throw error
        }
    }

    /// 모든 입력 필드를 초기화합니다.
    func clearFields() {
        foodName = ""
        servingSize = ""
        servingUnit = ""
        calories = ""
        carbohydrates = ""
        protein = ""
        fat = ""
        sodium = ""
        fiber = ""
        sugar = ""
        validationErrors = FoodValidationErrors()
        errorMessage = nil
    }

    // MARK: - Private Methods

    /// 입력값의 유효성을 검증합니다.
    ///
    /// - Returns: 모든 필수 입력값이 유효한지 여부
    private func validate() -> Bool {
        validationErrors = FoodValidationErrors()
        var isValid = true

        // 음식명 검증 (필수)
        let trimmedName = foodName.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedName.isEmpty {
            validationErrors.foodName = "음식명을 입력해주세요"
            isValid = false
        } else if trimmedName.count > 100 {
            validationErrors.foodName = "음식명은 100자 이내로 입력해주세요"
            isValid = false
        }

        // 칼로리 검증 (필수)
        if calories.isEmpty {
            validationErrors.calories = "칼로리를 입력해주세요"
            isValid = false
        } else if parsedCalories < 0 {
            validationErrors.calories = "칼로리는 0 이상이어야 합니다"
            isValid = false
        } else if parsedCalories > 9999 {
            validationErrors.calories = "칼로리는 9999 이하로 입력해주세요"
            isValid = false
        }

        // 1회 제공량 검증 (필수)
        if servingSize.isEmpty {
            validationErrors.servingSize = "1회 제공량을 입력해주세요"
            isValid = false
        } else if parsedServingSize <= 0 {
            validationErrors.servingSize = "1회 제공량은 0보다 커야 합니다"
            isValid = false
        } else if parsedServingSize > 9999 {
            validationErrors.servingSize = "1회 제공량은 9999g 이하로 입력해주세요"
            isValid = false
        }

        // 탄수화물 검증 (선택)
        if !carbohydrates.isEmpty && parsedCarbohydrates < 0 {
            validationErrors.carbohydrates = "탄수화물은 0 이상이어야 합니다"
            isValid = false
        }

        // 단백질 검증 (선택)
        if !protein.isEmpty && parsedProtein < 0 {
            validationErrors.protein = "단백질은 0 이상이어야 합니다"
            isValid = false
        }

        // 지방 검증 (선택)
        if !fat.isEmpty && parsedFat < 0 {
            validationErrors.fat = "지방은 0 이상이어야 합니다"
            isValid = false
        }

        // 나트륨 검증 (선택)
        if !sodium.isEmpty && parsedSodium ?? -1 < 0 {
            validationErrors.sodium = "나트륨은 0 이상이어야 합니다"
            isValid = false
        }

        // 식이섬유 검증 (선택)
        if !fiber.isEmpty && parsedFiber ?? -1 < 0 {
            validationErrors.fiber = "식이섬유는 0 이상이어야 합니다"
            isValid = false
        }

        // 당류 검증 (선택)
        if !sugar.isEmpty && parsedSugar ?? -1 < 0 {
            validationErrors.sugar = "당류는 0 이상이어야 합니다"
            isValid = false
        }

        return isValid
    }

    /// 에러를 처리합니다.
    ///
    /// - Parameter error: 발생한 에러
    private func handleError(_ error: Error) {
        // 에러 메시지 설정
        if let repositoryError = error as? RepositoryError {
            errorMessage = repositoryError.localizedDescription
        } else if let serviceError = error as? ServiceError {
            errorMessage = serviceError.localizedDescription
        } else {
            errorMessage = "오류가 발생했습니다: \(error.localizedDescription)"
        }
    }
}

// MARK: - Computed Properties

extension ManualFoodEntryViewModel {

    /// 파싱된 칼로리 (Int32)
    var parsedCalories: Int32 {
        Int32(calories) ?? 0
    }

    /// 파싱된 1회 제공량 (Decimal)
    var parsedServingSize: Decimal {
        Decimal(string: servingSize) ?? 0
    }

    /// 파싱된 탄수화물 (Decimal)
    var parsedCarbohydrates: Decimal {
        carbohydrates.isEmpty ? 0 : (Decimal(string: carbohydrates) ?? 0)
    }

    /// 파싱된 단백질 (Decimal)
    var parsedProtein: Decimal {
        protein.isEmpty ? 0 : (Decimal(string: protein) ?? 0)
    }

    /// 파싱된 지방 (Decimal)
    var parsedFat: Decimal {
        fat.isEmpty ? 0 : (Decimal(string: fat) ?? 0)
    }

    /// 파싱된 나트륨 (Decimal?, 선택적)
    var parsedSodium: Decimal? {
        guard !sodium.isEmpty,
              let value = Decimal(string: sodium) else { return nil }
        return value
    }

    /// 파싱된 식이섬유 (Decimal?, 선택적)
    var parsedFiber: Decimal? {
        guard !fiber.isEmpty,
              let value = Decimal(string: fiber) else { return nil }
        return value
    }

    /// 파싱된 당류 (Decimal?, 선택적)
    var parsedSugar: Decimal? {
        guard !sugar.isEmpty,
              let value = Decimal(string: sugar) else { return nil }
        return value
    }

    /// 저장 가능 여부
    var canSave: Bool {
        !isSaving &&
        !foodName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !calories.isEmpty &&
        !servingSize.isEmpty
    }

    /// 필수 필드가 모두 입력되었는지 여부
    var hasRequiredFields: Bool {
        !foodName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !calories.isEmpty &&
        !servingSize.isEmpty
    }
}

// MARK: - FoodValidationErrors

/// 필드별 유효성 검증 에러
struct FoodValidationErrors {
    var foodName: String?
    var calories: String?
    var servingSize: String?
    var carbohydrates: String?
    var protein: String?
    var fat: String?
    var sodium: String?
    var fiber: String?
    var sugar: String?

    /// 에러가 있는지 여부
    var hasErrors: Bool {
        foodName != nil ||
        calories != nil ||
        servingSize != nil ||
        carbohydrates != nil ||
        protein != nil ||
        fat != nil ||
        sodium != nil ||
        fiber != nil ||
        sugar != nil
    }
}
