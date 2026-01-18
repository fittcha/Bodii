//
//  MealSectionView.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-13.
//

// 📚 학습 포인트: Meal Section Component
// 끼니별 식단 기록을 표시하는 재사용 가능한 컴포넌트
// 💡 음식 추가 버튼과 식단 목록을 포함

import SwiftUI

/// 끼니 섹션 뷰
///
/// 특정 끼니(아침, 점심, 저녁, 간식)의 식단 기록을 표시합니다.
///
/// - Note: 음식 추가 버튼과 식단 기록 목록을 포함합니다.
/// - Note: 빈 상태일 때는 안내 메시지를 표시합니다.
///
/// - Example:
/// ```swift
/// MealSectionView(
///     mealType: .breakfast,
///     meals: breakfastMeals,
///     totalCalories: 450,
///     onAddFood: { showAddFoodSheet() },
///     onDeleteFood: { id in deleteFoodRecord(id) },
///     onEditFood: { id in editFoodRecord(id) }
/// )
/// ```
struct MealSectionView: View {

    // MARK: - Properties

    /// 끼니 타입 (breakfast, lunch, dinner, snack)
    let mealType: MealType

    /// 식단 기록 목록
    let meals: [FoodRecordWithFood]

    /// 총 칼로리
    let totalCalories: Int32

    /// 음식 추가 액션
    let onAddFood: () -> Void

    /// 음식 삭제 액션
    let onDeleteFood: (UUID) -> Void

    /// 음식 수정 액션
    let onEditFood: (UUID) -> Void

    /// AI 코멘트 보기 액션 (Optional)
    let onGetAIComment: (() -> Void)?

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // 헤더
            headerView

            // 식단 기록 목록
            if meals.isEmpty {
                // 빈 상태
                emptyStateView
            } else {
                // 식단 목록
                ForEach(meals) { item in
                    FoodRecordRow(
                        foodRecord: item.foodRecord,
                        food: item.food,
                        onDelete: {
                            onDeleteFood(item.foodRecord.id)
                        },
                        onEdit: {
                            onEditFood(item.foodRecord.id)
                        }
                    )
                }
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }

    // MARK: - Subviews

    /// 헤더 뷰
    ///
    /// 끼니 이름, 총 칼로리, AI 코멘트 버튼, 음식 추가 버튼을 표시합니다.
    private var headerView: some View {
        HStack {
            // 끼니 이름
            Text(mealType.displayName)
                .font(.headline)
                .foregroundColor(.primary)

            Spacer()

            // 총 칼로리
            if !meals.isEmpty {
                Text("\(totalCalories) kcal")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // AI 코멘트 버튼 (끼니에 음식이 있을 때만 표시)
            if !meals.isEmpty, let onGetAIComment = onGetAIComment {
                Button(action: onGetAIComment) {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.caption)
                        Text("AI")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.purple, Color.purple.opacity(0.8)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(8)
                }
                .accessibilityLabel("\(mealType.displayName) AI 코멘트 보기")
                .accessibilityHint("AI가 이 끼니의 영양 평가를 제공합니다")
            }

            // 음식 추가 버튼
            Button(action: onAddFood) {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                    .foregroundColor(.accentColor)
            }
            .accessibilityLabel("\(mealType.displayName)에 음식 추가")
            .accessibilityHint("음식 검색 화면을 엽니다")
        }
        .padding()
        .background(Color(.systemBackground))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(meals.isEmpty ? "\(mealType.displayName)" : "\(mealType.displayName), \(totalCalories)킬로칼로리")
    }

    /// 빈 상태 뷰
    ///
    /// 식단 기록이 없을 때 표시되는 안내 메시지입니다.
    private var emptyStateView: some View {
        Text("기록된 음식이 없습니다")
            .font(.subheadline)
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(Color(.systemBackground))
            .accessibilityLabel("\(mealType.displayName)에 기록된 음식이 없습니다")
            .accessibilityHint("플러스 버튼을 눌러 음식을 추가하세요")
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        // 빈 상태 프리뷰
        MealSectionView(
            mealType: .breakfast,
            meals: [],
            totalCalories: 0,
            onAddFood: { print("Add food") },
            onDeleteFood: { _ in print("Delete food") },
            onEditFood: { _ in print("Edit food") },
            onGetAIComment: nil
        )
        .padding()

        // 데이터가 있는 상태 프리뷰
        MealSectionView(
            mealType: .lunch,
            meals: [
                FoodRecordWithFood(
                    foodRecord: FoodRecord(
                        id: UUID(),
                        userId: UUID(),
                        foodId: UUID(),
                        date: Date(),
                        mealType: .lunch,
                        quantity: 1.0,
                        quantityUnit: .serving,
                        calculatedCalories: 330,
                        calculatedCarbs: 70,
                        calculatedProtein: 7,
                        calculatedFat: 1,
                        createdAt: Date(),
                        updatedAt: Date()
                    ),
                    food: Food(
                        id: UUID(),
                        name: "백미밥",
                        servingSize: 210,
                        servingUnit: "g",
                        caloriesPerServing: 330,
                        carbsPerServing: 70,
                        proteinPerServing: 7,
                        fatPerServing: 1,
                        sodiumPerServing: 0,
                        fiberPerServing: nil,
                        sugarPerServing: nil,
                        source: .governmentAPI,
                        sourceId: nil,
                        usageCount: 10,
                        lastUsedAt: Date(),
                        isUserDefined: false,
                        createdAt: Date(),
                        updatedAt: Date()
                    )
                )
            ],
            totalCalories: 330,
            onAddFood: { print("Add food") },
            onDeleteFood: { _ in print("Delete food") },
            onEditFood: { _ in print("Edit food") },
            onGetAIComment: { print("Get AI comment") }
        )
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}
