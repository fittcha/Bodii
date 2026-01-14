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
                // 음식 이름
                Text(food.name)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                // 1회 제공량 정보
                Text(servingSizeText)
                    .font(.caption)
                    .foregroundColor(.secondary)

                // 매크로 미리보기 (P/C/F)
                HStack(spacing: 8) {
                    macroPreview("P", value: food.protein, color: .orange)
                    macroPreview("C", value: food.carbohydrates, color: .blue)
                    macroPreview("F", value: food.fat, color: .purple)
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

    // MARK: - Helpers

    /// 1회 제공량 텍스트
    ///
    /// 제공량과 단위를 포맷팅하여 표시합니다.
    ///
    /// - Returns: 포맷팅된 제공량 문자열 (예: "1인분 (210g)", "100g")
    private var servingSizeText: String {
        let sizeString = formattedDecimal(food.servingSize)

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

#Preview {
    VStack(spacing: 0) {
        // 한국 음식 예시 (백미밥)
        FoodSearchResultRow(
            food: Food(
                id: UUID(),
                name: "백미밥",
                calories: 330,
                carbohydrates: 70,
                protein: 7,
                fat: 1,
                sodium: 0,
                fiber: nil,
                sugar: nil,
                servingSize: 210,
                servingUnit: "1공기",
                source: .governmentAPI,
                apiCode: "D000001",
                createdByUserId: nil,
                createdAt: Date()
            )
        )

        Divider()

        // 단백질 음식 예시 (닭가슴살)
        FoodSearchResultRow(
            food: Food(
                id: UUID(),
                name: "닭가슴살",
                calories: 165,
                carbohydrates: 0,
                protein: 31,
                fat: 3.6,
                sodium: 74,
                fiber: nil,
                sugar: nil,
                servingSize: 100,
                servingUnit: "100g",
                source: .governmentAPI,
                apiCode: "D000002",
                createdByUserId: nil,
                createdAt: Date()
            )
        )

        Divider()

        // 고지방 음식 예시 (아보카도)
        FoodSearchResultRow(
            food: Food(
                id: UUID(),
                name: "아보카도",
                calories: 160,
                carbohydrates: 9,
                protein: 2,
                fat: 15,
                sodium: 7,
                fiber: 7,
                sugar: 0.7,
                servingSize: 100,
                servingUnit: "100g",
                source: .usda,
                apiCode: "U000001",
                createdByUserId: nil,
                createdAt: Date()
            )
        )

        Divider()

        // 사용자 정의 음식 예시 (제공 단위 없음)
        FoodSearchResultRow(
            food: Food(
                id: UUID(),
                name: "집밥 김치찌개",
                calories: 150,
                carbohydrates: 10,
                protein: 12,
                fat: 8,
                sodium: 800,
                fiber: nil,
                sugar: nil,
                servingSize: 200,
                servingUnit: nil,
                source: .userDefined,
                apiCode: nil,
                createdByUserId: UUID(),
                createdAt: Date()
            )
        )
    }
    .background(Color(.systemGroupedBackground))
}
