//
//  NutritionFactsCard.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-13.
//

// 📚 학습 포인트: Nutrition Facts Card Component
// 영양 정보 카드 컴포넌트
// 💡 영양 성분표처럼 상세한 영양 정보 분해 표시

import SwiftUI

/// 영양 정보 카드
///
/// 음식의 영양 정보를 상세하게 표시하는 카드 컴포넌트입니다.
/// 영양 성분표 형식으로 칼로리, 매크로 영양소, 선택적 영양소를 표시합니다.
///
/// - Note: 계산된 영양 정보를 기반으로 렌더링됩니다.
/// - Note: 섭취량 정보를 함께 표시합니다.
///
/// - Example:
/// ```swift
/// NutritionFactsCard(
///     food: food,
///     quantity: 1.5,
///     quantityUnit: .serving,
///     calculatedCalories: 495,
///     calculatedCarbs: 105,
///     calculatedProtein: 10.5,
///     calculatedFat: 1.5
/// )
/// ```
struct NutritionFactsCard: View {

    // MARK: - Properties

    /// 음식 정보
    let food: Food

    /// 섭취량
    let quantity: Decimal

    /// 섭취량 단위
    let quantityUnit: QuantityUnit

    /// 계산된 칼로리 (kcal)
    let calculatedCalories: Int32

    /// 계산된 탄수화물 (g)
    let calculatedCarbs: Decimal

    /// 계산된 단백질 (g)
    let calculatedProtein: Decimal

    /// 계산된 지방 (g)
    let calculatedFat: Decimal

    // MARK: - Body

    var body: some View {
        VStack(spacing: 16) {
            // 섹션 헤더
            headerSection

            Divider()

            // 칼로리 (큼직하게 표시)
            caloriesSection

            Divider()

            // 매크로 영양소
            macrosSection

            // 선택적 영양소 (나트륨, 식이섬유, 당류)
            if hasOptionalNutrients {
                Divider()
                optionalNutrientsSection
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }

    // MARK: - Subviews

    /// 섹션 헤더
    ///
    /// 영양 정보 제목과 섭취량 정보를 표시합니다.
    private var headerSection: some View {
        HStack {
            Text("영양 정보")
                .font(.headline)
                .foregroundColor(.primary)

            Spacer()

            Text(quantityText)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    /// 칼로리 섹션
    ///
    /// 칼로리를 큼직하게 표시합니다.
    private var caloriesSection: some View {
        HStack {
            Text("칼로리")
                .font(.body)
                .foregroundColor(.secondary)

            Spacer()

            Text("\(calculatedCalories) kcal")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
        }
    }

    /// 매크로 영양소 섹션
    ///
    /// 탄수화물, 단백질, 지방을 표시합니다.
    private var macrosSection: some View {
        VStack(spacing: 12) {
            // 탄수화물
            nutritionRow(
                name: "탄수화물",
                value: calculatedCarbs,
                unit: "g",
                color: .blue
            )

            // 단백질
            nutritionRow(
                name: "단백질",
                value: calculatedProtein,
                unit: "g",
                color: .orange
            )

            // 지방
            nutritionRow(
                name: "지방",
                value: calculatedFat,
                unit: "g",
                color: .purple
            )
        }
    }

    /// 선택적 영양소 섹션
    ///
    /// 나트륨, 식이섬유, 당류 등 선택적 영양소를 표시합니다.
    private var optionalNutrientsSection: some View {
        VStack(spacing: 12) {
            // 나트륨
            if let sodium = food.sodium?.decimalValue {
                nutritionRow(
                    name: "나트륨",
                    value: sodium * multiplier,
                    unit: "mg",
                    color: .gray
                )
            }

            // 식이섬유
            if let fiber = food.fiber?.decimalValue {
                nutritionRow(
                    name: "식이섬유",
                    value: fiber * multiplier,
                    unit: "g",
                    color: .green
                )
            }

            // 당류
            if let sugar = food.sugar?.decimalValue {
                nutritionRow(
                    name: "당류",
                    value: sugar * multiplier,
                    unit: "g",
                    color: .pink
                )
            }
        }
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

    // MARK: - Computed Properties

    /// 섭취량 텍스트
    ///
    /// 섭취량을 사용자에게 표시하는 형식으로 포맷팅합니다.
    ///
    /// - Returns: 포맷팅된 섭취량 문자열 (예: "1.5인분", "150g")
    private var quantityText: String {
        let quantityStr = formattedDecimal(quantity)
        if quantityUnit == .serving {
            return "\(quantityStr)인분"
        } else {
            return "\(quantityStr)g"
        }
    }

    /// 현재 섭취량에 대한 배수
    ///
    /// 선택적 영양소 계산을 위한 배수입니다.
    ///
    /// - Returns: 배수 값
    private var multiplier: Decimal {
        if quantityUnit == .serving {
            return quantity
        } else {
            // 그램 단위일 경우: quantity / servingSize
            let servingSize = food.servingSize?.decimalValue ?? 1
            return servingSize > 0 ? quantity / servingSize : quantity
        }
    }

    /// 선택적 영양소 존재 여부
    ///
    /// 나트륨, 식이섬유, 당류 중 하나라도 있는지 확인합니다.
    ///
    /// - Returns: 선택적 영양소가 있으면 true
    private var hasOptionalNutrients: Bool {
        food.sodium != nil || food.fiber != nil || food.sugar != nil
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
// Preview는 Core Data 엔티티 초기화 문제로 인해 임시 비활성화
// TODO: PreviewHelpers를 사용한 Preview 구현 필요

// 📚 학습 포인트: Core Data 엔티티 Preview 제한
// Food는 Core Data 엔티티이므로 직접 초기화 불가
// TODO: Phase 7에서 Preview용 Core Data context helper 구현

#Preview("Placeholder") {
    Text("NutritionFactsCard Preview")
        .font(.headline)
        .padding()
}
