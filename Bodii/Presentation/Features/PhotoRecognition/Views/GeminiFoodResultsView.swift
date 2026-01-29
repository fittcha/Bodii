//
//  GeminiFoodResultsView.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-29.
//

import SwiftUI

/// Gemini AI 음식 분석 결과를 표시하는 뷰
///
/// AI가 인식한 음식 목록을 카드 형태로 표시하고,
/// 사용자가 수량을 편집하거나 항목을 선택/해제할 수 있습니다.
struct GeminiFoodResultsView: View {

    // MARK: - Properties

    /// Gemini 분석 결과 목록
    let results: [GeminiFoodAnalysis]

    /// 선택된 항목 ID 목록
    @State private var selectedIds: Set<UUID> = []

    /// 수량 편집 값 (ID → grams 문자열)
    @State private var editedGrams: [UUID: String] = [:]

    /// 저장 콜백
    let onSave: ([GeminiFoodAnalysis]) -> Void

    /// 취소 콜백
    let onCancel: () -> Void

    // MARK: - Initialization

    init(
        results: [GeminiFoodAnalysis],
        onSave: @escaping ([GeminiFoodAnalysis]) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.results = results
        self.onSave = onSave
        self.onCancel = onCancel
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // 헤더
            headerView

            // 결과 리스트
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(results) { food in
                        GeminiFoodCard(
                            food: food,
                            isSelected: selectedIds.contains(food.id),
                            editedGrams: Binding(
                                get: { editedGrams[food.id] ?? String(format: "%.0f", food.estimatedGrams) },
                                set: { editedGrams[food.id] = $0 }
                            ),
                            onToggle: {
                                toggleSelection(food.id)
                            }
                        )
                    }
                }
                .padding()
            }

            // 하단 버튼
            bottomBar
        }
        .onAppear {
            // 초기에 모든 항목 선택
            selectedIds = Set(results.map { $0.id })
        }
    }

    // MARK: - Subviews

    /// 헤더 뷰
    private var headerView: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.orange)
                Text("AI 음식 분석 결과")
                    .font(.headline)
                Spacer()
                Text("\(results.count)개 인식")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Text("수량을 확인하고 식단에 추가할 음식을 선택하세요")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color(.systemBackground))
    }

    /// 하단 버튼 바
    private var bottomBar: some View {
        VStack(spacing: 12) {
            // 총 칼로리 표시
            if !selectedIds.isEmpty {
                HStack {
                    Text("선택된 음식")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(selectedIds.count)개, \(totalSelectedCalories)kcal")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .padding(.horizontal)
            }

            HStack(spacing: 12) {
                Button(action: onCancel) {
                    Text("취소")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(.systemGray5))
                        .foregroundColor(.primary)
                        .cornerRadius(12)
                }

                Button(action: saveSelected) {
                    Text("식단에 추가")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(selectedIds.isEmpty ? Color.gray : Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .disabled(selectedIds.isEmpty)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .padding(.top, 8)
        .background(Color(.systemBackground))
    }

    // MARK: - Actions

    /// 항목 선택/해제 토글
    private func toggleSelection(_ id: UUID) {
        if selectedIds.contains(id) {
            selectedIds.remove(id)
        } else {
            selectedIds.insert(id)
        }
    }

    /// 선택된 항목 저장
    private func saveSelected() {
        let selectedItems = results.filter { selectedIds.contains($0.id) }.map { food in
            // 편집된 그램 수 적용
            if let gramsStr = editedGrams[food.id],
               let grams = Double(gramsStr),
               grams != food.estimatedGrams {
                let ratio = grams / food.estimatedGrams
                return GeminiFoodAnalysis(
                    id: food.id,
                    name: food.name,
                    estimatedGrams: grams,
                    calories: food.calories * ratio,
                    carbohydrates: food.carbohydrates * ratio,
                    protein: food.protein * ratio,
                    fat: food.fat * ratio
                )
            }
            return food
        }
        onSave(selectedItems)
    }

    // MARK: - Computed

    /// 선택된 항목의 총 칼로리
    private var totalSelectedCalories: Int {
        let total = results
            .filter { selectedIds.contains($0.id) }
            .reduce(0.0) { sum, food in
                if let gramsStr = editedGrams[food.id],
                   let grams = Double(gramsStr),
                   grams != food.estimatedGrams {
                    let ratio = grams / food.estimatedGrams
                    return sum + food.calories * ratio
                }
                return sum + food.calories
            }
        return Int(total.rounded())
    }
}

// MARK: - Gemini Food Card

/// 개별 음식 분석 결과 카드
private struct GeminiFoodCard: View {

    let food: GeminiFoodAnalysis
    let isSelected: Bool
    @Binding var editedGrams: String
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // 체크박스
            Button(action: onToggle) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? .accentColor : .secondary)
            }
            .accessibilityLabel(isSelected ? "선택됨" : "선택 안 됨")

            // 음식 정보
            VStack(alignment: .leading, spacing: 6) {
                Text(food.name)
                    .font(.headline)

                // 수량 편집
                HStack(spacing: 4) {
                    TextField("g", text: $editedGrams)
                        .keyboardType(.numberPad)
                        .frame(width: 60)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.subheadline)
                    Text("g")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                // 영양소 정보
                HStack(spacing: 12) {
                    NutrientLabel(name: "칼", value: displayCalories, color: .orange)
                    NutrientLabel(name: "탄", value: String(format: "%.1f", displayCarbs), color: .blue)
                    NutrientLabel(name: "단", value: String(format: "%.1f", displayProtein), color: .red)
                    NutrientLabel(name: "지", value: String(format: "%.1f", displayFat), color: .yellow)
                }
            }

            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
        )
    }

    // MARK: - Computed (with gram editing)

    private var gramsRatio: Double {
        guard let grams = Double(editedGrams), food.estimatedGrams > 0 else { return 1.0 }
        return grams / food.estimatedGrams
    }

    private var displayCalories: String {
        String(format: "%.0f", food.calories * gramsRatio)
    }

    private var displayCarbs: Double { food.carbohydrates * gramsRatio }
    private var displayProtein: Double { food.protein * gramsRatio }
    private var displayFat: Double { food.fat * gramsRatio }
}

// MARK: - Nutrient Label

/// 영양소 라벨 컴포넌트
private struct NutrientLabel: View {
    let name: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 2) {
            Text(name)
                .font(.caption2)
                .foregroundColor(color)
                .fontWeight(.semibold)
            Text(value)
                .font(.caption)
                .foregroundColor(.primary)
        }
    }
}
