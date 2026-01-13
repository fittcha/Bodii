//
//  FoodDetailView.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-13.
//

// 📚 학습 포인트: Food Detail View
// 음식 상세 화면 - 영양 정보 표시 및 섭취량 조절
// 💡 프리셋 배수와 커스텀 입력으로 섭취량 조절 지원

import SwiftUI

// MARK: - Food Detail View

/// 음식 상세 화면
///
/// 음식의 영양 정보를 표시하고 섭취량을 조절하여 식단에 추가합니다.
///
/// - Note: FoodDetailViewModel을 사용하여 데이터를 관리합니다.
/// - Note: 프리셋 배수(0.25x, 0.5x, 1x, 1.5x, 2x)와 커스텀 수량 입력을 지원합니다.
///
/// - Example:
/// ```swift
/// FoodDetailView(
///     viewModel: foodDetailViewModel,
///     foodId: foodId,
///     userId: userId,
///     date: Date(),
///     mealType: .breakfast,
///     bmr: 1650,
///     tdee: 2310,
///     onSave: {
///         // 저장 완료 처리
///     }
/// )
/// ```
struct FoodDetailView: View {

    // MARK: - Properties

    /// ViewModel
    @ObservedObject var viewModel: FoodDetailViewModel

    /// 음식 ID
    let foodId: UUID

    /// 사용자 ID
    let userId: UUID

    /// 섭취 날짜
    let date: Date

    /// 초기 끼니 타입
    let initialMealType: MealType

    /// 기초대사량 (kcal)
    let bmr: Int32

    /// 활동대사량 (kcal)
    let tdee: Int32

    /// 저장 완료 콜백
    let onSave: () -> Void

    // MARK: - State

    /// 저장 성공 알림 표시 여부
    @State private var showingSaveSuccess = false

    // MARK: - Body

    var body: some View {
        ZStack {
            // 📚 학습 포인트: Background Color
            // iOS 디자인 가이드에 따른 시스템 배경색 사용
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            if viewModel.isLoading {
                // 로딩 상태
                ProgressView()
                    .scaleEffect(1.5)
            } else if let food = viewModel.food {
                // 메인 컨텐츠
                ScrollView {
                    VStack(spacing: 20) {
                        // 음식 정보 헤더
                        foodHeaderSection(food: food)

                        // 영양 정보 카드
                        nutritionFactsSection(food: food)

                        // 섭취량 선택 섹션
                        servingSizeSection

                        // 끼니 선택 섹션
                        mealTypeSection

                        // 추가 버튼
                        addButton
                    }
                    .padding(.vertical)
                }
            }
        }
        .navigationTitle("음식 추가")
        .navigationBarTitleDisplayMode(.inline)
        .alert("오류", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("확인") {
                viewModel.errorMessage = nil
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
        .alert("추가 완료", isPresented: $showingSaveSuccess) {
            Button("확인") {
                onSave()
            }
        } message: {
            Text("식단에 추가되었습니다.")
        }
        .onAppear {
            viewModel.onAppear(
                foodId: foodId,
                userId: userId,
                date: date,
                mealType: initialMealType,
                bmr: bmr,
                tdee: tdee
            )
        }
    }

    // MARK: - Subviews

    /// 음식 정보 헤더
    ///
    /// 음식 이름과 1회 제공량 정보를 표시합니다.
    ///
    /// - Parameter food: 음식 정보
    /// - Returns: 헤더 섹션 뷰
    private func foodHeaderSection(food: Food) -> some View {
        VStack(spacing: 8) {
            // 음식 이름
            Text(food.name)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)

            // 1회 제공량 정보
            if let servingUnit = food.servingUnit {
                Text("\(servingUnit) (\(formattedDecimal(food.servingSize))g)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                Text("\(formattedDecimal(food.servingSize))g")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
    }

    /// 영양 정보 섹션
    ///
    /// 계산된 영양 정보를 표시합니다.
    ///
    /// - Parameter food: 음식 정보
    /// - Returns: 영양 정보 카드 뷰
    private func nutritionFactsSection(food: Food) -> some View {
        VStack(spacing: 16) {
            // 섹션 헤더
            HStack {
                Text("영양 정보")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                Text(viewModel.quantityText)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Divider()

            // 칼로리 (큼직하게 표시)
            HStack {
                Text("칼로리")
                    .font(.body)
                    .foregroundColor(.secondary)

                Spacer()

                Text("\(viewModel.calculatedCalories) kcal")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }

            Divider()

            // 탄수화물
            nutritionRow(
                name: "탄수화물",
                value: viewModel.calculatedCarbs,
                unit: "g",
                color: .blue
            )

            // 단백질
            nutritionRow(
                name: "단백질",
                value: viewModel.calculatedProtein,
                unit: "g",
                color: .orange
            )

            // 지방
            nutritionRow(
                name: "지방",
                value: viewModel.calculatedFat,
                unit: "g",
                color: .purple
            )

            // 나트륨 (선택적)
            if let sodium = food.sodium {
                Divider()
                nutritionRow(
                    name: "나트륨",
                    value: sodium * calculateMultiplier(food: food),
                    unit: "mg",
                    color: .gray
                )
            }

            // 식이섬유 (선택적)
            if let fiber = food.fiber {
                nutritionRow(
                    name: "식이섬유",
                    value: fiber * calculateMultiplier(food: food),
                    unit: "g",
                    color: .green
                )
            }

            // 당류 (선택적)
            if let sugar = food.sugar {
                nutritionRow(
                    name: "당류",
                    value: sugar * calculateMultiplier(food: food),
                    unit: "g",
                    color: .pink
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }

    /// 영양소 행
    ///
    /// 개별 영양소 정보를 표시하는 행입니다.
    ///
    /// - Parameters:
    ///   - name: 영양소 이름
    ///   - value: 값
    ///   - unit: 단위
    ///   - color: 색상
    /// - Returns: 영양소 행 뷰
    private func nutritionRow(name: String, value: Decimal, unit: String, color: Color) -> some View {
        HStack {
            HStack(spacing: 8) {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)

                Text(name)
                    .font(.body)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text("\(formattedDecimal(value)) \(unit)")
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
    }

    /// 섭취량 선택 섹션
    ///
    /// 프리셋 배수 버튼과 커스텀 수량 입력 필드를 제공합니다.
    private var servingSizeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 섹션 헤더
            Text("섭취량")
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.horizontal)

            VStack(spacing: 16) {
                // 프리셋 배수 버튼
                VStack(alignment: .leading, spacing: 8) {
                    Text("빠른 선택")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    HStack(spacing: 12) {
                        ForEach(viewModel.presetMultipliers, id: \.self) { multiplier in
                            presetButton(multiplier: multiplier)
                        }
                    }
                }

                Divider()

                // 커스텀 수량 입력
                VStack(alignment: .leading, spacing: 8) {
                    Text("직접 입력")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    HStack(spacing: 12) {
                        // 수량 입력 필드
                        TextField("수량", value: $viewModel.quantity, format: .number)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.roundedBorder)
                            .frame(maxWidth: 120)

                        // 단위 선택 (인분 / 그램)
                        Picker("단위", selection: $viewModel.quantityUnit) {
                            ForEach(QuantityUnit.allCases) { unit in
                                Text(unit.displayName).tag(unit)
                            }
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: viewModel.quantityUnit) { oldValue, newValue in
                            if oldValue != newValue {
                                viewModel.changeUnit(to: newValue)
                            }
                        }

                        Spacer()
                    }

                    // 유효성 검증 에러 메시지
                    if let quantityError = viewModel.quantityError {
                        Text(quantityError)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }

    /// 프리셋 배수 버튼
    ///
    /// 빠른 선택을 위한 프리셋 배수 버튼입니다.
    ///
    /// - Parameter multiplier: 배수 값
    /// - Returns: 프리셋 버튼 뷰
    private func presetButton(multiplier: Decimal) -> some View {
        Button(action: {
            viewModel.setQuantityMultiplier(multiplier)
        }) {
            Text("\(formatMultiplier(multiplier))x")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(
                    viewModel.isServingBased && viewModel.quantity == multiplier
                        ? .white
                        : .primary
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    viewModel.isServingBased && viewModel.quantity == multiplier
                        ? Color.blue
                        : Color(.systemGray5)
                )
                .cornerRadius(8)
        }
    }

    /// 끼니 선택 섹션
    ///
    /// 끼니 타입을 선택합니다.
    private var mealTypeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 섹션 헤더
            Text("끼니")
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.horizontal)

            // 끼니 선택 버튼
            HStack(spacing: 12) {
                ForEach(MealType.allCases) { mealType in
                    mealTypeButton(mealType: mealType)
                }
            }
            .padding(.horizontal)
        }
    }

    /// 끼니 타입 버튼
    ///
    /// 끼니를 선택하는 버튼입니다.
    ///
    /// - Parameter mealType: 끼니 타입
    /// - Returns: 끼니 버튼 뷰
    private func mealTypeButton(mealType: MealType) -> some View {
        Button(action: {
            viewModel.selectedMealType = mealType
        }) {
            Text(mealType.displayName)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(
                    viewModel.selectedMealType == mealType
                        ? .white
                        : .primary
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    viewModel.selectedMealType == mealType
                        ? Color.blue
                        : Color(.systemBackground)
                )
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(
                            viewModel.selectedMealType == mealType
                                ? Color.blue
                                : Color(.systemGray4),
                            lineWidth: 1
                        )
                )
        }
    }

    /// 추가 버튼
    ///
    /// 식단에 음식을 추가하는 버튼입니다.
    private var addButton: some View {
        Button(action: {
            Task {
                do {
                    try await viewModel.saveFoodRecord()
                    showingSaveSuccess = true
                } catch {
                    // 에러는 ViewModel에서 처리됨
                }
            }
        }) {
            HStack {
                if viewModel.isSaving {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)

                    Text("식단에 추가")
                        .font(.headline)
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(viewModel.canSave ? Color.blue : Color.gray)
            .cornerRadius(12)
        }
        .disabled(!viewModel.canSave)
        .padding(.horizontal)
        .padding(.bottom)
    }

    // MARK: - Helpers

    /// Decimal 값을 포맷팅
    ///
    /// Decimal 값을 소수점 둘째 자리까지 표시하는 문자열로 변환합니다.
    ///
    /// - Parameter value: 포맷팅할 Decimal 값
    /// - Returns: 포맷팅된 문자열
    private func formattedDecimal(_ value: Decimal) -> String {
        let nsDecimal = value as NSDecimalNumber
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter.string(from: nsDecimal) ?? "0"
    }

    /// 배수 값을 포맷팅
    ///
    /// 배수 값을 간결하게 표시합니다 (예: 0.25, 0.5, 1, 1.5, 2)
    ///
    /// - Parameter value: 배수 값
    /// - Returns: 포맷팅된 문자열
    private func formatMultiplier(_ value: Decimal) -> String {
        let nsDecimal = value as NSDecimalNumber
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter.string(from: nsDecimal) ?? "1"
    }

    /// 현재 섭취량에 대한 배수 계산
    ///
    /// 선택적 영양소 표시를 위한 배수 계산입니다.
    ///
    /// - Parameter food: 음식 정보
    /// - Returns: 배수 값
    private func calculateMultiplier(food: Food) -> Decimal {
        if viewModel.quantityUnit == .serving {
            return viewModel.quantity
        } else {
            // 그램 단위일 경우: quantity / servingSize
            return viewModel.quantity / food.servingSize
        }
    }
}

// MARK: - Preview

#Preview {
    // 프리뷰용 Mock 데이터
    let mockViewModel = FoodDetailViewModel(
        foodRepository: MockFoodRepository(),
        foodRecordService: MockFoodRecordService()
    )

    return NavigationView {
        FoodDetailView(
            viewModel: mockViewModel,
            foodId: UUID(),
            userId: UUID(),
            date: Date(),
            initialMealType: .breakfast,
            bmr: 1650,
            tdee: 2310,
            onSave: {
                print("Save completed")
            }
        )
    }
}

// MARK: - Mock Services for Preview

private class MockFoodRepository: FoodRepositoryProtocol {
    func save(_ food: Food) async throws -> Food {
        return food
    }

    func findById(_ id: UUID) async throws -> Food? {
        // 샘플 음식 반환
        return Food(
            id: id,
            name: "백미밥",
            calories: 330,
            carbohydrates: 70,
            protein: 7,
            fat: 1,
            sodium: 0,
            fiber: 1.5,
            sugar: 0.5,
            servingSize: 210,
            servingUnit: "1공기",
            source: .governmentAPI,
            apiCode: "D000001",
            createdByUserId: nil,
            createdAt: Date()
        )
    }

    func findAll() async throws -> [Food] {
        return []
    }

    func search(by name: String) async throws -> [Food] {
        return []
    }

    func getRecentFoods(userId: UUID, limit: Int) async throws -> [Food] {
        return []
    }

    func getFrequentFoods(userId: UUID, limit: Int) async throws -> [Food] {
        return []
    }

    func getUserDefinedFoods(userId: UUID) async throws -> [Food] {
        return []
    }

    func update(_ food: Food) async throws -> Food {
        return food
    }

    func delete(_ foodId: UUID) async throws {
        // Mock implementation
    }
}

private class MockFoodRecordService: FoodRecordServiceProtocol {
    func addFoodRecord(userId: UUID, foodId: UUID, date: Date, mealType: MealType, quantity: Decimal, quantityUnit: QuantityUnit, bmr: Int32, tdee: Int32) async throws -> FoodRecord {
        // Mock implementation
        return FoodRecord(
            id: UUID(),
            userId: userId,
            foodId: foodId,
            date: date,
            mealType: mealType,
            quantity: quantity,
            quantityUnit: quantityUnit,
            calculatedCalories: 330,
            calculatedCarbs: 70,
            calculatedProtein: 7,
            calculatedFat: 1,
            createdAt: Date()
        )
    }

    func updateFoodRecord(foodRecordId: UUID, quantity: Decimal, quantityUnit: QuantityUnit, mealType: MealType?) async throws -> FoodRecord {
        fatalError("Mock not implemented")
    }

    func deleteFoodRecord(foodRecordId: UUID) async throws {
        // Mock implementation
    }

    func getFoodRecords(for date: Date, userId: UUID) async throws -> [FoodRecord] {
        return []
    }

    func getFoodRecords(for date: Date, mealType: MealType, userId: UUID) async throws -> [FoodRecord] {
        return []
    }
}
