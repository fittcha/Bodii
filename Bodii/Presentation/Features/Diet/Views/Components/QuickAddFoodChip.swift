//
//  QuickAddFoodChip.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-13.
//

// 📚 학습 포인트: Quick Add Food Chip Component
// 빠른 추가를 위한 음식 칩 컴포넌트
// 💡 탭으로 기본 수량 추가, 길게 눌러 수량 선택

import SwiftUI

/// 빠른 추가 음식 칩 뷰
///
/// 최근 또는 자주 먹는 음식을 빠르게 추가할 수 있는 칩 형태의 컴포넌트입니다.
///
/// - Note: 짧게 탭하면 기본 수량(1.0)으로 추가됩니다.
/// - Note: 길게 누르면 수량 선택 화면이 표시됩니다.
///
/// - Example:
/// ```swift
/// QuickAddFoodChip(
///     food: food,
///     onQuickAdd: { food in
///         // 기본 수량으로 음식 추가
///     },
///     onSelectWithQuantity: { food in
///         // 수량 선택 화면 표시
///     }
/// )
/// ```
struct QuickAddFoodChip: View {

    // MARK: - Properties

    /// 음식 정보
    let food: Food

    /// 빠른 추가 액션 (기본 수량)
    let onQuickAdd: (Food) -> Void

    /// 수량 선택 후 추가 액션
    let onSelectWithQuantity: (Food) -> Void

    // MARK: - State

    /// 길게 누르기 상태
    @State private var isPressed: Bool = false

    // MARK: - Body

    var body: some View {
        VStack(spacing: 8) {
            // 📚 학습 포인트: Tap and Long Press Gestures
            // 짧게 탭하면 즉시 추가, 길게 누르면 수량 선택
            VStack(alignment: .leading, spacing: 6) {
                // 음식 이름
                Text(food.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                // 칼로리
                HStack(spacing: 4) {
                    Text("\(food.calories)")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.accentColor)

                    Text("kcal")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // 1회 제공량 정보
                Text(servingSizeText)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .frame(width: 120, alignment: .leading)
            .padding(12)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isPressed ? Color.accentColor : Color(.systemGray4), lineWidth: isPressed ? 2 : 1)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            // 짧게 탭: 기본 수량으로 추가
            onQuickAdd(food)
        }
        .onLongPressGesture(minimumDuration: 0.5, pressing: { pressing in
            isPressed = pressing
        }, perform: {
            // 길게 누르기: 수량 선택 화면 표시
            onSelectWithQuantity(food)
        })
    }

    // MARK: - Helpers

    /// 1회 제공량 텍스트
    ///
    /// 제공량과 단위를 포맷팅하여 표시합니다.
    ///
    /// - Returns: 포맷팅된 제공량 문자열 (예: "1공기", "100g")
    private var servingSizeText: String {
        if let unit = food.servingUnit {
            return unit
        } else {
            let sizeString = formattedDecimal(food.servingSize)
            return "\(sizeString)g"
        }
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
    VStack(spacing: 16) {
        // 한국 음식 예시 (백미밥)
        QuickAddFoodChip(
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
            ),
            onQuickAdd: { food in
                print("Quick add: \(food.name)")
            },
            onSelectWithQuantity: { food in
                print("Select quantity for: \(food.name)")
            }
        )

        // 단백질 음식 예시 (닭가슴살)
        QuickAddFoodChip(
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
            ),
            onQuickAdd: { food in
                print("Quick add: \(food.name)")
            },
            onSelectWithQuantity: { food in
                print("Select quantity for: \(food.name)")
            }
        )

        // 긴 이름 테스트
        QuickAddFoodChip(
            food: Food(
                id: UUID(),
                name: "아주 긴 음식 이름 테스트",
                calories: 250,
                carbohydrates: 30,
                protein: 15,
                fat: 10,
                sodium: 500,
                fiber: nil,
                sugar: nil,
                servingSize: 150,
                servingUnit: nil,
                source: .userDefined,
                apiCode: nil,
                createdByUserId: UUID(),
                createdAt: Date()
            ),
            onQuickAdd: { food in
                print("Quick add: \(food.name)")
            },
            onSelectWithQuantity: { food in
                print("Select quantity for: \(food.name)")
            }
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
