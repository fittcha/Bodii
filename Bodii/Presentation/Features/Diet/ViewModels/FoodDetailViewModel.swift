//
//  FoodDetailViewModel.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-13.
//

import Foundation
import Combine

/// 음식 상세 화면의 ViewModel
///
/// 음식의 영양 정보 표시, 섭취량 조절, 끼니 선택, 식단 기록 추가를 담당합니다.
/// 인분 단위와 그램 단위를 모두 지원하며, 실시간으로 영양소 계산을 업데이트합니다.
///
/// - Note: ObservableObject를 준수하여 SwiftUI View와 바인딩됩니다.
/// - Note: 섭취량은 최소 0.1 이상이어야 합니다.
///
/// - Example:
/// ```swift
/// let viewModel = FoodDetailViewModel(
///     foodRepository: foodRepository,
///     foodRecordService: foodRecordService
/// )
/// viewModel.onAppear(
///     foodId: foodId,
///     userId: userId,
///     date: Date(),
///     mealType: .breakfast,
///     bmr: 1650,
///     tdee: 2310
/// )
/// viewModel.quantity = 1.5
/// try await viewModel.saveFoodRecord()
/// ```
@MainActor
final class FoodDetailViewModel: ObservableObject {

    // MARK: - Published Properties

    /// 음식 정보
    @Published var food: Food?

    /// 섭취량 (unit에 따라 인분 또는 그램)
    @Published var quantity: Decimal = 1.0

    /// 섭취량 단위
    @Published var quantityUnit: QuantityUnit = .serving

    /// 선택된 끼니 종류
    @Published var selectedMealType: MealType = .breakfast

    /// 로딩 상태
    @Published var isLoading: Bool = false

    /// 저장 중 여부
    @Published var isSaving: Bool = false

    /// 에러 메시지
    @Published var errorMessage: String?

    /// 수량 유효성 검증 에러
    @Published var quantityError: String?

    // MARK: - Private Properties

    /// 음식 Repository
    private let foodRepository: FoodRepositoryProtocol

    /// 식단 기록 서비스
    private let foodRecordService: FoodRecordServiceProtocol

    /// 현재 음식 ID
    private var currentFoodId: UUID?

    /// 현재 사용자 ID
    private var currentUserId: UUID?

    /// 섭취 날짜
    private var currentDate: Date?

    /// 기초대사량 (kcal)
    private var currentBMR: Int32 = 0

    /// 활동대사량 (kcal)
    private var currentTDEE: Int32 = 0

    // MARK: - Constants

    /// 최소 섭취량
    private let minimumQuantity: Decimal = 0.1

    /// 프리셋 배수 (0.25x, 0.5x, 1x, 1.5x, 2x)
    let presetMultipliers: [Decimal] = [0.25, 0.5, 1.0, 1.5, 2.0]

    // MARK: - Initialization

    /// FoodDetailViewModel을 초기화합니다.
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
    /// 음식 정보를 불러오고 초기 섭취량을 설정합니다.
    ///
    /// - Parameters:
    ///   - foodId: 음식 ID
    ///   - userId: 사용자 ID
    ///   - date: 섭취 날짜
    ///   - mealType: 끼니 종류
    ///   - bmr: 기초대사량 (kcal)
    ///   - tdee: 활동대사량 (kcal)
    func onAppear(
        foodId: UUID,
        userId: UUID,
        date: Date,
        mealType: MealType,
        bmr: Int32,
        tdee: Int32
    ) {
        self.currentFoodId = foodId
        self.currentUserId = userId
        self.currentDate = date
        self.selectedMealType = mealType
        self.currentBMR = bmr
        self.currentTDEE = tdee

        loadFood()
    }

    /// 프리셋 배수로 섭취량을 설정합니다.
    ///
    /// - Parameter multiplier: 배수 (0.25, 0.5, 1.0, 1.5, 2.0 등)
    func setQuantityMultiplier(_ multiplier: Decimal) {
        quantity = multiplier
        quantityUnit = .serving
        validateQuantity()
    }

    /// 단위를 변경합니다.
    ///
    /// 인분 <-> 그램 간 변환 시 현재 섭취량을 유지합니다.
    ///
    /// - Parameter newUnit: 새로운 단위
    func changeUnit(to newUnit: QuantityUnit) {
        guard let food = food else { return }

        // 단위 변환 시 현재 섭취량을 유지
        let servingSizeValue = food.servingSize?.decimalValue ?? Decimal(100)
        if quantityUnit == .serving && newUnit == .grams {
            // 인분 -> 그램: servings * servingSize
            quantity = NutritionCalculator.servingsToGrams(
                servings: quantity,
                servingSize: servingSizeValue
            )
        } else if quantityUnit == .grams && newUnit == .serving {
            // 그램 -> 인분: grams / servingSize
            quantity = NutritionCalculator.gramsToServings(
                grams: quantity,
                servingSize: servingSizeValue
            )
        }

        quantityUnit = newUnit
        validateQuantity()
    }

    /// 섭취량을 유효성 검증합니다.
    ///
    /// - Returns: 유효한지 여부
    @discardableResult
    func validateQuantity() -> Bool {
        quantityError = nil

        if quantity < minimumQuantity {
            quantityError = "섭취량은 최소 \(minimumQuantity) 이상이어야 합니다."
            return false
        }

        return true
    }

    /// 식단 기록을 저장합니다.
    ///
    /// - Throws: 유효성 검증 실패 또는 저장 중 에러 발생 시
    func saveFoodRecord() async throws {
        guard let userId = currentUserId,
              let foodId = currentFoodId,
              let date = currentDate else {
            throw ServiceError.invalidQuantity
        }

        // 섭취량 유효성 검증
        guard validateQuantity() else {
            throw ServiceError.invalidQuantity
        }

        isSaving = true
        errorMessage = nil

        do {
            // 식단 기록 추가 (DailyLog 자동 업데이트됨)
            _ = try await foodRecordService.addFoodRecord(
                userId: userId,
                foodId: foodId,
                date: date,
                mealType: selectedMealType,
                quantity: quantity,
                quantityUnit: quantityUnit,
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

    // MARK: - Private Methods

    /// 음식 정보를 불러옵니다.
    private func loadFood() {
        guard let foodId = currentFoodId else { return }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                food = try await foodRepository.findById(foodId)
                isLoading = false
            } catch {
                handleError(error)
            }
        }
    }

    /// 에러를 처리합니다.
    ///
    /// - Parameter error: 발생한 에러
    private func handleError(_ error: Error) {
        isLoading = false
        isSaving = false

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

extension FoodDetailViewModel {

    /// 계산된 영양소 정보
    ///
    /// 현재 섭취량과 단위를 기반으로 실시간 계산합니다.
    var calculatedNutrition: NutritionValues? {
        guard let food = food else { return nil }

        return NutritionCalculator.calculateNutrition(
            food: food,
            quantity: quantity,
            unit: quantityUnit
        )
    }

    /// 계산된 칼로리 (kcal)
    var calculatedCalories: Int32 {
        calculatedNutrition?.calories ?? 0
    }

    /// 계산된 탄수화물 (g)
    var calculatedCarbs: Decimal {
        calculatedNutrition?.carbs ?? 0
    }

    /// 계산된 단백질 (g)
    var calculatedProtein: Decimal {
        calculatedNutrition?.protein ?? 0
    }

    /// 계산된 지방 (g)
    var calculatedFat: Decimal {
        calculatedNutrition?.fat ?? 0
    }

    /// 계산된 매크로 비율
    var calculatedMacroRatios: MacroRatios? {
        guard let nutrition = calculatedNutrition else { return nil }

        return NutritionCalculator.calculateMacroRatios(
            carbs: nutrition.carbs,
            protein: nutrition.protein,
            fat: nutrition.fat
        )
    }

    /// 현재 섭취량이 인분 기준인지 여부
    var isServingBased: Bool {
        quantityUnit == .serving
    }

    /// 현재 섭취량이 그램 기준인지 여부
    var isGramBased: Bool {
        quantityUnit == .grams
    }

    /// 섭취량 표시 문자열
    ///
    /// - Example: "1.5 인분" 또는 "315 g"
    var quantityText: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2

        let quantityStr = formatter.string(from: quantity as NSDecimalNumber) ?? "\(quantity)"
        let unitStr = quantityUnit.displayName

        return "\(quantityStr) \(unitStr)"
    }

    /// 음식 정보가 로드되었는지 여부
    var isFoodLoaded: Bool {
        food != nil
    }

    /// 저장 가능 여부
    var canSave: Bool {
        !isSaving && isFoodLoaded && quantityError == nil
    }
}
