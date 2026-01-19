//
//  FoodRecordRow.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-13.
//

// 📚 학습 포인트: Food Record Row Component
// 개별 식단 기록을 표시하는 재사용 가능한 행 컴포넌트
// 💡 탭하여 수정, 스와이프하여 삭제 기능 제공

import SwiftUI

/// 식단 기록 행 뷰
///
/// 개별 음식 기록을 표시하고 편집/삭제 기능을 제공합니다.
///
/// - Note: 음식 이름, 섭취량, 칼로리를 표시합니다.
/// - Note: 탭하여 수정, 스와이프하여 삭제할 수 있습니다.
///
/// - Example:
/// ```swift
/// FoodRecordRow(
///     foodRecord: record,
///     food: food,
///     onDelete: { deleteFoodRecord(record.id) },
///     onEdit: { editFoodRecord(record.id) }
/// )
/// ```
struct FoodRecordRow: View {

    // MARK: - Properties

    /// 식단 기록
    let foodRecord: FoodRecord

    /// 음식 정보
    let food: Food

    /// 삭제 액션
    let onDelete: () -> Void

    /// 수정 액션
    let onEdit: () -> Void

    // MARK: - Body

    var body: some View {
        Button(action: onEdit) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    // 음식 이름
                    Text(food.name ?? "")
                        .font(.body)
                        .foregroundColor(.primary)

                    // 섭취량 정보
                    Text(quantityText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // 칼로리
                Text("\(foodRecord.calculatedCalories) kcal")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                // 편집 아이콘
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .accessibilityHidden(true)
            }
            .padding()
            .background(Color(.systemBackground))
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(food.name ?? ""), \(quantityText), \(foodRecord.calculatedCalories)킬로칼로리")
        .accessibilityHint("두 번 탭하여 수정, 왼쪽으로 스와이프하여 삭제")
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive, action: onDelete) {
                Label("삭제", systemImage: "trash")
            }
            .accessibilityLabel("삭제")
            .accessibilityHint("\(food.name ?? "")을(를) 식단에서 삭제합니다")
        }
    }

    // MARK: - Helpers

    /// 섭취량 텍스트
    ///
    /// 수량과 단위를 포맷팅하여 표시합니다.
    ///
    /// - Returns: 포맷팅된 섭취량 문자열 (예: "1.5인분", "150g")
    private var quantityText: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1

        let quantityNumber = foodRecord.quantity ?? NSDecimalNumber.zero
        let quantityString = formatter.string(from: quantityNumber) ?? "0"

        let unitValue = QuantityUnit(rawValue: foodRecord.quantityUnit) ?? .serving
        switch unitValue {
        case .serving:
            return "\(quantityString)인분"
        case .grams:
            return "\(quantityString)g"
        }
    }
}

// MARK: - Preview

// 📚 학습 포인트: Core Data 엔티티 Preview 제한
// FoodRecord, Food는 Core Data 엔티티이므로 직접 초기화 불가
// TODO: Phase 7에서 Preview용 Core Data context helper 구현

#Preview("Placeholder") {
    Text("FoodRecordRow Preview")
        .font(.headline)
        .padding()
}
