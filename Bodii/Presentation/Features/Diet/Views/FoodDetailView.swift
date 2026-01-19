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

    /// 성공 토스트 메시지
    @State private var successToastMessage: String?

    // MARK: - Body

    var body: some View {
        ZStack {
            // 📚 학습 포인트: Background Color
            // iOS 디자인 가이드에 따른 시스템 배경색 사용
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
                .accessibilityHidden(true)

            if viewModel.isLoading {
                // 로딩 상태 (개선된 애니메이션)
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle(tint: .accentColor))

                    Text("음식 정보 불러오는 중...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("음식 정보 불러오는 중")
                .transition(.opacity)
            } else if let food = viewModel.food {
                // 메인 컨텐츠
                ScrollView {
                    VStack(spacing: 20) {
                        // 음식 정보 헤더
                        foodHeaderSection(food: food)

                        // 영양 정보 카드
                        NutritionFactsCard(
                            food: food,
                            quantity: viewModel.quantity,
                            quantityUnit: viewModel.quantityUnit,
                            calculatedCalories: viewModel.calculatedCalories,
                            calculatedCarbs: viewModel.calculatedCarbs,
                            calculatedProtein: viewModel.calculatedProtein,
                            calculatedFat: viewModel.calculatedFat
                        )

                        // 섭취량 선택 섹션
                        ServingSizePicker(
                            quantity: $viewModel.quantity,
                            quantityUnit: $viewModel.quantityUnit,
                            quantityError: viewModel.quantityError,
                            presetMultipliers: viewModel.presetMultipliers,
                            onSetQuantityMultiplier: { multiplier in
                                viewModel.setQuantityMultiplier(multiplier)
                            },
                            onChangeUnit: { newUnit in
                                viewModel.changeUnit(to: newUnit)
                            }
                        )

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
        .successToast(message: $successToastMessage)
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
            Text(food.name ?? "알 수 없는 음식")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)

            // 1회 제공량 정보
            if let servingUnit = food.servingUnit {
                Text("\(servingUnit) (\(formattedDecimal(food.servingSize?.decimalValue ?? Decimal(100)))g)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                Text("\(formattedDecimal(food.servingSize?.decimalValue ?? Decimal(100)))g")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
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
                .accessibilityAddTraits(.isHeader)

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
                await saveFood()
            }
        }) {
            HStack {
                if viewModel.isSaving {
                    ProgressView()
                        .tint(.white)
                        .accessibilityLabel("저장 중")
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
        .accessibilityLabel("식단에 추가")
        .accessibilityHint(viewModel.canSave ? "음식을 식단에 추가합니다" : "추가하기 전에 필수 입력값을 확인하세요")
    }

    // MARK: - Actions

    /// 음식 저장
    ///
    /// 음식을 식단에 추가합니다.
    @MainActor
    private func saveFood() async {
        do {
            try await viewModel.saveFoodRecord()
            successToastMessage = "식단에 추가되었습니다"
            // 약간의 지연 후 화면 닫기
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                onSave()
            }
        } catch {
            // 에러는 ViewModel에서 처리
        }
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
}

// MARK: - Preview

#Preview {
    Text("FoodDetailView Preview")
        .padding()
}
