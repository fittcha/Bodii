//
//  FoodMatchEditorView.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-17.
//

// 📚 학습 포인트: Food Match Editor View
// 인식된 음식 매칭의 상세 편집 화면
// 💡 음식 변경, 섭취량 조절, 끼니 타입 선택 기능 제공

import SwiftUI

/// 음식 매칭 편집 화면
///
/// AI가 인식한 음식 매칭을 사용자가 수정할 수 있는 화면입니다.
///
/// **주요 기능:**
/// - 매칭된 음식 정보 표시
/// - 다른 음식으로 변경 (검색 화면 열기)
/// - 섭취량 조절 (0.5 ~ 5 인분)
/// - 수량 단위 변경 (인분/그램)
/// - 실시간 칼로리 재계산
/// - 끼니 타입 선택
/// - 변경사항 저장 또는 삭제
///
/// - Note: FoodMatch를 기반으로 편집 가능한 상태를 관리합니다.
/// - Note: 변경사항은 콜백을 통해 부모 뷰에 전달됩니다.
///
/// - Example:
/// ```swift
/// FoodMatchEditorView(
///     match: foodMatch,
///     onSave: { updatedMatch, quantity, unit, mealType in
///         // 변경사항 저장
///     },
///     onDelete: {
///         // 항목 삭제
///     },
///     onSearchAlternative: { currentMatch in
///         // 다른 음식 검색 화면 열기
///     }
/// )
/// ```
struct FoodMatchEditorView: View {

    // MARK: - Properties

    /// 편집할 음식 매칭
    let match: FoodMatch

    /// 저장 콜백 (매칭, 수량, 단위, 끼니 타입)
    let onSave: (FoodMatch, Decimal, QuantityUnit, MealType) -> Void

    /// 삭제 콜백
    let onDelete: () -> Void

    /// 다른 음식 검색 콜백
    let onSearchAlternative: (FoodMatch) -> Void

    /// 취소 콜백
    let onCancel: () -> Void

    // MARK: - State

    /// 섭취량 (0.5 ~ 5.0)
    ///
    /// 📚 학습 포인트: Decimal for Precise Quantities
    /// 정확한 수량 계산을 위해 Decimal 타입 사용
    @State private var quantity: Decimal = 1.0

    /// 수량 단위 (인분/그램)
    @State private var quantityUnit: QuantityUnit = .serving

    /// 선택된 끼니 타입
    @State private var selectedMealType: MealType = .breakfast

    /// 삭제 확인 알림 표시 여부
    @State private var showingDeleteConfirmation = false

    // MARK: - Body

    var body: some View {
        NavigationView {
            ZStack {
                // 배경색
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // 음식 정보 섹션
                        foodInfoSection

                        // 섭취량 조절 섹션
                        quantitySection

                        // 끼니 타입 선택 섹션
                        mealTypeSection

                        // 영양 정보 요약 섹션
                        nutritionSummarySection
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("음식 편집")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") {
                        onCancel()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("저장") {
                        handleSave()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .alert("음식 삭제", isPresented: $showingDeleteConfirmation) {
            Button("취소", role: .cancel) { }
            Button("삭제", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("이 음식을 목록에서 삭제하시겠습니까?")
        }
        .onAppear {
            // 초기값 설정
            quantity = 1.0
            quantityUnit = .serving
            selectedMealType = .breakfast
        }
    }

    // MARK: - Subviews

    /// 음식 정보 섹션
    ///
    /// 현재 선택된 음식의 정보와 다른 음식으로 변경하는 버튼을 표시합니다.
    private var foodInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 섹션 헤더
            Text("음식 정보")
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.horizontal)

            VStack(spacing: 0) {
                // 음식 카드
                VStack(alignment: .leading, spacing: 12) {
                    // 음식 이름과 신뢰도
                    HStack(spacing: 8) {
                        Text(match.food.name)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)

                        Spacer()

                        // 신뢰도 배지
                        confidenceBadge
                    }

                    // 인식된 라벨
                    if !match.label.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "camera.viewfinder")
                                .font(.caption2)
                                .foregroundColor(.secondary)

                            Text("AI 인식: \(match.label)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    // 1회 제공량 정보
                    HStack(spacing: 4) {
                        Image(systemName: "scalemass")
                            .font(.caption2)
                            .foregroundColor(.secondary)

                        Text("1회 제공량: \(servingSizeText)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    // 기본 영양 정보 (1회 제공량 기준)
                    HStack(spacing: 16) {
                        nutritionBadge("칼로리", value: "\(match.food.calories)", unit: "kcal", color: .orange)
                        nutritionBadge("탄수화물", value: formattedDecimal(match.food.carbohydrates), unit: "g", color: .blue)
                        nutritionBadge("단백질", value: formattedDecimal(match.food.protein), unit: "g", color: .green)
                        nutritionBadge("지방", value: formattedDecimal(match.food.fat), unit: "g", color: .purple)
                    }
                }
                .padding()

                Divider()

                // 다른 음식으로 변경 버튼
                Button(action: {
                    onSearchAlternative(match)
                }) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .font(.body)

                        Text("다른 음식으로 변경")
                            .font(.body)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .foregroundColor(.blue)
                    .padding()
                }
            }
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }

    /// 섭취량 조절 섹션
    ///
    /// 📚 학습 포인트: Interactive Quantity Control
    /// 슬라이더와 스테퍼를 조합하여 정확한 수량 입력 지원
    private var quantitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 섹션 헤더
            Text("섭취량")
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.horizontal)

            VStack(spacing: 16) {
                // 수량 단위 선택
                Picker("수량 단위", selection: $quantityUnit) {
                    ForEach(QuantityUnit.allCases) { unit in
                        Text(unit.displayName).tag(unit)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                // 수량 표시 및 조절
                VStack(spacing: 12) {
                    // 현재 수량 표시
                    HStack {
                        Text("수량")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Spacer()

                        Text(formattedQuantity)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)

                        Text(quantityUnit.displayName)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)

                    // 슬라이더 (0.5 ~ 5.0)
                    VStack(spacing: 8) {
                        Slider(
                            value: Binding(
                                get: { NSDecimalNumber(decimal: quantity).doubleValue },
                                set: { quantity = Decimal($0) }
                            ),
                            in: 0.5...5.0,
                            step: 0.5
                        )
                        .accentColor(.blue)
                        .padding(.horizontal)

                        // 슬라이더 가이드
                        HStack {
                            Text("0.5")
                                .font(.caption2)
                                .foregroundColor(.secondary)

                            Spacer()

                            Text("5.0")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                    }

                    // 빠른 조절 버튼
                    HStack(spacing: 12) {
                        quickAdjustButton("-0.5", delta: -0.5)
                        quickAdjustButton("-1", delta: -1)

                        Spacer()

                        Button(action: {
                            quantity = 1.0
                        }) {
                            Text("초기화")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)
                        }

                        Spacer()

                        quickAdjustButton("+1", delta: 1)
                        quickAdjustButton("+0.5", delta: 0.5)
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }

    /// 끼니 타입 선택 섹션
    ///
    /// 📚 학습 포인트: Meal Type Selection
    /// 아침, 점심, 저녁, 간식 중 선택
    private var mealTypeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 섹션 헤더
            Text("끼니")
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.horizontal)

            // 끼니 타입 선택 (가로 스크롤)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(MealType.allCases) { mealType in
                        mealTypeButton(mealType)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    /// 영양 정보 요약 섹션
    ///
    /// 📚 학습 포인트: Real-time Nutrition Calculation
    /// 선택한 수량에 따라 실시간으로 칼로리와 영양소 재계산
    private var nutritionSummarySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 섹션 헤더
            HStack(spacing: 8) {
                Text("영양 정보 요약")
                    .font(.headline)
                    .foregroundColor(.primary)

                Text("(\(formattedQuantity) \(quantityUnit.displayName) 기준)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)

            VStack(spacing: 0) {
                // 칼로리
                nutritionRow(
                    icon: "flame.fill",
                    iconColor: .orange,
                    label: "칼로리",
                    value: calculatedCalories,
                    unit: "kcal"
                )

                Divider()
                    .padding(.leading, 56)

                // 탄수화물
                nutritionRow(
                    icon: "leaf.fill",
                    iconColor: .blue,
                    label: "탄수화물",
                    value: calculatedCarbohydrates,
                    unit: "g"
                )

                Divider()
                    .padding(.leading, 56)

                // 단백질
                nutritionRow(
                    icon: "bolt.fill",
                    iconColor: .green,
                    label: "단백질",
                    value: calculatedProtein,
                    unit: "g"
                )

                Divider()
                    .padding(.leading, 56)

                // 지방
                nutritionRow(
                    icon: "drop.fill",
                    iconColor: .purple,
                    label: "지방",
                    value: calculatedFat,
                    unit: "g"
                )
            }
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .padding(.horizontal)

            // 삭제 버튼
            Button(action: {
                showingDeleteConfirmation = true
            }) {
                HStack {
                    Image(systemName: "trash")
                        .font(.body)

                    Text("목록에서 삭제")
                        .font(.body)
                }
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Helper Views

    /// 신뢰도 배지
    private var confidenceBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: confidenceIcon)
                .font(.caption2)

            Text("\(match.confidencePercentage)%")
                .font(.caption)
                .fontWeight(.semibold)
        }
        .foregroundColor(confidenceColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(confidenceColor.opacity(0.15))
        .cornerRadius(8)
    }

    /// 영양 정보 배지
    ///
    /// - Parameters:
    ///   - label: 영양소 이름
    ///   - value: 값
    ///   - unit: 단위
    ///   - color: 색상
    private func nutritionBadge(_ label: String, value: String, unit: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)

            HStack(spacing: 2) {
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(unit)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }

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

    /// 빠른 조절 버튼
    ///
    /// - Parameters:
    ///   - label: 버튼 레이블
    ///   - delta: 변경량
    private func quickAdjustButton(_ label: String, delta: Decimal) -> some View {
        Button(action: {
            adjustQuantity(by: delta)
        }) {
            Text(label)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.blue)
                .frame(width: 60)
                .padding(.vertical, 8)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
        }
        .disabled(!canAdjust(by: delta))
    }

    /// 영양 정보 행
    ///
    /// - Parameters:
    ///   - icon: 아이콘 이름
    ///   - iconColor: 아이콘 색상
    ///   - label: 레이블
    ///   - value: 값
    ///   - unit: 단위
    private func nutritionRow(icon: String, iconColor: Color, label: String, value: String, unit: String) -> some View {
        HStack(spacing: 12) {
            // 아이콘
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(iconColor)
                .frame(width: 32)

            // 레이블
            Text(label)
                .font(.body)
                .foregroundColor(.primary)

            Spacer()

            // 값
            HStack(spacing: 4) {
                Text(value)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }

    // MARK: - Computed Properties

    /// 신뢰도 색상
    private var confidenceColor: Color {
        if match.confidence >= 0.7 {
            return .green
        } else if match.confidence >= 0.5 {
            return .orange
        } else {
            return .gray
        }
    }

    /// 신뢰도 아이콘
    private var confidenceIcon: String {
        if match.confidence >= 0.7 {
            return "checkmark.circle.fill"
        } else if match.confidence >= 0.5 {
            return "exclamationmark.circle.fill"
        } else {
            return "questionmark.circle.fill"
        }
    }

    /// 1회 제공량 텍스트
    private var servingSizeText: String {
        let sizeString = formattedDecimal(match.food.servingSize)

        if let unit = match.food.servingUnit {
            return "\(unit) (\(sizeString)g)"
        } else {
            return "\(sizeString)g"
        }
    }

    /// 포맷된 수량
    private var formattedQuantity: String {
        return formattedDecimal(quantity)
    }

    /// 계산된 칼로리
    ///
    /// 📚 학습 포인트: Real-time Calculation
    /// 수량 변경 시 실시간으로 칼로리 재계산
    private var calculatedCalories: String {
        let multiplier = quantityUnit == .serving ? quantity : quantity / match.food.servingSize
        let calories = Decimal(match.food.calories) * multiplier
        return formattedDecimal(calories)
    }

    /// 계산된 탄수화물
    private var calculatedCarbohydrates: String {
        let multiplier = quantityUnit == .serving ? quantity : quantity / match.food.servingSize
        let carbs = match.food.carbohydrates * multiplier
        return formattedDecimal(carbs)
    }

    /// 계산된 단백질
    private var calculatedProtein: String {
        let multiplier = quantityUnit == .serving ? quantity : quantity / match.food.servingSize
        let protein = match.food.protein * multiplier
        return formattedDecimal(protein)
    }

    /// 계산된 지방
    private var calculatedFat: String {
        let multiplier = quantityUnit == .serving ? quantity : quantity / match.food.servingSize
        let fat = match.food.fat * multiplier
        return formattedDecimal(fat)
    }

    // MARK: - Actions

    /// 수량 조절
    ///
    /// - Parameter delta: 변경량
    private func adjustQuantity(by delta: Decimal) {
        let newQuantity = quantity + delta

        // 범위 체크 (0.5 ~ 5.0)
        if newQuantity >= 0.5 && newQuantity <= 5.0 {
            withAnimation(.easeInOut(duration: 0.2)) {
                quantity = newQuantity
            }
        }
    }

    /// 조절 가능 여부 확인
    ///
    /// - Parameter delta: 변경량
    /// - Returns: 조절 가능 여부
    private func canAdjust(by delta: Decimal) -> Bool {
        let newQuantity = quantity + delta
        return newQuantity >= 0.5 && newQuantity <= 5.0
    }

    /// 저장 처리
    private func handleSave() {
        onSave(match, quantity, quantityUnit, selectedMealType)
    }

    // MARK: - Helpers

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
}

// MARK: - Preview

#Preview("Food Match Editor") {
    #if DEBUG
    // Mock 데이터
    let mockMatch = FoodMatch(
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
    )

    return FoodMatchEditorView(
        match: mockMatch,
        onSave: { match, quantity, unit, mealType in
            print("Saved: \(match.food.name), \(quantity) \(unit.displayName), \(mealType.displayName)")
        },
        onDelete: {
            print("Deleted")
        },
        onSearchAlternative: { match in
            print("Search alternative for: \(match.food.name)")
        },
        onCancel: {
            print("Cancelled")
        }
    )
    #endif
}
