//
//  FoodSearchResultRow.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-13.
//

// 📚 학습 포인트: Food Search Result Row Component
// 음식 검색 결과를 표시하는 재사용 가능한 행 컴포넌트
// 💡 음식 이름, 제공량, 칼로리, 매크로 영양소 미리보기 제공

import SwiftUI

/// 음식 검색 결과 행 뷰
///
/// 음식 이름, 1회 제공량, 칼로리, 매크로 영양소 미리보기를 표시합니다.
///
/// - Note: 검색 결과, 최근 음식, 자주 먹는 음식 섹션에서 재사용됩니다.
/// - Note: 매크로 영양소는 P(단백질)/C(탄수화물)/F(지방)으로 표시됩니다.
///
/// - Example:
/// ```swift
/// FoodSearchResultRow(food: food)
/// ```
struct FoodSearchResultRow: View {

    // MARK: - Properties

    /// 음식 정보
    let food: Food

    // MARK: - Body

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                // 음식 이름 + 유형 배지 + 소스 배지
                HStack(spacing: 6) {
                    Text(displayName)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    foodTypeBadge
                    sourceBadge
                }

                // 카테고리 서브타이틀 (복합명인 경우)
                if let category = categoryName {
                    Text(category)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                // 1회 제공량 정보
                Text(servingSizeText)
                    .font(.caption)
                    .foregroundColor(.secondary)

                // 매크로 미리보기 (P/C/F)
                HStack(spacing: 8) {
                    macroPreview("P", value: food.protein?.decimalValue ?? Decimal(0), color: .orange)
                    macroPreview("C", value: food.carbohydrates?.decimalValue ?? Decimal(0), color: .blue)
                    macroPreview("F", value: food.fat?.decimalValue ?? Decimal(0), color: .purple)
                }
            }

            Spacer()

            // 칼로리
            VStack(spacing: 2) {
                Text("\(food.calories)")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Text("kcal")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            // 네비게이션 아이콘
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .contentShape(Rectangle())
    }

    // MARK: - Food Type

    /// 원재료 여부 (이름에 '_' 없음 + 10자 이하)
    private var isRawIngredient: Bool {
        guard let name = food.name else { return false }
        return !name.contains("_") && name.count <= 10
    }

    /// 가공식품 여부 (이름에 '_' 포함 = KFDA 복합명)
    private var isProcessedFood: Bool {
        guard let name = food.name else { return false }
        return name.contains("_")
    }

    /// 표시용 이름 (카테고리_제품명 → 제품명만 표시)
    private var displayName: String {
        guard let name = food.name else { return "알 수 없는 음식" }
        if let underscoreIndex = name.firstIndex(of: "_") {
            return String(name[name.index(after: underscoreIndex)...])
        }
        return name
    }

    /// 카테고리 이름 (복합명에서 카테고리 부분 추출)
    private var categoryName: String? {
        guard let name = food.name,
              let underscoreIndex = name.firstIndex(of: "_") else { return nil }
        let category = String(name[name.startIndex..<underscoreIndex])
        return category.isEmpty ? nil : category
    }

    /// 데이터 소스 배지
    @ViewBuilder
    private var sourceBadge: some View {
        let source = FoodSource(rawValue: food.source) ?? .userDefined
        switch source {
        case .governmentAPI:
            Text("KFDA")
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(.green)
                .padding(.horizontal, 4)
                .padding(.vertical, 1)
                .background(Color.green.opacity(0.12))
                .cornerRadius(3)
        case .usda:
            Text("USDA")
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(.blue)
                .padding(.horizontal, 4)
                .padding(.vertical, 1)
                .background(Color.blue.opacity(0.12))
                .cornerRadius(3)
        case .openFoodFacts:
            Text("OFF")
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(.orange)
                .padding(.horizontal, 4)
                .padding(.vertical, 1)
                .background(Color.orange.opacity(0.12))
                .cornerRadius(3)
        case .userDefined:
            Text("직접")
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(.purple)
                .padding(.horizontal, 4)
                .padding(.vertical, 1)
                .background(Color.purple.opacity(0.12))
                .cornerRadius(3)
        }
    }

    /// 음식 유형 배지
    @ViewBuilder
    private var foodTypeBadge: some View {
        if isRawIngredient {
            Text("원재료")
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(.green)
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(Color.green.opacity(0.12))
                .cornerRadius(3)
        } else if isProcessedFood {
            Text("가공식품")
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(.orange)
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(Color.orange.opacity(0.12))
                .cornerRadius(3)
        }
    }

    // MARK: - Helpers

    /// 1회 제공량 텍스트
    ///
    /// 제공량과 단위를 포맷팅하여 표시합니다.
    ///
    /// - Returns: 포맷팅된 제공량 문자열 (예: "1인분 (210g)", "100g")
    private var servingSizeText: String {
        let sizeString = formattedDecimal(food.servingSize?.decimalValue ?? Decimal(0))

        if let unit = food.servingUnit {
            return "\(unit) (\(sizeString)g)"
        } else {
            return "\(sizeString)g"
        }
    }

    /// 매크로 영양소 미리보기
    ///
    /// 매크로 영양소의 짧은 정보를 표시합니다.
    ///
    /// - Parameters:
    ///   - label: 영양소 레이블 (P/C/F)
    ///   - value: 영양소 값 (g)
    ///   - color: 표시 색상
    /// - Returns: 매크로 미리보기 뷰
    private func macroPreview(_ label: String, value: Decimal, color: Color) -> some View {
        HStack(spacing: 2) {
            Text(label)
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(color)

            Text(formattedDecimal(value))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(color.opacity(0.1))
        .cornerRadius(4)
    }

    /// Decimal 값을 포맷팅
    ///
    /// Decimal 값을 소수점 첫째 자리까지 표시하는 문자열로 변환합니다.
    ///
    /// - Parameter value: 포맷팅할 Decimal 값
    /// - Returns: 포맷팅된 문자열
    private func formattedDecimal(_ value: Decimal) -> String {
        let nsDecimal = value as NSDecimalNumber
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
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
    Text("FoodSearchResultRow Preview")
        .font(.headline)
        .padding()
}
