//
//  ManualFoodEntryView.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-13.
//

// 📚 학습 포인트: Manual Food Entry View
// 음식 직접 입력 화면 - 데이터베이스에 없는 음식을 직접 입력
// 💡 필수 필드와 선택 필드를 구분하여 사용자 경험 최적화

import SwiftUI

// MARK: - Manual Food Entry View

/// 음식 직접 입력 화면
///
/// 데이터베이스에 없는 음식을 사용자가 직접 입력하여 저장하고 식단에 추가합니다.
///
/// - Note: ManualFoodEntryViewModel을 사용하여 데이터를 관리합니다.
/// - Note: 필수 필드(음식명, 칼로리, 1회 제공량)와 선택 필드(영양소)를 구분합니다.
///
/// - Example:
/// ```swift
/// ManualFoodEntryView(
///     viewModel: manualFoodEntryViewModel,
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
struct ManualFoodEntryView: View {

    // MARK: - Properties

    /// ViewModel
    @ObservedObject var viewModel: ManualFoodEntryViewModel

    /// 사용자 ID
    let userId: UUID

    /// 섭취 날짜
    let date: Date

    /// 끼니 타입
    let mealType: MealType

    /// 기초대사량 (kcal)
    let bmr: Int32

    /// 활동대사량 (kcal)
    let tdee: Int32

    /// 저장 완료 콜백
    let onSave: () -> Void

    // MARK: - State

    /// 저장 성공 알림 표시 여부
    @State private var showingSaveSuccess = false

    /// 포커스 관리
    @FocusState private var focusedField: Field?

    // MARK: - Body

    var body: some View {
        ZStack {
            // 📚 학습 포인트: Background Color
            // iOS 디자인 가이드에 따른 시스템 배경색 사용
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // 안내 메시지
                    instructionSection

                    // 기본 정보 섹션
                    basicInfoSection

                    // 영양 정보 섹션
                    macroNutrientsSection

                    // 선택 정보 섹션
                    optionalNutrientsSection

                    // 저장 버튼
                    saveButton
                }
                .padding(.vertical)
            }
        }
        .navigationTitle("음식 직접 입력")
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
                userId: userId,
                date: date,
                mealType: mealType,
                bmr: bmr,
                tdee: tdee
            )
        }
    }

    // MARK: - Subviews

    /// 안내 메시지 섹션
    ///
    /// 음식 직접 입력에 대한 안내 메시지를 표시합니다.
    private var instructionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.blue)
                    .font(.headline)

                Text("영양 정보를 직접 입력하세요")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }

            Text("포장지나 영양 정보 라벨을 참고하여 입력하면 정확한 기록을 남길 수 있습니다.")
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }

    /// 기본 정보 섹션
    ///
    /// 음식명과 1회 제공량을 입력합니다.
    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 섹션 헤더
            Text("기본 정보")
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.horizontal)

            VStack(spacing: 16) {
                // 음식명 (필수)
                formField(
                    title: "음식명",
                    placeholder: "예: 수제 샐러드",
                    text: $viewModel.foodName,
                    isRequired: true,
                    error: viewModel.validationErrors.foodName,
                    field: .foodName
                )

                Divider()
                    .padding(.horizontal, 16)

                // 1회 제공량 (필수)
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 4) {
                            Text("1회 제공량")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                            Text("*")
                                .font(.subheadline)
                                .foregroundColor(.red)
                        }

                        TextField("예: 250", text: $viewModel.servingSize)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.plain)
                            .padding(12)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .focused($focusedField, equals: .servingSize)

                        if let error = viewModel.validationErrors.servingSize {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("단위")
                            .font(.subheadline)
                            .foregroundColor(.primary)

                        TextField("예: 1인분", text: $viewModel.servingUnit)
                            .textFieldStyle(.plain)
                            .padding(12)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .focused($focusedField, equals: .servingUnit)
                    }
                }
                .padding(.horizontal, 16)

                // 단위 힌트
                Text("g 단위로 입력하고, 원한다면 단위 설명을 추가하세요 (예: 1인분, 1개)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)
            }
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }

    /// 영양 정보 섹션
    ///
    /// 칼로리와 3대 영양소(탄수화물, 단백질, 지방)를 입력합니다.
    private var macroNutrientsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 섹션 헤더
            Text("영양 정보")
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.horizontal)

            VStack(spacing: 16) {
                // 칼로리 (필수)
                formField(
                    title: "칼로리",
                    placeholder: "예: 350",
                    text: $viewModel.calories,
                    unit: "kcal",
                    isRequired: true,
                    error: viewModel.validationErrors.calories,
                    field: .calories,
                    keyboardType: .numberPad
                )

                Divider()
                    .padding(.horizontal, 16)

                // 탄수화물
                formField(
                    title: "탄수화물",
                    placeholder: "예: 45",
                    text: $viewModel.carbohydrates,
                    unit: "g",
                    error: viewModel.validationErrors.carbohydrates,
                    field: .carbohydrates,
                    keyboardType: .decimalPad
                )

                Divider()
                    .padding(.horizontal, 16)

                // 단백질
                formField(
                    title: "단백질",
                    placeholder: "예: 20",
                    text: $viewModel.protein,
                    unit: "g",
                    error: viewModel.validationErrors.protein,
                    field: .protein,
                    keyboardType: .decimalPad
                )

                Divider()
                    .padding(.horizontal, 16)

                // 지방
                formField(
                    title: "지방",
                    placeholder: "예: 15",
                    text: $viewModel.fat,
                    unit: "g",
                    error: viewModel.validationErrors.fat,
                    field: .fat,
                    keyboardType: .decimalPad
                )
            }
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }

    /// 선택 정보 섹션
    ///
    /// 선택적으로 입력할 수 있는 영양소(나트륨, 식이섬유, 당류)를 입력합니다.
    private var optionalNutrientsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 섹션 헤더
            HStack(spacing: 8) {
                Text("추가 정보")
                    .font(.headline)
                    .foregroundColor(.primary)

                Text("선택사항")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray5))
                    .cornerRadius(6)
            }
            .padding(.horizontal)

            VStack(spacing: 16) {
                // 나트륨
                formField(
                    title: "나트륨",
                    placeholder: "예: 500",
                    text: $viewModel.sodium,
                    unit: "mg",
                    error: viewModel.validationErrors.sodium,
                    field: .sodium,
                    keyboardType: .decimalPad
                )

                Divider()
                    .padding(.horizontal, 16)

                // 식이섬유
                formField(
                    title: "식이섬유",
                    placeholder: "예: 5",
                    text: $viewModel.fiber,
                    unit: "g",
                    error: viewModel.validationErrors.fiber,
                    field: .fiber,
                    keyboardType: .decimalPad
                )

                Divider()
                    .padding(.horizontal, 16)

                // 당류
                formField(
                    title: "당류",
                    placeholder: "예: 10",
                    text: $viewModel.sugar,
                    unit: "g",
                    error: viewModel.validationErrors.sugar,
                    field: .sugar,
                    keyboardType: .decimalPad
                )
            }
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }

    /// 저장 버튼
    ///
    /// 입력한 음식 정보를 저장하고 식단에 추가하는 버튼입니다.
    private var saveButton: some View {
        Button(action: {
            // 포커스 해제 (키보드 숨김)
            focusedField = nil

            Task {
                do {
                    try await viewModel.saveFood()
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
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)

                    Text("저장하고 식단에 추가")
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

    /// 폼 필드 생성 헬퍼
    ///
    /// 레이블, 텍스트 필드, 에러 메시지를 포함한 폼 필드를 생성합니다.
    ///
    /// - Parameters:
    ///   - title: 필드 제목
    ///   - placeholder: 플레이스홀더 텍스트
    ///   - text: 바인딩할 텍스트
    ///   - unit: 단위 표시 (선택사항)
    ///   - isRequired: 필수 입력 여부
    ///   - error: 에러 메시지 (선택사항)
    ///   - field: 포커스 필드
    ///   - keyboardType: 키보드 타입
    /// - Returns: 폼 필드 뷰
    @ViewBuilder
    private func formField(
        title: String,
        placeholder: String,
        text: Binding<String>,
        unit: String? = nil,
        isRequired: Bool = false,
        error: String? = nil,
        field: Field,
        keyboardType: UIKeyboardType = .default
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // 필드 제목
            HStack(spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.primary)

                if isRequired {
                    Text("*")
                        .font(.subheadline)
                        .foregroundColor(.red)
                }

                Spacer()

                if let unit = unit {
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // 텍스트 필드
            TextField(placeholder, text: text)
                .keyboardType(keyboardType)
                .textFieldStyle(.plain)
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .focused($focusedField, equals: field)

            // 에러 메시지
            if let error = error {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Focus Field

/// 포커스 필드 열거형
///
/// 각 입력 필드를 식별하기 위한 열거형입니다.
private enum Field: Hashable {
    case foodName
    case servingSize
    case servingUnit
    case calories
    case carbohydrates
    case protein
    case fat
    case sodium
    case fiber
    case sugar
}

// MARK: - Preview

#Preview {
    // 프리뷰용 Mock 데이터
    let mockViewModel = ManualFoodEntryViewModel(
        foodRepository: MockFoodRepository(),
        foodRecordService: MockFoodRecordService()
    )

    return NavigationView {
        ManualFoodEntryView(
            viewModel: mockViewModel,
            userId: UUID(),
            date: Date(),
            mealType: .breakfast,
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
        return nil
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
            calculatedCalories: 350,
            calculatedCarbs: 45,
            calculatedProtein: 20,
            calculatedFat: 15,
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
