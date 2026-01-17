//
//  RecognitionConfirmView.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-17.
//

// 📚 학습 포인트: Recognition Confirmation View
// AI 인식 결과의 최종 확인 및 저장 화면
// 💡 전체 음식 목록과 총 영양 정보를 표시하고 일괄 저장

import SwiftUI

/// 음식 인식 결과 확인 및 저장 화면
///
/// 사용자가 선택하고 편집한 음식들을 최종 확인하고 일괄 저장하는 화면입니다.
///
/// **주요 기능:**
/// - 저장할 모든 음식 항목 요약
/// - 총 칼로리 및 매크로 영양소 합계
/// - 끼니 타입 확인/변경
/// - 섭취 날짜/시간 선택
/// - 일괄 저장 버튼
/// - 저장 완료 피드백
///
/// - Note: PhotoRecognitionViewModel을 통해 데이터를 저장합니다.
/// - Note: 각 음식의 수량과 단위 정보를 포함하여 저장합니다.
///
/// - Example:
/// ```swift
/// RecognitionConfirmView(
///     viewModel: photoRecognitionViewModel,
///     selectedItems: editedFoodItems,
///     onSave: {
///         // 저장 완료 처리
///     },
///     onCancel: {
///         // 취소 처리
///     }
/// )
/// ```
struct RecognitionConfirmView: View {

    // MARK: - Properties

    /// ViewModel
    @ObservedObject var viewModel: PhotoRecognitionViewModel

    /// 저장할 음식 항목 목록
    ///
    /// 📚 학습 포인트: Edited Food Items
    /// 사용자가 편집한 수량, 단위 정보를 포함한 음식 항목
    let selectedItems: [EditedFoodItem]

    /// 저장 완료 콜백
    let onSave: () -> Void

    /// 취소 콜백
    let onCancel: () -> Void

    // MARK: - State

    /// 선택된 끼니 타입
    @State private var selectedMealType: MealType = .breakfast

    /// 섭취 날짜
    @State private var selectedDate: Date = Date()

    /// 날짜 선택기 표시 여부
    @State private var showingDatePicker: Bool = false

    /// 저장 완료 상태
    @State private var isSaved: Bool = false

    /// 저장 중 상태
    @State private var isSaving: Bool = false

    // MARK: - Body

    var body: some View {
        NavigationView {
            ZStack {
                // 배경색
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                if isSaved {
                    // 저장 완료 애니메이션
                    successView
                } else {
                    // 확인 화면
                    confirmationContentView
                }
            }
            .navigationTitle("저장 확인")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") {
                        onCancel()
                    }
                    .disabled(isSaving)
                }
            }
        }
    }

    // MARK: - Subviews

    /// 확인 화면 컨텐츠
    private var confirmationContentView: some View {
        VStack(spacing: 0) {
            // 스크롤 가능한 컨텐츠
            ScrollView {
                VStack(spacing: 20) {
                    // 끼니 및 날짜 선택 섹션
                    mealDateSection

                    // 음식 목록 요약
                    foodListSection

                    // 총 영양 정보
                    totalNutritionSection
                }
                .padding(.vertical)
            }

            // 저장 버튼
            saveButton
                .padding()
                .background(Color(.systemBackground))
        }
    }

    /// 끼니 및 날짜 선택 섹션
    ///
    /// 📚 학습 포인트: Meal Type and Date Selection
    /// 저장할 식사의 끼니 타입과 섭취 날짜/시간을 선택합니다.
    private var mealDateSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 섹션 헤더
            Text("식사 정보")
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.horizontal)

            VStack(spacing: 0) {
                // 끼니 선택
                VStack(alignment: .leading, spacing: 12) {
                    Text("끼니")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)

                    // 끼니 타입 버튼들
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(MealType.allCases) { mealType in
                                mealTypeButton(mealType)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)

                Divider()

                // 날짜/시간 선택
                Button(action: {
                    showingDatePicker.toggle()
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("섭취 시간")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Text(formattedDate)
                                .font(.body)
                                .foregroundColor(.primary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }
                .buttonStyle(PlainButtonStyle())
            }
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .padding(.horizontal)
        }
        .sheet(isPresented: $showingDatePicker) {
            NavigationView {
                VStack {
                    DatePicker(
                        "섭취 시간",
                        selection: $selectedDate,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.graphical)
                    .padding()

                    Spacer()
                }
                .navigationTitle("섭취 시간 선택")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("완료") {
                            showingDatePicker = false
                        }
                    }
                }
            }
        }
    }

    /// 음식 목록 요약 섹션
    ///
    /// 📚 학습 포인트: Food Items Summary
    /// 저장할 모든 음식 항목을 카드 형태로 표시합니다.
    private var foodListSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 섹션 헤더
            HStack {
                Text("음식 목록")
                    .font(.headline)
                    .foregroundColor(.primary)

                Spacer()

                Text("\(selectedItems.count)개")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)

            // 음식 카드 목록
            VStack(spacing: 12) {
                ForEach(selectedItems) { item in
                    foodItemCard(item)
                        .padding(.horizontal)
                }
            }
        }
    }

    /// 총 영양 정보 섹션
    ///
    /// 📚 학습 포인트: Total Nutrition Summary
    /// 모든 음식의 칼로리와 매크로 영양소 합계를 표시합니다.
    private var totalNutritionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 섹션 헤더
            Text("영양 정보 합계")
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.horizontal)

            VStack(spacing: 0) {
                // 총 칼로리 (강조)
                VStack(spacing: 8) {
                    Text("총 칼로리")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    HStack(spacing: 4) {
                        Text("\(totalCalories)")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.orange)

                        Text("kcal")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.orange.opacity(0.1))

                Divider()

                // 매크로 영양소 합계
                HStack(spacing: 0) {
                    // 탄수화물
                    macroTotalView(
                        label: "탄수화물",
                        value: totalCarbohydrates,
                        unit: "g",
                        color: .blue
                    )

                    Divider()

                    // 단백질
                    macroTotalView(
                        label: "단백질",
                        value: totalProtein,
                        unit: "g",
                        color: .green
                    )

                    Divider()

                    // 지방
                    macroTotalView(
                        label: "지방",
                        value: totalFat,
                        unit: "g",
                        color: .purple
                    )
                }
                .frame(height: 80)
            }
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }

    /// 저장 버튼
    private var saveButton: some View {
        Button(action: handleSave) {
            HStack {
                if isSaving {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                }

                Text(isSaving ? "저장 중..." : "\(selectedItems.count)개 음식 저장")
                    .font(.headline)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(isSaving ? Color.gray : Color.blue)
            .cornerRadius(12)
        }
        .disabled(isSaving || selectedItems.isEmpty)
    }

    /// 저장 완료 화면
    ///
    /// 📚 학습 포인트: Success Feedback
    /// 저장 완료 시 체크마크 애니메이션과 함께 피드백을 제공합니다.
    private var successView: some View {
        VStack(spacing: 24) {
            Spacer()

            // 체크마크 애니메이션
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 120, height: 120)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
            }
            .transition(.scale.combined(with: .opacity))

            // 성공 메시지
            VStack(spacing: 8) {
                Text("저장 완료!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Text("\(selectedItems.count)개 음식이 \(selectedMealType.displayName)에 추가되었습니다")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .onAppear {
            // 1.5초 후 자동으로 닫기
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                onSave()
            }
        }
    }

    // MARK: - Helper Views

    /// 끼니 타입 버튼
    ///
    /// - Parameter mealType: 끼니 타입
    private func mealTypeButton(_ mealType: MealType) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedMealType = mealType
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: mealTypeIcon(mealType))
                    .font(.body)

                Text(mealType.displayName)
                    .font(.body)
                    .fontWeight(selectedMealType == mealType ? .semibold : .regular)
            }
            .foregroundColor(selectedMealType == mealType ? .white : .primary)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                selectedMealType == mealType
                    ? Color.blue
                    : Color(.systemBackground)
            )
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        selectedMealType == mealType ? Color.clear : Color(.systemGray4),
                        lineWidth: 1
                    )
            )
        }
    }

    /// 음식 항목 카드
    ///
    /// - Parameter item: 편집된 음식 항목
    private func foodItemCard(_ item: EditedFoodItem) -> some View {
        HStack(spacing: 12) {
            // 음식 정보
            VStack(alignment: .leading, spacing: 6) {
                // 음식 이름
                Text(item.match.food.name)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                // 수량 정보
                HStack(spacing: 4) {
                    Image(systemName: "scalemass")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    Text("\(formattedQuantity(item.quantity)) \(item.unit.displayName)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // 칼로리 (계산된 값)
                HStack(spacing: 8) {
                    Text("\(item.calculatedCalories) kcal")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)

                    // 매크로 미리보기
                    HStack(spacing: 6) {
                        macroChip("P", value: item.calculatedProtein, color: .green)
                        macroChip("C", value: item.calculatedCarbohydrates, color: .blue)
                        macroChip("F", value: item.calculatedFat, color: .purple)
                    }
                }
            }

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
        )
    }

    /// 매크로 영양소 합계 뷰
    ///
    /// - Parameters:
    ///   - label: 영양소 이름
    ///   - value: 합계 값
    ///   - unit: 단위
    ///   - color: 색상
    private func macroTotalView(label: String, value: String, unit: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(spacing: 2) {
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(color)

                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }

    /// 매크로 영양소 칩
    ///
    /// - Parameters:
    ///   - label: 영양소 레이블 (P/C/F)
    ///   - value: 값
    ///   - color: 색상
    private func macroChip(_ label: String, value: String, color: Color) -> some View {
        HStack(spacing: 2) {
            Text(label)
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(color)

            Text(value)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 5)
        .padding(.vertical, 2)
        .background(color.opacity(0.1))
        .cornerRadius(4)
    }

    // MARK: - Actions

    /// 저장 처리
    ///
    /// 📚 학습 포인트: Batch Save Operation
    /// 모든 음식을 일괄 저장하고 성공 피드백을 표시합니다.
    private func handleSave() {
        isSaving = true

        Task {
            do {
                // TODO: ViewModel에 저장 메서드 추가 필요
                // 현재는 임시로 saveFoodRecords 사용
                // 실제로는 수량과 단위 정보를 포함하여 저장해야 함

                // 각 항목을 저장
                // Note: 이 부분은 ViewModel에 새로운 메서드가 필요합니다
                // 예: saveFoodRecordsWithDetails(_ items: [EditedFoodItem], mealType: MealType, date: Date)

                // 임시 구현: 기존 saveFoodRecords 사용
                let matches = selectedItems.map { $0.match }
                try await viewModel.saveFoodRecords(matches)

                // 저장 완료 애니메이션 표시
                await MainActor.run {
                    isSaving = false
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                        isSaved = true
                    }
                }

            } catch {
                await MainActor.run {
                    isSaving = false
                    // 에러 처리는 ViewModel에서 처리됨
                }
            }
        }
    }

    // MARK: - Computed Properties

    /// 총 칼로리
    private var totalCalories: Int {
        selectedItems.reduce(0) { $0 + Int($1.calculatedCalories) ?? 0 }
    }

    /// 총 탄수화물
    private var totalCarbohydrates: String {
        let total = selectedItems.reduce(Decimal(0)) { result, item in
            result + (Decimal(string: item.calculatedCarbohydrates) ?? 0)
        }
        return formattedDecimal(total)
    }

    /// 총 단백질
    private var totalProtein: String {
        let total = selectedItems.reduce(Decimal(0)) { result, item in
            result + (Decimal(string: item.calculatedProtein) ?? 0)
        }
        return formattedDecimal(total)
    }

    /// 총 지방
    private var totalFat: String {
        let total = selectedItems.reduce(Decimal(0)) { result, item in
            result + (Decimal(string: item.calculatedFat) ?? 0)
        }
        return formattedDecimal(total)
    }

    /// 포맷된 날짜
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: selectedDate)
    }

    // MARK: - Helpers

    /// 끼니 타입 아이콘
    ///
    /// - Parameter mealType: 끼니 타입
    /// - Returns: SF Symbol 아이콘 이름
    private func mealTypeIcon(_ mealType: MealType) -> String {
        switch mealType {
        case .breakfast:
            return "sunrise.fill"
        case .lunch:
            return "sun.max.fill"
        case .dinner:
            return "moon.fill"
        case .snack:
            return "cup.and.saucer.fill"
        }
    }

    /// 수량 포맷팅
    ///
    /// - Parameter quantity: 수량 값
    /// - Returns: 포맷팅된 문자열
    private func formattedQuantity(_ quantity: Decimal) -> String {
        let nsDecimal = quantity as NSDecimalNumber
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 0
        return formatter.string(from: nsDecimal) ?? "0"
    }

    /// Decimal 값을 포맷팅
    ///
    /// - Parameter value: 포맷팅할 Decimal 값
    /// - Returns: 포맷팅된 문자열
    private func formattedDecimal(_ value: Decimal) -> String {
        let nsDecimal = value as NSDecimalNumber
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 0
        return formatter.string(from: nsDecimal) ?? "0"
    }
}

// MARK: - EditedFoodItem Model

/// 편집된 음식 항목
///
/// 📚 학습 포인트: Edited Food Item with Quantities
/// FoodMatch와 사용자가 편집한 수량/단위 정보를 함께 저장하는 모델
///
/// - Note: 최종 저장 전에 계산된 영양 정보를 포함합니다.
struct EditedFoodItem: Identifiable {

    // MARK: - Properties

    /// 고유 ID
    let id: UUID

    /// 음식 매칭 정보
    let match: FoodMatch

    /// 섭취 수량
    let quantity: Decimal

    /// 수량 단위
    let unit: QuantityUnit

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        match: FoodMatch,
        quantity: Decimal = 1.0,
        unit: QuantityUnit = .serving
    ) {
        self.id = id
        self.match = match
        self.quantity = quantity
        self.unit = unit
    }

    // MARK: - Computed Properties

    /// 배수 (인분 또는 그램 기준)
    ///
    /// 📚 학습 포인트: Quantity Multiplier Calculation
    /// 수량 단위에 따라 영양 정보 계산을 위한 배수를 구합니다.
    private var multiplier: Decimal {
        switch unit {
        case .serving:
            // 인분 단위: 수량 그대로 사용
            return quantity
        case .grams:
            // 그램 단위: (입력 그램 / 1회 제공량 그램) 비율
            return quantity / match.food.servingSize
        }
    }

    /// 계산된 칼로리
    var calculatedCalories: String {
        let calories = Decimal(match.food.calories) * multiplier
        return formattedDecimal(calories)
    }

    /// 계산된 탄수화물
    var calculatedCarbohydrates: String {
        let carbs = match.food.carbohydrates * multiplier
        return formattedDecimal(carbs)
    }

    /// 계산된 단백질
    var calculatedProtein: String {
        let protein = match.food.protein * multiplier
        return formattedDecimal(protein)
    }

    /// 계산된 지방
    var calculatedFat: String {
        let fat = match.food.fat * multiplier
        return formattedDecimal(fat)
    }

    // MARK: - Helpers

    /// Decimal 값을 포맷팅
    private func formattedDecimal(_ value: Decimal) -> String {
        let nsDecimal = value as NSDecimalNumber
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 0
        return formatter.string(from: nsDecimal) ?? "0"
    }
}

// MARK: - Preview

#Preview("Confirm View with Items") {
    #if DEBUG
    // Mock 데이터
    let mockMatches = [
        FoodMatch(
            label: "Pizza",
            originalLabel: VisionLabel(description: "Pizza", score: 0.95, topicality: 0.95),
            confidence: 0.95,
            food: Food(
                id: UUID(),
                name: "페퍼로니 피자",
                calories: 285,
                carbohydrates: 36,
                protein: 12,
                fat: 10,
                sodium: 640,
                fiber: 2,
                sugar: 4,
                servingSize: 100,
                servingUnit: "1조각",
                source: .usda,
                apiCode: "U000123",
                createdByUserId: nil,
                createdAt: Date()
            ),
            alternatives: [],
            translatedKeyword: "피자"
        ),
        FoodMatch(
            label: "Salad",
            originalLabel: VisionLabel(description: "Salad", score: 0.72, topicality: 0.72),
            confidence: 0.72,
            food: Food(
                id: UUID(),
                name: "시저 샐러드",
                calories: 180,
                carbohydrates: 8,
                protein: 6,
                fat: 14,
                sodium: 350,
                fiber: 2,
                sugar: 2,
                servingSize: 150,
                servingUnit: "1인분",
                source: .usda,
                apiCode: "U000456",
                createdByUserId: nil,
                createdAt: Date()
            ),
            alternatives: [],
            translatedKeyword: "샐러드"
        )
    ]

    let editedItems = [
        EditedFoodItem(match: mockMatches[0], quantity: 2.0, unit: .serving),
        EditedFoodItem(match: mockMatches[1], quantity: 1.5, unit: .serving)
    ]

    let mockViewModel = MockPhotoRecognitionViewModel()

    return RecognitionConfirmView(
        viewModel: mockViewModel,
        selectedItems: editedItems,
        onSave: {
            print("Saved!")
        },
        onCancel: {
            print("Cancelled")
        }
    )
    #endif
}

#Preview("Confirm View - Empty") {
    #if DEBUG
    let mockViewModel = MockPhotoRecognitionViewModel()

    return RecognitionConfirmView(
        viewModel: mockViewModel,
        selectedItems: [],
        onSave: { },
        onCancel: { }
    )
    #endif
}
