//
//  QuickAddSection.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-13.
//

// 📚 학습 포인트: Quick Add Section Component
// 최근/자주 먹는 음식을 가로 스크롤로 표시하는 빠른 추가 섹션
// 💡 FoodSearchView에서 사용되어 빠른 음식 추가를 지원

import SwiftUI

/// 빠른 추가 섹션 뷰
///
/// 최근 또는 자주 먹는 음식을 가로 스크롤로 표시하여 빠른 추가를 지원합니다.
///
/// - Note: 짧게 탭하면 기본 수량(1.0)으로 추가됩니다.
/// - Note: 길게 누르면 수량 선택 화면이 표시됩니다.
///
/// - Example:
/// ```swift
/// QuickAddSection(
///     title: "최근 음식",
///     icon: "clock",
///     foods: recentFoods,
///     onQuickAdd: { food in
///         // 기본 수량으로 음식 추가
///     },
///     onSelectWithQuantity: { food in
///         // 수량 선택 화면 표시
///     }
/// )
/// ```
struct QuickAddSection: View {

    // MARK: - Properties

    /// 섹션 제목
    let title: String

    /// 섹션 아이콘 (SF Symbol 이름)
    let icon: String

    /// 음식 목록
    let foods: [Food]

    /// 빠른 추가 액션 (기본 수량)
    let onQuickAdd: (Food) -> Void

    /// 수량 선택 후 추가 액션
    let onSelectWithQuantity: (Food) -> Void

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 섹션 헤더
            sectionHeader

            // 📚 학습 포인트: Horizontal ScrollView
            // 가로 스크롤을 사용하여 많은 아이템을 효율적으로 표시
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(foods) { food in
                        QuickAddFoodChip(
                            food: food,
                            onQuickAdd: onQuickAdd,
                            onSelectWithQuantity: onSelectWithQuantity
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Subviews

    /// 섹션 헤더
    ///
    /// 아이콘과 제목을 표시합니다.
    private var sectionHeader: some View {
        HStack(spacing: 8) {
            // 아이콘
            Image(systemName: icon)
                .font(.headline)
                .foregroundColor(.secondary)

            // 제목
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)

            Spacer()

            // 힌트 텍스트
            Text("길게 눌러서 수량 선택")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 24) {
        // 최근 음식 섹션
        QuickAddSection(
            title: "최근 음식",
            icon: "clock",
            foods: [
                Food(
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
                ),
                Food(
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
                ),
                Food(
                    id: UUID(),
                    name: "계란",
                    calories: 155,
                    carbohydrates: 1.1,
                    protein: 12.6,
                    fat: 10.6,
                    sodium: 124,
                    fiber: nil,
                    sugar: nil,
                    servingSize: 100,
                    servingUnit: "2개",
                    source: .governmentAPI,
                    apiCode: "D000003",
                    createdByUserId: nil,
                    createdAt: Date()
                )
            ],
            onQuickAdd: { food in
                print("Quick add: \(food.name)")
            },
            onSelectWithQuantity: { food in
                print("Select quantity for: \(food.name)")
            }
        )

        // 자주 먹는 음식 섹션
        QuickAddSection(
            title: "자주 먹는 음식",
            icon: "star.fill",
            foods: [
                Food(
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
                ),
                Food(
                    id: UUID(),
                    name: "고구마",
                    calories: 86,
                    carbohydrates: 20,
                    protein: 1.6,
                    fat: 0.1,
                    sodium: 55,
                    fiber: 3,
                    sugar: 4.2,
                    servingSize: 100,
                    servingUnit: "1개",
                    source: .governmentAPI,
                    apiCode: "D000004",
                    createdByUserId: nil,
                    createdAt: Date()
                ),
                Food(
                    id: UUID(),
                    name: "바나나",
                    calories: 89,
                    carbohydrates: 23,
                    protein: 1.1,
                    fat: 0.3,
                    sodium: 1,
                    fiber: 2.6,
                    sugar: 12,
                    servingSize: 100,
                    servingUnit: "1개",
                    source: .usda,
                    apiCode: "U000002",
                    createdByUserId: nil,
                    createdAt: Date()
                ),
                Food(
                    id: UUID(),
                    name: "그릭 요거트",
                    calories: 59,
                    carbohydrates: 3.6,
                    protein: 10,
                    fat: 0.4,
                    sodium: 36,
                    fiber: nil,
                    sugar: 3.2,
                    servingSize: 100,
                    servingUnit: "100g",
                    source: .usda,
                    apiCode: "U000003",
                    createdByUserId: nil,
                    createdAt: Date()
                )
            ],
            onQuickAdd: { food in
                print("Quick add: \(food.name)")
            },
            onSelectWithQuantity: { food in
                print("Select quantity for: \(food.name)")
            }
        )
    }
    .background(Color(.systemGroupedBackground))
}
